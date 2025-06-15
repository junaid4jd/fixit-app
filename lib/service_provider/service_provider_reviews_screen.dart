import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ServiceProviderReviewsScreen extends StatefulWidget {
  const ServiceProviderReviewsScreen({super.key});

  @override
  State<ServiceProviderReviewsScreen> createState() =>
      _ServiceProviderReviewsScreenState();
}

class _ServiceProviderReviewsScreenState
    extends State<ServiceProviderReviewsScreen> {
  List<Map<String, dynamic>> _reviews = [];
  bool _isLoading = true;
  double _averageRating = 0.0;
  int _totalReviews = 0;

  @override
  void initState() {
    super.initState();
    _loadAllReviews();
  }

  @override
  void didUpdateWidget(ServiceProviderReviewsScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    _loadAllReviews();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Small delay to ensure screen is fully loaded
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) _loadAllReviews();
    });
  }

  Future<void> _loadAllReviews() async {
    try {
      User? user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        debugPrint('🔍 Loading all reviews for handyman: ${user.uid}');

        List<Map<String, dynamic>> allReviews = [];

        // Query 1: handymanId field (try all statuses first)
        try {
          QuerySnapshot reviewsSnapshot1 = await FirebaseFirestore.instance
              .collection('reviews')
              .where('handymanId', isEqualTo: user.uid)
              .get();

          debugPrint('📋 Query 1 (handymanId): Found ${reviewsSnapshot1.docs
              .length} reviews');

          for (var doc in reviewsSnapshot1.docs) {
            Map<String, dynamic> reviewData = {
              'id': doc.id,
              ...doc.data() as Map<String, dynamic>,
            };

            // Only add approved reviews to display
            if (reviewData['status'] == 'approved') {
              allReviews.add(reviewData);
            }
            debugPrint('📄 Review: ${doc
                .id} - Status: ${reviewData['status']} - Rating: ${reviewData['rating']}');
          }
        } catch (e) {
          debugPrint('⚠️ Query 1 failed: $e');
        }

        // Query 2: handyman_id field (try all statuses)
        try {
          QuerySnapshot reviewsSnapshot2 = await FirebaseFirestore.instance
              .collection('reviews')
              .where('handyman_id', isEqualTo: user.uid)
              .get();

          debugPrint('📋 Query 2 (handyman_id): Found ${reviewsSnapshot2.docs
              .length} reviews');

          for (var doc in reviewsSnapshot2.docs) {
            Map<String, dynamic> reviewData = {
              'id': doc.id,
              ...doc.data() as Map<String, dynamic>,
            };

            // Check if this review is already in the list (avoid duplicates)
            bool isDuplicate = allReviews.any((
                existingReview) => existingReview['id'] == doc.id);

            // Only add approved reviews and avoid duplicates
            if (!isDuplicate && reviewData['status'] == 'approved') {
              allReviews.add(reviewData);
            }
            debugPrint('📄 Review: ${doc
                .id} - Status: ${reviewData['status']} - Rating: ${reviewData['rating']} - Duplicate: $isDuplicate');
          }
        } catch (e) {
          debugPrint('⚠️ Query 2 failed: $e');
        }

        // Calculate statistics
        double totalRating = 0.0;
        int reviewCount = allReviews.length;

        for (var review in allReviews) {
          totalRating += (review['rating'] ?? 0).toDouble();
        }

        double averageRating = reviewCount > 0
            ? totalRating / reviewCount
            : 0.0;

        // Format reviews for display
        List<Map<String, dynamic>> formattedReviews = allReviews.map((review) {
          return {
            'id': review['id'],
            'userName': review['user_name'] ?? 'Anonymous',
            'rating': review['rating'] ?? 0,
            'comment': review['comment'] ?? '',
            'date': _formatReviewDate(
                review['created_at'] ?? review['createdAt']),
            'category': review['category'] ?? 'General Service',
            'status': review['status'] ?? 'unknown',
          };
        }).toList();

        debugPrint('✅ Loaded ${formattedReviews
            .length} approved reviews, average rating: $averageRating');

        setState(() {
          _reviews = formattedReviews;
          _averageRating = averageRating;
          _totalReviews = reviewCount;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('❌ Error loading reviews: $e');
      setState(() {
        _isLoading = false;
      });
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
      } else if (difference < 30) {
        final weeks = (difference / 7).floor();
        return '$weeks week${weeks > 1 ? 's' : ''} ago';
      } else {
        return '${date.day}/${date.month}/${date.year}';
      }
    } catch (e) {
      debugPrint('Error formatting date: $e');
      return 'Recently';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'My Reviews',
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
            onPressed: _loadAllReviews,
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh Reviews',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
        child: CircularProgressIndicator(
          color: Color(0xFF4169E1),
        ),
      )
          : Column(
        children: [
          // Rating Summary Header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            color: const Color(0xFF4169E1),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.star,
                      color: Colors.amber,
                      size: 32,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _averageRating.toStringAsFixed(1),
                      style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Based on $_totalReviews review${_totalReviews != 1
                      ? 's'
                      : ''}',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.white.withOpacity(0.9),
                  ),
                ),
                const SizedBox(height: 16),
                // Star breakdown could go here in the future
                _buildStarBreakdown(),
              ],
            ),
          ),

          // Reviews List
          Expanded(
            child: _reviews.isEmpty
                ? _buildEmptyState()
                : RefreshIndicator(
              onRefresh: _loadAllReviews,
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _reviews.length,
                itemBuilder: (context, index) {
                  final review = _reviews[index];
                  return _buildReviewCard(review);
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStarBreakdown() {
    if (_reviews.isEmpty) return const SizedBox();

    Map<int, int> starCounts = {5: 0, 4: 0, 3: 0, 2: 0, 1: 0};

    for (var review in _reviews) {
      int rating = review['rating'] ?? 0;
      if (rating >= 1 && rating <= 5) {
        starCounts[rating] = (starCounts[rating] ?? 0) + 1;
      }
    }

    return Column(
      children: [
        for (int stars = 5; stars >= 1; stars--)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: Row(
              children: [
                Text(
                  '$stars',
                  style: const TextStyle(color: Colors.white, fontSize: 12),
                ),
                const SizedBox(width: 4),
                const Icon(Icons.star, color: Colors.amber, size: 12),
                const SizedBox(width: 8),
                Expanded(
                  child: LinearProgressIndicator(
                    value: _totalReviews > 0 ? (starCounts[stars] ?? 0) /
                        _totalReviews : 0,
                    backgroundColor: Colors.white.withOpacity(0.3),
                    valueColor: const AlwaysStoppedAnimation<Color>(
                        Colors.amber),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '${starCounts[stars]}',
                  style: const TextStyle(color: Colors.white, fontSize: 12),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: Colors.grey[200],
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.rate_review_outlined,
              size: 60,
              color: Colors.grey[400],
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'No Reviews Yet',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Complete some services to start receiving reviews',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _loadAllReviews,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF4169E1),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            icon: const Icon(Icons.refresh),
            label: const Text('Refresh'),
          ),
        ],
      ),
    );
  }

  Widget _buildReviewCard(Map<String, dynamic> review) {
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
            // Header with user info and rating
            Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: const Color(0xFF4169E1).withOpacity(0.1),
                  child: Text(
                    (review['userName'] as String).isNotEmpty
                        ? (review['userName'] as String)[0].toUpperCase()
                        : 'U',
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
                      Text(
                        review['userName'] ?? 'Anonymous',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF2C3E50),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        review['category'] ?? 'General Service',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: List.generate(5, (index) {
                        return Icon(
                          index < (review['rating'] ?? 0) ? Icons.star : Icons
                              .star_border,
                          color: Colors.amber,
                          size: 18,
                        );
                      }),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      review['date'] ?? '',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[500],
                      ),
                    ),
                  ],
                ),
              ],
            ),

            // Review comment
            if (review['comment'] != null && review['comment']
                .toString()
                .isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey[200]!),
                ),
                child: Text(
                  review['comment'],
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF2C3E50),
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
