import 'dart:math';
import 'package:flutter/material.dart';
import 'package:confetti/confetti.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:shimmer/shimmer.dart';

import '../../../data/models/game.dart';
import '../../../data/models/level.dart';
import '../../../data/models/question_rule.dart';
import '../../../data/repositories/game_repository.dart';
import '../../../data/repositories/child_repository.dart';
import '../../../data/repositories/game_session_repository.dart';
import '../../../data/models/child_profile.dart';
import '../../../data/models/game_session.dart';
import '../services/question_generator.dart';
import '../../parent_panel/screens/parent_panel_screen.dart';
import '../../../core/services/sound_service.dart';
import '../services/gamification_service.dart';
import '../../../core/app_colors.dart';
import '../../../core/widgets/duo_button.dart';
import '../../../core/widgets/duo_progress_bar.dart';

class GamePageEnhanced extends StatefulWidget {
  final int childId;
  final int? initialLevelIndex;
  const GamePageEnhanced({super.key, required this.childId, this.initialLevelIndex});

  @override
  State<GamePageEnhanced> createState() => _GamePageEnhancedState();
}

enum GameStatus { welcome, playing, won, levelUp, lost }

class _GamePageEnhancedState extends State<GamePageEnhanced> with TickerProviderStateMixin {
  GameStatus _status = GameStatus.welcome;
  bool _isNextLevelUnlocked = false;
  int _lastComboBonus = 0;
  int _lastLevelGift = 0;
  
  // Game State Variables
  int _correctCount = 0;
  int _comboCount = 0;
  int _wrongCount = 0;
  
  // Monster Health
  int _monsterHealth = 100;
  int _monsterMaxHealth = 100;
  bool _monsterHit = false;
  
  // Game Data
  final GamificationService _gamification = GamificationService.instance;
  final GameRepository _gameRepo = GameRepository();
  final ChildRepository _childRepo = ChildRepository();
  final GameSessionRepository _sessionRepo = GameSessionRepository();
  final QuestionGenerator _questionGenerator = QuestionGenerator();
  
  Game? _game;
  ChildProfile? _childProfile;
  List<Level> _levels = [];
  List<QuestionRule> _currentRules = [];
  
  // Session Data
  int? _currentSessionId;
  int _currentLevelIndex = 0;
  bool _isLoading = true;

  // Current Question
  late int _num1;
  late int _num2;
  late String _operator;
  int _answer = 0;
  
  final TextEditingController _inputController = TextEditingController();
  final Random _random = Random();
  String _feedbackMessage = '';
  late ConfettiController _confettiController;
  late AnimationController _shakeController;
  late AnimationController _monsterController;

  // Monster emojis for variety
  final List<String> _monsters = ['👾', '👹', '👺', '🤖', '👻', '🧟', '🧌'];
  String _currentMonster = '👾';

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(duration: const Duration(seconds: 1));
    _shakeController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _monsterController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _loadGameData();
  }

  Future<void> _loadGameData() async {
    try {
      final profile = await _childRepo.getProfileById(widget.childId);
      final game = await _gameRepo.getGameByCode('MATH_RACE');
      if (game != null && profile != null) {
        final levels = await _gameRepo.getLevelsByGameId(game.id!);
        if (levels.isNotEmpty) {
           final startLevelIndex = widget.initialLevelIndex ?? profile.currentLevel;
           _currentLevelIndex = (startLevelIndex < levels.length) ? startLevelIndex : 0;
           final rules = await _gameRepo.getRulesByLevelId(levels[_currentLevelIndex].id!);
           
            if (mounted) {
              setState(() {
                _game = game;
                _childProfile = profile;
                _levels = levels;
                _currentRules = rules;
              });
              await _startGame();
              if (mounted) {
                setState(() => _isLoading = false);
              }
            }
            return;
          }
        }
      } catch (e) {
        debugPrint('Error loading game data: $e');
      }

      if (mounted) {
        setState(() => _isLoading = false);
      }
    }

  @override
  void dispose() {
    _confettiController.dispose();
    _inputController.dispose();
    _shakeController.dispose();
    _monsterController.dispose();
    SoundService.instance.stopBgMusic();
    super.dispose();
  }

  Future<void> _startGame() async {
    if (_levels.isEmpty || _currentRules.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Oyun verisi yüklenemedi!')),
        );
        return;
    }

    if (_game != null && _childProfile != null) {
      final session = GameSession(
        childId: _childProfile!.id!,
        gameId: _game!.id!,
        levelId: _levels[_currentLevelIndex].id!,
        startedAt: DateTime.now(),
      );
      _currentSessionId = await _sessionRepo.createSession(session);
    }

    setState(() {
      _status = GameStatus.playing;
      _correctCount = 0;
      _comboCount = 0;
      _wrongCount = 0;
      _feedbackMessage = '';
      _monsterHealth = 100;
      _monsterMaxHealth = 100;
      _currentMonster = _monsters[_random.nextInt(_monsters.length)];
      _generateQuestion();
    });
  }

  void _generateQuestion() {
    _inputController.clear();
    
    if (_currentRules.isEmpty) return;
    final rule = _currentRules[_random.nextInt(_currentRules.length)];
    
    final question = _questionGenerator.generate(rule);
    
    setState(() {
      _num1 = question.num1;
      _num2 = question.num2;
      _operator = question.operation;
      _answer = question.answer;
    });
  }

  void _checkAnswer() {
    if (_inputController.text.isEmpty) return;
    
    int? userAnswer = int.tryParse(_inputController.text);
    if (userAnswer == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lütfen geçerli bir sayı giriniz.')),
      );
      return;
    }

    setState(() {
      if (userAnswer == _answer) {
        _correctCount++;
        _comboCount++;
        
        // Hit the monster!
        int damage = min(20 + (_comboCount * 2), 35);
        _monsterHealth = max(0, _monsterHealth - damage);
        _monsterHit = true;
        
        int earnedPoints = 10;
        _feedbackMessage = _gamification.getFeedbackMessage(true, _comboCount);
        
        _confettiController.play();
        _monsterController.forward().then((_) => _monsterController.reverse());
        SoundService.instance.playCorrect();
        
        _childRepo.updateScore(widget.childId, earnedPoints);
        
        if (_childProfile != null) {
          _childProfile = _childProfile!.copyWith(
            totalScore: _childProfile!.totalScore + earnedPoints,
          );
        }

        Future.delayed(const Duration(milliseconds: 300), () {
          if (mounted) setState(() => _monsterHit = false);
        });

        int target = min(5 + (_currentLevelIndex * 2), 15);
        if (_correctCount >= target) {
          _advanceLevel();
        } else {
          Future.delayed(const Duration(milliseconds: 800), () {
             if (mounted && _status == GameStatus.playing) _generateQuestion();
          });
        }
      } else {
        _wrongCount++;
        _comboCount = 0;
        _feedbackMessage = _gamification.getFeedbackMessage(false, 0);
        _shakeController.forward().then((_) => _shakeController.reverse());
        SoundService.instance.playWrong();
      }
    });
  }

  Future<void> _advanceLevel() async {
    if (_currentSessionId != null) {
      await _sessionRepo.updateSessionEnd(
        _currentSessionId!, 
        DateTime.now(), 
        _correctCount, 
        _wrongCount
      );
      _currentSessionId = null;
    }

    int comboBonus = 0;
    int levelGift = 0;

    if (_currentLevelIndex + 1 < _levels.length) {
      if (_comboCount > 0) {
        comboBonus = _comboCount;
        await _childRepo.updateScore(widget.childId, comboBonus);
      }

      _currentLevelIndex++;
    
      await _childRepo.updateLevel(widget.childId, _currentLevelIndex);

      var updatedProfile = await _childRepo.getProfileById(widget.childId);
      
      bool unlocked = false;
      if (_currentLevelIndex < _levels.length) {
        final nextLevel = _levels[_currentLevelIndex];
        if ((updatedProfile?.totalScore ?? 0) >= nextLevel.unlockScore) {
          unlocked = true;
          levelGift = 10;
          await _childRepo.updateScore(widget.childId, levelGift);
          updatedProfile = await _childRepo.getProfileById(widget.childId);
        }
      }

      if (mounted) {
        setState(() {
          _childProfile = updatedProfile;
          _isNextLevelUnlocked = unlocked;
          _lastComboBonus = comboBonus;
          _lastLevelGift = levelGift;
          _status = GameStatus.levelUp;
          _isLoading = false; 
          _feedbackMessage = ''; 
        });
      }
    } else {
    setState(() {
      _status = GameStatus.won;
    });
  }
}

  void _exitGame() async {
    if (_currentSessionId != null) {
      await _sessionRepo.updateSessionEnd(
        _currentSessionId!,
        DateTime.now(),
        _correctCount,
        _wrongCount,
      );
      _currentSessionId = null;
    }

    if (mounted) {
      if (Navigator.canPop(context)) {
        Navigator.pop(context);
      } else {
        setState(() {
          _status = GameStatus.welcome;
          _correctCount = 0;
          _wrongCount = 0;
          _feedbackMessage = '';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator()) 
        : Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                const Color(0xFF667eea),
                const Color(0xFF764ba2),
                const Color(0xFFf093fb),
              ],
            ),
          ),
          child: SafeArea(
            child: Stack(
              alignment: Alignment.topCenter,
              children: [
                Column(
                  children: [
                    // Header Bar
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      child: Row(
                        children: [
                          IconButton(
                            onPressed: _exitGame,
                            icon: const Icon(Icons.close, color: Colors.white, size: 28),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: DuoProgressBar(
                              value: _correctCount / min(5 + (_currentLevelIndex * 2), 15),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Row(
                            children: [
                              const Icon(Icons.favorite, color: Colors.red, size: 24),
                              const SizedBox(width: 4),
                              Text(
                                '∞',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w900,
                                  fontSize: 24,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    Expanded(
                      child: _buildContent(),
                    ),
                  ],
                ),
                ConfettiWidget(
                  confettiController: _confettiController,
                  blastDirectionality: BlastDirectionality.explosive,
                  shouldLoop: false,
                  colors: const [
                    Colors.green,
                    Colors.blue,
                    Colors.pink,
                    Colors.orange,
                    Colors.purple,
                  ],
                ),
              ],
            ),
          ),
        ),
    );
  }

  Widget _buildContent() {
    switch (_status) {
      case GameStatus.welcome:
        return _buildWelcomeCard();
      case GameStatus.playing:
        return _buildGameCard();
      case GameStatus.levelUp:
        return _buildLevelUpCard();
      case GameStatus.won:
        return _buildResultCard(
          title: 'Tebrikler!',
          message: 'Tüm soruları bildin ve bu bölümü fethettin! 👑',
          icon: Icons.emoji_events_rounded,
          color: Colors.amber,
        );
      case GameStatus.lost:
        return _buildResultCard(
          title: 'Yeniden Dene',
          message: 'Hatalar öğrenmenin bir parçasıdır. Hadi bir daha deneyelim! 💪',
          icon: Icons.refresh_rounded,
          color: Colors.orangeAccent,
        );
    }
  }

  Widget _buildWelcomeCard() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Text(
              _childProfile?.avatarId ?? '🦊',
              style: const TextStyle(fontSize: 80),
            ),
          ).animate().scale(duration: 600.ms, curve: Curves.elasticOut),
          const SizedBox(height: 32),
          Text(
            _childProfile != null ? 'HAZIR MISIN, ${_childProfile!.name.toUpperCase()}?' : 'HAZIR MISIN?',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w900,
              color: Colors.white,
              shadows: [
                Shadow(
                  color: Colors.black26,
                  offset: Offset(2, 2),
                  blurRadius: 4,
                ),
              ],
            ),
          ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.3, end: 0),
          const SizedBox(height: 16),
          const Text(
            'Matematik canavarlarını yenmeye hazır ol!\nHer doğru cevap onlara hasar verecek!',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16, 
              color: Colors.white, 
              height: 1.5, 
              fontWeight: FontWeight.w600
            ),
          ).animate().fadeIn(delay: 400.ms),
          const SizedBox(height: 48),
          DuoButton(
            color: const Color(0xFF4CAF50),
            shadowColor: const Color(0xFF2E7D32),
            onPressed: _startGame,
            child: const Text(
              'SAVAŞA BAŞLA!',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 20),
            ),
          ).animate().scale(delay: 600.ms, duration: 400.ms, curve: Curves.elasticOut),
        ],
      ),
    );
  }

  Widget _buildGameCard() {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const SizedBox(height: 20),
            
            // Monster Display
            _buildMonsterSection(),
            
            const SizedBox(height: 40),
            
            // Question Card
            _buildQuestionCard(),
            
            const SizedBox(height: 20),
            
            // Feedback
            if (_feedbackMessage.isNotEmpty)
              Text(
                _feedbackMessage,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: _feedbackMessage.startsWith('Doğru') || _feedbackMessage.contains('! ')
                      ? Colors.greenAccent
                      : Colors.redAccent,
                  shadows: const [
                    Shadow(
                      color: Colors.black26,
                      offset: Offset(1, 1),
                      blurRadius: 3,
                    ),
                  ],
                ),
              ).animate().fadeIn().shake(),
          ],
        ),
      ),
    );
  }

  Widget _buildMonsterSection() {
    return Column(
      children: [
        // Monster Health Bar
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.3),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'CANAVAR',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      fontSize: 14,
                      letterSpacing: 2,
                    ),
                  ),
                  Text(
                    '$_monsterHealth / $_monsterMaxHealth',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: LinearProgressIndicator(
                  value: _monsterHealth / _monsterMaxHealth,
                  minHeight: 20,
                  backgroundColor: Colors.red.shade900,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    _monsterHealth > 50 ? Colors.red : Colors.orange,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        
        // Monster Character
        AnimatedBuilder(
          animation: _monsterController,
          builder: (context, child) {
            return Transform.scale(
              scale: 1.0 + (_monsterController.value * 0.2),
              child: Transform.rotate(
                angle: _monsterController.value * 0.1,
                child: Container(
                  width: 150,
                  height: 150,
                  decoration: BoxDecoration(
                    color: _monsterHit 
                        ? Colors.red.withOpacity(0.3)
                        : Colors.white.withOpacity(0.1),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: _monsterHit ? Colors.red : Colors.purple,
                        blurRadius: 30,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      _currentMonster,
                      style: const TextStyle(fontSize: 100),
                    ),
                  ),
                ),
              ),
            );
          },
        ).animate(
          onPlay: (controller) => controller.repeat(reverse: true),
        ).moveY(
          begin: 0,
          end: -10,
          duration: 2000.ms,
          curve: Curves.easeInOut,
        ),
      ],
    );
  }

  Widget _buildQuestionCard() {
    return AnimatedBuilder(
      animation: _shakeController,
      builder: (context, child) {
        final sineValue = sin(3 * 2 * pi * _shakeController.value);
        return Transform.translate(
          offset: Offset(sineValue * 10, 0),
          child: child,
        );
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.white,
              Colors.blue.shade50,
            ],
          ),
          borderRadius: BorderRadius.circular(32),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          children: [
            Shimmer.fromColors(
              baseColor: AppColors.textMain,
              highlightColor: AppColors.blue,
              child: Text(
                '$_num1 $_operator $_num2',
                style: const TextStyle(
                  fontSize: 72,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 4,
                ),
              ),
            ),
            const SizedBox(height: 24),
            
            // Answer Input
            Container(
              width: 180,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: AppColors.blue,
                  width: 3,
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.blue.withOpacity(0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: TextField(
                controller: _inputController,
                keyboardType: TextInputType.number,
                autofocus: true,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 48,
                  fontWeight: FontWeight.w900,
                  color: AppColors.blueShadow,
                ),
                decoration: const InputDecoration(
                  hintText: '?',
                  hintStyle: TextStyle(color: AppColors.lightGray),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(vertical: 12),
                ),
                onChanged: (val) {
                  if (val == _answer.toString()) {
                    _checkAnswer();
                  }
                },
                onSubmitted: (_) => _checkAnswer(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLevelUpCard() {
    final nextLevel = _currentLevelIndex;
    final unlockScoreNeeded = _levels[nextLevel].unlockScore;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text(
            'CANAVAR YENİLDİ!',
            style: TextStyle(
              fontSize: 32, 
              fontWeight: FontWeight.w900, 
              color: Colors.white,
              shadows: [
                Shadow(
                  color: Colors.black26,
                  offset: Offset(2, 2),
                  blurRadius: 4,
                ),
              ],
            ),
          ).animate().fadeIn().slideY(begin: -0.3, end: 0),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              children: [
                const Icon(Icons.stars_rounded, size: 100, color: Colors.amber),
                const SizedBox(height: 24),
                if (_lastComboBonus > 0 || _lastLevelGift > 0)
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    alignment: WrapAlignment.center,
                    children: [
                      if (_lastComboBonus > 0)
                        _buildBonusBadge('🔥 $_lastComboBonus KOMBO BONUSU'),
                      if (_lastLevelGift > 0)
                        _buildBonusBadge('🎁 $_lastLevelGift SEVİYE HEDİYESİ'),
                    ],
                  ),
                const SizedBox(height: 24),
                Text(
                  _isNextLevelUnlocked 
                      ? 'Yeni bir seviye açıldı!' 
                      : 'Sonraki seviye için $unlockScoreNeeded puana ulaşman gerekiyor.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 18, color: AppColors.textMain, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ).animate().scale(delay: 200.ms, curve: Curves.elasticOut),
          const SizedBox(height: 48),
          DuoButton(
            color: AppColors.green,
            shadowColor: AppColors.greenShadow,
            onPressed: _isNextLevelUnlocked ? _startGame : _exitGame,
            child: Text(
              _isNextLevelUnlocked ? 'SONRAKİ CANAVAR' : 'HARİTAYA DÖN',
              style: const TextStyle(color: AppColors.white, fontWeight: FontWeight.w900, fontSize: 18),
            ),
          ),
          if (_isNextLevelUnlocked)
            Padding(
              padding: const EdgeInsets.only(top: 16),
              child: TextButton(
                onPressed: _exitGame,
                child: const Text(
                  'ŞİMDİLİK BU KADAR', 
                  style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold)
                ),
              ),
            ),
        ],
      ),
    );
  }

Widget _buildBonusBadge(String text) {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
    decoration: BoxDecoration(
      color: Colors.orange,
      borderRadius: BorderRadius.circular(8),
    ),
    child: Text(
      text,
      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
    ),
  );
}

  Widget _buildResultCard({
    required String title,
    required String message,
    required IconData icon,
    required Color color,
  }) {
    bool isWin = title == 'Tebrikler!';
    
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            title.toUpperCase(),
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.w900,
              color: Colors.white,
              shadows: const [
                Shadow(
                  color: Colors.black26,
                  offset: Offset(2, 2),
                  blurRadius: 4,
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              children: [
                Icon(icon, size: 100, color: isWin ? Colors.amber : Colors.red),
                const SizedBox(height: 24),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 18, color: AppColors.textMain, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          const SizedBox(height: 48),
          DuoButton(
            color: isWin ? AppColors.green : AppColors.blue,
            shadowColor: isWin ? AppColors.greenShadow : AppColors.blueShadow,
            onPressed: isWin ? _exitGame : _startGame,
            child: Text(
              isWin ? 'DEVAM ET' : 'TEKRAR DENE',
              style: const TextStyle(color: AppColors.white, fontWeight: FontWeight.w900, fontSize: 18),
            ),
          ),
        ],
      ),
    );
  }
}
