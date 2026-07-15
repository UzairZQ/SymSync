import 'dart:async';
import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../domain/models/emg_frame.dart';
import '../domain/services/signal_processor.dart';
import '../theme/app_theme.dart';
import '../widgets/app_card.dart';

class EMGChart extends StatefulWidget {
  const EMGChart({
    super.key,
    required this.frameStream,
    required this.channelIndex, // 0 = Left, 1 = Right
    required this.lineColor,
    required this.channelLabel,
    required this.mode, // 'Raw ADC', 'Filtered', 'RMS Envelope'
  });

  final Stream<EmgFrame> frameStream;
  final int channelIndex;
  final Color lineColor;
  final String channelLabel;
  final String mode;

  @override
  State<EMGChart> createState() => _EMGChartState();
}

class _EMGChartState extends State<EMGChart>
    with SingleTickerProviderStateMixin {
  final List<double> _buffer = [];
  final SignalFilterState _filterState = SignalFilterState();
  StreamSubscription<EmgFrame>? _subscription;
  Timer? _timer;

  // Stats
  double _currentRms = 0.0;
  double _peakValue = 0.0;

  // Active status (2 seconds time window)
  final List<({DateTime time, double value})> _recentRawValues = [];
  bool _wasActive = false;
  bool _isLost = false;

  late final AnimationController _fadeController;
  late final Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    );

    _resetChart();
    _startListening();

    // Redraw at ~30 FPS (33ms) instead of 1000Hz to avoid jank
    _timer = Timer.periodic(const Duration(milliseconds: 33), (_) {
      if (mounted) {
        setState(() {});
      }
    });
  }

  void _resetChart() {
    _filterState.reset();
    _buffer.clear();
    double defaultValue = 32768.0;
    if (widget.mode == 'Filtered' || widget.mode == 'RMS Envelope') {
      defaultValue = 0.0;
    }
    _buffer.addAll(List<double>.filled(3000, defaultValue));
    _recentRawValues.clear();
    _wasActive = false;
    _isLost = false;
    unawaited(_fadeController.reverse());
    _currentRms = 0.0;
    _peakValue = defaultValue;
  }

  @override
  void didUpdateWidget(covariant EMGChart oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.mode != widget.mode) {
      _resetChart();
    }
  }

  void _startListening() {
    unawaited(_subscription?.cancel());
    _subscription = widget.frameStream.listen((frame) {
      final double raw = widget.channelIndex == 0
          ? frame.ch1.toDouble()
          : frame.ch3.toDouble();

      final now = DateTime.now();
      _recentRawValues.add((time: now, value: raw));
      _recentRawValues.removeWhere(
        (item) => now.difference(item.time).inSeconds > 2,
      );

      // Channel is active if variance in the last 2 seconds > 50 ADC units
      bool active = false;
      if (_recentRawValues.isNotEmpty) {
        double minVal = 999999;
        double maxVal = -999999;
        for (final item in _recentRawValues) {
          if (item.value < minVal) minVal = item.value;
          if (item.value > maxVal) maxVal = item.value;
        }
        active = (maxVal - minVal) > 50;
      }

      if (active) {
        if (!_wasActive) {
          _wasActive = true;
        }
        if (_isLost) {
          _isLost = false;
          unawaited(_fadeController.reverse());
        }
      } else {
        if (_wasActive && !_isLost) {
          _isLost = true;
          unawaited(_fadeController.forward());
        }
      }

      if (_isLost) {
        // Freeze last 3.0 seconds (do not append new samples to the buffer)
        return;
      }

      // Process raw data
      double value = raw;
      final double filtered = _filterState.filter(raw);
      final double rms = _filterState.processRms(filtered);

      if (widget.mode == 'Filtered') {
        value = filtered;
      } else if (widget.mode == 'RMS Envelope') {
        value = rms;
      }

      // Update current RMS and Peak values
      _currentRms = rms;
      if (widget.mode == 'Raw ADC') {
        if (value > _peakValue || _peakValue == 32768.0) {
          _peakValue = value;
        }
      } else if (widget.mode == 'Filtered') {
        if (value.abs() > _peakValue.abs()) {
          _peakValue = value;
        }
      } else {
        if (value > _peakValue) {
          _peakValue = value;
        }
      }

      _buffer.add(value);
      if (_buffer.length > 3000) {
        _buffer.removeAt(0);
      }
    });
  }

  @override
  void dispose() {
    unawaited(_subscription?.cancel());
    _timer?.cancel();
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    double minY = 0.0;
    double maxY = 65535.0;
    double horizontalInterval = 10000.0;

    if (widget.mode == 'Filtered') {
      final maxMagnitude = _buffer.fold<double>(
        0,
        (current, value) => math.max(current, value.abs()),
      );
      maxY = math.max(500, maxMagnitude * 1.1);
      minY = -maxY;
      horizontalInterval = maxY / 3;
    } else if (widget.mode == 'RMS Envelope') {
      minY = 0.0;
      maxY = math.max(100, _peakValue * 1.15);
      horizontalInterval = maxY / 4;
    }

    final spots = List<FlSpot>.generate(
      _buffer.length,
      (index) => FlSpot(index.toDouble(), _buffer[index]),
    );

    return AppCard(
      padding: EdgeInsets.zero,
      child: ClipRRect(
        borderRadius: AppTheme.cardRadius,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppTheme.spaceMD,
                AppTheme.spaceSM,
                AppTheme.spaceMD,
                AppTheme.spaceSM,
              ),
              child: Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: widget.lineColor,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: widget.lineColor.withValues(alpha: 0.4),
                          blurRadius: 6,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: AppTheme.spaceSM),
                  Text(
                    widget.channelLabel,
                    style: AppTheme.bodyMedium.copyWith(
                      color: context.txtPrimary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    'RMS: ${_currentRms.toStringAsFixed(3)}',
                    style: AppTheme.monoSmall.copyWith(
                      color: AppTheme.accentTeal,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: AppTheme.spaceMD),
                  Text(
                    'PEAK: ${widget.mode == 'RMS Envelope' ? _peakValue.toStringAsFixed(2) : _peakValue.toStringAsFixed(0)}',
                    style: AppTheme.monoSmall.copyWith(
                      color: context.txtSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Stack(
                children: [
                  Container(
                    color: context.bgCard,
                    padding: const EdgeInsets.fromLTRB(8, 12, 16, 8),
                    child: LineChart(
                      LineChartData(
                        minX: 0,
                        maxX: 2999,
                        minY: minY,
                        maxY: maxY,
                        borderData: FlBorderData(show: false),
                        gridData: FlGridData(
                          show: true,
                          drawVerticalLine: false,
                          horizontalInterval: horizontalInterval,
                          getDrawingHorizontalLine: (value) => FlLine(
                            color: context.dividerClr,
                            strokeWidth: 0.5,
                          ),
                        ),
                        titlesData: FlTitlesData(
                          show: true,
                          rightTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                          topTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                          leftTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              reservedSize: 42,
                              getTitlesWidget: (value, meta) {
                                final tolerance = (maxY - minY) * 0.05;
                                final diffMin = (value - minY).abs();
                                final diffMax = (value - maxY).abs();
                                final diffMid = (value - (minY + maxY) / 2)
                                    .abs();

                                if (diffMin < tolerance ||
                                    diffMax < tolerance ||
                                    diffMid < tolerance) {
                                  String label = '';
                                  if (widget.mode == 'Raw ADC') {
                                    if (diffMin < tolerance) {
                                      label = '0';
                                    } else if (diffMid < tolerance) {
                                      label = '32k';
                                    } else if (diffMax < tolerance) {
                                      label = '65k';
                                    }
                                  } else if (widget.mode == 'Filtered') {
                                    if (diffMin < tolerance) {
                                      label = minY.toStringAsFixed(0);
                                    } else if (diffMid < tolerance) {
                                      label = ((minY + maxY) / 2)
                                          .toStringAsFixed(0);
                                    } else if (diffMax < tolerance) {
                                      label = maxY.toStringAsFixed(0);
                                    }
                                  } else {
                                    if (diffMin < tolerance) {
                                      label = minY.toStringAsFixed(0);
                                    } else if (diffMid < tolerance) {
                                      label = ((minY + maxY) / 2)
                                          .toStringAsFixed(0);
                                    } else if (diffMax < tolerance) {
                                      label = maxY.toStringAsFixed(0);
                                    }
                                  }
                                  return Padding(
                                    padding: const EdgeInsets.only(right: 6.0),
                                    child: Text(
                                      label,
                                      style: AppTheme.monoSmall.copyWith(
                                        color: context.txtTertiary,
                                        fontSize: 10,
                                      ),
                                      textAlign: TextAlign.end,
                                    ),
                                  );
                                }
                                return const SizedBox.shrink();
                              },
                            ),
                          ),
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              reservedSize: 18,
                              getTitlesWidget: (value, meta) {
                                String label = '';
                                if (value == 0) {
                                  label = '-3s';
                                } else if ((value - 1000).abs() < 10) {
                                  label = '-2s';
                                } else if ((value - 2000).abs() < 10) {
                                  label = '-1s';
                                } else if ((value - 2999).abs() < 10) {
                                  label = 'Now';
                                }

                                if (label.isEmpty) {
                                  return const SizedBox.shrink();
                                }
                                return Text(
                                  label,
                                  style: AppTheme.monoSmall.copyWith(
                                    color: context.txtTertiary,
                                    fontSize: 10,
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                        lineBarsData: [
                          LineChartBarData(
                            spots: spots,
                            isCurved: false,
                            color: widget.lineColor,
                            barWidth: 1.5,
                            dotData: const FlDotData(show: false),
                            belowBarData: BarAreaData(
                              show: true,
                              color: widget.lineColor.withValues(alpha: 0.08),
                            ),
                          ),
                        ],
                        clipData: const FlClipData.all(),
                      ),
                    ),
                  ),
                  Positioned.fill(
                    child: FadeTransition(
                      opacity: _fadeAnimation,
                      child: Container(
                        color: AppTheme.accentAmber.withValues(alpha: 0.85),
                        padding: const EdgeInsets.all(AppTheme.spaceMD),
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.warning_amber_rounded,
                                color: AppTheme.backgroundPrimary,
                                size: 28,
                              ),
                              const SizedBox(height: AppTheme.spaceSM),
                              Text(
                                'Signal lost — check electrode contact',
                                style: AppTheme.headingMedium.copyWith(
                                  color: AppTheme.backgroundPrimary,
                                  fontWeight: FontWeight.w800,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
