import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../bloc/session_bloc.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_card.dart';
import '../../widgets/section_label.dart';

class ActivationSummaryPage extends StatefulWidget {
  const ActivationSummaryPage({super.key});

  @override
  State<ActivationSummaryPage> createState() => _ActivationSummaryPageState();
}

class _ActivationSummaryPageState extends State<ActivationSummaryPage> {
  int _periodIndex = 1;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SessionBloc, SessionState>(
      builder: (context, state) {
        final trendValue = state.symmetryIndex ?? 0.18;
        final deviation = (trendValue.abs() * 100).toStringAsFixed(0);
        final trendingUp = trendValue >= 0;
        final historyCount = state.history.length;

        return ListView(
          key: const PageStorageKey<String>('summary'),
          padding: const EdgeInsets.only(bottom: AppTheme.spaceXXL),
          children: <Widget>[
            Text(
              'Activation Summary',
              style: AppTheme.headingLarge.copyWith(
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: AppTheme.spaceXS),
            Text(
              'Review your recent symmetry and muscle pattern trends',
              style: AppTheme.bodyLarge.copyWith(color: AppTheme.textSecondary),
            ),
            const SizedBox(height: AppTheme.spaceXL),
            AppCard(
              padding: const EdgeInsets.all(AppTheme.spaceMD),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  const SectionLabel(label: 'Imbalance heatmap'),
                  const SizedBox(height: AppTheme.spaceMD),
                  SizedBox(
                    height: 240,
                    child: Stack(
                      alignment: Alignment.center,
                      children: <Widget>[
                        Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(
                              AppTheme.radiusXL,
                            ),
                            gradient: const LinearGradient(
                              colors: [
                                AppTheme.backgroundElevated,
                                AppTheme.backgroundCard,
                              ],
                            ),
                          ),
                        ),
                        Positioned(
                          top: 30,
                          child: Container(
                            width: 160,
                            height: 220,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(100),
                              gradient: RadialGradient(
                                colors: <Color>[
                                  AppTheme.accentAmber.withValues(alpha: 0.24),
                                  Colors.transparent,
                                ],
                                radius: 0.6,
                              ),
                            ),
                          ),
                        ),
                        Positioned(
                          left: 50,
                          top: 60,
                          child: Container(
                            width: 90,
                            height: 130,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(60),
                              gradient: RadialGradient(
                                colors: <Color>[
                                  AppTheme.accentBlue.withValues(alpha: 0.26),
                                  Colors.transparent,
                                ],
                                radius: 0.6,
                              ),
                            ),
                          ),
                        ),
                        Positioned(
                          right: 50,
                          top: 80,
                          child: Container(
                            width: 90,
                            height: 130,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(60),
                              gradient: RadialGradient(
                                colors: <Color>[
                                  AppTheme.accentAmber.withValues(alpha: 0.26),
                                  Colors.transparent,
                                ],
                                radius: 0.6,
                              ),
                            ),
                          ),
                        ),
                        Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: <Widget>[
                            Icon(
                              Icons.person_outline,
                              size: 88,
                              color: AppTheme.textTertiary.withValues(
                                alpha: 0.16,
                              ),
                            ),
                            const SizedBox(height: AppTheme.spaceSM),
                            Text(
                              'Front view history',
                              style: AppTheme.labelSmall.copyWith(
                                color: AppTheme.textSecondary,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppTheme.spaceXL),
                  Row(
                    children: <Widget>[
                      Expanded(
                        child: _summaryMetric(
                          label: 'Sessions',
                          value: '$historyCount',
                          color: AppTheme.accentTeal,
                        ),
                      ),
                      const SizedBox(width: AppTheme.spaceSM),
                      Expanded(
                        child: _summaryMetric(
                          label: 'Trend',
                          value: trendingUp ? '+8%' : '-8%',
                          color: trendingUp
                              ? AppTheme.accentAmber
                              : AppTheme.accentRed,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppTheme.spaceXL),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppTheme.spaceMD,
                vertical: AppTheme.spaceSM,
              ),
              decoration: BoxDecoration(
                color: AppTheme.backgroundCard,
                borderRadius: BorderRadius.circular(AppTheme.radiusXL),
                border: Border.all(color: AppTheme.divider),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: List<Widget>.generate(3, (index) {
                  const labels = <String>['Today', '7 Days', '30 Days'];
                  final active = _periodIndex == index;
                  return Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _periodIndex = index),
                      child: Container(
                        margin: const EdgeInsets.symmetric(
                          horizontal: AppTheme.spaceXS,
                        ),
                        padding: const EdgeInsets.symmetric(
                          vertical: AppTheme.spaceSM,
                        ),
                        decoration: BoxDecoration(
                          color: active
                              ? AppTheme.accentTeal.withValues(alpha: 0.16)
                              : AppTheme.backgroundElevated,
                          borderRadius: BorderRadius.circular(
                            AppTheme.radiusLG,
                          ),
                        ),
                        child: Text(
                          labels[index],
                          textAlign: TextAlign.center,
                          style: AppTheme.bodyMedium.copyWith(
                            color: active
                                ? AppTheme.textPrimary
                                : AppTheme.textSecondary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ),
            const SizedBox(height: AppTheme.spaceXL),
            AppCard(
              padding: const EdgeInsets.all(AppTheme.spaceMD),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: <Widget>[
                      Text(
                        'Pattern Analysis',
                        style: AppTheme.headingMedium.copyWith(
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      Text(
                        trendingUp ? '+8%' : '-8%',
                        style: AppTheme.labelSmall.copyWith(
                          color: trendingUp
                              ? AppTheme.accentAmber
                              : AppTheme.accentRed,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppTheme.spaceMD),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: <Widget>[
                      _analysisItem(
                        'Avg. Deviation',
                        '$deviation%',
                        AppTheme.textSecondary,
                      ),
                      _analysisItem(
                        'Balance',
                        historyCount > 0 ? 'Stable' : 'Pending',
                        AppTheme.textPrimary,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _summaryMetric({
    required String label,
    required String value,
    required Color color,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          label,
          style: AppTheme.bodyMedium.copyWith(
            color: AppTheme.textSecondary,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: AppTheme.spaceXS),
        Text(value, style: AppTheme.headingMedium.copyWith(color: color)),
      ],
    );
  }

  Widget _analysisItem(String title, String value, Color valueColor) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            title.toUpperCase(),
            style: AppTheme.labelSmall.copyWith(color: AppTheme.textSecondary),
          ),
          const SizedBox(height: AppTheme.spaceSM),
          Text(
            value,
            style: AppTheme.bodyLarge.copyWith(
              color: valueColor,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}
