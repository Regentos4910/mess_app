import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'screens/add_student_screen.dart';
import 'screens/attendance_history_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/login_screen.dart';
import 'screens/manage_subscription_screen.dart';
import 'screens/scan_screen.dart';
import 'screens/splash_screen.dart';
import 'screens/student_profile_screen.dart';
import 'services/app_controller.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (Firebase.apps.isEmpty) {
    await Firebase.initializeApp();
  }
  final AppController controller = AppController();
  await controller.initialize();
  runApp(MyApp(controller: controller));
}

class MyApp extends StatelessWidget {
  const MyApp({
    required this.controller,
    super.key,
  });

  final AppController controller;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Mess App',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF0F766E),
          brightness: Brightness.light,
        ),
        scaffoldBackgroundColor: const Color(0xFFF3FBF9),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFFF3FBF9),
          elevation: 0,
        ),
        cardTheme: CardThemeData(
          color: Colors.white,
          margin: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 16,
          ),
        ),
        useMaterial3: true,
      ),
      routes: <String, WidgetBuilder>{
        '/': (_) => SplashScreen(controller: controller),
        LoginScreen.routeName: (_) => LoginScreen(controller: controller),
        DashboardScreen.routeName: (_) => DashboardScreen(controller: controller),
        AddStudentScreen.routeName: (_) => AddStudentScreen(controller: controller),
        ScanScreen.routeName: (_) => ScanScreen(controller: controller),
        ManageSubscriptionScreen.routeName: (_) =>
            ManageSubscriptionScreen(controller: controller),
        AttendanceHistoryScreen.routeName: (_) =>
            AttendanceHistoryScreen(controller: controller),
      },
      onGenerateRoute: (RouteSettings settings) {
        if (settings.name == StudentProfileScreen.routeName) {
          final String studentId = settings.arguments! as String;
          return MaterialPageRoute<void>(
            builder: (_) => StudentProfileScreen(
              controller: controller,
              studentId: studentId,
            ),
          );
        }
        return null;
      },
    );
  }
}
