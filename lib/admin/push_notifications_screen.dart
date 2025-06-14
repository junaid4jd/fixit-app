import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import '../services/auth_service.dart';

class PushNotificationsScreen extends StatefulWidget {
  const PushNotificationsScreen({super.key});

  @override
  State<PushNotificationsScreen> createState() =>
      _PushNotificationsScreenState();
}

class _PushNotificationsScreenState extends State<PushNotificationsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _messageController = TextEditingController();

  String _selectedUserType = 'all';
  String _selectedCity = 'all';
  List<String> _cities = ['all'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadCities();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _titleController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _loadCities() async {
    try {
      if (mounted) {
        print('Fetching all cities...');
      }

      final citiesSnapshot = await FirebaseFirestore.instance
          .collection('cities')
          .where('is_active', isEqualTo: true)
          .get();

      final cities = ['all'];
      for (var doc in citiesSnapshot.docs) {
        cities.add(doc.data()['name']);
      }

      if (mounted) {
        setState(() {
          _cities = cities;
        });
      }
    } catch (e) {
      if (mounted) {
        print('Error loading cities: $e');
      }
    }
  }

  Future<void> _sendNotification() async {
    if (!_formKey.currentState!.validate()) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please fill all required fields')),
        );
      }
      return;
    }

    if (mounted) {
      setState(() => _isSending = true);
    }

    try {
      // Get target users based on selection
      Query usersQuery = FirebaseFirestore.instance.collection('users');

      if (_selectedUserType != 'all') {
        usersQuery = usersQuery.where('role', isEqualTo: _selectedUserType);
      }

      if (_selectedCity != 'all') {
        usersQuery = usersQuery.where('city', isEqualTo: _selectedCity);
      }

      final usersSnapshot = await usersQuery.get();
      final userTokens = <String>[];

      for (var userDoc in usersSnapshot.docs) {
        final userData = userDoc.data() as Map<String, dynamic>;
        if (userData['fcm_token'] != null) {
          userTokens.add(userData['fcm_token']);
        }
      }

      if (userTokens.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('No users found with the selected criteria')),
          );
        }
        return;
      }

      // Save notification to database
      await FirebaseFirestore.instance.collection('admin_notifications').add({
        'title': _titleController.text,
        'message': _messageController.text,
        'user_type': _selectedUserType,
        'city': _selectedCity,
        'sent_to_count': userTokens.length,
        'sent_at': FieldValue.serverTimestamp(),
      });

      // Send push notifications (in a real implementation, this would use Firebase Cloud Functions)
      for (String token in userTokens) {
        // In a real app, you'd use Firebase Cloud Messaging API
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Notification sent to ${userTokens.length} users')),
        );
      }

      // Clear form
      _titleController.clear();
      _messageController.clear();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error sending notification: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSending = false);
      }
    }
  }

  bool _isSending = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Push Notifications'),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF2C3E50),
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          labelColor: const Color(0xFF4169E1),
          unselectedLabelColor: Colors.grey,
          indicatorColor: const Color(0xFF4169E1),
          tabs: const [
            Tab(text: 'Send Notification'),
            Tab(text: 'History'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildSendNotificationTab(),
          _buildNotificationHistoryTab(),
        ],
      ),
    );
  }

  Widget _buildSendNotificationTab() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Send Push Notification',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2C3E50),
              ),
            ),
            const SizedBox(height: 24),

            // User Type Selection
            const Text('Target Audience',
                style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: _selectedUserType,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(
                    horizontal: 12, vertical: 8),
              ),
              items: const [
                DropdownMenuItem(value: 'all', child: Text('All Users')),
                DropdownMenuItem(value: 'user', child: Text('Customers Only')),
                DropdownMenuItem(
                    value: 'handyman', child: Text('Handymen Only')),
              ],
              onChanged: (value) => setState(() => _selectedUserType = value!),
            ),
            const SizedBox(height: 16),

            // City Selection
            const Text('City', style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: _selectedCity,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(
                    horizontal: 12, vertical: 8),
              ),
              items: _cities.map((city) =>
                  DropdownMenuItem(
                    value: city,
                    child: Text(city == 'all' ? 'All Cities' : city),
                  )).toList(),
              onChanged: (value) => setState(() => _selectedCity = value!),
            ),
            const SizedBox(height: 16),

            // Title
            const Text('Title', style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'Enter notification title',
              ),
              validator: (value) {
                if (value == null || value
                    .trim()
                    .isEmpty) {
                  return 'Title is required';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Message
            const Text(
                'Message', style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            TextFormField(
              controller: _messageController,
              maxLines: 4,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'Enter notification message',
              ),
              validator: (value) {
                if (value == null || value
                    .trim()
                    .isEmpty) {
                  return 'Message is required';
                }
                return null;
              },
            ),
            const SizedBox(height: 24),

            // Send Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isSending ? null : _sendNotification,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4169E1),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: _isSending
                    ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
                    : const Text(
                    'Send Notification', style: TextStyle(fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationHistoryTab() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('admin_notifications')
          .orderBy('sent_at', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(
            child: Text('No notifications sent yet'),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: snapshot.data!.docs.length,
          itemBuilder: (context, index) {
            final doc = snapshot.data!.docs[index];
            final data = doc.data() as Map<String, dynamic>;
            final sentAt = data['sent_at'] as Timestamp?;

            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      data['title'] ?? '',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(data['message'] ?? ''),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Icon(Icons.people, size: 16, color: Colors.grey[600]),
                        const SizedBox(width: 4),
                        Text(
                          '${data['sent_to_count']} recipients',
                          style: TextStyle(
                              color: Colors.grey[600], fontSize: 12),
                        ),
                        const Spacer(),
                        Text(
                          sentAt != null
                              ? '${sentAt
                              .toDate()
                              .day}/${sentAt
                              .toDate()
                              .month}/${sentAt
                              .toDate()
                              .year}'
                              : '',
                          style: TextStyle(
                              color: Colors.grey[600], fontSize: 12),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
