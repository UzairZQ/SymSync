import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class SessionConfirmationModal extends StatelessWidget {
  final String channelA;
  final String channelB;
  final VoidCallback onConfirm;
  final VoidCallback onCancel;

  const SessionConfirmationModal({
    super.key,
    required this.channelA,
    required this.channelB,
    required this.onConfirm,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: AppTheme.spaceLG),
      child: Container(
        decoration: BoxDecoration(
          color: context.bgCard,
          borderRadius: BorderRadius.circular(AppTheme.radiusLG),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 24,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        padding: const EdgeInsets.all(AppTheme.spaceLG),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Text(
              'Ready to Record?',
              style: AppTheme.headingLarge.copyWith(
                color: context.txtPrimary,
                fontSize: 22,
              ),
            ),
            const SizedBox(height: AppTheme.spaceLG),
            Container(
              decoration: BoxDecoration(
                color: context.bgElevated,
                borderRadius: BorderRadius.circular(AppTheme.radiusMD),
                border: Border.all(color: context.dividerClr),
              ),
              padding: const EdgeInsets.all(AppTheme.spaceMD),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  _ChannelDisplay(label: 'Channel A →', leg: channelA),
                  const SizedBox(height: AppTheme.spaceMD),
                  _ChannelDisplay(label: 'Channel B →', leg: channelB),
                ],
              ),
            ),
            const SizedBox(height: AppTheme.spaceLG),
            Text(
              'Double-check your cable placement before starting.',
              textAlign: TextAlign.center,
              style: AppTheme.bodyMedium.copyWith(color: context.txtSecondary),
            ),
            const SizedBox(height: AppTheme.spaceLG),
            Row(
              children: <Widget>[
                Expanded(
                  child: ElevatedButton(
                    onPressed: onCancel,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: context.bgElevated,
                      foregroundColor: context.txtPrimary,
                      side: BorderSide(color: context.dividerClr),
                      padding: const EdgeInsets.symmetric(
                        vertical: AppTheme.spaceMD,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                    child: Text(
                      'Cancel',
                      style: AppTheme.headingMedium.copyWith(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: context.txtPrimary,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: AppTheme.spaceMD),
                Expanded(
                  child: ElevatedButton(
                    onPressed: onConfirm,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: context.txtPrimary,
                      foregroundColor: context.bgPrimary,
                      padding: const EdgeInsets.symmetric(
                        vertical: AppTheme.spaceMD,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                    child: Text(
                      'Start',
                      style: AppTheme.headingMedium.copyWith(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: context.bgPrimary,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ChannelDisplay extends StatelessWidget {
  final String label;
  final String leg;

  const _ChannelDisplay({required this.label, required this.leg});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Text(
          label,
          style: AppTheme.bodyMedium.copyWith(
            color: context.txtSecondary,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(width: AppTheme.spaceMD),
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppTheme.spaceMD,
            vertical: AppTheme.spaceSM,
          ),
          decoration: BoxDecoration(
            color: context.bgPrimary,
            borderRadius: BorderRadius.circular(AppTheme.radiusSM),
            border: Border.all(color: context.dividerClr),
          ),
          child: Text(
            leg[0].toUpperCase() + leg.substring(1),
            style: AppTheme.bodyMedium.copyWith(
              color: context.txtPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}
