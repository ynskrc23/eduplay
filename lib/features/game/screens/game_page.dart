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

class GamePage extends StatefulWidget {
  final int childId;
  const GamePage({super.key, required this.childId});

  @override
  State<GamePage> createState() => _GamePageState();
}

enum GameStatus { welcome, playing, won, levelUp, lost }

class _GamePageState extends State<GamePage> {
  GameStatus _status = GameStatus.welcome;
  int _correctCount = 0;
  // ignore: unused_field
  int _wrongCount = 0;
  
  // Game Data
  // Game Data
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
           // Get starting level index from profile
           final startLevelIndex = profile.currentLevel;
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
               _isLoading = false;
             });
           }
           return;
        }
      }
    } catch (e) {
      debugPrint('Error loading game data: $e');
    }
    
    // If loading fails, we might show an error or remain loading.
    if (mounted) {
      setState(() {
        _isLoading = false; // Stop loading even if failed, maybe show error UI later
      });
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
        _feedbackMessage = 'Doğru! Harikasın! 🌟';
        _confettiController.play();
        SoundService.instance.playCorrect();
        
        // Update Score (+10 points)
        _childRepo.updateScore(widget.childId, 10);
        
        // Instant update in UI
        if (_childProfile != null) {
          _childProfile = _childProfile!.copyWith(
            totalScore: _childProfile!.totalScore + 10,
          );
        }

        // Level Progression Condition
        if (_correctCount >= 5) {
          _advanceLevel();
        } else {
          // Delay briefly to allow sound/feedback/confetti
          Future.delayed(const Duration(milliseconds: 800), () {
             if (mounted && _status == GameStatus.playing) _generateQuestion();
          });
        }
      } else {
        _wrongCount++; // Just for analytics, no penalty
        _feedbackMessage = 'Tekrar dene bakalım! 💪';
        SoundService.instance.playWrong();
        // Do not generate new question, let them retry
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

    // Check if there are more levels
    if (_currentLevelIndex + 1 < _levels.length) {
      _currentLevelIndex++;
      
      // Save progress to DB
      await _childRepo.updateLevel(widget.childId, _currentLevelIndex);

      _status = GameStatus.levelUp;
      _isLoading = false; 
      _feedbackMessage = ''; 
    } else {
      // No more levels - Game Won!
      setState(() {
        _status = GameStatus.won;
      });
    }

    // After celebration, go back to Welcome Screen (Home)
    Future.delayed(const Duration(seconds: 4), () {
      if (mounted && _status == GameStatus.levelUp) {
        _exitGame();
      }
    });
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

    setState(() {
      _status = GameStatus.welcome;
      _correctCount = 0;
      _wrongCount = 0;
      _feedbackMessage = '';
    });
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
                  // Header Bar
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Child Info
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.2),
                                shape: BoxShape.circle,
                              ),
                              child: Text(
                                _childProfile?.avatarId ?? '👤',
                                style: const TextStyle(fontSize: 24),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _childProfile?.name ?? 'Oyuncu',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                Text(
                                  'Puan: ${_childProfile?.totalScore ?? 0}',
                                  style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.8),
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        
                          // Settings Button (Parent Gate)
                        Row(
                          children: [
                            if (_status != GameStatus.welcome)
                              IconButton(
                                onPressed: _exitGame,
                                icon: const Icon(Icons.exit_to_app_rounded, color: Colors.white70),
                                tooltip: 'Çıkış',
                              ),
                            IconButton(
                              onPressed: _showParentGate,
                              icon: const Icon(Icons.settings_rounded, color: Colors.white),
                              tooltip: 'Ebeveyn Paneli',
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  Expanded(
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24.0),
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
          message: '5 soruyu doğru bildin ve oyunu kazandın! 🏆',
          icon: Icons.emoji_events_rounded,
          color: Colors.amber,
        );
      case GameStatus.lost:
        return _buildResultCard(
          title: 'Elendin',
          message: '3 yanlış cevap verdin. Bir dahaki sefere! 😔',
          icon: Icons.mood_bad_rounded,
          color: Colors.redAccent,
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
    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Score Header
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildScoreChip('Doğru', _correctCount, 5, Colors.green),
            ],
          ),
          const SizedBox(height: 32),
          
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
                    style: const TextStyle(
                      fontSize: 48,
                      fontWeight: FontWeight.w900,
                      color: Colors.indigo,
                    ),
                  ),
                  const SizedBox(height: 32),
                  TextField(
                    controller: _inputController,
                    keyboardType: TextInputType.number,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
                    decoration: InputDecoration(
                      hintText: '?',
                      filled: true,
                      fillColor: Colors.grey.shade100,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
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
                      child: Text(
                        _feedbackMessage,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: _feedbackMessage.startsWith('Doğru') 
                              ? Colors.green 
                              : Colors.red,
                        ),
                      ),
                    ),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: _checkAnswer,
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: const Text('Yanıtla', style: TextStyle(fontSize: 20)),
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
        color: Colors.white.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(
            label == 'Doğru' ? Icons.check_circle : Icons.cancel,
            color: color.withValues(alpha: 0.9), // Keeping it visible on dark bg
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
    return Card(
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 64, horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.rocket_launch_rounded, size: 100, color: Colors.orange),
            const SizedBox(height: 32),
            Text(
              'MUHTEŞEM! 🌟',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.w900,
                color: Colors.orange.shade800,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Seviye $_currentLevelIndex tamamlandı.\nŞimdi Seviye ${_currentLevelIndex + 1} zamanı!',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 48),
            FilledButton(
              onPressed: _exitGame,
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 20),
                backgroundColor: Colors.orange,
              ),
              child: const Text('Anasayfaya Dön 🏠', style: TextStyle(fontSize: 20)),
            ),
          ],
        ),
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
                color: color.withValues(alpha: 0.1),
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
              onPressed: _startGame,
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                backgroundColor: color,
                foregroundColor: Colors.white,
              ),
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Tekrar Oyna'),
            ),
          ],
        ),
      ),
    );
  }



  void _showParentGate() {
    final num1 = _random.nextInt(5) + 3; // 3 to 7
    final num2 = _random.nextInt(5) + 3; // 3 to 7
    final answer = num1 * num2;
    final controller = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Ebeveyn Kilidi'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Devam etmek için işlemi çözün:'),
            const SizedBox(height: 16),
            Text(
              '$num1 x $num2 = ?',
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              autofocus: true,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'Sonuç',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('İptal'),
          ),
          FilledButton(
            onPressed: () {
              if (int.tryParse(controller.text) == answer) {
                Navigator.pop(context);
                _showParentPanel();
              } else {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Yanlış cevap! Erişim reddedildi.')),
                );
              }
            },
            child: const Text('Giriş'),
          ),
        ],
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
