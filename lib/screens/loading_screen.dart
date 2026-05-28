import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../utils/constants.dart';

class LoadingScreen extends StatelessWidget {
  const LoadingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppConstants.uiDark,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(color: AppConstants.heroGreen),
            const SizedBox(height: 20),
            Text(
              'Loading hero bubbles...',
              style: GoogleFonts.fredoka(
                color: AppConstants.foamWhite,
                fontSize: 18,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
