import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ContentManagementScreen extends StatefulWidget {
  const ContentManagementScreen({super.key});

  @override
  State<ContentManagementScreen> createState() =>
      _ContentManagementScreenState();
}

class _ContentManagementScreenState extends State<ContentManagementScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _formKey = GlobalKey<FormState>();

  // Text controllers for different content types
  final _termsController = TextEditingController();
  final _privacyController = TextEditingController();
  final _helpController = TextEditingController();
  final _aboutController = TextEditingController();

  bool _isLoading = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadContent();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _termsController.dispose();
    _privacyController.dispose();
    _helpController.dispose();
    _aboutController.dispose();
    super.dispose();
  }

  Future<void> _loadContent() async {
    setState(() => _isLoading = true);

    try {
      final doc = await FirebaseFirestore.instance
          .collection('app_content')
          .doc('content')
          .get();

      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        _termsController.text = data['terms_of_service'] ?? '';
        _privacyController.text = data['privacy_policy'] ?? '';
        _helpController.text = data['help_content'] ?? '';
        _aboutController.text = data['about_us'] ?? '';
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading content: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _saveContent() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      await FirebaseFirestore.instance
          .collection('app_content')
          .doc('content')
          .set({
        'terms_of_service': _termsController.text,
        'privacy_policy': _privacyController.text,
        'help_content': _helpController.text,
        'about_us': _aboutController.text,
        'last_updated': FieldValue.serverTimestamp(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Content saved successfully!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error saving content: $e')),
      );
    } finally {
      setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Content Management'),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF2C3E50),
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          labelColor: const Color(0xFF4169E1),
          unselectedLabelColor: Colors.grey,
          indicatorColor: const Color(0xFF4169E1),
          tabs: const [
            Tab(text: 'Terms'),
            Tab(text: 'Privacy'),
            Tab(text: 'Help'),
            Tab(text: 'About'),
          ],
        ),
        actions: [
          IconButton(
            onPressed: _isSaving ? null : _saveContent,
            icon: _isSaving
                ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
                : const Icon(Icons.save),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Form(
        key: _formKey,
        child: TabBarView(
          controller: _tabController,
          children: [
            _buildContentTab(
              'Terms of Service',
              _termsController,
              'Enter terms of service content...',
            ),
            _buildContentTab(
              'Privacy Policy',
              _privacyController,
              'Enter privacy policy content...',
            ),
            _buildContentTab(
              'Help Content',
              _helpController,
              'Enter help and FAQ content...',
            ),
            _buildContentTab(
              'About Us',
              _aboutController,
              'Enter about us content...',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContentTab(String title, TextEditingController controller,
      String hint) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
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
          const SizedBox(height: 16),
          Expanded(
            child: TextFormField(
              controller: controller,
              maxLines: null,
              expands: true,
              textAlignVertical: TextAlignVertical.top,
              decoration: InputDecoration(
                hintText: hint,
                border: const OutlineInputBorder(),
                focusedBorder: const OutlineInputBorder(
                  borderSide: BorderSide(color: Color(0xFF4169E1)),
                ),
              ),
              validator: (value) {
                if (value == null || value
                    .trim()
                    .isEmpty) {
                  return 'This field cannot be empty';
                }
                return null;
              },
            ),
          ),
        ],
      ),
    );
  }
}
