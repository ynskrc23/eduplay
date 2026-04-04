import 'package:flutter/material.dart';

class DuoButton extends StatefulWidget {
  final Widget child;
  final VoidCallback? onPressed;
  final Color color;
  final Color shadowColor;
  final double height;
  final double? width; // Changed to double?

  const DuoButton({
    super.key,
    required this.child,
    this.onPressed,
    required this.color,
    required this.shadowColor,
    this.height = 50,
    this.width, // Defaults to null (expanded)
  });

  @override
  State<DuoButton> createState() => _DuoButtonState();
}

class _DuoButtonState extends State<DuoButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    const double shadowHeight = 6.0;
    
    return LayoutBuilder(
      builder: (context, constraints) {
        final double finalWidth = widget.width ?? constraints.maxWidth;
        
        return GestureDetector(
          onTapDown: (_) => setState(() => _isPressed = true),
          onTapUp: (_) {
            setState(() => _isPressed = false);
            widget.onPressed?.call();
          },
          onTapCancel: () => setState(() => _isPressed = false),
          child: SizedBox(
            width: finalWidth,
            height: widget.height + shadowHeight,
            child: Stack(
              children: [
                // Shadow
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    height: widget.height,
                    decoration: BoxDecoration(
                      color: widget.shadowColor,
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
                // Top Layer
                AnimatedPositioned(
                  duration: const Duration(milliseconds: 50),
                  bottom: _isPressed ? 0 : shadowHeight,
                  left: 0,
                  right: 0,
                  child: Container(
                    height: widget.height,
                    decoration: BoxDecoration(
                      color: widget.color,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.1),
                        width: 1,
                      ),
                    ),
                    alignment: Alignment.center,
                    child: widget.child,
                  ),
                ),
              ],
            ),
          ),
        );
      }
    );
  }
}
