import 'package:flutter/material.dart';
import '../../../data/models/child_profile.dart';
import '../../../data/repositories/child_repository.dart';
import '../../../core/app_colors.dart';
import '../../../core/widgets/duo_button.dart';
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
          MaterialPageRoute(builder: (context) => GameHubScreen(childId: createdProfile.id!)),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Hata oluştu: $e')),
        );
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
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 48.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const Text(
                  'PROFİL OLUŞTUR',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    color: AppColors.textMain,
                    letterSpacing: 1.5,
                  ),
                ),
                const SizedBox(height: 48),
                
                // Avatar Selection
                const Text(
                  'BİR AVATAR SEÇ',
                  style: TextStyle(color: AppColors.gray, fontWeight: FontWeight.w900, fontSize: 14),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  height: 100,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: _avatars.length,
                    separatorBuilder: (_, context) => const SizedBox(width: 16),
                    itemBuilder: (context, index) {
                      final avatar = _avatars[index];
                      final isSelected = _selectedAvatar == avatar;
                      return DuoButton(
                        width: 80,
                        height: 80,
                        color: isSelected ? AppColors.blue : AppColors.white,
                        shadowColor: isSelected ? AppColors.blueShadow : AppColors.lightGray,
                        onPressed: () => setState(() => _selectedAvatar = avatar),
                        child: Text(avatar, style: const TextStyle(fontSize: 40)),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 48),

                // Name Input
                _buildDuoInput(
                  controller: _nameController,
                  label: 'İSİM',
                  hint: 'Adın ne?',
                  icon: Icons.face_rounded,
                ),
                const SizedBox(height: 24),

                // Age Input
                _buildDuoInput(
                  controller: _ageController,
                  label: 'YAŞ',
                  hint: 'Kaç yaşındasın?',
                  icon: Icons.cake_rounded,
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 64),

                // Submit Button
                DuoButton(
                  onPressed: _isLoading ? null : _saveProfile,
                  color: AppColors.green,
                  shadowColor: AppColors.greenShadow,
                  child: _isLoading 
                    ? const SizedBox(
                        height: 24, 
                        width: 24, 
                        child: CircularProgressIndicator(strokeWidth: 3, color: Colors.white)
                      )
                    : const Text(
                        'BAŞLA!',
                        style: TextStyle(color: AppColors.white, fontWeight: FontWeight.w900, fontSize: 20),
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(color: AppColors.gray, fontWeight: FontWeight.w900, fontSize: 14),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: AppColors.lightGray.withOpacity(0.3),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.lightGray, width: 2),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: TextFormField(
            controller: controller,
            keyboardType: keyboardType,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textMain),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: const TextStyle(color: AppColors.gray),
              border: InputBorder.none,
              icon: Icon(icon, color: AppColors.blueShadow),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Lütfen burayı doldur';
              }
              return null;
            },
          ),
        ),
      ],
    );
  }
}
