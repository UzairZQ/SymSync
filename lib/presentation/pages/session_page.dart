import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../theme/app_theme.dart';
import '../../widgets/session_tab_bar.dart';
import '../../widgets/status_badge.dart';
import '../bloc/session_bloc.dart';
import 'anatomical_view_page.dart';
import 'balance_monitor_page.dart';
import 'signal_view_content.dart';

class SessionPage extends StatefulWidget {
  const SessionPage({super.key});

  @override
  State<SessionPage> createState() => _SessionPageState();
}

class _SessionPageState extends State<SessionPage> {
  final PageController _pageController = PageController();
  int _selectedIndex = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SessionBloc, SessionState>(
      builder: (context, state) {
        final minutes = (state.sessionSeconds / 60).floor();
        final seconds = state.sessionSeconds % 60;
        final timerStr =
            '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';

        final statusLabel = state.status == SessionStatus.connected
            ? 'Connected'
            : state.status == SessionStatus.connecting
            ? 'Connecting'
            : state.status == SessionStatus.signalLost
            ? 'Signal Lost'
            : 'Disconnected';

        final statusState = state.status == SessionStatus.connected
            ? StatusBadgeState.connected
            : state.status == SessionStatus.connecting
            ? StatusBadgeState.recording
            : StatusBadgeState.disconnected;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.only(bottom: AppTheme.spaceMD),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: <Widget>[
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          'SymSync',
                          style: AppTheme.headingLarge.copyWith(
                            color: context.txtPrimary,
                            fontSize: 28,
                          ),
                        ),
                        const SizedBox(height: AppTheme.spaceXS),
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
                                'Live bilateral monitoring',
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
                  StatusBadge(label: statusLabel, state: statusState),
                ],
              ),
            ),

            SessionTabBar(
              selectedIndex: _selectedIndex,
              onTap: (index) {
                _pageController.jumpToPage(index);
                setState(() => _selectedIndex = index);
              },
            ),
            const SizedBox(height: AppTheme.spaceMD),

            Expanded(
              child: PageView(
                physics: const NeverScrollableScrollPhysics(),
                controller: _pageController,
                children: const <Widget>[
                  AnatomicalViewContent(),
                  BalanceMonitorContent(),
                  SignalViewContent(),
                ],
              ),
            ),

            const SizedBox(height: AppTheme.spaceMD),

            const _SessionActionsBar(),
          ],
        );
      },
    );
  }
}

class _SessionActionsBar extends StatelessWidget {
  const _SessionActionsBar();

  static const String _deviceMac = '00:07:80:8C:0A:27';

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SessionBloc, SessionState>(
      builder: (context, state) {
        final isConnected = state.isConnected;
        final isConnecting = state.status == SessionStatus.connecting;
        final isBusy = state.busy;

        return Row(
          children: [
            Expanded(
              child: ElevatedButton(
                onPressed: isBusy
                    ? null
                    : () {
                        if (isConnected) {
                          context.read<SessionBloc>().disconnect();
                        } else {
                          context.read<SessionBloc>().connect(_deviceMac);
                        }
                      },
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    vertical: AppTheme.spaceMD,
                  ),
                  backgroundColor: isConnected
                      ? AppTheme.accentRed
                      : context.txtPrimary,
                  foregroundColor: context.bgPrimary,
                  disabledBackgroundColor: context.bgElevated,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
                child: isConnecting
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.white,
                          ),
                        ),
                      )
                    : Text(
                        isConnected ? 'Stop Recording' : 'Start Recording',
                        style: AppTheme.headingMedium.copyWith(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: isBusy
                              ? context.txtTertiary
                              : context.bgPrimary,
                        ),
                      ),
              ),
            ),
            const SizedBox(width: AppTheme.spaceMD),
            ElevatedButton(
              onPressed: (isConnected && !isBusy)
                  ? () => context.read<SessionBloc>().calibrate()
                  : null,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppTheme.spaceLG,
                  vertical: AppTheme.spaceMD,
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
                  fontSize: 14,
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
