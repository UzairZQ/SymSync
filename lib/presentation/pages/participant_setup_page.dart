import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/models/research_context.dart';
import '../../theme/app_theme.dart';
import '../bloc/session_bloc.dart';

class ParticipantSetupPage extends StatefulWidget {
  const ParticipantSetupPage({super.key});

  @override
  State<ParticipantSetupPage> createState() => _ParticipantSetupPageState();
}

class _ParticipantSetupPageState extends State<ParticipantSetupPage> {
  UsageScenario _scenario = UsageScenario.officeDesk;
  bool _busy = false;

  Future<void> _continue() async {
    setState(() => _busy = true);
    final bloc = context.read<SessionBloc>();
    await bloc.createParticipant();
    await bloc.selectScenario(_scenario);
    if (mounted) setState(() => _busy = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.bgPrimary,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 14),
          children: <Widget>[
            Container(
              width: 44,
              height: 44,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: context.txtPrimary,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Text(
                'S',
                style: AppTheme.headingMedium.copyWith(
                  color: context.bgPrimary,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            const SizedBox(height: 18),
            Text(
              'Set up the research session',
              style: AppTheme.displayMedium.copyWith(
                color: context.txtPrimary,
                fontSize: 28,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'SymSync creates an anonymous participant code. No name, email, '
              'camera, or cloud account is required.',
              style: AppTheme.bodyMedium.copyWith(
                color: context.txtSecondary,
                height: 1.35,
              ),
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(13),
              decoration: BoxDecoration(
                color: context.bgCard,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: context.dividerClr),
              ),
              child: Row(
                children: <Widget>[
                  const Icon(Icons.shield_outlined, color: AppTheme.accentTeal),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'The next available code will be assigned automatically '
                      '(for example P001). Measurements stay on this device '
                      'unless you deliberately export a copy.',
                      style: AppTheme.bodySmall.copyWith(
                        color: context.txtSecondary,
                        height: 1.3,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            Text(
              'FIRST TEST SCENARIO',
              style: AppTheme.labelSmall.copyWith(color: context.txtTertiary),
            ),
            const SizedBox(height: 7),
            for (final scenario in UsageScenario.values) ...[
              _ScenarioCard(
                scenario: scenario,
                selected: scenario == _scenario,
                onTap: () => setState(() => _scenario = scenario),
              ),
              const SizedBox(height: 7),
            ],
            const SizedBox(height: 8),
            FilledButton.icon(
              onPressed: _busy ? null : _continue,
              icon: _busy
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.arrow_forward_rounded),
              label: const Text('Create Participant and Continue'),
              style: FilledButton.styleFrom(
                backgroundColor: context.txtPrimary,
                foregroundColor: context.bgPrimary,
                padding: const EdgeInsets.symmetric(vertical: 13),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ScenarioCard extends StatelessWidget {
  const _ScenarioCard({
    required this.scenario,
    required this.selected,
    required this.onTap,
  });

  final UsageScenario scenario;
  final bool selected;
  final VoidCallback onTap;

  IconData get _icon => switch (scenario) {
    UsageScenario.officeDesk => Icons.desk_outlined,
    UsageScenario.gymExercise => Icons.fitness_center_rounded,
    UsageScenario.everydayStairs => Icons.stairs_outlined,
  };

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 11),
        decoration: BoxDecoration(
          color: selected
              ? AppTheme.accentTeal.withValues(alpha: 0.14)
              : context.bgCard,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: selected ? AppTheme.accentTeal : context.dividerClr,
            width: selected ? 2 : 1,
          ),
        ),
        child: Row(
          children: <Widget>[
            Icon(
              _icon,
              color: selected ? AppTheme.accentTeal : context.txtSecondary,
            ),
            const SizedBox(width: 11),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    scenario.label,
                    style: AppTheme.headingMedium.copyWith(
                      color: context.txtPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    scenario.description,
                    style: AppTheme.bodySmall.copyWith(
                      color: context.txtSecondary,
                      fontSize: 11,
                      height: 1.25,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              selected
                  ? Icons.check_circle_rounded
                  : Icons.radio_button_unchecked,
              color: selected ? AppTheme.accentTeal : context.txtTertiary,
            ),
          ],
        ),
      ),
    );
  }
}
