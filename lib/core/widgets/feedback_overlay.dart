import 'package:flutter/material.dart';
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
        return ScaleTransition(
          scale: CurvedAnimation(parent: anim, curve: Curves.easeOutBack),
          child: child,
        );
      },
    );
    await Future.delayed(duration);
    if (context.mounted) {
      Navigator.of(context, rootNavigator: true).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final Color accent = type == FeedbackType.success
        ? AppColors.leafGreen
        : AppColors.sunYellow;
    final String emoji = type == FeedbackType.success ? '🎉' : '💡';

    return Material(
      color: Colors.transparent,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 24),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(32),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.12),
              blurRadius: 16,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedScale(
              scale: 1.0,
              duration: const Duration(milliseconds: 300),
              child: Text(emoji, style: const TextStyle(fontSize: 64)),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w900,
                color: AppColors.darkText,
              ),
            ),
            if (message != null) ...[
              const SizedBox(height: 8),
              Text(
                message!,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.gray,
                ),
              ),
            ],
            const SizedBox(height: 8),
            Container(
              width: 60,
              height: 6,
              decoration: BoxDecoration(
                color: accent,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
