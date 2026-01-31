import 'package:flutter/material.dart';
import '../../../data/models/child_profile.dart';
import '../../../data/repositories/child_repository.dart';
import '../../game/screens/game_page.dart';

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

      await _repository.createProfile(newProfile);

      if (mounted) {
        // Navigate to Game Page after successful creation
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const GamePage()),
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
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.blue.shade300,
              Colors.blue.shade800,
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Card(
                elevation: 12,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                child: Padding(
                  padding: const EdgeInsets.all(32.0),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.person_add_rounded, size: 64, color: Colors.blue),
                        const SizedBox(height: 24),
                        Text(
                          'Yeni Profil Oluştur',
                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Colors.blue.shade900,
                          ),
                        ),
                        const SizedBox(height: 32),
                        
                        // Avatar Selection
                        Text('Bir Avatar Seç', style: TextStyle(color: Colors.grey.shade600)),
                        const SizedBox(height: 12),
                        SizedBox(
                          height: 80,
                          child: ListView.separated(
                            scrollDirection: Axis.horizontal,
                            itemCount: _avatars.length,
                            separatorBuilder: (_, context) => const SizedBox(width: 12),
                            itemBuilder: (context, index) {
                              final avatar = _avatars[index];
                              final isSelected = _selectedAvatar == avatar;
                              return GestureDetector(
                                onTap: () => setState(() => _selectedAvatar = avatar),
                                child: Container(
                                  width: 60,
                                  height: 60,
                                  decoration: BoxDecoration(
                                    color: isSelected ? Colors.blue.shade100 : Colors.grey.shade100,
                                    shape: BoxShape.circle,
                                    border: isSelected ? Border.all(color: Colors.blue, width: 3) : null,
                                  ),
                                  alignment: Alignment.center,
                                  child: Text(avatar, style: const TextStyle(fontSize: 32)),
                                ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 32),

                        // Name Input
                        TextFormField(
                          controller: _nameController,
                          decoration: InputDecoration(
                            labelText: 'İsim',
                            prefixIcon: const Icon(Icons.badge_rounded),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            filled: true,
                            fillColor: Colors.grey.shade50,
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Lütfen bir isim girin';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),

                        // Age Input
                        TextFormField(
                          controller: _ageController,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            labelText: 'Yaş',
                            prefixIcon: const Icon(Icons.cake_rounded),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            filled: true,
                            fillColor: Colors.grey.shade50,
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Lütfen yaş girin';
                            }
                            if (int.tryParse(value) == null) {
                              return 'Geçerli bir sayı girin';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 32),

                        // Submit Button
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton(
                            onPressed: _isLoading ? null : _saveProfile,
                            style: FilledButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            child: _isLoading 
                              ? const SizedBox(
                                  height: 24, 
                                  width: 24, 
                                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)
                                )
                              : const Text('Başla 🚀', style: TextStyle(fontSize: 18)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
