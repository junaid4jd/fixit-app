import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/booking_service.dart';
import '../services/auth_service.dart';
import '../user/chat_screen.dart';

class ServiceRequestsPage extends StatefulWidget {
  const ServiceRequestsPage({super.key});

  @override
  State<ServiceRequestsPage> createState() => _ServiceRequestsPageState();
}

class _ServiceRequestsPageState extends State<ServiceRequestsPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final AuthService _authService = AuthService();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'Service Requests',
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
          isScrollable: true,
          tabs: const [
            Tab(text: 'New'),
            Tab(text: 'Accepted'),
            Tab(text: 'In Progress'),
            Tab(text: 'Completed'),
            Tab(text: 'Cancelled'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildRequestsList('pending'),
          _buildRequestsList('accepted'),
          _buildRequestsList('in_progress'),
          _buildRequestsList('completed'),
          _buildRequestsList('cancelled'),
        ],
      ),
    );
  }

  Stream<QuerySnapshot> _getBookingsStream(String status) {
    final currentUserId = _authService.currentUserId;

    if (currentUserId == null) {
      debugPrint('User not logged in, returning empty stream');
      return Stream.empty();
    }

    try {
      debugPrint(
          'Creating booking stream for handyman: $currentUserId, status: $status');

      return FirebaseFirestore.instance
          .collection('bookings')
          .where('handyman_id', isEqualTo: currentUserId)
          .where('status', isEqualTo: status)
          .snapshots()
          .handleError((error) {
        debugPrint('Error in booking stream for status $status: $error');

        // If compound query fails, try simple query
        return FirebaseFirestore.instance
            .collection('bookings')
            .where('handyman_id', isEqualTo: currentUserId)
            .snapshots()
            .map((snapshot) {
          // Filter by status locally if compound query fails
          final filteredDocs = snapshot.docs.where((doc) {
            final data = doc.data() as Map<String, dynamic>;
            return data['status'] == status;
          }).toList();

          // Create a new QuerySnapshot-like object (simplified)
          return snapshot;
        });
      });
    } catch (e) {
      debugPrint('Error creating booking stream: $e');

      // Fallback: simple query without compound index
      try {
        return FirebaseFirestore.instance
            .collection('bookings')
            .where('handyman_id', isEqualTo: currentUserId)
            .snapshots()
            .map((snapshot) {
          debugPrint('Using fallback query, filtering ${snapshot.docs
              .length} documents');
          return snapshot;
        });
      } catch (fallbackError) {
        debugPrint('Fallback query also failed: $fallbackError');
        return Stream.empty();
      }
    }
  }

  Widget _buildRequestsList(String status) {
    return StreamBuilder<QuerySnapshot>(
      stream: _getBookingsStream(status),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error, size: 64, color: Colors.red[300]),
                const SizedBox(height: 16),
                Text('Error: ${snapshot.error}'),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => setState(() {}),
                  child: const Text('Retry'),
                ),
              ],
            ),
          );
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return _buildEmptyState(status);
        }

        // Filter documents by status locally if needed
        final filteredDocs = snapshot.data!.docs.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          return data['status'] == status;
        }).toList();

        if (filteredDocs.isEmpty) {
          return _buildEmptyState(status);
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: filteredDocs.length,
          itemBuilder: (context, index) {
            return _buildRequestCard(filteredDocs[index]);
          },
        );
      },
    );
  }

  Widget _buildEmptyState(String status) {
    String message;
    IconData icon;
    Color color;

    switch (status) {
      case 'pending':
        message = 'No new requests';
        icon = Icons.inbox_outlined;
        color = Colors.orange;
        break;
      case 'accepted':
        message = 'No accepted requests';
        icon = Icons.check_circle_outline;
        color = Colors.blue;
        break;
      case 'in_progress':
        message = 'No requests in progress';
        icon = Icons.work_outline;
        color = Colors.green;
        break;
      case 'completed':
        message = 'No completed requests';
        icon = Icons.done_all;
        color = Colors.grey;
        break;
      case 'cancelled':
        message = 'No cancelled requests';
        icon = Icons.cancel_outlined;
        color = Colors.red;
        break;
      default:
        message = 'No requests found';
        icon = Icons.search_off;
        color = Colors.grey;
    }

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 80,
            color: color.withValues(alpha: 0.3),
          ),
          const SizedBox(height: 16),
          Text(
            message,
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            status == 'pending'
                ? 'New requests will appear here'
                : 'Requests you\'ve ${status.replaceAll(
                '_', ' ')} will appear here',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildRequestCard(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    String status = data['status'] ?? 'pending';

    return FutureBuilder<Map<String, dynamic>?>(
      future: _getUserData(data['user_id']),
      builder: (context, userSnapshot) {
        String clientName = userSnapshot.data?['fullName'] ?? 'Unknown Client';
        String clientPhone = userSnapshot.data?['phoneNumber'] ?? '';

        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          elevation: 2,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            data['category'] ?? 'Service Request',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF2C3E50),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            data['description'] ?? 'No description',
                            style: const TextStyle(
                              fontSize: 14,
                              color: Color(0xFF7F8C8D),
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    _buildStatusChip(status),
                  ],
                ),

                const SizedBox(height: 16),

                // Client Info
                Row(
                  children: [
                    const Icon(
                        Icons.person, size: 16, color: Color(0xFF7F8C8D)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        clientName,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Color(0xFF7F8C8D),
                        ),
                      ),
                    ),
                    if (clientPhone.isNotEmpty) ...[
                      IconButton(
                        onPressed: () => _makePhoneCall(clientPhone),
                        icon: const Icon(Icons.phone, size: 18, color: Color(
                            0xFF4169E1)),
                        constraints: const BoxConstraints(),
                        padding: EdgeInsets.zero,
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 8),

                // Location
                Row(
                  children: [
                    const Icon(
                        Icons.location_on, size: 16, color: Color(0xFF7F8C8D)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        data['address'] ?? 'No address provided',
                        style: const TextStyle(
                          fontSize: 14,
                          color: Color(0xFF7F8C8D),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // Date and Time
                Row(
                  children: [
                    const Icon(
                        Icons.access_time, size: 16, color: Color(0xFF7F8C8D)),
                    const SizedBox(width: 8),
                    Text(
                      '${_formatDate(
                          data['scheduled_date'])} at ${data['scheduled_time'] ??
                          'Time not set'}',
                      style: const TextStyle(
                        fontSize: 14,
                        color: Color(0xFF7F8C8D),
                      ),
                    ),
                  ],
                ),

                if (data['special_instructions'] != null &&
                    data['special_instructions']
                        .toString()
                        .isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                          Icons.note, size: 16, color: Color(0xFF7F8C8D)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Note: ${data['special_instructions']}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF7F8C8D),
                            fontStyle: FontStyle.italic,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],

                const SizedBox(height: 16),

                // Price and Actions
                Row(
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${data['estimated_cost'] ?? 0} OMR',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF4169E1),
                          ),
                        ),
                        if (data['final_cost'] != null &&
                            data['final_cost'] != data['estimated_cost'])
                          Text(
                            'Final: ${data['final_cost']} OMR',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFF27AE60),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                      ],
                    ),
                    const Spacer(),
                    ..._buildActionButtons(doc.id, status, data, clientName),
                  ],
                ),

                if (data['created_at'] != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    'Requested ${_formatDateTime(data['created_at'])}',
                    style: const TextStyle(
                      fontSize: 11,
                      color: Color(0xFF95A5A6),
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatusChip(String status) {
    Color color;
    String label;
    IconData? icon;

    switch (status) {
      case 'pending':
        color = Colors.orange;
        label = 'New';
        icon = Icons.new_releases;
        break;
      case 'accepted':
        color = Colors.blue;
        label = 'Accepted';
        icon = Icons.check_circle;
        break;
      case 'in_progress':
        color = Colors.green;
        label = 'In Progress';
        icon = Icons.work;
        break;
      case 'completed':
        color = Colors.grey;
        label = 'Completed';
        icon = Icons.done_all;
        break;
      case 'cancelled':
        color = Colors.red;
        label = 'Cancelled';
        icon = Icons.cancel;
        break;
      case 'rejected':
        color = Colors.red;
        label = 'Rejected';
        icon = Icons.close;
        break;
      default:
        color = Colors.grey;
        label = status;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildActionButtons(String bookingId, String status,
      Map<String, dynamic> data, String clientName) {
    List<Widget> buttons = [];

    switch (status) {
      case 'pending':
        buttons.addAll([
          IconButton(
            onPressed: () => _openChat(bookingId, data['user_id'], clientName),
            icon: const Icon(Icons.chat, color: Color(0xFF4169E1)),
            tooltip: 'Chat with client',
          ),
          TextButton(
            onPressed: () => _rejectRequest(bookingId),
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            child: const Text('Reject'),
          ),
          const SizedBox(width: 4),
          ElevatedButton(
            onPressed: () => _acceptRequest(bookingId),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF4169E1),
              foregroundColor: Colors.white,
            ),
            child: const Text('Accept'),
          ),
        ]);
        break;

      case 'accepted':
        buttons.addAll([
          IconButton(
            onPressed: () => _openChat(bookingId, data['user_id'], clientName),
            icon: const Icon(Icons.chat, color: Color(0xFF4169E1)),
            tooltip: 'Chat with client',
          ),
          ElevatedButton(
            onPressed: () => _startWork(bookingId),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
            child: const Text('Start Work'),
          ),
        ]);
        break;

      case 'in_progress':
        buttons.addAll([
          IconButton(
            onPressed: () => _openChat(bookingId, data['user_id'], clientName),
            icon: const Icon(Icons.chat, color: Color(0xFF4169E1)),
            tooltip: 'Chat with client',
          ),
          ElevatedButton(
            onPressed: () => _completeWork(bookingId, data),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
            ),
            child: const Text('Complete'),
          ),
        ]);
        break;

      case 'completed':
        buttons.addAll([
          TextButton(
            onPressed: () => _viewDetails(bookingId, data),
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFF4169E1),
            ),
            child: const Text('View Details'),
          ),
          if (data['rating'] != null) ...[
            const SizedBox(width: 8),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.star, color: Colors.amber, size: 16),
                Text(
                  '${data['rating']}/5',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
        ]);
        break;

      case 'cancelled':
        buttons.add(
          TextButton(
            onPressed: () => _viewDetails(bookingId, data),
            style: TextButton.styleFrom(
              foregroundColor: Colors.grey,
            ),
            child: const Text('View Details'),
          ),
        );
        break;
    }

    return buttons;
  }

  Future<Map<String, dynamic>?> _getUserData(String? userId) async {
    if (userId == null) return null;
    try {
      final userData = await _authService.getUserData(userId);
      return userData;
    } catch (e) {
      return null;
    }
  }

  String _formatDate(dynamic timestamp) {
    if (timestamp == null) return 'No date';

    DateTime date;
    if (timestamp is Timestamp) {
      date = timestamp.toDate();
    } else {
      return 'Invalid date';
    }

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));
    final dateOnly = DateTime(date.year, date.month, date.day);

    if (dateOnly == today) {
      return 'Today';
    } else if (dateOnly == tomorrow) {
      return 'Tomorrow';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  String _formatDateTime(dynamic timestamp) {
    if (timestamp == null) return 'Unknown';

    DateTime date;
    if (timestamp is Timestamp) {
      date = timestamp.toDate();
    } else {
      return 'Invalid date';
    }

    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays > 0) {
      return '${difference.inDays} day${difference.inDays > 1 ? 's' : ''} ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hour${difference.inHours > 1
          ? 's'
          : ''} ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minute${difference.inMinutes > 1
          ? 's'
          : ''} ago';
    } else {
      return 'Just now';
    }
  }

  void _makePhoneCall(String phoneNumber) {
    // In a real app, you would use url_launcher to make phone calls
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Call: $phoneNumber')),
    );
  }

  Future<void> _acceptRequest(String bookingId) async {
    try {
      await BookingService.updateBookingStatus(bookingId, 'accepted');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Request accepted successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _rejectRequest(String bookingId) async {
    String? reason = await _showRejectDialog();
    if (reason != null && reason.isNotEmpty) {
      try {
        await BookingService.updateBookingStatus(
            bookingId, 'rejected', reason: reason);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Request rejected'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Future<void> _startWork(String bookingId) async {
    try {
      await BookingService.updateBookingStatus(bookingId, 'in_progress');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Work started - Client has been notified'),
            backgroundColor: Colors.blue,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _completeWork(String bookingId,
      Map<String, dynamic> data) async {
    final result = await _showCompleteWorkDialog(data);
    if (result != null) {
      try {
        await FirebaseFirestore.instance
            .collection('bookings')
            .doc(bookingId)
            .update({
          'status': 'completed',
          'completed_at': FieldValue.serverTimestamp(),
          'final_cost': result['finalCost'],
          'completion_notes': result['notes'],
          'updated_at': FieldValue.serverTimestamp(),
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Work completed - Customer will be notified'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  void _openChat(String bookingId, String userId, String userName) async {
    try {
      // Get user data for the chat
      final userData = await _getUserData(userId);
      if (userData != null && mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) =>
                ChatScreen(
                  bookingId: bookingId,
                  handyman: userData,
                  currentUserId: _authService.currentUserId!,
            ),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Unable to load chat. Please try again.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error opening chat: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _viewDetails(String bookingId, Map<String, dynamic> data) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => _buildDetailsSheet(data),
    );
  }

  Widget _buildDetailsSheet(Map<String, dynamic> data) {
    return Container(
      padding: const EdgeInsets.all(24),
      constraints: BoxConstraints(
        maxHeight: MediaQuery
            .of(context)
            .size
            .height * 0.8,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Booking Details',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close),
              ),
            ],
          ),
          const Divider(),

          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildDetailRow('Service', data['category']),
                  _buildDetailRow('Description', data['description']),
                  _buildDetailRow('Status', data['status']),
                  _buildDetailRow(
                      'Address', data['address'] ?? 'No address provided'),
                  _buildDetailRow('Date', _formatDate(data['scheduled_date'])),
                  _buildDetailRow(
                      'Time', data['scheduled_time'] ?? 'Time not set'),
                  _buildDetailRow('Phone', data['phone_number'] ?? 'N/A'),

                  const SizedBox(height: 16),
                  const Text(
                    'Cost Information',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  _buildDetailRow(
                      'Estimated Cost', '${data['estimated_cost'] ?? 0} OMR'),
                  if (data['final_cost'] != null &&
                      data['final_cost'] != data['estimated_cost'])
                    _buildDetailRow('Final Cost', '${data['final_cost']} OMR'),

                  if (data['special_instructions'] != null &&
                      data['special_instructions']
                          .toString()
                          .isNotEmpty) ...[
                    const SizedBox(height: 16),
                    const Text(
                      'Special Instructions',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        data['special_instructions'],
                        style: const TextStyle(
                          fontSize: 14,
                          color: Color(0xFF2C3E50),
                        ),
                      ),
                    ),
                  ],

                  if (data['completion_notes'] != null &&
                      data['completion_notes']
                          .toString()
                          .isNotEmpty) ...[
                    const SizedBox(height: 16),
                    const Text(
                      'Completion Notes',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.green[50],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.green[200]!),
                      ),
                      child: Text(
                        data['completion_notes'],
                        style: const TextStyle(
                          fontSize: 14,
                          color: Color(0xFF2C3E50),
                        ),
                      ),
                    ),
                  ],

                  if (data['rating'] != null) ...[
                    const SizedBox(height: 16),
                    const Text(
                      'Customer Review',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.amber[50],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.amber[200]!),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              ...List.generate(5, (index) {
                                return Icon(
                                  index < (data['rating'] ?? 0)
                                      ? Icons.star
                                      : Icons.star_border,
                                  color: Colors.amber,
                                  size: 20,
                                );
                              }),
                              const SizedBox(width: 8),
                              Text('${data['rating']}/5'),
                            ],
                          ),
                          if (data['review'] != null && data['review']
                              .toString()
                              .isNotEmpty) ...[
                            const SizedBox(height: 8),
                            Text(
                              data['review'],
                              style: const TextStyle(
                                fontSize: 14,
                                color: Color(0xFF2C3E50),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],

                  if (data['rejected_reason'] != null ||
                      data['cancellation_reason'] != null) ...[
                    const SizedBox(height: 16),
                    const Text(
                      'Reason',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.red[50],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.red[200]!),
                      ),
                      child: Text(
                        data['rejected_reason'] ??
                            data['cancellation_reason'] ?? '',
                        style: const TextStyle(
                          fontSize: 14,
                          color: Color(0xFF2C3E50),
                        ),
                      ),
                    ),
                  ],

                  const SizedBox(height: 16),
                  const Text(
                    'Timeline',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  _buildTimelineItem('Requested', data['created_at']),
                  if (data['accepted_at'] != null)
                    _buildTimelineItem('Accepted', data['accepted_at']),
                  if (data['started_at'] != null)
                    _buildTimelineItem('Started', data['started_at']),
                  if (data['completed_at'] != null)
                    _buildTimelineItem('Completed', data['completed_at']),
                  if (data['cancelled_at'] != null)
                    _buildTimelineItem('Cancelled', data['cancelled_at']),
                  if (data['rejected_at'] != null)
                    _buildTimelineItem('Rejected', data['rejected_at']),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String? value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                color: Color(0xFF7F8C8D),
              ),
            ),
          ),
          Expanded(
            child: Text(
              value ?? 'N/A',
              style: const TextStyle(
                color: Color(0xFF2C3E50),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineItem(String label, dynamic timestamp) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: const BoxDecoration(
              color: Color(0xFF4169E1),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          Text(
            '$label: ${_formatDateTime(timestamp)}',
            style: const TextStyle(
              fontSize: 13,
              color: Color(0xFF7F8C8D),
            ),
          ),
        ],
      ),
    );
  }

  Future<String?> _showRejectDialog() async {
    TextEditingController reasonController = TextEditingController();

    return await showDialog<String>(
      context: context,
      builder: (context) =>
          AlertDialog(
            title: const Text('Reject Request'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                    'Please provide a reason for rejecting this request:'),
                const SizedBox(height: 16),
                TextField(
                  controller: reasonController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    hintText: 'Enter reason...',
                    border: OutlineInputBorder(),
                  ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, reasonController.text),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Reject'),
          ),
        ],
      ),
    );
  }

  Future<Map<String, dynamic>?> _showCompleteWorkDialog(
      Map<String, dynamic> originalData) async {
    TextEditingController finalCostController = TextEditingController(
      text: originalData['estimated_cost']?.toString() ?? '0',
    );
    TextEditingController notesController = TextEditingController();

    return await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) =>
          AlertDialog(
            title: const Text('Complete Work'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Final cost (OMR):'),
                  const SizedBox(height: 8),
                  TextField(
                    controller: finalCostController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      hintText: '0.0',
                    ),
              ),
              const SizedBox(height: 16),
              const Text('Completion notes (optional):'),
              const SizedBox(height: 8),
              TextField(
                controller: notesController,
                maxLines: 3,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: 'Add any notes about the completed work...',
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue[200]!),
                ),
                child: const Text(
                  'The customer will be notified that the work is completed and can now rate your service.',
                  style: TextStyle(
                    fontSize: 12,
                    color: Color(0xFF2C3E50),
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              double? finalCost = double.tryParse(finalCostController.text);
              if (finalCost == null || finalCost < 0) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Please enter a valid final cost'),
                    backgroundColor: Colors.red,
                  ),
                );
                return;
              }

              Navigator.pop(context, {
                'finalCost': finalCost,
                'notes': notesController.text.trim(),
              });
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: const Text('Complete Work'),
          ),
        ],
      ),
    );
  }
}
