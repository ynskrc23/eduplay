import 'package:flutter/material.dart';

class NeumorphicGameButton extends StatefulWidget {
  final VoidCallback? onPressed;
  final Widget child;
  final Color color;
  final Color shadowColor;
  final double? width;
  final double? height;
  final double borderRadius;
  final Border? border;
  final EdgeInsetsGeometry? padding;

  const NeumorphicGameButton({
    super.key,
    required this.onPressed,
    required this.child,
    required this.color,
    required this.shadowColor,
    this.width,
    this.height,
    this.borderRadius = 20.0,
    this.border,
    this.padding,
  });

  @override
  State<NeumorphicGameButton> createState() => _NeumorphicGameButtonState();
}

class _NeumorphicGameButtonState extends State<NeumorphicGameButton> {
  bool _isPressed = false;

  void _onTapDown(TapDownDetails details) {
    if (widget.onPressed == null) return;
    setState(() => _isPressed = true);
  }

  void _onTapUp(TapUpDetails details) {
    if (widget.onPressed == null) return;
    setState(() => _isPressed = false);
    widget.onPressed?.call();
  }

  void _onTapCancel() {
    if (widget.onPressed == null) return;
    setState(() => _isPressed = false);
  }

  @override
  Widget build(BuildContext context) {
    // Top highlight is slightly lighter
    final Color highlightColor = Color.alphaBlend(Colors.white.withValues(alpha: 0.2), widget.color);
    // Depth of the 3D effect
    const double depth = 6.0;
    
    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 50),
        width: widget.width,
        height: widget.height,
        padding: widget.padding,
        margin: EdgeInsets.only(top: _isPressed ? depth : 0.0, bottom: _isPressed ? 0.0 : depth), // Physically move the button
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(widget.borderRadius),
          border: widget.border,
          color: widget.color,
          boxShadow: _isPressed
              ? [] // Pressed: No shadow, it's "flat" against the surface
              : [
                  // Hard bottom shadow for the "block" look
                  BoxShadow(
                    color: widget.shadowColor,
                    offset: Offset(0, depth), 
                    blurRadius: 0, 
                  ),
                  // Soft drop shadow for ambient occlusion
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.2),
                    offset: Offset(0, depth + 2),
                    blurRadius: 4,
                  ),
                ],
          gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: _isPressed 
                ? [widget.shadowColor, widget.color] // Darker when pressed
                : [highlightColor, widget.color],    // Lighter when raised
          ),
        ),
        child: Center(child: widget.child),
      ),
    );
  }
}
