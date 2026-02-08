import 'dart:math';
import 'package:flutter/material.dart';
import 'package:confetti/confetti.dart';
import '../../../core/app_colors.dart';
import '../../../core/widgets/neumorphic_game_button.dart';
import '../../../core/widgets/duo_progress_bar.dart';
import '../../../core/services/sound_service.dart';

class BalloonPopGame extends StatefulWidget {
  final int childId;
  const BalloonPopGame({super.key, required this.childId});

  @override
  State<BalloonPopGame> createState() => _BalloonPopGameState();
}

class _BalloonPopGameState extends State<BalloonPopGame> with TickerProviderStateMixin {
  late ConfettiController _confettiController;
  final Random _random = Random();
  
  late int _targetNumber;
  List<_BalloonData> _balloons = [];
  int _round = 1;
  final int _totalRounds = 5;
  bool _isGameFinished = false;

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(duration: const Duration(seconds: 1));
    _generateRound();
  }

  void _generateRound() {
    _targetNumber = _random.nextInt(15) + 1;
    Set<int> ops = {_targetNumber};
    // 4 benzersiz sayı oluştur (Sayılar arası mesafeyi artırmak için balon sayısını azalttık)
    while(ops.length < 4) {
      int nextVal = _random.nextInt(30) + 1;
      if (nextVal != _targetNumber) ops.add(nextVal);
    }
    
    List<int> numbers = ops.toList()..shuffle();
    double segmentWidth = 1.0 / numbers.length;
    
    List<Color> availableColors = [
      AppColors.berryRed,
      AppColors.oceanBlue,
      AppColors.leafGreen,
      AppColors.orange,
      AppColors.violetMain,
      AppColors.sunYellow,
    ]..shuffle();
    
    setState(() {
      _balloons = numbers.asMap().entries.map((entry) {
        int idx = entry.key;
        int n = entry.value;
        return _BalloonData(
          number: n,
          color: availableColors[idx % availableColors.length],
          x: (idx + 0.5) * segmentWidth, // Ekran geneline daha dengeli yayılım
          y: 1.2, // Start from bottom
          speed: 0.003 + (_random.nextDouble() * 0.0015), // Hız düşürüldü
        );
      }).toList();
    });
  }

  void _onBalloonPop(_BalloonData balloon) {
    if (balloon.isPopped) return;

    if (balloon.number == _targetNumber) {
      SoundService.instance.playCorrect();
      _confettiController.play();
      setState(() {
        balloon.isPopped = true;
        // Clear other balloons to prepare for next round
        for (var b in _balloons) {
          if (b != balloon) b.isPopped = true;
        }
      });
      _nextRound();
    } else {
      SoundService.instance.playWrong();
    }
  }

  void _nextRound() {
    if (_round < _totalRounds) {
      Future.delayed(const Duration(seconds: 1), () {
        if (mounted) {
          setState(() {
             _round++;
             _generateRound();
          });
        }
      });
    } else {
       Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) {
          setState(() {
            _isGameFinished = true;
          });
        }
      });
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text('HARİKA!', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.w900, color: AppColors.orange)),
        content: const Text('Tüm balonları uçurdun! 🎈', textAlign: TextAlign.center),
        actions: [
          NeumorphicGameButton(
            color: AppColors.orange,
            shadowColor: AppColors.orangeShadow,
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: const Text('TAMAM', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cloudBlue, // New Background
      body: SafeArea(
        child: Stack(
          children: [
            // Floating Balloons
            ..._balloons.map((b) => _buildAnimatedBalloon(b)), 

            // UI Overlay
            Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                  child: Row(
                    children: [
                      NeumorphicGameButton(
                        width: 48,
                        height: 48,
                        borderRadius: 12,
                        color: Colors.white,
                        shadowColor: Colors.blueGrey.shade200,
                        padding: EdgeInsets.zero,
                        onPressed: () => Navigator.pop(context),
                        child: const Icon(Icons.arrow_back_rounded, color: AppColors.cloudBlue, size: 28),
                      ),
                      const SizedBox(width: 16),
                      const Expanded(
                        child: Text(
                          'BALON PATLATMA',
                          textAlign: TextAlign.center,
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
                      const SizedBox(width: 16),
                      const SizedBox(width: 48), // Denge için boşluk
                    ],
                  ),
                ),
                
                const SizedBox(height: 10),
                
                // Progress Bar
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: SizedBox(
                      height: 12,
                      child: LinearProgressIndicator(
                        value: _round / _totalRounds,
                        backgroundColor: Colors.white.withOpacity(0.3),
                        valueColor: const AlwaysStoppedAnimation<Color>(AppColors.sunYellow),
                      ),
                    ),
                  ),
                ),
                
                const SizedBox(height: 20),
                
                // Target Number Display
                Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(30),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          offset: const Offset(0, 8),
                          blurRadius: 10,
                        ),
                      ],
                    ),
                    child: Text(
                      '$_targetNumber',
                      style: const TextStyle(
                        fontSize: 60,
                        fontWeight: FontWeight.w900,
                        color: AppColors.purpleDark,
                        height: 1,
                        shadows: [
                          Shadow(color: Colors.black12, offset: Offset(2, 2), blurRadius: 0),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            
            if (_isGameFinished) _buildResultCard(),
            
            Align(
              alignment: Alignment.center,
              child: ConfettiWidget(
                confettiController: _confettiController,
                blastDirectionality: BlastDirectionality.explosive,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultCard() {
    return Container(
      color: Colors.black54,
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
              const Text(
                'MÜKEMMEL!',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w900,
                  color: AppColors.orange,
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                '🎈⚡',
                style: TextStyle(fontSize: 80),
              ),
              const SizedBox(height: 24),
              const Text(
                'Hepsini ustalıkla patlattın!',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.gray,
                ),
              ),
              const SizedBox(height: 48),
              NeumorphicGameButton(
                color: AppColors.orange,
                shadowColor: AppColors.orangeShadow,
                width: 200,
                height: 60,
                onPressed: () => Navigator.pop(context),
                child: const Text(
                  'DEVAM ET',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 18),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAnimatedBalloon(_BalloonData balloon) {
    if (balloon.isPopped) return const SizedBox.shrink();

    return TweenAnimationBuilder<double>(
      key: ValueKey('${balloon.number}_${balloon.x}'), 
      tween: Tween(begin: 1.2, end: -0.3),
      duration: Duration(milliseconds: (1 / balloon.speed).toInt() * 80), 
      builder: (context, value, child) {
        return Align(
          alignment: Alignment(balloon.x * 2 - 1, value * 2 - 1),
          child: child,
        );
      },
      child: GestureDetector(
        onTap: () => _onBalloonPop(balloon),
        child: Container(
          width: 90,
          height: 110,
          decoration: BoxDecoration(
            gradient: RadialGradient(
              center: const Alignment(-0.3, -0.3),
              radius: 0.8,
              colors: [
                Color.alphaBlend(Colors.white.withOpacity(0.4), balloon.color),
                balloon.color,
                Color.alphaBlend(Colors.black.withOpacity(0.2), balloon.color),
              ],
            ),
            borderRadius: const BorderRadius.all(Radius.elliptical(90, 110)),
            boxShadow: [
              BoxShadow(color: balloon.color.withOpacity(0.4), blurRadius: 10, offset: const Offset(4, 4))
            ],
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Reflection shine
              Positioned(
                top: 15,
                left: 20,
                child: Container(
                  width: 15,
                  height: 25,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.3),
                    borderRadius: const BorderRadius.all(Radius.elliptical(15, 25)),
                  ),
                ),
              ),
              // Tie at bottom
              Positioned(
                bottom: -2,
                child: Column(
                  children: [
                    Container(width: 6, height: 6, color: balloon.color),
                    Container(width: 2, height: 40, color: Colors.white60),
                  ],
                ),
              ),
              // Number
              Text(
                '${balloon.number}',
                style: const TextStyle(
                  color: Colors.white, 
                  fontSize: 32, 
                  fontWeight: FontWeight.w900,
                  shadows: [Shadow(color: Colors.black26, offset: Offset(1,1), blurRadius: 2)],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BalloonData {
  final int number;
  final Color color;
  final double x;
  final double y;
  final double speed;
  bool isPopped = false;

  _BalloonData({
    required this.number,
    required this.color,
    required this.x,
    required this.y,
    required this.speed,
  });
}
