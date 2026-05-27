import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../services/audio_service.dart';
import '../services/save_service.dart';
import '../utils/constants.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  @override
  Widget build(BuildContext context) {
    final save = SaveService.instance;
    return Scaffold(
      backgroundColor: AppConstants.uiDark,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: Text('Settings', style: GoogleFonts.fredoka(color: Colors.white)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => context.go('/menu'),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _toggleTile(
            'Music',
            Icons.music_note,
            save.musicEnabled,
            (v) async {
              await save.setMusicEnabled(v);
              await AudioService.instance.refreshFromSettings();
              setState(() {});
            },
          ),
          _toggleTile(
            'Sound Effects',
            Icons.volume_up,
            save.sfxEnabled,
            (v) async {
              await save.setSfxEnabled(v);
              setState(() {});
            },
          ),
          _toggleTile(
            'Vibration',
            Icons.vibration,
            save.vibrationEnabled,
            (v) async {
              await save.setVibrationEnabled(v);
              setState(() {});
            },
          ),
          const Divider(color: Colors.white24, height: 32),
          ListTile(
            leading: const Icon(Icons.info, color: Colors.white),
            title: Text('Version',
                style: GoogleFonts.fredoka(color: Colors.white)),
            trailing: Text(
              AppConstants.appVersion,
              style: const TextStyle(color: Colors.white70),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.restore, color: Colors.white),
            title: Text(
              'Restore Purchases',
              style: GoogleFonts.fredoka(color: Colors.white),
            ),
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Purchases restored')),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _toggleTile(
      String label, IconData icon, bool value, ValueChanged<bool> onChanged) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      decoration: BoxDecoration(
        color: AppConstants.uiCard,
        borderRadius: BorderRadius.circular(12),
      ),
      child: SwitchListTile(
        title: Text(label, style: GoogleFonts.fredoka(color: Colors.white)),
        secondary: Icon(icon, color: Colors.white),
        value: value,
        activeColor: AppConstants.bubbleBlue,
        onChanged: onChanged,
      ),
    );
  }
}
