import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

Future<void> showTermsGlossarySheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    builder: (context) => const TermsGlossarySheet(),
  );
}

class TermsGlossarySheet extends StatelessWidget {
  const TermsGlossarySheet({super.key});

  static const _sections = <_GlossarySection>[
    _GlossarySection(
      title: 'Balance and symmetry',
      terms: <_GlossaryTerm>[
        _GlossaryTerm(
          name: 'Symmetry index',
          simple:
              'Shows which side is more active compared with the total activity from both sides.',
          detail:
              '0% means equal activation. A negative value means the left side is more active; a positive value means the right side is more active. The possible range is −100% to +100%.',
        ),
        _GlossaryTerm(
          name: 'Balance score / Index',
          simple: 'Turns the side-to-side difference into an easy 0–100 score.',
          detail:
              '100 is the most balanced result. Lower scores mean a larger difference between the two sides.',
        ),
        _GlossaryTerm(
          name: 'Average symmetry',
          simple:
              'Your average balance score across the readings included in the current view.',
          detail:
              'A higher value means the two sides were more similar overall.',
        ),
        _GlossaryTerm(
          name: 'Best balance',
          simple:
              'The most balanced completed session in the selected history.',
          detail:
              'This is the session with the smallest left-versus-right difference, shown as a score out of 100.',
        ),
        _GlossaryTerm(
          name: 'Average deviation',
          simple: 'The average distance away from perfectly equal activation.',
          detail:
              '0% is ideal equality. Larger percentages indicate a larger typical side-to-side difference.',
        ),
        _GlossaryTerm(
          name: 'Dominance / Primary imbalance',
          simple:
              'The side that was usually more active during the selected period.',
          detail:
              'Dominance describes the EMG pattern only. It does not by itself mean weakness, injury, or poor movement.',
        ),
      ],
    ),
    _GlossarySection(
      title: 'Muscle activity',
      terms: <_GlossaryTerm>[
        _GlossaryTerm(
          name: 'Relative activation',
          simple:
              'How active a muscle is compared with the highest activity seen in that session.',
          detail:
              'The app currently reports relative session activity, not a clinical percentage of maximum voluntary contraction (%MVC).',
        ),
        _GlossaryTerm(
          name: 'Heatmap',
          simple:
              'A color view of relative muscle activity on the left and right upper back.',
          detail:
              'Cool colors represent lower relative activity and warm colors represent higher relative activity. Compare colors only within the same scale and session.',
        ),
        _GlossaryTerm(
          name: 'Trend',
          simple:
              'How your imbalance changed compared with an earlier session.',
          detail:
              'A positive improvement means the recent session moved closer to equal activation; a negative result means it moved farther away.',
        ),
      ],
    ),
    _GlossarySection(
      title: 'Signal quality',
      terms: <_GlossaryTerm>[
        _GlossaryTerm(
          name: 'Calibration / Resting baseline',
          simple:
              'A short resting measurement used to estimate background signal before movement.',
          detail:
              'Stay relaxed and still while calibrating. SymSync subtracts this baseline power from later measurements.',
        ),
        _GlossaryTerm(
          name: 'Noise floor',
          simple:
              'The amount of unwanted signal measured while the muscle should be relaxed.',
          detail:
              'A high noise floor can come from loose electrodes, dry contact, cable movement, nearby electronics, or muscle tension.',
        ),
        _GlossaryTerm(
          name: 'Raw ADC',
          simple: 'The original digital samples received from the EMG device.',
          detail:
              'These values include the useful muscle signal as well as offsets, movement artifacts, and electrical noise.',
        ),
        _GlossaryTerm(
          name: 'Filtered signal',
          simple:
              'The raw signal after frequencies outside the intended EMG range are reduced.',
          detail:
              'Filtering makes the muscle-related waveform easier to analyze but does not make a poor sensor contact reliable.',
        ),
        _GlossaryTerm(
          name: 'RMS envelope',
          simple:
              'A smoothed measure of the EMG signal’s strength over a short time window.',
          detail:
              'SymSync uses this processed signal for its activity and symmetry calculations.',
        ),
      ],
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.88,
      minChildSize: 0.55,
      maxChildSize: 0.96,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: context.bgPrimary,
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(AppTheme.radiusXL),
            ),
            boxShadow: const <BoxShadow>[
              BoxShadow(
                color: Color(0x33000000),
                blurRadius: 24,
                offset: Offset(0, -8),
              ),
            ],
          ),
          child: Column(
            children: <Widget>[
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 10, 12, 8),
                child: Column(
                  children: <Widget>[
                    Container(
                      width: 42,
                      height: 4,
                      decoration: BoxDecoration(
                        color: context.dividerClr,
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: <Widget>[
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: AppTheme.accentTeal.withValues(alpha: 0.16),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: const Icon(
                            Icons.menu_book_rounded,
                            color: AppTheme.accentTeal,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Text(
                                'How to read SymSync',
                                style: AppTheme.headingLarge.copyWith(
                                  color: context.txtPrimary,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Plain-language definitions for your results',
                                style: AppTheme.bodySmall.copyWith(
                                  color: context.txtSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          tooltip: 'Close glossary',
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(Icons.close_rounded),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Divider(height: 1, color: context.dividerClr),
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
                  children: <Widget>[
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppTheme.accentAmber.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(AppTheme.radiusMD),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          const Icon(
                            Icons.info_outline_rounded,
                            color: AppTheme.accentAmber,
                            size: 18,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'SymSync supports research and movement feedback. Its results are not a medical diagnosis and should be interpreted alongside sensor placement and signal quality.',
                              style: AppTheme.bodySmall.copyWith(
                                color: context.txtSecondary,
                                height: 1.45,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    for (final section in _sections) ...<Widget>[
                      const SizedBox(height: 22),
                      Text(
                        section.title.toUpperCase(),
                        style: AppTheme.labelSmall.copyWith(
                          color: context.txtTertiary,
                          letterSpacing: 1.1,
                        ),
                      ),
                      const SizedBox(height: 8),
                      for (final term in section.terms)
                        _GlossaryTermTile(term: term),
                    ],
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _GlossaryTermTile extends StatelessWidget {
  const _GlossaryTermTile({required this.term});

  final _GlossaryTerm term;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      color: context.bgCard,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusMD),
        side: BorderSide(color: context.dividerClr),
      ),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
        childrenPadding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
        iconColor: AppTheme.accentTeal,
        collapsedIconColor: context.txtTertiary,
        title: Text(
          term.name,
          style: AppTheme.headingMedium.copyWith(
            color: context.txtPrimary,
            fontWeight: FontWeight.w800,
          ),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(
            term.simple,
            style: AppTheme.bodySmall.copyWith(
              color: context.txtSecondary,
              height: 1.4,
            ),
          ),
        ),
        children: <Widget>[
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              term.detail,
              style: AppTheme.bodySmall.copyWith(
                color: context.txtSecondary,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _GlossarySection {
  const _GlossarySection({required this.title, required this.terms});

  final String title;
  final List<_GlossaryTerm> terms;
}

class _GlossaryTerm {
  const _GlossaryTerm({
    required this.name,
    required this.simple,
    required this.detail,
  });

  final String name;
  final String simple;
  final String detail;
}
