import 'package:flutter/material.dart';
import '../../../data/models/child_profile.dart';
import '../../../data/repositories/child_repository.dart';
import '../../../core/app_colors.dart';
import '../../../core/widgets/duo_button.dart';
import '../../../core/widgets/mascot_guide.dart';
import '../../game/screens/game_page.dart';
import '../../game/screens/level_map_screen.dart';
import '../../game/screens/game_hub_screen.dart';

class CreateProfileScreen extends StatefulWidget {
  const CreateProfileScreen({super.key});

  @override
  State<CreateProfileScreen> createState() => _CreateProfileScreenState();
}

class _CreateProfileScreenState extends State<CreateProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _ageController = TextEditingController();

  // Simple avatar selection for now
  final List<String> _avatars = ['🦁', '🐯', '🐻', '🐼', '🐨', '🐸'];
  String _selectedAvatar = '🦁';

  bool _isLoading = false;
  final ChildRepository _repository = ChildRepository();

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final newProfile = ChildProfile(
        name: _nameController.text.trim(),
        age: int.parse(_ageController.text.trim()),
        avatarId: _selectedAvatar,
        createdAt: DateTime.now(),
      );

      final createdProfile = await _repository.createProfile(newProfile);

      if (mounted) {
        // Navigate to Game Hub
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => GameHubScreen(childId: createdProfile.id!),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Hata oluştu: $e')));
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _ageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isTablet = size.width >= 600;
    final horizontal = isTablet ? 48.0 : 24.0;
    final vertical = isTablet ? 64.0 : 48.0;
    final avatarSize = isTablet ? 100.0 : 80.0;
    final titleStyle = Theme.of(context).textTheme.headlineMedium;
    final sectionLabelStyle = Theme.of(
      context,
    ).textTheme.bodyMedium?.copyWith(color: AppColors.gray);
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(
            horizontal: horizontal,
            vertical: vertical,
          ),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Row(
                  children: [
                    Expanded(child: Text('PROFİL OLUŞTUR', style: titleStyle)),
                    const MascotGuide.mini(),
                  ],
                ),
                SizedBox(height: isTablet ? 56 : 48),

                // Avatar Selection
                Text('BİR AVATAR SEÇ', style: sectionLabelStyle),
                SizedBox(height: isTablet ? 28 : 24),
                SizedBox(
                  height: isTablet ? 120 : 100,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: _avatars.length,
                    separatorBuilder: (_, context) =>
                        SizedBox(width: isTablet ? 20 : 16),
                    itemBuilder: (context, index) {
                      final avatar = _avatars[index];
                      final isSelected = _selectedAvatar == avatar;
                      return DuoButton(
                        width: avatarSize,
                        height: avatarSize,
                        color: isSelected ? AppColors.blue : AppColors.white,
                        shadowColor: isSelected
                            ? AppColors.blueShadow
                            : AppColors.lightGray,
                        onPressed: () =>
                            setState(() => _selectedAvatar = avatar),
                        child: Text(
                          avatar,
                          style: TextStyle(fontSize: isTablet ? 44 : 40),
                        ),
                      );
                    },
                  ),
                ),
                SizedBox(height: isTablet ? 56 : 48),

                // Name Input
                _buildDuoInput(
                  controller: _nameController,
                  label: 'İSİM',
                  hint: 'Adın ne?',
                  icon: Icons.face_rounded,
                ),
                SizedBox(height: isTablet ? 28 : 24),

                // Age Input
                _buildDuoInput(
                  controller: _ageController,
                  label: 'YAŞ',
                  hint: 'Kaç yaşındasın?',
                  icon: Icons.cake_rounded,
                  keyboardType: TextInputType.number,
                ),
                SizedBox(height: isTablet ? 72 : 64),

                // Submit Button
                DuoButton(
                  onPressed: _isLoading ? null : _saveProfile,
                  color: AppColors.green,
                  shadowColor: AppColors.greenShadow,
                  child: _isLoading
                      ? const SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 3,
                            color: Colors.white,
                          ),
                        )
                      : Text(
                          'BAŞLA!',
                          style: Theme.of(context).textTheme.labelLarge
                              ?.copyWith(
                                color: AppColors.white,
                                fontSize: isTablet ? 22 : 20,
                              ),
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDuoInput({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      style: Theme.of(context).textTheme.bodyLarge,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, color: AppColors.oceanBlue),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Lütfen burayı doldur';
        }
        return null;
      },
    );
  }
}
