import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'services/auth_service.dart';
import 'role_selection_screen.dart';
import 'user/user_home_screen.dart';
import 'service_provider/service_provider_home_screen.dart';
import 'admin/admin_dashboard_screen.dart';

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  final AuthService _authService = AuthService();
  User? _user;
  String? _userRole;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initializeAuth();
  }

  Future<void> _initializeAuth() async {
    // Listen to auth state changes
    FirebaseAuth.instance.authStateChanges().listen((User? user) async {
      setState(() {
        _user = user;
        _isLoading = true;
      });

      if (user != null) {
        try {
          // Get user role
          final role = await _authService.getUserType(user.uid);
          setState(() {
            _userRole = role;
            _isLoading = false;
          });
          debugPrint('User authenticated: ${user.uid}, Role: $role');
        } catch (e) {
          debugPrint('Error getting user role: $e');
          setState(() {
            _userRole = null;
            _isLoading = false;
          });
        }
      } else {
        setState(() {
          _userRole = null;
          _isLoading = false;
        });
        debugPrint('User not authenticated');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(
                color: Color(0xFF4169E1),
              ),
              SizedBox(height: 16),
              Text('Checking authentication...'),
            ],
          ),
        ),
      );
    }

    if (_user == null) {
      // User not logged in
      return const RoleSelectionScreen();
    }

    // User is logged in, route based on role
    switch (_userRole) {
      case 'user':
        return const UserHomeScreen();
      case 'service_provider':
        return const ServiceProviderHomeScreen();
      case 'admin':
        return const AdminDashboardScreen();
      default:
      // Role not found or invalid, sign out and show role selection
        _authService.signOut();
        return const RoleSelectionScreen();
    }
  }
}
