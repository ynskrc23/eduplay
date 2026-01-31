import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'data/repositories/child_repository.dart';
import 'features/child_profile/screens/create_profile_screen.dart';
import 'features/game/screens/game_page.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  runApp(const EduPlayApp());
}

class EduPlayApp extends StatelessWidget {
  const EduPlayApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'EduPlay Matematik',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.indigo,
          brightness: Brightness.light,
        ),
        fontFamily: 'Roboto',
      ),
      home: const BootScreen(),
    );
  }
}

class BootScreen extends StatefulWidget {
  const BootScreen({super.key});

  @override
  State<BootScreen> createState() => _BootScreenState();
}

class _BootScreenState extends State<BootScreen> {
  @override
  void initState() {
    super.initState();
    _checkProfileStatus();
  }

  Future<void> _checkProfileStatus() async {
    // Add artificial delay for splash effect and DB init
    await Future.delayed(const Duration(seconds: 1));
    
    final repository = ChildRepository();
    
    // You can uncomment this following line to simulate "New Device" experience
    // await repository._dbHelper.deleteDatabase('eduplay.db'); 
    
    try {
      final hasProfile = await repository.hasAnyProfile();

      if (mounted) {
        if (hasProfile) {
          // Profile exists -> Go to Game
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => const GamePage()),
          );
        } else {
          // No profile -> Go to Create Profile
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => const CreateProfileScreen()),
          );
        }
      }
    } catch (e) {
      // Fallback
      if (mounted) {
         Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => const CreateProfileScreen()),
          );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.indigo,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
             Container(
              padding: const EdgeInsets.all(24),
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.school_rounded, size: 80, color: Colors.indigo),
            ),
            const SizedBox(height: 24),
            const Text(
              "EduPlay",
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 48),
            const CircularProgressIndicator(color: Colors.white),
          ],
        ),
      ),
    );
  }
}
