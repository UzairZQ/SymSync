import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class SectionLabel extends StatelessWidget {
  const SectionLabel({super.key, required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: <Widget>[
        Container(
          width: 24,
          height: 2,
          decoration: BoxDecoration(
            color: AppTheme.accentTeal,
            borderRadius: BorderRadius.circular(1),
          ),
        ),
        const SizedBox(width: AppTheme.spaceSM),
        Text(
          label.toUpperCase(),
          style: AppTheme.labelSmall.copyWith(color: AppTheme.textTertiary),
        ),
      ],
    );
  }
}
