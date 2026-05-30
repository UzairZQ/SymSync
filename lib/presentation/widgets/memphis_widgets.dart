import 'dart:math' as math;

import 'package:flutter/material.dart';

class MemphisBackdrop extends StatefulWidget {
  const MemphisBackdrop({super.key});

  @override
  State<MemphisBackdrop> createState() => _MemphisBackdropState();
}

class _MemphisBackdropState extends State<MemphisBackdrop>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 12),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final t = _controller.value * math.pi * 2;
        return CustomPaint(
          painter: _MemphisBackdropPainter(t),
          child: const SizedBox.expand(),
        );
      },
    );
  }
}

class _MemphisBackdropPainter extends CustomPainter {
  _MemphisBackdropPainter(this.time);

  final double time;

  @override
  void paint(Canvas canvas, Size size) {
    final bgPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: <Color>[
          Color(0xFFF7F7FB),
          Color(0xFFF5F0FF),
          Color(0xFFEAF6FF),
        ],
      ).createShader(Offset.zero & size);
    canvas.drawRect(Offset.zero & size, bgPaint);

    void blob(Offset center, double radius, List<Color> colors) {
      final paint = Paint()
        ..shader = RadialGradient(
          colors: colors,
        ).createShader(Rect.fromCircle(center: center, radius: radius));
      canvas.drawCircle(center, radius, paint);
    }

    blob(
      Offset(size.width * (0.10 + 0.02 * math.sin(time)), size.height * 0.10),
      120,
      <Color>[
        const Color(0xFFB3C7FF).withValues(alpha: 0.8),
        Colors.transparent,
      ],
    );
    blob(
      Offset(
        size.width * (0.84 + 0.02 * math.cos(time * 0.7)),
        size.height * 0.16,
      ),
      140,
      <Color>[
        const Color(0xFFFFC98C).withValues(alpha: 0.72),
        Colors.transparent,
      ],
    );
    blob(
      Offset(
        size.width * 0.78,
        size.height * (0.82 + 0.02 * math.sin(time * 0.9)),
      ),
      160,
      <Color>[
        const Color(0xFFA7F3D0).withValues(alpha: 0.55),
        Colors.transparent,
      ],
    );

    final strokePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..color = const Color(0xFF232A3A).withValues(alpha: 0.05);
    final path = Path()
      ..moveTo(size.width * 0.1, size.height * 0.58)
      ..quadraticBezierTo(
        size.width * 0.22,
        size.height * (0.48 + 0.02 * math.sin(time)),
        size.width * 0.34,
        size.height * 0.58,
      )
      ..quadraticBezierTo(
        size.width * 0.46,
        size.height * (0.68 + 0.02 * math.cos(time)),
        size.width * 0.62,
        size.height * 0.56,
      )
      ..quadraticBezierTo(
        size.width * 0.76,
        size.height * (0.44 + 0.02 * math.sin(time * 0.8)),
        size.width * 0.9,
        size.height * 0.58,
      );
    canvas.drawPath(path, strokePaint);

    for (var i = 0; i < 5; i++) {
      final x = size.width * (0.08 + i * 0.18);
      final y = size.height * (0.22 + 0.03 * math.sin(time + i));
      final paint = Paint()
        ..color = const Color(0xFF355CFF).withValues(alpha: 0.08);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(center: Offset(x, y), width: 52, height: 18),
          const Radius.circular(10),
        ),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _MemphisBackdropPainter oldDelegate) {
    return oldDelegate.time != time;
  }
}

class MemphisCard extends StatelessWidget {
  const MemphisCard({
    super.key,
    required this.child,
    this.tint = const Color(0xFF355CFF),
  });

  final Widget child;
  final Color tint;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: tint.withValues(alpha: 0.08),
            blurRadius: 28,
            offset: const Offset(0, 12),
          ),
        ],
        border: Border.all(color: tint.withValues(alpha: 0.08)),
      ),
      child: ClipRRect(borderRadius: BorderRadius.circular(28), child: child),
    );
  }
}

class StatusPill extends StatelessWidget {
  const StatusPill({super.key, required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: color,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class MemphisSectionHeader extends StatelessWidget {
  const MemphisSectionHeader({
    super.key,
    required this.title,
    required this.subtitle,
    this.trailing,
  });

  final String title;
  final String subtitle;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                title,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: const Color(0xFF5A6478),
                ),
              ),
            ],
          ),
        ),
        if (trailing != null) trailing!,
      ],
    );
  }
}

class MemphisMetric extends StatelessWidget {
  const MemphisMetric({
    super.key,
    required this.label,
    required this.value,
    this.caption,
    this.color = const Color(0xFF355CFF),
  });

  final String label;
  final String value;
  final String? caption;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            label,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: color,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900),
          ),
          if (caption != null) ...<Widget>[
            const SizedBox(height: 2),
            Text(
              caption!,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: const Color(0xFF5A6478)),
            ),
          ],
        ],
      ),
    );
  }
}
