import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

enum StatusBadgeState { connected, disconnected, recording, idle }

class StatusBadge extends StatelessWidget {
  const StatusBadge({super.key, required this.label, required this.state});

  final String label;
  final StatusBadgeState state;

  Color get _backgroundColor {
    switch (state) {
      case StatusBadgeState.connected:
        return AppTheme.accentGreen.withOpacity(0.14);
      case StatusBadgeState.recording:
        return AppTheme.accentRed.withOpacity(0.14);
      case StatusBadgeState.disconnected:
        return AppTheme.textTertiary.withOpacity(0.12);
      case StatusBadgeState.idle:
        return AppTheme.textTertiary.withOpacity(0.12);
    }
  }

  Color get _textColor {
    switch (state) {
      case StatusBadgeState.connected:
        return AppTheme.accentGreen;
      case StatusBadgeState.recording:
        return AppTheme.accentRed;
      case StatusBadgeState.disconnected:
        return AppTheme.textSecondary;
      case StatusBadgeState.idle:
        return AppTheme.textSecondary;
    }
  }

  Widget get _statusDot {
    final dotColor = _textColor;
    return Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(color: dotColor, shape: BoxShape.circle),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.spaceSM,
        vertical: AppTheme.spaceXS,
      ),
      decoration: BoxDecoration(
        color: _backgroundColor,
        borderRadius: BorderRadius.circular(AppTheme.radiusLG),
        border: Border.all(color: AppTheme.divider),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          _statusDot,
          const SizedBox(width: AppTheme.spaceSM),
          Text(
            label,
            style: AppTheme.bodyMedium.copyWith(
              color: _textColor,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
