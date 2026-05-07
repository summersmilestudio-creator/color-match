import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/rewards_service.dart';
import 'daily_reward_screen.dart';
import 'game_screen.dart';
import 'settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _rewards = RewardsService();
  int _coins = 0;
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
    _load();
  }

  Future<void> _load() async {
    final c = await _rewards.getCoins();
    final p = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        _coins = c;
        _highScore = p.getInt('colorMatchHigh') ?? 0;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFFCE4EC), Color(0xFFF8BBD0), Color(0xFFFCE4EC)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.settings, color: Color(0xFFFF4081)),
                      onPressed: () async {
                        await Navigator.push(context,
                            MaterialPageRoute(builder: (_) => const SettingsScreen()));
                      },
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: const Color(0xFFFF4081)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.monetization_on, color: Color(0xFFFFAB00), size: 20),
                          const SizedBox(width: 6),
                          Text('$_coins',
                              style: const TextStyle(
                                  color: Color(0xFFFF4081),
                                  fontSize: 16,
                                  fontWeight: FontWeight.w900)),
                        ],
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                ShaderMask(
                  shaderCallback: (r) => const LinearGradient(
                    colors: [Color(0xFFFF4081), Color(0xFF7B1FA2)],
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
                const Text('Apasă pe 3+ piese conectate de aceeași culoare',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.black54)),
                const SizedBox(height: 32),
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFFF4081)),
                    boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 6)],
                  ),
                  child: Column(
                    children: [
                      const Text('TOP SCORE',
                          style: TextStyle(color: Colors.black54, fontSize: 12, letterSpacing: 2)),
                      const SizedBox(height: 6),
                      Text('$_highScore',
                          style: const TextStyle(
                              color: Color(0xFFFF4081),
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
                      backgroundColor: const Color(0xFFFF4081),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      textStyle: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      elevation: 6,
                    ),
                    onPressed: () async {
                      await Navigator.push(context,
                          MaterialPageRoute(builder: (_) => const GameScreen()));
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
}
