import 'package:flutter/material.dart';
import '../services/rewards_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _settings = SettingsService();
  bool _sound = true;
  bool _haptic = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final s = await _settings.soundOn();
    final h = await _settings.hapticOn();
    if (mounted) setState(() { _sound = s; _haptic = h; });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFCE4EC),
      appBar: AppBar(
        title: const Text('Setări'),
        backgroundColor: const Color(0xFFFF4081),
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: SwitchListTile(
              activeColor: const Color(0xFFFF4081),
              title: const Text('Sunet'),
              subtitle: const Text('Efecte sonore în joc'),
              value: _sound,
              onChanged: (v) async {
                await _settings.setSound(v);
                setState(() => _sound = v);
              },
              secondary: const Icon(Icons.volume_up, color: Color(0xFFFF4081)),
            ),
          ),
          Card(
            child: SwitchListTile(
              activeColor: const Color(0xFFFF4081),
              title: const Text('Vibrații'),
              subtitle: const Text('Haptic feedback'),
              value: _haptic,
              onChanged: (v) async {
                await _settings.setHaptic(v);
                setState(() => _haptic = v);
              },
              secondary: const Icon(Icons.vibration, color: Color(0xFFFF4081)),
            ),
          ),
          const Card(
            child: ListTile(
              leading: Icon(Icons.info_outline, color: Color(0xFFFF4081)),
              title: Text('Versiune'),
              subtitle: Text('1.1.0'),
            ),
          ),
          const Card(
            child: ListTile(
              leading: Icon(Icons.business, color: Color(0xFFFF4081)),
              title: Text('Publisher'),
              subtitle: Text('Summer Smile SRL'),
            ),
          ),
        ],
      ),
    );
  }
}
