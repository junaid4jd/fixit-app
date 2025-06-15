import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';
import '../services/auth_service.dart';
import '../role_selection_screen.dart';

class ServiceProviderProfilePage extends StatefulWidget {
  const ServiceProviderProfilePage({super.key});

  @override
  State<ServiceProviderProfilePage> createState() =>
      _ServiceProviderProfilePageState();
}

class _ServiceProviderProfilePageState
    extends State<ServiceProviderProfilePage> {
  Map<String, dynamic>? _userData;
  bool _isLoading = true;
  bool _isEditing = false;

  final TextEditingController _fullNameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _experienceController = TextEditingController();
  final TextEditingController _hourlyRateController = TextEditingController();
  final TextEditingController _aboutController = TextEditingController();

  String? _selectedCity;
  String? _selectedCategory;
  List<String> _specialties = [];
  List<String> _cities = [];
  List<String> _categories = [];
  List<Map<String, dynamic>> _reviews = [];
  Map<String, dynamic> _stats = {};

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _loadCitiesAndCategories();
    _loadReviews();
    _loadStats();
  }

  @override
  void didUpdateWidget(ServiceProviderProfilePage oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Refresh data when screen is revisited
    _loadReviews();
    _loadStats();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Refresh reviews when screen becomes active
    _loadReviews();
  }

  Future<void> _loadUserData() async {
    try {
      User? user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        DocumentSnapshot doc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();

        if (doc.exists) {
          setState(() {
            _userData = doc.data() as Map<String, dynamic>;
            _populateControllers();
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading profile: $e')),
        );
      }
    }
  }

  void _populateControllers() {
    if (_userData != null) {
      _fullNameController.text = _userData!['fullName'] ?? '';
      _phoneController.text = _userData!['phoneNumber'] ?? '';
      _experienceController.text = _userData!['experience']?.toString() ?? '';
      _hourlyRateController.text = _userData!['hourlyRate']?.toString() ?? '';
      _aboutController.text = _userData!['about'] ?? '';
      _selectedCity = _userData!['city'];
      _selectedCategory = _userData!['primaryCategory'];
      _specialties = List<String>.from(_userData!['specialties'] ?? []);
    }
  }

  Future<void> _loadCitiesAndCategories() async {
    try {
      // Load cities
      QuerySnapshot citiesSnapshot = await FirebaseFirestore.instance
          .collection('cities')
          .where('isActive', isEqualTo: true)
          .get();

      List<String> cities = citiesSnapshot.docs
          .map((doc) => (doc.data() as Map<String, dynamic>)['name'] as String)
          .toList();

      // Load categories
      QuerySnapshot categoriesSnapshot = await FirebaseFirestore.instance
          .collection('categories')
          .where('isActive', isEqualTo: true)
          .orderBy('order')
          .get();

      List<String> categories = categoriesSnapshot.docs
          .map((doc) => (doc.data() as Map<String, dynamic>)['name'] as String)
          .toList();

      setState(() {
        _cities = cities;
        _categories = categories;
      });
    } catch (e) {
      debugPrint('Error loading cities and categories: $e');
    }
  }

  Future<void> _loadReviews() async {
    try {
      User? user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        debugPrint('🔍 Loading reviews for handyman: ${user.uid}');

        // Try multiple query approaches to find reviews
        List<Map<String, dynamic>> allReviews = [];

        // Query 1: handymanId field (new format)
        try {
          QuerySnapshot reviewsSnapshot1 = await FirebaseFirestore.instance
              .collection('reviews')
              .where('handymanId', isEqualTo: user.uid)
              .where('status', isEqualTo: 'approved')
              .orderBy('createdAt', descending: true)
              .limit(10)
              .get();

          debugPrint(
              '📋 Query 1 (handymanId + approved): Found ${reviewsSnapshot1.docs
                  .length} reviews');

          for (var doc in reviewsSnapshot1.docs) {
            allReviews.add({
              'id': doc.id,
              ...doc.data() as Map<String, dynamic>,
            });
          }
        } catch (e) {
          debugPrint('⚠️ Query 1 failed: $e');
        }

        // Query 2: handyman_id field (old format)
        try {
          QuerySnapshot reviewsSnapshot2 = await FirebaseFirestore.instance
              .collection('reviews')
              .where('handyman_id', isEqualTo: user.uid)
              .where('status', isEqualTo: 'approved')
              .orderBy('created_at', descending: true)
              .limit(10)
              .get();

          debugPrint(
              '📋 Query 2 (handyman_id + approved): Found ${reviewsSnapshot2.docs
                  .length} reviews');

          for (var doc in reviewsSnapshot2.docs) {
            Map<String, dynamic> reviewData = {
              'id': doc.id,
              ...doc.data() as Map<String, dynamic>,
            };

            // Check if this review is already in the list (avoid duplicates)
            bool isDuplicate = allReviews.any((
                existingReview) => existingReview['id'] == doc.id);
            if (!isDuplicate) {
              allReviews.add(reviewData);
            }
          }
        } catch (e) {
          debugPrint('⚠️ Query 2 failed: $e');
        }

        // Query 3: Fallback - get all reviews for this handyman (any status)
        if (allReviews.isEmpty) {
          try {
            debugPrint('🔄 Trying fallback query without status filter...');

            QuerySnapshot fallbackSnapshot = await FirebaseFirestore.instance
                .collection('reviews')
                .where('handymanId', isEqualTo: user.uid)
                .get();

            debugPrint(
                '📋 Fallback query (handymanId): Found ${fallbackSnapshot.docs
                    .length} reviews');

            for (var doc in fallbackSnapshot.docs) {
              Map<String, dynamic> reviewData = doc.data() as Map<
                  String,
                  dynamic>;
              debugPrint(
                  '📄 Review status: ${reviewData['status']}, rating: ${reviewData['rating']}');

              allReviews.add({
                'id': doc.id,
                ...reviewData,
              });
            }
          } catch (e) {
            debugPrint('⚠️ Fallback query also failed: $e');
          }
        }

        // Convert and format reviews for display
        List<Map<String, dynamic>> formattedReviews = allReviews.map((review) {
          return {
            'userName': review['user_name'] ?? 'Anonymous',
            'rating': review['rating'] ?? 0,
            'comment': review['comment'] ?? '',
            'date': _formatReviewDate(
                review['created_at'] ?? review['createdAt']),
            'status': review['status'] ?? 'unknown',
            'category': review['category'] ?? 'General',
          };
        }).toList();

        debugPrint('✅ Final processed reviews: ${formattedReviews.length}');
        for (int i = 0; i < formattedReviews.length; i++) {
          debugPrint(
              '📝 Review $i: ${formattedReviews[i]['userName']} - ${formattedReviews[i]['rating']} stars - ${formattedReviews[i]['status']}');
        }

        setState(() {
          _reviews = formattedReviews;
        });
      }
    } catch (e) {
      debugPrint('❌ Error loading reviews: $e');
    }
  }

  String _formatReviewDate(dynamic timestamp) {
    if (timestamp == null) return 'Recently';

    try {
      DateTime date;
      if (timestamp is Timestamp) {
        date = timestamp.toDate();
      } else if (timestamp is String) {
        date = DateTime.parse(timestamp);
      } else {
        return 'Recently';
      }

      final now = DateTime.now();
      final difference = now
          .difference(date)
          .inDays;

      if (difference == 0) {
        return 'Today';
      } else if (difference == 1) {
        return 'Yesterday';
      } else if (difference < 7) {
        return '$difference days ago';
      } else {
        return '${date.day}/${date.month}/${date.year}';
      }
    } catch (e) {
      debugPrint('Error formatting date: $e');
      return 'Recently';
    }
  }

  Future<void> _loadStats() async {
    try {
      User? user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        debugPrint('📊 Loading stats for handyman: ${user.uid}');

        // Get completed bookings count (try both field names)
        QuerySnapshot completedBookings;
        try {
          completedBookings = await FirebaseFirestore.instance
              .collection('bookings')
              .where(
              'handyman_id', isEqualTo: user.uid) // Changed from handymanId
              .where('status', isEqualTo: 'completed')
              .get();
          debugPrint(
              '✅ Found ${completedBookings.docs.length} completed bookings');
        } catch (e) {
          debugPrint('⚠️ First query failed, trying fallback: $e');
          // Fallback to handymanId field
          completedBookings = await FirebaseFirestore.instance
              .collection('bookings')
              .where('handymanId', isEqualTo: user.uid)
              .where('status', isEqualTo: 'completed')
              .get();
          debugPrint('✅ Fallback found ${completedBookings.docs
              .length} completed bookings');
        }

        // Calculate total earnings
        double totalEarnings = 0;
        for (var doc in completedBookings.docs) {
          Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
          double cost = (data['estimated_cost'] ?? data['estimatedCost'] ?? 0)
              .toDouble();
          totalEarnings += cost;
        }
        debugPrint('💰 Total earnings calculated: $totalEarnings OMR');

        // Get this month's bookings
        DateTime now = DateTime.now();
        DateTime startOfMonth = DateTime(now.year, now.month, 1);
        QuerySnapshot thisMonthBookings;
        try {
          thisMonthBookings = await FirebaseFirestore.instance
              .collection('bookings')
              .where(
              'handyman_id', isEqualTo: user.uid) // Changed from handymanId
              .where('status', isEqualTo: 'completed')
              .where('completed_at', isGreaterThanOrEqualTo: Timestamp.fromDate(
              startOfMonth)) // Changed from completedAt
              .get();
          debugPrint(
              '✅ Found ${thisMonthBookings.docs.length} bookings this month');
        } catch (e) {
          debugPrint('⚠️ Monthly bookings query failed: $e');
          // Simpler fallback without date filter
          thisMonthBookings = await FirebaseFirestore.instance
              .collection('bookings')
              .where('handyman_id', isEqualTo: user.uid)
              .where('status', isEqualTo: 'completed')
              .get();

          // Filter manually for this month
          List<QueryDocumentSnapshot> thisMonthDocs = thisMonthBookings.docs
              .where((doc) {
            Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
            Timestamp? completedAt = data['completed_at'] ??
                data['completedAt'];
            if (completedAt != null) {
              return completedAt.toDate().isAfter(startOfMonth);
            }
            return false;
          }).toList();

          debugPrint('✅ Manually filtered: ${thisMonthDocs
              .length} bookings this month');
          // Create a new QuerySnapshot-like object (simplified)
          // For now, just use the count
        }

        setState(() {
          _stats = {
            'completedJobs': completedBookings.docs.length,
            'totalEarnings': totalEarnings,
            'thisMonthJobs': thisMonthBookings.docs.length,
            'rating': _userData?['averageRating'] ?? _userData?['rating'] ??
                0.0,
            'reviewCount': _userData?['totalReviews'] ??
                _userData?['reviewCount'] ?? 0,
          };
        });

        debugPrint('📈 Stats loaded: ${_stats}');
      }
    } catch (e) {
      debugPrint('❌ Error loading stats: $e');
      setState(() {
        _stats = {
          'completedJobs': 0,
          'totalEarnings': 0.0,
          'thisMonthJobs': 0,
          'rating': _userData?['averageRating'] ?? _userData?['rating'] ?? 0.0,
          'reviewCount': _userData?['totalReviews'] ??
              _userData?['reviewCount'] ?? 0,
        };
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'My Profile',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF2C3E50),
        elevation: 0,
        actions: [
          IconButton(
            onPressed: () {
              setState(() {
                _isEditing = !_isEditing;
              });
              if (!_isEditing) {
                _saveProfile();
              }
            },
            icon: Icon(_isEditing ? Icons.save : Icons.edit),
          ),
          IconButton(
            onPressed: _loadReviews,
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh Reviews',
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildProfileHeader(),
            _buildStatsCards(),
            _buildProfileDetails(),
            _buildRecentReviews(),
            _buildSettingsSection(),
            const SizedBox(height: 100),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileHeader() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Stack(
            children: [
              CircleAvatar(
                radius: 50,
                backgroundColor: const Color(0xFF4169E1),
                backgroundImage: _userData?['profileImage'] != null
                    ? NetworkImage(_userData!['profileImage'])
                    : null,
                child: _userData?['profileImage'] == null
                    ? const Icon(Icons.person, size: 50, color: Colors.white)
                    : null,
              ),
              if (_userData?['isVerified'] == true)
                Positioned(
                  bottom: 5,
                  right: 5,
                  child: Container(
                    padding: const EdgeInsets.all(3),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.verified,
                      color: Colors.green,
                      size: 20,
                    ),
                  ),
                ),
              if (_isEditing)
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: GestureDetector(
                    onTap: _pickImage,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: const BoxDecoration(
                        color: Color(0xFF4169E1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.camera_alt,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Expanded(
                child: _isEditing
                    ? TextField(
                  controller: _fullNameController,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                  decoration: const InputDecoration(
                    hintText: 'Full Name',
                    border: UnderlineInputBorder(),
                  ),
                )
                    : Text(
                  _userData?['fullName'] ?? 'No Name',
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2C3E50),
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              if (_userData?['isVerified'] == true && !_isEditing)
                Container(
                  margin: const EdgeInsets.only(left: 8),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.green.withAlpha(30),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.verified,
                        color: Colors.green,
                        size: 14,
                      ),
                      SizedBox(width: 4),
                      Text(
                        'Verified',
                        style: TextStyle(
                          color: Colors.green,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: _userData?['isVerified'] == true
                      ? Colors.green.withAlpha(30)
                      : _userData?['verification_status'] == 'rejected'
                      ? Colors.red.withAlpha(30)
                      : Colors.orange.withAlpha(30),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  _userData?['isVerified'] == true
                      ? 'Identity Verified'
                      : _userData?['verification_status'] == 'rejected'
                      ? 'Verification Rejected'
                      : 'Pending Verification',
                  style: TextStyle(
                    color: _userData?['isVerified'] == true
                        ? Colors.green
                        : _userData?['verification_status'] == 'rejected'
                        ? Colors.red
                        : Colors.orange,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Row(
                children: [
                  const Icon(Icons.star, color: Colors.amber, size: 20),
                  const SizedBox(width: 4),
                  Text(
                    '${_userData?['rating'] ??
                        0.0} (${_userData?['reviewCount'] ?? 0})',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatsCards() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: _buildStatCard(
              title: 'Completed Jobs',
              value: '${_stats['completedJobs'] ?? 0}',
              icon: Icons.done_all,
              color: const Color(0xFF2ECC71),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildStatCard(
              title: 'This Month',
              value: '${_stats['thisMonthJobs'] ?? 0}',
              icon: Icons.calendar_month,
              color: const Color(0xFF3498DB),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildStatCard(
              title: 'Total Earned',
              value: '${_stats['totalEarnings']?.toStringAsFixed(0) ?? 0} OMR',
              icon: Icons.account_balance_wallet,
              color: const Color(0xFFE67E22),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(10),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withAlpha(30),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2C3E50),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: const TextStyle(
              fontSize: 11,
              color: Color(0xFF7F8C8D),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildProfileDetails() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(10),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Profile Details',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2C3E50),
            ),
          ),
          const SizedBox(height: 20),

          _buildDetailField(
              'Phone Number', _phoneController, _userData?['phoneNumber'],
              Icons.phone),
          _buildDetailField('Experience (Years)', _experienceController,
              _userData?['experience']?.toString(), Icons.work),
          _buildDetailField('Hourly Rate (OMR)', _hourlyRateController,
              _userData?['hourlyRate']?.toString(), Icons.money),

          _buildDropdownField('City', _selectedCity, _cities, (value) {
            setState(() {
              _selectedCity = value;
            });
          }),

          _buildDropdownField(
              'Primary Category', _selectedCategory, _categories, (value) {
            setState(() {
              _selectedCategory = value;
            });
          }),

          _buildSpecialtiesField(),

          _buildDetailField(
              'About Me', _aboutController, _userData?['about'], Icons.info,
              maxLines: 3),
        ],
      ),
    );
  }

  Widget _buildDetailField(String label, TextEditingController controller,
      String? value, IconData icon, {int maxLines = 1}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Color(0xFF7F8C8D),
            ),
          ),
          const SizedBox(height: 8),
          _isEditing
              ? TextField(
            controller: controller,
            maxLines: maxLines,
            decoration: InputDecoration(
              prefixIcon: Icon(icon, color: const Color(0xFF7F8C8D)),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              hintText: 'Enter $label',
            ),
          )
              : Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(icon, color: const Color(0xFF7F8C8D)),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    value ?? 'Not provided',
                    style: const TextStyle(
                      fontSize: 16,
                      color: Color(0xFF2C3E50),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDropdownField(String label, String? value, List<String> options,
      Function(String?) onChanged) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Color(0xFF7F8C8D),
            ),
          ),
          const SizedBox(height: 8),
          _isEditing
              ? DropdownButtonFormField<String>(
            value: value,
            decoration: InputDecoration(
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            items: options.map((option) {
              return DropdownMenuItem(
                value: option,
                child: Text(option),
              );
            }).toList(),
            onChanged: onChanged,
            hint: Text('Select $label'),
          )
              : Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                const Icon(Icons.location_city, color: Color(0xFF7F8C8D)),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    value ?? 'Not selected',
                    style: const TextStyle(
                      fontSize: 16,
                      color: Color(0xFF2C3E50),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSpecialtiesField() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Specialties',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Color(0xFF7F8C8D),
            ),
          ),
          const SizedBox(height: 8),
          if (_isEditing) ...[
            TextField(
              decoration: InputDecoration(
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                hintText: 'Enter specialty and press Enter',
                suffixIcon: IconButton(
                  onPressed: _addSpecialty,
                  icon: const Icon(Icons.add),
                ),
              ),
              onSubmitted: (value) => _addSpecialty(),
            ),
            const SizedBox(height: 8),
          ],
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _specialties.map((specialty) {
              return Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFF4169E1).withAlpha(30),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      specialty,
                      style: const TextStyle(
                        color: Color(0xFF4169E1),
                        fontSize: 12,
                      ),
                    ),
                    if (_isEditing) ...[
                      const SizedBox(width: 4),
                      GestureDetector(
                        onTap: () => _removeSpecialty(specialty),
                        child: const Icon(
                          Icons.close,
                          size: 16,
                          color: Color(0xFF4169E1),
                        ),
                      ),
                    ],
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentReviews() {
    if (_reviews.isEmpty) return const SizedBox();

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(10),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Recent Reviews',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2C3E50),
            ),
          ),
          const SizedBox(height: 16),
          ..._reviews
              .take(3)
              .map((review) => _buildReviewCard(review)),
        ],
      ),
    );
  }

  Widget _buildReviewCard(Map<String, dynamic> review) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                review['userName'] ?? 'Anonymous',
                style: const TextStyle(
                  fontWeight: FontWeight.w500,
                  fontSize: 14,
                ),
              ),
              const Spacer(),
              Row(
                children: List.generate(5, (index) {
                  return Icon(
                    index < (review['rating'] ?? 0) ? Icons.star : Icons
                        .star_border,
                    color: Colors.amber,
                    size: 16,
                  );
                }),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            review['comment'] ?? '',
            style: const TextStyle(
              fontSize: 13,
              color: Color(0xFF7F8C8D),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            review['date'] ?? '',
            style: const TextStyle(
              fontSize: 11,
              color: Color(0xFF95A5A6),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsSection() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(10),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Settings',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2C3E50),
            ),
          ),
          const SizedBox(height: 16),
          _buildSettingsItem(
            icon: Icons.notifications_outlined,
            title: 'Notifications',
            subtitle: 'Manage your notification preferences',
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Notification settings coming soon'),
                  backgroundColor: Color(0xFF4169E1),
                ),
              );
            },
          ),
          _buildSettingsItem(
            icon: Icons.help_outline,
            title: 'Help & Support',
            subtitle: 'Get help or contact support',
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Help & Support coming soon'),
                  backgroundColor: Color(0xFF4169E1),
                ),
              );
            },
          ),
          _buildSettingsItem(
            icon: Icons.privacy_tip_outlined,
            title: 'Privacy Policy',
            subtitle: 'View our privacy policy',
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Privacy Policy coming soon'),
                  backgroundColor: Color(0xFF4169E1),
                ),
              );
            },
          ),
          _buildSettingsItem(
            icon: Icons.bug_report,
            title: 'Debug Reviews',
            subtitle: 'Test review loading (Debug)',
            onTap: () async {
              debugPrint('🔍 Debug: Testing review loading from profile...');
              await _loadReviews();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Debug: Found ${_reviews
                      .length} reviews. Check console for details.'),
                  backgroundColor: Colors.orange,
                ),
              );
            },
          ),
          const Divider(height: 32),
          _buildSettingsItem(
            icon: Icons.logout,
            title: 'Logout',
            subtitle: 'Sign out of your account',
            onTap: _showLogoutConfirmation,
            isDestructive: true,
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    return ListTile(
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: isDestructive
              ? Colors.red.withAlpha(30)
              : const Color(0xFF4169E1).withAlpha(30),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(
          icon,
          color: isDestructive ? Colors.red : const Color(0xFF4169E1),
          size: 20,
        ),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: isDestructive ? Colors.red : const Color(0xFF2C3E50),
        ),
      ),
      subtitle: Text(
        subtitle,
        style: const TextStyle(
          fontSize: 13,
          color: Color(0xFF7F8C8D),
        ),
      ),
      trailing: Icon(
        Icons.arrow_forward_ios,
        size: 16,
        color: isDestructive ? Colors.red : const Color(0xFF7F8C8D),
      ),
      onTap: onTap,
      contentPadding: EdgeInsets.zero,
    );
  }

  void _addSpecialty() {
    // This would typically open a dialog to add specialty
    // For now, we'll just add a sample specialty
    if (_specialties.length < 5) {
      setState(() {
        _specialties.add('New Specialty');
      });
    }
  }

  void _removeSpecialty(String specialty) {
    setState(() {
      _specialties.remove(specialty);
    });
  }

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);

    if (image != null) {
      await _uploadImage(File(image.path));
    }
  }

  Future<void> _uploadImage(File imageFile) async {
    try {
      User? user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        Reference storageRef = FirebaseStorage.instance
            .ref()
            .child('profile_images')
            .child('${user.uid}.jpg');

        await storageRef.putFile(imageFile);
        String downloadUrl = await storageRef.getDownloadURL();

        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .update({'profileImage': downloadUrl});

        setState(() {
          _userData!['profileImage'] = downloadUrl;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error uploading image: $e')),
        );
      }
    }
  }

  Future<void> _saveProfile() async {
    try {
      User? user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        Map<String, dynamic> updateData = {
          'fullName': _fullNameController.text,
          'phoneNumber': _phoneController.text,
          'experience': int.tryParse(_experienceController.text) ?? 0,
          'hourlyRate': double.tryParse(_hourlyRateController.text) ?? 0,
          'about': _aboutController.text,
          'city': _selectedCity,
          'primaryCategory': _selectedCategory,
          'specialties': _specialties,
          'updatedAt': FieldValue.serverTimestamp(),
        };

        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .update(updateData);

        setState(() {
          _userData = {..._userData!, ...updateData};
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Profile updated successfully')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating profile: $e')),
        );
      }
    }
  }

  void _showLogoutConfirmation() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.red.withAlpha(30),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.logout, color: Colors.red, size: 20),
              ),
              const SizedBox(width: 12),
              const Text(
                'Logout',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2C3E50),
                ),
              ),
            ],
          ),
          content: const Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Are you sure you want to logout?',
                style: TextStyle(fontSize: 16, color: Color(0xFF2C3E50)),
              ),
              SizedBox(height: 8),
              Text(
                'You will need to sign in again to access your account.',
                style: TextStyle(fontSize: 14, color: Color(0xFF7F8C8D)),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text(
                'Cancel',
                style: TextStyle(
                  color: Color(0xFF7F8C8D),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: _performLogout,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
              ),
              child: const Text(
                'Logout',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _performLogout() async {
    try {
      // Close the dialog first
      Navigator.of(context).pop();

      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return const Dialog(
            child: Padding(
              padding: EdgeInsets.all(20),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(color: Color(0xFF4169E1)),
                  SizedBox(width: 16),
                  Text('Signing out...'),
                ],
              ),
            ),
          );
        },
      );

      // Initialize AuthService and sign out
      final authService = AuthService();
      await authService.signOut();

      // Close loading dialog
      if (mounted) {
        Navigator.of(context).pop();

        // Navigate to role selection screen and clear all previous routes
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const RoleSelectionScreen()),
          (route) => false,
        );

        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Successfully logged out'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      // Close loading dialog if still open
      if (mounted) {
        Navigator.of(context).pop();

        // Show error message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to logout: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }
}
