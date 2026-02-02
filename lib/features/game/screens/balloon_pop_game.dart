import 'dart:math';
import 'package:flutter/material.dart';
import 'package:confetti/confetti.dart';
import '../../../core/app_colors.dart';
import '../../../core/widgets/duo_button.dart';
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

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(duration: const Duration(seconds: 1));
    _generateRound();
  }

  void _generateRound() {
    _targetNumber = _random.nextInt(15) + 1;
    Set<int> ops = {_targetNumber};
    // Ensure 5 unique numbers
    while(ops.length < 5) {
      int nextVal = _random.nextInt(30) + 1;
      if (nextVal != _targetNumber) ops.add(nextVal);
    }
    
    List<int> numbers = ops.toList()..shuffle();
    double segmentWidth = 0.8 / numbers.length;
    
    setState(() {
      _balloons = numbers.asMap().entries.map((entry) {
        int idx = entry.key;
        int n = entry.value;
        return _BalloonData(
          number: n,
          color: [
            const Color(0xFFFF5252), // Red
            const Color(0xFF448AFF), // Blue
            const Color(0xFF4CAF50), // Green
            const Color(0xFFFFAB40), // Orange
            const Color(0xFFE040FB), // Purple
          ][_random.nextInt(5)],
          x: 0.1 + (idx * segmentWidth) + (segmentWidth * 0.2),
          y: 1.2, // Same start for sync
          speed: 0.005 + (_random.nextDouble() * 0.002), // Faster speed
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
      // Only shake or give feedback, don't pop wrong balloons as requested: "sadece doğru olan balon patlasın"
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
      setState(() {
         _isGameFinished = true;
      });
    }
  }

  bool _isGameFinished = false;

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text('HARİKA!', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.w900, color: AppColors.orange)),
        content: const Text('Tüm balonları uçurdun! 🎈', textAlign: TextAlign.center),
        actions: [
          DuoButton(
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
      backgroundColor: Colors.lightBlue.shade50, // Sky background
      body: SafeArea(
        child: Stack(
          children: [
            // Floating Balloons
            ..._balloons.map((b) => _buildAnimatedBalloon(b)),

            // UI Overlay
            Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close, color: AppColors.gray),
                      ),
                      Expanded(child: DuoProgressBar(value: _round / _totalRounds)),
                    ],
                  ),
                ),
                Center(
                  child: Container(
                    margin: const EdgeInsets.only(top: 10),
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    decoration: BoxDecoration(
                      color: AppColors.white,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        const BoxShadow(
                          color: Color(0x33000000),
                          offset: Offset(0, 4),
                        ),
                        BoxShadow(
                          color: AppColors.purpleDark.withOpacity(0.3),
                          offset: const Offset(0, 8),
                          blurRadius: 15,
                        ),
                      ],
                      border: Border.all(color: AppColors.purpleDark.withOpacity(0.1), width: 2),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.purpleLight.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.flash_on_rounded, color: AppColors.gold, size: 24),
                        ),
                        const SizedBox(width: 16),
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'HEDEF SAYI',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w900,
                                color: AppColors.gray,
                                letterSpacing: 1.5,
                              ),
                            ),
                            Text(
                              '$_targetNumber',
                              style: const TextStyle(
                                fontSize: 40,
                                fontWeight: FontWeight.w900,
                                color: AppColors.purpleDark,
                                height: 1,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(width: 8),
                      ],
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
      color: Colors.white,
      width: double.infinity,
      height: double.infinity,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
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
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.gray,
            ),
          ),
          const SizedBox(height: 48),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 48),
            child: DuoButton(
              color: AppColors.orange,
              shadowColor: AppColors.orangeShadow,
              onPressed: () => Navigator.pop(context),
              child: const Text(
                'DEVAM ET',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 18),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnimatedBalloon(_BalloonData balloon) {
    if (balloon.isPopped) return const SizedBox.shrink();

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: balloon.y, end: -0.2),
      duration: Duration(milliseconds: (1 / balloon.speed).toInt() * 100),
      builder: (context, value, child) {
        return Align(
          alignment: Alignment(balloon.x * 2 - 1, value * 2 - 1),
          child: GestureDetector(
            onTap: () => _onBalloonPop(balloon),
            child: Container(
              width: 90,
              height: 110,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Balloon Shape
                  Container(
                    decoration: BoxDecoration(
                      color: balloon.color,
                      borderRadius: const BorderRadius.all(Radius.elliptical(90, 110)),
                      boxShadow: [
                        BoxShadow(color: balloon.color.withOpacity(0.4), blurRadius: 10, offset: const Offset(4, 4))
                      ],
                    ),
                  ),
                  // Balloon String
                  Positioned(
                    bottom: 0,
                    child: Container(width: 2, height: 20, color: Colors.grey.shade400),
                  ),
                  // Number
                  Text(
                    '${balloon.number}',
                    style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w900),
                  ),
                ],
              ),
            ),
          ),
        );
      },
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
