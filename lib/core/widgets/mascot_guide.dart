import 'package:flutter/material.dart';
import '../app_colors.dart';

class MascotGuide extends StatelessWidget {
  final double size;
  final String emoji;

  const MascotGuide({
    super.key,
    this.size = 48,
    this.emoji = '🦊',
  });

  const MascotGuide.mini({super.key})
      : size = 48,
        emoji = '🦊';

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 10,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      alignment: Alignment.center,
      child: Text(
        emoji,
        style: TextStyle(fontSize: size * 0.6),
      ),
    );
  }
}
