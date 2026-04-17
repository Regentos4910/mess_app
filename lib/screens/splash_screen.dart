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
  double _opacity = 0.0;

  @override
  void initState() {
    super.initState();
    _startAnimation();
    _checkAuth();
  }

  void _startAnimation() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) setState(() => _opacity = 1.0);
    });
  }

  Future<void> _checkAuth() async {
    // Wait a tiny bit for the UI to settle
    await Future.delayed(const Duration(milliseconds: 2000));

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
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // Main Logo Content
          Center(
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 800),
              opacity: _opacity,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    height: 140,
                    width: 140,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.08),
                          blurRadius: 30,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(70),
                      child: Image.asset(
                        'assets/appLogo.jpg',
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => 
                          const Icon(Icons.restaurant_rounded, size: 80, color: Colors.blueAccent),
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  const SizedBox(
                    width: 40,
                    child: LinearProgressIndicator(
                      backgroundColor: Color(0xFFF0F0F0),
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.blueAccent),
                      minHeight: 2,
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          // Branding Footer
          Positioned(
            bottom: 40,
            left: 0,
            right: 0,
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 1200),
              opacity: _opacity,
              child: Column(
                children: [
                  Text(
                    'BEYONDEV',
                    style: TextStyle(
                      letterSpacing: 4,
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                      color: Colors.grey.shade400,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'We Tech up your Business',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey.shade300,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}