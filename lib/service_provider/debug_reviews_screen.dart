import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class DebugReviewsScreen extends StatefulWidget {
  const DebugReviewsScreen({super.key});

  @override
  State<DebugReviewsScreen> createState() => _DebugReviewsScreenState();
}

class _DebugReviewsScreenState extends State<DebugReviewsScreen> {
  List<Map<String, dynamic>> _allReviews = [];
  List<Map<String, dynamic>> _myReviews = [];
  bool _isLoading = true;
  String? _currentUserId;

  @override
  void initState() {
    super.initState();
    _currentUserId = FirebaseAuth.instance.currentUser?.uid;
    _loadAllReviewsForDebugging();
  }

  Future<void> _loadAllReviewsForDebugging() async {
    try {
      setState(() => _isLoading = true);

      debugPrint(
          '🔍 Starting comprehensive review debug for user: $_currentUserId');

      // Get ALL reviews from database
      QuerySnapshot allReviewsSnapshot = await FirebaseFirestore.instance
          .collection('reviews')
          .get();

      debugPrint(
          '📊 Total reviews in database: ${allReviewsSnapshot.docs.length}');

      List<Map<String, dynamic>> allReviews = [];
      List<Map<String, dynamic>> myReviews = [];

      for (var doc in allReviewsSnapshot.docs) {
        Map<String, dynamic> reviewData = {
          'id': doc.id,
          ...doc.data() as Map<String, dynamic>,
        };

        allReviews.add(reviewData);

        // Check if this review belongs to current user
        String? handymanId = reviewData['handyman_id'] ??
            reviewData['handymanId'];
        if (handymanId == _currentUserId) {
          myReviews.add(reviewData);
          debugPrint('✅ Found my review: ${doc
              .id} - Status: ${reviewData['status']} - Rating: ${reviewData['rating']}');
        }
      }

      // Debug print all reviews
      debugPrint('📋 All Reviews Debug:');
      for (int i = 0; i < allReviews.length; i++) {
        var review = allReviews[i];
        debugPrint(
            'Review $i: ID=${review['id']}, handyman_id=${review['handyman_id']}, handymanId=${review['handymanId']}, status=${review['status']}, rating=${review['rating']}, user_name=${review['user_name']}');
      }

      debugPrint('🎯 My Reviews: ${myReviews.length} found');

      setState(() {
        _allReviews = allReviews;
        _myReviews = myReviews;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('❌ Error in debug loading: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _approveAllMyReviews() async {
    try {
      for (var review in _myReviews) {
        if (review['status'] != 'approved') {
          await FirebaseFirestore.instance
              .collection('reviews')
              .doc(review['id'])
              .update({
            'status': 'approved',
            'moderated_at': FieldValue.serverTimestamp(),
          });
          debugPrint('✅ Approved review: ${review['id']}');
        }
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('All your reviews have been approved for testing!'),
          backgroundColor: Colors.green,
        ),
      );

      // Reload data
      _loadAllReviewsForDebugging();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error approving reviews: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Debug Reviews'),
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            onPressed: _loadAllReviewsForDebugging,
            icon: const Icon(Icons.refresh),
          ),
          IconButton(
            onPressed: _approveAllMyReviews,
            icon: const Icon(Icons.check_circle),
            tooltip: 'Approve All My Reviews',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Summary Cards
            Row(
              children: [
                Expanded(
                  child: _buildSummaryCard(
                    'Total Reviews',
                    '${_allReviews.length}',
                    Colors.blue,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildSummaryCard(
                    'My Reviews',
                    '${_myReviews.length}',
                    Colors.green,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // Current User Info
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Current User ID: $_currentUserId',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text('Reviews found for this user: ${_myReviews.length}'),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // My Reviews Section
            const Text(
              'My Reviews:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),

            if (_myReviews.isEmpty)
              const Card(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Text('No reviews found for your account'),
                ),
              )
            else
              ..._myReviews.map((review) =>
                  _buildDebugReviewCard(review, true)),

            const SizedBox(height: 30),

            // All Reviews Section
            Text(
              'All Reviews in Database (${_allReviews.length}):',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),

            ..._allReviews.map((review) =>
                _buildDebugReviewCard(review, false)),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCard(String title, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDebugReviewCard(Map<String, dynamic> review, bool isMine) {
    Color cardColor = isMine ? Colors.green : Colors.grey;
    String status = review['status'] ?? 'unknown';
    Color statusColor = status == 'approved' ? Colors.green :
    status == 'pending' ? Colors.orange : Colors.red;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      color: cardColor.withOpacity(0.05),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    status.toUpperCase(),
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: statusColor,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                if (isMine)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      'MINE',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
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
              'ID: ${review['id']}',
              style: const TextStyle(fontSize: 10, fontFamily: 'monospace'),
            ),
            const SizedBox(height: 4),
            Text('User: ${review['user_name'] ?? 'N/A'}'),
            Text('Rating: ${review['rating'] ?? 'N/A'}'),
            Text('Comment: ${review['comment'] ?? 'N/A'}'),
            Text('handyman_id: ${review['handyman_id'] ?? 'N/A'}'),
            Text('handymanId: ${review['handymanId'] ?? 'N/A'}'),
            Text('Status: ${review['status'] ?? 'N/A'}'),
            Text('Category: ${review['category'] ?? 'N/A'}'),
            if (review['created_at'] != null)
              Text('Created: ${(review['created_at'] as Timestamp).toDate()}'),
          ],
        ),
      ),
    );
  }
}