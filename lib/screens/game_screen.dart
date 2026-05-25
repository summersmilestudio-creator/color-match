import 'dart:math';
import 'package:flutter/material.dart';
import '../widgets/banner_ad_widget.dart';
import '../services/ads_service.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

const int kCols = 8;
const int kRows = 10;
const _palette = [
  Color(0xFFE53935),
  Color(0xFF1E88E5),
  Color(0xFF43A047),
  Color(0xFFFFB300),
  Color(0xFF8E24AA),
  Color(0xFF00ACC1),
];

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
        List.generate(kCols, (_) => _rng.nextInt(_palette.length)));
    _score = 0;
    _moves = 30;
  }

  // Find connected blob from (r,c)
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
      Future.delayed(const Duration(milliseconds: 300), () {
        if (!mounted) return;
        AdsService.instance.maybeShowInterstitial();
        showDialog(
          context: context,
          builder: (c) => AlertDialog(
            title: const Text('Joc terminat'),
            content: Text('Scor final: $_score${_score == _high ? "\n🏆 Record nou!" : ""}'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(c);
                  setState(() => _newGame());
                },
                child: const Text('Joc nou'),
              ),
            ],
          ),
        );
      });
    }
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
        if (_grid[r][c] == -1) _grid[r][c] = _rng.nextInt(_palette.length);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      bottomNavigationBar: const BannerAdWidget(),
      appBar: AppBar(
        title: const Text('Color Match'),
        backgroundColor: const Color(0xFFFF4081),
        foregroundColor: Colors.white,
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: () => setState(() => _newGame())),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _stat('SCOR', '$_score', const Color(0xFFFF4081)),
                  _stat('TOP', '$_high', const Color(0xFFE91E63)),
                  _stat('MUTĂRI', '$_moves', const Color(0xFFAD1457)),
                ],
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: AspectRatio(
                  aspectRatio: kCols / kRows,
                  child: GridView.builder(
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
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
                            color: v == -1 ? Colors.transparent : _palette[v],
                            borderRadius: BorderRadius.circular(8),
                            boxShadow: v >= 0
                                ? const [BoxShadow(color: Colors.black12, blurRadius: 2, offset: Offset(0, 1))]
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
                  style: TextStyle(color: Colors.black54, fontSize: 12)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _stat(String label, String value, Color color) {
    return Column(
      children: [
        Text(label, style: const TextStyle(color: Colors.black54, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 1)),
        Text(value, style: TextStyle(color: color, fontSize: 24, fontWeight: FontWeight.w900)),
      ],
    );
  }
}
