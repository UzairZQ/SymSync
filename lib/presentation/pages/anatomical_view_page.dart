import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/services/signal_processor.dart';
import '../bloc/session_bloc.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_card.dart';
import '../widgets/session_visuals.dart';

class AnatomicalViewContent extends StatelessWidget {
  const AnatomicalViewContent({super.key});

  @override
  Widget build(BuildContext context) {
    final processor = const SignalProcessor();
    return BlocBuilder<SessionBloc, SessionState>(
      builder: (context, state) {
        final leftActivation = state.liveActivation;
        final rightActivation = state.symmetryIndex == null
            ? null
            : (1 - state.liveActivation).clamp(0.0, 1.0).toDouble();
        final imbalanceLabel = state.symmetryIndex == null
            ? 'Awaiting second channel to compare sides.'
            : state.symmetryIndex! < 0
            ? 'Left side is ${(state.symmetryIndex!.abs() * 100).toStringAsFixed(0)}% more active.'
            : 'Right side is ${(state.symmetryIndex! * 100).toStringAsFixed(0)}% more active.';

        return ListView(
          key: const PageStorageKey<String>('anatomical'),
          padding: const EdgeInsets.only(bottom: AppTheme.spaceXXL),
          children: <Widget>[
            Row(
              children: <Widget>[
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        'Lower Extremity\nNeural Load',
                        style: AppTheme.headingLarge.copyWith(
                          color: context.txtPrimary,
                          fontSize: 28,
                          height: 1.15,
                        ),
                      ),
                      const SizedBox(height: AppTheme.spaceXS),
                      Text(
                        'Real-time heatmap visualization of neuromuscular engagement across primary muscle groups on the anterior chain.',
                        style: AppTheme.bodyLarge.copyWith(
                          color: context.txtSecondary,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(AppTheme.spaceSM),
                  decoration: BoxDecoration(
                    color: state.isConnected
                        ? AppTheme.accentGreen.withValues(alpha: 0.16)
                        : context.bgElevated,
                    borderRadius: BorderRadius.circular(AppTheme.radiusLG),
                  ),
                  child: Icon(
                    Icons.bluetooth,
                    color: state.isConnected
                        ? AppTheme.accentGreen
                        : context.txtTertiary,
                    size: 22,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppTheme.spaceLG),
            AppCard(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  SizedBox(
                    height: 320,
                    child: Stack(
                      children: <Widget>[
                        Positioned.fill(
                          child: Opacity(
                            opacity: 0.12,
                            child: Container(
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: <Color>[
                                    AppTheme.accentTeal,
                                    AppTheme.accentAmber,
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(
                                  AppTheme.radiusXL,
                                ),
                              ),
                            ),
                          ),
                        ),
                        Center(
                          child: SizedBox(
                            height: 260,
                            child: LegPairSilhouette(
                              leftActivation: leftActivation,
                              rightActivation: rightActivation,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppTheme.spaceXL),
                  _LegendCard(),
                  const SizedBox(height: AppTheme.spaceXL),
                  AppCard(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          imbalanceLabel,
                          style: AppTheme.bodyLarge.copyWith(
                            color: context.txtPrimary,
                            fontWeight: FontWeight.w800,
                            height: 1.4,
                          ),
                        ),
                        const SizedBox(height: AppTheme.spaceMD),
                        Text(
                          state.symmetryIndex == null
                              ? 'Connect the second channel for full side-by-side comparison.'
                              : processor.correctiveInstruction(
                                  state.symmetryIndex,
                                ),
                          style: AppTheme.bodyMedium.copyWith(
                            color: context.txtSecondary,
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppTheme.spaceXL),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppTheme.spaceMD,
                        vertical: AppTheme.spaceSM,
                      ),
                      decoration: BoxDecoration(
                        color: context.bgElevated,
                        borderRadius: BorderRadius.circular(AppTheme.radiusLG),
                        border: Border.all(color: context.dividerClr),
                      ),
                      child: Text(
                        'Vastus Lateralis',
                        style: AppTheme.bodyLarge.copyWith(
                          color: AppTheme.accentGreen,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

class _LegendCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          _LegendItem(color: AppTheme.accentLime, label: 'Optimal range'),
          const SizedBox(height: 10),
          _LegendItem(color: AppTheme.accentTeal, label: 'Hypotonic state'),
        ],
      ),
    );
  }
}

class _LegendItem extends StatelessWidget {
  const _LegendItem({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 10),
        Text(
          label.toUpperCase(),
          style: AppTheme.labelSmall.copyWith(
            color: context.txtSecondary,
            letterSpacing: 0.8,
          ),
        ),
      ],
    );
  }
}
