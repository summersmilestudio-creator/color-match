import 'dart:math';
import 'package:flutter/material.dart';
import '../game/skins.dart';
import '../widgets/banner_ad_widget.dart';
import '../widgets/game_juice.dart';
import '../services/ads_service.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

const int kCols = 8;
const int kRows = 10;
const int kColors = 6;

class GameScreen extends StatefulWidget {
  const GameScreen({super.key});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  late List<List<int>> _grid; // -1 empty
  int _score = 0;
  int _high = 0;
  int _moves = 30;
  bool _coinsAwarded = false;
  final _rng = Random();

  @override
  void initState() {
    super.initState();
    _newGame();
    _load();
  }

  Future<void> _load() async {
    final p = await SharedPreferences.getInstance();
    setState(() => _high = p.getInt('colorMatchHigh') ?? 0);
  }

  Future<void> _saveHigh() async {
    if (_score > _high) {
      _high = _score;
      final p = await SharedPreferences.getInstance();
      await p.setInt('colorMatchHigh', _high);
    }
  }

  void _newGame() {
    _grid = List.generate(kRows, (_) =>
        List.generate(kCols, (_) => _rng.nextInt(kColors)));
    _score = 0;
    _moves = 30;
    _coinsAwarded = false;
  }

  Set<Point<int>> _findBlob(int r, int c, int color) {
    final visited = <Point<int>>{};
    final stack = [Point(c, r)];
    while (stack.isNotEmpty) {
      final p = stack.removeLast();
      if (visited.contains(p)) continue;
      if (p.y < 0 || p.y >= kRows || p.x < 0 || p.x >= kCols) continue;
      if (_grid[p.y][p.x] != color) continue;
      visited.add(p);
      stack.add(Point(p.x + 1, p.y));
      stack.add(Point(p.x - 1, p.y));
      stack.add(Point(p.x, p.y + 1));
      stack.add(Point(p.x, p.y - 1));
    }
    return visited;
  }

  void _onTap(int r, int c) {
    final color = _grid[r][c];
    if (color < 0 || _moves <= 0) return;
    final blob = _findBlob(r, c, color);
    if (blob.length < 3) return;
    HapticFeedback.mediumImpact();
    if (blob.length >= 6) Celebrate.show(context);
    setState(() {
      for (final p in blob) {
        _grid[p.y][p.x] = -1;
      }
      _score += blob.length * blob.length;
      _moves--;
      _gravity();
      _refill();
    });
    _saveHigh();
    if (_moves == 0) {
      final earned = (_score ~/ 100).clamp(0, 999);
      if (!_coinsAwarded) {
        _coinsAwarded = true;
        if (earned > 0) SkinStore.instance.addCoins(earned);
      }
      Future.delayed(const Duration(milliseconds: 300), () {
        if (!mounted) return;
        AdsService.instance.maybeShowInterstitial();
        showDialog(
          context: context,
          builder: (c) => AlertDialog(
            title: const Text('Joc terminat'),
            content: Text('Scor final: $_score${_score == _high ? "\n🏆 Record nou!" : ""}\n+$earned monede 🪙'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(c);
                  setState(() => _newGame());
                },
                child: const Text('Joc nou'),
              ),
              TextButton.icon(
                icon: const Icon(Icons.play_circle, color: Color(0xFFFFD740)),
                label: const Text('+15 mutări 🎁',
                    style: TextStyle(color: Color(0xFFFFD740))),
                onPressed: () async {
                  Navigator.pop(c);
                  await _watchAdForBonusMoves();
                },
              ),
            ],
          ),
        );
      });
    }
  }

  Future<void> _watchAdForBonusMoves() async {
    final got = await AdsService.instance.showBonusAd();
    if (!mounted || !got) return;
    setState(() {
      _moves += 15;
      _coinsAwarded = false;
    });
    final p = await SharedPreferences.getInstance();
    final cur = p.getInt('colorMax') ?? 0;
    await p.setInt('colorMax', cur + 2);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('🎁 +15 mutări adăugate! Continuă să joci.'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  Future<void> _watchAdToSkip() async {
    final got = await AdsService.instance.showBonusAd();
    if (!mounted || !got) return;
    setState(() => _moves += 10);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('⏭️ +10 mutări bonus!'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _gravity() {
    for (var c = 0; c < kCols; c++) {
      var write = kRows - 1;
      for (var r = kRows - 1; r >= 0; r--) {
        if (_grid[r][c] != -1) {
          _grid[write][c] = _grid[r][c];
          if (write != r) _grid[r][c] = -1;
          write--;
        }
      }
    }
  }

  void _refill() {
    for (var r = 0; r < kRows; r++) {
      for (var c = 0; c < kCols; c++) {
        if (_grid[r][c] == -1) _grid[r][c] = _rng.nextInt(kColors);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final skin = activeSkinCM();
    final palette = skin.palette;
    return Scaffold(
      bottomNavigationBar: const BannerAdWidget(),
      appBar: AppBar(
        title: const Text('Color Match'),
        backgroundColor: skin.accent,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            tooltip: '+10 mutări (urmărește reclamă)',
            icon: const Icon(Icons.skip_next, color: Color(0xFF69F0AE)),
            onPressed: _watchAdToSkip,
          ),
          IconButton(icon: const Icon(Icons.refresh), onPressed: () => setState(() => _newGame())),
        ],
      ),
      body: PremiumBackground(
        colors: skin.bg,
        bokeh: skin.bokeh,
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _stat('SCOR', '$_score'),
                    _stat('TOP', '$_high'),
                    _stat('MUTĂRI', '$_moves'),
                  ],
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: AspectRatio(
                    aspectRatio: kCols / kRows,
                    child: GridView.builder(
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: kCols,
                        childAspectRatio: 1,
                        crossAxisSpacing: 3,
                        mainAxisSpacing: 3,
                      ),
                      itemCount: kRows * kCols,
                      physics: const NeverScrollableScrollPhysics(),
                      itemBuilder: (ctx, i) {
                        final r = i ~/ kCols;
                        final c = i % kCols;
                        final v = _grid[r][c];
                        return GestureDetector(
                          onTap: () => _onTap(r, c),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 150),
                            decoration: BoxDecoration(
                              gradient: v == -1
                                  ? null
                                  : LinearGradient(
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                      colors: [
                                        Color.lerp(palette[v], Colors.white, 0.22)!,
                                        palette[v],
                                      ],
                                    ),
                              color: v == -1 ? Colors.white.withValues(alpha: 0.04) : null,
                              borderRadius: BorderRadius.circular(8),
                              boxShadow: v >= 0
                                  ? [BoxShadow(color: palette[v].withValues(alpha: 0.45), blurRadius: 4, offset: const Offset(0, 1))]
                                  : null,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),
              const Padding(
                padding: EdgeInsets.all(12),
                child: Text('Apasă pe 3+ piese conectate de aceeași culoare',
                    style: TextStyle(color: Colors.white70, fontSize: 12)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _stat(String label, String value) {
    return Column(
      children: [
        Text(label, style: const TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 1)),
        Text(value, style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900)),
      ],
    );
  }
}
