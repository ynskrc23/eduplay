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
import '../../../core/services/sound_service.dart';
import '../../../core/app_colors.dart';
import '../../../core/widgets/neumorphic_game_button.dart';

class GamePageModern extends StatefulWidget {
  final int childId;
  final int? initialLevelIndex;
  final String? operation; // '+', '-', '*', '/'
  final String? difficulty; // 'kolay' | 'orta' | 'zor'
  const GamePageModern({
    super.key,
    required this.childId,
    this.initialLevelIndex,
    this.operation,
    this.difficulty,
  });

  @override
  State<GamePageModern> createState() => _GamePageModernState();
}

enum GameStatus { welcome, playing, won, levelUp, lost }

class _GamePageModernState extends State<GamePageModern> with TickerProviderStateMixin {
  GameStatus _status = GameStatus.welcome;
  bool _isNextLevelUnlocked = false;
  int _lastLevelGift = 0;
  int _lastComboBonus = 0;
  bool get _isFreeMode => widget.operation != null && widget.difficulty != null;
  
  // Game State Variables
  int _correctCount = 0;
  int _comboCount = 0;
  int _wrongCount = 0;
  
  // Multiple choice options
  List<int> _answerOptions = [];
  int? _selectedAnswer;
  bool _showFeedback = false;
  
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
  
  final Random _random = Random();
  int _levelTarget = 5;
  String _feedbackMessage = '';
  late ConfettiController _confettiController;
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(duration: const Duration(seconds: 1));
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    )..repeat(reverse: true);
    _loadGameData();
  }

  Future<void> _loadGameData() async {
    try {
      final profile = await _childRepo.getProfileById(widget.childId);
      if (!_isFreeMode) {
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
              if (mounted) setState(() => _isLoading = false);
            }
            return;
          }
        }
      } else {
        if (mounted) {
          setState(() {
            _childProfile = profile;
            _levels = [];
            _currentRules = _buildRulesForSelection(widget.operation!, widget.difficulty!);
          });
          await _startGame();
          if (mounted) setState(() => _isLoading = false);
        }
        return;
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
    _pulseController.dispose();
    SoundService.instance.stopBgMusic();
    super.dispose();
  }

  Future<void> _startGame() async {
    if (_currentRules.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Oyun verisi yüklenemedi!')),
        );
        return;
    }

    if (!_isFreeMode && _game != null && _childProfile != null) {
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
      _levelTarget = _isFreeMode ? _targetForDifficulty(widget.difficulty!) : min(5 + (_currentLevelIndex * 2), 15);
      _generateQuestion();
    });
  }

  void _generateQuestion() {
    if (_currentRules.isEmpty) return;
    final rule = _currentRules[_random.nextInt(_currentRules.length)];
    
    final question = _questionGenerator.generate(rule);
    
    // Generate multiple choice options
    List<int> options = [question.answer];
    while (options.length < 4) {
      int wrongAnswer = question.answer + _random.nextInt(20) - 10;
      if (wrongAnswer > 0 && !options.contains(wrongAnswer)) {
        options.add(wrongAnswer);
      }
    }
    options.shuffle();
    
    setState(() {
      _num1 = question.num1;
      _num2 = question.num2;
      _operator = question.operation;
      _answer = question.answer;
      _answerOptions = options;
      _selectedAnswer = null;
      _showFeedback = false;
      _feedbackMessage = '';
    });
  }

  void _checkAnswer(int userAnswer) {
    setState(() {
      _selectedAnswer = userAnswer;
      _showFeedback = true;
      
      if (userAnswer == _answer) {
        _correctCount++;
        _comboCount++;
        
        int earnedPoints = 10;
        // _feedbackMessage set edilmiyor, böylece ekranda "Doğru!" yazısı çıkmayacak
        
        _confettiController.play();
        SoundService.instance.playCorrect();
        
        _childRepo.updateScore(widget.childId, earnedPoints);
        
        if (_childProfile != null) {
          _childProfile = _childProfile!.copyWith(
            totalScore: _childProfile!.totalScore + earnedPoints,
          );
        }

        if (_correctCount >= _levelTarget) {
          Future.delayed(const Duration(milliseconds: 1500), () {
            _advanceLevel();
          });
        } else {
          Future.delayed(const Duration(milliseconds: 1500), () {
             if (mounted && _status == GameStatus.playing) _generateQuestion();
          });
        }
      } else {
        _comboCount = 0;
        _feedbackMessage = "Cevap bu değil, tekrar dene! 💪";
        SoundService.instance.playWrong();
        
        // Hatalı cevapta soruyu atlamak yerine tekrar denemesi için geri bildirimi kapatıyoruz
        Future.delayed(const Duration(milliseconds: 1500), () {
           if (mounted) {
             setState(() {
               _showFeedback = false;
               _selectedAnswer = null;
             });
           }
        });
      }
    });
  }

  Future<void> _advanceLevel() async {
    if (_isFreeMode) {
      setState(() {
        _status = GameStatus.won;
      });
      return;
    }
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
 
      await _childRepo.updateLevel(widget.childId, _currentLevelIndex + 1);

      var updatedProfile = await _childRepo.getProfileById(widget.childId);
      
      bool unlocked = false;
      if (_currentLevelIndex + 1 < _levels.length) {
        final nextLevel = _levels[_currentLevelIndex + 1];
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
          // Not incrementing _currentLevelIndex here yet to keep header consistent
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
      backgroundColor: AppColors.cloudBlue, // New Background
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator()) 
        : SafeArea(
            child: Stack(
              alignment: Alignment.topCenter,
              children: [
                Column(
                  children: [
                    // Header Bar
                    _buildHeader(),
                    Expanded(
                      child: _buildContent(),
                    ),
                  ],
                ),
                ConfettiWidget(
                  confettiController: _confettiController,
                  blastDirectionality: BlastDirectionality.explosive,
                  shouldLoop: false,
                ),
              ],
            ),
          ),
    );
  }

  Widget _buildHeader() {
    
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          NeumorphicGameButton(
            width: 48,
            height: 48,
            borderRadius: 12,
            color: Colors.white,
            shadowColor: Colors.blueGrey.shade200,
            padding: EdgeInsets.zero,
            onPressed: _exitGame,
            child: const Icon(Icons.arrow_back_rounded, color: AppColors.cloudBlue, size: 28),
          ),
          const SizedBox(width: 12),
          
          Expanded(
            child: Column(
              children: [
                Text(
                  _isFreeMode ? _headerTitleForSelection(widget.operation!, widget.difficulty!) : 'MATEMATİK OYUNU',
                  style: const TextStyle(
                    fontFamily: 'Roboto',
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    letterSpacing: 1.0,
                    shadows: [
                      Shadow(color: Colors.black26, offset: Offset(2, 2), blurRadius: 4),
                    ],
                  ),
                ),
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: SizedBox(
                    height: 12,
                    width: 150,
                    child: LinearProgressIndicator(
                      value: (_status == GameStatus.levelUp || _status == GameStatus.won) 
                          ? 1.0 
                          : (_correctCount / _levelTarget).clamp(0.0, 1.0),
                      backgroundColor: Colors.white.withValues(alpha: 0.3),
                      valueColor: const AlwaysStoppedAnimation<Color>(AppColors.sunYellow),
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          if (!_isFreeMode)
            Container(
               padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
               decoration: BoxDecoration(
                 color: AppColors.orange,
                 borderRadius: BorderRadius.circular(20),
                 boxShadow: [
                   BoxShadow(color: AppColors.orangeShadow, offset: const Offset(0, 4), blurRadius: 0),
                 ],
               ),
               child: Text(
                 'SEVİYE ${_currentLevelIndex + 1}',
                 style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
               ),
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
      case GameStatus.lost:
        return _buildResultCard(
          title: _status == GameStatus.won ? 'Tebrikler!' : 'Yeniden Dene',
          message: _status == GameStatus.won 
              ? 'Bölümü fethettin! 👑' 
              : 'Hadi bir daha deneyelim!',
        );
    }
  }

  Widget _buildWelcomeCard() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
           Container(
             padding: const EdgeInsets.all(32),
             decoration: BoxDecoration(
               color: Colors.white,
               shape: BoxShape.circle,
               boxShadow: [
                 BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 30, offset: const Offset(0, 10)),
               ],
             ),
             child: Text(
               _childProfile?.avatarId ?? '🦊',
               style: const TextStyle(fontSize: 80),
             ),
           ),
           const SizedBox(height: 32),
           NeumorphicGameButton(
             color: AppColors.leafGreen,
             shadowColor: AppColors.leafGreenShadow,
             width: 200,
             height: 60,
             onPressed: _startGame,
             child: const Text('BAŞLA', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900)),
           ),
        ],
      ),
    );
  }

  Widget _buildGameCard() {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            const SizedBox(height: 20),
            
            // Question Text Direct on Background (Design Style)
            Text(
              'Ne kadar eder?',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white.withOpacity(0.9),
                shadows: [Shadow(color: Colors.black12, offset: Offset(1,1), blurRadius: 2)],
              ),
            ),
            const SizedBox(height: 20),
            
            // Big Question
            AnimatedBuilder(
              animation: _pulseController,
              builder: (context, child) {
                return Transform.scale(
                  scale: 1.0 + (_pulseController.value * 0.05),
                  child: child,
                );
              },
              child: Text(
                '$_num1 $_operator $_num2',
                style: const TextStyle(
                  fontSize: 80,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  shadows: [
                    Shadow(color: Colors.black26, offset: Offset(4, 4), blurRadius: 0), // Hard shadow
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 60),
            
            // Grid of Answers
            if (_answerOptions.isEmpty)
              const CircularProgressIndicator(color: Colors.white)
            else
              Column(
                children: [
                  Row(
                    children: [
                      Expanded(child: _buildAnswerButton(_answerOptions[0])),
                      const SizedBox(width: 20),
                      Expanded(child: _buildAnswerButton(_answerOptions[1])),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(child: _buildAnswerButton(_answerOptions[2])),
                      const SizedBox(width: 20),
                      Expanded(child: _buildAnswerButton(_answerOptions[3])),
                    ],
                  ),
                ],
              ),
              
              const SizedBox(height: 60),

            if (_feedbackMessage.isNotEmpty && _selectedAnswer != _answer)
              Padding(
                padding: const EdgeInsets.only(bottom: 20),
                child: Text(
                  _feedbackMessage,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.berryRed,
                  ),
                ),
              ),
            
            // CHECK Button (Green Pill)
            NeumorphicGameButton(
              color: AppColors.leafGreen,
              shadowColor: AppColors.leafGreenShadow,
              width: 200,
              height: 60,
              borderRadius: 30,
              onPressed: (_selectedAnswer != null && !_showFeedback) ? () => _checkAnswer(_selectedAnswer!) : null,
              child: const Text(
                'KONTROL ET',
                style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900),
              ), 
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnswerButton(int option) {
    // In design: Yellow buttons with numbers.
    // If selected/correct, change color.
    Color color = AppColors.sunYellow;
    Color shadow = AppColors.sunYellowShadow;
    
    if (_showFeedback) {
      if (option == _answer && _selectedAnswer == _answer) {
        color = AppColors.leafGreen;
        shadow = AppColors.leafGreenShadow;
      } else if (option == _selectedAnswer && _selectedAnswer != _answer) {
        color = AppColors.berryRed;
        shadow = AppColors.berryRedShadow;
      }
    } else if (_selectedAnswer == option) {
      color = AppColors.oceanBlue; // Selection state
      shadow = AppColors.oceanBlueShadow;
    }

    return NeumorphicGameButton(
      height: 90,
      color: color,
      shadowColor: shadow,
      borderRadius: 20,
      onPressed: _showFeedback ? null : () {
        setState(() {
          _selectedAnswer = option;
        });
      },
      child: Text(
        '$option',
        style: const TextStyle(
          fontSize: 40,
          fontWeight: FontWeight.w900,
          color: Colors.white, // In design it's white or dark grey
          shadows: [Shadow(color: Colors.black26, offset: Offset(2,2), blurRadius: 2)],
        ),
      ),
    );
  }
  
  Widget _buildResultCard({required String title, required String message}) {
    return Center(
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
            Text(title, style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: AppColors.oceanBlue)),
             const SizedBox(height: 24),
            Text(message, textAlign: TextAlign.center, style: const TextStyle(fontSize: 18, color: AppColors.gray)),
            const SizedBox(height: 32),
            NeumorphicGameButton(
              color: AppColors.oceanBlue,
              shadowColor: AppColors.oceanBlueShadow,
              width: 200, 
              height: 60,
              onPressed: _exitGame,
              child: const Text('TEKRAR OYNA', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }




  Widget _buildLevelUpCard() {
    if (_isFreeMode) {
      return _buildResultCard(title: 'Harika!', message: 'Seçtiğin modu başarıyla tamamladın! 🎉');
    }
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
           Container(
             padding: const EdgeInsets.all(32),
             decoration: BoxDecoration(
               color: Colors.white,
               shape: BoxShape.circle,
               boxShadow: [
                 BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 30, offset: const Offset(0, 10)),
               ],
             ),
             child: const Icon(Icons.star_rounded, size: 80, color: AppColors.sunYellow),
           ),
           const SizedBox(height: 32),
           Text(
             _isNextLevelUnlocked ? 'SEVİYE TAMAMLANDI!' : 'BÖLÜM BİTTİ!',
             style: const TextStyle(
               fontSize: 28,
               fontWeight: FontWeight.w900,
               color: Colors.white,
             ),
           ),
           const SizedBox(height: 16),
           if (!_isNextLevelUnlocked)
             const Padding(
               padding: EdgeInsets.symmetric(horizontal: 24),
               child: Text(
                 'Sıradaki seviye için biraz daha puan toplamalısın!',
                 textAlign: TextAlign.center,
                 style: TextStyle(fontSize: 16, color: Colors.white70, fontWeight: FontWeight.bold),
               ),
             ),
           if (_lastLevelGift > 0)
             Text(
               '+$_lastLevelGift Puan Hediye!',
               style: const TextStyle(fontSize: 20, color: AppColors.sunYellow, fontWeight: FontWeight.bold),
             ),
           const SizedBox(height: 32),
           NeumorphicGameButton(
             color: AppColors.oceanBlue,
             shadowColor: AppColors.oceanBlueShadow,
             width: 200,
             height: 60,
             onPressed: _isNextLevelUnlocked 
                ? () {
                    setState(() {
                      _currentLevelIndex++;
                      _status = GameStatus.playing;
                      _correctCount = 0;
                      _wrongCount = 0;
                      _comboCount = 0;
                      _feedbackMessage = '';
                      _levelTarget = min(5 + (_currentLevelIndex * 2), 15);
                      _generateQuestion();
                    });
                  }
                : _exitGame,
             child: Text(
               _isNextLevelUnlocked ? 'SONRAKİ SEVİYE' : 'MENÜYE DÖN',
               style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900),
             ),
           ),
        ],
      ),
    );
  }

  List<QuestionRule> _buildRulesForSelection(String operation, String difficulty) {
    switch (difficulty) {
      case 'kolay':
        return [
          QuestionRule(levelId: 0, operation: operation, minOperand: 1, maxOperand: 9, allowNegative: false),
        ];
      case 'orta':
        return [
          QuestionRule(levelId: 0, operation: operation, minOperand: 10, maxOperand: 99, allowNegative: false),
        ];
      case 'zor':
        return [
          QuestionRule(levelId: 0, operation: operation, minOperand: 100, maxOperand: 999, allowNegative: false),
        ];
      default:
        return [
          QuestionRule(levelId: 0, operation: operation, minOperand: 1, maxOperand: 9, allowNegative: false),
        ];
    }
  }

  int _targetForDifficulty(String difficulty) {
    switch (difficulty) {
      case 'kolay':
        return 5;
      case 'orta':
        return 7;
      case 'zor':
        return 10;
      default:
        return 5;
    }
  }

  String _headerTitleForSelection(String operation, String difficulty) {
    final opText = switch (operation) {
      '+' => 'Toplama',
      '-' => 'Çıkarma',
      '*' => 'Çarpma',
      '/' => 'Bölme',
      _ => 'Matematik'
    };
    final diffText = switch (difficulty) {
      'kolay' => 'Kolay',
      'orta' => 'Orta',
      'zor' => 'Zor',
      _ => ''
    };
    return '$opText • $diffText';
  }
}
