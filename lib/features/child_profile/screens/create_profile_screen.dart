import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import '../../../data/models/child_profile.dart';
import '../../../data/repositories/child_repository.dart';
import '../../../core/app_colors.dart';
import '../../../core/widgets/duo_button.dart';
import '../../../core/widgets/mascot_guide.dart';
import '../../game/screens/level_map_screen.dart';
import '../../game/screens/game_hub_screen.dart';

class CreateProfileScreen extends StatefulWidget {
  final ChildProfile? profileToEdit;
  const CreateProfileScreen({super.key, this.profileToEdit});

  @override
  State<CreateProfileScreen> createState() => _CreateProfileScreenState();
}

class _CreateProfileScreenState extends State<CreateProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  DateTime? _selectedBirthDate;

  // Simple avatar selection
  final List<String> _avatars = ['🦁', '🐯', '🐻', '🐼', '🐨', '🐸', '🐱', '🐶', '🦄', '🐲'];
  String _selectedAvatar = '🦁';

  bool _isLoading = false;
  final ChildRepository _repository = ChildRepository();

  @override
  void initState() {
    super.initState();
    if (widget.profileToEdit != null) {
      _nameController.text = widget.profileToEdit!.name;
      _selectedBirthDate = widget.profileToEdit!.birthDate;
      _selectedAvatar = widget.profileToEdit!.avatarId;
    }
  }

  void _selectBirthDate(BuildContext context) {
    DateTime initialDate = _selectedBirthDate ?? DateTime.now().subtract(const Duration(days: 365 * 6));
    
    showCupertinoModalPopup(
      context: context,
      builder: (_) => Container(
        height: 300,
        color: Colors.white,
        child: Column(
          children: [
            // Kapatma/Onaylama Butonu Çubuğu
            Container(
              height: 50,
              decoration: const BoxDecoration(
                color: Color(0xFFF6F8FB),
                border: Border(bottom: BorderSide(color: AppColors.lightGray, width: 1)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  CupertinoButton(
                    child: const Text('Tamam', style: TextStyle(color: AppColors.blue, fontWeight: FontWeight.bold)),
                    onPressed: () => Navigator.of(context).pop(),
                  )
                ],
              ),
            ),
            // Cupertino Takvimi
            Expanded(
              child: SafeArea(
                top: false,
                child: CupertinoDatePicker(
                  mode: CupertinoDatePickerMode.date,
                  initialDateTime: initialDate,
                  minimumDate: DateTime(1900), // Daha eski tarihlere izin ver
                  maximumDate: DateTime.now(),
                  onDateTimeChanged: (DateTime newDate) {
                    setState(() {
                      _selectedBirthDate = newDate;
                    });
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedBirthDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lütfen doğum tarihini seçin')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      if (widget.profileToEdit != null) {
        final updatedProfile = widget.profileToEdit!.copyWith(
          name: _nameController.text.trim(),
          birthDate: _selectedBirthDate!,
          avatarId: _selectedAvatar,
        );
        await _repository.updateProfile(updatedProfile);
        if (mounted) Navigator.of(context).pop(true);
      } else {
        final newProfile = ChildProfile(
          name: _nameController.text.trim(),
          birthDate: _selectedBirthDate!,
          avatarId: _selectedAvatar,
          createdAt: DateTime.now(),
        );

        final createdProfile = await _repository.createProfile(newProfile);

        if (mounted) {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(
              builder: (context) => GameHubScreen(childId: createdProfile.id!),
            ),
            (route) => false,
          );
        }
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
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isTablet = size.width >= 600;
    final horizontal = isTablet ? 48.0 : 24.0;
    final vertical = isTablet ? 64.0 : 48.0;
    final avatarSize = isTablet ? 100.0 : 80.0;
    final isEdit = widget.profileToEdit != null;

    final titleStyle = Theme.of(context).textTheme.headlineMedium;
    final sectionLabelStyle = Theme.of(context).textTheme.bodyMedium?.copyWith(
          color: AppColors.gray,
          fontWeight: FontWeight.bold,
        );

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: (isEdit || Navigator.of(context).canPop()) ? AppBar(
        title: Text(isEdit ? 'PROFİLİ DÜZENLE' : 'YENİ PROFİL EKLE'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: AppColors.darkText,
      ) : null,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(
            horizontal: horizontal,
            vertical: isEdit ? 24 : vertical,
          ),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                if (!isEdit)
                  Row(
                    children: [
                      Expanded(child: Text('HOŞ GELDİN!', style: titleStyle)),
                      const MascotGuide.mini(),
                    ],
                  ),
                if (!isEdit) SizedBox(height: isTablet ? 56 : 48),

                // Avatar Selection
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
                SizedBox(height: isTablet ? 32 : 28),

                // Birth Date Selection
                InkWell(
                  onTap: () => _selectBirthDate(context),
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                        decoration: BoxDecoration(
                          color: AppColors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppColors.lightGray, width: 2),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.cake_rounded, color: AppColors.oceanBlue),
                            const SizedBox(width: 12),
                            Text(
                              _selectedBirthDate == null
                                  ? 'Tarih Seçin'
                                  : "${_selectedBirthDate!.day}.${_selectedBirthDate!.month}.${_selectedBirthDate!.year}",
                              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                    color: _selectedBirthDate == null 
                                        ? AppColors.gray 
                                        : AppColors.darkText,
                                  ),
                            ),
                            const Spacer(),
                            const Icon(Icons.calendar_today_rounded, size: 18, color: AppColors.gray),
                          ],
                        ),
                  ),
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
                          isEdit ? 'KAYDET' : 'BAŞLA!',
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
      style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: AppColors.darkText),
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon: Icon(icon, color: AppColors.oceanBlue),
        filled: true,
        fillColor: AppColors.white,
        border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: AppColors.lightGray, width: 2),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: AppColors.lightGray, width: 2),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: AppColors.blue, width: 2),
            ),
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
