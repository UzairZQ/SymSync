import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';

import '../../theme/app_theme.dart';
import '../../widgets/sensor_placement_guide.dart';
import '../bloc/session_bloc.dart';

class OnboardingPage extends StatefulWidget {
  final VoidCallback onComplete;

  const OnboardingPage({super.key, required this.onComplete});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage>
    with TickerProviderStateMixin {
  final PageController _pageCtrl = PageController();
  int _currentPage = 0;
  String? _selectedUserType = 'athlete';
  String _channelA = 'left';
  String _channelB = 'right';

  late final AnimationController _entryCtrl;

  @override
  void initState() {
    super.initState();
    _entryCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    )..forward();
  }

  @override
  void dispose() {
    _pageCtrl.dispose();
    _entryCtrl.dispose();
    super.dispose();
  }

  void _nextPage() {
    if (_currentPage < 6) {
      _pageCtrl.nextPage(
        duration: const Duration(milliseconds: 380),
        curve: Curves.easeOutCubic,
      );
    }
  }

  void _skipToLast() {
    _pageCtrl.animateToPage(
      6,
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeOutCubic,
    );
  }

  Future<void> _complete() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_complete', true);
    await prefs.setString('channel_mapping.A', _channelA);
    await prefs.setString('channel_mapping.B', _channelB);
    if (_selectedUserType != null) {
      await prefs.setString('user_type', _selectedUserType!);
    }
    if (!mounted) return;
    await context.read<SessionBloc>().setChannelMapping(_channelA, _channelB);
    widget.onComplete();
  }

  bool get _canProceedSlide4 => true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.lightBackgroundPrimary,
      body: SafeArea(
        child: Column(
          children: <Widget>[
            // Top bar
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppTheme.spaceLG,
                AppTheme.spaceMD,
                AppTheme.spaceLG,
                0,
              ),
              child: Row(
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color: AppTheme.lightTextPrimary,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          'S',
                          style: GoogleFonts.inter(
                            color: AppTheme.lightBackgroundPrimary,
                            fontWeight: FontWeight.w800,
                            fontSize: 14,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        'SymSync',
                        style: GoogleFonts.inter(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.lightTextPrimary,
                          letterSpacing: -0.2,
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  if (_currentPage < 6)
                    TextButton(
                      onPressed: _skipToLast,
                      style: TextButton.styleFrom(
                        foregroundColor: AppTheme.lightTextTertiary,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                      ),
                      child: Text(
                        'Skip',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.lightTextTertiary,
                        ),
                      ),
                    ),
                ],
              ),
            ),

            // Page content
            Expanded(
              child: PageView(
                controller: _pageCtrl,
                physics: const NeverScrollableScrollPhysics(),
                onPageChanged: (i) {
                  setState(() => _currentPage = i);
                  _entryCtrl.reset();
                  _entryCtrl.forward();
                },
                children: <Widget>[
                  _SlideImage(
                    key: const ValueKey<String>('welcome'),
                    asset: 'assets/images/onboarding/welcome.png',
                    title: 'Welcome to SymSync',
                    body:
                        'Your personal muscle symmetry coach.\nWe measure, you move, we guide.',
                    entry: _entryCtrl,
                  ),
                  _SlideImage(
                    key: const ValueKey<String>('emg'),
                    asset: 'assets/images/onboarding/emg.png',
                    title: 'EMG Made Simple',
                    body:
                        'Connect your biosignalsplux device over\nBluetooth. SymSync reads both EMG\nchannels and shows you which side of\nyour upper back is working harder.',
                    entry: _entryCtrl,
                    illustration: const _BluetoothConnectionIllustration(),
                  ),
                  _SlideElectrodePlacement(
                    key: const ValueKey<String>('placement'),
                    entry: _entryCtrl,
                  ),
                  _SlideImage(
                    key: const ValueKey<String>('stairs'),
                    asset: 'assets/images/onboarding/stairs.png',
                    title: 'Feel the Difference',
                    body:
                        'As you climb stairs, SymSync reads both sides of your upper back and shows you which trapezius is working harder — so you can move with better balance every day.',
                    entry: _entryCtrl,
                  ),
                  _SlideUserType(
                    key: const ValueKey<String>('usertype'),
                    selected: _selectedUserType,
                    onSelect: (t) => setState(() => _selectedUserType = t),
                    entry: _entryCtrl,
                  ),
                  _SlideChannelCalibration(
                    key: const ValueKey<String>('channels'),
                    entry: _entryCtrl,
                    channelA: _channelA,
                    channelB: _channelB,
                    onChannelAChanged: (v) => setState(() => _channelA = v),
                    onChannelBChanged: (v) => setState(() => _channelB = v),
                  ),
                  _SlideReady(
                    key: const ValueKey<String>('ready'),
                    entry: _entryCtrl,
                  ),
                ],
              ),
            ),

            // Bottom controls
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppTheme.spaceLG,
                AppTheme.spaceMD,
                AppTheme.spaceLG,
                AppTheme.spaceLG,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  SmoothPageIndicator(
                    controller: _pageCtrl,
                    count: 7,
                    effect: ExpandingDotsEffect(
                      dotHeight: 7,
                      dotWidth: 7,
                      dotColor: AppTheme.lightDivider,
                      activeDotColor: AppTheme.lightTextPrimary,
                      spacing: 8,
                      expansionFactor: 3,
                    ),
                  ),
                  const SizedBox(height: AppTheme.spaceLG),
                  if (_currentPage == 6)
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: FilledButton(
                        onPressed: _complete,
                        style: FilledButton.styleFrom(
                          backgroundColor: AppTheme.lightTextPrimary,
                          foregroundColor: AppTheme.lightBackgroundPrimary,
                          disabledBackgroundColor:
                              AppTheme.lightBackgroundElevated,
                          disabledForegroundColor: AppTheme.lightTextTertiary,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(
                              AppTheme.radiusMD,
                            ),
                          ),
                        ),
                        child: Text(
                          'Get Started',
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.2,
                          ),
                        ),
                      ),
                    )
                  else
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: FilledButton(
                        onPressed: _canProceedSlide4 ? _nextPage : null,
                        style: FilledButton.styleFrom(
                          backgroundColor: AppTheme.lightTextPrimary,
                          foregroundColor: AppTheme.lightBackgroundPrimary,
                          disabledBackgroundColor:
                              AppTheme.lightBackgroundElevated,
                          disabledForegroundColor: AppTheme.lightTextTertiary,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(
                              AppTheme.radiusMD,
                            ),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: <Widget>[
                            Text(
                              'Continue',
                              style: GoogleFonts.inter(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.2,
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Icon(Icons.arrow_forward_rounded, size: 18),
                          ],
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

// ─── Slide with image, title and body ─────────────────────────────────────
class _SlideImage extends StatelessWidget {
  final String asset;
  final String title;
  final String body;
  final AnimationController entry;
  final Widget? illustration;

  const _SlideImage({
    super.key,
    required this.asset,
    required this.title,
    required this.body,
    required this.entry,
    this.illustration,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppTheme.spaceLG),
      child: Column(
        children: <Widget>[
          const SizedBox(height: AppTheme.spaceLG),
          Expanded(
            flex: 6,
            child: FadeTransition(
              opacity: CurvedAnimation(parent: entry, curve: Curves.easeOut),
              child: SlideTransition(
                position:
                    Tween<Offset>(
                      begin: const Offset(0, 0.06),
                      end: Offset.zero,
                    ).animate(
                      CurvedAnimation(
                        parent: entry,
                        curve: Curves.easeOutCubic,
                      ),
                    ),
                child: Container(
                  decoration: BoxDecoration(
                    color: AppTheme.lightBackgroundCard,
                    borderRadius: AppTheme.cardRadius,
                    border: Border.all(color: AppTheme.lightDivider),
                    boxShadow: AppTheme.lightCardShadow,
                  ),
                  padding: const EdgeInsets.all(AppTheme.spaceLG),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(AppTheme.radiusLG),
                    child:
                        illustration ??
                        Image.asset(
                          asset,
                          fit: BoxFit.contain,
                          filterQuality: FilterQuality.medium,
                          errorBuilder: (context, error, stack) => Center(
                            child: Icon(
                              Icons.image_outlined,
                              size: 48,
                              color: AppTheme.lightTextTertiary,
                            ),
                          ),
                        ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: AppTheme.spaceXL),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 250),
            child: Text(
              title,
              key: ValueKey<String>(title),
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 26,
                fontWeight: FontWeight.w800,
                color: AppTheme.lightTextPrimary,
                height: 1.2,
                letterSpacing: -0.6,
              ),
            ),
          ),
          const SizedBox(height: AppTheme.spaceSM),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 250),
            child: Text(
              body,
              key: ValueKey<String>(body),
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 15,
                fontWeight: FontWeight.w400,
                color: AppTheme.lightTextSecondary,
                height: 1.55,
              ),
            ),
          ),
          const Spacer(flex: 1),
        ],
      ),
    );
  }
}

class _SlideElectrodePlacement extends StatelessWidget {
  const _SlideElectrodePlacement({super.key, required this.entry});

  final AnimationController entry;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppTheme.spaceLG),
      child: Column(
        children: <Widget>[
          const SizedBox(height: AppTheme.spaceLG),
          Expanded(
            flex: 7,
            child: FadeTransition(
              opacity: entry,
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFF0F4F8),
                  borderRadius: AppTheme.cardRadius,
                  border: Border.all(color: AppTheme.lightDivider),
                  boxShadow: AppTheme.lightCardShadow,
                ),
                padding: const EdgeInsets.all(12),
                child: const SensorPlacementDiagram(),
              ),
            ),
          ),
          const SizedBox(height: AppTheme.spaceLG),
          Text(
            'Place Both Sensors',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 25,
              fontWeight: FontWeight.w800,
              color: AppTheme.lightTextPrimary,
              height: 1.2,
              letterSpacing: -0.6,
            ),
          ),
          const SizedBox(height: AppTheme.spaceSM),
          Text(
            'Use matching positions on the left and right upper trapezius. Clean and dry the skin, align the sensor with the muscle, and avoid bone or irritated skin.',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 13,
              color: AppTheme.lightTextSecondary,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Follow the sensor manufacturer’s instructions for electrode spacing and cable fixation.',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 10,
              color: AppTheme.lightTextTertiary,
              height: 1.35,
            ),
          ),
          const Spacer(flex: 1),
        ],
      ),
    );
  }
}

// ─── Slide 5: Ready ───────────────────────────────────────────────────────
class _SlideReady extends StatelessWidget {
  final AnimationController entry;

  const _SlideReady({super.key, required this.entry});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppTheme.spaceLG),
      child: Column(
        children: <Widget>[
          const SizedBox(height: AppTheme.spaceLG),
          Expanded(
            flex: 5,
            child: FadeTransition(
              opacity: entry,
              child: SlideTransition(
                position:
                    Tween<Offset>(
                      begin: const Offset(0, 0.06),
                      end: Offset.zero,
                    ).animate(
                      CurvedAnimation(
                        parent: entry,
                        curve: Curves.easeOutCubic,
                      ),
                    ),
                child: Container(
                  decoration: BoxDecoration(
                    color: AppTheme.lightBackgroundCard,
                    borderRadius: AppTheme.cardRadius,
                    border: Border.all(color: AppTheme.lightDivider),
                    boxShadow: AppTheme.lightCardShadow,
                  ),
                  padding: const EdgeInsets.all(AppTheme.spaceLG),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(AppTheme.radiusLG),
                    child: Image.asset(
                      'assets/images/onboarding/ready.png',
                      fit: BoxFit.contain,
                      filterQuality: FilterQuality.medium,
                      errorBuilder: (context, error, stack) => Center(
                        child: Icon(
                          Icons.check_circle_outline_rounded,
                          size: 80,
                          color: AppTheme.accentTeal,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: AppTheme.spaceXL),
          Text(
            "You're all set",
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 26,
              fontWeight: FontWeight.w800,
              color: AppTheme.lightTextPrimary,
              height: 1.2,
              letterSpacing: -0.6,
            ),
          ),
          const SizedBox(height: AppTheme.spaceSM),
          Text(
            'SymSync is ready to measure your upper\nback symmetry during stair climbing.',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 15,
              fontWeight: FontWeight.w400,
              color: AppTheme.lightTextSecondary,
              height: 1.55,
            ),
          ),
          const Spacer(flex: 1),
        ],
      ),
    );
  }
}

class _BluetoothConnectionIllustration extends StatelessWidget {
  const _BluetoothConnectionIllustration();

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: <Widget>[
        CustomPaint(painter: _BluetoothConnectionPainter()),
        const Align(
          alignment: Alignment(-0.55, -0.1),
          child: Icon(Icons.bluetooth, color: Color(0xFF2563EB), size: 32),
        ),
      ],
    );
  }
}

class _BluetoothConnectionPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final stroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round
      ..color = const Color(0xFF2563EB);
    final fill = Paint()..color = const Color(0xFFF8FAFC);
    final outline = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..color = const Color(0xFFCBD5E1);

    final phoneRect = Rect.fromCenter(
      center: Offset(size.width * 0.30, size.height * 0.50),
      width: size.width * 0.23,
      height: size.height * 0.58,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(phoneRect, const Radius.circular(18)),
      fill,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(phoneRect.deflate(2), const Radius.circular(16)),
      outline,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(phoneRect.deflate(15), const Radius.circular(10)),
      Paint()..color = Colors.white,
    );

    for (var i = 0; i < 3; i++) {
      final rect = Rect.fromCenter(
        center: Offset(size.width * 0.49, size.height * 0.50),
        width: size.width * (0.18 + i * 0.12),
        height: size.height * (0.28 + i * 0.18),
      );
      canvas.drawArc(
        rect,
        -math.pi / 3,
        math.pi * 2 / 3,
        false,
        stroke
          ..color = const Color(0xFF2563EB).withValues(alpha: 0.55 - i * 0.14),
      );
    }

    final sensorRect = Rect.fromCenter(
      center: Offset(size.width * 0.72, size.height * 0.50),
      width: size.width * 0.24,
      height: size.height * 0.23,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(sensorRect, const Radius.circular(14)),
      Paint()..color = const Color(0xFFEFF6FF),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(sensorRect, const Radius.circular(14)),
      outline,
    );
    canvas.drawCircle(
      sensorRect.centerLeft + Offset(sensorRect.width * 0.22, 0),
      5,
      Paint()..color = const Color(0xFF22C55E),
    );
    canvas.drawLine(
      sensorRect.topRight + const Offset(-18, 2),
      sensorRect.topRight + const Offset(4, -24),
      stroke..color = const Color(0xFF2563EB),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ─── Slide 4: User type selection ─────────────────────────────────────────
class _SlideUserType extends StatelessWidget {
  final String? selected;
  final ValueChanged<String> onSelect;
  final AnimationController entry;

  const _SlideUserType({
    super.key,
    required this.selected,
    required this.onSelect,
    required this.entry,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppTheme.spaceLG),
      child: Column(
        children: <Widget>[
          const SizedBox(height: AppTheme.spaceLG),
          Expanded(
            flex: 6,
            child: FadeTransition(
              opacity: entry,
              child: Column(
                children: <Widget>[
                  Expanded(
                    child: _UserTypeCard(
                      icon: Icons.fitness_center_rounded,
                      label: 'Athlete',
                      subtitle:
                          'Monitor bilateral performance and\npush for symmetry gains.',
                      isSelected: selected == 'athlete',
                      onTap: () => onSelect('athlete'),
                    ),
                  ),
                  const SizedBox(height: AppTheme.spaceMD),
                  Expanded(
                    child: _UserTypeCard(
                      icon: Icons.healing_rounded,
                      label: 'Rehabilitation',
                      subtitle:
                          'Track recovery progress and\nbalance the load on each side.',
                      isSelected: selected == 'rehabilitation',
                      onTap: () => onSelect('rehabilitation'),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppTheme.spaceXL),
          Text(
            'Who are you?',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 26,
              fontWeight: FontWeight.w800,
              color: AppTheme.lightTextPrimary,
              height: 1.2,
              letterSpacing: -0.6,
            ),
          ),
          const SizedBox(height: AppTheme.spaceSM),
          Text(
            "We'll personalise your experience\nbased on your goals.",
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 15,
              fontWeight: FontWeight.w400,
              color: AppTheme.lightTextSecondary,
              height: 1.55,
            ),
          ),
          const Spacer(flex: 1),
        ],
      ),
    );
  }
}

class _UserTypeCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final bool isSelected;
  final VoidCallback onTap;

  const _UserTypeCard({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        decoration: BoxDecoration(
          color: isSelected
              ? AppTheme.lightTextPrimary
              : AppTheme.lightBackgroundCard,
          borderRadius: BorderRadius.circular(AppTheme.radiusMD),
          border: Border.all(
            color: isSelected ? const Color(0xFF2563EB) : AppTheme.lightDivider,
            width: 1.5,
          ),
          boxShadow: isSelected
              ? <BoxShadow>[
                  BoxShadow(
                    color: AppTheme.lightTextPrimary.withValues(alpha: 0.18),
                    blurRadius: 18,
                    offset: const Offset(0, 8),
                  ),
                ]
              : AppTheme.lightCardShadow,
        ),
        padding: const EdgeInsets.all(AppTheme.spaceMD),
        child: Row(
          children: <Widget>[
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: isSelected
                    ? Colors.white.withValues(alpha: 0.14)
                    : AppTheme.lightBackgroundElevated,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                icon,
                size: 28,
                color: isSelected
                    ? AppTheme.lightBackgroundPrimary
                    : AppTheme.lightTextPrimary,
              ),
            ),
            const SizedBox(width: AppTheme.spaceMD),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Text(
                    label,
                    style: GoogleFonts.inter(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      color: isSelected
                          ? AppTheme.lightBackgroundPrimary
                          : AppTheme.lightTextPrimary,
                      letterSpacing: -0.2,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w400,
                      color: isSelected
                          ? AppTheme.lightBackgroundPrimary.withValues(
                              alpha: 0.72,
                            )
                          : AppTheme.lightTextSecondary,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isSelected
                    ? AppTheme.lightBackgroundPrimary
                    : Colors.transparent,
                border: Border.all(
                  color: isSelected
                      ? AppTheme.lightBackgroundPrimary
                      : AppTheme.lightDivider,
                  width: 1.5,
                ),
              ),
              child: isSelected
                  ? const Icon(
                      Icons.check_rounded,
                      size: 16,
                      color: AppTheme.lightTextPrimary,
                    )
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}

class _SlideChannelCalibration extends StatelessWidget {
  final AnimationController entry;
  final String channelA;
  final String channelB;
  final ValueChanged<String> onChannelAChanged;
  final ValueChanged<String> onChannelBChanged;

  const _SlideChannelCalibration({
    super.key,
    required this.entry,
    required this.channelA,
    required this.channelB,
    required this.onChannelAChanged,
    required this.onChannelBChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppTheme.spaceLG),
      child: Column(
        children: <Widget>[
          const SizedBox(height: AppTheme.spaceLG),
          Expanded(
            flex: 6,
            child: FadeTransition(
              opacity: entry,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                children: <Widget>[
                  Container(
                    decoration: BoxDecoration(
                      color: AppTheme.lightBackgroundCard,
                      borderRadius: AppTheme.cardRadius,
                      border: Border.all(color: AppTheme.lightDivider),
                      boxShadow: AppTheme.lightCardShadow,
                    ),
                    padding: const EdgeInsets.all(AppTheme.spaceLG),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          'Pair Your Cables',
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.lightTextPrimary,
                            letterSpacing: -0.3,
                          ),
                        ),
                        const SizedBox(height: AppTheme.spaceLG),
                        _ChannelSelector(
                          label: 'Channel A →',
                          selected: channelA,
                          options: const ['left', 'right'],
                          onSelect: onChannelAChanged,
                        ),
                        const SizedBox(height: AppTheme.spaceMD),
                        _ChannelSelector(
                          label: 'Channel B →',
                          selected: channelB,
                          options: const ['left', 'right'],
                          onSelect: onChannelBChanged,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppTheme.spaceXL),
          Text(
            'Cable Assignment',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 26,
              fontWeight: FontWeight.w800,
              color: AppTheme.lightTextPrimary,
              height: 1.2,
              letterSpacing: -0.6,
            ),
          ),
          const SizedBox(height: AppTheme.spaceSM),
          Text(
            'Which side is each cable connected to?\nYou can recalibrate anytime in settings.',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 15,
              fontWeight: FontWeight.w400,
              color: AppTheme.lightTextSecondary,
              height: 1.55,
            ),
          ),
          const Spacer(flex: 1),
        ],
      ),
    );
  }
}

class _ChannelSelector extends StatelessWidget {
  final String label;
  final String selected;
  final List<String> options;
  final ValueChanged<String> onSelect;

  const _ChannelSelector({
    required this.label,
    required this.selected,
    required this.options,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppTheme.lightTextSecondary,
          ),
        ),
        const SizedBox(width: AppTheme.spaceMD),
        ...options.map(
          (option) => Padding(
            padding: const EdgeInsets.only(right: AppTheme.spaceSM),
            child: GestureDetector(
              onTap: () => onSelect(option),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppTheme.spaceMD,
                  vertical: AppTheme.spaceSM,
                ),
                decoration: BoxDecoration(
                  color: selected == option
                      ? AppTheme.lightTextPrimary
                      : AppTheme.lightBackgroundElevated,
                  borderRadius: BorderRadius.circular(AppTheme.radiusSM),
                  border: Border.all(
                    color: selected == option
                        ? AppTheme.lightTextPrimary
                        : AppTheme.lightDivider,
                    width: 1.5,
                  ),
                ),
                child: Text(
                  option[0].toUpperCase() + option.substring(1),
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: selected == option
                        ? AppTheme.lightBackgroundPrimary
                        : AppTheme.lightTextSecondary,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
