import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../config/app_config.dart';
import '../../domain/models/feedback_view.dart';
import '../../screens/calibration_screen.dart';
import '../../theme/app_theme.dart';
import '../../widgets/session_tab_bar.dart';
import '../../widgets/connection_badge.dart';
import '../../widgets/research_context_sheet.dart';
import '../bloc/session_bloc.dart';
import 'anatomical_view_page.dart';
import 'balance_monitor_page.dart';
import 'signal_view_content.dart';

class SessionScreen extends StatelessWidget {
  const SessionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: true,
      child: Scaffold(
        backgroundColor: context.bgPrimary,
        body: const SafeArea(
          child: Padding(
            padding: EdgeInsets.fromLTRB(16, 6, 16, 0),
            child: SessionPage(),
          ),
        ),
      ),
    );
  }
}

class SessionPage extends StatefulWidget {
  const SessionPage({super.key});

  @override
  State<SessionPage> createState() => _SessionPageState();
}

class _SessionPageState extends State<SessionPage> {
  late final PageController _pageController;
  late int _selectedIndex;

  @override
  void initState() {
    super.initState();
    _selectedIndex = _indexForFeedbackView(
      context.read<SessionBloc>().state.selectedFeedbackView,
    );
    _pageController = PageController(initialPage: _selectedIndex);
    _pageController.addListener(_onPageChanged);
  }

  @override
  void dispose() {
    _pageController.removeListener(_onPageChanged);
    _pageController.dispose();
    super.dispose();
  }

  void _onPageChanged() {
    final page = _pageController.page;
    if (page != null) {
      final index = page.round();
      if (index != _selectedIndex && index >= 0) {
        setState(() => _selectedIndex = index);
        context.read<SessionBloc>().selectFeedbackView(
          _feedbackViewForIndex(index),
        );
      }
    }
  }

  FeedbackView? _feedbackViewForIndex(int index) => switch (index) {
    0 => FeedbackView.anatomicalHeatmap,
    1 => FeedbackView.balanceMonitor,
    _ => null,
  };

  int _indexForFeedbackView(FeedbackView? view) => switch (view) {
    FeedbackView.balanceMonitor => 1,
    FeedbackView.anatomicalHeatmap => 0,
    null => AppConfig.showResearcherTools ? 2 : 0,
  };

  @override
  Widget build(BuildContext context) {
    final tabs = <String>[
      'Heatmap',
      'Balance',
      if (AppConfig.showResearcherTools) 'Signal',
    ];
    final pages = <Widget>[
      const AnatomicalViewContent(),
      const BalanceMonitorContent(),
      if (AppConfig.showResearcherTools) const SignalViewContent(),
    ];

    return BlocBuilder<SessionBloc, SessionState>(
      builder: (context, state) {
        final minutes = (state.sessionSeconds / 60).floor();
        final seconds = state.sessionSeconds % 60;
        final timerStr =
            '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';

        final isConnected = state.isConnected;
        final isConnecting = state.status == SessionStatus.connecting;
        final selectedFeedbackView = state.selectedFeedbackView;
        final sharedIndex = _indexForFeedbackView(selectedFeedbackView);
        if (sharedIndex != _selectedIndex && _pageController.hasClients) {
          _selectedIndex = sharedIndex;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted && _pageController.hasClients) {
              _pageController.jumpToPage(sharedIndex);
            }
          });
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.fromLTRB(12, 8, 10, 8),
              decoration: BoxDecoration(
                color: context.bgCard,
                borderRadius: BorderRadius.circular(AppTheme.radiusLG),
                border: Border.all(color: context.dividerClr),
                boxShadow: context.cardShadow,
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: <Widget>[
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          'Session',
                          style: AppTheme.headingLarge.copyWith(
                            color: context.txtPrimary,
                            fontSize: 21,
                            height: 1.05,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Icon(
                              Icons.timer_outlined,
                              size: 14,
                              color: AppTheme.accentGreen.withValues(
                                alpha: 0.8,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              timerStr,
                              style: AppTheme.monoSmall.copyWith(
                                color: AppTheme.accentGreen,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              width: 1,
                              height: 10,
                              color: context.dividerClr,
                            ),
                            const SizedBox(width: 8),
                            Flexible(
                              child: Text(
                                selectedFeedbackView?.label ?? 'Signal View',
                                overflow: TextOverflow.ellipsis,
                                style: AppTheme.bodyMedium.copyWith(
                                  color: context.txtSecondary,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  ConnectionBadge(
                    isConnected: isConnected,
                    isConnecting: isConnecting,
                  ),
                ],
              ),
            ),

            const ResearchContextBanner(compact: true),
            const SizedBox(height: 4),
            SessionTabBar(
              selectedIndex: _selectedIndex,
              labels: tabs,
              onTap: state.isRecording
                  ? null
                  : (index) {
                      _pageController.jumpToPage(index);
                      setState(() => _selectedIndex = index);
                      context.read<SessionBloc>().selectFeedbackView(
                        _feedbackViewForIndex(index),
                      );
                    },
            ),
            const SizedBox(height: 4),

            Expanded(
              child: PageView(
                controller: _pageController,
                physics: state.isRecording
                    ? const NeverScrollableScrollPhysics()
                    : const PageScrollPhysics(),
                children: pages,
              ),
            ),

            const SizedBox(height: 4),

            const _SessionActionsBar(),
            const SizedBox(height: 8),
          ],
        );
      },
    );
  }
}

class _SessionActionsBar extends StatelessWidget {
  const _SessionActionsBar();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SessionBloc, SessionState>(
      builder: (context, state) {
        final isConnected = state.isConnected;
        final isRecording = state.isRecording;
        final isBusy = state.busy;
        final isConnecting = state.status == SessionStatus.connecting;

        return Row(
          children: [
            Expanded(
              child: ElevatedButton(
                onPressed: isBusy || !isConnected
                    ? null
                    : () async {
                        if (isRecording) {
                          await context.read<SessionBloc>().stopRecording();
                        } else {
                          final confirmed = await showRecordingContextSheet(
                            context,
                          );
                          if (confirmed && context.mounted) {
                            final selectedView = context
                                .read<SessionBloc>()
                                .state
                                .selectedFeedbackView;
                            if (selectedView == null) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Choose Heatmap or Balance before recording.',
                                  ),
                                ),
                              );
                              return;
                            }
                            await context.read<SessionBloc>().startRecording(
                              feedbackView: selectedView,
                            );
                          }
                        }
                      },
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  backgroundColor: isRecording
                      ? AppTheme.accentRed
                      : context.txtPrimary,
                  foregroundColor: context.bgPrimary,
                  disabledBackgroundColor: AppTheme.accentRed.withValues(
                    alpha: 0.16,
                  ),
                  disabledForegroundColor: AppTheme.accentRed.withValues(
                    alpha: 0.62,
                  ),
                  side: !isConnected && !isRecording
                      ? BorderSide(
                          color: AppTheme.accentRed.withValues(alpha: 0.28),
                        )
                      : null,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
                child: isConnecting
                    ? const SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.white,
                          ),
                        ),
                      )
                    : Text(
                        isRecording ? 'Stop Recording' : 'Start Recording',
                        style: AppTheme.headingMedium.copyWith(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: (!isConnected && !isRecording)
                              ? AppTheme.accentRed.withValues(alpha: 0.62)
                              : isBusy
                              ? context.txtTertiary
                              : context.bgPrimary,
                        ),
                      ),
              ),
            ),
            const SizedBox(width: AppTheme.spaceMD),
            ElevatedButton(
              onPressed: (isConnected && !isBusy)
                  ? () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const CalibrationScreen(),
                      ),
                    )
                  : null,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 8,
                ),
                backgroundColor: context.bgPrimary,
                foregroundColor: context.txtPrimary,
                disabledBackgroundColor: context.bgElevated.withValues(
                  alpha: 0.5,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(999),
                  side: BorderSide(
                    color: isConnected
                        ? context.txtPrimary
                        : context.dividerClr,
                    width: 1,
                  ),
                ),
              ),
              child: Text(
                'Calibrate',
                style: AppTheme.headingMedium.copyWith(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: isConnected ? context.txtPrimary : context.txtTertiary,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
