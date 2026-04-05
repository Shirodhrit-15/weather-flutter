// ignore_for_file: unused_import

import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:weather_app/pages/login_page.dart';
import 'package:weather_app/pages/weather_screen.dart';
import 'package:weather_app/pages/register_pgae.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized(); // 🔥 required
  await Firebase.initializeApp(); // 🔥 initialize Firebase

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark(useMaterial3: true),

      // 👇 start with login page
      home: const LoginPage(),

      // 👇 optional but useful navigation routes
      routes: {
        '/login': (context) => const LoginPage(),
        '/home': (context) => const WeatherScreen(),
        '/register': (context) => const RegisterPage(),
      },
    );
  }
}
