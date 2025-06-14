import 'package:flutter/material.dart';
import 'admin/admin_dashboard_screen.dart';

class MainScreen extends StatelessWidget {
  final String role;

  const MainScreen({super.key, required this.role});

  @override
  Widget build(BuildContext context) {
    // If admin role, show admin dashboard instead
    if (role == 'Admin') {
      return const AdminDashboardScreen();
    }

    // For other roles, show basic screen
    return Scaffold(
      appBar: AppBar(
        title: Text('Fixit Oman - $role'),
        backgroundColor: const Color(0xFF4169E1),
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _getRoleIcon(),
              size: 80,
              color: const Color(0xFF4169E1),
            ),
            const SizedBox(height: 20),
            Text(
              'Welcome, $role!',
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFF4169E1),
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'Your Handyman Solution in Oman',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getRoleIcon() {
    switch (role) {
      case 'User':
        return Icons.person;
      case 'Service Provider':
        return Icons.build_circle;
      case 'Admin':
        return Icons.admin_panel_settings;
      default:
        return Icons.build;
    }
  }
}
