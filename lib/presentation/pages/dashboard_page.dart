import 'dart:math';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shimmer/shimmer.dart';

import '../../theme/app_theme.dart';
import '../../widgets/app_card.dart';
import '../../widgets/gradient_button.dart';
import '../../widgets/section_label.dart';
import '../../widgets/status_badge.dart';
import '../../widgets/theme_toggle.dart';
import '../bloc/session_bloc.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({
    super.key,
    required this.onOpenSession,
    required this.onOpenSummary,
    required this.onConnect,
    required this.onDisconnect,
    required this.onCalibrate,
  });

  final VoidCallback onOpenSession;
  final VoidCallback onOpenSummary;
  final VoidCallback onConnect;
  final VoidCallback onDisconnect;
  final VoidCallback onCalibrate;

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  static const List<String> _tips = <String>[
    'Keep your step rhythm even to reduce bias between legs.',
    'Breathe steadily and let the biofeedback guide your balance.',
    'A small shift toward the weaker leg can improve symmetry fast.',
    'Use the live view to correct muscle dominance in real time.',
    'Consistency over intensity helps the nervous system learn better.',
  ];

  late final String _tip = _tips[DateTime.now().millisecond % _tips.length];

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SessionBloc, SessionState>(
      builder: (context, state) {
        final lastSummary = state.history.isNotEmpty ? state.history.first : null;
        final bestScore = state.history
            .map((s) => s.averageSymmetryIndex)
            .whereType<double>()
            .fold<double?>(null, (prev, v) {
              if (prev == null) return v.abs();
              return min(prev, v.abs());
            });
        final averageScore = state.symmetryIndex;
        final scoreLabel = averageScore == null
            ? '--'
            : '${(averageScore * 100).toStringAsFixed(0)}%';
        final summaryLabel = averageScore == null
            ? 'No session yet'
            : averageScore >= 0
            ? 'Right side stronger'
            : 'Left side stronger';
        final recentDate = lastSummary == null
            ? 'No recent session'
            : '${lastSummary.startedAt.month}/${lastSummary.startedAt.day}/${lastSummary.startedAt.year}';
        final bestBalanceLabel = bestScore == null
            ? '--'
            : '${(bestScore * 100).toStringAsFixed(0)}%';
        final stats = <_StatCardData>[
          _StatCardData('Today\u2019s Sessions', '${state.history.length}', 'this week'),
          _StatCardData('Avg Symmetry', scoreLabel, 'real-time index'),
          _StatCardData('Best Balance', bestBalanceLabel, 'lowest asymmetry'),
        ];
        final rawSpots = <FlSpot>[];
        final rawPoints = state.rawPoints.take(40).toList();
        for (var i = 0; i < rawPoints.length; i++) {
          rawSpots.add(FlSpot(i.toDouble(), rawPoints[i].toDouble()));
        }

        final loading = state.history.isEmpty && state.symmetryIndex == null;
        final isConnected = state.isConnected;
        final isConnecting = state.status == SessionStatus.connecting;

        return ListView(
          key: const PageStorageKey<String>('dashboard'),
          padding: const EdgeInsets.only(bottom: 24),
          children: <Widget>[
            const SizedBox(height: AppTheme.spaceMD),
            // ── HEADER ──
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        'Good morning,',
                        style: AppTheme.bodyLarge.copyWith(
                          color: context.txtSecondary,
                        ),
                      ),
                      const SizedBox(height: AppTheme.spaceXS),
                      Text(
                        'Zoro',
                        style: AppTheme.headingMedium.copyWith(
                          color: context.txtPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
                StatusBadge(
                  label: state.status == SessionStatus.connected
                      ? 'Connected'
                      : state.status == SessionStatus.connecting
                      ? 'Connecting'
                      : 'Disconnected',
                  state: state.status == SessionStatus.connected
                      ? StatusBadgeState.connected
                      : state.status == SessionStatus.connecting
                      ? StatusBadgeState.recording
                      : StatusBadgeState.disconnected,
                ),
                const SizedBox(width: AppTheme.spaceSM),
                const ThemeToggle(),
              ],
            ),
            const SizedBox(height: AppTheme.spaceMD),

            // ── CONNECTION CARD ──
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: isConnecting
                  ? _ConnectingCard(key: const ValueKey('connecting'))
                  : isConnected
                  ? _ConnectedCard(
                      key: const ValueKey('connected'),
                      onDisconnect: widget.onDisconnect,
                    )
                  : _DisconnectedCard(
                      key: const ValueKey('disconnected'),
                      onConnect: widget.onConnect,
                    ),
            ),

            const SizedBox(height: AppTheme.spaceXL),

            // ── STAT CARDS ──
            Row(
              children: stats
                  .asMap()
                  .entries
                  .map(
                    (entry) => Expanded(
                      child: Padding(
                        padding: EdgeInsets.only(
                          left: entry.key == 0 ? 0 : AppTheme.spaceSM,
                        ),
                        child: AppCard(
                          padding: const EdgeInsets.all(AppTheme.spaceMD),
                          child: loading
                              ? _ShimmerStatCard()
                              : Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: <Widget>[
                                    SectionLabel(label: entry.value.title),
                                    const SizedBox(height: AppTheme.spaceSM),
                                    Text(
                                      entry.value.value,
                                      style: AppTheme.displayMedium.copyWith(
                                        color: context.txtPrimary,
                                        fontSize: 30,
                                      ),
                                    ),
                                    const SizedBox(height: AppTheme.spaceXS),
                                    Text(
                                      entry.value.subtitle,
                                      style: AppTheme.bodyMedium.copyWith(
                                        color: context.txtSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
            const SizedBox(height: AppTheme.spaceXL),

            // ── LAST SESSION CARD ──
            loading
                ? _ShimmerRecentSessionCard()
                : AppCard(
                    child: Padding(
                      padding: const EdgeInsets.all(AppTheme.spaceMD),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: <Widget>[
                          const SectionLabel(label: 'Last Session'),
                          const SizedBox(height: AppTheme.spaceSM),
                          Text(
                            recentDate,
                            style: AppTheme.bodyMedium.copyWith(
                              color: context.txtSecondary,
                            ),
                          ),
                          const SizedBox(height: AppTheme.spaceMD),
                          SizedBox(
                            height: 90,
                            child: rawSpots.isEmpty
                                ? Center(
                                    child: Text(
                                      'Waiting for session data',
                                      style: AppTheme.bodyMedium.copyWith(
                                        color: context.txtSecondary,
                                      ),
                                    ),
                                  )
                                : LineChart(
                                    LineChartData(
                                      backgroundColor: Colors.transparent,
                                      gridData: const FlGridData(show: false),
                                      titlesData:
                                          const FlTitlesData(show: false),
                                      borderData:
                                          FlBorderData(show: false),
                                      minY: 0,
                                      maxY: 4096,
                                      lineBarsData: <LineChartBarData>[
                                        LineChartBarData(
                                          spots: rawSpots,
                                          color: AppTheme.accentTeal,
                                          isCurved: true,
                                          barWidth: 3,
                                          dotData:
                                              const FlDotData(show: false),
                                          belowBarData:
                                              BarAreaData(show: false),
                                        ),
                                      ],
                                    ),
                                  ),
                          ),
                          const SizedBox(height: AppTheme.spaceMD),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: <Widget>[
                              Text(
                                'Symmetry overview',
                                style: AppTheme.headingMedium.copyWith(
                                  color: context.txtPrimary,
                                ),
                              ),
                              Icon(Icons.chevron_right, color: context.txtSecondary),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
            const SizedBox(height: AppTheme.spaceXL),

            // ── QUICK START CARD ──
            AppCard(
              child: Padding(
                padding: const EdgeInsets.all(AppTheme.spaceMD),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    const SectionLabel(label: 'Quick Start'),
                    const SizedBox(height: AppTheme.spaceSM),
                    Text(
                      'Ready to begin a new bilateral recording?',
                      style: AppTheme.headingMedium.copyWith(
                        color: context.txtPrimary,
                      ),
                    ),
                    const SizedBox(height: AppTheme.spaceSM),
                    Text(
                      'Tap to begin bilateral EMG recording',
                      style: AppTheme.bodyMedium.copyWith(
                        color: context.txtSecondary,
                      ),
                    ),
                    const SizedBox(height: AppTheme.spaceMD),
                    GradientButton(
                      label: 'Start New Session',
                      onPressed: widget.onOpenSession,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppTheme.spaceXL),

            // ── TIPS CARD ──
            loading
                ? _ShimmerTipsCard()
                : AppCard(
                    child: Padding(
                      padding: const EdgeInsets.all(AppTheme.spaceMD),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Container(
                            width: 42,
                            height: 42,
                            decoration: BoxDecoration(
                              gradient: AppTheme.dangerGradient,
                              borderRadius:
                                  BorderRadius.circular(AppTheme.radiusMD),
                            ),
                            child: const Icon(
                              Icons.lightbulb,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(width: AppTheme.spaceMD),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                Text(
                                  'HMI Tip',
                                  style: AppTheme.labelSmall.copyWith(
                                    color: context.txtPrimary,
                                  ),
                                ),
                                const SizedBox(height: AppTheme.spaceSM),
                                Text(
                                  _tip,
                                  style: AppTheme.bodyLarge.copyWith(
                                    color: context.txtPrimary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
            const SizedBox(height: AppTheme.spaceXL),

            // ── RECENT SYMMETRY CARD ──
            AppCard(
              child: Padding(
                padding: const EdgeInsets.all(AppTheme.spaceMD),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      'Recent symmetry',
                      style: AppTheme.headingMedium.copyWith(
                        color: context.txtPrimary,
                      ),
                    ),
                    const SizedBox(height: AppTheme.spaceSM),
                    Text(
                      summaryLabel,
                      style: AppTheme.bodyMedium.copyWith(
                        color: context.txtSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

// ── CONNECTION CARDS ───────────────────────────────────────────────────
class _DisconnectedCard extends StatelessWidget {
  const _DisconnectedCard({super.key, required this.onConnect});
  final VoidCallback onConnect;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.spaceMD,
        vertical: AppTheme.spaceSM,
      ),
      child: Row(
        children: <Widget>[
          _PulsingDot(color: AppTheme.accentAmber),
          const SizedBox(width: AppTheme.spaceMD),
          Expanded(
            child: Text(
              'biosignalsplux not connected',
              style: AppTheme.bodyMedium.copyWith(
                color: context.txtSecondary,
              ),
            ),
          ),
          OutlinedButton(
            onPressed: onConnect,
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: AppTheme.accentTeal),
              foregroundColor: AppTheme.accentTeal,
              padding: const EdgeInsets.symmetric(
                horizontal: AppTheme.spaceMD,
                vertical: AppTheme.spaceSM,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppTheme.radiusMD),
              ),
            ),
            child: const Text('Connect'),
          ),
        ],
      ),
    );
  }
}

class _ConnectingCard extends StatelessWidget {
  const _ConnectingCard({super.key});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: EdgeInsets.zero,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppTheme.spaceMD,
              vertical: AppTheme.spaceSM,
            ),
            child: Row(
              children: <Widget>[
                Shimmer.fromColors(
                  baseColor: context.bgElevated,
                  highlightColor: context.bgCard,
                  child: Container(
                    width: 10,
                    height: 10,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
                const SizedBox(width: AppTheme.spaceMD),
                Expanded(
                  child: Shimmer.fromColors(
                    baseColor: context.bgElevated,
                    highlightColor: context.bgCard,
                    child: Container(
                      height: 14,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius:
                            BorderRadius.circular(AppTheme.radiusSM),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: AppTheme.spaceMD),
                const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      AppTheme.accentTeal,
                    ),
                  ),
                ),
              ],
            ),
          ),
          LinearProgressIndicator(
            valueColor:
                const AlwaysStoppedAnimation<Color>(AppTheme.accentTeal),
            backgroundColor: context.bgElevated,
            minHeight: 3,
          ),
        ],
      ),
    );
  }
}

class _ConnectedCard extends StatelessWidget {
  const _ConnectedCard({super.key, required this.onDisconnect});
  final VoidCallback onDisconnect;

  static const String _mac = '00:07:80:8C:0A:27';

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.spaceMD,
        vertical: AppTheme.spaceSM,
      ),
      child: Row(
        children: <Widget>[
          Container(
            width: 10,
            height: 10,
            decoration: const BoxDecoration(
              color: AppTheme.accentGreen,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: AppTheme.spaceMD),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  'biosignalsplux connected',
                  style: AppTheme.bodyMedium.copyWith(
                    color: AppTheme.accentGreen,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  _mac,
                  style: AppTheme.monoSmall.copyWith(
                    color: context.txtTertiary,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: onDisconnect,
            child: Text(
              'Disconnect',
              style: AppTheme.bodyMedium.copyWith(
                color: context.txtTertiary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PulsingDot extends StatefulWidget {
  const _PulsingDot({required this.color});
  final Color color;

  @override
  State<_PulsingDot> createState() => _PulsingDotState();
}

class _PulsingDotState extends State<_PulsingDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    _anim = Tween<double>(begin: 0.4, end: 1.0).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, __) => Opacity(
        opacity: _anim.value,
        child: Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: widget.color,
            shape: BoxShape.circle,
          ),
        ),
      ),
    );
  }
}

// ── SHIMMER PLACEHOLDERS ──────────────────────────────────────────────────
class _ShimmerStatCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: context.bgElevated,
      highlightColor:
          context.isDark ? context.bgCard : Colors.grey.shade200,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Container(
            height: 12,
            width: 72,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(AppTheme.radiusSM),
            ),
          ),
          const SizedBox(height: AppTheme.spaceSM),
          Container(
            height: 32,
            width: 56,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(AppTheme.radiusSM),
            ),
          ),
          const SizedBox(height: AppTheme.spaceXS),
          Container(
            height: 12,
            width: 80,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(AppTheme.radiusSM),
            ),
          ),
        ],
      ),
    );
  }
}

class _ShimmerRecentSessionCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spaceMD),
        child: Shimmer.fromColors(
          baseColor: context.bgElevated,
          highlightColor:
              context.isDark ? context.bgCard : Colors.grey.shade200,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Container(
                height: 12,
                width: 80,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(AppTheme.radiusSM),
                ),
              ),
              const SizedBox(height: AppTheme.spaceSM),
              Container(
                height: 16,
                width: 120,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(AppTheme.radiusSM),
                ),
              ),
              const SizedBox(height: AppTheme.spaceMD),
              Container(
                height: 80,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(AppTheme.radiusSM),
                ),
              ),
              const SizedBox(height: AppTheme.spaceSM),
              Container(
                height: 12,
                width: 100,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(AppTheme.radiusSM),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ShimmerTipsCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spaceMD),
        child: Shimmer.fromColors(
          baseColor: context.bgElevated,
          highlightColor:
              context.isDark ? context.bgCard : Colors.grey.shade200,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Container(
                width: 42,
                height: 42,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: AppTheme.spaceMD),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Container(
                      height: 14,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(AppTheme.radiusSM),
                      ),
                    ),
                    const SizedBox(height: AppTheme.spaceXS),
                    Container(
                      height: 12,
                      width: 160,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(AppTheme.radiusSM),
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

class _StatCardData {
  const _StatCardData(this.title, this.value, this.subtitle);
  final String title;
  final String value;
  final String subtitle;
}
