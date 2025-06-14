import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'notification_service.dart';

class BookingService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final NotificationService _notificationService = NotificationService();

  // Create a new booking
  static Future<String> createBooking({
    required String userId,
    required String handymanId,
    required String category,
    required String description,
    required DateTime scheduledDate,
    required TimeOfDay scheduledTime,
    required String address,
    required String phoneNumber,
    required double estimatedCost,
    String? specialInstructions,
  }) async {
    try {
      final bookingRef = await _firestore.collection('bookings').add({
        'userId': userId,
        'handymanId': handymanId,
        'category': category,
        'description': description,
        'scheduledDate': Timestamp.fromDate(scheduledDate),
        'scheduledTime': '${scheduledTime.hour}:${scheduledTime.minute}',
        'address': address,
        'phoneNumber': phoneNumber,
        'estimatedCost': estimatedCost,
        'specialInstructions': specialInstructions,
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'paymentStatus': 'pending',
        'isReviewed': false,
        'bookingType': 'general',
      });

      // Get user and handyman info for notifications
      final userDoc = await _firestore.collection('users').doc(userId).get();
      final handymanDoc = await _firestore
          .collection('users')
          .doc(handymanId)
          .get();

      final userName = userDoc.data()?['fullName'] ?? 'User';

      // Send notification to handyman
      await _notificationService.sendNotificationToUser(
        handymanId,
        'New Booking Request',
        'You have a new booking request from $userName for $category service.',
      );

      // Update handyman's statistics
      await _updateHandymanStats(handymanId, 'booking_requested');

      return bookingRef.id;
    } catch (e) {
      throw Exception('Failed to create booking: $e');
    }
  }

  // Create a booking request with enhanced validation and service support
  static Future<String> createBookingRequest({
    required String userId,
    required String handymanId,
    required String category,
    required String serviceDescription,
    required DateTime scheduledDate,
    required String timeSlot,
    required double estimatedCost,
    required String address,
    required Map<String, dynamic> contactInfo,
    String? serviceId,
    String? serviceTitle,
    String? serviceName,
  }) async {
    try {
      // Validate required fields
      if (userId.isEmpty || handymanId.isEmpty) {
        throw Exception('Invalid user or handyman ID');
      }

      if (serviceDescription
          .trim()
          .isEmpty) {
        throw Exception('Service description is required');
      }

      if (address
          .trim()
          .isEmpty) {
        throw Exception('Service address is required');
      }

      if (contactInfo['phone'] == null || contactInfo['phone']
          .toString()
          .trim()
          .isEmpty) {
        throw Exception('Phone number is required');
      }

      // Validate scheduled date is not in the past
      if (scheduledDate.isBefore(
          DateTime.now().subtract(const Duration(hours: 1)))) {
        throw Exception('Scheduled date cannot be in the past');
      }

      // Validate time slot format
      if (!RegExp(r'^\d{1,2}:\d{2}$').hasMatch(timeSlot)) {
        throw Exception('Invalid time slot format. Use HH:MM format');
      }

      Map<String, dynamic> bookingData = {
        'userId': userId,
        'handymanId': handymanId,
        'category': category,
        'description': serviceDescription.trim(),
        'scheduledDate': Timestamp.fromDate(scheduledDate),
        'scheduledTime': timeSlot,
        'estimatedCost': estimatedCost,
        'address': address.trim(),
        'phoneNumber': contactInfo['phone'].toString().trim(),
        'specialInstructions': contactInfo['notes']?.toString().trim() ?? '',
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'paymentStatus': 'pending',
        'isReviewed': false,
      };

      // Add service-specific fields if this is a service booking
      if (serviceId != null && serviceId.isNotEmpty) {
        bookingData['serviceId'] = serviceId;
        bookingData['serviceTitle'] = serviceTitle ?? '';
        bookingData['serviceName'] = serviceName ?? serviceTitle ?? '';
        bookingData['bookingType'] = 'service';
      } else {
        bookingData['bookingType'] = 'general';
      }

      debugPrint('🔧 Creating booking with data: $bookingData');

      DocumentReference bookingRef = await _firestore
          .collection('bookings')
          .add(bookingData);

      debugPrint('✅ Booking created with ID: ${bookingRef.id}');

      // Get user and handyman info for notifications
      final userDoc = await _firestore.collection('users').doc(userId).get();
      final handymanDoc = await _firestore
          .collection('users')
          .doc(handymanId)
          .get();

      final userName = userDoc.data()?['fullName'] ?? 'User';
      final handymanName = handymanDoc.data()?['fullName'] ?? 'Handyman';

      // Send notification to handyman
      await _notificationService.sendNotificationToUser(
        handymanId,
        'New Booking Request',
        'You have a new booking request from $userName for $category service.',
      );

      // Initialize chat for this booking if it doesn't exist
      await _initializeChatForBooking(bookingRef.id, userId, handymanId);

      // Update handyman's statistics
      await _updateHandymanStats(handymanId, 'booking_requested');

      return bookingRef.id;
    } catch (e) {
      debugPrint('💥 Error creating booking request: $e');
      throw Exception('Failed to create booking request: ${e.toString()}');
    }
  }

  // Initialize chat for booking
  static Future<void> _initializeChatForBooking(String bookingId, String userId,
      String handymanId) async {
    try {
      await _firestore.collection('chats').doc(bookingId).set({
        'bookingId': bookingId,
        'userId': userId,
        'handymanId': handymanId,
        'lastMessage': 'Booking created - you can now chat with your handyman',
        'lastMessageTime': FieldValue.serverTimestamp(),
        'lastSenderId': 'system',
        'createdAt': FieldValue.serverTimestamp(),
        'participants': [userId, handymanId],
      });
    } catch (e) {
      debugPrint('Error initializing chat: $e');
      // Don't throw error as this is not critical for booking creation
    }
  }

  // Accept booking (handyman)
  static Future<void> acceptBooking(String bookingId, String handymanId) async {
    try {
      await _firestore.collection('bookings').doc(bookingId).update({
        'status': 'accepted',
        'accepted_at': FieldValue.serverTimestamp(),
        'updated_at': FieldValue.serverTimestamp(),
      });

      // Get booking and user info
      final bookingDoc = await _firestore
          .collection('bookings')
          .doc(bookingId)
          .get();
      final bookingData = bookingDoc.data()!;
      final userId = bookingData['user_id'];

      final userDoc = await _firestore.collection('users').doc(userId).get();
      final handymanDoc = await _firestore
          .collection('users')
          .doc(handymanId)
          .get();

      final handymanName = handymanDoc.data()?['name'] ?? 'Handyman';

      // Send notification to user
      await _notificationService.sendNotificationToUser(
        userId,
        'Booking Accepted',
        '$handymanName has accepted your booking request for ${bookingData['category']} service.',
      );

      // Update handyman's statistics
      await _updateHandymanStats(handymanId, 'booking_accepted');
    } catch (e) {
      throw Exception('Failed to accept booking: $e');
    }
  }

  // Reject booking (handyman)
  static Future<void> rejectBooking(String bookingId, String handymanId,
      String reason) async {
    try {
      await _firestore.collection('bookings').doc(bookingId).update({
        'status': 'rejected',
        'rejection_reason': reason,
        'rejected_at': FieldValue.serverTimestamp(),
        'updated_at': FieldValue.serverTimestamp(),
      });

      // Get booking and user info
      final bookingDoc = await _firestore
          .collection('bookings')
          .doc(bookingId)
          .get();
      final bookingData = bookingDoc.data()!;
      final userId = bookingData['user_id'];

      final handymanDoc = await _firestore
          .collection('users')
          .doc(handymanId)
          .get();
      final handymanName = handymanDoc.data()?['name'] ?? 'Handyman';

      // Send notification to user
      await _notificationService.sendNotificationToUser(
        userId,
        'Booking Rejected',
        '$handymanName has rejected your booking request. Reason: $reason',
      );

    } catch (e) {
      throw Exception('Failed to reject booking: $e');
    }
  }

  // Start service (handyman)
  static Future<void> startService(String bookingId, String handymanId) async {
    try {
      await _firestore.collection('bookings').doc(bookingId).update({
        'status': 'in_progress',
        'started_at': FieldValue.serverTimestamp(),
        'updated_at': FieldValue.serverTimestamp(),
      });

      // Get booking and user info
      final bookingDoc = await _firestore
          .collection('bookings')
          .doc(bookingId)
          .get();
      final bookingData = bookingDoc.data()!;
      final userId = bookingData['user_id'];

      final handymanDoc = await _firestore
          .collection('users')
          .doc(handymanId)
          .get();
      final handymanName = handymanDoc.data()?['name'] ?? 'Handyman';

      // Send notification to user
      await _notificationService.sendNotificationToUser(
        userId,
        'Service Started',
        '$handymanName has started working on your ${bookingData['category']} service.',
      );

    } catch (e) {
      throw Exception('Failed to start service: $e');
    }
  }

  // Complete service (handyman)
  static Future<void> completeService(String bookingId, String handymanId, {
    double? finalCost,
    String? completionNotes,
    List<String>? completionPhotos,
  }) async {
    try {
      final updateData = {
        'status': 'completed',
        'completed_at': FieldValue.serverTimestamp(),
        'updated_at': FieldValue.serverTimestamp(),
      };

      if (finalCost != null) {
        updateData['final_cost'] = finalCost;
      }
      if (completionNotes != null) {
        updateData['completion_notes'] = completionNotes;
      }
      if (completionPhotos != null) {
        updateData['completion_photos'] = completionPhotos;
      }

      await _firestore.collection('bookings').doc(bookingId).update(updateData);

      // Get booking and user info
      final bookingDoc = await _firestore
          .collection('bookings')
          .doc(bookingId)
          .get();
      final bookingData = bookingDoc.data()!;
      final userId = bookingData['user_id'];

      final handymanDoc = await _firestore
          .collection('users')
          .doc(handymanId)
          .get();
      final handymanName = handymanDoc.data()?['name'] ?? 'Handyman';

      // Send notification to user
      await _notificationService.sendNotificationToUser(
        userId,
        'Service Completed',
        '$handymanName has completed your ${bookingData['category']} service. Please rate and review the service.',
      );

      // Update handyman's statistics
      await _updateHandymanStats(handymanId, 'booking_completed');
    } catch (e) {
      throw Exception('Failed to complete service: $e');
    }
  }

  // Cancel booking by user
  static Future<void> cancelBookingByUser(String bookingId, String userId,
      String reason) async {
    try {
      await _firestore.collection('bookings').doc(bookingId).update({
        'status': 'cancelled',
        'cancellation_reason': reason,
        'cancelled_at': FieldValue.serverTimestamp(),
        'cancelled_by': 'user',
        'updated_at': FieldValue.serverTimestamp(),
      });

      // Get booking and handyman info
      final bookingDoc = await _firestore
          .collection('bookings')
          .doc(bookingId)
          .get();
      final bookingData = bookingDoc.data()!;
      final handymanId = bookingData['handyman_id'];

      final userDoc = await _firestore.collection('users').doc(userId).get();
      final userName = userDoc.data()?['name'] ?? 'User';

      // Send notification to handyman if booking was accepted
      if (bookingData['status'] == 'accepted' ||
          bookingData['status'] == 'in_progress') {
        await _notificationService.sendNotificationToUser(
          handymanId,
          'Booking Cancelled',
          '$userName has cancelled the booking for ${bookingData['category']} service. Reason: $reason',
        );
      }

    } catch (e) {
      throw Exception('Failed to cancel booking: $e');
    }
  }

  // Submit review (user)
  static Future<void> submitReview({
    required String bookingId,
    required String userId,
    required String handymanId,
    required int rating,
    required String comment,
    required String category,
  }) async {
    try {
      // Get user and handyman info
      final userDoc = await _firestore.collection('users').doc(userId).get();
      final handymanDoc = await _firestore
          .collection('users')
          .doc(handymanId)
          .get();

      final userName = userDoc.data()?['name'] ?? 'User';
      final handymanName = handymanDoc.data()?['name'] ?? 'Handyman';

      // Create review
      await _firestore.collection('reviews').add({
        'booking_id': bookingId,
        'user_id': userId,
        'user_name': userName,
        'handyman_id': handymanId,
        'handyman_name': handymanName,
        'rating': rating,
        'comment': comment,
        'category': category,
        'status': 'pending', // Reviews need admin approval
        'created_at': FieldValue.serverTimestamp(),
      });

      // Update booking to mark as reviewed
      await _firestore.collection('bookings').doc(bookingId).update({
        'is_reviewed': true,
        'reviewed_at': FieldValue.serverTimestamp(),
      });

      // Update handyman's rating statistics
      await _updateHandymanRating(handymanId, rating.toDouble());

      // Send notification to handyman
      await _notificationService.sendNotificationToUser(
        handymanId,
        'New Review Received',
        '$userName left a $rating-star review for your service.',
      );

    } catch (e) {
      throw Exception('Failed to submit review: $e');
    }
  }

  // Get bookings for current user
  static Stream<QuerySnapshot> getUserBookings() {
    User? user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception('User not authenticated');

    return _firestore
        .collection('bookings')
        .where('user_id', isEqualTo: user.uid)
        .orderBy('created_at', descending: true)
        .snapshots();
  }

  // Get bookings for current handyman
  static Stream<QuerySnapshot> getHandymanBookings() {
    User? user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception('User not authenticated');

    return _firestore
        .collection('bookings')
        .where('handyman_id', isEqualTo: user.uid)
        .orderBy('created_at', descending: true)
        .snapshots();
  }

  // Get pending bookings for handyman
  static Stream<QuerySnapshot> getPendingBookingsForHandyman(
      String handymanId) {
    return _firestore
        .collection('bookings')
        .where('handyman_id', isEqualTo: handymanId)
        .where('status', isEqualTo: 'pending')
        .orderBy('created_at', descending: true)
        .snapshots();
  }

  // Update booking status
  static Future<void> updateBookingStatus(String bookingId, String status,
      {String? reason}) async {
    try {
      final updateData = {
        'status': status,
        'updated_at': FieldValue.serverTimestamp(),
      };

      if (reason != null) {
        if (status == 'rejected') {
          updateData['rejection_reason'] = reason;
          updateData['rejected_at'] = FieldValue.serverTimestamp();
        } else if (status == 'cancelled') {
          updateData['cancellation_reason'] = reason;
          updateData['cancelled_at'] = FieldValue.serverTimestamp();
          updateData['cancelled_by'] = 'handyman';
        }
      }

      await _firestore.collection('bookings').doc(bookingId).update(updateData);

      // Send notifications using the notification service
      await _notificationService.sendBookingNotification(bookingId, status);

    } catch (e) {
      throw Exception('Failed to update booking status: $e');
    }
  }

  // Cancel booking with reason
  static Future<void> cancelBooking(String bookingId, String reason) async {
    return await updateBookingStatus(bookingId, 'cancelled', reason: reason);
  }

  // Complete booking and add review
  static Future<void> completeBookingWithReview(String bookingId,
      String handymanId, int rating, String review) async {
    // First update booking status to completed
    await updateBookingStatus(bookingId, 'completed');

    // Then add the review
    await submitReview(
      bookingId: bookingId,
      userId: FirebaseAuth.instance.currentUser!.uid,
      handymanId: handymanId,
      rating: rating,
      comment: review,
      category: 'General',
    );
  }

  // Get booking statistics for admin
  static Future<Map<String, dynamic>> getBookingStatistics() async {
    try {
      DateTime now = DateTime.now();
      DateTime startOfMonth = DateTime(now.year, now.month, 1);
      DateTime startOfWeek = now.subtract(Duration(days: now.weekday - 1));

      QuerySnapshot allBookings = await _firestore.collection('bookings').get();

      QuerySnapshot completedBookings = await _firestore
          .collection('bookings')
          .where('status', isEqualTo: 'completed')
          .get();

      QuerySnapshot thisMonthBookings = await _firestore
          .collection('bookings')
          .where('created_at',
          isGreaterThanOrEqualTo: Timestamp.fromDate(startOfMonth))
          .get();

      QuerySnapshot thisWeekBookings = await _firestore
          .collection('bookings')
          .where(
          'created_at', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfWeek))
          .get();

      double totalRevenue = 0;
      double thisMonthRevenue = 0;

      for (var doc in completedBookings.docs) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        double amount = data['estimated_cost'] ?? 0;
        totalRevenue += amount;

        // Check if completed this month
        if (data['completed_at'] != null) {
          DateTime completedAt = (data['completed_at'] as Timestamp).toDate();
          if (completedAt.isAfter(startOfMonth)) {
            thisMonthRevenue += amount;
          }
        }
      }

      return {
        'totalBookings': allBookings.docs.length,
        'completedBookings': completedBookings.docs.length,
        'thisMonthBookings': thisMonthBookings.docs.length,
        'thisWeekBookings': thisWeekBookings.docs.length,
        'totalRevenue': totalRevenue,
        'thisMonthRevenue': thisMonthRevenue,
        'completionRate': allBookings.docs.isEmpty
            ? 0.0
            : (completedBookings.docs.length / allBookings.docs.length) * 100,
      };
    } catch (e) {
      throw Exception('Failed to get booking statistics: $e');
    }
  }

  // Get all bookings for admin dashboard
  static Stream<QuerySnapshot> getAllBookings() {
    return _firestore
        .collection('bookings')
        .orderBy('created_at', descending: true)
        .limit(50)
        .snapshots();
  }

  // Get handyman availability
  static Future<List<String>> getHandymanAvailability(String handymanId,
      DateTime date) async {
    try {
      QuerySnapshot bookings = await _firestore
          .collection('bookings')
          .where('handyman_id', isEqualTo: handymanId)
          .where('scheduled_date', isEqualTo: Timestamp.fromDate(date))
          .where('status', whereIn: ['pending', 'accepted', 'in_progress'])
          .get();

      List<String> bookedSlots = [];
      for (var doc in bookings.docs) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        bookedSlots.add(data['scheduled_time']);
      }

      List<String> allSlots = [
        '9:00', '10:00', '11:00', '12:00',
        '13:00', '14:00', '15:00', '16:00', '17:00'
      ];

      return allSlots.where((slot) => !bookedSlots.contains(slot)).toList();
    } catch (e) {
      throw Exception('Failed to get handyman availability: $e');
    }
  }

  // Get available handymen
  static Future<List<Map<String, dynamic>>> getAvailableHandymen({
    required String city,
    required String category,
    DateTime? date,
    String? timeSlot,
  }) async {
    try {
      QuerySnapshot handymenSnapshot = await _firestore
          .collection('users')
          .where('role', isEqualTo: 'handyman')
          .where('location.city', isEqualTo: city)
          .where('services', arrayContains: category)
          .get();

      List<Map<String, dynamic>> availableHandymen = [];

      for (var doc in handymenSnapshot.docs) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        String handymanId = doc.id;

        // Check if available at the requested time
        if (date != null && timeSlot != null) {
          QuerySnapshot bookings = await _firestore
              .collection('bookings')
              .where('handyman_id', isEqualTo: handymanId)
              .where('scheduled_date', isEqualTo: Timestamp.fromDate(date))
              .where('scheduled_time', isEqualTo: timeSlot)
              .where('status', whereIn: ['pending', 'accepted', 'in_progress'])
              .get();

          if (bookings.docs.isEmpty) {
            availableHandymen.add(data);
          }
        } else {
          availableHandymen.add(data);
        }
      }

      return availableHandymen;
    } catch (e) {
      throw Exception('Failed to get available handymen: $e');
    }
  }

  // Get booking details with user and handyman info
  static Future<Map<String, dynamic>> getBookingDetails(
      String bookingId) async {
    try {
      DocumentSnapshot bookingDoc = await _firestore.collection('bookings').doc(
          bookingId).get();

      if (!bookingDoc.exists) {
        throw Exception('Booking not found');
      }

      Map<String, dynamic> bookingData = bookingDoc.data() as Map<
          String,
          dynamic>;

      // Get user details
      if (bookingData['user_id'] != null) {
        DocumentSnapshot userDoc = await _firestore.collection('users').doc(
            bookingData['user_id']).get();
        if (userDoc.exists) {
          bookingData['customerDetails'] = userDoc.data();
        }
      }

      // Get handyman details
      if (bookingData['handyman_id'] != null) {
        DocumentSnapshot handymanDoc = await _firestore.collection('users').doc(
            bookingData['handyman_id']).get();
        if (handymanDoc.exists) {
          bookingData['handymanDetails'] = handymanDoc.data();
        }
      }

      return bookingData;
    } catch (e) {
      throw Exception('Failed to get booking details: $e');
    }
  }

  // Get handyman performance metrics
  static Future<Map<String, dynamic>> getHandymanPerformance(
      String handymanId) async {
    try {
      DateTime now = DateTime.now();
      DateTime startOfMonth = DateTime(now.year, now.month, 1);

      QuerySnapshot allBookings = await _firestore
          .collection('bookings')
          .where('handyman_id', isEqualTo: handymanId)
          .get();

      QuerySnapshot completedBookings = await _firestore
          .collection('bookings')
          .where('handyman_id', isEqualTo: handymanId)
          .where('status', isEqualTo: 'completed')
          .get();

      QuerySnapshot thisMonthBookings = await _firestore
          .collection('bookings')
          .where('handyman_id', isEqualTo: handymanId)
          .where('created_at',
          isGreaterThanOrEqualTo: Timestamp.fromDate(startOfMonth))
          .get();

      double totalEarnings = 0;
      double averageRating = 0;
      int totalRatings = 0;

      for (var doc in completedBookings.docs) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        totalEarnings += data['estimated_cost'] ?? 0;

        if (data['rating'] != null) {
          averageRating += data['rating'];
          totalRatings++;
        }
      }

      if (totalRatings > 0) {
        averageRating = averageRating / totalRatings;
      }

      return {
        'totalBookings': allBookings.docs.length,
        'completedBookings': completedBookings.docs.length,
        'thisMonthBookings': thisMonthBookings.docs.length,
        'totalEarnings': totalEarnings,
        'averageRating': averageRating,
        'completionRate': allBookings.docs.isEmpty
            ? 0.0
            : (completedBookings.docs.length / allBookings.docs.length) * 100,
      };
    } catch (e) {
      throw Exception('Failed to get handyman performance: $e');
    }
  }

  // Private helper method to update handyman statistics
  static Future<void> _updateHandymanStats(String handymanId,
      String action) async {
    try {
      final handymanRef = _firestore.collection('users').doc(handymanId);

      await _firestore.runTransaction((transaction) async {
        final handymanDoc = await transaction.get(handymanRef);
        final currentStats = handymanDoc.data()?['statistics'] as Map<
            String,
            dynamic>? ?? {};

        switch (action) {
          case 'booking_requested':
            currentStats['total_requests'] =
                (currentStats['total_requests'] ?? 0) + 1;
            break;
          case 'booking_accepted':
            currentStats['total_accepted'] =
                (currentStats['total_accepted'] ?? 0) + 1;
            break;
          case 'booking_completed':
            currentStats['total_completed'] =
                (currentStats['total_completed'] ?? 0) + 1;
            currentStats['last_completed'] = FieldValue.serverTimestamp();
            break;
        }

        transaction.update(handymanRef, {'statistics': currentStats});
      });
    } catch (e) {
      print('Error updating handyman stats: $e');
    }
  }

  // Private helper method to update handyman rating
  static Future<void> _updateHandymanRating(String handymanId,
      double newRating) async {
    try {
      final handymanRef = _firestore.collection('users').doc(handymanId);

      await _firestore.runTransaction((transaction) async {
        final handymanDoc = await transaction.get(handymanRef);
        final currentData = handymanDoc.data() ?? {};

        final currentRating = currentData['average_rating'] as double? ?? 0.0;
        final totalReviews = currentData['total_reviews'] as int? ?? 0;

        final newTotalReviews = totalReviews + 1;
        final newAverageRating = ((currentRating * totalReviews) + newRating) /
            newTotalReviews;

        transaction.update(handymanRef, {
          'average_rating': newAverageRating,
          'total_reviews': newTotalReviews,
        });
      });
    } catch (e) {
      print('Error updating handyman rating: $e');
    }
  }

  // Get active bookings count for handyman
  static Future<int> getActiveBookingsCount(String handymanId) async {
    final snapshot = await _firestore
        .collection('bookings')
        .where('handyman_id', isEqualTo: handymanId)
        .where('status', whereIn: ['accepted', 'in_progress'])
        .get();

    return snapshot.docs.length;
  }

  // Get booking by ID
  static Future<DocumentSnapshot> getBookingById(String bookingId) {
    return _firestore.collection('bookings').doc(bookingId).get();
  }
}
