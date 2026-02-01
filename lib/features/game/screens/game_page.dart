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
    SoundService.instance.startBgMusic();
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
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.indigo.shade900,
                  Colors.deepPurple.shade700,
                  Colors.purple.shade500,
                ],
              ),
            ),
            child: SafeArea(
              child: Column(
                children: [
                  // Simplified Header Bar
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Child Info
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 20,
                              backgroundColor: Colors.white,
                              child: Text(
                                _childProfile?.avatarId ?? '👤',
                                style: const TextStyle(fontSize: 20),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _childProfile?.name ?? 'Oyuncu',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w900,
                                    fontSize: 16,
                                  ),
                                ),
                                Text(
                                  'Puan: ${_childProfile?.totalScore ?? 0}',
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.8),
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        Row(
                          children: [
                            IconButton(
                              onPressed: _exitGame,
                              icon: const Icon(Icons.close_rounded, color: Colors.white, size: 28),
                              tooltip: 'Çıkış',
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  Expanded(
                    child: Align(
                      alignment: Alignment.topCenter,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24.0),
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
    return Card(
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.school_rounded, size: 80, color: Colors.indigo),
            const SizedBox(height: 24),
            Text(
              _childProfile != null ? 'Merhaba, ${_childProfile!.name}!' : (_game?.name ?? 'Hoşgeldin!'),
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.indigo.shade900,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Eğlenerek öğrenmeye hazır mısın?\nHer 5 doğru cevapta yeni bir macera seni bekliyor! 🚀',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 18, color: Colors.black54, height: 1.5),
            ),
            const SizedBox(height: 48),
            FilledButton.icon(
              onPressed: _startGame,
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              icon: const Icon(Icons.play_arrow_rounded),
              label: const Text('Oyuna Başla'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGameCard() {
    int target = min(5 + (_currentLevelIndex * 2), 15);
    double progress = _correctCount / target;

    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Progress Bar (Reduced Padding)
          Padding(
            padding: const EdgeInsets.only(left: 32, right: 32, top: 8),
            child: Column(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 12,
                    backgroundColor: Colors.white24,
                    valueColor: const AlwaysStoppedAnimation<Color>(Colors.greenAccent),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Hedef: $_correctCount / $target',
                  style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 20),

          // Combo Meter
          if (_comboCount > 1)
            TweenAnimationBuilder(
              tween: Tween<double>(begin: 0.8, end: 1.2),
              duration: const Duration(milliseconds: 200),
              builder: (context, value, child) {
                return Transform.scale(
                  scale: value,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.orange,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [BoxShadow(color: Colors.orange.withOpacity(0.5), blurRadius: 10)],
                    ),
                    child: Text(
                      '🔥 $_comboCount KOMBO! 🔥',
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 18),
                    ),
                  ),
                );
              },
            ),
          
          const SizedBox(height: 20),
          
          Card(
            elevation: 12,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            child: Padding(
              padding: const EdgeInsets.all(32.0),
              child: Column(
                children: [
                  Text(
                    'Soru (Seviye ${_currentLevelIndex + 1})',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '$_num1 $_operator $_num2 = ?',
                    style: TextStyle(
                      fontSize: 44,
                      fontWeight: FontWeight.w900,
                      color: Colors.indigo.shade900,
                      shadows: [
                        Shadow(color: Colors.indigo.withOpacity(0.2), offset: const Offset(2, 2), blurRadius: 4),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  TextField(
                    controller: _inputController,
                    keyboardType: TextInputType.number,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.indigo),
                    decoration: InputDecoration(
                      hintText: '?',
                      filled: true,
                      fillColor: Colors.indigo.withOpacity(0.05),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    onSubmitted: (_) => _checkAnswer(),
                  ),
                  const SizedBox(height: 24),
                  if (_feedbackMessage.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: TweenAnimationBuilder(
                        tween: Tween<double>(begin: 0, end: 1),
                        duration: const Duration(milliseconds: 300),
                        builder: (context, value, child) {
                          return Opacity(
                            opacity: value,
                            child: Transform.translate(
                              offset: Offset(0, 10 * (1 - value)),
                              child: Text(
                                _feedbackMessage,
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w900,
                                  color: _feedbackMessage.startsWith('Doğru') || _feedbackMessage.contains('! ')
                                      ? Colors.green.shade600
                                      : Colors.red.shade600,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  SizedBox(
                    width: double.infinity,
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(color: Colors.indigo.withOpacity(0.3), blurRadius: 12, offset: const Offset(0, 6)),
                        ],
                      ),
                      child: FilledButton(
                        onPressed: _checkAnswer,
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 20),
                          backgroundColor: Colors.indigo,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                        child: const Text('Yanıtla', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
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

  return Card(
    elevation: 8,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
    child: Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            _isNextLevelUnlocked ? Icons.stars_rounded : Icons.info_outline_rounded, 
            size: 64, 
            color: _isNextLevelUnlocked ? Colors.amber : Colors.blue
          ),
          const SizedBox(height: 16),
          Text(
            _isNextLevelUnlocked ? 'Harika İş! 🌟' : 'Bölüm Tamam! 🚩',
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: Colors.indigo),
          ),
          const SizedBox(height: 24),
          
          // Simplified Bonus Row (Transparent/Clean)
          if (_lastComboBonus > 0 || _lastLevelGift > 0)
            Padding(
              padding: const EdgeInsets.only(bottom: 24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (_lastComboBonus > 0)
                    _buildBonusBadge('🔥 $_lastComboBonus Kombo'),
                  if (_lastComboBonus > 0 && _lastLevelGift > 0)
                    const SizedBox(width: 12),
                  if (_lastLevelGift > 0)
                    _buildBonusBadge('🎁 $_lastLevelGift Hediye'),
                ],
              ),
            ),

          Text(
            _isNextLevelUnlocked 
                ? 'Seviye ${nextLevel + 1} Sizi Bekliyor!'
                : 'Sonraki Seviye İçin $unlockScoreNeeded Puan Lazım.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16, color: Colors.grey.shade700, fontWeight: FontWeight.w600),
          ),
          
          const SizedBox(height: 32),
          
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TextButton(
                onPressed: _exitGame,
                child: const Text('Anasayfa', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
              const SizedBox(width: 12),
              FilledButton(
                onPressed: _startGame,
                style: FilledButton.styleFrom(
                  backgroundColor: _isNextLevelUnlocked ? Colors.green : Colors.indigo,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: Text(_isNextLevelUnlocked ? 'Devam Et 🚀' : 'Tekrar Oyna 🔄'),
              ),
            ],
          ),
        ],
      ),
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
    return Card(
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.all(40.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 64, color: color),
            ),
            const SizedBox(height: 24),
            Text(
              title,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 18, color: Colors.black87),
            ),
            const SizedBox(height: 48),
            FilledButton.icon(
              onPressed: () {
                if (title == 'Tebrikler!') {
                  // If won and more levels exist, go to next level or map
                  _exitGame();
                } else {
                  _startGame();
                }
              },
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                backgroundColor: color,
                foregroundColor: Colors.white,
              ),
              icon: Icon(title == 'Tebrikler!' ? Icons.arrow_forward_rounded : Icons.refresh_rounded),
              label: Text(title == 'Tebrikler!' ? 'Devam Et' : 'Tekrar Oyna'),
            ),
          ],
        ),
      ),
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
