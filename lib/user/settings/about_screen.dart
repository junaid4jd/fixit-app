import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AboutScreen extends StatefulWidget {
  const AboutScreen({super.key});

  @override
  State<AboutScreen> createState() => _AboutScreenState();
}

class _AboutScreenState extends State<AboutScreen> {
  Map<String, dynamic>? _appContent;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAppContent();
  }

  Future<void> _loadAppContent() async {
    setState(() => _isLoading = true);

    try {
      final doc = await FirebaseFirestore.instance
          .collection('app_content')
          .doc('content')
          .get();

      if (doc.exists) {
        setState(() {
          _appContent = doc.data();
        });
      }
    } catch (e) {
      // Handle error silently for demo
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'About Fixit',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF2C3E50),
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // App Logo and Title
            Center(
              child: Column(
                children: [
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF4169E1), Color(0xFF3A5FCD)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF4169E1).withValues(alpha: 0.3),
                          blurRadius: 15,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.handyman,
                      color: Colors.white,
                      size: 50,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Fixit Oman',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2C3E50),
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Your Trusted Handyman Services',
                    style: TextStyle(
                      fontSize: 16,
                      color: Color(0xFF7F8C8D),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),

            // About Us Section
            _buildInfoCard(
              'About Us',
              _appContent?['about_us'] ??
                  'Fixit Oman is the leading handyman services marketplace in Oman, connecting customers with skilled professionals for all their home and office maintenance needs. '
                      'We are committed to providing reliable, affordable, and high-quality services across Muscat, Salalah, and other major cities in Oman.\n\n'
                      'Our platform ensures that all service providers are verified and experienced, giving you peace of mind when booking services. '
                      'From plumbing and electrical work to cleaning and carpentry, we have experts ready to help.',
              Icons.info_outline,
            ),
            const SizedBox(height: 20),

            // Our Mission Section
            _buildInfoCard(
              'Our Mission',
              'To make quality handyman services accessible to everyone in Oman by connecting skilled professionals with customers through our easy-to-use platform. '
                  'We strive to create a trusted ecosystem where both customers and service providers can benefit from transparent, efficient, and reliable service delivery.',
              Icons.flag,
            ),
            const SizedBox(height: 20),

            // Features Section
            _buildInfoCard(
              'Key Features',
              '• Verified and experienced handymen\n'
                  '• Transparent pricing with no hidden fees\n'
                  '• 24/7 customer support\n'
                  '• Real-time booking and tracking\n'
                  '• Secure payment processing\n'
                  '• Customer reviews and ratings\n'
                  '• Service guarantee\n'
                  '• Available across major cities in Oman',
              Icons.star,
            ),
            const SizedBox(height: 20),

            // App Information
            _buildInfoCard(
              'App Information',
              'Version: 1.0.0\n'
                  'Build: 2024.12.20\n'
                  'Platform: Flutter\n'
                  'Supported Languages: English, Arabic\n'
                  'Target Region: Sultanate of Oman\n'
                  'Last Updated: December 2024',
              Icons.phone_android,
            ),
            const SizedBox(height: 20),

            // Contact Information
            _buildInfoCard(
              'Contact Information',
              'Email: support@fixit-oman.com\n'
                  'Phone: +968 2412 3456\n'
                  'WhatsApp: +968 2412 3456\n'
                  'Website: www.fixit-oman.com\n'
                  'Business Hours: 8:00 AM - 8:00 PM (Sun-Thu)\n'
                  'Emergency Support: Available 24/7',
              Icons.contact_phone,
            ),
            const SizedBox(height: 20),

            // Terms and Privacy
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                children: [
                  _buildLinkTile(
                    'Terms of Service',
                    'Read our terms and conditions',
                    Icons.description,
                        () =>
                        _showContentDialog('Terms of Service',
                            _appContent?['terms_of_service']),
                  ),
                  const Divider(height: 1),
                  _buildLinkTile(
                    'Privacy Policy',
                    'Learn how we protect your data',
                    Icons.privacy_tip,
                        () =>
                        _showContentDialog(
                            'Privacy Policy', _appContent?['privacy_policy']),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),

            // Footer
            Center(
              child: Column(
                children: [
                  Text(
                    '© 2024 Fixit Oman',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Made with ❤️ in Oman',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard(String title, String content, IconData icon) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: const Color(0xFF4169E1).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    icon,
                    color: const Color(0xFF4169E1),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2C3E50),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              content,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[700],
                height: 1.6,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLinkTile(String title, String subtitle, IconData icon,
      VoidCallback onTap) {
    return ListTile(
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: const Color(0xFF4169E1).withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: const Color(0xFF4169E1), size: 20),
      ),
      title: Text(
        title,
        style: const TextStyle(
          fontWeight: FontWeight.w600,
          color: Color(0xFF2C3E50),
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          color: Colors.grey[600],
          fontSize: 13,
        ),
      ),
      trailing: const Icon(
        Icons.arrow_forward_ios,
        size: 16,
        color: Color(0xFF7F8C8D),
      ),
      onTap: onTap,
    );
  }

  void _showContentDialog(String title, String? content) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title),
          content: SingleChildScrollView(
            child: Text(
              content ?? 'Content not available. Please check back later.',
              style: const TextStyle(height: 1.5),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }
}