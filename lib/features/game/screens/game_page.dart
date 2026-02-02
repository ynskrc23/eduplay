import 'dart:math';
import 'package:flutter/material.dart';
import 'package:confetti/confetti.dart';



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

class GamePage extends StatefulWidget {
  final int childId;
  final int? initialLevelIndex;
  const GamePage({super.key, required this.childId, this.initialLevelIndex});

  @override
  State<GamePage> createState() => _GamePageState();
}

enum GameStatus { welcome, playing, won, levelUp, lost }

class _GamePageState extends State<GamePage> {
  GameStatus _status = GameStatus.welcome;
  bool _isNextLevelUnlocked = false; // Added to check if score reached next level
  int _lastComboBonus = 0;
  int _lastLevelGift = 0;
  
  // Game State Variables
  int _correctCount = 0;
  int _comboCount = 0;
  // ignore: unused_field
  int _wrongCount = 0;
  
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

  // ignore: prefer_final_fields
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

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(duration: const Duration(seconds: 1));
    _loadGameData();
    // SoundService.instance.startBgMusic(); // Disabled missing asset
  }

  Future<void> _loadGameData() async {
    try {
      // Fetch Child Profile
      final profile = await _childRepo.getProfileById(widget.childId);

      // Fetch 'MATH_RACE' game which we seeded
      final game = await _gameRepo.getGameByCode('MATH_RACE');
      if (game != null && profile != null) {
        final levels = await _gameRepo.getLevelsByGameId(game.id!);
        if (levels.isNotEmpty) {
           // Get starting level index from profile or parameter
           final startLevelIndex = widget.initialLevelIndex ?? profile.currentLevel;
           // Cap it to the number of levels available
           _currentLevelIndex = (startLevelIndex < levels.length) ? startLevelIndex : 0;

           // Start with current level rules
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

    // Start New Session Logic
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
      _generateQuestion();
    });
  }

  void _generateQuestion() {
    _inputController.clear();
    
    // Pick a random rule from current level's rules
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
        
        int earnedPoints = 10; // Only base points per question
        _feedbackMessage = _gamification.getFeedbackMessage(true, _comboCount);
        
        _confettiController.play();
        SoundService.instance.playCorrect();
        
        // Update Score (Base only)
        _childRepo.updateScore(widget.childId, earnedPoints);
        
        // Instant update in UI
        if (_childProfile != null) {
          _childProfile = _childProfile!.copyWith(
            totalScore: _childProfile!.totalScore + earnedPoints,
          );
        }

        // Level Progression Condition (Capped at 15)
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
        _comboCount = 0; // Reset combo
        _feedbackMessage = _gamification.getFeedbackMessage(false, 0);
        SoundService.instance.playWrong();
      }
    });
  }

  Future<void> _advanceLevel() async {
    // Close current session
    if (_currentSessionId != null) {
      await _sessionRepo.updateSessionEnd(
        _currentSessionId!, 
        DateTime.now(), 
        _correctCount, 
        _wrongCount
      );
      _currentSessionId = null; // Reset
    }

    int comboBonus = 0;
    int levelGift = 0;

    // Check if there are more levels
    if (_currentLevelIndex + 1 < _levels.length) {
      // Award Combo Bonus at the end (Combo Count * 1)
      if (_comboCount > 0) {
        comboBonus = _comboCount;
        await _childRepo.updateScore(widget.childId, comboBonus);
      }

      _currentLevelIndex++;
    
      // Save progress to DB
      await _childRepo.updateLevel(widget.childId, _currentLevelIndex);

      // Reload profile to show new score immediately
      var updatedProfile = await _childRepo.getProfileById(widget.childId);
      
      // CHECK: Is the next level's unlock score reached?
      bool unlocked = false;
      if (_currentLevelIndex < _levels.length) {
        final nextLevel = _levels[_currentLevelIndex];
        // If current score is enough to unlock this level
        if ((updatedProfile?.totalScore ?? 0) >= nextLevel.unlockScore) {
          unlocked = true;
          // Award 10 points ONLY if they graduated to a new level
          levelGift = 10;
          await _childRepo.updateScore(widget.childId, levelGift);
          // Refresh profile again to include the gift
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
    // No more levels - Game Won!
    setState(() {
      _status = GameStatus.won;
    });
  }
}
  void _exitGame() async {
    // Close session if playing
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
        : Stack(
        alignment: Alignment.topCenter,
        children: [
          Container(
            color: AppColors.background,
            child: SafeArea(
              child: Column(
                children: [
                  // Header Bar
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    child: Row(
                      children: [
                        IconButton(
                          onPressed: _exitGame,
                          icon: const Icon(Icons.close, color: AppColors.gray, size: 28),
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
                            const Icon(Icons.favorite, color: AppColors.red, size: 24),
                            const SizedBox(width: 4),
                            Text(
                              '5',
                              style: TextStyle(
                                color: AppColors.redShadow,
                                fontWeight: FontWeight.w900,
                                fontSize: 18,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 24.0),
                      child: SizedBox(
                        height: MediaQuery.of(context).size.height - 100,
                        child: _buildContent(),
                      ),
                    ),
                  ),
                ],
              ),
            ),
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
            createParticlePath: drawBalloonPath, 
          ),
        ],
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
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: AppColors.white,
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.lightGray, width: 4),
          ),
          child: Text(
            _childProfile?.avatarId ?? '🦊',
            style: const TextStyle(fontSize: 80),
          ),
        ),
        const SizedBox(height: 32),
        Text(
          _childProfile != null ? 'HAZIR MISIN, ${_childProfile!.name.toUpperCase()}?' : 'HAZIR MISIN?',
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w900,
            color: AppColors.textMain,
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          'Yeni bir macera seni bekliyor!\nMatematik canavarlarını yenelim mi?',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 18, color: AppColors.gray, height: 1.5, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 48),
        DuoButton(
          color: AppColors.blue,
          shadowColor: AppColors.blueShadow,
          onPressed: _startGame,
          child: const Text(
            'BAŞLAYALIM!',
            style: TextStyle(color: AppColors.white, fontWeight: FontWeight.w900, fontSize: 20),
          ),
        ),
      ],
    );
  }

  Widget _buildGameCard() {
    int target = min(5 + (_currentLevelIndex * 2), 15);
    
    return Column(
      children: [
        const SizedBox(height: 32),
        // Mascot and Speech Bubble
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.white,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.lightGray, width: 2),
              ),
              child: Text(
                _childProfile?.avatarId ?? '🦊',
                style: const TextStyle(fontSize: 48),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: const BorderRadius.only(
                    topRight: Radius.circular(16),
                    bottomLeft: Radius.circular(16),
                    bottomRight: Radius.circular(16),
                  ),
                  border: Border.all(color: AppColors.lightGray, width: 2),
                ),
                child: Text(
                  'Bu işlemi yapabilir misin?',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textMain,
                  ),
                ),
              ),
            ),
          ],
        ),
        
        const Spacer(),

        // Question Display
        Text(
          '$_num1 $_operator $_num2',
          style: const TextStyle(
            fontSize: 64,
            fontWeight: FontWeight.w900,
            color: AppColors.textMain,
          ),
        ),
        
        const SizedBox(height: 16),
        
        // Answer Input Box (Using standard TextField for "yazma olsun")
        Container(
          width: 200,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: AppColors.lightGray.withOpacity(0.2),
            borderRadius: BorderRadius.circular(16),
            border: const Border(
              bottom: BorderSide(color: AppColors.lightGray, width: 4),
            ),
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
              border: InputBorder.none,
            ),
            onChanged: (val) {
              // Auto-check when correct
              if (val == _answer.toString()) {
                _checkAnswer();
              }
            },
            onSubmitted: (_) => _checkAnswer(),
          ),
        ),

        const SizedBox(height: 32),
        
        if (_feedbackMessage.isNotEmpty)
          Text(
            _feedbackMessage,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w900,
              color: _feedbackMessage.startsWith('Doğru') || _feedbackMessage.contains('! ')
                  ? AppColors.green
                  : AppColors.red,
            ),
          ),

        const Spacer(),
      ],
    );
  }


  Widget _buildScoreChip(String label, int current, int max, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(
            label == 'Doğru' ? Icons.check_circle : Icons.cancel,
            color: color.withOpacity(0.9), // Keeping it visible on dark bg
            size: 20,
          ),
          const SizedBox(width: 8),
          Text(
            '$label: $current/$max',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLevelUpCard() {
    final nextLevel = _currentLevelIndex;
    final unlockScoreNeeded = _levels[nextLevel].unlockScore;

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text(
          'BÖLÜM BİTTİ!',
          style: TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: AppColors.yellowShadow),
        ),
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: AppColors.lightGray, width: 4),
          ),
          child: Column(
            children: [
              const Icon(Icons.stars_rounded, size: 100, color: AppColors.yellow),
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
        ),
        const SizedBox(height: 48),
        DuoButton(
          color: AppColors.green,
          shadowColor: AppColors.greenShadow,
          onPressed: _isNextLevelUnlocked ? _startGame : _exitGame,
          child: Text(
            _isNextLevelUnlocked ? 'DEVAM ET' : 'HARİTAYA DÖN',
            style: const TextStyle(color: AppColors.white, fontWeight: FontWeight.w900, fontSize: 18),
          ),
        ),
        if (_isNextLevelUnlocked)
          Padding(
            padding: const EdgeInsets.only(top: 16),
            child: TextButton(
              onPressed: _exitGame,
              child: const Text('ŞİMDİLİK BU KADAR', style: TextStyle(color: AppColors.gray, fontWeight: FontWeight.bold)),
            ),
          ),
      ],
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
    
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          title.toUpperCase(),
          style: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.w900,
            color: isWin ? AppColors.yellowShadow : AppColors.redShadow,
          ),
        ),
        const SizedBox(height: 32),
        Container(
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: AppColors.lightGray, width: 4),
          ),
          child: Column(
            children: [
              Icon(icon, size: 100, color: isWin ? AppColors.yellow : AppColors.red),
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
    );
  }







  void _showParentPanel() {
    if (_childProfile == null) return;
    
    Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => ParentPanelScreen(childProfile: _childProfile!)),
    );
  }

  /// A custom Path to paint balloon-like shapes.
  Path drawBalloonPath(Size size) {
    final path = Path();
    path.addOval(Rect.fromLTWH(0, 0, size.width, size.height * 0.8));
    path.moveTo(size.width / 2, size.height * 0.8);
    path.lineTo(size.width / 2 - 5, size.height);
    path.lineTo(size.width / 2 + 5, size.height);
    path.close();
    return path;
  }
}
