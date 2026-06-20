import 'package:flutter_test/flutter_test.dart';
import 'package:sym_sync/theme/accessibility_provider.dart';
import 'package:sym_sync/utils/heatmap_utils.dart';

void main() {
  tearDown(() {
    AccessibilityProvider.colorBlindNotifier.value = false;
  });

  test('color-blind mode switches to the accessible heatmap palette', () {
    AccessibilityProvider.colorBlindNotifier.value = false;
    final standard = HeatmapGradient.at(0.75);

    AccessibilityProvider.colorBlindNotifier.value = true;
    final accessible = HeatmapGradient.at(0.75);

    expect(accessible, isNot(standard));
    expect(HeatmapGradient.activeColors, HeatmapGradient.accessibleColors);
  });

  test('accessible balance palette remains symmetric around center', () {
    AccessibilityProvider.colorBlindNotifier.value = true;

    expect(BalanceGradient.at(0), BalanceGradient.accessibleColors.first);
    expect(BalanceGradient.at(1), BalanceGradient.accessibleColors.last);
    expect(BalanceGradient.at(0.5), BalanceGradient.accessibleColors[2]);
  });
}
