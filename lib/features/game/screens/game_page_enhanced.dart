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
import '../../../core/services/sound_service.dart';
import '../../../core/services/admob_service.dart';
import '../../../core/app_colors.dart';
import '../../../core/widgets/duo_button.dart';
import '../../../core/widgets/neumorphic_game_button.dart';

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
  
  // Game State Variables
  int _correctCount = 0;
  int _comboCount = 0;
  int _wrongCount = 0;
  
  // Monster Health
  int _monsterHealth = 100;
  int _monsterMaxHealth = 100;
  bool _monsterHit = false;
  
  // Game Data
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
      _monsterHealth = 150;
      _monsterMaxHealth = 150;
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
        
        // Hit the monster! (Adjusted for more questions, ~8-10 correct answers)
        int damage = min(12 + (_comboCount * 1), 25);
        _monsterHealth = max(0, _monsterHealth - damage);
        _monsterHit = true;
        
        // _feedbackMessage set edilmiyor, böylece ekranda "Doğru!" yazısı çıkmayacak
        
        _confettiController.play();
        _monsterController.forward().then((_) => _monsterController.reverse());
        SoundService.instance.playCorrect();
        
        Future.delayed(const Duration(milliseconds: 300), () {
          if (mounted) setState(() => _monsterHit = false);
        });

        if (_monsterHealth <= 0) {
          _advanceLevel();
        } else {
          Future.delayed(const Duration(milliseconds: 800), () {
             if (mounted && _status == GameStatus.playing) _generateQuestion();
          });
        }
      } else {
        _wrongCount++;
        _comboCount = 0;
        _feedbackMessage = "Cevap bu değil, tekrar dene! 💪";
        _shakeController.forward().then((_) => _shakeController.reverse());
        SoundService.instance.playWrong();
        
        // Hatalı cevapta mesajı bir süre sonra temizle
        Future.delayed(const Duration(milliseconds: 1500), () {
          if (mounted) {
            setState(() {
              _feedbackMessage = '';
              _inputController.clear();
            });
          }
        });
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


    if (_currentLevelIndex + 1 < _levels.length) {
      _currentLevelIndex++;
    
      await _childRepo.updateLevel(widget.childId, _currentLevelIndex);

      var updatedProfile = await _childRepo.getProfileById(widget.childId);
      
      if (mounted) {
        setState(() {
          _childProfile = updatedProfile;
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
      
      // Oyun tamamlandı, reklam göster (her 3 oyunda bir)
      AdMobService().onGameCompleted();
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
          color: AppColors.cloudBlue,
          child: SafeArea(
            child: Stack(
              alignment: Alignment.topCenter,
              children: [
                Column(
                  children: [
                    // Header Bar (Simplified like Number Ordering)
                    Container(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          // Back Button
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.blueGrey.shade200,
                                  offset: const Offset(0, 4),
                                  blurRadius: 0,
                                ),
                              ],
                            ),
                            child: IconButton(
                              padding: EdgeInsets.zero,
                              onPressed: _exitGame,
                              icon: const Icon(Icons.arrow_back_rounded, color: AppColors.cloudBlue, size: 28),
                            ),
                          ),
                          const SizedBox(width: 16),
                          // Title
                          const Expanded(
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                'MATEMATİK SAVAŞI',
                                textAlign: TextAlign.center,
                                maxLines: 1,
                                softWrap: false,
                                style: TextStyle(
                                  fontFamily: 'Roboto',
                                  fontSize: 24,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.white,
                                  letterSpacing: 1.0,
                                  shadows: [
                                    Shadow(color: Colors.black26, offset: Offset(2, 2), blurRadius: 4),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          const SizedBox(width: 48), // Balancing space
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 10),
                    
                    // Monster Health Bar (Header Style)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: SizedBox(
                          height: 12,
                          child: LinearProgressIndicator(
                            value: _monsterHealth / _monsterMaxHealth,
                            backgroundColor: Colors.white.withValues(alpha: 0.3),
                            valueColor: AlwaysStoppedAnimation<Color>(
                              _monsterHealth > 50 ? AppColors.sunYellow : AppColors.orange,
                            ),
                          ),
                        ),
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
                  color: Colors.black.withValues(alpha: 0.2),
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
        // Monster Character
        AnimatedBuilder(
          animation: _monsterController,
          builder: (context, child) {
            return Transform.scale(
              scale: 1.0 + (_monsterController.value * 0.2),
              child: Transform.rotate(
                angle: _monsterController.value * 0.1,
                child: Container(
                  width: 200,
                  height: 200,
                  decoration: BoxDecoration(
                    color: _monsterHit 
                        ? Colors.red.withValues(alpha: 0.3)
                        : Colors.white.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: _monsterHit ? Colors.red : AppColors.purpleDark.withValues(alpha: 0.5),
                        blurRadius: 30,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      _currentMonster,
                      style: const TextStyle(fontSize: 130),
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
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          children: [
            Shimmer.fromColors(
              baseColor: AppColors.blueShadow,
              highlightColor: AppColors.blue,
              child: (_operator == '*' || _operator == '/') 
                ? Text(
                    '$_num1 $_operator $_num2',
                    style: const TextStyle(
                      fontSize: 72,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 4,
                    ),
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '$_num1',
                        style: const TextStyle(
                          fontSize: 72,
                          fontWeight: FontWeight.w900,
                          height: 1.1,
                        ),
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '$_operator ',
                            style: const TextStyle(
                              fontSize: 50,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          Text(
                            '$_num2',
                            style: const TextStyle(
                              fontSize: 72,
                              fontWeight: FontWeight.w900,
                              height: 1.1,
                            ),
                          ),
                        ],
                      ),
                      Container(
                        margin: const EdgeInsets.only(top: 8),
                        height: 6,
                        width: 140,
                        decoration: BoxDecoration(
                          color: AppColors.blueShadow,
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                    ],
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
                    color: AppColors.blue.withValues(alpha: 0.3),
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
    return _buildResultCard(
      title: 'MÜKEMMEL!',
      message: 'Canavarı yendin ve zafer kazandın!',
      icon: Icons.emoji_events_rounded,
      color: AppColors.orange,
    );
  }

  Widget _buildResultCard({
    required String title,
    required String message,
    required IconData icon,
    required Color color,
  }) {
    bool isWin = title == 'Tebrikler!' || title == 'MÜKEMMEL!';
    
    return Container(
      color: Colors.black54, // Overlay
      child: Center(
        child: Container(
          margin: const EdgeInsets.all(24),
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(30),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                title.toUpperCase(),
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w900,
                  color: isWin ? AppColors.orange : AppColors.berryRed,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                isWin ? '🏆' : '💪',
                style: const TextStyle(fontSize: 80),
              ),
              const SizedBox(height: 24),
              Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.gray,
                ),
              ),
              const SizedBox(height: 48),
              NeumorphicGameButton(
                color: isWin ? AppColors.orange : AppColors.oceanBlue,
                shadowColor: isWin ? AppColors.orangeShadow : AppColors.oceanBlueShadow,
                width: 200,
                height: 60,
                onPressed: isWin ? _exitGame : _startGame,
                child: Text(
                  isWin ? 'DEVAM ET' : 'TEKRAR DENE',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 18,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
