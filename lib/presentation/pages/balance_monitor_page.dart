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
        final symmetry = state.symmetryIndex;
        final tiltDegrees = symmetry == null
            ? 0
            : (symmetry / 3.0).clamp(-20.0, 20.0).toStringAsFixed(0);

        return ListView(
          key: const PageStorageKey<String>('balance'),
          padding: const EdgeInsets.only(bottom: AppTheme.spaceXXL),
          children: <Widget>[
            Text(
              'LIVE SESSION METRICS',
              style: AppTheme.labelSmall.copyWith(
                color: context.txtTertiary,
                letterSpacing: 1.1,
              ),
            ),
            const SizedBox(height: AppTheme.spaceXS),
            Text(
              'Balance Monitor',
              style: AppTheme.headingLarge.copyWith(
                color: context.txtPrimary,
                fontSize: 30,
              ),
            ),
            const SizedBox(height: AppTheme.spaceXS),
            Text(
              'Muscle activation balance',
              style: AppTheme.bodyLarge.copyWith(color: context.txtSecondary),
            ),
            const SizedBox(height: AppTheme.spaceLG),
            AppCard(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  TiltMeter(symmetryIndex: symmetry),
                  const SizedBox(height: 20),
                  Text(
                    symmetry == null ? '- -°' : '$tiltDegrees°',
                    style: AppTheme.displayMedium.copyWith(
                      fontWeight: FontWeight.w900,
                      color: context.txtPrimary,
                      fontSize: 34,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppTheme.spaceSM),
                  Text(
                    'Activation tilt from center',
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
                _MuscleChip(label: 'Vastus Lat.', selected: true),
                _MuscleChip(label: 'Rectus Fem.'),
                _MuscleChip(label: 'Glutes'),
              ],
            ),
            const SizedBox(height: AppTheme.spaceLG),
            AppCard(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    'CHANNEL A',
                    style: AppTheme.labelSmall.copyWith(
                      color: context.txtTertiary,
                      letterSpacing: 1,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Left Hemisphere',
                    style: AppTheme.headingMedium.copyWith(
                      color: context.txtPrimary,
                      fontSize: 20,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: <Widget>[
                      Text(
                        '${state.latestRaw}',
                        style: AppTheme.displayMedium.copyWith(
                          color: context.txtPrimary,
                          fontSize: 32,
                        ),
                      ),
                      const SizedBox(width: 5),
                      Padding(
                        padding: const EdgeInsets.only(bottom: 7),
                        child: Text(
                          'uV',
                          style: AppTheme.bodyMedium.copyWith(
                            color: context.txtTertiary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  const _MiniBars(color: AppTheme.leftLeg),
                  const SizedBox(height: 24),
                  Text(
                    symmetry == null
                        ? 'Awaiting bilateral feed.'
                        : symmetry < 0
                        ? 'Left vastus lateralis is more active.'
                        : 'Right vastus lateralis is more active.',
                    style: AppTheme.bodyLarge.copyWith(
                      fontWeight: FontWeight.w800,
                      height: 1.4,
                      color: context.txtPrimary,
                    ),
                  ),
                  const SizedBox(height: AppTheme.spaceMD),
                  Text(
                    processor.correctiveInstruction(symmetry),
                    style: AppTheme.bodyMedium.copyWith(
                      color: context.txtSecondary,
                      height: 1.5,
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
  const _MiniBars({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    const heights = <double>[18, 24, 32, 20, 26, 16, 28, 22];
    return SizedBox(
      height: 48,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: List<Widget>.generate(heights.length, (index) {
          return Expanded(
            child: Container(
              height: heights[index],
              margin: const EdgeInsets.symmetric(horizontal: 3),
              decoration: BoxDecoration(
                color: color.withValues(alpha: index.isEven ? 0.5 : 0.78),
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(8),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}
