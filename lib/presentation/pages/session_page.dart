import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';
import '../../widgets/app_card.dart';
import '../../widgets/section_label.dart';
import 'anatomical_view_page.dart';
import 'balance_monitor_page.dart';

enum SessionViewTab { anatomical, balance }

class SessionPage extends StatefulWidget {
  const SessionPage({super.key});

  @override
  State<SessionPage> createState() => _SessionPageState();
}

class _SessionPageState extends State<SessionPage> {
  SessionViewTab _selectedTab = SessionViewTab.anatomical;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.only(bottom: AppTheme.spaceLG),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      'Session Control',
                      style: AppTheme.headingLarge.copyWith(
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: AppTheme.spaceXS),
                    Text(
                      'Choose your live monitoring view',
                      style: AppTheme.bodyLarge.copyWith(
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppTheme.spaceSM,
                  vertical: AppTheme.spaceXS,
                ),
                decoration: BoxDecoration(
                  color: AppTheme.backgroundCard,
                  borderRadius: BorderRadius.circular(AppTheme.radiusXL),
                  border: Border.all(color: AppTheme.divider),
                ),
                child: Text(
                  _selectedTab == SessionViewTab.anatomical
                      ? 'Live'
                      : 'Balance',
                  style: AppTheme.bodyMedium.copyWith(
                    color: AppTheme.textSecondary,
                  ),
                ),
              ),
            ],
          ),
        ),
        AppCard(
          padding: const EdgeInsets.all(AppTheme.spaceMD),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              const SectionLabel(label: 'View mode'),
              const SizedBox(height: AppTheme.spaceSM),
              Row(
                children: <Widget>[
                  _buildOptionButton(
                    label: 'Anatomical',
                    selected: _selectedTab == SessionViewTab.anatomical,
                    onTap: () => setState(
                      () => _selectedTab = SessionViewTab.anatomical,
                    ),
                  ),
                  const SizedBox(width: AppTheme.spaceSM),
                  _buildOptionButton(
                    label: 'Balance',
                    selected: _selectedTab == SessionViewTab.balance,
                    onTap: () =>
                        setState(() => _selectedTab = SessionViewTab.balance),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: AppTheme.spaceXL),
        Expanded(
          child: _selectedTab == SessionViewTab.anatomical
              ? const AnatomicalViewContent()
              : const BalanceMonitorContent(),
        ),
      ],
    );
  }

  Widget _buildOptionButton({
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: AppTheme.spaceMD),
          decoration: BoxDecoration(
            color: selected
                ? AppTheme.accentTeal.withValues(alpha: 0.18)
                : AppTheme.backgroundElevated,
            borderRadius: BorderRadius.circular(AppTheme.radiusLG),
            border: Border.all(
              color: selected ? AppTheme.accentTeal : AppTheme.divider,
            ),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: AppTheme.bodyLarge.copyWith(
              color: selected ? AppTheme.accentTeal : AppTheme.textPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }
}
