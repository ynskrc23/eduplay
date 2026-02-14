import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'data/repositories/child_repository.dart';
import 'features/child_profile/screens/create_profile_screen.dart';
import 'features/game/screens/game_hub_screen.dart';

import 'package:intl/date_symbol_data_local.dart';

import 'core/app_theme.dart';
import 'core/services/admob_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // UNCOMMENT the line below and run once to RESET the database
  // await DatabaseHelper.instance.resetDatabase();

  await initializeDateFormatting('tr_TR', null);
  
  // AdMob SDK'yı başlat
  await AdMobService().initialize();
  
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  runApp(const MatematiKoyApp());
}

class MatematiKoyApp extends StatelessWidget {
  const MatematiKoyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MatematiKöy',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: TextScaler.noScaling,
          ),
          child: child!,
        );
      },
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

    // For development: Uncomment the following line once to reset DB and apply schema changes
    // await repository.deleteDatabaseForDev();
    try {
      final profiles = await repository.getAllProfiles();

      if (mounted) {
        if (profiles.isNotEmpty) {
          // Profile exists -> Go to Level Map
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (context) => GameHubScreen(childId: profiles.first.id!),
            ),
          );
        } else {
          // No profile -> Go to Create Profile
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (context) => const CreateProfileScreen(),
            ),
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
              child: const Icon(
                Icons.school_rounded,
                size: 80,
                color: Colors.indigo,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              "MatematiKöy",
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
