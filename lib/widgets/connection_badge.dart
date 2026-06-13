import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class ConnectionBadge extends StatelessWidget {
  const ConnectionBadge({
    super.key,
    required this.isConnected,
    required this.isConnecting,
  });

  final bool isConnected;
  final bool isConnecting;

  @override
  Widget build(BuildContext context) {
    final Color color;
    final String label;
    if (isConnecting) {
      color = AppTheme.accentAmber;
      label = 'Connecting';
    } else if (isConnected) {
      color = AppTheme.accentGreen;
      label = 'Connected';
    } else {
      color = context.txtTertiary;
      label = 'Not Connected';
    }

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.spaceSM + 2,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: context.bgCard,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: context.dividerClr),
        boxShadow: context.cardShadow,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: AppTheme.spaceSM),
          Text(
            label,
            style: AppTheme.labelSmall.copyWith(
              color: context.txtPrimary,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.4,
            ),
          ),
        ],
      ),
    );
  }
}
