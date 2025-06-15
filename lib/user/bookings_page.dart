import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:async';
import 'chat_screen.dart';

class BookingsPage extends StatefulWidget {
  const BookingsPage({super.key});

  @override
  State<BookingsPage> createState() => _BookingsPageState();
}

class _BookingsPageState extends State<BookingsPage>
    with TickerProviderStateMixin {
  final AuthService _authService = AuthService();
  late TabController _tabController;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  List<Map<String, dynamic>> _pendingBookings = [];
  List<Map<String, dynamic>> _completedBookings = [];
  List<Map<String, dynamic>> _cancelledBookings = [];
  bool _isLoading = true;

  // Store handyman details to avoid repeated fetches
  Map<String, Map<String, dynamic>> _handymanCache = {};

  // Stream subscription for real-time updates
  StreamSubscription? _bookingsStreamSubscription;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _setupRealTimeBookingsListener();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _bookingsStreamSubscription?.cancel();
    super.dispose();
  }

  @override
  void didUpdateWidget(BookingsPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    _loadBookingsWithHandymanDetails();
  }

  void _setupRealTimeBookingsListener() {
    final currentUserId = _authService.currentUserId;
    if (currentUserId == null) {
      debugPrint('❌ Cannot setup listener: User not logged in');
      setState(() => _isLoading = false);
      return;
    }

    debugPrint('🎧 Setting up real-time listener for user: $currentUserId');

    _bookingsStreamSubscription = _firestore
        .collection('bookings')
        .where('user_id', isEqualTo: currentUserId)
        .snapshots()
        .listen(
          (snapshot) {
        debugPrint(
            '🔥 Real-time update: ${snapshot.docs.length} bookings found');
        _processBookingsFromSnapshot(snapshot);
      },
      onError: (error) {
        debugPrint('💥 Real-time listener error: $error');
        // Fallback to manual loading
        _loadBookingsWithHandymanDetails();
      },
    );
  }

  Future<void> _processBookingsFromSnapshot(QuerySnapshot snapshot) async {
    try {
      setState(() => _isLoading = true);

      final bookings = snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        debugPrint('📱 Real-time booking: ${doc
            .id} - ${data['status']} - ${data['category']}');
        return {
          'id': doc.id,
          ...data,
        };
      }).toList();

      debugPrint('📊 Processing ${bookings.length} real-time bookings');

      // Fetch handyman details for each booking
      for (var booking in bookings) {
        final handymanId = booking['handyman_id'];
        if (handymanId != null && !_handymanCache.containsKey(handymanId)) {
          try {
            final handymanDoc = await _firestore
                .collection('users')
                .doc(handymanId)
                .get();

            if (handymanDoc.exists) {
              _handymanCache[handymanId] = {
                'id': handymanId,
                ...handymanDoc.data() as Map<String, dynamic>,
              };
              debugPrint('✅ Cached handyman data for: $handymanId');
            } else {
              debugPrint('❌ Handyman document not found: $handymanId');
            }
          } catch (e) {
            debugPrint('💥 Error fetching handyman $handymanId: $e');
          }
        }
      }

      // Enrich bookings with handyman data
      final enrichedBookings = bookings.map((booking) {
        final handymanId = booking['handyman_id'];
        final handymanData = _handymanCache[handymanId];

        return {
          ...booking,
          'handyman': handymanData,
        };
      }).toList();

      setState(() {
        _pendingBookings = enrichedBookings.where((booking) {
          final status = booking['status']?.toString().toLowerCase();
          final isPending = ['pending', 'accepted', 'in_progress'].contains(
              status);
          debugPrint(
              '📋 Categorizing booking ${booking['id']}: status=$status, isPending=$isPending');
          return isPending;
        }).toList();

        _completedBookings = enrichedBookings.where((booking) {
          final status = booking['status']?.toString().toLowerCase();
          return status == 'completed';
        }).toList();

        _cancelledBookings = enrichedBookings.where((booking) {
          final status = booking['status']?.toString().toLowerCase();
          return ['cancelled', 'rejected'].contains(status);
        }).toList();

        _isLoading = false;
      });

      debugPrint('📈 Real-time update complete - Pending: ${_pendingBookings
          .length}, Completed: ${_completedBookings
          .length}, Cancelled: ${_cancelledBookings.length}');
    } catch (e) {
      debugPrint('💥 Error processing real-time bookings: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadBookingsWithHandymanDetails() async {
    setState(() => _isLoading = true);

    try {
      final currentUserId = _authService.currentUserId;
      if (currentUserId == null) {
        debugPrint('User not logged in');
        setState(() => _isLoading = false);
        return;
      }

      debugPrint('🔍 Loading bookings for user: $currentUserId');

      // Get user's bookings with real-time updates
      final bookings = await _authService.getUserBookings(currentUserId);
      debugPrint('📋 Found ${bookings.length} bookings for user $currentUserId');

      // Debug: Print booking details
      for (int i = 0; i < bookings.length; i++) {
        final booking = bookings[i];
        debugPrint(
            '📄 Booking $i: ID=${booking['id']}, Status=${booking['status']}, UserID=${booking['user_id']}, HandymanID=${booking['handyman_id']}');
      }

      // If no bookings found, let's try a direct Firebase query as fallback
      if (bookings.isEmpty) {
        debugPrint(
            '⚠️ No bookings found via AuthService, trying direct query...');
        try {
          final directQuery = await _firestore
              .collection('bookings')
              .where('user_id', isEqualTo: currentUserId)
              .get();
          debugPrint(
              '🔍 Direct query found ${directQuery.docs.length} bookings');

          for (var doc in directQuery.docs) {
            final data = doc.data();
            debugPrint('📋 Direct booking: ${doc
                .id} - ${data['status']} - ${data['category']}');
          }
        } catch (directError) {
          debugPrint('💥 Direct query failed: $directError');
        }
      }

      // Fetch handyman details for each booking
      for (var booking in bookings) {
        final handymanId = booking['handyman_id'];
        if (handymanId != null && !_handymanCache.containsKey(handymanId)) {
          try {
            final handymanDoc = await _firestore
                .collection('users')
                .doc(handymanId)
                .get();

            if (handymanDoc.exists) {
              _handymanCache[handymanId] = {
                'id': handymanId,
                ...handymanDoc.data() as Map<String, dynamic>,
              };
              debugPrint('✅ Cached handyman data for: $handymanId');
            } else {
              debugPrint('❌ Handyman document not found: $handymanId');
            }
          } catch (e) {
            debugPrint('💥 Error fetching handyman $handymanId: $e');
          }
        }
      }

      // Enrich bookings with handyman data
      final enrichedBookings = bookings.map((booking) {
        final handymanId = booking['handyman_id'];
        final handymanData = _handymanCache[handymanId];

        return {
          ...booking,
          'handyman': handymanData,
        };
      }).toList();

      debugPrint('🎯 Enriched ${enrichedBookings.length} bookings');

      setState(() {
        _pendingBookings = enrichedBookings.where((booking) {
          final status = booking['status']?.toString().toLowerCase();
          final isPending = ['pending', 'accepted', 'in_progress'].contains(
              status);
          debugPrint(
              '📊 Booking ${booking['id']}: status=$status, isPending=$isPending');
          return isPending;
        }).toList();

        _completedBookings = enrichedBookings.where((booking) {
          final status = booking['status']?.toString().toLowerCase();
          return status == 'completed';
        }).toList();

        _cancelledBookings = enrichedBookings.where((booking) {
          final status = booking['status']?.toString().toLowerCase();
          return ['cancelled', 'rejected'].contains(status);
        }).toList();

        _isLoading = false;
      });

      debugPrint('📈 Final counts - Pending: ${_pendingBookings
          .length}, Completed: ${_completedBookings
          .length}, Cancelled: ${_cancelledBookings.length}');

      // Debug: Print all pending bookings
      for (int i = 0; i < _pendingBookings.length; i++) {
        final booking = _pendingBookings[i];
        debugPrint(
            '⏳ Pending Booking $i: ${booking['id']} - ${booking['status']} - ${booking['category']}');
      }
    } catch (e) {
      debugPrint('💥 Error loading bookings: $e');
      setState(() => _isLoading = false);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load bookings: $e'),
            backgroundColor: Colors.red,
            action: SnackBarAction(
              label: 'Retry',
              textColor: Colors.white,
              onPressed: _loadBookingsWithHandymanDetails,
            ),
          ),
        );
      }
    }
  }

  Future<void> _createTestBookingForDebug() async {
    try {
      final currentUserId = _authService.currentUserId;
      if (currentUserId == null) {
        debugPrint('❌ User not logged in - cannot create test booking');
        return;
      }

      debugPrint('🔧 Creating test booking for user: $currentUserId');

      final testBooking = {
        'user_id': currentUserId,
        'category': 'Plumbing',
        'description': 'Test booking for real-time functionality',
        'address': '123 Test Street, Test City',
        'scheduled_date': Timestamp.fromDate(
            DateTime.now().add(Duration(days: 2))),
        'scheduled_time': '10:00 AM',
        'estimated_cost': 50.0,
        'status': 'pending',
        'created_at': FieldValue.serverTimestamp(),
        'updated_at': FieldValue.serverTimestamp(),
      };

      final docRef = await _firestore.collection('bookings').add(testBooking);
      debugPrint('✅ Created test booking with ID: ${docRef.id}');
    } catch (e) {
      debugPrint('💥 Error creating test booking: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to create test booking: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'My Bookings',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: const Color(0xFF4169E1),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: _loadBookingsWithHandymanDetails,
            icon: const Icon(Icons.refresh),
          ),
          // Add test button for debugging
          IconButton(
            onPressed: _createTestBookingForDebug,
            icon: const Icon(Icons.add_circle),
            tooltip: 'Create Test Booking',
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          indicatorWeight: 3,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          labelStyle: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
          tabs: [
            Tab(
              text: 'Pending (${_pendingBookings.length})',
            ),
            Tab(
              text: 'Completed (${_completedBookings.length})',
            ),
            Tab(
              text: 'Cancelled (${_cancelledBookings.length})',
            ),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(
        child: CircularProgressIndicator(
          color: Color(0xFF4169E1),
        ),
      )
          : TabBarView(
        controller: _tabController,
        children: [
          _buildBookingsList(_pendingBookings, 'pending'),
          _buildBookingsList(_completedBookings, 'completed'),
          _buildBookingsList(_cancelledBookings, 'cancelled'),
        ],
      ),
    );
  }

  Widget _buildBookingsList(List<Map<String, dynamic>> bookings, String type) {
    if (bookings.isEmpty) {
      return _buildEmptyState(type);
    }

    return RefreshIndicator(
      onRefresh: _loadBookingsWithHandymanDetails,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: bookings.length,
        itemBuilder: (context, index) {
          final booking = bookings[index];
          return _buildEnhancedBookingCard(booking);
        },
      ),
    );
  }

  Widget _buildEmptyState(String type) {
    IconData icon;
    String title;
    String subtitle;

    switch (type) {
      case 'pending':
        icon = Icons.pending_actions;
        title = 'No Pending Bookings';
        subtitle = 'Your upcoming bookings will appear here';
        break;
      case 'completed':
        icon = Icons.check_circle_outline;
        title = 'No Completed Bookings';
        subtitle = 'Your finished services will appear here';
        break;
      case 'cancelled':
        icon = Icons.cancel_outlined;
        title = 'No Cancelled Bookings';
        subtitle = 'Cancelled bookings will appear here';
        break;
      default:
        icon = Icons.bookmark_outline;
        title = 'No Bookings';
        subtitle = 'Your bookings will appear here';
    }

    return RefreshIndicator(
      onRefresh: _loadBookingsWithHandymanDetails,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Container(
          height: MediaQuery
              .of(context)
              .size
              .height * 0.6,
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    icon,
                    size: 60,
                    color: Colors.grey[400],
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[700],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[500],
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                Text(
                  'Pull down to refresh',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[400],
                    fontStyle: FontStyle.italic,
                  ),
                ),
                const SizedBox(height: 32),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ElevatedButton.icon(
                      onPressed: _loadBookingsWithHandymanDetails,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF4169E1),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 24, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      icon: const Icon(Icons.refresh),
                      label: const Text('Refresh'),
                    ),
                    const SizedBox(width: 16),
                    ElevatedButton.icon(
                      onPressed: () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.grey[600],
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 24, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      icon: const Icon(Icons.search),
                      label: const Text('Find Services'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEnhancedBookingCard(Map<String, dynamic> booking) {
    final status = booking['status'] ?? 'pending';
    final category = booking['category'] ?? 'Service';
    final description = booking['description'] ?? 'No description';
    final scheduledDate = booking['scheduled_date'] as Timestamp?;
    final scheduledTime = booking['scheduled_time'] ?? '';
    final estimatedCost = booking['estimated_cost'] ?? 0.0;
    final address = booking['address'] ?? '';
    final handyman = booking['handyman'] as Map<String, dynamic>?;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with Status
            Row(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: _getStatusColor(status).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    _getCategoryIcon(category),
                    color: _getStatusColor(status),
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        category,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2C3E50),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Booking #${booking['id']?.substring(0, 8) ?? ''}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: _getStatusColor(status).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: _getStatusColor(status).withOpacity(0.3),
                    ),
                  ),
                  child: Text(
                    _getStatusText(status),
                    style: TextStyle(
                      color: _getStatusColor(status),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Handyman Information
            if (handyman != null) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey[200]!),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 20,
                      backgroundColor: const Color(0xFF4169E1).withOpacity(0.1),
                      child: Text(
                        (handyman['fullName'] ?? 'H')[0].toUpperCase(),
                        style: const TextStyle(
                          color: Color(0xFF4169E1),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                handyman['fullName'] ?? 'Handyman',
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF2C3E50),
                                ),
                              ),
                              if (handyman['isVerified'] == true) ...[
                                const SizedBox(width: 4),
                                const Icon(
                                  Icons.verified,
                                  color: Color(0xFF1ABC9C),
                                  size: 16,
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              const Icon(
                                  Icons.star, color: Colors.amber, size: 14),
                              const SizedBox(width: 4),
                              Text(
                                '${handyman['averageRating'] ?? 0.0}',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFF7F8C8D),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                '${handyman['phoneNumber'] ?? 'N/A'}',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFF7F8C8D),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => _openChat(booking),
                      icon: const Icon(
                        Icons.chat_bubble_outline,
                        color: Color(0xFF4169E1),
                        size: 20,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Description
            Text(
              description,
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF7F8C8D),
                height: 1.4,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),

            const SizedBox(height: 12),

            // Details Grid
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _buildDetailItem(
                          Icons.calendar_today,
                          scheduledDate != null
                              ? _formatDate(scheduledDate.toDate())
                              : 'Date not set',
                        ),
                      ),
                      Expanded(
                        child: _buildDetailItem(
                          Icons.access_time,
                          scheduledTime.isNotEmpty
                              ? scheduledTime
                              : 'Time not set',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: _buildDetailItem(
                          Icons.location_on,
                          address.isNotEmpty ? address : 'Address not provided',
                        ),
                      ),
                      Expanded(
                        child: _buildDetailItem(
                          Icons.attach_money,
                          'OMR ${estimatedCost.toStringAsFixed(1)}',
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Action Buttons
            _buildActionButtons(booking, status),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons(Map<String, dynamic> booking, String status) {
    return Row(
      children: [
        if (status == 'pending') ...[
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () => _cancelBooking(booking['id']),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Colors.red),
                foregroundColor: Colors.red,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              icon: const Icon(Icons.cancel, size: 16),
              label: const Text('Cancel'),
            ),
          ),
          const SizedBox(width: 12),
        ],
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () => _viewBookingDetails(booking),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF4169E1),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            icon: const Icon(Icons.info_outline, size: 16),
            label: const Text('Details'),
          ),
        ),
        if (status == 'completed') ...[
          const SizedBox(width: 12),
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () => _rateService(booking),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.amber,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              icon: const Icon(Icons.star, size: 16),
              label: const Text('Rate'),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildDetailItem(IconData icon, String text) {
    return Row(
      children: [
        Icon(
          icon,
          size: 16,
          color: Colors.grey[600],
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[700],
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Colors.orange;
      case 'accepted':
        return Colors.blue;
      case 'in_progress':
        return Colors.purple;
      case 'completed':
        return Colors.green;
      case 'cancelled':
      case 'rejected':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _getStatusText(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return 'Pending';
      case 'accepted':
        return 'Accepted';
      case 'in_progress':
        return 'In Progress';
      case 'completed':
        return 'Completed';
      case 'cancelled':
        return 'Cancelled';
      case 'rejected':
        return 'Rejected';
      default:
        return 'Unknown';
    }
  }

  IconData _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'plumbing':
        return Icons.plumbing;
      case 'electrical':
        return Icons.electrical_services;
      case 'painting':
        return Icons.format_paint;
      case 'cleaning':
        return Icons.cleaning_services;
      case 'carpentry':
        return Icons.handyman;
      case 'hvac':
        return Icons.ac_unit;
      default:
        return Icons.build;
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = date
        .difference(now)
        .inDays;

    if (difference == 0) {
      return 'Today';
    } else if (difference == 1) {
      return 'Tomorrow';
    } else if (difference == -1) {
      return 'Yesterday';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  void _openChat(Map<String, dynamic> booking) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            ChatScreen(
              bookingId: booking['id'],
              handyman: booking['handyman'] ?? {},
              currentUserId: _authService.currentUserId!,
            ),
      ),
    );
  }

  void _cancelBooking(String bookingId) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16)),
          title: const Text('Cancel Booking'),
          content: const Text(
              'Are you sure you want to cancel this booking? This action cannot be undone.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Keep Booking'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop();
                await _performCancelBooking(bookingId);
              },
              child: const Text(
                  'Cancel Booking', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }

  Future<void> _performCancelBooking(String bookingId) async {
    try {
      await _authService.updateBookingStatus(bookingId, 'cancelled');
      await _loadBookingsWithHandymanDetails(); // Refresh the list

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Booking cancelled successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to cancel booking: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _viewBookingDetails(Map<String, dynamic> booking) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BookingDetailsScreen(booking: booking),
      ),
    );
  }

  void _rateService(Map<String, dynamic> booking) {
    showDialog(
      context: context,
      builder: (BuildContext context) =>
          _RatingDialog(
            booking: booking,
            onRated: () => _loadBookingsWithHandymanDetails(),
      ),
    );
  }
}

class BookingDetailsScreen extends StatelessWidget {
  final Map<String, dynamic> booking;

  const BookingDetailsScreen({super.key, required this.booking});

  @override
  Widget build(BuildContext context) {
    final scheduledDate = booking['scheduled_date'] as Timestamp?;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Booking Details'),
        backgroundColor: const Color(0xFF4169E1),
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Booking Information',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildDetailRow('Booking ID:', booking['id'] ?? 'N/A'),
                    _buildDetailRow('Category:', booking['category'] ?? 'N/A'),
                    _buildDetailRow('Status:', booking['status'] ?? 'N/A'),
                    _buildDetailRow(
                        'Description:', booking['description'] ?? 'N/A'),
                    _buildDetailRow('Address:', booking['address'] ?? 'N/A'),
                    _buildDetailRow('Scheduled Date:', scheduledDate != null
                        ? '${scheduledDate
                        .toDate()
                        .day}/${scheduledDate
                        .toDate()
                        .month}/${scheduledDate
                        .toDate()
                        .year}'
                        : 'N/A'),
                    _buildDetailRow(
                        'Scheduled Time:', booking['scheduled_time'] ?? 'N/A'),
                    _buildDetailRow('Estimated Cost:',
                        'OMR ${booking['estimated_cost']?.toStringAsFixed(1) ??
                            '0'}'),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                color: Color(0xFF7F8C8D),
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: Color(0xFF2C3E50),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RatingDialog extends StatefulWidget {
  final Map<String, dynamic> booking;
  final VoidCallback onRated;

  const _RatingDialog({
    super.key,
    required this.booking,
    required this.onRated,
  });

  @override
  State<_RatingDialog> createState() => _RatingDialogState();
}

class _RatingDialogState extends State<_RatingDialog> {
  int selectedRating = 0;
  final TextEditingController _commentController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Text(
        'Rate Service',
        style: TextStyle(fontWeight: FontWeight.bold),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'How would you rate ${widget.booking['handyman']?['fullName'] ??
                'this handyman'}?',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 16),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              5,
                  (index) =>
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        selectedRating = index + 1;
                      });
                    },
                    child: Icon(
                      Icons.star,
                      color: selectedRating > index ? Colors.amber : Colors
                          .grey[300],
                      size: 36,
                    ),
                  ),
            ),
          ),
          if (selectedRating > 0) ...[
            const SizedBox(height: 20),
            TextField(
              controller: _commentController,
              decoration: InputDecoration(
                hintText: 'Add a comment (optional)',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                filled: true,
                fillColor: Colors.grey[50],
              ),
              maxLines: 3,
              maxLength: 200,
            ),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: _isSubmitting ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: selectedRating > 0 && !_isSubmitting
              ? _submitRating
              : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF4169E1),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8)),
          ),
          child: _isSubmitting
              ? const SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: Colors.white,
            ),
          )
              : const Text('Submit', style: TextStyle(color: Colors.white)),
        ),
      ],
    );
  }

  Future<void> _submitRating() async {
    setState(() => _isSubmitting = true);

    try {
      // Get user and handyman names for the review
      String userName = 'Anonymous';
      String handymanName = 'Unknown';
      String category = widget.booking['category'] ?? 'General';

      try {
        // Get current user's name
        final currentUser = FirebaseAuth.instance.currentUser;
        if (currentUser != null) {
          final userDoc = await FirebaseFirestore.instance
              .collection('users')
              .doc(currentUser.uid)
              .get();
          if (userDoc.exists) {
            userName = userDoc.data()?['fullName'] ?? 'Anonymous';
          }
        }

        // Get handyman's name
        final handymanData = widget.booking['handyman'] as Map<String,
            dynamic>?;
        if (handymanData != null) {
          handymanName = handymanData['fullName'] ?? 'Unknown';
        } else if (widget.booking['handyman_id'] != null) {
          final handymanDoc = await FirebaseFirestore.instance
              .collection('users')
              .doc(widget.booking['handyman_id'])
              .get();
          if (handymanDoc.exists) {
            handymanName = handymanDoc.data()?['fullName'] ?? 'Unknown';
          }
        }
      } catch (e) {
        debugPrint('Error getting user/handyman names: $e');
      }

      // Submit rating to Firebase with all required fields
      await FirebaseFirestore.instance.collection('reviews').add({
        'booking_id': widget.booking['id'],
        'user_id': widget.booking['user_id'],
        'handyman_id': widget.booking['handyman_id'],
        // Keep this for compatibility
        'handymanId': widget.booking['handyman_id'],
        // Add this for service provider queries
        'user_name': userName,
        'handyman_name': handymanName,
        'rating': selectedRating,
        'comment': _commentController.text.trim(),
        'category': category,
        'created_at': FieldValue.serverTimestamp(),
        'createdAt': FieldValue.serverTimestamp(),
        // Add this for service provider queries
        'status': 'pending',
        // Reviews need admin approval
        'is_reviewed': true,
      });

      // Update booking to mark as reviewed
      await FirebaseFirestore.instance
          .collection('bookings')
          .doc(widget.booking['id'])
          .update({
        'is_reviewed': true,
        'reviewed_at': FieldValue.serverTimestamp(),
      });

      // Update handyman's average rating
      final handymanId = widget.booking['handyman_id'];
      if (handymanId != null) {
        final handymanRef = FirebaseFirestore.instance.collection('users').doc(
            handymanId);
        await FirebaseFirestore.instance.runTransaction((transaction) async {
          final handymanDoc = await transaction.get(handymanRef);
          if (handymanDoc.exists) {
            final currentRating = handymanDoc.data()?['averageRating'] ?? 0.0;
            final totalReviews = handymanDoc.data()?['totalReviews'] ?? 0;

            final newTotalReviews = totalReviews + 1;
            final newAverageRating = ((currentRating * totalReviews) +
                selectedRating) / newTotalReviews;

            transaction.update(handymanRef, {
              'averageRating': newAverageRating,
              'totalReviews': newTotalReviews,
              'reviewCount': newTotalReviews,
              // Add this for service provider profile
            });
          }
        });
      }

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
                'Review submitted successfully! It will be visible after admin approval.'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 3),
          ),
        );
        widget.onRated();
      }
    } catch (e) {
      print('Error submitting rating: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to submit rating: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }
}
