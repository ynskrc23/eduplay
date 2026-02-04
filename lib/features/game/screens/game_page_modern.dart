import 'dart:math';
import 'package:flutter/material.dart';
import 'package:confetti/confetti.dart';
import 'package:flutter_animate/flutter_animate.dart';

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

class GamePageModern extends StatefulWidget {
  final int childId;
  final int? initialLevelIndex;
  const GamePageModern({super.key, required this.childId, this.initialLevelIndex});

  @override
  State<GamePageModern> createState() => _GamePageModernState();
}

enum GameStatus { welcome, playing, won, levelUp, lost }

class _GamePageModernState extends State<GamePageModern> with TickerProviderStateMixin {
  GameStatus _status = GameStatus.welcome;
  bool _isNextLevelUnlocked = false;
  int _lastComboBonus = 0;
  int _lastLevelGift = 0;
  
  // Game State Variables
  int _correctCount = 0;
  int _comboCount = 0;
  int _wrongCount = 0;
  
  // Multiple choice options
  List<int> _answerOptions = [];
  int? _selectedAnswer;
  bool _showFeedback = false;
  
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
  int _currentLevelIndex = 0;
  bool _isLoading = true;

  // Current Question
  late int _num1;
  late int _num2;
  late String _operator;
  int _answer = 0;
  
  final Random _random = Random();
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
    _pulseController.dispose();
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
    });
    
    // Debug print
    debugPrint('Question: $_num1 $_operator $_num2 = $_answer');
    debugPrint('Options: $_answerOptions');
  }

  void _checkAnswer(int userAnswer) {
    setState(() {
      _selectedAnswer = userAnswer;
      _showFeedback = true;
      
      if (userAnswer == _answer) {
        _correctCount++;
        _comboCount++;
        
        int earnedPoints = 10;
        _feedbackMessage = _gamification.getFeedbackMessage(true, _comboCount);
        
        _confettiController.play();
        SoundService.instance.playCorrect();
        
        _childRepo.updateScore(widget.childId, earnedPoints);
        
        if (_childProfile != null) {
          _childProfile = _childProfile!.copyWith(
            totalScore: _childProfile!.totalScore + earnedPoints,
          );
        }

        int target = min(5 + (_currentLevelIndex * 2), 15);
        if (_correctCount >= target) {
          Future.delayed(const Duration(milliseconds: 1500), () {
            _advanceLevel();
          });
        } else {
          Future.delayed(const Duration(milliseconds: 1500), () {
             if (mounted && _status == GameStatus.playing) _generateQuestion();
          });
        }
      } else {
        _wrongCount++;
        _comboCount = 0;
        _feedbackMessage = _gamification.getFeedbackMessage(false, 0);
        SoundService.instance.playWrong();
        
        Future.delayed(const Duration(milliseconds: 1500), () {
           if (mounted && _status == GameStatus.playing) _generateQuestion();
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

    int comboBonus = 0;
    int levelGift = 0;

    if (_currentLevelIndex + 1 < _levels.length) {
      if (_comboCount > 0) {
        comboBonus = _comboCount;
        await _childRepo.updateScore(widget.childId, comboBonus);
      }

      _currentLevelIndex++;
    
      await _childRepo.updateLevel(widget.childId, _currentLevelIndex);

      var updatedProfile = await _childRepo.getProfileById(widget.childId);
      
      bool unlocked = false;
      if (_currentLevelIndex < _levels.length) {
        final nextLevel = _levels[_currentLevelIndex];
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
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator()) 
        : Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color(0xFF6366F1),
                Color(0xFF8B5CF6),
                Color(0xFFA855F7),
              ],
            ),
          ),
          child: SafeArea(
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

  Widget _buildHeader() {
    int target = min(5 + (_currentLevelIndex * 2), 15);
    
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          // Close button
          Container(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: IconButton(
              onPressed: _exitGame,
              icon: const Icon(Icons.close, color: Colors.white, size: 24),
            ),
          ),
          const SizedBox(width: 12),
          
          // Progress
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Seviye ${_currentLevelIndex + 1}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    Text(
                      '$_correctCount / $target',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: LinearProgressIndicator(
                    value: _correctCount / target,
                    minHeight: 12,
                    backgroundColor: Colors.white.withOpacity(0.3),
                    valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF10B981)),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          
          // Score
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.amber,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.amber.withOpacity(0.5),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                const Icon(Icons.star, color: Colors.white, size: 20),
                const SizedBox(width: 4),
                Text(
                  '${_childProfile?.totalScore ?? 0}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 16,
                  ),
                ),
              ],
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
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 30,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Text(
                _childProfile?.avatarId ?? '🦊',
                style: const TextStyle(fontSize: 80),
              ),
            ).animate().scale(duration: 600.ms, curve: Curves.elasticOut),
            const SizedBox(height: 40),
            Text(
              _childProfile != null ? 'Merhaba, ${_childProfile!.name}!' : 'Merhaba!',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.w900,
                color: Colors.white,
              ),
            ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.3, end: 0),
            const SizedBox(height: 16),
            const Text(
              'Matematik macerası seni bekliyor!\nHazır mısın?',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 18, 
                color: Colors.white, 
                height: 1.5, 
                fontWeight: FontWeight.w600
              ),
            ).animate().fadeIn(delay: 400.ms),
            const SizedBox(height: 48),
            Container(
              width: double.infinity,
              height: 60,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF10B981), Color(0xFF059669)],
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF10B981).withOpacity(0.5),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: _startGame,
                  borderRadius: BorderRadius.circular(16),
                  child: const Center(
                    child: Text(
                      'BAŞLA',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        fontSize: 20,
                        letterSpacing: 2,
                      ),
                    ),
                  ),
                ),
              ),
            ).animate().scale(delay: 600.ms, duration: 400.ms, curve: Curves.elasticOut),
          ],
        ),
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
            
            // Question Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(32),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 30,
                    offset: const Offset(0, 15),
                  ),
                ],
              ),
              child: Column(
                children: [
                  const Text(
                    'Ne kadar eder?',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF6B7280),
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  // Question
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
                        fontSize: 64,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF6366F1),
                        letterSpacing: 4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 32),
            
            // Answer Options - Simplified Layout
            if (_answerOptions.isEmpty)
              const Text(
                'Cevaplar yükleniyor...',
                style: TextStyle(color: Colors.white, fontSize: 18),
              )
            else
              Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _buildAnswerButton(_answerOptions[0]),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildAnswerButton(_answerOptions[1]),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _buildAnswerButton(_answerOptions[2]),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildAnswerButton(_answerOptions[3]),
                      ),
                    ],
                  ),
                ],
              ),
            
            const SizedBox(height: 24),
            
            // Feedback Message
            if (_showFeedback && _feedbackMessage.isNotEmpty)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                decoration: BoxDecoration(
                  color: _selectedAnswer == _answer
                      ? const Color(0xFF10B981).withOpacity(0.2)
                      : const Color(0xFFEF4444).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: _selectedAnswer == _answer
                        ? const Color(0xFF10B981)
                        : const Color(0xFFEF4444),
                    width: 2,
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      _selectedAnswer == _answer ? Icons.check_circle : Icons.cancel,
                      color: _selectedAnswer == _answer
                          ? const Color(0xFF10B981)
                          : const Color(0xFFEF4444),
                      size: 28,
                    ),
                    const SizedBox(width: 12),
                    Flexible(
                      child: Text(
                        _feedbackMessage,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          color: _selectedAnswer == _answer
                              ? const Color(0xFF10B981)
                              : const Color(0xFFEF4444),
                        ),
                      ),
                    ),
                  ],
                ),
              ).animate().fadeIn().shake(),
          ],
        ),
      ),
    );
  }

  Widget _buildAnswerButton(int option) {
    final isSelected = _selectedAnswer == option;
    final isCorrect = option == _answer;
    
    Color buttonColor = Colors.white;
    Color textColor = const Color(0xFF1F2937);
    
    if (_showFeedback && isSelected) {
      if (isCorrect) {
        buttonColor = const Color(0xFF10B981);
        textColor = Colors.white;
      } else {
        buttonColor = const Color(0xFFEF4444);
        textColor = Colors.white;
      }
    } else if (_showFeedback && isCorrect) {
      buttonColor = const Color(0xFF10B981);
      textColor = Colors.white;
    }
    
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      height: 80,
      decoration: BoxDecoration(
        color: buttonColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: buttonColor.withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _showFeedback ? null : () => _checkAnswer(option),
          borderRadius: BorderRadius.circular(20),
          child: Center(
            child: Text(
              '$option',
              style: TextStyle(
                fontSize: 36,
                fontWeight: FontWeight.w900,
                color: textColor,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLevelUpCard() {
    final nextLevel = _currentLevelIndex;
    final unlockScoreNeeded = _levels[nextLevel].unlockScore;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.stars_rounded,
              size: 100,
              color: Colors.amber,
            ).animate().scale(duration: 600.ms, curve: Curves.elasticOut),
            const SizedBox(height: 24),
            const Text(
              'SEVİYE TAMAMLANDI!',
              style: TextStyle(
                fontSize: 32, 
                fontWeight: FontWeight.w900, 
                color: Colors.white,
              ),
            ).animate().fadeIn().slideY(begin: -0.3, end: 0),
            const SizedBox(height: 32),
            Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 30,
                    offset: const Offset(0, 15),
                  ),
                ],
              ),
              child: Column(
                children: [
                  if (_lastComboBonus > 0 || _lastLevelGift > 0)
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      alignment: WrapAlignment.center,
                      children: [
                        if (_lastComboBonus > 0)
                          _buildBonusBadge('🔥 $_lastComboBonus KOMBO'),
                        if (_lastLevelGift > 0)
                          _buildBonusBadge('🎁 $_lastLevelGift BONUS'),
                      ],
                    ),
                  const SizedBox(height: 24),
                  Text(
                    _isNextLevelUnlocked 
                        ? 'Yeni seviye açıldı! 🎉' 
                        : 'Sonraki seviye için $unlockScoreNeeded puan gerekli.',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 18, 
                      color: Color(0xFF1F2937), 
                      fontWeight: FontWeight.bold
                    ),
                  ),
                ],
              ),
            ).animate().scale(delay: 200.ms, curve: Curves.elasticOut),
            const SizedBox(height: 48),
            Container(
              width: double.infinity,
              height: 60,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF10B981), Color(0xFF059669)],
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF10B981).withOpacity(0.5),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: _isNextLevelUnlocked ? _startGame : _exitGame,
                  borderRadius: BorderRadius.circular(16),
                  child: Center(
                    child: Text(
                      _isNextLevelUnlocked ? 'DEVAM ET' : 'HARİTAYA DÖN',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        fontSize: 18,
                        letterSpacing: 2,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            if (_isNextLevelUnlocked)
              Padding(
                padding: const EdgeInsets.only(top: 16),
                child: TextButton(
                  onPressed: _exitGame,
                  child: const Text(
                    'ŞİMDİLİK BU KADAR', 
                    style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold)
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

Widget _buildBonusBadge(String text) {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    decoration: BoxDecoration(
      gradient: const LinearGradient(
        colors: [Color(0xFFF59E0B), Color(0xFFD97706)],
      ),
      borderRadius: BorderRadius.circular(12),
      boxShadow: [
        BoxShadow(
          color: const Color(0xFFF59E0B).withOpacity(0.3),
          blurRadius: 8,
          offset: const Offset(0, 4),
        ),
      ],
    ),
    child: Text(
      text,
      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
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
    
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 100,
              color: Colors.white,
            ).animate().scale(duration: 600.ms, curve: Curves.elasticOut),
            const SizedBox(height: 24),
            Text(
              title.toUpperCase(),
              style: const TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.w900,
                color: Colors.white,
              ),
            ).animate().fadeIn().slideY(begin: -0.3, end: 0),
            const SizedBox(height: 32),
            Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 30,
                    offset: const Offset(0, 15),
                  ),
                ],
              ),
              child: Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 18, 
                  color: Color(0xFF1F2937), 
                  fontWeight: FontWeight.bold
                ),
              ),
            ),
            const SizedBox(height: 48),
            Container(
              width: double.infinity,
              height: 60,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isWin 
                      ? [const Color(0xFF10B981), const Color(0xFF059669)]
                      : [const Color(0xFF6366F1), const Color(0xFF4F46E5)],
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: (isWin ? const Color(0xFF10B981) : const Color(0xFF6366F1)).withOpacity(0.5),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: isWin ? _exitGame : _startGame,
                  borderRadius: BorderRadius.circular(16),
                  child: Center(
                    child: Text(
                      isWin ? 'DEVAM ET' : 'TEKRAR DENE',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        fontSize: 18,
                        letterSpacing: 2,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
