import 'package:shared_preferences/shared_preferences.dart';

class RewardsService {
  static const _kCoinsKey = 'cmCoins';
  static const _kLastLoginKey = 'cmLastLogin';
  static const _kStreakKey = 'cmStreak';
  static const dailyRewards = [10, 15, 25, 40, 60, 90, 150];

  Future<int> getCoins() async {
    final p = await SharedPreferences.getInstance();
    return p.getInt(_kCoinsKey) ?? 50;
  }

  Future<void> addCoins(int n) async {
    final p = await SharedPreferences.getInstance();
    await p.setInt(_kCoinsKey, await getCoins() + n);
  }

  Future<({int day, int reward})> claimDailyIfAvailable() async {
    final p = await SharedPreferences.getInstance();
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final lastEpoch = p.getInt(_kLastLoginKey);
    final streak = p.getInt(_kStreakKey) ?? 0;
    if (lastEpoch != null) {
      final last = DateTime.fromMillisecondsSinceEpoch(lastEpoch);
      final lastDay = DateTime(last.year, last.month, last.day);
      if (lastDay.isAtSameMomentAs(today)) return (day: streak, reward: 0);
      final diff = today.difference(lastDay).inDays;
      final newStreak = (diff == 1 ? streak + 1 : 1).clamp(1, 7);
      final reward = dailyRewards[newStreak - 1];
      await addCoins(reward);
      await p.setInt(_kLastLoginKey, today.millisecondsSinceEpoch);
      await p.setInt(_kStreakKey, newStreak);
      return (day: newStreak, reward: reward);
    }
    final reward = dailyRewards[0];
    await addCoins(reward);
    await p.setInt(_kLastLoginKey, today.millisecondsSinceEpoch);
    await p.setInt(_kStreakKey, 1);
    return (day: 1, reward: reward);
  }
}

class SettingsService {
  Future<bool> soundOn() async => (await SharedPreferences.getInstance()).getBool('cm_sound') ?? true;
  Future<bool> hapticOn() async => (await SharedPreferences.getInstance()).getBool('cm_haptic') ?? true;
  Future<void> setSound(bool v) async => (await SharedPreferences.getInstance()).setBool('cm_sound', v);
  Future<void> setHaptic(bool v) async => (await SharedPreferences.getInstance()).setBool('cm_haptic', v);
}
