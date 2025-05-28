import 'package:attendance_app/firebase_options.dart';
import 'package:attendance_app/screen/employee_login_page.dart';
import 'package:attendance_app/screen/employee_master.dart';
import 'package:attendance_app/screen/employee_profiles.dart';
import 'package:attendance_app/screen/home_page.dart';
import 'package:attendance_app/screen/admin_login_page.dart';
import 'package:attendance_app/screen/mark_attendance.dart';
import 'package:attendance_app/widget_tree.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const AttendanceApp());
}

class AttendanceApp extends StatelessWidget {
  const AttendanceApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Cloud9 Attendance Management',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      // home: const WidgetTree(),
      routes: {
        '/': (context) => const WidgetTree(),
        '/adminLogin': (context) => const AdminLoginPage(),
        '/employeeLogin': (context) => const EmployeeLoginPage(),
        '/home': (context) => const HomePage(),
        '/employeeProfiles': (context) => const EmployeeProfiles(),
        '/employeeMaster': (context) => const EmployeeMaster(),
        '/markAttendance': (context) => const MarkAttendance(),
      },
    );
  }
}
