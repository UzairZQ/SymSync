import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

import '../domain/models/target_muscle.dart';
import '../theme/app_theme.dart';

Future<void> showSensorPlacementSheet(
  BuildContext context, {
  TargetMuscle targetMuscle = TargetMuscle.trapezius,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    builder: (context) => _SensorPlacementSheet(targetMuscle: targetMuscle),
  );
}

class SensorPlacementDiagram extends StatelessWidget {
  const SensorPlacementDiagram({super.key, this.showInstructions = true});

  final bool showInstructions;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        Expanded(
          child: Stack(
            alignment: Alignment.center,
            children: <Widget>[
              Positioned.fill(
                child: Image.asset(
                  'assets/images/upper_body_clinical.png',
                  fit: BoxFit.contain,
                  filterQuality: FilterQuality.high,
                ),
              ),
              const Align(
                alignment: Alignment(-0.29, -0.12),
                child: _PlacementMarker(number: '1', side: 'LEFT'),
              ),
              const Align(
                alignment: Alignment(0.29, -0.12),
                child: _PlacementMarker(number: '2', side: 'RIGHT'),
              ),
            ],
          ),
        ),
        if (showInstructions) ...<Widget>[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.88),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                const Icon(
                  Icons.straighten_rounded,
                  color: AppTheme.accentTeal,
                  size: 18,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Place each sensor halfway between C7 (the bump at the base of the neck) and the outer shoulder bone (acromion).',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      height: 1.4,
                      color: AppTheme.lightTextSecondary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

class _SensorPlacementSheet extends StatelessWidget {
  const _SensorPlacementSheet({required this.targetMuscle});

  final TargetMuscle targetMuscle;

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.9,
      minChildSize: 0.65,
      maxChildSize: 0.96,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: context.bgPrimary,
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(AppTheme.radiusXL),
            ),
          ),
          child: ListView(
            controller: scrollController,
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 32),
            children: <Widget>[
              Center(
                child: Container(
                  width: 42,
                  height: 4,
                  decoration: BoxDecoration(
                    color: context.dividerClr,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: <Widget>[
                  Expanded(
                    child: Text(
                      '${targetMuscle.chipLabel} sensor placement',
                      style: AppTheme.headingLarge.copyWith(
                        color: context.txtPrimary,
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Close placement guide',
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
              Text(
                'Use the same anatomical position on both sides for a fair bilateral comparison.',
                style: AppTheme.bodyMedium.copyWith(
                  color: context.txtSecondary,
                  height: 1.45,
                ),
              ),
              const SizedBox(height: 16),
              if (targetMuscle == TargetMuscle.trapezius)
                Container(
                  height: 430,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0F4F8),
                    borderRadius: AppTheme.cardRadius,
                    border: Border.all(color: context.dividerClr),
                  ),
                  child: const SensorPlacementDiagram(),
                )
              else
                _bicepsPlacementCard(context: context),
              const SizedBox(height: 16),
              const _PlacementStep(
                number: '1',
                title: 'Prepare the skin',
                body:
                    'Use clean, dry, intact skin. Remove lotion and secure loose cables to reduce movement noise.',
              ),
              _PlacementStep(
                number: '2',
                title: 'Find the landmarks',
                body: targetMuscle == TargetMuscle.trapezius
                    ? 'Locate C7 at the base of the neck and the acromion at the outer edge of the shoulder.'
                    : 'Locate the elbow crease and the medial acromion at the inner edge of the shoulder.',
              ),
              _PlacementStep(
                number: '3',
                title: 'Match both sides',
                body: targetMuscle == TargetMuscle.trapezius
                    ? 'Place each sensor halfway along that line and orient it in the same direction as the upper-trapezius fibers.'
                    : 'Place each sensor one-third of the way from the elbow crease toward the medial acromion, aligned with the muscle fibres.',
              ),
              const SizedBox(height: 8),
              Text(
                'Avoid placement directly over bone, broken or irritated skin. Follow the sensor manufacturer’s instructions for electrode spacing, reference electrodes, and cable connection.',
                style: AppTheme.bodySmall.copyWith(
                  color: context.txtTertiary,
                  height: 1.5,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _bicepsPlacementCard({required BuildContext context}) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: context.bgCard,
        borderRadius: AppTheme.cardRadius,
        border: Border.all(color: context.dividerClr),
      ),
      child: Column(
        children: <Widget>[
          const Icon(Icons.fitness_center_rounded, size: 52),
          const SizedBox(height: 12),
          Text(
            'Place the electrodes on the front of each upper arm, one-third of '
            'the way from the elbow crease toward the inner shoulder landmark. '
            'Align them with the muscle fibres and mirror the position on both sides.',
            textAlign: TextAlign.center,
            style: AppTheme.bodyMedium.copyWith(
              color: context.txtSecondary,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 12),
          TextButton.icon(
            onPressed: () async {
              final opened = await launchUrl(
                Uri.parse('https://seniam.org/bicepsbrachii.html'),
                mode: LaunchMode.externalApplication,
              );
              if (!opened && context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Could not open the reference.'),
                  ),
                );
              }
            },
            icon: const Icon(Icons.open_in_new_rounded, size: 16),
            label: const Text('Open SENIAM placement reference'),
          ),
        ],
      ),
    );
  }
}

class _PlacementStep extends StatelessWidget {
  const _PlacementStep({
    required this.number,
    required this.title,
    required this.body,
  });

  final String number;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Container(
            width: 28,
            height: 28,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              color: AppTheme.accentTeal,
              shape: BoxShape.circle,
            ),
            child: Text(
              number,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  title,
                  style: AppTheme.headingMedium.copyWith(
                    color: context.txtPrimary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  body,
                  style: AppTheme.bodySmall.copyWith(
                    color: context.txtSecondary,
                    height: 1.45,
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

class _PlacementMarker extends StatelessWidget {
  const _PlacementMarker({required this.number, required this.side});

  final String number;
  final String side;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '$side upper trapezius sensor placement',
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Container(
            width: 30,
            height: 30,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: const Color(0xFF2563EB),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 3),
              boxShadow: const <BoxShadow>[
                BoxShadow(
                  color: Color(0x552563EB),
                  blurRadius: 12,
                  spreadRadius: 3,
                ),
              ],
            ),
            child: Text(
              number,
              style: GoogleFonts.inter(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          const SizedBox(height: 3),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
            decoration: BoxDecoration(
              color: AppTheme.lightTextPrimary.withValues(alpha: 0.82),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              side,
              style: GoogleFonts.inter(
                color: Colors.white,
                fontSize: 7,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
