import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// A cosmetic theme for Color Match: a 6-color piece palette (always 6 clearly
/// distinct hues so the matching stays playable) plus the background it pairs
/// with. Unlockable with the coins earned from daily bonuses and play.
class SkinCM {
  final String id;
  final String name;
  final int cost; // 0 = free/default
  final List<Color> palette; // exactly 6 distinct piece colors
  final List<Color> bg; // 3: center → mid → edge of the radial background
  final Color bokeh;
  final Color accent; // app bar / highlights

  const SkinCM({
    required this.id,
    required this.name,
    required this.cost,
    required this.palette,
    required this.bg,
    required this.bokeh,
    required this.accent,
  });
}

const skinsCM = <SkinCM>[
  SkinCM(
    id: 'default',
    name: 'Clasic',
    cost: 0,
    palette: [
      Color(0xFFE53935), Color(0xFF1E88E5), Color(0xFF43A047),
      Color(0xFFFFB300), Color(0xFF8E24AA), Color(0xFF00ACC1),
    ],
    bg: [Color(0xFFFCE4EC), Color(0xFFF8BBD0), Color(0xFFF3A5C0)],
    bokeh: Color(0xFFFF80AB),
    accent: Color(0xFFFF4081),
  ),
  SkinCM(
    id: 'neon',
    name: 'Neon',
    cost: 300,
    palette: [
      Color(0xFFFF1744), Color(0xFF00E5FF), Color(0xFF76FF03),
      Color(0xFFFFEA00), Color(0xFFD500F9), Color(0xFFFF9100),
    ],
    bg: [Color(0xFF1A0B2E), Color(0xFF120820), Color(0xFF05030F)],
    bokeh: Color(0xFF00E5FF),
    accent: Color(0xFFD500F9),
  ),
  SkinCM(
    id: 'jewel',
    name: 'Bijuterii',
    cost: 400,
    palette: [
      Color(0xFFC2185B), Color(0xFF1565C0), Color(0xFF2E7D32),
      Color(0xFFF9A825), Color(0xFF6A1B9A), Color(0xFF00838F),
    ],
    bg: [Color(0xFF15233E), Color(0xFF0E1830), Color(0xFF060B1A)],
    bokeh: Color(0xFF64B5F6),
    accent: Color(0xFF1565C0),
  ),
  SkinCM(
    id: 'pastel',
    name: 'Pastel',
    cost: 500,
    palette: [
      Color(0xFFFF8A80), Color(0xFF80D8FF), Color(0xFFB9F6CA),
      Color(0xFFFFE57F), Color(0xFFEA80FC), Color(0xFF84FFFF),
    ],
    bg: [Color(0xFF2E2A45), Color(0xFF211E33), Color(0xFF13111F)],
    bokeh: Color(0xFFEA80FC),
    accent: Color(0xFFB388FF),
  ),
  SkinCM(
    id: 'candy',
    name: 'Bomboane',
    cost: 700,
    palette: [
      Color(0xFFFF5C8D), Color(0xFF42A5F5), Color(0xFF66BB6A),
      Color(0xFFFFCA28), Color(0xFFAB47BC), Color(0xFF26C6DA),
    ],
    bg: [Color(0xFF3A1430), Color(0xFF2A0E24), Color(0xFF170614)],
    bokeh: Color(0xFFFF80AB),
    accent: Color(0xFFFF5C8D),
  ),
];

SkinCM skinCMById(String id) =>
    skinsCM.firstWhere((s) => s.id == id, orElse: () => skinsCM.first);

/// Persistent skin/coin store. Coins share the existing `cmCoins` key so the
/// daily bonus (RewardsService) and the shop draw from one wallet.
class SkinStore extends ChangeNotifier {
  SkinStore._();
  static final SkinStore instance = SkinStore._();

  static const _kCoins = 'cmCoins';
  static const _kEquipped = 'cm_equipped';
  static const _kUnlocked = 'cm_unlocked';

  SharedPreferences? _p;
  bool _ready = false;

  Future<void> init() async {
    if (_ready) return;
    _p = await SharedPreferences.getInstance();
    _ready = true;
  }

  int get coins => _p?.getInt(_kCoins) ?? 50;

  void reload() => notifyListeners();

  Future<void> addCoins(int n) async {
    await _p?.setInt(_kCoins, coins + n);
    notifyListeners();
  }

  Future<bool> spend(int n) async {
    if (coins < n) return false;
    await _p?.setInt(_kCoins, coins - n);
    notifyListeners();
    return true;
  }

  Set<String> get unlocked =>
      (_p?.getStringList(_kUnlocked) ?? const <String>[]).toSet()..add('default');

  bool isUnlocked(String id) => id == 'default' || unlocked.contains(id);

  Future<void> unlock(String id) async {
    final s = unlocked..add(id);
    await _p?.setStringList(_kUnlocked, s.toList());
    notifyListeners();
  }

  String get equippedId => _p?.getString(_kEquipped) ?? 'default';

  Future<void> equip(String id) async {
    await _p?.setString(_kEquipped, id);
    notifyListeners();
  }
}

/// The currently equipped Color Match theme (synchronous, safe during paint).
SkinCM activeSkinCM() => skinCMById(SkinStore.instance.equippedId);
