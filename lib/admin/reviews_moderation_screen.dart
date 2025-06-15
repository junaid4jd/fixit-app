import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ReviewsModerationScreen extends StatefulWidget {
  const ReviewsModerationScreen({super.key});

  @override
  State<ReviewsModerationScreen> createState() =>
      _ReviewsModerationScreenState();
}

class _ReviewsModerationScreenState extends State<ReviewsModerationScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _approveReview(String reviewId) async {
    try {
      await FirebaseFirestore.instance
          .collection('reviews')
          .doc(reviewId)
          .update(
          {'status': 'approved', 'moderated_at': FieldValue.serverTimestamp()});

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Review approved successfully')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error approving review: $e')),
      );
    }
  }

  Future<void> _rejectReview(String reviewId, String reason) async {
    try {
      await FirebaseFirestore.instance
          .collection('reviews')
          .doc(reviewId)
          .update({
        'status': 'rejected',
        'rejection_reason': reason,
        'moderated_at': FieldValue.serverTimestamp()
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Review rejected successfully')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error rejecting review: $e')),
      );
    }
  }

  Future<void> _deleteReview(String reviewId) async {
    try {
      await FirebaseFirestore.instance
          .collection('reviews')
          .doc(reviewId)
          .delete();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Review deleted successfully')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error deleting review: $e')),
      );
    }
  }

  Future<void> _approveAllPendingReviews() async {
    try {
      final QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('reviews')
          .where('status', isEqualTo: 'pending')
          .get();

      for (final DocumentSnapshot doc in snapshot.docs) {
        await doc.reference.update({
          'status': 'approved',
          'moderated_at': FieldValue.serverTimestamp()
        });
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('All pending reviews approved')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error approving all reviews: $e')),
      );
    }
  }

  void _showRejectDialog(String reviewId) {
    final reasonController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) =>
          AlertDialog(
            title: const Text('Reject Review'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                    'Please provide a reason for rejecting this review:'),
                const SizedBox(height: 16),
                TextField(
                  controller: reasonController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    hintText: 'Enter rejection reason...',
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
                onPressed: () {
                  if (reasonController.text
                      .trim()
                      .isNotEmpty) {
                    Navigator.pop(context);
                    _rejectReview(reviewId, reasonController.text.trim());
                  }
                },
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                child: const Text(
                    'Reject', style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reviews Moderation'),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF2C3E50),
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          labelColor: const Color(0xFF4169E1),
          unselectedLabelColor: Colors.grey,
          indicatorColor: const Color(0xFF4169E1),
          tabs: const [
            Tab(text: 'Pending'),
            Tab(text: 'Approved'),
            Tab(text: 'Rejected'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildReviewsList('pending'),
          _buildReviewsList('approved'),
          _buildReviewsList('rejected'),
        ],
      ),
      floatingActionButton: _tabController.index == 0 ? FloatingActionButton
          .extended(
        onPressed: _approveAllPendingReviews,
        backgroundColor: Colors.green,
        icon: const Icon(Icons.check_circle, color: Colors.white),
        label: const Text('Approve All', style: TextStyle(color: Colors.white)),
      ) : null,
    );
  }

  Widget _buildReviewsList(String status) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('reviews')
          .where('status', isEqualTo: status)
          .orderBy('created_at', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  status == 'pending' ? Icons.pending_actions :
                  status == 'approved' ? Icons.check_circle : Icons.cancel,
                  size: 64,
                  color: Colors.grey,
                ),
                const SizedBox(height: 16),
                Text(
                  'No ${status} reviews',
                  style: const TextStyle(fontSize: 18, color: Colors.grey),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: snapshot.data!.docs.length,
          itemBuilder: (context, index) {
            final doc = snapshot.data!.docs[index];
            final review = doc.data() as Map<String, dynamic>;
            final reviewId = doc.id;

            return Card(
              margin: const EdgeInsets.only(bottom: 16),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header with user info and rating
                    Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: const Color(0xFF4169E1),
                          child: Text(
                            (review['user_name'] as String? ?? 'U')[0]
                                .toUpperCase(),
                            style: const TextStyle(color: Colors.white),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                review['user_name'] ?? 'Anonymous',
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold),
                              ),
                              Text(
                                'For: ${review['handyman_name'] ?? 'Unknown'}',
                                style: TextStyle(
                                    color: Colors.grey[600], fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                        // Rating stars
                        Row(
                          children: List.generate(5, (i) =>
                              Icon(
                                i < (review['rating'] ?? 0) ? Icons.star : Icons
                                    .star_border,
                                color: Colors.amber,
                                size: 20,
                              )),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Review comment
                    if (review['comment'] != null && review['comment']
                        .toString()
                        .isNotEmpty) ...[
                      Text(
                        review['comment'],
                        style: const TextStyle(fontSize: 14),
                      ),
                      const SizedBox(height: 12),
                    ],

                    // Category and booking info
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFF4169E1).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            review['category'] ?? 'General',
                            style: const TextStyle(
                              color: Color(0xFF4169E1),
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        const Spacer(),
                        Text(
                          _formatDate(review['created_at']),
                          style: TextStyle(
                              color: Colors.grey[600], fontSize: 12),
                        ),
                      ],
                    ),

                    // Moderation actions for pending reviews
                    if (status == 'pending') ...[
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () => _approveReview(reviewId),
                              icon: const Icon(Icons.check),
                              label: const Text('Approve'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                                foregroundColor: Colors.white,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () => _showRejectDialog(reviewId),
                              icon: const Icon(Icons.close),
                              label: const Text('Reject'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red,
                                foregroundColor: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],

                    // Show rejection reason for rejected reviews
                    if (status == 'rejected' &&
                        review['rejection_reason'] != null) ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.red.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                              color: Colors.red.withOpacity(0.3)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.info_outline, color: Colors.red,
                                size: 16),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Rejection reason: ${review['rejection_reason']}',
                                style: const TextStyle(
                                    color: Colors.red, fontSize: 12),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    // Delete option for all reviews
                    if (status != 'pending') ...[
                      const SizedBox(height: 12),
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton.icon(
                          onPressed: () => _showDeleteConfirmation(reviewId),
                          icon: const Icon(
                              Icons.delete, color: Colors.red, size: 16),
                          label: const Text(
                              'Delete', style: TextStyle(color: Colors.red)),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showDeleteConfirmation(String reviewId) {
    showDialog(
      context: context,
      builder: (context) =>
          AlertDialog(
            title: const Text('Delete Review'),
            content: const Text(
                'Are you sure you want to permanently delete this review?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  _deleteReview(reviewId);
                },
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                child: const Text(
                    'Delete', style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
    );
  }

  String _formatDate(dynamic timestamp) {
    if (timestamp == null) return '';

    final date = timestamp is Timestamp ? timestamp.toDate() : DateTime.now();
    return '${date.day}/${date.month}/${date.year}';
  }
}
