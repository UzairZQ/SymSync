import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../domain/models/research_context.dart';
import '../presentation/bloc/session_bloc.dart';
import '../presentation/pages/session_page.dart';
import '../theme/app_theme.dart';
import '../widgets/app_card.dart';

enum CalibrationPhase { connecting, monitoring }

class CalibrationScreen extends StatefulWidget {
  const CalibrationScreen({super.key});

  @override
  State<CalibrationScreen> createState() => _CalibrationScreenState();
}

class _CalibrationScreenState extends State<CalibrationScreen> {
  CalibrationPhase _phase = CalibrationPhase.connecting;

  Timer? _connectionTimer;
  int _connectionElapsedSeconds = 0;

  Timer? _monitoringTimer;
  String _ch1Status = '—';
  String _ch3Status = '—';
  double _ch1NoiseRms = 0;
  double _ch3NoiseRms = 0;

  static const String _deviceMac = '00:07:80:8C:0A:27';

  @override
  void initState() {
    super.initState();
    _startConnecting();
  }

  @override
  void dispose() {
    _connectionTimer?.cancel();
    _monitoringTimer?.cancel();
    super.dispose();
  }

  void _startConnecting() {
    setState(() {
      _phase = CalibrationPhase.connecting;
      _connectionElapsedSeconds = 0;
    });

    final bloc = context.read<SessionBloc>();
    if (!bloc.state.isConnected) {
      bloc.connect(_deviceMac);
    }

    _connectionTimer?.cancel();
    _connectionTimer = Timer.periodic(const Duration(milliseconds: 500), (
      timer,
    ) {
      _connectionElapsedSeconds += 1;

      if (bloc.state.isConnected) {
        timer.cancel();
        _startMonitoring();
      } else if (_connectionElapsedSeconds >= 30) {
        timer.cancel();
        _connectionTimedOut();
      }
    });
  }

  void _connectionTimedOut() {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Could not reach biosignalsplux ($_deviceMac). Check power and range.',
        ),
      ),
    );
  }

  void _startMonitoring() {
    setState(() {
      _phase = CalibrationPhase.monitoring;
    });

    _monitoringTimer?.cancel();
    _monitoringTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _updateLiveStatus();
    });
  }

  void _updateLiveStatus() {
    final state = context.read<SessionBloc>().state;
    final raw1 = state.rawPoints;
    final raw3 = state.rawPoints3;

    final std1 = raw1.length >= 200 ? _calculateStdDev(raw1, 200) : 0.0;
    final std3 = raw3.length >= 200 ? _calculateStdDev(raw3, 200) : 0.0;

    final rms1 = raw1.length >= 200 ? _calculateCenteredRms(raw1, 200) : 0.0;
    final rms3 = raw3.length >= 200 ? _calculateCenteredRms(raw3, 200) : 0.0;

    setState(() {
      _ch1NoiseRms = rms1;
      _ch3NoiseRms = rms3;

      _ch1Status = std1 > 50
          ? (rms1 < 3000 ? 'Signal OK' : 'Noisy')
          : 'No signal';
      _ch3Status = std3 > 50
          ? (rms3 < 3000 ? 'Signal OK' : 'Noisy')
          : 'No signal';
    });
  }

  void _beginSession() {
    final bloc = context.read<SessionBloc>();
    final straightAhead = bloc.state.activeParticipant?.baselineFor(
      BaselineReferencePosition.straightAhead,
    );
    if (straightAhead == null) {
      bloc.calibrate();
    } else {
      bloc.saveCalibration(
        baselineLeft: straightAhead.leftRms,
        baselineRight: straightAhead.rightRms,
      );
    }

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const SessionScreen()),
    );
  }

  Future<void> _saveBaseline(BaselineReferencePosition position) async {
    try {
      await context.read<SessionBloc>().saveBaselineReference(position);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.toString())));
    }
  }

  double _calculateStdDev(List<int> samples, int count) {
    if (samples.length < count) return 0.0;
    final segment = samples.sublist(samples.length - count);
    final mean = segment.reduce((a, b) => a + b) / count;
    final sumSqDiff = segment
        .map((x) => (x - mean) * (x - mean))
        .reduce((a, b) => a + b);
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.bgPrimary,
      appBar: AppBar(
        backgroundColor: context.bgPrimary,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new_rounded,
            color: context.txtPrimary,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Device Setup',
          style: TextStyle(
            color: context.txtPrimary,
            fontWeight: FontWeight.bold,
          ),
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
                _phase == CalibrationPhase.connecting
                    ? 'Connecting to biosignalsplux…'
                    : 'Live signal monitoring — begin your session when ready',
                style: TextStyle(color: context.txtSecondary, fontSize: 14),
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
      case CalibrationPhase.monitoring:
        return _buildMonitoringWidget();
    }
  }

  Widget _buildConnectingWidget() {
    return AppCard(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.bluetooth_searching_rounded,
            size: 64,
            color: context.txtPrimary,
          ),
          const SizedBox(height: 16),
          Text(
            'Connecting to Device…',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: context.txtPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'biosignalsplux\nMAC: $_deviceMac',
            textAlign: TextAlign.center,
            style: TextStyle(color: context.txtTertiary),
          ),
          const SizedBox(height: 24),
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(context.txtPrimary),
          ),
        ],
      ),
    );
  }

  Widget _buildMonitoringWidget() {
    final state = context.watch<SessionBloc>().state;
    final channelAIsLeft = state.channelMapping['A'] == 'left';
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
        _buildBaselineProtocolCard(state),
        const SizedBox(height: 16),
        _buildChannelRow(
          channelLabel: 'CH1 — ${channelAIsLeft ? 'Left' : 'Right'} Trapezius',
          status: _ch1Status,
          noiseRms: _ch1NoiseRms,
          samples: ch1Samples,
          color: const Color(0xFF8BAEA3),
        ),
        const SizedBox(height: 16),
        _buildChannelRow(
          channelLabel: 'CH3 — ${channelAIsLeft ? 'Right' : 'Left'} Trapezius',
          status: _ch3Status,
          noiseRms: _ch3NoiseRms,
          samples: ch3Samples,
          color: const Color(0xFFC56D5D),
        ),
      ],
    );
  }

  Widget _buildBaselineProtocolCard(SessionState state) {
    final participant = state.activeParticipant;
    return AppCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(
                Icons.assignment_turned_in_outlined,
                color: context.txtPrimary,
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Baseline reference protocol',
                  style: TextStyle(
                    color: context.txtPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'For each posture, hold still for 10 seconds, then save the current left/right ADC RMS values.',
            style: TextStyle(color: context.txtSecondary, fontSize: 12.5),
          ),
          const SizedBox(height: 12),
          for (final position in BaselineReferencePosition.values) ...[
            _BaselineCaptureRow(
              position: position,
              reference: participant?.baselineFor(position),
              enabled: state.isConnected && participant != null,
              onSave: () => _saveBaseline(position),
            ),
            if (position != BaselineReferencePosition.values.last)
              const SizedBox(height: 8),
          ],
          if (participant == null) ...[
            const SizedBox(height: 10),
            Text(
              'Select or create a participant before saving baseline references.',
              style: TextStyle(color: AppTheme.accentAmber, fontSize: 12),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildChannelRow({
    required String channelLabel,
    required String status,
    required double noiseRms,
    required List<int> samples,
    required Color color,
  }) {
    Color badgeColor = Colors.grey;
    if (status == 'Signal OK') badgeColor = const Color(0xFF22C55E);
    if (status == 'Noisy') badgeColor = const Color(0xFFF59E0B);
    if (status == 'No signal') badgeColor = const Color(0xFFEF4444);

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
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                  color: context.txtPrimary,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: badgeColor.withValues(alpha: 0.12),
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
          const SizedBox(height: 4),
          Text(
            'Noise floor: ${noiseRms.toStringAsFixed(0)} ADC RMS',
            style: TextStyle(color: context.txtTertiary, fontSize: 12),
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

  Widget _buildBottomActions(BuildContext context) {
    if (_phase == CalibrationPhase.monitoring) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ElevatedButton(
            onPressed: _beginSession,
            style: ElevatedButton.styleFrom(
              backgroundColor: context.txtPrimary,
              foregroundColor: context.bgPrimary,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(999),
              ),
              elevation: 0,
            ),
            child: Text(
              'Begin Session',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: context.bgPrimary,
              ),
            ),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: _startConnecting,
            child: Text(
              'Reconnect',
              style: TextStyle(
                color: context.txtSecondary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      );
    }

    return OutlinedButton(
      onPressed: () => Navigator.pop(context),
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
        side: BorderSide(color: context.dividerClr),
        foregroundColor: context.txtSecondary,
      ),
      child: Text(
        'Cancel',
        style: TextStyle(
          color: context.txtSecondary,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _BaselineCaptureRow extends StatelessWidget {
  const _BaselineCaptureRow({
    required this.position,
    required this.reference,
    required this.enabled,
    required this.onSave,
  });

  final BaselineReferencePosition position;
  final BaselineReference? reference;
  final bool enabled;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    final value = reference == null
        ? 'Not saved'
        : 'L ${reference!.leftRms.toStringAsFixed(0)} / R ${reference!.rightRms.toStringAsFixed(0)} ADC RMS';
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: context.bgElevated,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: context.dividerClr),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  position.label,
                  style: TextStyle(
                    color: context.txtPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  position.instruction,
                  style: TextStyle(color: context.txtSecondary, fontSize: 11),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(
                    color: reference == null
                        ? context.txtTertiary
                        : AppTheme.accentTeal,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          FilledButton.tonal(
            onPressed: enabled ? onSave : null,
            style: FilledButton.styleFrom(
              minimumSize: const Size(74, 40),
              padding: const EdgeInsets.symmetric(horizontal: 12),
            ),
            child: const Text('Save'),
          ),
        ],
      ),
    );
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
      final y = (size.height / 2 - (diff / 2000.0) * (size.height / 2)).clamp(
        0.0,
        size.height,
      );
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
