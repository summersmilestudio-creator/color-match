import 'package:flutter/material.dart';
import '../services/rewards_service.dart';
import '../services/purchase_service.dart';

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

  Future<void> _showRemoveAdsDialog() async {
    final price =
        PurchaseService.instance.productFor(PurchaseService.noAdsId)?.price ?? '15 lei';
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Text('Fără reclame',
            style: TextStyle(color: Color(0xFFFF4081), fontWeight: FontWeight.w900)),
        content: const Text(
            'Elimină toate reclamele (bannere și reclame care te întrerup) pentru totdeauna. Plată unică.'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              PurchaseService.instance.restore();
            },
            child: const Text('Restaurează',
                style: TextStyle(color: Color(0xFFFF4081))),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF4081),
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              Navigator.of(ctx).pop();
              final result =
                  await PurchaseService.instance.buy(PurchaseService.noAdsId);
              if (!mounted) return;
              final msg = result.message;
              if (msg != null) {
                ScaffoldMessenger.of(context)
                    .showSnackBar(SnackBar(content: Text(msg)));
              }
            },
            child: Text('Cumpără • $price',
                style: const TextStyle(fontWeight: FontWeight.w900)),
          ),
        ],
      ),
    );
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
          ValueListenableBuilder<bool>(
            valueListenable: PurchaseService.instance.noAdsNotifier,
            builder: (context, noAds, _) => Card(
              child: ListTile(
                leading: const Icon(Icons.block, color: Color(0xFFFF4081)),
                title: const Text('Fără reclame'),
                subtitle: Text(noAds
                    ? 'Reclamele sunt eliminate. Mulțumim!'
                    : 'Elimină toate reclamele definitiv'),
                trailing: noAds
                    ? const Icon(Icons.check_circle, color: Colors.green)
                    : const Icon(Icons.chevron_right, color: Color(0xFFFF4081)),
                onTap: noAds ? null : _showRemoveAdsDialog,
              ),
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
