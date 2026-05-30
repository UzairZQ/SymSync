import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/services/signal_processor.dart';
import '../bloc/session_bloc.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_card.dart';
import '../../widgets/section_label.dart';
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
              'Balance Monitor',
              style: AppTheme.headingLarge.copyWith(
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: AppTheme.spaceXS),
            Text(
              'Muscle activation balance',
              style: AppTheme.bodyLarge.copyWith(color: AppTheme.textSecondary),
            ),
            const SizedBox(height: AppTheme.spaceLG),
            AppCard(
              padding: const EdgeInsets.all(AppTheme.spaceMD),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  const SectionLabel(label: 'Tilt meter'),
                  const SizedBox(height: AppTheme.spaceMD),
                  TiltMeter(symmetryIndex: symmetry),
                  const SizedBox(height: AppTheme.spaceXL),
                  Text(
                    symmetry == null ? '- -°' : '$tiltDegrees°',
                    style: AppTheme.displayMedium.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppTheme.spaceSM),
                  Text(
                    'Activation tilt from center',
                    style: AppTheme.bodyLarge.copyWith(
                      color: AppTheme.textSecondary,
                      fontWeight: FontWeight.w700,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppTheme.spaceXL),
            AppCard(
              padding: const EdgeInsets.all(AppTheme.spaceMD),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  Text(
                    symmetry == null
                        ? 'Awaiting bilateral feed.'
                        : symmetry < 0
                        ? 'Left vastus lateralis is more active.'
                        : 'Right vastus lateralis is more active.',
                    style: AppTheme.bodyLarge.copyWith(
                      fontWeight: FontWeight.w800,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: AppTheme.spaceMD),
                  Text(
                    processor.correctiveInstruction(symmetry),
                    style: AppTheme.bodyMedium.copyWith(
                      color: AppTheme.textSecondary,
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
