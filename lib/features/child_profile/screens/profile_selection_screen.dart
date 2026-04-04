import 'package:flutter/material.dart';
import '../../../data/models/child_profile.dart';
import '../../../data/repositories/child_repository.dart';
import '../../../core/app_colors.dart';
import '../../../core/widgets/duo_button.dart';
import '../../../core/widgets/mascot_guide.dart';
import '../../game/screens/game_hub_screen.dart';
import 'create_profile_screen.dart';

class ProfileSelectionScreen extends StatefulWidget {
  const ProfileSelectionScreen({super.key});

  @override
  State<ProfileSelectionScreen> createState() => _ProfileSelectionScreenState();
}

class _ProfileSelectionScreenState extends State<ProfileSelectionScreen> {
  final ChildRepository _repository = ChildRepository();
  List<ChildProfile> _profiles = [];
  bool _isLoading = true;
  bool _isEditMode = false;

  @override
  void initState() {
    super.initState();
    _loadProfiles();
  }

  Future<void> _loadProfiles() async {
    setState(() => _isLoading = true);
    try {
      final profiles = await _repository.getAllProfiles();
      setState(() {
        _profiles = profiles;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Hata: $e')));
      }
    }
  }

  void _onProfileSelected(ChildProfile profile) {
    if (_isEditMode) {
      _editProfile(profile);
    } else {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (context) => GameHubScreen(childId: profile.id!),
        ),
        (route) => false,
      );
    }
  }

  Future<void> _editProfile(ChildProfile profile) async {
    final result = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => CreateProfileScreen(profileToEdit: profile),
      ),
    );
    if (result == true) {
      _loadProfiles();
    }
  }

  Future<void> _deleteProfile(ChildProfile profile) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('${profile.name} silinsin mi?'),
        content: const Text('Bu işlem geri alınamaz ve tüm ilerleme silinir.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('VAZGEÇ'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('SİL', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _repository.deleteProfile(profile.id!);
      _loadProfiles();
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isTablet = size.width >= 600;
    final crossAxisCount = isTablet ? 3 : 2;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _isEditMode
                              ? 'Düzenlemek için bir profil seç'
                              : 'Devam etmek için profilini seç',
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(
                                color: Colors.white.withValues(alpha: 0.8),
                              ),
                        ),
                      ],
                    ),
                  ),
                  const MascotGuide.mini(),
                ],
              ),
            ),

            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _profiles.isEmpty
                  ? _buildEmptyState()
                  : GridView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: crossAxisCount,
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                        mainAxisExtent: 150,
                      ),
                      itemCount: _profiles.length + 1,
                      itemBuilder: (context, index) {
                        if (index == _profiles.length) {
                          return _buildAddButton();
                        }
                        return _buildProfileCard(_profiles[index]);
                      },
                    ),
            ),

            if (_profiles.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24.0,
                  vertical: 16.0,
                ),
                child: DuoButton(
                  width: double.infinity,
                  height: 50,
                  color: _isEditMode ? AppColors.white : AppColors.blue,
                  shadowColor: _isEditMode
                      ? AppColors.lightGray
                      : AppColors.blueShadow,
                  onPressed: () => setState(() => _isEditMode = !_isEditMode),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        _isEditMode
                            ? Icons.check_circle_rounded
                            : Icons.edit_rounded,
                        color: _isEditMode ? AppColors.green : Colors.white,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _isEditMode ? 'BİTİR' : 'PROFİLLERİ DÜZENLE',
                        style: TextStyle(
                          color: _isEditMode ? AppColors.green : Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileCard(ChildProfile profile) {
    return Stack(
      children: [
        DuoButton(
          height: 140, // Daha kibar bir yükseklik
          onPressed: () => _onProfileSelected(profile),
          color: AppColors.white,
          shadowColor: AppColors.lightGray,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(profile.avatarId, style: const TextStyle(fontSize: 50)),
              const SizedBox(height: 8),
              Text(
                profile.name,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.darkText,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                '${profile.age} Yaş',
                style: const TextStyle(fontSize: 14, color: AppColors.gray),
              ),
            ],
          ),
        ),
        if (_isEditMode)
          Positioned(
            top: 4,
            right: 4,
            child: GestureDetector(
              onTap: () => _deleteProfile(profile),
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.close, size: 16, color: Colors.white),
              ),
            ),
          ),
        if (_isEditMode)
          Positioned(
            top: 4,
            left: 4,
            child: GestureDetector(
              onTap: () => _editProfile(profile),
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(
                  color: AppColors.blue,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.edit, size: 16, color: Colors.white),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildAddButton() {
    return Align(
      alignment: Alignment.topCenter,
      child: DuoButton(
        height: 140, // Daha kibar bir yükseklik
        onPressed: () async {
          final result = await Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => const CreateProfileScreen(),
            ),
          );
          if (result == true) _loadProfiles();
        },
        color: AppColors.white,
        shadowColor: AppColors.lightGray,
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.add_circle_outline_rounded,
              size: 40,
              color: AppColors.blue,
            ),
            SizedBox(height: 8),
            Text(
              'YENİ EKLE',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: AppColors.blue,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.people_outline_rounded,
            size: 64,
            color: AppColors.lightGray,
          ),
          const SizedBox(height: 16),
          const Text(
            'Henüz hiç profil yok',
            style: TextStyle(color: AppColors.gray, fontSize: 18),
          ),
          const SizedBox(height: 24),
          DuoButton(
            height: 60,
            onPressed: () async {
              final result = await Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const CreateProfileScreen(),
                ),
              );
              if (result == true) _loadProfiles();
            },
            color: AppColors.blue,
            shadowColor: AppColors.blueShadow,
            child: const Text(
              'İLK PROFİLİ OLUŞTUR',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}
