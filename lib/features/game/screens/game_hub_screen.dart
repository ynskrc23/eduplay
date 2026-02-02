import 'package:flutter/material.dart';
import 'level_map_screen.dart';
import 'number_ordering_game.dart';
import 'balloon_pop_game.dart';
import '../../../core/app_colors.dart';
import '../../../core/widgets/duo_button.dart';
import '../../../data/models/child_profile.dart';
import '../../../data/repositories/child_repository.dart';

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
    if (_isLoading) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.purpleLight,
              AppColors.purpleDark,
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      const Text(
                        'EĞLENEREK\nMATEMATİK ÖĞREN!',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.2,
                        ),
                      ),
                      const SizedBox(height: 32),
                      _buildGameCard(
                        title: 'MATEMATİK YARIŞI',
                        subtitle: 'Hızlı sorularla kendini dene!',
                        icon: '🚀',
                        color: AppColors.green,
                        shadow: AppColors.greenShadow,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => LevelMapScreen(childId: widget.childId)),
                          );
                        },
                      ),
                      const SizedBox(height: 20),
                      _buildGameCard(
                        title: 'SAYI SIRALAMA',
                        subtitle: 'Küçükten büyüğe sırala!',
                        icon: '🔢',
                        color: AppColors.blue,
                        shadow: AppColors.blueShadow,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => NumberOrderingGame(childId: widget.childId)),
                          );
                        },
                      ),
                      const SizedBox(height: 20),
                      _buildGameCard(
                        title: 'BALON PATLAT',
                        subtitle: 'Doğru sonucu bul ve patlat!',
                        icon: '🎈',
                        color: AppColors.orange,
                        shadow: AppColors.orangeShadow,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => BalloonPopGame(childId: widget.childId)),
                          );
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
              CircleAvatar(
                backgroundColor: Colors.white,
                child: Text(_childProfile?.avatarId ?? '🦊'),
              ),
              const SizedBox(width: 12),
              Text(
                _childProfile?.name ?? '',
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
              ),
            ],
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.gold.withOpacity(0.3),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.gold, width: 2),
            ),
            child: Row(
              children: [
                const Icon(Icons.stars_rounded, color: AppColors.gold, size: 20),
                const SizedBox(width: 4),
                Text(
                  '${_childProfile?.totalScore ?? 0}',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900),
                ),
              ],
            ),
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
  }) {
    return DuoButton(
      height: 120,
      color: AppColors.white,
      shadowColor: AppColors.lightGray,
      onPressed: onTap,
      child: Row(
        children: [
          const SizedBox(width: 20),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(icon, style: const TextStyle(fontSize: 40)),
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
                    color: AppColors.textMain,
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
          const Icon(Icons.arrow_forward_ios_rounded, color: AppColors.lightGray),
          const SizedBox(width: 20),
        ],
      ),
    );
  }
}
