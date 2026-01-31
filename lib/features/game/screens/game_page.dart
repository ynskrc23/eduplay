import 'dart:math';
import 'package:flutter/material.dart';
import 'package:confetti/confetti.dart';



class GamePage extends StatefulWidget {
  const GamePage({super.key});

  @override
  State<GamePage> createState() => _GamePageState();
}

enum GameStatus { welcome, playing, won, lost }

class _GamePageState extends State<GamePage> {
  GameStatus _status = GameStatus.welcome;
  int _correctCount = 0;
  int _wrongCount = 0;
  
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
  }

  @override
  void dispose() {
    _confettiController.dispose();
    _inputController.dispose();
    super.dispose();
  }

  void _startGame() {
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
    int opIndex = _random.nextInt(4); // 0: +, 1: -, 2: *, 3: /
    
    switch (opIndex) {
      case 0:
        _operator = '+';
        _num1 = _random.nextInt(50) + 1;
        _num2 = _random.nextInt(50) + 1;
        _answer = _num1 + _num2;
        break;
      case 1:
        _operator = '-';
        _num1 = _random.nextInt(50) + 1;
        _num2 = _random.nextInt(_num1) + 1; // Ensure non-negative roughly
        _answer = _num1 - _num2;
        break;
      case 2:
        _operator = 'x';
        _num1 = _random.nextInt(12) + 1;
        _num2 = _random.nextInt(12) + 1;
        _answer = _num1 * _num2;
        break;
      case 3:
        _operator = '/';
        _num2 = _random.nextInt(10) + 2; // Divisor between 2 and 11
        _answer = _random.nextInt(10) + 1; // Result between 1 and 10
        _num1 = _num2 * _answer;
        break;
    }
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
        _feedbackMessage = 'Doğru! 🎉';
        if (_correctCount >= 5) {
          _status = GameStatus.won;
          _confettiController.play();
        } else {
          _confettiController.play();
          _generateQuestion();
        }
      } else {
        _wrongCount++;
        _feedbackMessage = 'Yanlış! Cevap $_answer olacaktı.';
        if (_wrongCount >= 3) {
          _status = GameStatus.lost;
        } else {
          _generateQuestion();
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
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
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: _buildContent(),
                ),
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
              'Hoşgeldin!',
              style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.indigo.shade900,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Matematik bilgini test etmeye hazır mısın?\n5 doğru yapan kazanır,\n3 yanlış yapan elenir.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: Colors.black54),
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
              const SizedBox(width: 16),
              _buildScoreChip('Yanlış', _wrongCount, 3, Colors.red),
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
                    'Soru',
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
