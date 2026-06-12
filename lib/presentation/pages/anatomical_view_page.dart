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
        final isLive = state.isConnected;

        final displaySymmetryIndex = isLive
            ? state.symmetryIndex
            : lastSession?.averageSymmetryIndex;
        final displayLeftActivation =
            (isLive
                    ? state.normalisedLeftActivation
                    : (lastSession?.averageLeftActivation ?? 0.0))
                .clamp(0.0, 1.0);
        final displayRightActivation =
            (isLive
                    ? state.normalisedRightActivation
                    : (lastSession?.averageRightActivation ?? 0.0))
                .clamp(0.0, 1.0);

        final imbalanceLabel = displaySymmetryIndex == null
            ? 'Connect both EMG cables to see bilateral muscle activation.'
            : displaySymmetryIndex < 0
            ? 'Left side is ${displaySymmetryIndex.abs().toStringAsFixed(0)}% more active.'
            : displaySymmetryIndex > 0
            ? 'Right side is ${displaySymmetryIndex.toStringAsFixed(0)}% more active.'
            : 'Both sides are balanced.';

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
                        'Muscle\nActivation',
                        style: AppTheme.headingLarge.copyWith(
                          color: context.txtPrimary,
                          fontSize: 28,
                          height: 1.15,
                        ),
                      ),
                      const SizedBox(height: AppTheme.spaceXS),
                      Text(
                        'Live symmetry map of your upper back during movement.',
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
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: const Color(0xFFF0F4F8),
                borderRadius: AppTheme.cardRadius,
                border: Border.all(color: context.dividerClr),
                boxShadow: context.cardShadow,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  SizedBox(
                    height: 340,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: HeatmapSilhouetteWidget(
                        leftActivation: displayLeftActivation,
                        rightActivation: displayRightActivation,
                        width: 260,
                      ),
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
                              ? 'Start recording with both channels connected to see corrective guidance.'
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
