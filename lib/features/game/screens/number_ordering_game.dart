import 'dart:math';
import 'package:flutter/material.dart';
import 'package:confetti/confetti.dart';
import '../../../core/app_colors.dart';
import '../../../core/widgets/duo_button.dart';
import '../../../core/widgets/duo_progress_bar.dart';
import '../../../data/repositories/child_repository.dart';
import '../../../core/services/sound_service.dart';

class NumberOrderingGame extends StatefulWidget {
  final int childId;
  const NumberOrderingGame({super.key, required this.childId});

  @override
  State<NumberOrderingGame> createState() => _NumberOrderingGameState();
}

class _NumberOrderingGameState extends State<NumberOrderingGame> {
  final ChildRepository _childRepo = ChildRepository();
  late ConfettiController _confettiController;
  final Random _random = Random();
  
  List<int> _currentNumbers = [];
  List<int> _userSelection = [];
  String _errorText = '';
  int _round = 1;
  final int _totalRounds = 5;

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(duration: const Duration(seconds: 1));
    _generateRound();
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
    });
  }

  void _onNumberDrop(int num) {
    List<int> sorted = List.from(_currentNumbers)..sort();
    int nextCorrect = sorted[_userSelection.length];

    if (num == nextCorrect) {
      setState(() {
        _userSelection.add(num);
        _errorText = '';
      });
      SoundService.instance.playCorrect();

      if (_userSelection.length == _currentNumbers.length) {
        _confettiController.play();
        _nextRound();
      }
    } else {
      SoundService.instance.playWrong();
      setState(() {
        _errorText = 'Yanlış Sıra! Daha küçük bir sayı olmalı.';
      });
      Future.delayed(const Duration(seconds: 2), () {
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
        title: const Text('HARİKA!', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.w900, color: AppColors.green)),
        content: const Text('Tüm sayıları ustalıkla sıraladın!', textAlign: TextAlign.center),
        actions: [
          DuoButton(
            color: AppColors.green,
            shadowColor: AppColors.greenShadow,
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: const Text('DEVAM ET', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
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
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Stack(
          children: [
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
                const SizedBox(height: 32),
                const Text(
                  'Küçükten büyüğe soldan sağa sırala! 🔢',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.gray),
                ),
                const SizedBox(height: 8),
                // Error Message Area
                SizedBox(
                  height: 30,
                  child: AnimatedOpacity(
                    opacity: _errorText.isEmpty ? 0 : 1,
                    duration: const Duration(milliseconds: 300),
                    child: Center(
                      child: Text(
                        _errorText,
                        style: const TextStyle(color: AppColors.red, fontWeight: FontWeight.w900, fontSize: 13),
                      ),
                    ),
                  ),
                ),
                
                // DRAG TARGET AREA (Slots for sorted numbers)
                DragTarget<int>(
                  onWillAccept: (data) => !_userSelection.contains(data),
                  onAccept: (data) => _onNumberDrop(data),
                  builder: (context, candidateData, rejectedData) {
                    return Container(
                      width: double.infinity,
                      margin: const EdgeInsets.symmetric(horizontal: 24),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      decoration: BoxDecoration(
                        color: candidateData.isNotEmpty ? AppColors.green.withOpacity(0.05) : Colors.transparent,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        alignment: WrapAlignment.center,
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
                
                const SizedBox(height: 20),
                
                // DRAGGABLE NUMBERS
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Wrap(
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
                ),
                const Spacer(flex: 2),
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
            'BÖLÜM BİTTİ!',
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.w900,
              color: AppColors.purpleDark,
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            '🦊',
            style: TextStyle(fontSize: 100),
          ),
          const SizedBox(height: 24),
          const Text(
            'Tüm sayıları ustalıkla sıraladın!',
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
              color: AppColors.green,
              shadowColor: AppColors.greenShadow,
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

  Widget _buildNumberChip(int n, {bool isActive = false, bool isFeedback = false}) {
    return DuoButton(
      width: isFeedback ? 80 : 70,
      height: isFeedback ? 80 : 70,
      color: isActive ? AppColors.green : AppColors.white,
      shadowColor: isActive ? AppColors.greenShadow : AppColors.lightGray,
      onPressed: null,
      child: Text(
        '$n',
        style: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.w900,
          color: isActive ? Colors.white : AppColors.textMain,
        ),
      ),
    );
  }

  Widget _buildEmptySlot() {
    return Container(
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        color: AppColors.lightGray.withOpacity(0.2),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.lightGray, width: 2, style: BorderStyle.solid),
      ),
    );
  }
}
