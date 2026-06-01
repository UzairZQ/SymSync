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
        borderRadius: BorderRadius.circular(999),
        splashColor: AppTheme.accentGreen.withValues(alpha: 0.12),
        child: Container(
          height: widget.height,
          decoration: BoxDecoration(
            color: enabled ? context.txtPrimary : context.bgElevated,
            borderRadius: BorderRadius.circular(999),
            boxShadow: enabled
                ? const <BoxShadow>[
                    BoxShadow(
                      color: Color(0x24000000),
                      blurRadius: 18,
                      offset: Offset(0, 10),
                    ),
                  ]
                : null,
          ),
          alignment: Alignment.center,
          child: Text(
            widget.label,
            style: AppTheme.bodyLarge.copyWith(
              color: enabled ? context.bgPrimary : context.txtSecondary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }
}
