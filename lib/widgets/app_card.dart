import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(AppTheme.spaceMD),
  });

  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: context.bgCard,
        borderRadius: AppTheme.cardRadius,
        border: Border.all(color: context.dividerClr),
        boxShadow: context.cardShadow,
      ),
      child: child,
    );
  }
}
