import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/auth_service.dart';

class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  State<NotificationSettingsScreen> createState() =>
      _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState
    extends State<NotificationSettingsScreen> {
  final AuthService _authService = AuthService();
  Map<String, bool> _notificationSettings = {
    'bookingUpdates': true,
    'paymentReminders': true,
    'promotionalOffers': false,
    'newMessages': true,
    'serviceReminders': true,
    'reviewRequests': true,
    'emailNotifications': false,
    'smsNotifications': true,
  };

  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadNotificationSettings();
  }

  Future<void> _loadNotificationSettings() async {
    setState(() => _isLoading = true);

    try {
      if (_authService.currentUserId != null) {
        final doc = await FirebaseFirestore.instance
            .collection('user_settings')
            .doc(_authService.currentUserId!)
            .get();

        if (doc.exists) {
          final data = doc.data() as Map<String, dynamic>;
          final settings = data['notifications'] as Map<String, dynamic>? ?? {};

          setState(() {
            _notificationSettings = {
              'bookingUpdates': settings['bookingUpdates'] ?? true,
              'paymentReminders': settings['paymentReminders'] ?? true,
              'promotionalOffers': settings['promotionalOffers'] ?? false,
              'newMessages': settings['newMessages'] ?? true,
              'serviceReminders': settings['serviceReminders'] ?? true,
              'reviewRequests': settings['reviewRequests'] ?? true,
              'emailNotifications': settings['emailNotifications'] ?? false,
              'smsNotifications': settings['smsNotifications'] ?? true,
            };
          });
        }
      }
    } catch (e) {
      _showErrorSnackBar('Error loading settings: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _saveNotificationSettings() async {
    setState(() => _isSaving = true);

    try {
      if (_authService.currentUserId != null) {
        await FirebaseFirestore.instance
            .collection('user_settings')
            .doc(_authService.currentUserId!)
            .set({
          'notifications': _notificationSettings,
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));

        _showSuccessSnackBar('Settings saved successfully!');
      }
    } catch (e) {
      _showErrorSnackBar('Error saving settings: $e');
    } finally {
      setState(() => _isSaving = false);
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.green),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'Notification Settings',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF2C3E50),
        elevation: 0,
        actions: [
          if (_isSaving)
            const Padding(
              padding: EdgeInsets.all(16),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
          else
            TextButton(
              onPressed: _saveNotificationSettings,
              child: const Text(
                'Save',
                style: TextStyle(
                  color: Color(0xFF4169E1),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionCard(
              'Push Notifications',
              'Manage when you receive push notifications',
              [
                _buildSwitchTile(
                  'Booking Updates',
                  'Get notified about booking status changes',
                  'bookingUpdates',
                  Icons.calendar_today,
                ),
                _buildSwitchTile(
                  'New Messages',
                  'Receive notifications for new chat messages',
                  'newMessages',
                  Icons.message,
                ),
                _buildSwitchTile(
                  'Payment Reminders',
                  'Get reminded about pending payments',
                  'paymentReminders',
                  Icons.payment,
                ),
                _buildSwitchTile(
                  'Service Reminders',
                  'Reminders about upcoming services',
                  'serviceReminders',
                  Icons.alarm,
                ),
                _buildSwitchTile(
                  'Review Requests',
                  'Get asked to review completed services',
                  'reviewRequests',
                  Icons.star,
                ),
              ],
            ),
            const SizedBox(height: 20),
            _buildSectionCard(
              'Marketing',
              'Control promotional communications',
              [
                _buildSwitchTile(
                  'Promotional Offers',
                  'Receive special offers and discounts',
                  'promotionalOffers',
                  Icons.local_offer,
                ),
              ],
            ),
            const SizedBox(height: 20),
            _buildSectionCard(
              'Communication Channels',
              'Choose how you want to receive notifications',
              [
                _buildSwitchTile(
                  'Email Notifications',
                  'Receive important updates via email',
                  'emailNotifications',
                  Icons.email,
                ),
                _buildSwitchTile(
                  'SMS Notifications',
                  'Get critical updates via text message',
                  'smsNotifications',
                  Icons.sms,
                ),
              ],
            ),
            const SizedBox(height: 30),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF4169E1).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: const Color(0xFF4169E1).withValues(alpha: 0.2),
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.info_outline,
                    color: Color(0xFF4169E1),
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Important Notice',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF4169E1),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Some notifications are essential for service delivery and cannot be disabled.',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[700],
                          ),
                        ),
                      ],
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

  Widget _buildSectionCard(String title, String subtitle,
      List<Widget> children) {
    return Container(
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2C3E50),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          ...children,
        ],
      ),
    );
  }

  Widget _buildSwitchTile(String title, String subtitle, String key,
      IconData icon) {
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
          fontSize: 13,
          color: Colors.grey[600],
        ),
      ),
      trailing: Switch(
        value: _notificationSettings[key] ?? false,
        onChanged: (value) {
          setState(() {
            _notificationSettings[key] = value;
          });
        },
        activeColor: const Color(0xFF4169E1),
      ),
    );
  }
}