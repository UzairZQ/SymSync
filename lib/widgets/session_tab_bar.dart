import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class SessionTabBar extends StatelessWidget {
  const SessionTabBar({
    super.key,
    required this.selectedIndex,
    required this.onTap,
    required this.labels,
  });

  final int selectedIndex;
  final ValueChanged<int> onTap;
  final List<String> labels;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final double availableWidth = constraints.maxWidth;
        final double tabWidth = availableWidth / labels.length;

        return SizedBox(
          height: 43,
          child: Stack(
            children: [
              AnimatedPositioned(
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeInOut,
                left: selectedIndex * tabWidth,
                width: tabWidth,
                top: 0,
                bottom: 0,
                child: Align(
                  alignment: Alignment.bottomCenter,
                  child: Container(
                    width: 48,
                    height: 2,
                    color: context.txtPrimary,
                  ),
                ),
              ),
              Row(
                children: List.generate(labels.length, (index) {
                  final isSelected = selectedIndex == index;
                  return Expanded(
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () => onTap(index),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            labels[index],
                            style: AppTheme.labelSmall.copyWith(
                              fontSize: 12,
                              letterSpacing: 0,
                              fontWeight: isSelected
                                  ? FontWeight.w800
                                  : FontWeight.w600,
                              color: isSelected
                                  ? context.txtPrimary
                                  : context.txtSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }),
              ),
            ],
          ),
        );
      },
    );
  }
}
