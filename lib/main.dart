import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:google_sign_in/google_sign_in.dart';

import 'package:project_daon/firebase_options.dart';
import 'package:project_daon/login/view/main.dart';

import 'common/switchPage.dart';
import 'onboarding/view/onboardingController.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // google_sign_in 7.x 기준 초기화
  await GoogleSignIn.instance.initialize();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'DAON app',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.white),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent,
          elevation: 0,
          centerTitle: true,
        ),
      ),

      // 로그인 성공 후 Navigator.pushReplacementNamed()로 이동할 수 있게 route 등록
      initialRoute: '/login',
      routes: {
        '/login': (context) => const LoginPage(),
        '/onboarding': (context) => OnboardingController(),
        '/home': (context) => SwitchPage(),
      },
    );
  }
}
