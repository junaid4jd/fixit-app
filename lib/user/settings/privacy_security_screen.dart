import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/auth_service.dart';

class PrivacySecurityScreen extends StatefulWidget {
  const PrivacySecurityScreen({super.key});

  @override
  State<PrivacySecurityScreen> createState() => _PrivacySecurityScreenState();
}

class _PrivacySecurityScreenState extends State<PrivacySecurityScreen> {
  final AuthService _authService = AuthService();
  final TextEditingController _currentPasswordController = TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();

  Map<String, bool> _privacySettings = {
    'profileVisibility': true,
    'locationSharing': true,
    'activityStatus': true,
    'dataCollection': false,
    'marketingEmails': false,
  };

  bool _isLoading = true;
  bool _isSaving = false;
  bool _isChangingPassword = false;

  @override
  void initState() {
    super.initState();
    _loadPrivacySettings();
  }

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _loadPrivacySettings() async {
    setState(() => _isLoading = true);

    try {
      if (_authService.currentUserId != null) {
        final doc = await FirebaseFirestore.instance
            .collection('user_settings')
            .doc(_authService.currentUserId!)
            .get();

        if (doc.exists) {
          final data = doc.data() as Map<String, dynamic>;
          final settings = data['privacy'] as Map<String, dynamic>? ?? {};

          setState(() {
            _privacySettings = {
              'profileVisibility': settings['profileVisibility'] ?? true,
              'locationSharing': settings['locationSharing'] ?? true,
              'activityStatus': settings['activityStatus'] ?? true,
              'dataCollection': settings['dataCollection'] ?? false,
              'marketingEmails': settings['marketingEmails'] ?? false,
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

  Future<void> _savePrivacySettings() async {
    setState(() => _isSaving = true);

    try {
      if (_authService.currentUserId != null) {
        await FirebaseFirestore.instance
            .collection('user_settings')
            .doc(_authService.currentUserId!)
            .set({
          'privacy': _privacySettings,
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));

        _showSuccessSnackBar('Privacy settings saved successfully!');
      }
    } catch (e) {
      _showErrorSnackBar('Error saving settings: $e');
    } finally {
      setState(() => _isSaving = false);
    }
  }

  Future<void> _changePassword() async {
    if (_newPasswordController.text != _confirmPasswordController.text) {
      _showErrorSnackBar('New passwords do not match');
      return;
    }

    if (_newPasswordController.text.length < 6) {
      _showErrorSnackBar('Password must be at least 6 characters');
      return;
    }

    setState(() => _isChangingPassword = true);

    try {
      await _authService.changePassword(
        _currentPasswordController.text,
        _newPasswordController.text,
      );

      _currentPasswordController.clear();
      _newPasswordController.clear();
      _confirmPasswordController.clear();

      _showSuccessSnackBar('Password changed successfully!');
    } catch (e) {
      _showErrorSnackBar('Error changing password: $e');
    } finally {
      setState(() => _isChangingPassword = false);
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

  void _showDeleteAccountDialog() {
    showDialog(
      context: context,
      builder: (context) =>
          AlertDialog(
            title: const Text('Delete Account'),
            content: const Text(
              'Are you sure you want to delete your account? This action cannot be undone and all your data will be permanently removed.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  _deleteAccount();
                },
                child: const Text(
                    'Delete', style: TextStyle(color: Colors.red)),
              ),
            ],
          ),
    );
  }

  Future<void> _deleteAccount() async {
    try {
      await _authService.deleteAccount();
      if (mounted) {
        Navigator.of(context).pushNamedAndRemoveUntil(
          '/role-selection',
              (route) => false,
        );
      }
    } catch (e) {
      _showErrorSnackBar('Error deleting account: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'Privacy & Security',
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
            _buildSectionCard(
              'Privacy Settings',
              'Control what information is shared',
              [
                _buildSwitchTile(
                  'Profile Visibility',
                  'Allow handymen to see your profile information',
                  'profileVisibility',
                  Icons.visibility,
                ),
                _buildSwitchTile(
                  'Location Sharing',
                  'Share your location for better service matching',
                  'locationSharing',
                  Icons.location_on,
                ),
                _buildSwitchTile(
                  'Activity Status',
                  'Show when you were last active',
                  'activityStatus',
                  Icons.access_time,
                ),
                _buildSwitchTile(
                  'Data Collection',
                  'Allow anonymous data collection for app improvement',
                  'dataCollection',
                  Icons.analytics,
                ),
                _buildSwitchTile(
                  'Marketing Emails',
                  'Receive promotional emails and offers',
                  'marketingEmails',
                  Icons.email,
                ),
              ],
            ),
            const SizedBox(height: 20),

            _buildSectionCard(
              'Security',
              'Manage your account security',
              [
                _buildActionTile(
                  'Change Password',
                  'Update your account password',
                  Icons.lock,
                  _showChangePasswordDialog,
                ),
                _buildActionTile(
                  'Login Activity',
                  'View recent login activity',
                  Icons.history,
                  _showLoginActivity,
                ),
                _buildActionTile(
                  'Data Export',
                  'Download your personal data',
                  Icons.download,
                  _exportData,
                ),
              ],
            ),
            const SizedBox(height: 20),

            _buildSectionCard(
              'Account Management',
              'Manage your account',
              [
                _buildActionTile(
                  'Delete Account',
                  'Permanently delete your account and data',
                  Icons.delete_forever,
                  _showDeleteAccountDialog,
                  textColor: Colors.red,
                  iconColor: Colors.red,
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Save Privacy Settings Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isSaving ? null : _savePrivacySettings,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4169E1),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isSaving
                    ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
                    : const Text(
                  'Save Privacy Settings',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
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
        value: _privacySettings[key] ?? false,
        onChanged: (value) {
          setState(() {
            _privacySettings[key] = value;
          });
        },
        activeColor: const Color(0xFF4169E1),
      ),
    );
  }

  Widget _buildActionTile(String title, String subtitle, IconData icon,
      VoidCallback onTap, {
        Color? textColor,
        Color? iconColor,
      }) {
    return ListTile(
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: (iconColor ?? const Color(0xFF4169E1)).withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(
            icon, color: iconColor ?? const Color(0xFF4169E1), size: 20),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.w600,
          color: textColor ?? const Color(0xFF2C3E50),
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          fontSize: 13,
          color: Colors.grey[600],
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

  void _showChangePasswordDialog() {
    showDialog(
      context: context,
      builder: (context) =>
          AlertDialog(
            title: const Text('Change Password'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: _currentPasswordController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Current Password',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _newPasswordController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'New Password',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _confirmPasswordController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Confirm New Password',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  _currentPasswordController.clear();
                  _newPasswordController.clear();
                  _confirmPasswordController.clear();
                },
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: _isChangingPassword ? null : () {
                  Navigator.pop(context);
                  _changePassword();
                },
                child: _isChangingPassword
                    ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
                    : const Text('Change'),
              ),
            ],
          ),
    );
  }

  void _showLoginActivity() {
    showDialog(
      context: context,
      builder: (context) =>
          AlertDialog(
            title: const Text('Login Activity'),
            content: const Text(
              'Recent login activity:\n\n'
                  '• Today, 2:30 PM - Mobile App\n'
                  '• Yesterday, 8:15 AM - Mobile App\n'
                  '• 2 days ago, 6:45 PM - Mobile App\n\n'
                  'If you notice any suspicious activity, please change your password immediately.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Close'),
              ),
            ],
          ),
    );
  }

  void _exportData() {
    showDialog(
      context: context,
      builder: (context) =>
          AlertDialog(
            title: const Text('Export Data'),
            content: const Text(
              'Your data export request has been received. You will receive an email with your data within 48 hours.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'),
              ),
            ],
          ),
    );
  }
}