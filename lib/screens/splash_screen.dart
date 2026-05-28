import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../utils/constants.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 2200), () {
      if (mounted) context.go('/menu');
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppConstants.world1Secondary,
              AppConstants.waterfall,
              Color(0xFF2F8C36),
            ],
            stops: [0, 0.55, 1],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CustomPaint(
                size: Size(132, 132),
                painter: _SplashBubblePainter(),
              )
                  .animate()
                  .scale(duration: 700.ms, curve: Curves.elasticOut)
                  .then()
                  .shake(duration: 600.ms),
              const SizedBox(height: 16),
              Text(
                'Bubble\nBlitz',
                textAlign: TextAlign.center,
                style: GoogleFonts.fredoka(
                  fontSize: 42,
                  height: 0.92,
                  color: AppConstants.foamWhite,
                  shadows: const [
                    Shadow(
                        blurRadius: 8,
                        color: Colors.black45,
                        offset: Offset(2, 2)),
                  ],
                ),
              ).animate().fadeIn(duration: 700.ms, delay: 400.ms),
              const SizedBox(height: 24),
              Text(
                'Arcade Bubble Rescue',
                style: GoogleFonts.fredoka(
                  fontSize: 16,
                  color: AppConstants.foamWhite.withValues(alpha: 0.72),
                ),
              ).animate().fadeIn(duration: 700.ms, delay: 1000.ms),
            ],
          ),
        ),
      ),
    );
  }
}

class _SplashBubblePainter extends CustomPainter {
  const _SplashBubblePainter();

  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height / 2);
    canvas.drawCircle(
      c,
      size.width * 0.45,
      Paint()..color = AppConstants.bubbleBlue.withValues(alpha: 0.34),
    );
    canvas.drawCircle(
      c,
      size.width * 0.42,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.9)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4,
    );
    canvas.drawCircle(
      Offset(c.dx - size.width * 0.16, c.dy - size.width * 0.16),
      size.width * 0.1,
      Paint()..color = Colors.white.withValues(alpha: 0.72),
    );
    canvas.drawCircle(
      Offset(c.dx + size.width * 0.18, c.dy + size.width * 0.12),
      size.width * 0.07,
      Paint()..color = AppConstants.accentYellow.withValues(alpha: 0.55),
    );
    final bodyPaint = Paint()..color = AppConstants.heroGreen;
    final glovePaint = Paint()..color = AppConstants.accentYellow;
    final white = Paint()..color = AppConstants.foamWhite;
    final ink = Paint()..color = AppConstants.uiDark;

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(c.dx, c.dy + 18), width: 44, height: 50),
        const Radius.circular(23),
      ),
      bodyPaint,
    );
    canvas.drawOval(
      Rect.fromCenter(center: Offset(c.dx, c.dy + 25), width: 24, height: 28),
      white,
    );
    canvas.drawOval(
      Rect.fromCenter(center: Offset(c.dx, c.dy - 14), width: 54, height: 42),
      bodyPaint,
    );
    for (int i = 0; i < 4; i++) {
      final x = c.dx - 23 + i * 13;
      final spike = Path()
        ..moveTo(x, c.dy - 27)
        ..lineTo(x + 6, c.dy - 43)
        ..lineTo(x + 12, c.dy - 27)
        ..close();
      canvas.drawPath(spike, Paint()..color = AppConstants.accentYellow);
    }
    canvas.drawOval(
      Rect.fromCenter(
          center: Offset(c.dx + 30, c.dy - 5), width: 22, height: 14),
      Paint()..color = const Color(0xFFFFF5C6),
    );
    canvas.drawCircle(Offset(c.dx - 30, c.dy + 12), 10, glovePaint);
    canvas.drawCircle(Offset(c.dx + 30, c.dy + 12), 10, glovePaint);
    canvas.drawOval(Rect.fromLTWH(c.dx - 20, c.dy - 22, 16, 22), white);
    canvas.drawOval(Rect.fromLTWH(c.dx + 4, c.dy - 22, 16, 22), white);
    canvas.drawCircle(Offset(c.dx - 10, c.dy - 11), 5, ink);
    canvas.drawCircle(Offset(c.dx + 14, c.dy - 11), 5, ink);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
