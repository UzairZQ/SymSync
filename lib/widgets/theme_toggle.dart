import 'dart:async';

import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../theme/theme_provider.dart';

class ThemeToggle extends StatelessWidget {
  const ThemeToggle({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;
    return Semantics(
      button: true,
      label: isDark ? 'Use light theme' : 'Use dark theme',
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          unawaited(
            ThemeProvider.setThemeMode(
              isDark ? ThemeMode.light : ThemeMode.dark,
            ),
          );
        },
        child: SizedBox(
          width: 48,
          height: 48,
          child: Center(
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: context.bgElevated,
                shape: BoxShape.circle,
                border: Border.all(color: context.dividerClr),
              ),
              child: ExcludeSemantics(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  transitionBuilder: (child, animation) {
                    return RotationTransition(
                      turns: animation,
                      child: FadeTransition(opacity: animation, child: child),
                    );
                  },
                  child: Icon(
                    isDark ? Icons.wb_sunny_outlined : Icons.dark_mode_outlined,
                    key: ValueKey<bool>(isDark),
                    color: AppTheme.accentTeal,
                    size: 20,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
