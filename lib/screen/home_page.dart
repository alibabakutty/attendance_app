import 'package:attendance_app/authentication/auth_provider.dart';
import 'package:attendance_app/screen/attendance_history.dart';
import 'package:attendance_app/screen/employee_profiles.dart';
import 'package:attendance_app/screen/mark_attendance.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  void _onMarkAttendance(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const MarkAttendance()),
    );
  }

  void _onViewHistory(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const AttendanceHistory()),
    );
  }

  void _onProfileView(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const EmployeeProfiles(),
      ),
    );
  }

  void _onLogout() {
    showDialog(
        context: context,
        builder: (BuildContext context) {
          final authProvider =
              Provider.of<AuthProvider>(context, listen: false);
          return AlertDialog(
            title: const Text('Logout'),
            content: const Text('Are you sure you want to logout?'),
            actions: [
              TextButton(
                child: const Text('Cancel'),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
              TextButton(
                child: const Text('Logout'),
                onPressed: () {
                  final isAdmin = authProvider.isAdmin;
                  authProvider.logout();
                  Navigator.of(context).pop();
                  Navigator.of(context).pushReplacementNamed(
                      isAdmin ? '/adminLogin' : '/employeeLogin');
                },
              ),
            ],
          );
        });
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Employee Dashboard',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _onLogout,
            tooltip: 'Logout',
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Greeting
            Text(
              'Hello, ${authProvider.username} 👋',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Welcome back! Here’s what you can do today.',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Colors.grey[600],
                  ),
            ),
            const SizedBox(height: 30),

            // Action Cards
            Expanded(
              child: GridView.count(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                children: [
                  _buildDashboardCard(
                    icon: Icons.access_time,
                    title: 'Mark Attendance',
                    color: Colors.indigo,
                    onTap: () => _onMarkAttendance(context),
                  ),
                  _buildDashboardCard(
                    icon: Icons.history,
                    title: 'Attendance History',
                    color: Colors.teal,
                    onTap: () => _onViewHistory(context),
                  ),
                  _buildDashboardCard(
                    icon: Icons.person_outline,
                    title: 'Employee Profiles',
                    color: Colors.orange,
                    onTap: () => _onProfileView(context),
                  ),
                  _buildDashboardCard(
                    icon: Icons.settings,
                    title: 'Employee Profiles Management',
                    color: Colors.purple,
                    onTap: () {
                      // Optional: navigate to settings
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDashboardCard({
    required IconData icon,
    required String title,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: color.withOpacity(0.1),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 40, color: color),
              const SizedBox(height: 12),
              Text(
                title,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: color.withOpacity(0.8),
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}
