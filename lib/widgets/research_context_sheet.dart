import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../domain/models/research_context.dart';
import '../presentation/bloc/session_bloc.dart';
import '../theme/app_theme.dart';

Future<bool> showRecordingContextSheet(BuildContext context) async {
  final bloc = context.read<SessionBloc>();
  var participantId = bloc.state.activeParticipantId;
  var scenario = bloc.state.selectedScenario;

  final confirmed = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (sheetContext) {
      return StatefulBuilder(
        builder: (context, setSheetState) {
          final state = bloc.state;
          return Padding(
            padding: EdgeInsets.fromLTRB(
              20,
              16,
              20,
              20 + MediaQuery.of(context).viewInsets.bottom,
            ),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  Center(
                    child: Container(
                      width: 42,
                      height: 4,
                      decoration: BoxDecoration(
                        color: context.dividerClr,
                        borderRadius: BorderRadius.circular(99),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Confirm measurement context',
                    style: AppTheme.headingLarge.copyWith(
                      color: context.txtPrimary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'This participant and scenario will be saved with the EMG '
                    'session so research results stay separated.',
                    style: AppTheme.bodyMedium.copyWith(
                      color: context.txtSecondary,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 20),
                  DropdownButtonFormField<String>(
                    initialValue: participantId,
                    decoration: const InputDecoration(
                      labelText: 'Participant',
                      border: OutlineInputBorder(),
                    ),
                    items: state.participants
                        .map(
                          (participant) => DropdownMenuItem<String>(
                            value: participant.id,
                            child: Text(participant.displayLabel),
                          ),
                        )
                        .toList(growable: false),
                    onChanged: (value) {
                      setSheetState(() => participantId = value);
                    },
                  ),
                  const SizedBox(height: 18),
                  Text(
                    'SCENARIO',
                    style: AppTheme.labelSmall.copyWith(
                      color: context.txtTertiary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  for (final item in UsageScenario.values)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 4,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                          side: BorderSide(
                            color: item == scenario
                                ? AppTheme.accentTeal
                                : context.dividerClr,
                          ),
                        ),
                        tileColor: item == scenario
                            ? AppTheme.accentTeal.withValues(alpha: 0.12)
                            : null,
                        leading: Icon(
                          item == scenario
                              ? Icons.check_circle
                              : Icons.circle_outlined,
                          color: item == scenario
                              ? AppTheme.accentTeal
                              : context.txtTertiary,
                        ),
                        title: Text(item.label),
                        subtitle: Text(item.description),
                        onTap: () => setSheetState(() => scenario = item),
                      ),
                    ),
                  const SizedBox(height: 12),
                  FilledButton(
                    onPressed: participantId == null
                        ? null
                        : () async {
                            await bloc.selectParticipant(participantId!);
                            await bloc.selectScenario(scenario);
                            if (sheetContext.mounted) {
                              Navigator.of(sheetContext).pop(true);
                            }
                          },
                    child: const Text('Confirm and Start Recording'),
                  ),
                ],
              ),
            ),
          );
        },
      );
    },
  );
  return confirmed ?? false;
}

Future<void> showParticipantManagerSheet(BuildContext context) async {
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (sheetContext) => const _ParticipantManager(),
  );
}

class _ParticipantManager extends StatelessWidget {
  const _ParticipantManager();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SessionBloc, SessionState>(
      builder: (context, state) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Text(
                'Research participants',
                style: AppTheme.headingLarge.copyWith(
                  color: context.txtPrimary,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Anonymous codes keep each person’s measurements separate.',
                style: AppTheme.bodyMedium.copyWith(
                  color: context.txtSecondary,
                ),
              ),
              const SizedBox(height: 16),
              Flexible(
                child: ListView(
                  shrinkWrap: true,
                  children: state.participants
                      .map((participant) {
                        final active =
                            participant.id == state.activeParticipantId;
                        final count = state.history
                            .where(
                              (item) => item.participantId == participant.id,
                            )
                            .length;
                        return ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: CircleAvatar(
                            child: Text(participant.id.substring(1)),
                          ),
                          title: Text(participant.displayLabel),
                          subtitle: Text(
                            '$count recorded session${count == 1 ? '' : 's'}',
                          ),
                          trailing: PopupMenuButton<String>(
                            enabled: !state.isRecording,
                            onSelected: (action) async {
                              if (action == 'select') {
                                await context
                                    .read<SessionBloc>()
                                    .selectParticipant(participant.id);
                              } else if (action == 'delete') {
                                final confirmed = await showDialog<bool>(
                                  context: context,
                                  builder: (dialogContext) => AlertDialog(
                                    title: Text(
                                      'Delete ${participant.displayLabel}?',
                                    ),
                                    content: Text(
                                      'This permanently deletes the participant '
                                      'code and its $count recorded '
                                      'session${count == 1 ? '' : 's'}.',
                                    ),
                                    actions: <Widget>[
                                      TextButton(
                                        onPressed: () => Navigator.of(
                                          dialogContext,
                                        ).pop(false),
                                        child: const Text('Cancel'),
                                      ),
                                      FilledButton(
                                        onPressed: () => Navigator.of(
                                          dialogContext,
                                        ).pop(true),
                                        style: FilledButton.styleFrom(
                                          backgroundColor: AppTheme.accentRed,
                                          foregroundColor: Colors.white,
                                        ),
                                        child: const Text('Delete'),
                                      ),
                                    ],
                                  ),
                                );
                                if (confirmed == true && context.mounted) {
                                  await context
                                      .read<SessionBloc>()
                                      .deleteParticipant(participant.id);
                                }
                              }
                            },
                            itemBuilder: (_) => <PopupMenuEntry<String>>[
                              if (!active)
                                const PopupMenuItem<String>(
                                  value: 'select',
                                  child: Text('Use this participant'),
                                ),
                              const PopupMenuItem<String>(
                                value: 'delete',
                                child: Text('Delete participant and sessions'),
                              ),
                            ],
                            icon: Icon(
                              active ? Icons.check_circle : Icons.more_vert,
                              color: active
                                  ? AppTheme.accentGreen
                                  : context.txtSecondary,
                            ),
                          ),
                          onTap: state.isRecording
                              ? null
                              : () => context
                                    .read<SessionBloc>()
                                    .selectParticipant(participant.id),
                        );
                      })
                      .toList(growable: false),
                ),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: state.isRecording
                    ? null
                    : () => context.read<SessionBloc>().createParticipant(),
                icon: const Icon(Icons.person_add_alt_1_outlined),
                label: const Text('Create Next Participant ID'),
              ),
            ],
          ),
        );
      },
    );
  }
}

class ResearchContextBanner extends StatelessWidget {
  const ResearchContextBanner({super.key, this.compact = false});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SessionBloc, SessionState>(
      buildWhen: (previous, current) =>
          previous.activeParticipantId != current.activeParticipantId ||
          previous.selectedScenario != current.selectedScenario ||
          previous.participants != current.participants,
      builder: (context, state) {
        return InkWell(
          onTap: state.isRecording
              ? null
              : () => showParticipantManagerSheet(context),
          borderRadius: BorderRadius.circular(18),
          child: Container(
            padding: EdgeInsets.symmetric(
              horizontal: compact ? 12 : 14,
              vertical: compact ? 6 : 12,
            ),
            decoration: BoxDecoration(
              color: AppTheme.accentTeal.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(compact ? 16 : 18),
              border: Border.all(
                color: AppTheme.accentTeal.withValues(alpha: 0.35),
              ),
            ),
            child: Row(
              children: <Widget>[
                Icon(
                  Icons.badge_outlined,
                  size: compact ? 16 : 18,
                  color: AppTheme.accentTeal,
                ),
                SizedBox(width: compact ? 7 : 9),
                Expanded(
                  child: Text(
                    '${state.displayName} · ${state.selectedScenario.label}',
                    overflow: TextOverflow.ellipsis,
                    style: AppTheme.bodySmall.copyWith(
                      color: context.txtPrimary,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                if (!state.isRecording)
                  Icon(
                    Icons.swap_horiz_rounded,
                    size: compact ? 16 : 18,
                    color: context.txtSecondary,
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}
