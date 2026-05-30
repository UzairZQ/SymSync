import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';
import '../../widgets/app_card.dart';
import '../../widgets/section_label.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      key: const PageStorageKey<String>('profile'),
      padding: const EdgeInsets.only(bottom: AppTheme.spaceXXL),
      children: <Widget>[
        const SizedBox(height: AppTheme.spaceMD),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppTheme.spaceSM),
          child: Text(
            'Profile',
            style: AppTheme.headingLarge.copyWith(color: AppTheme.textPrimary),
          ),
        ),
        const SizedBox(height: AppTheme.spaceLG),
        AppCard(
          padding: const EdgeInsets.all(AppTheme.spaceMD),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              const SectionLabel(label: 'App settings'),
              const SizedBox(height: AppTheme.spaceSM),
              Text(
                'Access your device pairing, notifications, and app preferences here.',
                style: AppTheme.bodyLarge.copyWith(
                  color: AppTheme.textSecondary,
                  height: 1.5,
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
              Text(
                'Account',
                style: AppTheme.headingMedium.copyWith(
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: AppTheme.spaceSM),
              Text(
                'Personal profile data and preferences will appear here once configured.',
                style: AppTheme.bodyLarge.copyWith(
                  color: AppTheme.textSecondary,
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
