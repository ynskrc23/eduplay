import 'dart:math';
import 'package:flutter/material.dart';
import 'package:confetti/confetti.dart';
import '../../../core/app_colors.dart';
import '../../../core/widgets/neumorphic_game_button.dart';
import '../../../core/services/sound_service.dart';
import '../../../data/models/game_session.dart';
import '../../../data/repositories/game_session_repository.dart';
import '../../../data/repositories/game_repository.dart';
import '../../../data/models/game.dart';

class NumberOrderingGame extends StatefulWidget {
  final int childId;
  const NumberOrderingGame({super.key, required this.childId});

  @override
  State<NumberOrderingGame> createState() => _NumberOrderingGameState();
}

class _NumberOrderingGameState extends State<NumberOrderingGame> {
  late ConfettiController _confettiController;
  final Random _random = Random();
  
  List<int> _currentNumbers = [];
  List<int> _userSelection = [];
  String _errorText = '';
  int _round = 1;
  final int _totalRounds = 5;
  bool _isGameFinished = false;

  final GameSessionRepository _sessionRepo = GameSessionRepository();
  final GameRepository _gameRepo = GameRepository();
  int? _currentSessionId;
  int _correctCount = 0;
  int _wrongCount = 0;
  bool _roundMistakeMade = false;
  DateTime? _startedAt;
  Game? _game;

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(duration: const Duration(seconds: 1));
    _initSession();
    _generateRound();
  }

  Future<void> _initSession() async {
    _startedAt = DateTime.now();
    _game = await _gameRepo.getGameByCode('NUMBER_ORDERING');
    final gameId = _game?.id ?? 1;

    final session = GameSession(
      childId: widget.childId,
      gameId: gameId,
      levelId: 1, 
      startedAt: _startedAt!,
    );
    _currentSessionId = await _sessionRepo.createSession(session);
  }

  Future<void> _endSession() async {
    if (_currentSessionId != null) {
      await _sessionRepo.updateSessionEnd(
        _currentSessionId!,
        DateTime.now(),
        _correctCount,
        _wrongCount,
      );
      _currentSessionId = null;
    }
  }

  void _generateRound() {
    int count = 3 + (_round ~/ 2); // Start with 3, increase as rounds go
    int maxVal = 10 * _round;
    
    Set<int> nums = {};
    while(nums.length < count) {
      nums.add(_random.nextInt(maxVal) + 1);
    }
    
    setState(() {
      _currentNumbers = nums.toList()..shuffle();
      _userSelection = [];
      _roundMistakeMade = false;
    });
  }

  void _onNumberDrop(int num) {
    if (_isGameFinished) return;
    
    List<int> sorted = List.from(_currentNumbers)..sort();
    int nextCorrect = sorted[_userSelection.length];

    if (num == nextCorrect) {
      setState(() {
        _userSelection.add(num);
        _errorText = '';
      });
      SoundService.instance.playCorrect();

      if (_userSelection.length == _currentNumbers.length) {
        _correctCount++;
        _confettiController.play();
        _nextRound();
      }
    } else {
      if (!_roundMistakeMade) {
        _wrongCount++;
        _roundMistakeMade = true;
      }
      SoundService.instance.playWrong();
      setState(() {
        _errorText = 'Yanlış Sıra!';
      });
      Future.delayed(const Duration(seconds: 1), () {
        if (mounted) setState(() => _errorText = '');
      });
    }
  }

  void _nextRound() {
    if (_round < _totalRounds) {
      Future.delayed(const Duration(seconds: 1), () {
        if (mounted) {
          setState(() => _round++);
          _generateRound();
        }
      });
    } else {
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) {
          setState(() {
             _isGameFinished = true;
          });
          _endSession();
        }
      });
    }
  }

  Color _getNumberColor(int n) {
    // Cycle through vibrant colors based on number value
    final colors = [
      AppColors.sunYellow,
      AppColors.leafGreen,
      AppColors.berryRed,
      AppColors.oceanBlue,
      AppColors.violetMain,
      AppColors.orange,
    ];
    return colors[n % colors.length];
  }

  Color _getNumberShadowColor(int n) {
    final shadows = [
      AppColors.sunYellowShadow,
      AppColors.leafGreenShadow,
      AppColors.berryRedShadow,
      AppColors.oceanBlueShadow,
      AppColors.purpleDark,
      AppColors.orangeShadow,
    ];
    return shadows[n % shadows.length];
  }

  @override
  void dispose() {
    _endSession();
    _confettiController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cloudBlue, // New Background
      body: SafeArea(
        bottom: false,
        child: Stack(
          children: [
            // Background patterns (Clouds) could go here
            
            Column(
              children: [
                // HEADER
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
                      Expanded(
                        child: Text(
                          'SAYI SIRALAMA',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                color: Colors.white,
                                shadows: [Shadow(color: Colors.black.withValues(alpha: 0.26), offset: const Offset(2, 2), blurRadius: 4)],
                              ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      const SizedBox(width: 48), // Empty space to balance the back button
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
                        backgroundColor: Colors.white.withValues(alpha: 0.3),
                        valueColor: const AlwaysStoppedAnimation<Color>(AppColors.sunYellow),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // Question / Instruction Area
                Text(
                  'Küçükten büyüğe sırala ve kazan!',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: Colors.white,
                        shadows: [Shadow(color: Colors.black.withValues(alpha: 0.12), offset: const Offset(1, 1), blurRadius: 2)],
                      ),
                ),

                // Error Message
                SizedBox(
                  height: 40,
                  child: AnimatedOpacity(
                    opacity: _errorText.isEmpty ? 0 : 1,
                    duration: const Duration(milliseconds: 300),
                    child: Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppColors.berryRed,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            const BoxShadow(color: Colors.black12, offset: Offset(0, 4), blurRadius: 4),
                          ],
                        ),
                        child: Text(
                          _errorText,
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                      ),
                    ),
                  ),
                ),
                
                // DRAG TARGET AREA (Slots)
                Expanded(
                  flex: 3,
                  child: Center(
                    child: DragTarget<int>(
                      onWillAccept: (data) => !_userSelection.contains(data),
                      onAccept: (data) => _onNumberDrop(data),
                      builder: (context, candidateData, rejectedData) {
                        return Container(
                          width: double.infinity,
                          margin: const EdgeInsets.symmetric(horizontal: 24),
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2), // Frosted glass look
                            borderRadius: BorderRadius.circular(30),
                            border: Border.all(color: Colors.white.withValues(alpha: 0.4), width: 2),
                          ),
                          child: Wrap(
                            spacing: 12,
                            runSpacing: 12, // vertical spacing
                            alignment: WrapAlignment.center,
                            runAlignment: WrapAlignment.center,
                            children: _userSelection.isEmpty 
                              ? List.generate(_currentNumbers.length, (i) => _buildEmptySlot())
                              : [
                                  ..._userSelection.map((n) => _buildNumberChip(n, isActive: true)),
                                  ...List.generate(_currentNumbers.length - _userSelection.length, (i) => _buildEmptySlot())
                                ],
                          ),
                        );
                      },
                    ),
                  ),
                ),
                
                // DRAGGABLE NUMBERS SOURCE
                Expanded(
                  flex: 2,
                  child: Container(
                    width: double.infinity,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(40),
                        topRight: Radius.circular(40),
                      ),
                      boxShadow: [
                         BoxShadow(color: Colors.black12, offset: Offset(0, -4), blurRadius: 10),
                      ],
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          "SAYILAR",
                          style: TextStyle(
                            color: AppColors.gray,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.5,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 20),
                        Wrap(
                          spacing: 16,
                          runSpacing: 16,
                          alignment: WrapAlignment.center,
                          children: _currentNumbers
                              .where((n) => !_userSelection.contains(n))
                              .map((n) => Draggable<int>(
                                    data: n,
                                    feedback: Material(
                                      color: Colors.transparent,
                                      child: _buildNumberChip(n, isFeedback: true),
                                    ),
                                    childWhenDragging: Opacity(
                                      opacity: 0,
                                      child: _buildNumberChip(n),
                                    ),
                                    child: _buildNumberChip(n),
                                  ))
                              .toList(),
                        ),
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
                numberOfParticles: 30, 
                gravity: 0.2,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultCard() {
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
                '🎉',
                style: TextStyle(fontSize: 80),
              ),
              const SizedBox(height: 24),
              const Text(
                'Tüm sayıları ustalıkla sıraladın!',
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
                  style: TextStyle(
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


  Widget _buildNumberChip(int n, {bool isActive = false, bool isFeedback = false}) {
    // If active (placed in slot), maybe show it differently? 
    // Actually, stick to the style.
    return NeumorphicGameButton(
      width: isFeedback ? 80 : 70,
      height: isFeedback ? 80 : 70,
      color: _getNumberColor(n),
      shadowColor: _getNumberShadowColor(n),
      onPressed: null, // It's draggable
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Text(
          '$n',
          style: TextStyle(
            fontSize: isFeedback ? 32 : 28,
            fontWeight: FontWeight.w900,
            color: Colors.white,
            shadows: const [
              Shadow(color: Colors.black26, offset: Offset(1, 1), blurRadius: 2),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptySlot() {
    return Container(
      width: 70,
      height: 70,
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.1), // Inner shadow/indent effect
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.2), width: 2),
        boxShadow: const [
           // Inner shadow simulation via inset is hard in Flutter without package, 
           // but transparent black usually does the job of "hole"
        ],
      ),
      child: Center(
        child: Container(
          width: 20,
          height: 20,
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
        ),
      ),
    );
  }
}
