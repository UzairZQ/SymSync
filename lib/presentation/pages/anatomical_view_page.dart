import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../bloc/session_bloc.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_card.dart';
import '../../widgets/heatmap_silhouette_widget.dart';

class AnatomicalViewContent extends StatelessWidget {
  const AnatomicalViewContent({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SessionBloc, SessionState>(
      builder: (context, state) {
        final lastSession = state.activeHistory.isNotEmpty
            ? state.activeHistory.first
            : null;
        final isLive = state.isRecording;

        final rawSymmetryIndex = isLive
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
        final hasEnoughActivity =
            state.isConnected &&
            (displayLeftActivation + displayRightActivation) >= 0.12 &&
            (displayLeftActivation > 0.04 || displayRightActivation > 0.04);
        final displaySymmetryIndex = hasEnoughActivity
            ? rawSymmetryIndex
            : null;

        final imbalanceLabel = !state.isConnected
            ? 'Connect the sensors to start.'
            : displaySymmetryIndex == null
            ? 'Move a little more to compare both sides.'
            : displaySymmetryIndex < -8
            ? 'Left side is working more.'
            : displaySymmetryIndex > 8
            ? 'Right side is working more.'
            : 'Both sides look balanced.';
        final guidanceText = !state.isConnected
            ? 'Connect both EMG sensors before comparing the shoulders.'
            : displaySymmetryIndex == null
            ? 'Move a little more so the app can compare both sides.'
            : displaySymmetryIndex.abs() < 8
            ? 'Keep both shoulders relaxed and steady.'
            : displaySymmetryIndex > 0
            ? 'Try relaxing the right shoulder or sharing the effort with the left side.'
            : 'Try relaxing the left shoulder or sharing the effort with the right side.';
        final signalStatus = state.status == SessionStatus.signalLost
            ? 'Signal unstable'
            : state.isConnected
            ? 'Signal quality OK'
            : 'Signal offline';
        final baselineStatus = state.calibratedAt == null
            ? 'Baseline not calibrated'
            : 'Baseline calibrated';

        return LayoutBuilder(
          key: const PageStorageKey<String>('anatomical'),
          builder: (context, constraints) {
            final isCompact = constraints.maxHeight < 430;
            final panelPadding = isCompact ? 8.0 : 14.0;
            final visualWidth =
                (constraints.maxWidth * (isCompact ? 0.58 : 0.70)).clamp(
                  210.0,
                  310.0,
                );
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
                                'See which shoulder is working more.',
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
                    SizedBox(height: isCompact ? 6 : 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: <Widget>[
                          Expanded(
                            child: Container(
                              padding: EdgeInsets.all(panelPadding),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF0F4F8),
                                borderRadius: AppTheme.cardRadius,
                                border: Border.all(color: context.dividerClr),
                                boxShadow: context.cardShadow,
                              ),
                              child: HeatmapSilhouetteWidget(
                                leftActivation: displayLeftActivation,
                                rightActivation: displayRightActivation,
                                width: visualWidth,
                              ),
                            ),
                          ),
                          SizedBox(height: isCompact ? 6 : 10),
                          _ActivationMetricsRow(
                            leftActivation: displayLeftActivation,
                            rightActivation: displayRightActivation,
                            leftRms: isLive ? state.leftTrapRms : null,
                            rightRms: isLive ? state.rightTrapRms : null,
                            compact: isCompact,
                          ),
                          SizedBox(height: isCompact ? 6 : 10),
                          AppCard(
                            padding: EdgeInsets.all(isCompact ? 10 : 14),
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
                                    height: isCompact ? 1.15 : 1.2,
                                  ),
                                ),
                                SizedBox(height: isCompact ? 3 : 5),
                                Text(
                                  guidanceText,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: AppTheme.bodySmall.copyWith(
                                    color: context.txtSecondary,
                                    height: isCompact ? 1.2 : 1.25,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          SizedBox(height: isCompact ? 6 : 10),
                          _SignalQualityRow(
                            signalStatus: signalStatus,
                            baselineStatus: baselineStatus,
                            connected: state.isConnected,
                            calibrated: state.calibratedAt != null,
                            compact: isCompact,
                          ),
                        ],
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

class _ActivationMetricsRow extends StatelessWidget {
  const _ActivationMetricsRow({
    required this.leftActivation,
    required this.rightActivation,
    required this.leftRms,
    required this.rightRms,
    required this.compact,
  });

  final double leftActivation;
  final double rightActivation;
  final double? leftRms;
  final double? rightRms;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Expanded(
          child: _MetricPill(
            label: 'Left Trapezius',
            value: '${(leftActivation * 100).round()}%',
            rms: leftRms,
            compact: compact,
          ),
        ),
        SizedBox(width: compact ? 5 : 8),
        Expanded(
          child: _MetricPill(
            label: 'Right Trapezius',
            value: '${(rightActivation * 100).round()}%',
            rms: rightRms,
            compact: compact,
          ),
        ),
      ],
    );
  }
}

class _SignalQualityRow extends StatelessWidget {
  const _SignalQualityRow({
    required this.signalStatus,
    required this.baselineStatus,
    required this.connected,
    required this.calibrated,
    required this.compact,
  });

  final String signalStatus;
  final String baselineStatus;
  final bool connected;
  final bool calibrated;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Expanded(
          child: _StatusPill(
            icon: Icons.sensors_rounded,
            label: signalStatus,
            active: connected,
            compact: compact,
          ),
        ),
        SizedBox(width: compact ? 5 : 8),
        Expanded(
          child: _StatusPill(
            icon: Icons.tune_rounded,
            label: baselineStatus,
            active: calibrated,
            compact: compact,
          ),
        ),
      ],
    );
  }
}

class _MetricPill extends StatelessWidget {
  const _MetricPill({
    required this.label,
    required this.value,
    required this.rms,
    required this.compact,
  });

  final String label;
  final String value;
  final double? rms;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 7 : 10,
        vertical: compact ? 5 : 7,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.78),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: context.dividerClr.withValues(alpha: 0.58)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTheme.labelSmall.copyWith(
              color: context.txtTertiary,
              fontSize: compact ? 7.5 : 8,
              letterSpacing: 0.25,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTheme.headingMedium.copyWith(
              color: context.txtPrimary,
              fontSize: compact ? 12 : 14,
              height: 1,
            ),
          ),
          if (rms != null) ...[
            const SizedBox(height: 2),
            Text(
              'RMS ${rms!.toStringAsFixed(0)} ADC',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTheme.labelSmall.copyWith(
                color: context.txtTertiary,
                fontSize: compact ? 7 : 8,
                letterSpacing: 0,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({
    required this.icon,
    required this.label,
    required this.active,
    required this.compact,
  });

  final IconData icon;
  final String label;
  final bool active;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final color = active ? AppTheme.accentGreen : AppTheme.accentAmber;
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 7 : 10,
        vertical: compact ? 5 : 7,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.22)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(icon, size: compact ? 12 : 14, color: color),
          const SizedBox(width: 5),
          Expanded(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTheme.labelSmall.copyWith(
                color: color,
                fontSize: compact ? 8.5 : 9.5,
                fontWeight: FontWeight.w800,
                letterSpacing: 0,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
