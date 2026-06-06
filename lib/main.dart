import 'package:flutter/material.dart';
import 'pages/home_page.dart';
import 'pages/admin_page.dart';
import 'pages/adviser_page.dart';
import 'pages/student_page.dart';
import 'pages/login_page.dart';
import 'pages/signup_page.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Web-Based Capstone Project Monitoring System',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
        primaryColor: Colors.indigo,
        appBarTheme: const AppBarTheme(centerTitle: true, elevation: 2),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            minimumSize: const Size.fromHeight(48),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 14,
          ),
        ),
        // cardTheme left default to avoid SDK compatibility issues
        scaffoldBackgroundColor: Colors.grey.shade50,
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => const HomePage(),
        '/admin': (context) => const AdminPage(),
        '/adviser': (context) => const AdviserPage(),
        '/student': (context) => const StudentPage(),
        '/login': (context) => const LoginPage(),
        '/signup': (context) => const SignupPage(),
      },
    );
  }
}
