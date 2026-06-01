import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../theme/app_theme.dart';
import '../../widgets/app_card.dart';
import '../../widgets/theme_toggle.dart';
import '../bloc/session_bloc.dart';

class DashboardPage extends StatelessWidget {
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
  Widget build(BuildContext context) {
    return BlocBuilder<SessionBloc, SessionState>(
      builder: (context, state) {
        final symmetry = state.symmetryIndex;
        final index = symmetry == null
            ? 90
            : (100 - min(65, symmetry.abs() * 100)).round();
        final avg = symmetry == null
            ? '88.4'
            : (100 - symmetry.abs() * 100).toStringAsFixed(1);
        final symmetryScores = state.history
            .map((s) => s.averageSymmetryIndex)
            .whereType<double>()
            .toList();
        final best = symmetryScores.isEmpty
            ? '94%'
            : '${(100 - symmetryScores.map((s) => s.abs()).reduce(min) * 100).toStringAsFixed(0)}%';
        final channelA = state.latestRaw;
        final channelB = state.rawPoints.isEmpty ? 712 : state.rawPoints.last;
        final isConnected = state.isConnected;

        return ListView(
          key: const PageStorageKey<String>('dashboard'),
          padding: const EdgeInsets.only(bottom: 28),
          children: <Widget>[
            const SizedBox(height: 8),
            Row(
              children: <Widget>[
                Expanded(
                  child: Text(
                    'SymSync',
                    style: AppTheme.headingLarge.copyWith(
                      color: context.txtPrimary,
                      fontSize: 28,
                    ),
                  ),
                ),
                const ThemeToggle(),
              ],
            ),
            const SizedBox(height: 28),
            Text(
              'Good morning,\nZoro',
              style: AppTheme.displayLarge.copyWith(
                color: context.txtPrimary,
                fontSize: 32,
                height: 1.08,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Your movement symmetry is up 4% this week. Let’s maintain this momentum with a calibration session.',
              style: AppTheme.bodyMedium.copyWith(
                color: context.txtSecondary,
                height: 1.45,
              ),
            ),
            const SizedBox(height: 20),
            AppCard(
              padding: const EdgeInsets.all(28),
              child: Column(
                children: <Widget>[
                  SizedBox(
                    height: 148,
                    width: 148,
                    child: Stack(
                      alignment: Alignment.center,
                      children: <Widget>[
                        CircularProgressIndicator(
                          value: index / 100,
                          strokeWidth: 9,
                          backgroundColor: context.bgElevated,
                          valueColor: const AlwaysStoppedAnimation<Color>(
                            AppTheme.accentTeal,
                          ),
                        ),
                        Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: <Widget>[
                            Text(
                              '$index%',
                              style: AppTheme.displayMedium.copyWith(
                                color: context.txtPrimary,
                                fontSize: 30,
                              ),
                            ),
                            Text(
                              'INDEX',
                              style: AppTheme.labelSmall.copyWith(
                                color: context.txtTertiary,
                                letterSpacing: 0.8,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 26),
                  _MetricRow(
                    label: 'Sessions Today',
                    value: '${state.history.length}',
                  ),
                  _MetricRow(label: 'Avg Symmetry', value: avg),
                  _MetricRow(label: 'Best Balance', value: best),
                ],
              ),
            ),
            const SizedBox(height: 18),
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: context.txtPrimary,
                borderRadius: AppTheme.cardRadius,
                boxShadow: const <BoxShadow>[
                  BoxShadow(
                    color: Color(0x26000000),
                    blurRadius: 22,
                    offset: Offset(0, 14),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  Text(
                    'Quick Start',
                    style: AppTheme.headingMedium.copyWith(
                      color: context.bgPrimary,
                      fontSize: 22,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Begin a real-time motion analysis session with automated sensors.',
                    style: AppTheme.bodyMedium.copyWith(
                      color: context.bgPrimary.withValues(alpha: 0.78),
                      height: 1.45,
                    ),
                  ),
                  const SizedBox(height: 18),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: context.bgPrimary.withValues(alpha: 0.16),
                      ),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Row(
                      children: <Widget>[
                        Icon(
                          Icons.sensors_outlined,
                          color: isConnected
                              ? AppTheme.accentLime
                              : AppTheme.accentAmber,
                          size: 18,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            isConnected
                                ? 'BIOSIGNALSPLUX: CONNECTED'
                                : 'BIOSIGNALSPLUX: NOT CONNECTED',
                            style: AppTheme.labelSmall.copyWith(
                              color: context.bgPrimary,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton(
                    onPressed: isConnected ? onDisconnect : onConnect,
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(
                        color: context.bgPrimary.withValues(alpha: 0.8),
                      ),
                      foregroundColor: context.bgPrimary,
                      shape: const StadiumBorder(),
                      padding: const EdgeInsets.symmetric(vertical: 13),
                    ),
                    child: Text(
                      isConnected ? 'Disconnect Device' : 'Connect Device',
                    ),
                  ),
                  const SizedBox(height: 8),
                  FilledButton.icon(
                    onPressed: onOpenSession,
                    icon: const Icon(Icons.play_arrow_rounded),
                    label: const Text('Launch Session'),
                    style: FilledButton.styleFrom(
                      backgroundColor: context.bgPrimary,
                      foregroundColor: context.txtPrimary,
                      shape: const StadiumBorder(),
                      padding: const EdgeInsets.symmetric(vertical: 13),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            _ChannelCard(
              label: 'CHANNEL A',
              title: 'Left Hemisphere',
              value: channelA.toString(),
              color: AppTheme.leftLeg,
            ),
            const SizedBox(height: 12),
            _ChannelCard(
              label: 'CHANNEL B',
              title: 'Right Hemisphere',
              value: channelB.toString(),
              color: AppTheme.rightLeg,
            ),
            const SizedBox(height: 18),
            AppCard(
              padding: const EdgeInsets.all(22),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      Expanded(
                        child: Text(
                          'Recent\nSessions',
                          style: AppTheme.headingMedium.copyWith(
                            color: context.txtPrimary,
                            fontSize: 22,
                            height: 1.05,
                          ),
                        ),
                      ),
                      TextButton(
                        onPressed: onOpenSummary,
                        child: const Text('View all'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const _SessionListItem(
                    title: 'Morning Gait Analysis',
                    tag: 'Optimal',
                  ),
                  const _SessionListItem(
                    title: 'Post-Rehab Strength',
                    tag: 'Fair',
                  ),
                  const _SessionListItem(
                    title: 'Stair Climbing Test',
                    tag: 'Critical',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            AppCard(
              padding: EdgeInsets.zero,
              child: ClipRRect(
                borderRadius: AppTheme.cardRadius,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Padding(
                      padding: const EdgeInsets.fromLTRB(24, 24, 24, 14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            'RECOMMENDED READING',
                            style: AppTheme.labelSmall.copyWith(
                              color: AppTheme.accentBlue,
                              letterSpacing: 1,
                            ),
                          ),
                          const SizedBox(height: 14),
                          Text(
                            'Understanding the nuances of Pelvic Tilt and Kinetic Chain Symmetry',
                            style: AppTheme.headingMedium.copyWith(
                              color: context.txtPrimary,
                              fontSize: 22,
                              height: 1.12,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            'Clinical studies show that a 5% improvement in pelvic stability correlates with reduced joint inflammation.',
                            style: AppTheme.bodyMedium.copyWith(
                              color: context.txtSecondary,
                              height: 1.45,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      height: 132,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: <Color>[
                            AppTheme.accentAmber.withValues(alpha: 0.25),
                            context.txtPrimary.withValues(alpha: 0.9),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                      child: Center(
                        child: Icon(
                          Icons.self_improvement,
                          size: 60,
                          color: context.bgPrimary.withValues(alpha: 0.9),
                        ),
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

class _MetricRow extends StatelessWidget {
  const _MetricRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        children: <Widget>[
          Expanded(
            child: Text(
              label.toUpperCase(),
              style: AppTheme.labelSmall.copyWith(
                color: context.txtTertiary,
                letterSpacing: 1,
              ),
            ),
          ),
          Text(
            value,
            style: AppTheme.headingMedium.copyWith(
              color: context.txtPrimary,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _ChannelCard extends StatelessWidget {
  const _ChannelCard({
    required this.label,
    required this.title,
    required this.value,
    required this.color,
  });

  final String label;
  final String title;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            label,
            style: AppTheme.labelSmall.copyWith(
              color: context.txtTertiary,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            title,
            style: AppTheme.headingMedium.copyWith(
              color: context.txtPrimary,
              fontSize: 20,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: <Widget>[
              Text(
                value,
                style: AppTheme.displayMedium.copyWith(
                  color: context.txtPrimary,
                  fontSize: 30,
                ),
              ),
              const SizedBox(width: 5),
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Text(
                  'uV',
                  style: AppTheme.bodyMedium.copyWith(
                    color: context.txtTertiary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 42,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: List<Widget>.generate(8, (index) {
                final heights = <double>[16, 22, 30, 18, 26, 14, 24, 20];
                return Expanded(
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    height: heights[index],
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: index.isEven ? 0.55 : 0.8),
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(8),
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }
}

class _SessionListItem extends StatelessWidget {
  const _SessionListItem({required this.title, required this.tag});

  final String title;
  final String tag;

  @override
  Widget build(BuildContext context) {
    final tagColor = switch (tag) {
      'Optimal' => AppTheme.accentLime,
      'Fair' => AppTheme.accentAmber,
      _ => AppTheme.accentRed,
    };
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: <Widget>[
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: tagColor.withValues(alpha: 0.18),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.directions_walk, color: tagColor, size: 16),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              title,
              style: AppTheme.bodyMedium.copyWith(
                color: context.txtPrimary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
            decoration: BoxDecoration(
              color: tagColor.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              tag,
              style: AppTheme.labelSmall.copyWith(
                color: tag == 'Critical'
                    ? AppTheme.accentRed
                    : AppTheme.accentGreen,
                letterSpacing: 0,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
