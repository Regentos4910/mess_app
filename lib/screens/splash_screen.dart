import 'package:flutter/material.dart';
import '../services/app_controller.dart';
import 'dashboard_screen.dart';
import 'login_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({required this.controller, super.key});
  final AppController controller;

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkAuth();
  }

  Future<void> _checkAuth() async {
    // Wait a tiny bit for the UI to settle
    await Future.delayed(const Duration(milliseconds: 1500));

    if (!mounted) return;

    // Logic: Check Firebase Auth persistence
    final user = widget.controller.firebaseService.currentUser;

    if (user != null) {
      // User is already logged in, go to Dashboard
      Navigator.of(context).pushReplacementNamed(DashboardScreen.routeName);
    } else {
      // No user found, go to Login
      Navigator.of(context).pushReplacementNamed(LoginScreen.routeName);
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.restaurant_menu_rounded, size: 80, color: Colors.blueAccent),
            SizedBox(height: 24),
            CircularProgressIndicator(strokeWidth: 2),
          ],
        ),
      ),
    );
  }
}