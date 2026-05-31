import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import 'dart:math' as math;

// ─── Onboarding entry point ────────────────────────────────────────────────
// Call this from main.dart:
//   final prefs = await SharedPreferences.getInstance();
//   final done  = prefs.getBool('onboarding_complete') ?? false;
//   home: done ? const HomeShellPage() : const OnboardingPage(),

// Add this at the very top of onboarding_page.dart
// before the OnboardingPage class definition

abstract class _OC {
  static const Color bg = Color(0xFFFAFAFA);
  static const Color teal = Color(0xFF00E5CC);
  static const Color amber = Color(0xFFFFB340);
  static const Color coral = Color(0xFFFF4D6A);
  static const Color blue = Color(0xFF4A9EFF);
  static const Color txtPri = Color(0xFF0D1B2A);
  static const Color txtSec = Color(0xFF4A5A6B);
  static const LinearGradient tealGradient = LinearGradient(
    colors: [Color(0xFF00E5CC), Color(0xFF4A9EFF)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}

class OnboardingPage extends StatefulWidget {
  final VoidCallback onComplete; // ADD THIS

  const OnboardingPage({super.key, required this.onComplete});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage>
    with TickerProviderStateMixin {
  final PageController _pageCtrl = PageController();
  int _currentPage = 0;
  String? _selectedUserType; // 'athlete' or 'rehabilitation'

  // Memphis shape animation
  late AnimationController _memphisCtrl;
  // Star rotation on slide 5
  late AnimationController _starCtrl;

  // ── Memphis palette (always light, ignores app theme) ──────────────────
  static const Color _bg = Color(0xFFFAFAFA);
  static const Color _teal = Color(0xFF00E5CC);
  static const Color _amber = Color(0xFFFFB340);
  static const Color _coral = Color(0xFFFF4D6A);
  static const Color _blue = Color(0xFF4A9EFF);
  static const Color _txtPri = Color(0xFF0D1B2A);
  static const Color _txtSec = Color(0xFF4A5A6B);
  static const LinearGradient _tealGradient = LinearGradient(
    colors: [Color(0xFF00E5CC), Color(0xFF4A9EFF)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  @override
  void initState() {
    super.initState();
    _memphisCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..forward();
    _starCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    )..repeat();
  }

  @override
  void dispose() {
    _pageCtrl.dispose();
    _memphisCtrl.dispose();
    _starCtrl.dispose();
    super.dispose();
  }

  void _nextPage() {
    if (_currentPage < 4) {
      _pageCtrl.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    }
  }

  void _skipToLast() {
    _pageCtrl.animateToPage(
      4,
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeInOut,
    );
  }

  Future<void> _complete() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_complete', true);
    if (_selectedUserType != null) {
      await prefs.setString('user_type', _selectedUserType!);
    }
    if (!mounted) return;
    widget.onComplete(); // CALL THE CALLBACK instead of navigating
  }

  bool get _canProceedSlide4 => _currentPage != 3 || _selectedUserType != null;

  @override
  Widget build(BuildContext context) {
    return Theme(
      // Force light theme for onboarding regardless of app theme
      data: ThemeData(
        brightness: Brightness.light,
        scaffoldBackgroundColor: _bg,
      ),
      child: Scaffold(
        backgroundColor: _bg,
        body: Stack(
          children: [
            // ── Page content ──────────────────────────────────────────────
            PageView(
              controller: _pageCtrl,
              physics: const NeverScrollableScrollPhysics(),
              onPageChanged: (i) {
                setState(() => _currentPage = i);
                _memphisCtrl.reset();
                _memphisCtrl.forward();
              },
              children: [
                _Slide1(ctrl: _memphisCtrl),
                _Slide2(ctrl: _memphisCtrl),
                _Slide3(ctrl: _memphisCtrl),
                _Slide4(
                  ctrl: _memphisCtrl,
                  selected: _selectedUserType,
                  onSelect: (t) => setState(() => _selectedUserType = t),
                ),
                _Slide5(ctrl: _memphisCtrl, starCtrl: _starCtrl),
              ],
            ),

            // ── Bottom controls ───────────────────────────────────────────
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: _BottomControls(
                currentPage: _currentPage,
                pageCtrl: _pageCtrl,
                canProceed: _canProceedSlide4,
                onNext: _nextPage,
                onSkip: _skipToLast,
                onComplete: _complete,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Bottom controls bar ──────────────────────────────────────────────────
class _BottomControls extends StatelessWidget {
  final int currentPage;
  final PageController pageCtrl;
  final bool canProceed;
  final VoidCallback onNext;
  final VoidCallback onSkip;
  final VoidCallback onComplete;

  const _BottomControls({
    required this.currentPage,
    required this.pageCtrl,
    required this.canProceed,
    required this.onNext,
    required this.onSkip,
    required this.onComplete,
  });

  @override
  Widget build(BuildContext context) {
    final isLast = currentPage == 4;
    return Container(
      padding: EdgeInsets.fromLTRB(
        24,
        16,
        24,
        MediaQuery.of(context).padding.bottom + 24,
      ),
      decoration: const BoxDecoration(
        color: Color(0xFFFAFAFA),
        border: Border(top: BorderSide(color: Color(0xFFE8EDF2), width: 1)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Page indicator
          if (!isLast)
            SmoothPageIndicator(
              controller: pageCtrl,
              count: 5,
              effect: const WormEffect(
                dotHeight: 8,
                dotWidth: 8,
                dotColor: Color(0xFFCCCCCC),
                activeDotColor: Color(0xFF00E5CC),
                spacing: 8,
              ),
            ),
          if (!isLast) const SizedBox(height: 20),

          // Buttons row or Get Started
          if (isLast)
            _GradientButton(label: 'Get Started', onTap: onComplete)
          else
            Row(
              children: [
                TextButton(
                  onPressed: onSkip,
                  child: Text(
                    'Skip',
                    style: GoogleFonts.dmSans(
                      fontSize: 15,
                      color: const Color(0xFF9AAABB),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                const Spacer(),
                AnimatedOpacity(
                  opacity: canProceed ? 1.0 : 0.4,
                  duration: const Duration(milliseconds: 200),
                  child: _OutlinedNextButton(onTap: canProceed ? onNext : null),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

class _GradientButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _GradientButton({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        height: 56,
        decoration: BoxDecoration(
          gradient: _OC.tealGradient,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF00E5CC).withOpacity(0.35),
              blurRadius: 20,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: GoogleFonts.dmSans(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: Colors.white,
            letterSpacing: 0.3,
          ),
        ),
      ),
    );
  }
}

class _OutlinedNextButton extends StatelessWidget {
  final VoidCallback? onTap;
  const _OutlinedNextButton({this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
        decoration: BoxDecoration(
          border: Border.all(color: const Color(0xFF00E5CC), width: 2),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Next',
              style: GoogleFonts.dmSans(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF00E5CC),
              ),
            ),
            const SizedBox(width: 6),
            const Icon(
              Icons.arrow_forward_rounded,
              color: Color(0xFF00E5CC),
              size: 18,
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Slide base template ──────────────────────────────────────────────────
class _SlideBase extends StatelessWidget {
  final AnimationController ctrl;
  final List<_MemphisShape> shapes;
  final Widget illustration;
  final String title;
  final String body;
  final Widget? extra;

  const _SlideBase({
    required this.ctrl,
    required this.shapes,
    required this.illustration,
    required this.title,
    required this.body,
    this.extra,
  });

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return Stack(
      children: [
        // Memphis background
        CustomPaint(
          size: size,
          painter: _MemphisPainter(shapes: shapes, animation: ctrl),
        ),

        // Foreground content
        SafeArea(
          bottom: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(28, 40, 28, 120),
            child: Column(
              children: [
                // Illustration area
                Expanded(
                  flex: 5,
                  child: FadeTransition(
                    opacity: ctrl,
                    child: ScaleTransition(
                      scale: Tween(begin: 0.88, end: 1.0).animate(
                        CurvedAnimation(parent: ctrl, curve: Curves.easeOut),
                      ),
                      child: illustration,
                    ),
                  ),
                ),

                // Text area
                Expanded(
                  flex: 4,
                  child: FadeTransition(
                    opacity: CurvedAnimation(
                      parent: ctrl,
                      curve: const Interval(0.3, 1.0),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        const SizedBox(height: 20),
                        Text(
                          title,
                          textAlign: TextAlign.center,
                          style: GoogleFonts.dmSerifDisplay(
                            fontSize: 30,
                            color: _OC.txtPri,
                            height: 1.15,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          body,
                          textAlign: TextAlign.center,
                          maxLines: 4,
                          style: GoogleFonts.dmSans(
                            fontSize: 16,
                            color: _OC.txtSec,
                            height: 1.5,
                          ),
                        ),
                        if (extra != null) ...[
                          const SizedBox(height: 16),
                          extra!,
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ─── Slide 1: Welcome ─────────────────────────────────────────────────────
class _Slide1 extends StatelessWidget {
  final AnimationController ctrl;
  const _Slide1({required this.ctrl});

  @override
  Widget build(BuildContext context) {
    return _SlideBase(
      ctrl: ctrl,
      shapes: [
        _MemphisShape.circle(dx: 0.85, dy: 0.08, r: 64, color: _OC.teal),
        _MemphisShape.circle(dx: 0.12, dy: 0.22, r: 32, color: _OC.amber),
        _MemphisShape.circle(dx: 0.70, dy: 0.30, r: 16, color: _OC.coral),
        _MemphisShape.triangle(dx: 0.05, dy: 0.70, size: 48, color: _OC.blue),
        _MemphisShape.squiggle(dx: 0.40, dy: 0.15, color: _OC.amber),
        _MemphisShape.dots(dx: 0.75, dy: 0.70, color: _OC.teal),
      ],
      illustration: CustomPaint(
        size: const Size(260, 240),
        painter: _WelcomeIllustrationPainter(),
      ),
      title: 'Welcome to SymSync',
      body:
          'Your personal muscle symmetry coach.\nWe measure, you move, we guide.',
    );
  }
}

// ─── Slide 2: How it works ────────────────────────────────────────────────
class _Slide2 extends StatelessWidget {
  final AnimationController ctrl;
  const _Slide2({required this.ctrl});

  @override
  Widget build(BuildContext context) {
    return _SlideBase(
      ctrl: ctrl,
      shapes: [
        _MemphisShape.circle(dx: 0.10, dy: 0.10, r: 48, color: _OC.blue),
        _MemphisShape.triangle(dx: 0.80, dy: 0.70, size: 56, color: _OC.amber),
        _MemphisShape.squiggle(dx: 0.20, dy: 0.60, color: _OC.teal),
        _MemphisShape.dots(dx: 0.05, dy: 0.40, color: _OC.coral),
        _MemphisShape.circle(dx: 0.90, dy: 0.25, r: 20, color: _OC.coral),
      ],
      illustration: CustomPaint(
        size: const Size(300, 200),
        painter: _HowItWorksPainter(),
      ),
      title: 'EMG Made Simple',
      body:
          'Attach two sensors to your legs,\nconnect via Bluetooth, and see your\nmuscle balance in real time.',
    );
  }
}

// ─── Slide 3: Stair task ──────────────────────────────────────────────────
class _Slide3 extends StatelessWidget {
  final AnimationController ctrl;
  const _Slide3({required this.ctrl});

  @override
  Widget build(BuildContext context) {
    return _SlideBase(
      ctrl: ctrl,
      shapes: [
        _MemphisShape.triangle(dx: 0.10, dy: 0.55, size: 72, color: _OC.coral),
        _MemphisShape.dots(dx: 0.75, dy: 0.10, color: _OC.blue),
        _MemphisShape.circle(dx: 0.85, dy: 0.55, r: 28, color: _OC.amber),
        _MemphisShape.squiggle(dx: 0.55, dy: 0.75, color: _OC.teal),
        _MemphisShape.circle(dx: 0.25, dy: 0.10, r: 18, color: _OC.teal),
      ],
      illustration: CustomPaint(
        size: const Size(260, 240),
        painter: _StairIllustrationPainter(),
      ),
      title: 'Climb with Confidence',
      body:
          'During stair climbing, SymSync detects\nwhich leg is working harder and helps\nyou balance the load.',
    );
  }
}

// ─── Slide 4: User type selection ─────────────────────────────────────────
class _Slide4 extends StatelessWidget {
  final AnimationController ctrl;
  final String? selected;
  final ValueChanged<String> onSelect;

  const _Slide4({
    required this.ctrl,
    required this.selected,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return _SlideBase(
      ctrl: ctrl,
      shapes: [
        _MemphisShape.circle(dx: 0.88, dy: 0.12, r: 40, color: _OC.teal),
        _MemphisShape.squiggle(dx: 0.05, dy: 0.30, color: _OC.amber),
        _MemphisShape.dots(dx: 0.80, dy: 0.65, color: _OC.coral),
        _MemphisShape.triangle(dx: 0.10, dy: 0.75, size: 44, color: _OC.blue),
      ],
      illustration: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _UserTypeCard(
            icon: Icons.fitness_center_rounded,
            label: 'Athlete',
            subtitle: 'Monitor bilateral\nperformance',
            color: _OC.amber,
            isSelected: selected == 'athlete',
            onTap: () => onSelect('athlete'),
          ),
          const SizedBox(width: 16),
          _UserTypeCard(
            icon: Icons.favorite_rounded,
            label: 'Rehabilitation',
            subtitle: 'Track your\nrecovery progress',
            color: _OC.blue,
            isSelected: selected == 'rehabilitation',
            onTap: () => onSelect('rehabilitation'),
          ),
        ],
      ),
      title: 'Who are you?',
      body: "We'll personalise your experience\nbased on your goals.",
    );
  }
}

class _UserTypeCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final Color color;
  final bool isSelected;
  final VoidCallback onTap;

  const _UserTypeCard({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.color,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeInOut,
        width: 145,
        height: 160,
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.12) : Colors.white,
          border: Border.all(
            color: isSelected ? color : const Color(0xFFDDE3EA),
            width: isSelected ? 2.5 : 1.5,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: isSelected
              ? [BoxShadow(color: color.withOpacity(0.20), blurRadius: 16)]
              : [const BoxShadow(color: Color(0x0F000000), blurRadius: 8)],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedScale(
              scale: isSelected ? 1.15 : 1.0,
              duration: const Duration(milliseconds: 220),
              child: Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 28),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              label,
              style: GoogleFonts.dmSans(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: isSelected ? _OC.txtPri : _OC.txtSec,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: GoogleFonts.dmSans(
                fontSize: 12,
                color: _OC.txtSec,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Slide 5: Ready ───────────────────────────────────────────────────────
class _Slide5 extends StatelessWidget {
  final AnimationController ctrl;
  final AnimationController starCtrl;
  const _Slide5({required this.ctrl, required this.starCtrl});

  @override
  Widget build(BuildContext context) {
    return _SlideBase(
      ctrl: ctrl,
      shapes: [
        _MemphisShape.circle(dx: 0.15, dy: 0.10, r: 36, color: _OC.teal),
        _MemphisShape.circle(dx: 0.82, dy: 0.18, r: 52, color: _OC.amber),
        _MemphisShape.triangle(dx: 0.80, dy: 0.60, size: 40, color: _OC.coral),
        _MemphisShape.squiggle(dx: 0.10, dy: 0.65, color: _OC.blue),
        _MemphisShape.dots(dx: 0.60, dy: 0.08, color: _OC.coral),
      ],
      illustration: _PhoneWithStars(starCtrl: starCtrl),
      title: "You're all set!",
      body:
          'Pair your biosignalsplux device and\nbegin your first bilateral EMG session.',
    );
  }
}

class _PhoneWithStars extends StatelessWidget {
  final AnimationController starCtrl;
  const _PhoneWithStars({required this.starCtrl});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 240,
      height: 240,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Rotating stars
          RotationTransition(
            turns: starCtrl,
            child: CustomPaint(
              size: const Size(220, 220),
              painter: _StarConfettiPainter(),
            ),
          ),
          // Phone illustration
          CustomPaint(size: const Size(130, 200), painter: _PhonePainter()),
        ],
      ),
    );
  }
}

// ─── Memphis shape system ─────────────────────────────────────────────────
enum _MemphisShapeType { circle, triangle, squiggle, dots }

class _MemphisShape {
  final _MemphisShapeType type;
  final double dx, dy;
  final double size;
  final Color color;

  const _MemphisShape._({
    required this.type,
    required this.dx,
    required this.dy,
    required this.size,
    required this.color,
  });

  factory _MemphisShape.circle({
    required double dx,
    required double dy,
    required double r,
    required Color color,
  }) => _MemphisShape._(
    type: _MemphisShapeType.circle,
    dx: dx,
    dy: dy,
    size: r,
    color: color,
  );

  factory _MemphisShape.triangle({
    required double dx,
    required double dy,
    required double size,
    required Color color,
  }) => _MemphisShape._(
    type: _MemphisShapeType.triangle,
    dx: dx,
    dy: dy,
    size: size,
    color: color,
  );

  factory _MemphisShape.squiggle({
    required double dx,
    required double dy,
    required Color color,
  }) => _MemphisShape._(
    type: _MemphisShapeType.squiggle,
    dx: dx,
    dy: dy,
    size: 80,
    color: color,
  );

  factory _MemphisShape.dots({
    required double dx,
    required double dy,
    required Color color,
  }) => _MemphisShape._(
    type: _MemphisShapeType.dots,
    dx: dx,
    dy: dy,
    size: 5,
    color: color,
  );
}

class _MemphisPainter extends CustomPainter {
  final List<_MemphisShape> shapes;
  final Animation<double> animation;

  _MemphisPainter({required this.shapes, required this.animation})
    : super(repaint: animation);

  @override
  void paint(Canvas canvas, Size size) {
    final opacity = animation.value * 0.55;
    for (final s in shapes) {
      final x = s.dx * size.width;
      final y = s.dy * size.height;
      final paint = Paint()
        ..color = s.color.withOpacity(opacity)
        ..style = PaintingStyle.fill;

      switch (s.type) {
        case _MemphisShapeType.circle:
          canvas.drawCircle(Offset(x, y), s.size, paint);
          break;
        case _MemphisShapeType.triangle:
          final path = Path()
            ..moveTo(x, y - s.size * 0.6)
            ..lineTo(x + s.size * 0.55, y + s.size * 0.4)
            ..lineTo(x - s.size * 0.55, y + s.size * 0.4)
            ..close();
          canvas.drawPath(path, paint);
          break;
        case _MemphisShapeType.squiggle:
          paint
            ..style = PaintingStyle.stroke
            ..strokeWidth = 3
            ..strokeCap = StrokeCap.round;
          final path = Path()
            ..moveTo(x, y)
            ..cubicTo(x + 20, y - 18, x + 40, y + 18, x + 60, y)
            ..cubicTo(x + 80, y - 18, x + 100, y + 18, x + 120, y);
          canvas.drawPath(path, paint);
          break;
        case _MemphisShapeType.dots:
          for (int r = 0; r < 4; r++) {
            for (int c = 0; c < 4; c++) {
              canvas.drawCircle(
                Offset(x + c * 14.0, y + r * 14.0),
                s.size * 0.55,
                paint,
              );
            }
          }
          break;
      }
    }
  }

  @override
  bool shouldRepaint(_MemphisPainter old) => true;
}

// ─── Illustration painters ────────────────────────────────────────────────

class _WelcomeIllustrationPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;

    // Phone body
    final phonePaint = Paint()..color = const Color(0xFF0D1B2A);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(cx + 48, cy - 10),
          width: 70,
          height: 110,
        ),
        const Radius.circular(12),
      ),
      phonePaint,
    );

    // Phone screen - symmetry dial
    final screenPaint = Paint()..color = const Color(0xFF162030);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(cx + 48, cy - 10),
          width: 58,
          height: 95,
        ),
        const Radius.circular(8),
      ),
      screenPaint,
    );

    // Dial circle on phone
    canvas.drawCircle(
      Offset(cx + 48, cy - 12),
      24,
      Paint()..color = const Color(0xFF00E5CC).withOpacity(0.25),
    );
    canvas.drawCircle(
      Offset(cx + 48, cy - 12),
      24,
      Paint()
        ..color = const Color(0xFF00E5CC)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );

    // Leg illustration (left side)
    final legPaint = Paint()..color = const Color(0xFF4A9EFF).withOpacity(0.85);
    final rightLegPaint = Paint()
      ..color = const Color(0xFF00E5CC).withOpacity(0.85);

    // Left leg
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(cx - 65, cy - 20, 28, 70),
        const Radius.circular(14),
      ),
      legPaint,
    );
    // Right leg
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(cx - 30, cy - 20, 28, 70),
        const Radius.circular(14),
      ),
      rightLegPaint,
    );

    // Electrode dots on left leg
    final dotPaint = Paint()..color = Colors.white;
    canvas.drawCircle(Offset(cx - 51, cy + 5), 5, dotPaint);
    canvas.drawCircle(Offset(cx - 51, cy + 22), 5, dotPaint);

    // Connection wire squiggle
    final wirePaint = Paint()
      ..color = const Color(0xFFFFB340)
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    final wirePath = Path()
      ..moveTo(cx - 40, cy + 13)
      ..cubicTo(cx + 10, cy - 30, cx + 20, cy - 30, cx + 28, cy - 12);
    canvas.drawPath(wirePath, wirePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}

class _HowItWorksPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final y = size.height / 2;
    final icons = [
      (size.width * 0.18, 'EMG'),
      (size.width * 0.50, 'BT'),
      (size.width * 0.82, 'SYM'),
    ];
    final colours = [
      const Color(0xFF4A9EFF),
      const Color(0xFF00E5CC),
      const Color(0xFFFFB340),
    ];

    for (int i = 0; i < 3; i++) {
      final x = icons[i].$1;
      final label = icons[i].$2;
      final col = colours[i];

      // Circle background
      canvas.drawCircle(
        Offset(x, y),
        38,
        Paint()..color = col.withOpacity(0.15),
      );
      canvas.drawCircle(
        Offset(x, y),
        38,
        Paint()
          ..color = col
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2,
      );

      // Label text
      final tp = TextPainter(
        text: TextSpan(
          text: label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: col,
            letterSpacing: 0.5,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(x - tp.width / 2, y - tp.height / 2));

      // Arrow between icons
      if (i < 2) {
        final arrowPaint = Paint()
          ..color = const Color(0xFF9AAABB)
          ..strokeWidth = 2
          ..style = PaintingStyle.stroke;
        canvas.drawLine(Offset(x + 44, y), Offset(x + 82, y), arrowPaint);
        // Arrowhead
        canvas.drawLine(Offset(x + 76, y - 6), Offset(x + 82, y), arrowPaint);
        canvas.drawLine(Offset(x + 76, y + 6), Offset(x + 82, y), arrowPaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}

class _StairIllustrationPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final base = size.height * 0.75;
    final stepW = 55.0;
    final stepH = 22.0;

    // Draw 3 stairs
    final stairPaint = Paint()
      ..color = const Color(0xFF0D1B2A).withOpacity(0.85);
    for (int i = 0; i < 3; i++) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(
            cx - 80 + i * stepW,
            base - i * stepH,
            stepW * (3 - i),
            stepH,
          ),
          const Radius.circular(4),
        ),
        stairPaint,
      );
    }

    // Figure body
    final bodyPaint = Paint()..color = const Color(0xFF0D1B2A);
    // Torso
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(cx + 10, base - 80),
          width: 22,
          height: 36,
        ),
        const Radius.circular(11),
      ),
      bodyPaint,
    );
    // Head
    canvas.drawCircle(Offset(cx + 10, base - 106), 14, bodyPaint);

    // Left leg (blue)
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(cx + 2, base - 62, 10, 32),
        const Radius.circular(5),
      ),
      Paint()..color = const Color(0xFF4A9EFF),
    );
    // Right leg (teal)
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(cx + 14, base - 62, 10, 32),
        const Radius.circular(5),
      ),
      Paint()..color = const Color(0xFF00E5CC),
    );

    // Arrow up
    final arrowPaint = Paint()
      ..color = const Color(0xFF00E5CC)
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
      Offset(cx + 60, base - 30),
      Offset(cx + 60, base - 90),
      arrowPaint,
    );
    canvas.drawLine(
      Offset(cx + 48, base - 78),
      Offset(cx + 60, base - 90),
      arrowPaint,
    );
    canvas.drawLine(
      Offset(cx + 72, base - 78),
      Offset(cx + 60, base - 90),
      arrowPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}

class _PhonePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;

    // Phone frame
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(0, 0, size.width, size.height),
        const Radius.circular(18),
      ),
      Paint()..color = const Color(0xFF0D1B2A),
    );

    // Screen
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(6, 10, size.width - 12, size.height - 20),
        const Radius.circular(12),
      ),
      Paint()..color = const Color(0xFF0F1923),
    );

    // Two coloured leg shapes inside screen
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(cx - 30, 40, 22, 90),
        const Radius.circular(11),
      ),
      Paint()..color = const Color(0xFF4A9EFF).withOpacity(0.85),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(cx + 8, 40, 22, 90),
        const Radius.circular(11),
      ),
      Paint()..color = const Color(0xFF00E5CC).withOpacity(0.85),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}

class _StarConfettiPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final colours = [
      const Color(0xFF00E5CC),
      const Color(0xFFFFB340),
      const Color(0xFFFF4D6A),
      const Color(0xFF4A9EFF),
    ];
    final positions = [
      Offset(cx - 80, cy - 40),
      Offset(cx + 75, cy - 50),
      Offset(cx - 70, cy + 60),
      Offset(cx + 65, cy + 55),
      Offset(cx, cy - 90),
      Offset(cx - 30, cy + 90),
    ];

    for (int i = 0; i < positions.length; i++) {
      _drawStar(canvas, positions[i], 10, colours[i % colours.length]);
    }

    // Confetti dots
    for (int i = 0; i < 12; i++) {
      final angle = i * math.pi * 2 / 12;
      final r = 90.0;
      canvas.drawCircle(
        Offset(cx + r * math.cos(angle), cy + r * math.sin(angle)),
        4,
        Paint()..color = colours[i % colours.length].withOpacity(0.6),
      );
    }
  }

  void _drawStar(Canvas canvas, Offset center, double r, Color color) {
    final path = Path();
    for (int i = 0; i < 4; i++) {
      final angle = i * math.pi / 2 - math.pi / 4;
      final outer = Offset(
        center.dx + r * math.cos(angle),
        center.dy + r * math.sin(angle),
      );
      final inner = Offset(
        center.dx + (r * 0.4) * math.cos(angle + math.pi / 4),
        center.dy + (r * 0.4) * math.sin(angle + math.pi / 4),
      );
      if (i == 0)
        path.moveTo(outer.dx, outer.dy);
      else
        path.lineTo(outer.dx, outer.dy);
      path.lineTo(inner.dx, inner.dy);
    }
    path.close();
    canvas.drawPath(path, Paint()..color = color);
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}
