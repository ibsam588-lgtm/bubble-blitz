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
              AppConstants.bubbleBlue,
              AppConstants.bubblePurple,
            ],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('🫧', style: TextStyle(fontSize: 96))
                  .animate()
                  .scale(duration: 700.ms, curve: Curves.elasticOut)
                  .then()
                  .shake(duration: 600.ms),
              const SizedBox(height: 16),
              Text(
                'Bubble Blitz',
                style: GoogleFonts.fredoka(
                  fontSize: 48,
                  color: Colors.white,
                  shadows: const [
                    Shadow(blurRadius: 8, color: Colors.black45, offset: Offset(2, 2)),
                  ],
                ),
              ).animate().fadeIn(duration: 700.ms, delay: 400.ms),
              const SizedBox(height: 24),
              Text(
                'by Corsair Labs',
                style: GoogleFonts.fredoka(
                  fontSize: 16,
                  color: Colors.white70,
                ),
              ).animate().fadeIn(duration: 700.ms, delay: 1000.ms),
            ],
          ),
        ),
      ),
    );
  }
}
