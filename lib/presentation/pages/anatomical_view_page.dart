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
        final lastSession = state.activeHistory.isNotEmpty
            ? state.activeHistory.first
            : null;
        final isLive = state.isRecording;

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

        return LayoutBuilder(
          key: const PageStorageKey<String>('anatomical'),
          builder: (context, constraints) {
            return SingleChildScrollView(
              physics: const ClampingScrollPhysics(),
              child: SizedBox(
                height: constraints.maxHeight,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    Row(
                      children: <Widget>[
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Text(
                                'Muscle Activation',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: AppTheme.headingLarge.copyWith(
                                  color: context.txtPrimary,
                                  height: 1.05,
                                  fontSize: 21,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Live upper-back symmetry map.',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: AppTheme.bodySmall.copyWith(
                                  color: context.txtSecondary,
                                  height: 1.2,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.all(5),
                          decoration: BoxDecoration(
                            color: state.isConnected
                                ? AppTheme.accentGreen.withValues(alpha: 0.16)
                                : context.bgElevated,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Icon(
                            Icons.bluetooth,
                            color: state.isConnected
                                ? AppTheme.accentGreen
                                : context.txtTertiary,
                            size: 16,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF0F4F8),
                          borderRadius: AppTheme.cardRadius,
                          border: Border.all(color: context.dividerClr),
                          boxShadow: context.cardShadow,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: <Widget>[
                            Expanded(
                              child: HeatmapSilhouetteWidget(
                                leftActivation: displayLeftActivation,
                                rightActivation: displayRightActivation,
                                width: 170,
                              ),
                            ),
                            const SizedBox(height: 6),
                            AppCard(
                              padding: const EdgeInsets.all(10),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: <Widget>[
                                  Text(
                                    imbalanceLabel,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: AppTheme.bodyMedium.copyWith(
                                      color: context.txtPrimary,
                                      fontWeight: FontWeight.w800,
                                      height: 1.15,
                                    ),
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    displaySymmetryIndex == null
                                        ? 'Start recording with both channels connected.'
                                        : processor.correctiveInstruction(
                                            displaySymmetryIndex,
                                          ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: AppTheme.bodySmall.copyWith(
                                      color: context.txtSecondary,
                                      height: 1.2,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 6),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: <Widget>[
                                Text(
                                  'TARGET MUSCLE',
                                  style: AppTheme.labelSmall.copyWith(
                                    color: context.txtTertiary,
                                    letterSpacing: 0.8,
                                    fontSize: 9,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                const Expanded(
                                  child: Wrap(
                                    spacing: 6,
                                    runSpacing: 4,
                                    children: [
                                      _MuscleChip(
                                        label: 'Trapezius',
                                        selected: true,
                                      ),
                                      _MuscleChip(label: 'Deltoid'),
                                      _MuscleChip(label: 'Lat'),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
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
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
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
          fontSize: 10,
        ),
      ),
    );
  }
}
