import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';

class HelpSupportScreen extends StatefulWidget {
  const HelpSupportScreen({super.key});

  @override
  State<HelpSupportScreen> createState() => _HelpSupportScreenState();
}

class _HelpSupportScreenState extends State<HelpSupportScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _supportMessageController = TextEditingController();
  final TextEditingController _subjectController = TextEditingController();
  String _selectedCategory = 'General';
  bool _isSendingMessage = false;

  final List<String> _supportCategories = [
    'General',
    'Booking Issues',
    'Payment Problems',
    'Account Issues',
    'Technical Problems',
    'Feedback',
  ];

  final List<Map<String, dynamic>> _faqItems = [
    {
      'question': 'How do I book a service?',
      'answer': 'To book a service, go to the home screen, select the service category you need, browse available handymen, and tap "Book Now" on your preferred provider.',
    },
    {
      'question': 'How do I pay for services?',
      'answer': 'Payments can be made through the app using credit/debit cards or mobile wallets. Payment is processed after service completion.',
    },
    {
      'question': 'Can I cancel a booking?',
      'answer': 'Yes, you can cancel a booking up to 2 hours before the scheduled time. Go to "My Bookings" and tap the cancel button.',
    },
    {
      'question': 'How do I rate a handyman?',
      'answer': 'After service completion, you\'ll receive a notification to rate the handyman. You can also rate them from the "My Bookings" section.',
    },
    {
      'question': 'What if I\'m not satisfied with the service?',
      'answer': 'If you\'re not satisfied, please contact our support team immediately. We offer a satisfaction guarantee and will work to resolve any issues.',
    },
    {
      'question': 'How do I change my profile information?',
      'answer': 'Go to your Profile page, tap the edit button, make your changes, and save. Your information will be updated across the platform.',
    },
    {
      'question': 'Are the handymen verified?',
      'answer': 'Yes, all handymen go through a verification process including ID verification, background checks, and skill assessments.',
    },
    {
      'question': 'What are the service charges?',
      'answer': 'Service charges vary by handyman and service type. You can see the rate before booking. There are no hidden fees.',
    },
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _supportMessageController.dispose();
    _subjectController.dispose();
    super.dispose();
  }

  Future<void> _sendSupportMessage() async {
    if (_subjectController.text
        .trim()
        .isEmpty || _supportMessageController.text
        .trim()
        .isEmpty) {
      _showErrorSnackBar('Please fill in all required fields');
      return;
    }

    setState(() => _isSendingMessage = true);

    try {
      await FirebaseFirestore.instance.collection('support_tickets').add({
        'subject': _subjectController.text.trim(),
        'message': _supportMessageController.text.trim(),
        'category': _selectedCategory,
        'status': 'open',
        'createdAt': FieldValue.serverTimestamp(),
        'userId': 'current_user_id', // Replace with actual user ID
      });

      _subjectController.clear();
      _supportMessageController.clear();
      _selectedCategory = 'General';

      _showSuccessSnackBar(
          'Support ticket submitted successfully! We\'ll get back to you soon.');
    } catch (e) {
      _showErrorSnackBar('Error sending message: $e');
    } finally {
      setState(() => _isSendingMessage = false);
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

  Future<void> _launchPhone() async {
    const phoneNumber = 'tel:+96824123456';
    if (await canLaunchUrl(Uri.parse(phoneNumber))) {
      await launchUrl(Uri.parse(phoneNumber));
    } else {
      _showErrorSnackBar('Could not launch phone dialer');
    }
  }

  Future<void> _launchEmail() async {
    const email = 'mailto:support@fixit-oman.com';
    if (await canLaunchUrl(Uri.parse(email))) {
      await launchUrl(Uri.parse(email));
    } else {
      _showErrorSnackBar('Could not launch email client');
    }
  }

  Future<void> _launchWhatsApp() async {
    const whatsapp = 'https://wa.me/96824123456';
    if (await canLaunchUrl(Uri.parse(whatsapp))) {
      await launchUrl(Uri.parse(whatsapp));
    } else {
      _showErrorSnackBar('Could not launch WhatsApp');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'Help & Support',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF2C3E50),
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          labelColor: const Color(0xFF4169E1),
          unselectedLabelColor: Colors.grey,
          indicatorColor: const Color(0xFF4169E1),
          tabs: const [
            Tab(text: 'FAQ', icon: Icon(Icons.help_outline)),
            Tab(text: 'Contact', icon: Icon(Icons.support_agent)),
            Tab(text: 'Guides', icon: Icon(Icons.book)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildFAQTab(),
          _buildContactTab(),
          _buildGuidesTab(),
        ],
      ),
    );
  }

  Widget _buildFAQTab() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _faqItems.length,
      itemBuilder: (context, index) {
        final faq = _faqItems[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ExpansionTile(
            title: Text(
              faq['question'],
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: Color(0xFF2C3E50),
              ),
            ),
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  faq['answer'],
                  style: TextStyle(
                    color: Colors.grey[700],
                    height: 1.5,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildContactTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Quick Contact Options
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
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.all(20),
                  child: Text(
                    'Quick Contact',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2C3E50),
                    ),
                  ),
                ),
                const Divider(height: 1),
                _buildContactTile(
                  'Phone Support',
                  '+968 2412 3456',
                  Icons.phone,
                  Colors.green,
                  _launchPhone,
                ),
                _buildContactTile(
                  'Email Support',
                  'support@fixit-oman.com',
                  Icons.email,
                  Colors.blue,
                  _launchEmail,
                ),
                _buildContactTile(
                  'WhatsApp',
                  'Chat with us on WhatsApp',
                  Icons.chat,
                  Colors.green[700]!,
                  _launchWhatsApp,
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Support Message Form
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
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Send us a Message',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2C3E50),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Category Dropdown
                  DropdownButtonFormField<String>(
                    value: _selectedCategory,
                    decoration: InputDecoration(
                      labelText: 'Category',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    items: _supportCategories.map((category) =>
                        DropdownMenuItem(
                          value: category,
                          child: Text(category),
                        )
                    ).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedCategory = value!;
                      });
                    },
                  ),
                  const SizedBox(height: 16),

                  // Subject Field
                  TextField(
                    controller: _subjectController,
                    decoration: InputDecoration(
                      labelText: 'Subject *',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Message Field
                  TextField(
                    controller: _supportMessageController,
                    maxLines: 5,
                    decoration: InputDecoration(
                      labelText: 'Message *',
                      hintText: 'Please describe your issue or question in detail...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Send Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isSendingMessage ? null : _sendSupportMessage,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF4169E1),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: _isSendingMessage
                          ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white),
                        ),
                      )
                          : const Text(
                        'Send Message',
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
          ),
        ],
      ),
    );
  }

  Widget _buildGuidesTab() {
    final guides = [
      {
        'title': 'Getting Started',
        'description': 'Learn how to use Fixit to find and book services',
        'icon': Icons.play_circle_outline,
        'steps': [
          'Download and install the Fixit app',
          'Create your account with email or phone',
          'Complete your profile information',
          'Browse available services in your city',
          'Select a handyman and book a service',
        ],
      },
      {
        'title': 'Booking a Service',
        'description': 'Step-by-step guide to booking your first service',
        'icon': Icons.book_online,
        'steps': [
          'Open the app and select your city',
          'Choose the service category you need',
          'Browse available handymen and their ratings',
          'Check availability and select a time slot',
          'Confirm your booking and make payment',
        ],
      },
      {
        'title': 'Managing Your Account',
        'description': 'How to update your profile and manage settings',
        'icon': Icons.manage_accounts,
        'steps': [
          'Go to the Profile tab',
          'Tap the edit button to modify information',
          'Update your contact details and preferences',
          'Save your changes',
          'Access settings for notifications and privacy',
        ],
      },
      {
        'title': 'Payment and Billing',
        'description': 'Understanding how payments work on Fixit',
        'icon': Icons.payment,
        'steps': [
          'Add your preferred payment method',
          'Review service costs before booking',
          'Payment is processed after service completion',
          'View payment history in your profile',
          'Download receipts for your records',
        ],
      },
    ];

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: guides.length,
      itemBuilder: (context, index) {
        final guide = guides[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          child: ExpansionTile(
            leading: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: const Color(0xFF4169E1).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                guide['icon'] as IconData,
                color: const Color(0xFF4169E1),
                size: 20,
              ),
            ),
            title: Text(
              guide['title'] as String,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Color(0xFF2C3E50),
              ),
            ),
            subtitle: Text(
              guide['description'] as String,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 13,
              ),
            ),
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ...(guide['steps'] as List<String>)
                        .asMap()
                        .entries
                        .map(
                          (entry) =>
                          Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  width: 20,
                                  height: 20,
                                  decoration: const BoxDecoration(
                                    color: Color(0xFF4169E1),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Center(
                                    child: Text(
                                      '${entry.key + 1}',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    entry.value,
                                    style: TextStyle(
                                      color: Colors.grey[700],
                                      height: 1.4,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildContactTile(String title, String subtitle, IconData icon,
      Color color, VoidCallback onTap) {
    return ListTile(
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: color, size: 20),
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
}