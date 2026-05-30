import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/services/signal_processor.dart';
import '../bloc/session_bloc.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_card.dart';
import '../../widgets/section_label.dart';
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
                        'Anatomical View',
                        style: AppTheme.headingLarge.copyWith(
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      const SizedBox(height: AppTheme.spaceXS),
                      Text(
                        'Lower body activation mapping',
                        style: AppTheme.bodyLarge.copyWith(
                          color: AppTheme.textSecondary,
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
                        : AppTheme.backgroundElevated,
                    borderRadius: BorderRadius.circular(AppTheme.radiusLG),
                  ),
                  child: Icon(
                    Icons.bluetooth,
                    color: state.isConnected
                        ? AppTheme.accentTeal
                        : AppTheme.textTertiary,
                    size: 22,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppTheme.spaceLG),
            AppCard(
              padding: const EdgeInsets.all(AppTheme.spaceMD),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  SizedBox(
                    height: 320,
                    child: Stack(
                      children: <Widget>[
                        Positioned.fill(
                          child: Opacity(
                            opacity: 0.18,
                            child: Container(
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: <Color>[
                                    AppTheme.accentBlue,
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
                  AppCard(
                    padding: const EdgeInsets.all(AppTheme.spaceMD),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: <Widget>[
                        const SectionLabel(label: 'Muscle activity'),
                        const SizedBox(height: AppTheme.spaceSM),
                        Container(
                          height: 10,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(999),
                            gradient: const LinearGradient(
                              colors: [
                                AppTheme.accentBlue,
                                AppTheme.accentAmber,
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppTheme.spaceXL),
                  AppCard(
                    padding: const EdgeInsets.all(AppTheme.spaceMD),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          imbalanceLabel,
                          style: AppTheme.bodyLarge.copyWith(
                            color: AppTheme.textPrimary,
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
                            color: AppTheme.textSecondary,
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
                        color: AppTheme.backgroundElevated,
                        borderRadius: BorderRadius.circular(AppTheme.radiusLG),
                        border: Border.all(color: AppTheme.divider),
                      ),
                      child: Text(
                        'Vastus Lateralis',
                        style: AppTheme.bodyLarge.copyWith(
                          color: AppTheme.accentTeal,
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
