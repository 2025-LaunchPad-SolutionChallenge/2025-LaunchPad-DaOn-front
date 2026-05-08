import 'package:flutter/material.dart';
import 'common/switchPage.dart';
import 'onboarding/view/main.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'DAON app',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.white),
      ),
      // home: SwitchPage(),
      home: OnboardingPage(),
    );
  }
}
