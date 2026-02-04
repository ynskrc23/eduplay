import 'package:flutter/material.dart';
import 'dart:math';
import '../../../data/models/child_profile.dart';
import '../../../data/models/level.dart';
import '../../../data/repositories/game_repository.dart';
import '../../../data/repositories/child_repository.dart';
import '../../../core/app_colors.dart';
import '../../../core/widgets/duo_button.dart';
import 'game_page_modern.dart';
import '../../parent_panel/screens/parent_panel_screen.dart';

class LevelMapScreen extends StatefulWidget {
  final int childId;
  const LevelMapScreen({super.key, required this.childId});

  @override
  State<LevelMapScreen> createState() => _LevelMapScreenState();
}

class _LevelMapScreenState extends State<LevelMapScreen> {
  final GameRepository _gameRepo = GameRepository();
  final ChildRepository _childRepo = ChildRepository();
  
  ChildProfile? _childProfile;
  List<Level> _levels = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final profile = await _childRepo.getProfileById(widget.childId);
    final game = await _gameRepo.getGameByCode('MATH_RACE');
    if (game != null) {
      final levels = await _gameRepo.getLevelsByGameId(game.id!);
      setState(() {
        _childProfile = profile;
        _levels = levels;
        _isLoading = false;
      });

      // Daily Reward Check
      _checkDailyReward();
    }
  }

  Future<void> _checkDailyReward() async {
    final reward = await _childRepo.checkAndClaimDailyReward(widget.childId);
    if (reward != null && mounted) {
      // Reload profile to show new score
      final profile = await _childRepo.getProfileById(widget.childId);
      setState(() {
        _childProfile = profile;
      });

      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('🎁 Günlük Ödül!', textAlign: TextAlign.center),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.card_giftcard, size: 80, color: Colors.pink),
              const SizedBox(height: 16),
              Text(
                'Bugün giriş yaptığın için $reward puan kazandın!',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 18),
              ),
            ],
          ),
          actions: [
            Center(
              child: FilledButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Yaşasın!'),
              ),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Stack(
              children: [
                // Vibrant Background
                Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        AppColors.purpleLight,
                        AppColors.purpleDark,
                      ],
                    ),
                  ),
                ),
                
                // Main Layout
                Column(
                  children: [
                    _buildHeader(),
                    Expanded(
                      child: _buildMapPath(),
                    ),
                  ],
                ),
              ],
            ),
    );
  }

  Widget _buildHeader() {
    return Container(
      margin: const EdgeInsets.only(top: 48, left: 16, right: 16, bottom: 8),
      padding: const EdgeInsets.only(left: 8, right: 16, top: 12, bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.white.withOpacity(0.9),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.5), width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // Back Button
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.arrow_back_rounded, color: AppColors.purpleDark),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
          const SizedBox(width: 8),
          // Avatar
          Container(
            padding: const EdgeInsets.all(2),
            decoration: const BoxDecoration(
              color: Colors.indigo,
              shape: BoxShape.circle,
            ),
            child: CircleAvatar(
              radius: 24,
              backgroundColor: Colors.white,
              child: Text(_childProfile?.avatarId ?? '👤', style: const TextStyle(fontSize: 24)),
            ),
          ),
          const SizedBox(width: 12),
          // User Info
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _childProfile?.name ?? 'Oyuncu',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: AppColors.purpleDark,
                    letterSpacing: -0.5,
                  ),
                ),
                Text(
                  'Skor: ${_childProfile?.totalScore ?? 0}',
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          // "USTA" Badge & Settings
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.amber.shade100,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.amber.shade300),
            ),
            child: Row(
              children: [
                Icon(Icons.stars_rounded, color: Colors.amber.shade800, size: 16),
                const SizedBox(width: 4),
                Text(
                  'USTA',
                  style: TextStyle(
                    color: Colors.amber.shade900,
                    fontWeight: FontWeight.w900,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            onPressed: () {
              if (_childProfile != null) {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (context) => ParentPanelScreen(childProfile: _childProfile!)),
                );
              }
            },
            icon: Icon(Icons.settings_rounded, color: Colors.indigo.shade300, size: 24),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            tooltip: 'Ebeveyn Paneli',
          ),
        ],
      ),
    );
  }



  void _checkAndNavigate(String input, String correct) {
    if (input == correct) {
      Navigator.pop(context);
      if (_childProfile != null) {
        Navigator.of(context).push(
          MaterialPageRoute(builder: (context) => ParentPanelScreen(childProfile: _childProfile!)),
        );
      }
    } else {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Hatalı giriş! Lütfen tekrar deneyin.'), backgroundColor: Colors.red),
      );
    }
  }

  Widget _buildKey(int number, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade200),
        ),
        alignment: Alignment.center,
        child: Text(
          number.toString(),
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.indigo),
        ),
      ),
    );
  }

  Widget _buildMapPath() {
    return SingleChildScrollView(
      padding: const EdgeInsets.only(top: 20, bottom: 50),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 400),
          child: Column(
            children: List.generate(_levels.length, (index) {
              final level = _levels[index];
              final isLocked = (_childProfile?.totalScore ?? 0) < level.unlockScore;
              final isCurrent = index == _childProfile?.currentLevel;
              
              // Zig-zag alignment
              double padding = (index % 4 == 0) ? 0 : (index % 4 == 1 ? 80.0 : (index % 4 == 2 ? 0 : -80.0));

              return Padding(
                padding: EdgeInsets.only(left: padding > 0 ? padding : 0, right: padding < 0 ? -padding : 0, bottom: 40),
                child: _buildLevelNode(level, index, isLocked, isCurrent),
              );
            }),
          ),
        ),
      ),
    );
  }

  Widget _buildLevelNode(Level level, int index, bool isLocked, bool isCurrent) {
    Color nodeColor = isLocked ? AppColors.white.withOpacity(0.3) : (isCurrent ? AppColors.yellow : AppColors.blue);
    Color shadowColor = isLocked ? Colors.black.withOpacity(0.1) : (isCurrent ? AppColors.yellowShadow : AppColors.blueShadow);
    
    return Column(
      children: [
        DuoButton(
          width: 80,
          height: 80,
          color: nodeColor,
          shadowColor: shadowColor,
          onPressed: isLocked ? null : () => _startLevel(index),
          child: Icon(
            isLocked ? Icons.lock : (isCurrent ? Icons.star : Icons.play_arrow),
            color: AppColors.white,
            size: 40,
          ),
        ),
        if (!isLocked) ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white.withOpacity(0.3)),
            ),
            child: Text(
              'SEVİYE ${index + 1}',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w900,
                fontSize: 12,
              ),
            ),
          ),
        ],
        if (isLocked)
          Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: Text(
              '${level.unlockScore} PUAN',
              style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 10, fontWeight: FontWeight.w900),
            ),
          ),
      ],
    );
  }

  void _startLevel(int levelIndex) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => GamePageModern(childId: widget.childId, initialLevelIndex: levelIndex)),
    ).then((_) => _loadData()); // Reload data when returning
  }
}
