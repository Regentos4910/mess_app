import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:mess_app/screens/export_screen.dart';

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
  
  // Initialize Firebase if not already done
  if (Firebase.apps.isEmpty) {
    await Firebase.initializeApp();
  }
  
  final AppController controller = AppController();
  
  // Initialize controller (this checks Firebase Auth state internally)
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
      title: 'Mess Manager',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blueAccent,
          brightness: Brightness.light,
        ),
        scaffoldBackgroundColor: Colors.white,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          elevation: 0,
          centerTitle: true,
          titleTextStyle: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.w900,
            fontSize: 20,
          ),
        ),
      ),
      // Splash screen is the entry point
      initialRoute: '/', 
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
        '/export-data': (context) => ExportScreen(controller: controller),
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