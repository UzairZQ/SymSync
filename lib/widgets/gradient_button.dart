import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class GradientButton extends StatefulWidget {
  const GradientButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.enabled = true,
    this.height = 56,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool enabled;
  final double height;

  @override
  State<GradientButton> createState() => _GradientButtonState();
}

class _GradientButtonState extends State<GradientButton> {
  bool _pressed = false;

  void _updatePressed(bool pressed) {
    if (!_pressed && pressed || _pressed && !pressed) {
      setState(() {
        _pressed = pressed;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final enabled = widget.enabled && widget.onPressed != null;
    return AnimatedScale(
      scale: _pressed ? 0.97 : 1,
      duration: const Duration(milliseconds: 120),
      curve: Curves.easeOut,
      child: InkWell(
        onTap: enabled ? widget.onPressed : null,
        onTapDown: (_) => _updatePressed(true),
        onTapUp: (_) => _updatePressed(false),
        onTapCancel: () => _updatePressed(false),
        borderRadius: BorderRadius.circular(AppTheme.radiusMD),
        splashColor: AppTheme.accentTeal.withOpacity(0.12),
        child: Container(
          height: widget.height,
          decoration: BoxDecoration(
            gradient: enabled ? AppTheme.tealGradient : null,
            color: enabled ? null : AppTheme.backgroundElevated,
            borderRadius: BorderRadius.circular(AppTheme.radiusMD),
            boxShadow: enabled ? AppTheme.tealGlow : null,
          ),
          alignment: Alignment.center,
          child: Text(
            widget.label,
            style: AppTheme.bodyLarge.copyWith(
              color: enabled ? Colors.white : AppTheme.textSecondary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }
}
