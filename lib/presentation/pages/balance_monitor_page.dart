import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/services/signal_processor.dart';
import '../bloc/session_bloc.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_card.dart';
import '../widgets/session_visuals.dart';

class BalanceMonitorContent extends StatelessWidget {
  const BalanceMonitorContent({super.key});

  @override
  Widget build(BuildContext context) {
    final processor = const SignalProcessor();
    return BlocBuilder<SessionBloc, SessionState>(
      builder: (context, state) {
        final lastSession = state.history.isNotEmpty
            ? state.history.first
            : null;
        final isRecording = state.sessionSeconds > 0;

        final displaySymmetry = lastSession?.averageSymmetryIndex;
        final leftAct = (lastSession?.averageLeftActivation ?? 0.0).clamp(0.0, 1.0);
        final rightAct = (lastSession?.averageRightActivation ?? 0.0).clamp(0.0, 1.0);

        final tiltDegrees = displaySymmetry == null
            ? null
            : (displaySymmetry / 3.0).clamp(-20.0, 20.0);

        final hasData = lastSession != null;

        String activityLabel(double activation) {
          if (activation < 0.05) return 'Inactive';
          if (activation < 0.25) return 'Low';
          if (activation < 0.50) return 'Moderate';
          return 'High';
        }

        return ListView(
          key: const PageStorageKey<String>('balance'),
          padding: const EdgeInsets.only(bottom: AppTheme.spaceXXL),
          children: <Widget>[
            Row(
              children: <Widget>[
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        'Balance Monitor',
                        style: AppTheme.headingLarge.copyWith(
                          color: context.txtPrimary,
                          fontSize: 30,
                        ),
                      ),
                      const SizedBox(height: AppTheme.spaceXS),
                      Text(
                        hasData
                            ? 'Last session results'
                            : 'Complete a session to see results',
                        style: AppTheme.bodyLarge.copyWith(
                          color: context.txtSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                if (isRecording)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppTheme.spaceSM,
                      vertical: AppTheme.spaceXS,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.accentAmber.withValues(alpha: 0.16),
                      borderRadius: BorderRadius.circular(AppTheme.radiusLG),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: AppTheme.accentAmber,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Recording',
                          style: AppTheme.bodyMedium.copyWith(
                            color: AppTheme.accentAmber,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
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
                  TiltMeter(symmetryIndex: displaySymmetry),
                  const SizedBox(height: 20),
                  Text(
                    tiltDegrees == null ? '- -°' : '${tiltDegrees.toStringAsFixed(0)}°',
                    style: AppTheme.displayMedium.copyWith(
                      fontWeight: FontWeight.w900,
                      color: context.txtPrimary,
                      fontSize: 34,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppTheme.spaceSM),
                  Text(
                    hasData
                        ? 'Tilt from bilateral symmetry'
                        : 'Awaiting session data',
                    style: AppTheme.bodyLarge.copyWith(
                      color: context.txtSecondary,
                      fontWeight: FontWeight.w700,
                    ),
                    textAlign: TextAlign.center,
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
              children: const <Widget>[
                _MuscleChip(label: 'Trapezius', selected: true),
                _MuscleChip(label: 'Deltoid'),
                _MuscleChip(label: 'Lat'),
              ],
            ),
            const SizedBox(height: AppTheme.spaceLG),
            if (isRecording && !hasData)
              AppCard(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: <Widget>[
                    Icon(
                      Icons.fiber_manual_record,
                      size: 48,
                      color: AppTheme.accentAmber.withValues(alpha: 0.6),
                    ),
                    const SizedBox(height: AppTheme.spaceMD),
                    Text(
                      'Recording in progress',
                      style: AppTheme.headingMedium.copyWith(
                        color: context.txtPrimary,
                      ),
                    ),
                    const SizedBox(height: AppTheme.spaceSM),
                    Text(
                      'Results will appear here when the session ends.',
                      textAlign: TextAlign.center,
                      style: AppTheme.bodyLarge.copyWith(
                        color: context.txtSecondary,
                      ),
                    ),
                  ],
                ),
              )
            else
              Row(
                children: <Widget>[
                  Expanded(
                    child: _ChannelCard(
                      label: 'Left Trap',
                      activation: leftAct,
                      activity: activityLabel(leftAct),
                      color: AppTheme.leftTrap,
                    ),
                  ),
                  const SizedBox(width: AppTheme.spaceMD),
                  Expanded(
                    child: _ChannelCard(
                      label: 'Right Trap',
                      activation: rightAct,
                      activity: activityLabel(rightAct),
                      color: AppTheme.rightTrap,
                    ),
                  ),
                ],
              ),
            if (hasData) ...[
              const SizedBox(height: AppTheme.spaceLG),
              AppCard(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      displaySymmetry == null
                          ? 'Single-channel mode'
                          : displaySymmetry < 0
                          ? 'Left Trap dominance'
                          : 'Right Trap dominance',
                      style: AppTheme.headingMedium.copyWith(
                        color: context.txtPrimary,
                        fontSize: 20,
                      ),
                    ),
                    const SizedBox(height: AppTheme.spaceSM),
                    Text(
                      displaySymmetry == null
                          ? 'Complete a bilateral session to get corrective feedback.'
                          : processor.correctiveInstruction(displaySymmetry),
                      style: AppTheme.bodyMedium.copyWith(
                        color: context.txtSecondary,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        );
      },
    );
  }
}

class _ChannelCard extends StatelessWidget {
  final String label;
  final double activation;
  final String activity;
  final Color color;

  const _ChannelCard({
    required this.label,
    required this.activation,
    required this.activity,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final pct = (activation * 100).round();
    return AppCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            label,
            style: AppTheme.headingMedium.copyWith(
              color: context.txtPrimary,
              fontSize: 18,
            ),
          ),
          const SizedBox(height: AppTheme.spaceMD),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: <Widget>[
              Text(
                '$pct',
                style: AppTheme.displayMedium.copyWith(
                  color: context.txtPrimary,
                  fontSize: 36,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(width: 4),
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Text(
                  '%',
                  style: AppTheme.bodyLarge.copyWith(
                    color: context.txtTertiary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          _ActivityBadge(level: activity, color: color),
          const SizedBox(height: AppTheme.spaceMD),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: activation,
              backgroundColor: context.bgElevated,
              color: color,
              minHeight: 6,
            ),
          ),
          const SizedBox(height: AppTheme.spaceSM),
          _MiniBars(
            color: color,
            activation: activation,
          ),
        ],
      ),
    );
  }
}

class _ActivityBadge extends StatelessWidget {
  final String level;
  final Color color;

  const _ActivityBadge({required this.level, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        level,
        style: AppTheme.labelSmall.copyWith(
          color: color,
          fontWeight: FontWeight.w800,
          fontSize: 11,
        ),
      ),
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

class _MiniBars extends StatelessWidget {
  final Color color;
  final double activation;

  const _MiniBars({required this.color, required this.activation});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 36,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: List<Widget>.generate(8, (index) {
          final barHeight = (activation * (12 + (index * 4).toDouble()))
              .clamp(4.0, 40.0);
          return Expanded(
            child: Container(
              height: barHeight,
              margin: const EdgeInsets.symmetric(horizontal: 2),
              decoration: BoxDecoration(
                color: color.withValues(
                  alpha: index.isEven ? 0.35 : 0.65,
                ),
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(6),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}
