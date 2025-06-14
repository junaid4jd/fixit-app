import 'package:flutter/material.dart';
import 'user/user_signin_screen.dart';
import 'service_provider/service_provider_signin_screen.dart';
import 'admin/admin_login_screen.dart';

class RoleSelectionScreen extends StatelessWidget {
  const RoleSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF667eea),
              Color(0xFF764ba2),
              Color(0xFFf093fb),
            ],
            stops: [0.0, 0.5, 1.0],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              const SizedBox(height: 40),

              // Animated Header Section
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  children: [
                    // Modern Logo Container
                    Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFFFFFFF), Color(0xFFF8F9FA)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(25),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.15),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                          BoxShadow(
                            color: Colors.white.withOpacity(0.1),
                            blurRadius: 10,
                            offset: const Offset(-5, -5),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.build_circle,
                        size: 45,
                        color: Color(0xFF667eea),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // App Name with Modern Typography
                    ShaderMask(
                      shaderCallback: (bounds) =>
                          const LinearGradient(
                            colors: [Colors.white, Color(0xFFF8F9FA)],
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                          ).createShader(bounds),
                      child: const Text(
                        'Fixit',
                        style: TextStyle(
                          fontSize: 36,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          letterSpacing: 1.5,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),

                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.3),
                          width: 1,
                        ),
                      ),
                      child: const Text(
                        'Your trusted handyman platform',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.white,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 60),

              // Role Cards Section
              Expanded(
                child: Container(
                  width: double.infinity,
                  decoration: const BoxDecoration(
                    color: Color(0xFFF8F9FA),
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(30),
                      topRight: Radius.circular(30),
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 20),

                        const Text(
                          'Choose Your Role',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF2D3748),
                          ),
                        ),
                        const SizedBox(height: 8),

                        const Text(
                          'Select how you want to use Fixit',
                          style: TextStyle(
                            fontSize: 16,
                            color: Color(0xFF718096),
                            fontWeight: FontWeight.w500,
                          ),
                        ),

                        const SizedBox(height: 32),

                        Expanded(
                          child: SingleChildScrollView(
                            child: Column(
                              children: [
                                _buildModernRoleCard(
                                  context,
                                  icon: Icons.person_outline,
                                  title: 'Customer',
                                  subtitle: 'Book trusted handyman services',
                                  description: 'Find skilled professionals for your home repairs',
                                  gradient: const LinearGradient(
                                    colors: [
                                      Color(0xFF4299E1),
                                      Color(0xFF3182CE)
                                    ],
                                  ),
                                  onTap: () => _navigateToUserSignIn(context),
                                ),
                                const SizedBox(height: 20),

                                _buildModernRoleCard(
                                  context,
                                  icon: Icons.engineering_outlined,
                                  title: 'Service Provider',
                                  subtitle: 'Offer your expertise and earn',
                                  description: 'Connect with customers who need your skills',
                                  gradient: const LinearGradient(
                                    colors: [
                                      Color(0xFF48BB78),
                                      Color(0xFF38A169)
                                    ],
                                  ),
                                  onTap: () =>
                                      _navigateToServiceProviderSignIn(context),
                                ),
                                const SizedBox(height: 20),

                                _buildModernRoleCard(
                                  context,
                                  icon: Icons.admin_panel_settings_outlined,
                                  title: 'Administrator',
                                  subtitle: 'Manage platform operations',
                                  description: 'Oversee users, services, and system settings',
                                  gradient: const LinearGradient(
                                    colors: [
                                      Color(0xFFED8936),
                                      Color(0xFFDD6B20)
                                    ],
                                  ),
                                  onTap: () => _navigateToAdminLogin(context),
                                ),

                                const SizedBox(height: 40),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildModernRoleCard(BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
        required String description,
        required Gradient gradient,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Column(
            children: [
              // Gradient Header
              Container(
                width: double.infinity,
                height: 6,
                decoration: BoxDecoration(gradient: gradient),
              ),

              Padding(
                padding: const EdgeInsets.all(24),
                child: Row(
                  children: [
                    // Icon Container
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        gradient: gradient,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: gradient.colors.first.withOpacity(0.3),
                            blurRadius: 12,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Icon(
                        icon,
                        size: 30,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 20),

                    // Content
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF2D3748),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            subtitle,
                            style: const TextStyle(
                              fontSize: 16,
                              color: Color(0xFF4A5568),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            description,
                            style: const TextStyle(
                              fontSize: 14,
                              color: Color(0xFF718096),
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Arrow
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF7FAFC),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.arrow_forward_ios,
                        size: 16,
                        color: Color(0xFF718096),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _navigateToUserSignIn(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => const UserSignInScreen()),
    );
  }

  void _navigateToServiceProviderSignIn(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
          builder: (context) => const ServiceProviderSignInScreen()),
    );
  }

  void _navigateToAdminLogin(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => const AdminLoginScreen()),
    );
  }
}
