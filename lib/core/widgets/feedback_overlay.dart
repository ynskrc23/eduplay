import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import '../app_colors.dart';

enum FeedbackType { success, gentleWrong }

class FeedbackOverlay extends StatelessWidget {
  final FeedbackType type;
  final String title;
  final String? message;

  const FeedbackOverlay({
    super.key,
    required this.type,
    required this.title,
    this.message,
  });

  static Future<void> show(
    BuildContext context, {
    required FeedbackType type,
    required String title,
    String? message,
    Duration duration = const Duration(milliseconds: 1200),
  }) async {
    await showGeneralDialog(
      context: context,
      barrierColor: Colors.black45,
      barrierDismissible: false,
      barrierLabel: 'feedback',
      transitionDuration: const Duration(milliseconds: 250),
      pageBuilder: (_, __, ___) {
        return Align(
          alignment: Alignment.center,
          child: FeedbackOverlay(type: type, title: title, message: message),
        );
      },
      transitionBuilder: (_, anim, __, child) {
        return ScaleTransition(scale: CurvedAnimation(parent: anim, curve: Curves.easeOutBack), child: child);
      },
    );
    await Future.delayed(duration);
    Navigator.of(context, rootNavigator: true).pop();
  }

  @override
  Widget build(BuildContext context) {
    final String lottieUrl = switch (type) {
      FeedbackType.success =>
        'https://lottie.host/7c295a0e-9a6c-44b4-9f39-2e3f3f0f1af9/9wCzKJpHfF.json', // fireworks
      FeedbackType.gentleWrong =>
        'https://lottie.host/14f40602-7b2f-4dca-b4e4-79b3b6badd4d/NpR7rIuXgY.json', // soft warning
    };

    final Color accent = type == FeedbackType.success ? AppColors.leafGreen : AppColors.sunYellow;

    return Material(
      color: Colors.transparent,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 24),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(32),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.12), blurRadius: 16, offset: const Offset(0, 8)),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              height: 120,
              child: Lottie.network(lottieUrl, repeat: false),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: AppColors.darkText),
            ),
            if (message != null) ...[
              const SizedBox(height: 8),
              Text(
                message!,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.gray),
              ),
            ],
            const SizedBox(height: 8),
            Container(
              width: 60,
              height: 6,
              decoration: BoxDecoration(color: accent, borderRadius: BorderRadius.circular(3)),
            ),
          ],
        ),
      ),
    );
  }
}
