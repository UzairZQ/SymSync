import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/models/feedback_view.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../domain/models/research_context.dart';
import '../../domain/models/session_summary.dart';
import '../../domain/models/target_muscle.dart';
import '../bloc/session_bloc.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_card.dart';
import '../../widgets/connection_badge.dart';
import '../../widgets/heatmap_silhouette_widget.dart';
import '../../widgets/terms_glossary_sheet.dart';
import '../../widgets/research_context_sheet.dart';

class ActivationSummaryPage extends StatefulWidget {
  const ActivationSummaryPage({super.key});

  @override
  State<ActivationSummaryPage> createState() => _ActivationSummaryPageState();
}

enum _SummaryScope { all, latest, selected }

class _ActivationSummaryPageState extends State<ActivationSummaryPage> {
  int _periodIndex = 0;
  _SummaryScope _summaryScope = _SummaryScope.all;
  int? _selectedSessionMs;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SessionBloc, SessionState>(
      builder: (context, state) {
        final periodHistory = _filterHistoryForPeriod(
          state.activeHistory,
          _periodIndex,
        );
        final filteredHistory = _historyForScope(periodHistory);

        final historyCount = filteredHistory.length;

        final avgSI = _durationWeightedAverage(
          filteredHistory,
          (session) => session.averageSymmetryIndex,
        );
        final avgDeviation = avgSI?.abs();
        final periodDominance = _dominanceValue(avgSI);
        final targetMuscle = state.targetMuscle;

        final trendPercent = _trendPercent(filteredHistory);
        final trendingUp = trendPercent == null ? null : trendPercent >= 0;
        final isConnected = state.isConnected;
        final isConnecting = state.status == SessionStatus.connecting;

        final leftAvg =
            _durationWeightedAverage(
              filteredHistory,
              (session) => session.averageLeftActivation,
            ) ??
            0.0;
        final rightAvg =
            _durationWeightedAverage(
              filteredHistory,
              (session) => session.averageRightActivation,
            ) ??
            0.0;

        final primaryImbalance = _primaryImbalanceLabel(avgSI, targetMuscle);
        final primaryImbalanceColor = _primaryImbalanceColor(avgSI, context);

        return ListView(
          key: const PageStorageKey<String>('summary'),
          padding: const EdgeInsets.only(bottom: AppTheme.spaceLG),
          children: <Widget>[
            Row(
              children: <Widget>[
                Expanded(
                  child: Text(
                    'Activation Summary',
                    style: AppTheme.headingLarge.copyWith(
                      color: context.txtPrimary,
                    ),
                  ),
                ),
                ConnectionBadge(
                  isConnected: isConnected,
                  isConnecting: isConnecting,
                ),
                const SizedBox(width: AppTheme.spaceSM),
                IconButton(
                  tooltip: 'Explain summary terms',
                  onPressed: () => showTermsGlossarySheet(context),
                  style: IconButton.styleFrom(
                    backgroundColor: context.bgCard,
                    foregroundColor: context.txtSecondary,
                    side: BorderSide(color: context.dividerClr),
                  ),
                  icon: const Icon(Icons.help_outline_rounded, size: 18),
                ),
              ],
            ),
            const SizedBox(height: AppTheme.spaceXS),
            Text(
              'Review your recent symmetry and muscle pattern trends',
              style: AppTheme.bodyMedium.copyWith(color: context.txtSecondary),
            ),
            const SizedBox(height: AppTheme.spaceMD),
            const ResearchContextBanner(compact: true),
            const SizedBox(height: AppTheme.spaceMD),
            _ParticipantSummarySelector(
              participants: state.participants,
              activeParticipantId: state.activeParticipantId,
              history: state.history,
              isRecording: state.isRecording,
              onSelected: (participantId) =>
                  context.read<SessionBloc>().selectParticipant(participantId),
            ),
            if (state.activeParticipant != null) ...[
              const SizedBox(height: AppTheme.spaceMD),
              _BaselineReferenceCard(participant: state.activeParticipant!),
            ],
            const SizedBox(height: AppTheme.spaceMD),
            _SummaryScopeCard(
              periodHistory: periodHistory,
              scopedHistory: filteredHistory,
              scope: _summaryScope,
              selectedSessionMs: _selectedSessionMs,
              onScopeChanged: (scope) => setState(() {
                _summaryScope = scope;
                if (scope == _SummaryScope.selected &&
                    _selectedSession(periodHistory) == null &&
                    periodHistory.isNotEmpty) {
                  _selectedSessionMs = _sessionKey(periodHistory.first);
                }
              }),
              onSessionSelected: (sessionMs) => setState(() {
                _summaryScope = _SummaryScope.selected;
                _selectedSessionMs = sessionMs;
              }),
            ),
            const SizedBox(height: AppTheme.spaceMD),
            AppCard(
              padding: const EdgeInsets.all(AppTheme.spaceMD),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  Text(
                    'Anatomical heatmap',
                    style: AppTheme.labelSmall.copyWith(
                      color: context.txtTertiary,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Aggregate of all recorded scenarios in the selected period.',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppTheme.bodySmall.copyWith(
                      color: context.txtSecondary,
                      height: 1.25,
                    ),
                  ),
                  const SizedBox(height: AppTheme.spaceSM),
                  SizedBox(
                    height: 260,
                    child: historyCount > 0
                        ? HeatmapSilhouetteWidget(
                            leftActivation: leftAvg.clamp(0.0, 1.0),
                            rightActivation: rightAvg.clamp(0.0, 1.0),
                            width: 200,
                            style: HeatmapDisplayStyle.summaryHeatmap,
                            targetMuscle: targetMuscle,
                          )
                        : const _EmptyHeatmap(),
                  ),
                  const SizedBox(height: AppTheme.spaceSM),
                  // Muscle chip row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      _MuscleChip(
                        label: TargetMuscle.trapezius.chipLabel,
                        isActive: targetMuscle == TargetMuscle.trapezius,
                        onTap: state.isRecording
                            ? null
                            : () => context
                                  .read<SessionBloc>()
                                  .selectTargetMuscle(TargetMuscle.trapezius),
                      ),
                      const SizedBox(width: AppTheme.spaceSM),
                      _MuscleChip(
                        label: TargetMuscle.biceps.chipLabel,
                        isActive: targetMuscle == TargetMuscle.biceps,
                        onTap: state.isRecording
                            ? null
                            : () => context
                                  .read<SessionBloc>()
                                  .selectTargetMuscle(TargetMuscle.biceps),
                      ),
                      const SizedBox(width: AppTheme.spaceSM),
                      const Tooltip(
                        message: 'Coming soon',
                        triggerMode: TooltipTriggerMode.tap,
                        child: _MuscleChip(label: 'Deltoid', isActive: false),
                      ),
                      const SizedBox(width: AppTheme.spaceSM),
                      Tooltip(
                        message: 'Coming soon',
                        triggerMode: TooltipTriggerMode.tap,
                        child: _MuscleChip(label: 'Lat', isActive: false),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppTheme.spaceLG),
                  Row(
                    children: <Widget>[
                      Expanded(
                        child: _summaryMetric(
                          context: context,
                          label: 'Sessions',
                          value: '$historyCount',
                          color: AppTheme.accentTeal,
                        ),
                      ),
                      const SizedBox(width: AppTheme.spaceSM),
                      Expanded(
                        child: _summaryMetric(
                          context: context,
                          label: 'Dominance',
                          value: periodDominance,
                          color: primaryImbalanceColor,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppTheme.spaceLG),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppTheme.spaceMD,
                vertical: AppTheme.spaceSM,
              ),
              decoration: BoxDecoration(
                color: context.bgCard,
                borderRadius: BorderRadius.circular(AppTheme.radiusXL),
                border: Border.all(color: context.dividerClr),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: List<Widget>.generate(3, (index) {
                  const labels = <String>['Today', '7 Days', '30 Days'];
                  final active = _periodIndex == index;
                  return Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _periodIndex = index),
                      child: Container(
                        margin: const EdgeInsets.symmetric(
                          horizontal: AppTheme.spaceXS,
                        ),
                        padding: const EdgeInsets.symmetric(
                          vertical: AppTheme.spaceSM,
                        ),
                        decoration: BoxDecoration(
                          color: active
                              ? AppTheme.accentTeal.withValues(alpha: 0.16)
                              : context.bgElevated,
                          borderRadius: BorderRadius.circular(
                            AppTheme.radiusLG,
                          ),
                        ),
                        child: Text(
                          labels[index],
                          textAlign: TextAlign.center,
                          style: AppTheme.bodyMedium.copyWith(
                            color: active
                                ? context.txtPrimary
                                : context.txtSecondary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ),
            const SizedBox(height: AppTheme.spaceLG),
            _ScenarioBreakdownCard(history: filteredHistory),
            const SizedBox(height: AppTheme.spaceLG),
            AppCard(
              padding: const EdgeInsets.all(AppTheme.spaceMD),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: <Widget>[
                      Text(
                        'Pattern Analysis',
                        style: AppTheme.headingMedium.copyWith(
                          color: context.txtPrimary,
                        ),
                      ),
                      if (trendPercent != null)
                        Text(
                          '${trendingUp! ? '+' : ''}${trendPercent.toStringAsFixed(0)}%',
                          style: AppTheme.labelSmall.copyWith(
                            color: trendingUp
                                ? AppTheme.accentLime
                                : AppTheme.accentRed,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: AppTheme.spaceMD),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: <Widget>[
                      _analysisItem(
                        context: context,
                        title: 'Avg. Deviation',
                        value: avgDeviation == null
                            ? '—'
                            : '${avgDeviation.toStringAsFixed(0)}%',
                        valueColor: context.txtSecondary,
                      ),
                      _analysisItem(
                        context: context,
                        title: 'Primary Imbalance',
                        value: primaryImbalance,
                        valueColor: primaryImbalanceColor,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppTheme.spaceLG),
            _ExerciseRecommendations(
              primaryImbalance: primaryImbalance,
              scenarioLabel: _scenarioScopeLabel(filteredHistory),
              targetMuscle: targetMuscle,
            ),
          ],
        );
      },
    );
  }

  double? _trendPercent(List history) {
    if (history.length < 2) return null;
    final scores = history
        .map((s) => s.averageSymmetryIndex)
        .whereType<double>()
        .toList();
    if (scores.length < 2) return null;
    final recent = scores.first.abs();
    final prior = scores[1].abs();
    if (prior == 0) return 0;
    return ((prior - recent) / prior) * 100;
  }

  List<SessionSummary> _filterHistoryForPeriod(
    List<SessionSummary> history,
    int periodIndex,
  ) {
    final now = DateTime.now();
    final DateTime cutoff = switch (periodIndex) {
      0 => DateTime(now.year, now.month, now.day),
      1 => now.subtract(const Duration(days: 7)),
      _ => now.subtract(const Duration(days: 30)),
    };
    return history
        .where((session) => !session.startedAt.isBefore(cutoff))
        .toList(growable: false);
  }

  List<SessionSummary> _historyForScope(List<SessionSummary> periodHistory) {
    if (periodHistory.isEmpty) {
      return const <SessionSummary>[];
    }
    return switch (_summaryScope) {
      _SummaryScope.all => periodHistory,
      _SummaryScope.latest => <SessionSummary>[periodHistory.first],
      _SummaryScope.selected => <SessionSummary>[
        _selectedSession(periodHistory) ?? periodHistory.first,
      ],
    };
  }

  SessionSummary? _selectedSession(List<SessionSummary> periodHistory) {
    final selectedMs = _selectedSessionMs;
    if (selectedMs == null) {
      return null;
    }
    for (final session in periodHistory) {
      if (_sessionKey(session) == selectedMs) {
        return session;
      }
    }
    return null;
  }

  int _sessionKey(SessionSummary session) =>
      session.startedAt.millisecondsSinceEpoch;

  double? _durationWeightedAverage(
    List<SessionSummary> history,
    double? Function(SessionSummary session) valueOf,
  ) {
    var weightedSum = 0.0;
    var totalWeight = 0.0;
    for (final session in history) {
      final value = valueOf(session);
      if (value == null) continue;
      final weight = session.durationSeconds <= 0
          ? 1.0
          : session.durationSeconds.toDouble();
      weightedSum += value * weight;
      totalWeight += weight;
    }
    if (totalWeight == 0) {
      return null;
    }
    return weightedSum / totalWeight;
  }

  String _scenarioScopeLabel(List<SessionSummary> history) {
    final scenarioIds = history
        .map((session) => session.scenarioId)
        .whereType<String>()
        .toSet();
    if (scenarioIds.length <= 1) {
      final id = scenarioIds.isEmpty ? null : scenarioIds.first;
      final scenario = UsageScenario.values.where((item) => item.id == id);
      return scenario.isEmpty
          ? 'the selected period'
          : scenario.first.shortLabel;
    }
    return 'all recorded scenarios';
  }

  String _dominanceValue(double? averageSymmetryIndex) {
    if (averageSymmetryIndex == null) {
      return '—';
    }
    final value = averageSymmetryIndex.abs();
    if (value < 8) {
      return 'Symmetrical';
    }
    final direction = averageSymmetryIndex > 0 ? 'Right' : 'Left';
    final strength = value < 16 ? 'slight' : 'clear';
    return '$direction +${value.toStringAsFixed(0)}% $strength';
  }

  String _primaryImbalanceLabel(
    double? averageSymmetryIndex,
    TargetMuscle targetMuscle,
  ) {
    if (averageSymmetryIndex == null) {
      return 'Pending';
    }
    final value = averageSymmetryIndex.abs();
    if (value < 8) {
      return 'Both sides symmetrical';
    }
    final direction = averageSymmetryIndex > 0 ? 'Right' : 'Left';
    if (value < 16) {
      return targetMuscle.dominanceLabel(direction == 'Right', slight: true);
    }
    return targetMuscle.dominanceLabel(direction == 'Right', slight: false);
  }

  Color _primaryImbalanceColor(
    double? averageSymmetryIndex,
    BuildContext context,
  ) {
    if (averageSymmetryIndex == null) {
      return context.txtTertiary;
    }
    final value = averageSymmetryIndex.abs();
    if (value < 8) {
      return AppTheme.accentLime;
    }
    if (value < 16) {
      return AppTheme.accentAmber;
    }
    return AppTheme.accentRed;
  }

  Widget _summaryMetric({
    required BuildContext context,
    required String label,
    required String value,
    required Color color,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          label,
          style: AppTheme.bodyMedium.copyWith(
            color: context.txtSecondary,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: AppTheme.spaceXS),
        Text(
          value,
          style: AppTheme.headingMedium.copyWith(color: color, fontSize: 20),
        ),
      ],
    );
  }

  Widget _analysisItem({
    required BuildContext context,
    required String title,
    required String value,
    required Color valueColor,
  }) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            title.toUpperCase(),
            style: AppTheme.labelSmall.copyWith(color: context.txtSecondary),
          ),
          const SizedBox(height: AppTheme.spaceSM),
          Text(
            value,
            style: AppTheme.bodyLarge.copyWith(
              color: valueColor,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryScopeCard extends StatelessWidget {
  const _SummaryScopeCard({
    required this.periodHistory,
    required this.scopedHistory,
    required this.scope,
    required this.selectedSessionMs,
    required this.onScopeChanged,
    required this.onSessionSelected,
  });

  final List<SessionSummary> periodHistory;
  final List<SessionSummary> scopedHistory;
  final _SummaryScope scope;
  final int? selectedSessionMs;
  final ValueChanged<_SummaryScope> onScopeChanged;
  final ValueChanged<int?> onSessionSelected;

  @override
  Widget build(BuildContext context) {
    final selectedValue = _selectedDropdownValue;
    return AppCard(
      padding: const EdgeInsets.all(AppTheme.spaceMD),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Row(
            children: <Widget>[
              Icon(
                Icons.filter_alt_outlined,
                size: 19,
                color: AppTheme.accentTeal,
              ),
              const SizedBox(width: AppTheme.spaceSM),
              Expanded(
                child: Text(
                  'Summary scope',
                  style: AppTheme.headingMedium.copyWith(
                    color: context.txtPrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            _scopeDescription,
            style: AppTheme.bodySmall.copyWith(
              color: context.txtSecondary,
              height: 1.3,
            ),
          ),
          const SizedBox(height: AppTheme.spaceMD),
          Wrap(
            spacing: AppTheme.spaceSM,
            runSpacing: AppTheme.spaceSM,
            children: <Widget>[
              _ScopeChip(
                label: 'All',
                selected: scope == _SummaryScope.all,
                onTap: () => onScopeChanged(_SummaryScope.all),
              ),
              _ScopeChip(
                label: 'Latest',
                selected: scope == _SummaryScope.latest,
                onTap: () => onScopeChanged(_SummaryScope.latest),
              ),
              _ScopeChip(
                label: 'Session',
                selected: scope == _SummaryScope.selected,
                onTap: () => onScopeChanged(_SummaryScope.selected),
              ),
            ],
          ),
          if (scope == _SummaryScope.selected) ...<Widget>[
            const SizedBox(height: AppTheme.spaceMD),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: AppTheme.spaceSM),
              decoration: BoxDecoration(
                color: context.bgElevated,
                borderRadius: BorderRadius.circular(AppTheme.radiusLG),
                border: Border.all(color: context.dividerClr),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<int>(
                  value: selectedValue,
                  isExpanded: true,
                  hint: Text(
                    periodHistory.isEmpty
                        ? 'No sessions in this period'
                        : 'Choose a session',
                  ),
                  items: periodHistory
                      .map(
                        (session) => DropdownMenuItem<int>(
                          value: session.startedAt.millisecondsSinceEpoch,
                          child: Text(
                            _sessionLabel(session),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      )
                      .toList(growable: false),
                  onChanged: periodHistory.isEmpty ? null : onSessionSelected,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  int? get _selectedDropdownValue {
    if (periodHistory.isEmpty) {
      return null;
    }
    final selected = selectedSessionMs;
    if (selected != null &&
        periodHistory.any(
          (session) => session.startedAt.millisecondsSinceEpoch == selected,
        )) {
      return selected;
    }
    return periodHistory.first.startedAt.millisecondsSinceEpoch;
  }

  String get _scopeDescription {
    if (periodHistory.isEmpty) {
      return 'No sessions are available in the selected period.';
    }
    if (scope == _SummaryScope.all) {
      return 'Showing aggregate data from all ${periodHistory.length} sessions in this period.';
    }
    if (scope == _SummaryScope.latest) {
      return 'Showing only the most recent session in this period.';
    }
    final session = scopedHistory.isEmpty
        ? periodHistory.first
        : scopedHistory.first;
    return 'Showing one selected session: ${_sessionLabel(session)}.';
  }

  String _sessionLabel(SessionSummary session) {
    final time = TimeOfDay.fromDateTime(session.startedAt);
    final hour = time.hourOfPeriod == 0 ? 12 : time.hourOfPeriod;
    final minute = time.minute.toString().padLeft(2, '0');
    final period = time.period == DayPeriod.am ? 'AM' : 'PM';
    final scenario = _scenarioLabel(session.scenarioId);
    final view = session.feedbackView?.label ?? 'View not recorded';
    final dominance = _dominanceLabel(session.averageSymmetryIndex);
    return '$hour:$minute $period · $scenario · $view · $dominance';
  }

  String _scenarioLabel(String? scenarioId) {
    for (final scenario in UsageScenario.values) {
      if (scenario.id == scenarioId) {
        return scenario.shortLabel;
      }
    }
    return 'Unlabeled';
  }

  String _dominanceLabel(double? si) {
    if (si == null) {
      return 'Pending';
    }
    if (si.abs() < 8) {
      return 'Even';
    }
    return si > 0
        ? 'Right +${si.abs().toStringAsFixed(0)}%'
        : 'Left +${si.abs().toStringAsFixed(0)}%';
  }
}

class _ScopeChip extends StatelessWidget {
  const _ScopeChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      selected: selected,
      onSelected: (_) => onTap(),
      label: Text(label),
      selectedColor: AppTheme.accentTeal.withValues(alpha: 0.18),
      backgroundColor: context.bgElevated,
      side: BorderSide(
        color: selected ? AppTheme.accentTeal : context.dividerClr,
      ),
      showCheckmark: false,
      labelStyle: AppTheme.bodySmall.copyWith(
        color: selected ? context.txtPrimary : context.txtSecondary,
        fontWeight: FontWeight.w800,
      ),
    );
  }
}

class _ScenarioBreakdownCard extends StatelessWidget {
  const _ScenarioBreakdownCard({required this.history});

  final List<SessionSummary> history;

  @override
  Widget build(BuildContext context) {
    final total = history.length;
    final unlabeledCount = history.where((item) {
      final id = item.scenarioId;
      return id == null ||
          !UsageScenario.values.any((scenario) => scenario.id == id);
    }).length;

    return AppCard(
      padding: const EdgeInsets.all(AppTheme.spaceMD),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Row(
            children: <Widget>[
              Icon(
                Icons.assignment_turned_in_outlined,
                size: 19,
                color: AppTheme.accentTeal,
              ),
              const SizedBox(width: AppTheme.spaceSM),
              Expanded(
                child: Text(
                  'Scenario breakdown',
                  style: AppTheme.headingMedium.copyWith(
                    color: context.txtPrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Exercise types recorded for this participant in the selected period.',
            style: AppTheme.bodySmall.copyWith(color: context.txtSecondary),
          ),
          const SizedBox(height: AppTheme.spaceMD),
          if (total == 0)
            Text(
              'No recorded scenario sessions in this period.',
              style: AppTheme.bodyMedium.copyWith(color: context.txtSecondary),
            )
          else ...<Widget>[
            for (final scenario in UsageScenario.values)
              _ScenarioBreakdownRow(
                scenario: scenario,
                count: history
                    .where((item) => item.scenarioId == scenario.id)
                    .length,
                total: total,
              ),
            if (unlabeledCount > 0)
              _UnlabeledScenarioRow(count: unlabeledCount, total: total),
          ],
        ],
      ),
    );
  }
}

class _ScenarioBreakdownRow extends StatelessWidget {
  const _ScenarioBreakdownRow({
    required this.scenario,
    required this.count,
    required this.total,
  });

  final UsageScenario scenario;
  final int count;
  final int total;

  IconData get _icon => switch (scenario) {
    UsageScenario.officeDesk => Icons.desk_outlined,
    UsageScenario.gymExercise => Icons.fitness_center_rounded,
    UsageScenario.everydayStairs => Icons.stairs_outlined,
  };

  @override
  Widget build(BuildContext context) {
    final fraction = total == 0 ? 0.0 : count / total;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppTheme.spaceSM),
      child: Row(
        children: <Widget>[
          Container(
            width: 34,
            height: 34,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppTheme.accentTeal.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(_icon, size: 18, color: AppTheme.accentTeal),
          ),
          const SizedBox(width: AppTheme.spaceSM),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Expanded(
                      child: Text(
                        scenario.label,
                        overflow: TextOverflow.ellipsis,
                        style: AppTheme.bodyMedium.copyWith(
                          color: context.txtPrimary,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    Text(
                      '$count',
                      style: AppTheme.bodyMedium.copyWith(
                        color: count > 0
                            ? AppTheme.accentTeal
                            : context.txtTertiary,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 5),
                ClipRRect(
                  borderRadius: BorderRadius.circular(99),
                  child: LinearProgressIndicator(
                    minHeight: 5,
                    value: fraction,
                    color: count > 0
                        ? AppTheme.accentTeal
                        : context.txtTertiary.withValues(alpha: 0.35),
                    backgroundColor: context.bgElevated,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _UnlabeledScenarioRow extends StatelessWidget {
  const _UnlabeledScenarioRow({required this.count, required this.total});

  final int count;
  final int total;

  @override
  Widget build(BuildContext context) {
    final fraction = total == 0 ? 0.0 : count / total;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppTheme.spaceSM),
      child: Row(
        children: <Widget>[
          Container(
            width: 34,
            height: 34,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: context.bgElevated,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.help_outline_rounded,
              size: 18,
              color: context.txtTertiary,
            ),
          ),
          const SizedBox(width: AppTheme.spaceSM),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Expanded(
                      child: Text(
                        'Unlabeled session',
                        style: AppTheme.bodyMedium.copyWith(
                          color: context.txtSecondary,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    Text(
                      '$count',
                      style: AppTheme.bodyMedium.copyWith(
                        color: context.txtTertiary,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 5),
                ClipRRect(
                  borderRadius: BorderRadius.circular(99),
                  child: LinearProgressIndicator(
                    minHeight: 5,
                    value: fraction,
                    color: context.txtTertiary.withValues(alpha: 0.55),
                    backgroundColor: context.bgElevated,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ParticipantSummarySelector extends StatelessWidget {
  const _ParticipantSummarySelector({
    required this.participants,
    required this.activeParticipantId,
    required this.history,
    required this.isRecording,
    required this.onSelected,
  });

  final List<ParticipantProfile> participants;
  final String? activeParticipantId;
  final List<SessionSummary> history;
  final bool isRecording;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    if (participants.isEmpty) {
      return const SizedBox.shrink();
    }

    ParticipantProfile? activeParticipant;
    for (final participant in participants) {
      if (participant.id == activeParticipantId) {
        activeParticipant = participant;
        break;
      }
    }
    final activeSessionCount = history
        .where((item) => item.participantId == activeParticipantId)
        .length;

    return AppCard(
      padding: const EdgeInsets.all(AppTheme.spaceMD),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Row(
            children: <Widget>[
              Icon(
                Icons.groups_2_outlined,
                size: 19,
                color: AppTheme.accentTeal,
              ),
              const SizedBox(width: AppTheme.spaceSM),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      activeParticipant?.displayLabel ?? 'Select a participant',
                      style: AppTheme.headingMedium.copyWith(
                        color: context.txtPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '$activeSessionCount recorded session${activeSessionCount == 1 ? '' : 's'} shown in this summary',
                      style: AppTheme.bodySmall.copyWith(
                        color: context.txtSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spaceMD),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: participants
                  .map((participant) {
                    final selected = participant.id == activeParticipantId;
                    final sessionCount = history
                        .where((item) => item.participantId == participant.id)
                        .length;
                    return Padding(
                      padding: const EdgeInsets.only(right: AppTheme.spaceSM),
                      child: ChoiceChip(
                        selected: selected,
                        onSelected: isRecording || selected
                            ? null
                            : (_) => onSelected(participant.id),
                        avatar: CircleAvatar(
                          backgroundColor: selected
                              ? context.bgPrimary
                              : context.bgElevated,
                          child: Text(
                            participant.id.substring(1),
                            style: AppTheme.labelSmall.copyWith(
                              color: selected
                                  ? AppTheme.accentTeal
                                  : context.txtSecondary,
                              letterSpacing: 0,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                        label: Text(
                          '$sessionCount session${sessionCount == 1 ? '' : 's'}',
                        ),
                        selectedColor: AppTheme.accentTeal.withValues(
                          alpha: 0.18,
                        ),
                        backgroundColor: context.bgElevated,
                        side: BorderSide(
                          color: selected
                              ? AppTheme.accentTeal
                              : context.dividerClr,
                        ),
                        labelStyle: AppTheme.bodySmall.copyWith(
                          color: selected
                              ? context.txtPrimary
                              : context.txtSecondary,
                          fontWeight: FontWeight.w800,
                        ),
                        showCheckmark: false,
                      ),
                    );
                  })
                  .toList(growable: false),
            ),
          ),
          if (isRecording) ...<Widget>[
            const SizedBox(height: AppTheme.spaceSM),
            Text(
              'Stop recording before switching participants.',
              style: AppTheme.bodySmall.copyWith(color: AppTheme.accentAmber),
            ),
          ],
        ],
      ),
    );
  }
}

class _BaselineReferenceCard extends StatelessWidget {
  const _BaselineReferenceCard({required this.participant});

  final ParticipantProfile participant;

  @override
  Widget build(BuildContext context) {
    final completed = BaselineReferencePosition.values
        .where((position) => participant.baselineFor(position) != null)
        .length;
    return AppCard(
      padding: const EdgeInsets.all(AppTheme.spaceMD),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Row(
            children: <Widget>[
              Icon(
                Icons.fact_check_outlined,
                size: 19,
                color: AppTheme.accentTeal,
              ),
              const SizedBox(width: AppTheme.spaceSM),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      'Baseline references',
                      style: AppTheme.headingMedium.copyWith(
                        color: context.txtPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '$completed of 3 posture references saved for ${participant.id}',
                      style: AppTheme.bodySmall.copyWith(
                        color: context.txtSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spaceSM),
          for (final position in BaselineReferencePosition.values) ...[
            _BaselineReferenceRow(
              position: position,
              reference: participant.baselineFor(position),
            ),
            if (position != BaselineReferencePosition.values.last)
              Divider(height: AppTheme.spaceMD, color: context.dividerClr),
          ],
        ],
      ),
    );
  }
}

class _BaselineReferenceRow extends StatelessWidget {
  const _BaselineReferenceRow({
    required this.position,
    required this.reference,
  });

  final BaselineReferencePosition position;
  final BaselineReference? reference;

  @override
  Widget build(BuildContext context) {
    final value = reference == null
        ? 'Not recorded'
        : 'L ${reference!.leftRms.toStringAsFixed(0)} / R ${reference!.rightRms.toStringAsFixed(0)} ADC RMS';
    return Row(
      children: <Widget>[
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                position.label,
                style: AppTheme.bodyMedium.copyWith(
                  color: context.txtPrimary,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                position.instruction,
                style: AppTheme.bodySmall.copyWith(
                  color: context.txtSecondary,
                  height: 1.2,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: AppTheme.spaceSM),
        Text(
          value,
          textAlign: TextAlign.end,
          style: AppTheme.labelSmall.copyWith(
            color: reference == null
                ? context.txtTertiary
                : AppTheme.accentTeal,
            letterSpacing: 0,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}

class _MuscleChip extends StatelessWidget {
  final String label;
  final bool isActive;
  final VoidCallback? onTap;

  const _MuscleChip({required this.label, required this.isActive, this.onTap});

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppTheme.radiusXL),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppTheme.spaceMD,
            vertical: 4,
          ),
          decoration: BoxDecoration(
            color: isActive
                ? AppTheme.accentTeal.withValues(alpha: 0.16)
                : context.bgElevated,
            borderRadius: BorderRadius.circular(AppTheme.radiusXL),
            border: Border.all(
              color: isActive ? AppTheme.accentTeal : context.dividerClr,
            ),
          ),
          child: Text(
            label,
            style: AppTheme.bodySmall.copyWith(
              color: isActive
                  ? AppTheme.accentTeal
                  : enabled
                  ? context.txtSecondary
                  : context.txtTertiary,
              fontWeight: FontWeight.w600,
              fontSize: 11,
            ),
          ),
        ),
      ),
    );
  }
}

class _EmptyHeatmap extends StatelessWidget {
  const _EmptyHeatmap();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Icon(
            Icons.heat_pump_outlined,
            size: 40,
            color: context.txtTertiary.withValues(alpha: 0.6),
          ),
          const SizedBox(height: AppTheme.spaceSM),
          Text(
            'No data yet',
            style: AppTheme.bodyMedium.copyWith(color: context.txtSecondary),
          ),
          const SizedBox(height: AppTheme.spaceXS),
          Text(
            'Run a session to see your heatmap',
            textAlign: TextAlign.center,
            style: AppTheme.bodySmall.copyWith(color: context.txtTertiary),
          ),
        ],
      ),
    );
  }
}

class _ExerciseRecommendations extends StatelessWidget {
  const _ExerciseRecommendations({
    required this.primaryImbalance,
    required this.scenarioLabel,
    required this.targetMuscle,
  });

  final String primaryImbalance;
  final String scenarioLabel;
  final TargetMuscle targetMuscle;

  static const _videos = <_ExerciseVideo>[
    _ExerciseVideo(
      id: '-r0eoFS7_5Q',
      title: 'Upper Trapezius Stretch',
      source: 'Ask Doctor Jo',
      purpose: 'Gentle mobility for a tense or overactive upper trapezius.',
    ),
    _ExerciseVideo(
      id: 'IBdiLul8x2k',
      title: 'Scapular Retraction',
      source: 'National University Hospital Singapore',
      purpose: 'A simple posture exercise for the neck and upper back.',
    ),
    _ExerciseVideo(
      id: '_94If_xw7Lg',
      title: 'Early Scapular Strengthening',
      source: 'Physiotutors',
      purpose: 'Controlled shoulder-blade strengthening with clear form cues.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    if (targetMuscle == TargetMuscle.biceps) {
      return AppCard(
        padding: const EdgeInsets.all(AppTheme.spaceLG),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              'Biceps testing mode',
              style: AppTheme.headingLarge.copyWith(color: context.txtPrimary),
            ),
            const SizedBox(height: 5),
            Text(
              'The same left-right EMG logic is being used for biceps. Place CH1 and CH3 on matching left/right biceps positions, then compare activation, RMS, and dominance in this summary.',
              style: AppTheme.bodySmall.copyWith(
                color: context.txtSecondary,
                height: 1.4,
              ),
            ),
          ],
        ),
      );
    }

    final guidance = primaryImbalance == 'Both sides symmetrical'
        ? 'Maintain balanced movement with gentle mobility and control.'
        : 'Use these as general educational exercises for $scenarioLabel. '
              'Stop if an exercise causes pain and consult a clinician when needed.';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Text(
          'Recommended exercises',
          style: AppTheme.headingLarge.copyWith(color: context.txtPrimary),
        ),
        const SizedBox(height: 5),
        Text(
          guidance,
          style: AppTheme.bodySmall.copyWith(
            color: context.txtSecondary,
            height: 1.4,
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 224,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: _videos.length,
            separatorBuilder: (_, _) => const SizedBox(width: 12),
            itemBuilder: (context, index) =>
                _ExerciseVideoCard(video: _videos[index]),
          ),
        ),
      ],
    );
  }
}

class _ExerciseVideo {
  const _ExerciseVideo({
    required this.id,
    required this.title,
    required this.source,
    required this.purpose,
  });

  final String id;
  final String title;
  final String source;
  final String purpose;
}

class _ExerciseVideoCard extends StatelessWidget {
  const _ExerciseVideoCard({required this.video});

  final _ExerciseVideo video;

  Future<void> _open(BuildContext context) async {
    final uri = Uri.parse('https://www.youtube.com/watch?v=${video.id}');
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication) &&
        context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('The video could not be opened.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 250,
      child: AppCard(
        padding: EdgeInsets.zero,
        child: InkWell(
          onTap: () => _open(context),
          borderRadius: AppTheme.cardRadius,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(AppTheme.radiusXL),
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: <Widget>[
                    Image.network(
                      'https://img.youtube.com/vi/${video.id}/hqdefault.jpg',
                      height: 112,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => Container(
                        height: 112,
                        color: context.bgElevated,
                        child: const Icon(Icons.video_library_outlined),
                      ),
                    ),
                    Container(
                      width: 42,
                      height: 42,
                      decoration: const BoxDecoration(
                        color: Color(0xDD171916),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.play_arrow_rounded,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      video.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTheme.headingMedium.copyWith(
                        color: context.txtPrimary,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      video.source,
                      style: AppTheme.labelSmall.copyWith(
                        color: AppTheme.accentTeal,
                        letterSpacing: 0,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      video.purpose,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTheme.bodySmall.copyWith(
                        color: context.txtSecondary,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
