import 'package:cloud_firestore/cloud_firestore.dart';
import 'notification_service.dart';

class PlatformIntegrationService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final NotificationService _notificationService = NotificationService();

  // Admin Operations

  // Approve handyman verification
  static Future<void> approveHandymanVerification(String handymanId,
      String adminId) async {
    try {
      await _firestore.runTransaction((transaction) async {
        // Update handyman status
        final handymanRef = _firestore.collection('users').doc(handymanId);
        transaction.update(handymanRef, {
          'verification_status': 'approved',
          'is_verified': true,
          'verified_at': FieldValue.serverTimestamp(),
          'verified_by': adminId,
        });

        // Update verification document
        final verificationQuery = await _firestore
            .collection('identity_verifications')
            .where('handyman_id', isEqualTo: handymanId)
            .limit(1)
            .get();

        if (verificationQuery.docs.isNotEmpty) {
          final verificationRef = verificationQuery.docs.first.reference;
          transaction.update(verificationRef, {
            'status': 'approved',
            'reviewed_at': FieldValue.serverTimestamp(),
            'reviewed_by': adminId,
          });
        }
      });

      // Send notification to handyman
      await _notificationService.sendNotificationToUser(
        handymanId,
        'Verification Approved',
        'Congratulations! Your account has been verified. You can now start receiving bookings.',
      );

      // Create activity log
      await _createActivityLog(
        'handyman_verification_approved',
        adminId,
        {'handyman_id': handymanId},
      );
    } catch (e) {
      throw Exception('Failed to approve handyman verification: $e');
    }
  }

  // Reject handyman verification
  static Future<void> rejectHandymanVerification(String handymanId,
      String adminId, String reason) async {
    try {
      await _firestore.runTransaction((transaction) async {
        // Update handyman status
        final handymanRef = _firestore.collection('users').doc(handymanId);
        transaction.update(handymanRef, {
          'verification_status': 'rejected',
          'is_verified': false,
          'rejection_reason': reason,
          'rejected_at': FieldValue.serverTimestamp(),
          'rejected_by': adminId,
        });

        // Update verification document
        final verificationQuery = await _firestore
            .collection('identity_verifications')
            .where('handyman_id', isEqualTo: handymanId)
            .limit(1)
            .get();

        if (verificationQuery.docs.isNotEmpty) {
          final verificationRef = verificationQuery.docs.first.reference;
          transaction.update(verificationRef, {
            'status': 'rejected',
            'rejection_reason': reason,
            'reviewed_at': FieldValue.serverTimestamp(),
            'reviewed_by': adminId,
          });
        }
      });

      // Send notification to handyman
      await _notificationService.sendNotificationToUser(
        handymanId,
        'Verification Rejected',
        'Your verification has been rejected. Reason: $reason. Please resubmit with correct documents.',
      );

      // Create activity log
      await _createActivityLog(
        'handyman_verification_rejected',
        adminId,
        {'handyman_id': handymanId, 'reason': reason},
      );
    } catch (e) {
      throw Exception('Failed to reject handyman verification: $e');
    }
  }

  // Admin approve review
  static Future<void> approveReview(String reviewId, String adminId) async {
    try {
      await _firestore.collection('reviews').doc(reviewId).update({
        'status': 'approved',
        'approved_at': FieldValue.serverTimestamp(),
        'approved_by': adminId,
      });

      // Get review data
      final reviewDoc = await _firestore
          .collection('reviews')
          .doc(reviewId)
          .get();
      final reviewData = reviewDoc.data()!;

      // Update handyman's public rating
      await _updateHandymanPublicRating(reviewData['handyman_id']);

      // Notify handyman
      await _notificationService.sendNotificationToUser(
        reviewData['handyman_id'],
        'Review Published',
        'Your ${reviewData['rating']}-star review from ${reviewData['user_name']} is now public.',
      );
    } catch (e) {
      throw Exception('Failed to approve review: $e');
    }
  }

  // User Operations

  // Create user profile with role-specific fields
  static Future<void> createUserProfile({
    required String userId,
    required String role,
    required Map<String, dynamic> profileData,
  }) async {
    try {
      final userData = {
        'role': role,
        'created_at': FieldValue.serverTimestamp(),
        'updated_at': FieldValue.serverTimestamp(),
        'is_active': true,
        ...profileData,
      };

      // Add role-specific fields
      if (role == 'handyman') {
        userData.addAll({
          'verification_status': 'pending',
          'is_verified': false,
          'average_rating': 0.0,
          'total_reviews': 0,
          'total_bookings': 0,
          'completed_bookings': 0,
          'statistics': {
            'total_requests': 0,
            'total_accepted': 0,
            'total_completed': 0,
          },
        });
      } else if (role == 'user') {
        userData.addAll({
          'total_bookings': 0,
          'total_spent': 0.0,
          'favorite_categories': [],
        });
      }

      await _firestore.collection('users').doc(userId).set(userData);

      // Initialize user notifications settings
      await _firestore.collection('user_settings').doc(userId).set({
        'notifications_enabled': true,
        'email_notifications': true,
        'push_notifications': true,
        'sms_notifications': false,
        'created_at': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Failed to create user profile: $e');
    }
  }

  // Handyman Operations

  // Update handyman availability
  static Future<void> updateHandymanAvailability(String handymanId,
      Map<String, dynamic> availability) async {
    try {
      await _firestore.collection('users').doc(handymanId).update({
        'availability': availability,
        'updated_at': FieldValue.serverTimestamp(),
      });

      // Notify users who bookmarked this handyman
      await _notifyBookmarkedUsers(handymanId, 'Availability Updated');
    } catch (e) {
      throw Exception('Failed to update handyman availability: $e');
    }
  }

  // Update handyman services
  static Future<void> updateHandymanServices(String handymanId,
      List<String> services, Map<String, double> hourlyRates) async {
    try {
      await _firestore.collection('users').doc(handymanId).update({
        'services': services,
        'hourly_rates': hourlyRates,
        'updated_at': FieldValue.serverTimestamp(),
      });

      // Update existing bookings if rates changed
      await _updatePendingBookingRates(handymanId, hourlyRates);
    } catch (e) {
      throw Exception('Failed to update handyman services: $e');
    }
  }

  // Cross-Platform Integration

  // Match users with handymen based on preferences
  static Future<List<Map<String, dynamic>>> getRecommendedHandymen(
      String userId, String category) async {
    try {
      // Get user preferences
      final userDoc = await _firestore.collection('users').doc(userId).get();
      final userData = userDoc.data() ?? {};
      final userCity = userData['city'] ?? '';

      // Get available handymen
      Query handymenQuery = _firestore
          .collection('users')
          .where('role', isEqualTo: 'handyman')
          .where('is_verified', isEqualTo: true)
          .where('is_active', isEqualTo: true)
          .where('services', arrayContains: category);

      if (userCity.isNotEmpty) {
        handymenQuery = handymenQuery.where('city', isEqualTo: userCity);
      }

      final handymenSnapshot = await handymenQuery.get();

      List<Map<String, dynamic>> recommendations = [];

      for (var doc in handymenSnapshot.docs) {
        final handymanData = doc.data() as Map<String, dynamic>;
        handymanData['id'] = doc.id;

        // Calculate compatibility score
        double score = _calculateCompatibilityScore(
            userData, handymanData, category);
        handymanData['compatibility_score'] = score;

        recommendations.add(handymanData);
      }

      // Sort by compatibility score
      recommendations.sort((a, b) =>
          b['compatibility_score'].compareTo(a['compatibility_score']));

      return recommendations.take(10).toList();
    } catch (e) {
      throw Exception('Failed to get recommended handymen: $e');
    }
  }

  // Real-time booking status sync
  static Stream<DocumentSnapshot> getBookingRealTimeUpdates(String bookingId) {
    return _firestore.collection('bookings').doc(bookingId).snapshots();
  }

  // Analytics and Reporting

  // Get platform-wide analytics
  static Future<Map<String, dynamic>> getPlatformAnalytics() async {
    try {
      final now = DateTime.now();
      final startOfMonth = DateTime(now.year, now.month, 1);

      // Get all collections data
      final usersSnapshot = await _firestore.collection('users').get();
      final bookingsSnapshot = await _firestore.collection('bookings').get();
      final reviewsSnapshot = await _firestore.collection('reviews').get();

      // Categorize users
      int totalUsers = 0;
      int totalHandymen = 0;
      int verifiedHandymen = 0;
      int activeUsers = 0;

      for (var doc in usersSnapshot.docs) {
        final userData = doc.data();
        totalUsers++;

        if (userData['role'] == 'handyman') {
          totalHandymen++;
          if (userData['is_verified'] == true) {
            verifiedHandymen++;
          }
        }

        if (userData['is_active'] == true) {
          activeUsers++;
        }
      }

      // Booking statistics
      int totalBookings = bookingsSnapshot.docs.length;
      int completedBookings = 0;
      int thisMonthBookings = 0;
      double totalRevenue = 0;

      for (var doc in bookingsSnapshot.docs) {
        final bookingData = doc.data();

        if (bookingData['status'] == 'completed') {
          completedBookings++;
          totalRevenue +=
              (bookingData['final_cost'] ?? bookingData['estimated_cost'] ?? 0)
                  .toDouble();
        }

        final createdAt = bookingData['created_at'] as Timestamp?;
        if (createdAt != null && createdAt.toDate().isAfter(startOfMonth)) {
          thisMonthBookings++;
        }
      }

      // Review statistics
      int totalReviews = reviewsSnapshot.docs.length;
      int approvedReviews = 0;
      double averageRating = 0;

      for (var doc in reviewsSnapshot.docs) {
        final reviewData = doc.data();

        if (reviewData['status'] == 'approved') {
          approvedReviews++;
          averageRating += (reviewData['rating'] ?? 0).toDouble();
        }
      }

      if (approvedReviews > 0) {
        averageRating = averageRating / approvedReviews;
      }

      return {
        'users': {
          'total': totalUsers,
          'active': activeUsers,
          'customers': totalUsers - totalHandymen,
          'handymen': totalHandymen,
          'verified_handymen': verifiedHandymen,
        },
        'bookings': {
          'total': totalBookings,
          'completed': completedBookings,
          'this_month': thisMonthBookings,
          'completion_rate': totalBookings > 0 ? (completedBookings /
              totalBookings * 100) : 0,
        },
        'revenue': {
          'total': totalRevenue,
          'average_per_booking': completedBookings > 0 ? (totalRevenue /
              completedBookings) : 0,
        },
        'reviews': {
          'total': totalReviews,
          'approved': approvedReviews,
          'average_rating': averageRating,
        },
      };
    } catch (e) {
      throw Exception('Failed to get platform analytics: $e');
    }
  }

  // Utility Methods

  // Create activity log
  static Future<void> _createActivityLog(String action, String userId,
      Map<String, dynamic> metadata) async {
    await _firestore.collection('activity_logs').add({
      'action': action,
      'user_id': userId,
      'metadata': metadata,
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  // Update handyman public rating
  static Future<void> _updateHandymanPublicRating(String handymanId) async {
    try {
      final reviewsSnapshot = await _firestore
          .collection('reviews')
          .where('handyman_id', isEqualTo: handymanId)
          .where('status', isEqualTo: 'approved')
          .get();

      if (reviewsSnapshot.docs.isEmpty) return;

      double totalRating = 0;
      int count = 0;

      for (var doc in reviewsSnapshot.docs) {
        final reviewData = doc.data();
        totalRating += (reviewData['rating'] ?? 0).toDouble();
        count++;
      }

      final averageRating = totalRating / count;

      await _firestore.collection('users').doc(handymanId).update({
        'average_rating': averageRating,
        'total_reviews': count,
      });
    } catch (e) {
      print('Error updating handyman public rating: $e');
    }
  }

  // Notify bookmarked users
  static Future<void> _notifyBookmarkedUsers(String handymanId,
      String title) async {
    try {
      final bookmarksSnapshot = await _firestore
          .collection('user_bookmarks')
          .where('handyman_id', isEqualTo: handymanId)
          .get();

      for (var doc in bookmarksSnapshot.docs) {
        final bookmarkData = doc.data();
        await _notificationService.sendNotificationToUser(
          bookmarkData['user_id'],
          title,
          'Updates from your bookmarked handyman.',
        );
      }
    } catch (e) {
      print('Error notifying bookmarked users: $e');
    }
  }

  // Update pending booking rates
  static Future<void> _updatePendingBookingRates(String handymanId,
      Map<String, double> newRates) async {
    try {
      final pendingBookingsSnapshot = await _firestore
          .collection('bookings')
          .where('handyman_id', isEqualTo: handymanId)
          .where('status', isEqualTo: 'pending')
          .get();

      for (var doc in pendingBookingsSnapshot.docs) {
        final bookingData = doc.data();
        final category = bookingData['category'];

        if (newRates.containsKey(category)) {
          await doc.reference.update({
            'estimated_cost': newRates[category],
            'rate_updated': true,
          });
        }
      }
    } catch (e) {
      print('Error updating pending booking rates: $e');
    }
  }

  // Calculate compatibility score
  static double _calculateCompatibilityScore(Map<String, dynamic> userData,
      Map<String, dynamic> handymanData, String category) {
    double score = 0;

    // Base score for being in same city
    if (userData['city'] == handymanData['city']) {
      score += 30;
    }

    // Rating score (0-25 points)
    final rating = handymanData['average_rating'] ?? 0.0;
    score += (rating / 5.0) * 25;

    // Experience score (0-20 points)
    final totalBookings = handymanData['total_bookings'] ?? 0;
    if (totalBookings > 100) {
      score += 20;
    } else if (totalBookings > 50) {
      score += 15;
    } else if (totalBookings > 20) {
      score += 10;
    } else if (totalBookings > 5) {
      score += 5;
    }

    // Price match score (0-15 points)
    final userPricePreference = userData['price_preference'] ?? 'medium';
    final handymanRate = handymanData['hourly_rates']?[category] ?? 0.0;

    if (userPricePreference == 'low' && handymanRate < 15) {
      score += 15;
    } else if (userPricePreference == 'medium' && handymanRate >= 15 &&
        handymanRate <= 30) {
      score += 15;
    } else if (userPricePreference == 'high' && handymanRate > 30) {
      score += 15;
    } else {
      score += 5; // Partial match
    }

    // Availability score (0-10 points)
    final availability = handymanData['availability'] ?? {};
    if (availability.isNotEmpty) {
      score += 10; // Has availability set
    }

    return score;
  }

  // Get user interaction history
  static Future<Map<String, dynamic>> getUserInteractionHistory(
      String userId) async {
    try {
      // Get user's bookings
      final bookingsSnapshot = await _firestore
          .collection('bookings')
          .where('user_id', isEqualTo: userId)
          .orderBy('created_at', descending: true)
          .get();

      // Get user's reviews
      final reviewsSnapshot = await _firestore
          .collection('reviews')
          .where('user_id', isEqualTo: userId)
          .orderBy('created_at', descending: true)
          .get();

      List<Map<String, dynamic>> bookings = [];
      List<Map<String, dynamic>> reviews = [];

      for (var doc in bookingsSnapshot.docs) {
        final data = doc.data();
        data['id'] = doc.id;
        bookings.add(data);
      }

      for (var doc in reviewsSnapshot.docs) {
        final data = doc.data();
        data['id'] = doc.id;
        reviews.add(data);
      }

      return {
        'bookings': bookings,
        'reviews': reviews,
        'total_bookings': bookings.length,
        'completed_bookings': bookings
            .where((b) => b['status'] == 'completed')
            .length,
        'total_reviews': reviews.length,
      };
    } catch (e) {
      throw Exception('Failed to get user interaction history: $e');
    }
  }

  // Get handyman performance overview
  static Future<Map<String, dynamic>> getHandymanPerformanceOverview(
      String handymanId) async {
    try {
      // Get handyman's bookings
      final bookingsSnapshot = await _firestore
          .collection('bookings')
          .where('handyman_id', isEqualTo: handymanId)
          .get();

      // Get handyman's reviews
      final reviewsSnapshot = await _firestore
          .collection('reviews')
          .where('handyman_id', isEqualTo: handymanId)
          .where('status', isEqualTo: 'approved')
          .get();

      int totalBookings = bookingsSnapshot.docs.length;
      int completedBookings = 0;
      int cancelledBookings = 0;
      double totalEarnings = 0;

      for (var doc in bookingsSnapshot.docs) {
        final data = doc.data();

        if (data['status'] == 'completed') {
          completedBookings++;
          totalEarnings +=
              (data['final_cost'] ?? data['estimated_cost'] ?? 0).toDouble();
        } else if (data['status'] == 'cancelled') {
          cancelledBookings++;
        }
      }

      double averageRating = 0;
      if (reviewsSnapshot.docs.isNotEmpty) {
        double totalRating = 0;
        for (var doc in reviewsSnapshot.docs) {
          totalRating += (doc.data()['rating'] ?? 0).toDouble();
        }
        averageRating = totalRating / reviewsSnapshot.docs.length;
      }

      return {
        'total_bookings': totalBookings,
        'completed_bookings': completedBookings,
        'cancelled_bookings': cancelledBookings,
        'completion_rate': totalBookings > 0 ? (completedBookings /
            totalBookings * 100) : 0,
        'total_earnings': totalEarnings,
        'average_rating': averageRating,
        'total_reviews': reviewsSnapshot.docs.length,
      };
    } catch (e) {
      throw Exception('Failed to get handyman performance overview: $e');
    }
  }
}
