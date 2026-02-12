import 'package:flutter/material.dart';
import 'level_map_screen.dart';
import 'number_ordering_game.dart';
import 'balloon_pop_game.dart';
import 'game_page_enhanced.dart';
import 'game_page_modern.dart';
import '../../../core/app_colors.dart';
import '../../../core/widgets/neumorphic_game_button.dart';
import '../../../data/models/child_profile.dart';
import '../../../data/repositories/child_repository.dart';
import '../../../core/services/sound_service.dart';
import '../../parent_panel/screens/parent_panel_screen.dart';

class GameHubScreen extends StatefulWidget {
  final int childId;
  const GameHubScreen({super.key, required this.childId});

  @override
  State<GameHubScreen> createState() => _GameHubScreenState();
}

class _GameHubScreenState extends State<GameHubScreen> {
  final ChildRepository _childRepo = ChildRepository();
  ChildProfile? _childProfile;
  bool _isLoading = true;
  bool _isMuted = false;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final profile = await _childRepo.getProfileById(widget.childId);
    setState(() {
      _childProfile = profile;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading)
      return const Scaffold(body: Center(child: CircularProgressIndicator()));

    return Scaffold(
      backgroundColor: AppColors.cloudBlue, // New Design Background
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(color: AppColors.cloudBlue),
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 20.0),
                        child: Text(
                          'EĞLENEREK\nMATEMATİK ÖĞREN!',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 28,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.2,
                            shadows: [
                              Shadow(
                                color: Colors.black.withValues(alpha: 0.2),
                                offset: const Offset(2, 2),
                                blurRadius: 4,
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      _buildGameCard(
                        title: 'MATEMATİK YARIŞI',
                        subtitle: 'Seviyeleri tamamla!',
                        icon: '🚀',
                        color: AppColors.leafGreen,
                        shadow: AppColors.leafGreenShadow,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  LevelMapScreen(childId: widget.childId),
                            ),
                          ).then((_) => _loadProfile());
                        },
                      ),
                      const SizedBox(height: 20),
                      _buildGameCard(
                        title: 'SAYI SIRALAMA',
                        subtitle: 'Küçükten büyüğe sırala!',
                        icon: '🔢',
                        color: AppColors.oceanBlue,
                        shadow: AppColors.oceanBlueShadow,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  NumberOrderingGame(childId: widget.childId),
                            ),
                          ).then((_) => _loadProfile());
                        },
                      ),
                      const SizedBox(height: 20),
                      _buildGameCard(
                        title: 'MATEMATİK SAVAŞI',
                        subtitle: 'Canavarları yen!',
                        icon: '👾',
                        color: AppColors.violetMain,
                        shadow: AppColors.purpleDark,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  GamePageEnhanced(childId: widget.childId),
                            ),
                          ).then((_) => _loadProfile());
                        },
                      ),
                      const SizedBox(height: 20),
                      _buildGameCard(
                        title: 'BALON PATLAT',
                        subtitle: 'Doğru sonucu bul!',
                        icon: '🎈',
                        color: AppColors.sunYellow,
                        shadow: AppColors.sunYellowShadow,
                        textColor:
                            AppColors.darkText, // Yellow bg needs dark text
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  BalloonPopGame(childId: widget.childId),
                            ),
                          ).then((_) => _loadProfile());
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Text(
                  _childProfile?.avatarId ?? '🦊',
                  style: const TextStyle(fontSize: 28),
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    (_childProfile?.name ?? '').toUpperCase(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      fontSize: 20,
                      shadows: [
                        Shadow(
                          color: Colors.black12,
                          offset: Offset(1, 1),
                          blurRadius: 2,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      offset: const Offset(0, 4),
                      blurRadius: 4,
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.stars_rounded,
                      color: AppColors.gold,
                      size: 24,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${_childProfile?.totalScore ?? 0}',
                      style: const TextStyle(
                        color: AppColors.darkText,
                        fontWeight: FontWeight.w900,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              NeumorphicGameButton(
                width: 44,
                height: 44,
                borderRadius: 12,
                color: Colors.white,
                shadowColor: Colors.blueGrey.shade200,
                onPressed: () {
                  setState(() => _isMuted = !_isMuted);
                  SoundService.instance.setMute(_isMuted);
                },
                child: Icon(
                  _isMuted ? Icons.volume_off_rounded : Icons.volume_up_rounded,
                  color: AppColors.cloudBlue,
                ),
              ),
              const SizedBox(width: 12),
              NeumorphicGameButton(
                width: 44,
                height: 44,
                borderRadius: 12,
                color: Colors.white,
                shadowColor: Colors.blueGrey.shade200,
                onPressed: () {
                  if (_childProfile != null) {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                          builder: (context) =>
                              ParentPanelScreen(childProfile: _childProfile!)),
                    ).then((_) => _loadProfile());
                  }
                },
                child: const Icon(Icons.settings_rounded,
                    color: AppColors.cloudBlue, size: 24),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildGameCard({
    required String title,
    required String subtitle,
    required String icon,
    required Color color,
    required Color shadow,
    required VoidCallback onTap,
    Color textColor = Colors.white,
  }) {
    return NeumorphicGameButton(
      height: 100,
      width: double.infinity,
      color: Colors.white, // Main card background white
      shadowColor: Colors.blueGrey.shade100, // Card shadow
      onPressed: onTap,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      borderRadius: 24,
      child: Row(
        children: [
          // Icon Box
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: shadow,
                  offset: const Offset(0, 4),
                  blurRadius: 0,
                ),
              ],
            ),
            child: Center(
              child: Text(icon, style: const TextStyle(fontSize: 32)),
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: AppColors.darkText,
                  ),
                ),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.gray,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          NeumorphicGameButton(
            // Mini button for arrow
            width: 40,
            height: 40,
            color: color,
            shadowColor: shadow,
            borderRadius: 12,
            onPressed: onTap, // Mini button for arrow
            child: Icon(
              Icons.arrow_forward_rounded,
              color: textColor,
              size: 24,
            ),
          ),
        ],
      ),
    );
  }
}
