import 'package:flutter/material.dart';
import 'screens/home_screen.dart';
import 'services/ads_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AdsService.instance.initialize();
  runApp(const ColorMatchApp());
}

class ColorMatchApp extends StatelessWidget {
  const ColorMatchApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Color Match',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFFFF4081)),
        scaffoldBackgroundColor: const Color(0xFFFCE4EC),
      ),
      home: const HomeScreen(),
    );
  }
}
