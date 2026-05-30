import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../theme/app_theme.dart';

class SessionTabBar extends StatelessWidget {
  const SessionTabBar({
    super.key,
    required this.selectedIndex,
    required this.onTap,
  });

  final int selectedIndex;
  final ValueChanged<int> onTap;

  static const List<IconData> _icons = [
    Icons.accessibility_new_outlined,
    Icons.linear_scale_outlined,
    Icons.show_chart_outlined,
  ];

  static const List<String> _labels = [
    'Anatomical',
    'Balance',
    'Signal',
  ];

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Leave a 4px padding on each side inside the container
        final double outerPadding = 4.0;
        final double availableWidth = constraints.maxWidth - (outerPadding * 2);
        final double tabWidth = availableWidth / 3;

        return Container(
          height: 48,
          decoration: BoxDecoration(
            color: context.bgElevated,
            borderRadius: BorderRadius.circular(AppTheme.radiusLG),
          ),
          padding: EdgeInsets.all(outerPadding),
          child: Stack(
            children: [
              AnimatedPositioned(
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeInOut,
                left: selectedIndex * tabWidth,
                width: tabWidth,
                top: 0,
                bottom: 0,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: AppTheme.tealGradient,
                    borderRadius: BorderRadius.circular(AppTheme.radiusMD),
                  ),
                ),
              ),
              Row(
                children: List.generate(3, (index) {
                  final isSelected = selectedIndex == index;
                  return Expanded(
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () => onTap(index),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            _icons[index],
                            color: isSelected ? Colors.white : context.txtTertiary,
                            size: 18,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _labels[index],
                            style: GoogleFonts.dmSans(
                              fontSize: 11,
                              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                              color: isSelected ? Colors.white : context.txtTertiary,
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
