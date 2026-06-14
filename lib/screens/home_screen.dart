import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../game/skins.dart';
import '../services/rewards_service.dart';
import '../widgets/banner_ad_widget.dart';
import '../widgets/game_juice.dart';
import 'daily_reward_screen.dart';
import 'game_screen.dart';
import 'settings_screen.dart';
import 'shop_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _rewards = RewardsService();
  int _highScore = 0;

  @override
  void initState() {
    super.initState();
    _checkDaily();
  }

  Future<void> _checkDaily() async {
    final r = await _rewards.claimDailyIfAvailable();
    if (r.reward > 0 && mounted) {
      await Navigator.push(context, MaterialPageRoute(
          builder: (_) => DailyRewardScreen(day: r.day, reward: r.reward)));
    }
    SkinStore.instance.reload();
    _load();
  }

  Future<void> _load() async {
    final p = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() => _highScore = p.getInt('colorMatchHigh') ?? 0);
    }
  }

  @override
  Widget build(BuildContext context) {
    final skin = activeSkinCM();
    final dark = skin.bg.first.computeLuminance() < 0.5;
    final fg = dark ? Colors.white : const Color(0xFF6A1B4A);
    return Scaffold(
      bottomNavigationBar: const BannerAdWidget(),
      body: PremiumBackground(
        colors: skin.bg,
        bokeh: skin.bokeh,
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: Icon(Icons.settings, color: fg),
                      onPressed: () async {
                        await Navigator.push(context,
                            MaterialPageRoute(builder: (_) => const SettingsScreen()));
                      },
                    ),
                    Row(
                      children: [
                        PressableScale(
                          onTap: () async {
                            await Navigator.push(context,
                                MaterialPageRoute(builder: (_) => const ShopScreen()));
                            setState(() {});
                          },
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: skin.accent,
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: const Icon(Icons.palette_rounded,
                                color: Colors.white, size: 22),
                          ),
                        ),
                        const SizedBox(width: 10),
                        ListenableBuilder(
                          listenable: SkinStore.instance,
                          builder: (context, _) => Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: skin.accent),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.monetization_on,
                                    color: Color(0xFFFFAB00), size: 20),
                                const SizedBox(width: 6),
                                Text('${SkinStore.instance.coins}',
                                    style: TextStyle(
                                        color: skin.accent,
                                        fontSize: 16,
                                        fontWeight: FontWeight.w900)),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const Spacer(),
                ShaderMask(
                  shaderCallback: (r) => LinearGradient(
                    colors: [skin.accent, skin.palette[4]],
                  ).createShader(r),
                  child: const Text('COLOR\nMATCH',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          fontSize: 60,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          letterSpacing: 4,
                          height: 1.0)),
                ),
                const SizedBox(height: 12),
                Text('Apasă pe 3+ piese conectate de aceeași culoare',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: fg.withValues(alpha: 0.85))),
                const SizedBox(height: 28),
                _paletteRow(skin),
                const SizedBox(height: 28),
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: dark ? Colors.white.withValues(alpha: 0.08) : Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: skin.accent),
                    boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 6)],
                  ),
                  child: Column(
                    children: [
                      Text('TOP SCORE',
                          style: TextStyle(
                              color: fg.withValues(alpha: 0.7), fontSize: 12, letterSpacing: 2)),
                      const SizedBox(height: 6),
                      Text('$_highScore',
                          style: TextStyle(
                              color: dark ? Colors.white : skin.accent,
                              fontSize: 40,
                              fontWeight: FontWeight.w900)),
                    ],
                  ),
                ),
                const Spacer(),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: skin.accent,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      textStyle: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      elevation: 6,
                    ),
                    onPressed: () async {
                      await Navigator.push(context,
                          MaterialPageRoute(builder: (_) => const GameScreen()));
                      SkinStore.instance.reload();
                      _load();
                    },
                    child: const Text('JOC NOU'),
                  ),
                ),
                const SizedBox(height: 60),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _paletteRow(SkinCM skin) {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      alignment: WrapAlignment.center,
      children: [
        for (final c in skin.palette)
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: c,
              borderRadius: BorderRadius.circular(10),
              boxShadow: [BoxShadow(color: c.withValues(alpha: 0.6), blurRadius: 10)],
            ),
          ),
      ],
    );
  }
}
