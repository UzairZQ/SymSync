import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../presentation/bloc/session_bloc.dart';
import '../presentation/pages/session_page.dart'; // SessionPage or SessionScreen
import '../theme/app_theme.dart';
import '../widgets/app_card.dart';

enum CalibrationPhase {
  connecting,      // Waiting for BT connection to confirm both channels live
  checkingSignal,  // 5-second window: sampling noise floor + contact quality
  baselineCapture, // 3-second relaxed baseline RMS capture
  ready,           // Both channels passed — CTA to begin session unlocked
  failed,          // One or both channels failed — actionable error shown
}

class CalibrationScreen extends StatefulWidget {
  const CalibrationScreen({super.key});

  @override
  State<CalibrationScreen> createState() => _CalibrationScreenState();
}

class _CalibrationScreenState extends State<CalibrationScreen> {
  CalibrationPhase _phase = CalibrationPhase.connecting;
  
  // Connection phase variables
  Timer? _connectionTimer;
  int _connectionElapsedSeconds = 0;

  // Signal check phase variables
  Timer? _signalCheckTimer;
  int _signalCheckCountdown = 5;
  String _ch1Status = "Checking…";
  String _ch3Status = "Checking…";
  bool _ch1SignalPresent = false;
  bool _ch3SignalPresent = false;
  bool _ch1NoiseOk = false;
  bool _ch3NoiseOk = false;
  
  // Baseline capture variables
  Timer? _baselineTimer;
  int _baselineCountdown = 3;
  final List<double> _baselineSamplesLeft = [];
  final List<double> _baselineSamplesRight = [];
  double _finalBaselineLeft = 0.0;
  final List<int> _capturedRawLeft = [];
  final List<int> _capturedRawRight = [];
  double _finalBaselineRight = 0.0;

  String? _failedErrorMessage;

  static const String _deviceMac = '00:07:80:8C:0A:27';

  @override
  void initState() {
    super.initState();
    _startConnecting();
  }

  @override
  void dispose() {
    _connectionTimer?.cancel();
    _signalCheckTimer?.cancel();
    _baselineTimer?.cancel();
    super.dispose();
  }

  void _startConnecting() {
    setState(() {
      _phase = CalibrationPhase.connecting;
      _connectionElapsedSeconds = 0;
      _failedErrorMessage = null;
    });

    final bloc = context.read<SessionBloc>();
    if (!bloc.state.isConnected) {
      bloc.connect(_deviceMac);
    }

    _connectionTimer?.cancel();
    _connectionTimer = Timer.periodic(const Duration(milliseconds: 500), (timer) {
      _connectionElapsedSeconds += 1;
      
      if (bloc.state.isConnected) {
        timer.cancel();
        _startCheckingSignal();
      } else if (_connectionElapsedSeconds >= 30) { // 30 ticks of 500ms = 15 seconds
        timer.cancel();
        setState(() {
          _phase = CalibrationPhase.failed;
          _failedErrorMessage = "Could not reach biosignalsplux ($_deviceMac). Check that the device is powered on and within range.";
        });
      }
    });
  }

  void _startCheckingSignal() {
    setState(() {
      _phase = CalibrationPhase.checkingSignal;
      _signalCheckCountdown = 5;
      _ch1Status = "Checking…";
      _ch3Status = "Checking…";
    });

    _signalCheckTimer?.cancel();
    _signalCheckTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        if (_signalCheckCountdown > 1) {
          _signalCheckCountdown -= 1;
        } else {
          timer.cancel();
          _evaluateSignalQuality();
        }
      });
    });
  }

  void _evaluateSignalQuality() {
    final bloc = context.read<SessionBloc>();
    final rawPoints = bloc.state.rawPoints;
    final rawPoints3 = bloc.state.rawPoints3;

    // Evaluate CH1 (Left Trapezius)
    _ch1SignalPresent = _calculateStdDev(rawPoints, 200) > 50.0;
    _ch1NoiseOk = _calculateCenteredRms(rawPoints, 200) < 3000.0;

    // Evaluate CH2 (Right Trapezius)
    _ch3SignalPresent = _calculateStdDev(rawPoints3, 200) > 50.0;
    _ch3NoiseOk = _calculateCenteredRms(rawPoints3, 200) < 3000.0;

    setState(() {
      _ch1Status = !_ch1SignalPresent
          ? "No signal"
          : (!_ch1NoiseOk ? "Poor contact" : "Good");
      
      _ch3Status = !_ch3SignalPresent
          ? "No signal"
          : (!_ch3NoiseOk ? "Poor contact" : "Good");

      if (_ch1SignalPresent && _ch1NoiseOk && _ch3SignalPresent && _ch3NoiseOk) {
        _startBaselineCapture();
      } else {
        _phase = CalibrationPhase.failed;
      }
    });
  }

  void _startBaselineCapture() {
    setState(() {
      _phase = CalibrationPhase.baselineCapture;
      _baselineCountdown = 3;
      _baselineSamplesLeft.clear();
      _baselineSamplesRight.clear();
      _capturedRawLeft.clear();
      _capturedRawRight.clear();
    });

    // Record RMS level on each rebuild / timer tick
    _baselineTimer?.cancel();
    _baselineTimer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
      final state = context.read<SessionBloc>().state;
      _baselineSamplesLeft.add(state.leftTrapRms);
      _baselineSamplesRight.add(state.rightTrapRms);
      
      if (state.rawPoints.isNotEmpty) {
        _capturedRawLeft.add(state.rawPoints.last);
      }
      if (state.rawPoints3.isNotEmpty) {
        _capturedRawRight.add(state.rawPoints3.last);
      }

      if (_baselineSamplesLeft.length % 10 == 0) {
        setState(() {
          if (_baselineCountdown > 1) {
            _baselineCountdown -= 1;
          } else {
            timer.cancel();
            _completeCalibration();
          }
        });
      }
    });
  }

  void _completeCalibration() {
    // Record average of raw deviations from midpoint as baseline
    _finalBaselineLeft = _calculateCenteredRms(_capturedRawLeft, _capturedRawLeft.length);
    _finalBaselineRight = _calculateCenteredRms(_capturedRawRight, _capturedRawRight.length);

    // Save calibration baseline values in bloc
    context.read<SessionBloc>().saveCalibration(
      baselineLeft: _finalBaselineLeft,
      baselineRight: _finalBaselineRight,
    );

    setState(() {
      _phase = CalibrationPhase.ready;
    });
  }

  double _calculateStdDev(List<int> samples, int count) {
    if (samples.length < count) return 0.0;
    final segment = samples.sublist(samples.length - count);
    final mean = segment.reduce((a, b) => a + b) / count;
    final sumSqDiff = segment.map((x) => (x - mean) * (x - mean)).reduce((a, b) => a + b);
    return math.sqrt(sumSqDiff / count);
  }

  double _calculateCenteredRms(List<int> samples, int count) {
    if (samples.isEmpty) return 0.0;
    final actualCount = math.min(samples.length, count);
    final segment = samples.sublist(samples.length - actualCount);
    double sumSq = 0;
    for (final x in segment) {
      final diff = x - 32768;
      sumSq += diff * diff;
    }
    return math.sqrt(sumSq / actualCount);
  }

  double _adcToMicrovolts(double adcCentered) {
    // transfer function: µV = ((ADC / 65535) * 3.0 - 1.5) / 0.019 * 1000
    // for centered value (midpoint subtracted), V_offset is already removed:
    return ((adcCentered / 65535.0) * 3.0) / 0.019 * 1000.0;
  }

  @override
  Widget build(BuildContext context) {
    
    return Scaffold(
      backgroundColor: const Color(0xFFF2F6FB),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Device Setup",
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppTheme.spaceMD),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                "Checking both EMG channels before your session",
                style: TextStyle(color: Colors.grey[600], fontSize: 14),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppTheme.spaceLG),
              Expanded(
                child: Center(
                  child: SingleChildScrollView(
                    child: _buildPhaseContent(context),
                  ),
                ),
              ),
              const SizedBox(height: AppTheme.spaceLG),
              _buildBottomActions(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPhaseContent(BuildContext context) {
    switch (_phase) {
      case CalibrationPhase.connecting:
        return _buildConnectingWidget();
      case CalibrationPhase.checkingSignal:
        return _buildCheckingSignalWidget();
      case CalibrationPhase.baselineCapture:
        return _buildBaselineCaptureWidget();
      case CalibrationPhase.ready:
        return _buildReadyWidget();
      case CalibrationPhase.failed:
        return _buildFailedWidget();
    }
  }

  Widget _buildConnectingWidget() {
    return AppCard(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.bluetooth_searching_rounded,
            size: 64,
            color: Color(0xFF2563EB),
          ),
          const SizedBox(height: 16),
          const Text(
            "Connecting to Device...",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            "biosignalsplux\nMAC: $_deviceMac",
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 24),
          const CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF2563EB)),
          ),
        ],
      ),
    );
  }

  Widget _buildCheckingSignalWidget() {
    final state = context.watch<SessionBloc>().state;
    final ch1Samples = state.rawPoints.length >= 200
        ? state.rawPoints.sublist(state.rawPoints.length - 200)
        : state.rawPoints;
    final ch3Samples = state.rawPoints3.length >= 200
        ? state.rawPoints3.sublist(state.rawPoints3.length - 200)
        : state.rawPoints3;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppCard(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Text(
                "Checking Signal Quality",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey[800]),
              ),
              const SizedBox(height: 6),
              Text(
                "Analyzing noise floor and connection in $_signalCheckCountdown s",
                style: const TextStyle(color: Colors.grey, fontSize: 13),
              ),
              const SizedBox(height: 16),
              LinearProgressIndicator(
                value: (5 - _signalCheckCountdown) / 5.0,
                backgroundColor: Colors.grey[200],
                valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF2563EB)),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _buildChannelRow(
          channelLabel: "CH1 — Left Trapezius",
          status: _ch1Status,
          samples: ch1Samples,
          color: const Color(0xFFC56D5D),
        ),
        const SizedBox(height: 16),
        _buildChannelRow(
          channelLabel: "CH2 — Right Trapezius",
          status: _ch3Status,
          samples: ch3Samples,
          color: const Color(0xFF8BAEA3),
        ),
      ],
    );
  }

  Widget _buildChannelRow({
    required String channelLabel,
    required String status,
    required List<int> samples,
    required Color color,
  }) {
    Color badgeColor = Colors.grey;
    if (status == "Good") badgeColor = const Color(0xFF22C55E);
    if (status == "Poor contact") badgeColor = const Color(0xFFF59E0B);
    if (status == "No signal") badgeColor = const Color(0xFFEF4444);

    return AppCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                channelLabel,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: badgeColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  status,
                  style: TextStyle(
                    color: badgeColor,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 60,
            child: ClipRect(
              child: CustomPaint(
                painter: _SparklinePainter(samples: samples, color: color),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBaselineCaptureWidget() {
    final progress = (3 - _baselineCountdown) / 3.0;

    return AppCard(
      padding: const EdgeInsets.all(28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            "Capture Baseline",
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            "Relax your shoulders and stay still for 3 seconds.",
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 32),
          SizedBox(
            width: 120,
            height: 120,
            child: CustomPaint(
              painter: _CountdownPainter(progress: progress),
              child: Center(
                child: Text(
                  "$_baselineCountdown",
                  style: const TextStyle(fontSize: 36, fontWeight: FontWeight.w900),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReadyWidget() {
    final leftUv = _adcToMicrovolts(_finalBaselineLeft);
    final rightUv = _adcToMicrovolts(_finalBaselineRight);

    return AppCard(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.check_circle_rounded,
            size: 64,
            color: Color(0xFF22C55E),
          ),
          const SizedBox(height: 16),
          const Text(
            "Calibration Complete",
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            "Both Trapezius channels are calibrated and ready.",
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 24),
          const Divider(),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              Column(
                children: [
                  const Text(
                    "Left Trap ✓",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "Baseline: ${leftUv.toStringAsFixed(1)} µV",
                    style: const TextStyle(color: Colors.grey, fontSize: 13),
                  ),
                ],
              ),
              Container(width: 1, height: 40, color: Colors.grey[300]),
              Column(
                children: [
                  const Text(
                    "Right Trap ✓",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "Baseline: ${rightUv.toStringAsFixed(1)} µV",
                    style: const TextStyle(color: Colors.grey, fontSize: 13),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFailedWidget() {
    final hasCh1Error = !_ch1SignalPresent || !_ch1NoiseOk;
    final hasCh3Error = !_ch3SignalPresent || !_ch3NoiseOk;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AppCard(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const Icon(
                Icons.warning_rounded,
                size: 64,
                color: Color(0xFFEF4444),
              ),
              const SizedBox(height: 16),
              const Text(
                "Calibration Failed",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              if (_failedErrorMessage != null)
                Text(
                  _failedErrorMessage!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.grey),
                )
              else ...[
                if (hasCh1Error) ...[
                  Text(
                    "CH1 — Left Trapezius: " +
                    (!_ch1SignalPresent
                        ? "No signal detected. Check electrode contact and cable connection."
                        : "Signal too noisy. Ensure the cable is not loose and the participant is at rest."),
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(height: 12),
                ],
                if (hasCh3Error) ...[
                  Text(
                    "CH2 — Right Trapezius: " +
                    (!_ch3SignalPresent
                        ? "No signal detected. Check electrode contact and cable connection."
                        : "Signal too noisy. Ensure the cable is not loose and the participant is at rest."),
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.grey),
                  ),
                ],
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBottomActions(BuildContext context) {
    if (_phase == CalibrationPhase.ready) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ElevatedButton(
            onPressed: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const SessionScreen()),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2563EB),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            child: const Text("Begin Session", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: _startCheckingSignal,
            child: const Text("Recalibrate", style: TextStyle(color: Color(0xFF2563EB))),
          ),
        ],
      );
    }

    if (_phase == CalibrationPhase.failed) {
      return Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: () {
                Navigator.pop(context);
              },
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: const Text("Cancel"),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: ElevatedButton(
              onPressed: _startConnecting,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2563EB),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: const Text("Try Again"),
            ),
          ),
        ],
      );
    }

    // Otherwise, show disabled or loading status actions
    return OutlinedButton(
      onPressed: () {
        Navigator.pop(context);
      },
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      child: const Text("Cancel"),
    );
  }
}

class _CountdownPainter extends CustomPainter {
  final double progress; // 0.0 to 1.0

  _CountdownPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 8;
    final paintBg = Paint()
      ..color = Colors.grey[300]!
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8.0;

    final paintFg = Paint()
      ..color = const Color(0xFF2563EB)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8.0
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, paintBg);
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      2 * math.pi * progress,
      false,
      paintFg,
    );
  }

  @override
  bool shouldRepaint(covariant _CountdownPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}

class _SparklinePainter extends CustomPainter {
  final List<int> samples;
  final Color color;

  _SparklinePainter({required this.samples, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    if (samples.isEmpty) return;

    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    final path = Path();
    final stepX = size.width / 200.0;
    
    for (int i = 0; i < samples.length; i++) {
      final sample = samples[i];
      final x = i * stepX;
      final diff = sample - 32768;
      final y = (size.height / 2 - (diff / 2000.0) * (size.height / 2))
          .clamp(0.0, size.height);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _SparklinePainter oldDelegate) {
    return oldDelegate.samples != samples;
  }
}
