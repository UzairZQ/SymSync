import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class ChannelBar extends StatelessWidget {
  const ChannelBar({
    super.key,
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final double value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final boundedValue = value.clamp(0.0, 1.0);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        TweenAnimationBuilder<double>(
          tween: Tween<double>(begin: 0, end: boundedValue),
          duration: const Duration(milliseconds: 150),
          curve: Curves.easeOut,
          builder: (context, animatedValue, _) {
            return Container(
              width: 42,
              height: 180,
              decoration: BoxDecoration(
                color: AppTheme.backgroundElevated,
                borderRadius: BorderRadius.circular(AppTheme.radiusLG),
                border: Border.all(color: AppTheme.divider),
              ),
              child: Align(
                alignment: Alignment.bottomCenter,
                child: Container(
                  height: 180 * animatedValue,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(AppTheme.radiusLG),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
        const SizedBox(height: AppTheme.spaceSM),
        Text(
          label,
          style: AppTheme.bodyMedium.copyWith(
            color: AppTheme.textPrimary,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: AppTheme.spaceXS),
        Text(
          '${(boundedValue * 100).toStringAsFixed(0)}%',
          style: AppTheme.monoSmall.copyWith(color: AppTheme.textSecondary),
        ),
      ],
    );
  }
}
