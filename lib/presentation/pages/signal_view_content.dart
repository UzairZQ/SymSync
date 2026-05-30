import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../data/emg/emg_hardware.dart';
import '../../domain/models/emg_frame.dart';
import '../../theme/app_theme.dart';
import '../../widgets/emg_chart.dart';

class SignalViewContent extends StatefulWidget {
  const SignalViewContent({super.key});

  @override
  State<SignalViewContent> createState() => _SignalViewContentState();
}

class _SignalViewContentState extends State<SignalViewContent> {
  final List<({DateTime time, double value})> _recentCh1 = [];
  final List<({DateTime time, double value})> _recentCh3 = [];
  StreamSubscription<EmgFrame>? _subscription;

  bool _ch1Active = false;
  bool _ch3Active = false;

  final ValueNotifier<String> _modeNotifier = ValueNotifier<String>('RMS Envelope');

  @override
  void initState() {
    super.initState();
    final hardware = context.read<EmgHardware>();
    _subscription = hardware.frames.listen((frame) {
      final now = DateTime.now();

      _recentCh1.add((time: now, value: frame.ch1.toDouble()));
      _recentCh1.removeWhere((item) => now.difference(item.time).inSeconds > 2);

      _recentCh3.add((time: now, value: frame.ch3.toDouble()));
      _recentCh3.removeWhere((item) => now.difference(item.time).inSeconds > 2);

      bool ch1Active = false;
      if (_recentCh1.isNotEmpty) {
        double minV = 999999;
        double maxV = -999999;
        for (final item in _recentCh1) {
          if (item.value < minV) minV = item.value;
          if (item.value > maxV) maxV = item.value;
        }
        ch1Active = (maxV - minV) > 50;
      }

      bool ch3Active = false;
      if (_recentCh3.isNotEmpty) {
        double minV = 999999;
        double maxV = -999999;
        for (final item in _recentCh3) {
          if (item.value < minV) minV = item.value;
          if (item.value > maxV) maxV = item.value;
        }
        ch3Active = (maxV - minV) > 50;
      }

      if (mounted && (ch1Active != _ch1Active || ch3Active != _ch3Active)) {
        setState(() {
          _ch1Active = ch1Active;
          _ch3Active = ch3Active;
        });
      }
    });
  }

  @override
  void dispose() {
    _subscription?.cancel();
    _modeNotifier.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String>(
      valueListenable: _modeNotifier,
      builder: (context, mode, child) {
        int activeCount = 0;
        if (_ch1Active) activeCount++;
        if (_ch3Active) activeCount++;

        Widget chartsArea;
        if (activeCount == 2) {
          chartsArea = Column(
            children: [
              Expanded(
                child: EMGChart(
                  key: const ValueKey('ch1_dual'),
                  frameStream: context.read<EmgHardware>().frames,
                  channelIndex: 0,
                  lineColor: AppTheme.leftLeg,
                  channelLabel: 'LEFT LEG — CH1',
                  mode: mode,
                ),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: EMGChart(
                  key: const ValueKey('ch3_dual'),
                  frameStream: context.read<EmgHardware>().frames,
                  channelIndex: 1,
                  lineColor: AppTheme.rightLeg,
                  channelLabel: 'RIGHT LEG — CH3',
                  mode: mode,
                ),
              ),
            ],
          );
        } else {
          final bool showCh3 = _ch3Active && !_ch1Active;
          chartsArea = Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: EMGChart(
                  key: ValueKey(showCh3 ? 'ch3_single' : 'ch1_single'),
                  frameStream: context.read<EmgHardware>().frames,
                  channelIndex: showCh3 ? 1 : 0,
                  lineColor: showCh3 ? AppTheme.rightLeg : AppTheme.leftLeg,
                  channelLabel: showCh3 ? 'RIGHT LEG — CH3' : 'LEFT LEG — CH1',
                  mode: mode,
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(AppTheme.spaceMD),
                decoration: BoxDecoration(
                  color: AppTheme.accentAmber.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(AppTheme.radiusMD),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.sensors_outlined,
                      color: AppTheme.accentAmber,
                      size: 20,
                    ),
                    const SizedBox(width: AppTheme.spaceSM),
                    Expanded(
                      child: Text(
                        'Single channel mode — Connect both legs for bilateral symmetry tracking',
                        style: AppTheme.bodyMedium.copyWith(
                          color: AppTheme.accentAmber,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Signal Monitor',
                        style: AppTheme.headingLarge.copyWith(
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      const SizedBox(height: AppTheme.spaceXS),
                      Text(
                        'Live EMG waveform visualizer',
                        style: AppTheme.bodyLarge.copyWith(
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: AppTheme.accentAmber, width: 1.2),
                  ),
                  child: Text(
                    'RESEARCHER',
                    style: AppTheme.labelSmall.copyWith(
                      color: AppTheme.accentAmber,
                      fontSize: 9,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.0,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppTheme.spaceLG),
            Expanded(
              child: chartsArea,
            ),
            const SizedBox(height: AppTheme.spaceMD),
            Container(
              height: 40,
              decoration: BoxDecoration(
                color: context.bgElevated,
                borderRadius: BorderRadius.circular(20),
              ),
              padding: const EdgeInsets.all(3),
              child: Row(
                children: ['Raw ADC', 'Filtered', 'RMS Envelope'].map((option) {
                  final isSelected = mode == option;
                  return Expanded(
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () {
                        _modeNotifier.value = option;
                      },
                      child: Container(
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: isSelected ? context.bgCard : Colors.transparent,
                          borderRadius: BorderRadius.circular(17),
                        ),
                        child: Text(
                          option,
                          style: GoogleFonts.dmSans(
                            fontSize: 12,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            color: isSelected ? AppTheme.accentTeal : context.txtTertiary,
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        );
      },
    );
  }
}
