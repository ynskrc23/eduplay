import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../data/models/child_profile.dart';
import '../../../data/repositories/game_repository.dart';
import '../../../data/repositories/child_repository.dart';
import '../../../core/app_colors.dart';
import '../../../core/widgets/neumorphic_game_button.dart';
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
  bool _isLoading = true;
  String? _selectedOperation; // '+', '-', '*', '/'
  String? _selectedDifficulty; // 'kolay' | 'orta' | 'zor'

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final profile = await _childRepo.getProfileById(widget.childId);
    setState(() {
      _childProfile = profile;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      backgroundColor: AppColors.cloudBlue,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppColors.cloudBlue, AppColors.purpleLight],
          ),
        ),
        child: SafeArea(
          child: Stack(
            children: [
              // Background Decorations
              Positioned(top: 100, left: 30, child: _buildBackgroundElement(Icons.stars_rounded, Colors.white.withValues(alpha: 0.2), 30)),
              Positioned(bottom: 200, left: 50, child: _buildBackgroundElement(Icons.bubble_chart_rounded, Colors.white.withValues(alpha: 0.15), 40)),
              Positioned(top: 150, right: 40, child: _buildBackgroundElement(Icons.favorite_rounded, Colors.white.withValues(alpha: 0.1), 25)),
              Positioned(bottom: 100, right: 60, child: _buildBackgroundElement(Icons.star_rounded, Colors.white.withValues(alpha: 0.2), 35)),

              Column(
                children: [
                  _buildHeader(),
                  Expanded(
                    child: _buildSelection(),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBackgroundElement(IconData icon, Color color, double size) {
    return Icon(icon, color: color, size: size)
        .animate(onPlay: (controller) => controller.repeat(reverse: true))
        .scale(begin: const Offset(0.8, 0.8), end: const Offset(1.2, 1.2), duration: 2.seconds)
        .rotate(begin: -0.1, end: 0.1);
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: [
          NeumorphicGameButton(
            width: 48,
            height: 48,
            color: Colors.white,
            shadowColor: Colors.blueGrey.shade100,
            onPressed: () => Navigator.pop(context),
            child: const Icon(Icons.arrow_back_rounded, color: AppColors.cloudBlue, size: 28),
          ),
          Expanded(
            child: Text(
              'MATEMATİK YARIŞI',
              textAlign: TextAlign.center,
              style: GoogleFonts.outfit(
                fontSize: 24,
                fontWeight: FontWeight.w900,
                color: Colors.white,
                letterSpacing: 1.2,
                shadows: [
                  const Shadow(
                    color: Colors.black26,
                    offset: Offset(2, 2),
                    blurRadius: 4,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 48), // Balancing
        ],
      ),
    );
  }

  Widget _buildSelection() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      child: Column(
        children: [
          _buildSectionHeader('İŞLEM SEÇ', Icons.calculate_rounded),
          const SizedBox(height: 16),
          _buildOperationGrid(),
          const SizedBox(height: 32),
          _buildSectionHeader('ZORLUK SEÇ', Icons.speed_rounded),
          const SizedBox(height: 16),
          _buildDifficultySelection(),
          const SizedBox(height: 48),
          _buildStartButton(),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, color: Colors.white, size: 24),
        const SizedBox(width: 8),
        Text(
          title,
          style: GoogleFonts.outfit(
            fontSize: 22,
            fontWeight: FontWeight.w900,
            color: Colors.white,
            letterSpacing: 1.5,
            shadows: [const Shadow(color: Colors.black26, offset: Offset(2, 2), blurRadius: 4)],
          ),
        ),
      ],
    );
  }

  Widget _buildOperationGrid() {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      mainAxisSpacing: 16,
      crossAxisSpacing: 16,
      childAspectRatio: 1.2,
      children: [
        _buildOpCard('+', 'TOPLAMA', AppColors.sunYellow, AppColors.sunYellowShadow),
        _buildOpCard('-', 'ÇIKARMA', AppColors.oceanBlue, AppColors.oceanBlueShadow),
        _buildOpCard('*', 'ÇARPMA', AppColors.berryRed, AppColors.berryRedShadow),
        _buildOpCard('/', 'BÖLME', AppColors.leafGreen, AppColors.leafGreenShadow),
      ],
    );
  }

  Widget _buildOpCard(String op, String label, Color color, Color shadow) {
    bool isSelected = _selectedOperation == op;
    return NeumorphicGameButton(
      color: isSelected ? color : Colors.white,
      shadowColor: isSelected ? shadow : Colors.blueGrey.shade100,
      onPressed: () => setState(() => _selectedOperation = op),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(op, style: GoogleFonts.outfit(
            fontSize: 40, 
            fontWeight: FontWeight.w900, 
            color: isSelected ? Colors.white : AppColors.darkText
          )),
          Text(label, style: GoogleFonts.outfit(
            fontSize: 16, 
            fontWeight: FontWeight.w800, 
            color: isSelected ? Colors.white.withValues(alpha: 0.8) : AppColors.gray
          )),
        ],
      ),
    );
  }

  Widget _buildDifficultySelection() {
    return Row(
      children: [
        _buildDiffCard('kolay', 'KOLAY', Icons.star_rounded, 1),
        const SizedBox(width: 12),
        _buildDiffCard('orta', 'ORTA', Icons.stars_rounded, 2),
        const SizedBox(width: 12),
        _buildDiffCard('zor', 'ZOR', Icons.workspace_premium_rounded, 3),
      ],
    );
  }

  Widget _buildDiffCard(String key, String label, IconData icon, int stars) {
    bool isSelected = _selectedDifficulty == key;
    return Expanded(
      child: NeumorphicGameButton(
        height: 100,
        color: isSelected ? AppColors.violetMain : Colors.white,
        shadowColor: isSelected ? AppColors.purpleDark : Colors.blueGrey.shade100,
        onPressed: () => setState(() => _selectedDifficulty = key),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: isSelected ? Colors.white : AppColors.violetMain, size: 32),
            const SizedBox(height: 4),
            Text(label, style: GoogleFonts.outfit(
              fontSize: 14, 
              fontWeight: FontWeight.w900, 
              color: isSelected ? Colors.white : AppColors.darkText
            )),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(3, (index) => Icon(
                Icons.star_rounded, 
                size: 10, 
                color: index < stars ? (isSelected ? Colors.white.withValues(alpha: 0.8) : AppColors.gold) : Colors.grey.withValues(alpha: 0.3)
              )),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStartButton() {
    bool canStart = _selectedOperation != null && _selectedDifficulty != null;
    return NeumorphicGameButton(
      width: double.infinity,
      height: 70,
      color: canStart ? AppColors.leafGreen : Colors.white.withValues(alpha: 0.5),
      shadowColor: canStart ? AppColors.leafGreenShadow : Colors.transparent,
      onPressed: canStart ? () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => GamePageModern(
              childId: widget.childId,
              operation: _selectedOperation,
              difficulty: _selectedDifficulty,
            ),
          ),
        ).then((_) => _loadData());
      } : null,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'OYUNU BAŞLAT',
            style: GoogleFonts.outfit(
              color: canStart ? Colors.white : AppColors.gray,
              fontWeight: FontWeight.w900,
              fontSize: 22,
              letterSpacing: 1.2,
            ),
          ),
          if (canStart) ...[
            const SizedBox(width: 12),
            const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 32),
          ],
        ],
      ),
    ).animate(target: canStart ? 1 : 0).shimmer(duration: 2.seconds, color: Colors.white24);
  }
}
