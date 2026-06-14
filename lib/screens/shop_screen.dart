import 'package:flutter/material.dart';
import '../game/skins.dart';
import '../widgets/game_juice.dart';

/// Theme shop: spend earned coins to unlock & equip color themes.
class ShopScreen extends StatefulWidget {
  const ShopScreen({super.key});

  @override
  State<ShopScreen> createState() => _ShopScreenState();
}

class _ShopScreenState extends State<ShopScreen> {
  Future<void> _onTapSkin(SkinCM skin) async {
    final store = SkinStore.instance;
    if (store.isUnlocked(skin.id)) {
      await store.equip(skin.id);
      setState(() {});
      return;
    }
    if (store.coins < skin.cost) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(
              'Îți mai trebuie ${skin.cost - store.coins} monede. Joacă și revino zilnic pentru bonus! 🪙'),
          duration: const Duration(seconds: 2)));
      return;
    }
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: Text('Cumperi tema "${skin.name}"?'),
        content: Text('Cost: ${skin.cost} monede.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(c, false), child: const Text('Nu')),
          TextButton(
              onPressed: () => Navigator.pop(c, true),
              child: const Text('Cumpără')),
        ],
      ),
    );
    if (ok != true) return;
    if (await store.spend(skin.cost)) {
      await store.unlock(skin.id);
      await store.equip(skin.id);
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final store = SkinStore.instance;
    final active = activeSkinCM();
    return Scaffold(
      body: PremiumBackground(
        colors: active.bg,
        bokeh: active.bokeh,
        child: SafeArea(
          child: Column(
            children: [
              Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                  ),
                  const Text('Magazin Teme',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w800)),
                  const Spacer(),
                  ListenableBuilder(
                    listenable: store,
                    builder: (context, _) => Container(
                      margin: const EdgeInsets.only(right: 12),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.25),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.monetization_on_rounded,
                              color: Color(0xFFFFD740), size: 20),
                          const SizedBox(width: 6),
                          Text('${store.coins}',
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 15)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              Expanded(
                child: ListenableBuilder(
                  listenable: store,
                  builder: (context, _) => GridView.builder(
                    padding: const EdgeInsets.all(16),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 0.82,
                      crossAxisSpacing: 14,
                      mainAxisSpacing: 14,
                    ),
                    itemCount: skinsCM.length,
                    itemBuilder: (ctx, i) {
                      final skin = skinsCM[i];
                      return _SkinCard(
                        skin: skin,
                        unlocked: store.isUnlocked(skin.id),
                        equipped: store.equippedId == skin.id,
                        onTap: () => _onTapSkin(skin),
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SkinCard extends StatelessWidget {
  final SkinCM skin;
  final bool unlocked;
  final bool equipped;
  final VoidCallback onTap;
  const _SkinCard({
    required this.skin,
    required this.unlocked,
    required this.equipped,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: const Alignment(0, -0.4),
            radius: 1.2,
            colors: skin.bg,
          ),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: equipped ? skin.accent : Colors.white.withValues(alpha: 0.12),
            width: equipped ? 3 : 1.5,
          ),
        ),
        padding: const EdgeInsets.all(14),
        child: Column(
          children: [
            Text(skin.name,
                style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 15)),
            const SizedBox(height: 12),
            Expanded(child: Center(child: _palettePreview())),
            const SizedBox(height: 12),
            _actionChip(),
          ],
        ),
      ),
    );
  }

  Widget _palettePreview() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      alignment: WrapAlignment.center,
      children: [
        for (final c in skin.palette)
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: c,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(color: c.withValues(alpha: 0.6), blurRadius: 6),
              ],
            ),
          ),
      ],
    );
  }

  Widget _actionChip() {
    if (equipped) return _chip('Echipat ✓', skin.accent, Colors.white);
    if (unlocked) {
      return _chip('Echipează', Colors.white.withValues(alpha: 0.15), Colors.white);
    }
    return _chip('${skin.cost} 🪙', const Color(0xFFFFD740), Colors.black);
  }

  Widget _chip(String label, Color bg, Color fg) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 9),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(label,
          textAlign: TextAlign.center,
          style: TextStyle(color: fg, fontWeight: FontWeight.w800)),
    );
  }
}
