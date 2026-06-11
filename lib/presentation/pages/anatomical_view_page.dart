import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/services/signal_processor.dart';
import '../bloc/session_bloc.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_card.dart';
import '../../widgets/heatmap_silhouette_widget.dart';

class AnatomicalViewContent extends StatelessWidget {
  const AnatomicalViewContent({super.key});

  @override
  Widget build(BuildContext context) {
    final processor = const SignalProcessor();
    return BlocBuilder<SessionBloc, SessionState>(
      builder: (context, state) {
        final lastSession = state.history.isNotEmpty
            ? state.history.first
            : null;

        final displaySymmetryIndex = lastSession?.averageSymmetryIndex;
        final displayLeftActivation =
            (lastSession?.averageLeftActivation ?? 0.0).clamp(0.0, 1.0);
        final displayRightActivation =
            (lastSession?.averageRightActivation ?? 0.0).clamp(0.0, 1.0);

        final imbalanceLabel = displaySymmetryIndex == null
            ? 'No completed session yet — run a session to see results.'
            : displaySymmetryIndex < 0
            ? 'Right side is ${(displaySymmetryIndex.abs() * 100).toStringAsFixed(0)}% more active.'
            : 'Left side is ${(displaySymmetryIndex * 100).toStringAsFixed(0)}% more active.';

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
                        'Upper Back\nNeural Load',
                        style: AppTheme.headingLarge.copyWith(
                          color: context.txtPrimary,
                          fontSize: 28,
                          height: 1.15,
                        ),
                      ),
                      const SizedBox(height: AppTheme.spaceXS),
                      Text(
                        'Real-time heatmap visualization of neuromuscular engagement across primary muscle groups on the upper back.',
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
                    height: 340,
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
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          child: HeatmapSilhouetteWidget(
                            leftActivation: displayLeftActivation,
                            rightActivation: displayRightActivation,
                            width: 260,
                          ),
                        ),
                      ],
                    ),
                  ),
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
                          displaySymmetryIndex == null
                              ? 'Complete a session to see corrective guidance.'
                              : processor.correctiveInstruction(
                                  displaySymmetryIndex,
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
                  Text(
                    'TARGET MUSCLE GROUP',
                    style: AppTheme.labelSmall.copyWith(
                      color: context.txtTertiary,
                      letterSpacing: 1.1,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: const [
                      _MuscleChip(label: 'Trapezius', selected: true),
                      _MuscleChip(label: 'Deltoid'),
                      _MuscleChip(label: 'Lat'),
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
}

class _MuscleChip extends StatelessWidget {
  const _MuscleChip({required this.label, this.selected = false});

  final String label;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: selected ? context.txtPrimary : context.bgCard,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: selected ? context.txtPrimary : context.dividerClr,
        ),
      ),
      child: Text(
        label,
        style: AppTheme.labelSmall.copyWith(
          color: selected ? context.bgPrimary : context.txtSecondary,
          letterSpacing: 0,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

