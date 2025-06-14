import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/notification_service.dart';

class UserHandymanInteractionService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final NotificationService _notificationService = NotificationService();

  // Enhanced booking creation with verification checks
  static Future<String> createBooking({
    required String handymanId,
    required String category,
    required String serviceDescription,
    required DateTime scheduledDate,
    required String timeSlot,
    required double estimatedCost,
    required Map<String, dynamic> address,
    required Map<String, dynamic> contactInfo,
  }) async {
    try {
      User? user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('User not authenticated');

      // Check if handyman is verified
      DocumentSnapshot handymanDoc = await _firestore
          .collection('users')
          .doc(handymanId)
          .get();

      if (!handymanDoc.exists) {
        throw Exception('Handyman not found');
      }

      Map<String, dynamic> handymanData = handymanDoc.data() as Map<
          String,
          dynamic>;

      // Check if handyman is suspended
      if (handymanData['isSuspended'] == true) {
        throw Exception('This handyman is currently unavailable');
      }

      String bookingStatus = 'pending';
      if (handymanData['isVerified'] != true) {
        bookingStatus = 'pending_verification';
      }

      // Check if category is active
      QuerySnapshot categoryQuery = await _firestore
          .collection('categories')
          .where('name', isEqualTo: category)
          .where('isActive', isEqualTo: true)
          .get();

      if (categoryQuery.docs.isEmpty) {
        throw Exception('This service category is currently unavailable');
      }

      // Check time slot availability
      QuerySnapshot existingBookings = await _firestore
          .collection('bookings')
          .where('handymanId', isEqualTo: handymanId)
          .where('scheduledDate', isEqualTo: Timestamp.fromDate(scheduledDate))
          .where('timeSlot', isEqualTo: timeSlot)
          .where('status', whereIn: ['pending', 'accepted', 'in_progress'])
          .get();

      if (existingBookings.docs.isNotEmpty) {
        throw Exception('This time slot is no longer available');
      }

      // Create booking
      DocumentReference docRef = await _firestore.collection('bookings').add({
        'userId': user.uid,
        'handymanId': handymanId,
        'category': category,
        'serviceDescription': serviceDescription,
        'scheduledDate': Timestamp.fromDate(scheduledDate),
        'timeSlot': timeSlot,
        'estimatedCost': estimatedCost,
        'address': address,
        'contactInfo': contactInfo,
        'status': bookingStatus,
        'paymentStatus': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Send notifications
      if (bookingStatus == 'pending') {
        await _notificationService.sendNotificationToUser(
          handymanId,
          'New Booking Request',
          'You have received a new booking for $category service on ${_formatDate(
              scheduledDate)} at $timeSlot',
        );
      } else {
        await _notificationService.sendNotificationToUser(
          user.uid,
          'Booking Submitted',
          'Your booking is waiting for the handyman to be verified. You will be notified once approved.',
        );
      }

      return docRef.id;
    } catch (e) {
      throw Exception('Failed to create booking: $e');
    }
  }

  // Enhanced booking status update with notifications
  static Future<void> updateBookingStatus(String bookingId, String newStatus,
      {String? reason}) async {
    try {
      DocumentSnapshot bookingDoc = await _firestore
          .collection('bookings')
          .doc(bookingId)
          .get();

      if (!bookingDoc.exists) throw Exception('Booking not found');

      Map<String, dynamic> bookingData = bookingDoc.data() as Map<
          String,
          dynamic>;
      String oldStatus = bookingData['status'];

      // Update booking status
      Map<String, dynamic> updateData = {
        'status': newStatus,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (reason != null) {
        updateData['statusReason'] = reason;
      }

      if (newStatus == 'accepted') {
        updateData['acceptedAt'] = FieldValue.serverTimestamp();
      } else if (newStatus == 'in_progress') {
        updateData['startedAt'] = FieldValue.serverTimestamp();
      } else if (newStatus == 'completed') {
        updateData['completedAt'] = FieldValue.serverTimestamp();
      } else if (newStatus == 'cancelled') {
        updateData['cancelledAt'] = FieldValue.serverTimestamp();
        if (reason != null) {
          updateData['cancellationReason'] = reason;
        }
      }

      await _firestore.collection('bookings').doc(bookingId).update(updateData);

      // Send notifications based on status change
      await _sendBookingStatusNotifications(
          bookingData, oldStatus, newStatus, reason);

      // Update handyman statistics
      if (newStatus == 'completed') {
        await _updateHandymanStats(
            bookingData['handymanId'], bookingData['estimatedCost']);
      }
    } catch (e) {
      throw Exception('Failed to update booking status: $e');
    }
  }

  // Send appropriate notifications for booking status changes
  static Future<void> _sendBookingStatusNotifications(
      Map<String, dynamic> bookingData,
      String oldStatus,
      String newStatus,
      String? reason,) async {
    String userId = bookingData['userId'];
    String handymanId = bookingData['handymanId'];
    String category = bookingData['category'];

    switch (newStatus) {
      case 'accepted':
        await _notificationService.sendNotificationToUser(
          userId,
          'Booking Accepted',
          'Your $category booking has been accepted. The handyman will contact you soon.',
        );
        break;

      case 'rejected':
        await _notificationService.sendNotificationToUser(
          userId,
          'Booking Rejected',
          reason != null
              ? 'Your $category booking has been rejected. Reason: $reason'
              : 'Your $category booking has been rejected.',
        );
        break;

      case 'in_progress':
        await _notificationService.sendNotificationToUser(
          userId,
          'Work Started',
          'Your handyman has started working on your $category service.',
        );
        break;

      case 'completed':
        await _notificationService.sendNotificationToUser(
          userId,
          'Service Completed',
          'Your $category service has been completed. Please rate your experience.',
        );
        break;

      case 'cancelled':
        String notificationMessage = reason != null
            ? 'Your $category booking has been cancelled. Reason: $reason'
            : 'Your $category booking has been cancelled.';

        await _notificationService.sendNotificationToUser(
          userId,
          'Booking Cancelled',
          notificationMessage,
        );

        await _notificationService.sendNotificationToUser(
          handymanId,
          'Booking Cancelled',
          'A $category booking has been cancelled.',
        );
        break;
    }
  }

  // Update handyman statistics after job completion
  static Future<void> _updateHandymanStats(String handymanId,
      double earnings) async {
    try {
      DocumentSnapshot handymanDoc = await _firestore
          .collection('users')
          .doc(handymanId)
          .get();

      if (handymanDoc.exists) {
        Map<String, dynamic> handymanData = handymanDoc.data() as Map<
            String,
            dynamic>;

        int currentJobs = handymanData['completedJobs'] ?? 0;
        double currentEarnings = handymanData['totalEarnings'] ?? 0.0;

        await _firestore.collection('users').doc(handymanId).update({
          'completedJobs': currentJobs + 1,
          'totalEarnings': currentEarnings + earnings,
          'lastActiveAt': FieldValue.serverTimestamp(),
        });
      }
    } catch (e) {
      print('Error updating handyman stats: $e');
    }
  }

  // Get available handymen with real-time filters
  static Future<List<Map<String, dynamic>>> getAvailableHandymen({
    required String city,
    required String category,
    DateTime? date,
    String? timeSlot,
  }) async {
    try {
      // Get handymen in the specified city and category
      QuerySnapshot handymenQuery = await _firestore
          .collection('users')
          .where('userType', isEqualTo: 'service_provider')
          .where('city', isEqualTo: city)
          .where('primaryCategory', isEqualTo: category)
          .where('isVerified', isEqualTo: true)
          .where('isSuspended', isNotEqualTo: true)
          .get();

      List<Map<String, dynamic>> availableHandymen = [];

      for (var doc in handymenQuery.docs) {
        Map<String, dynamic> handymanData = doc.data() as Map<String, dynamic>;
        handymanData['id'] = doc.id;

        // Check availability for specific date and time if provided
        if (date != null && timeSlot != null) {
          QuerySnapshot conflictingBookings = await _firestore
              .collection('bookings')
              .where('handymanId', isEqualTo: doc.id)
              .where('scheduledDate', isEqualTo: Timestamp.fromDate(date))
              .where('timeSlot', isEqualTo: timeSlot)
              .where('status', whereIn: ['pending', 'accepted', 'in_progress'])
              .get();

          if (conflictingBookings.docs.isEmpty) {
            handymanData['isAvailable'] = true;
            availableHandymen.add(handymanData);
          }
        } else {
          // General availability check
          handymanData['isAvailable'] = handymanData['isAvailable'] ?? true;
          availableHandymen.add(handymanData);
        }
      }

      // Sort by rating and then by completed jobs
      availableHandymen.sort((a, b) {
        double ratingA = a['rating'] ?? 0.0;
        double ratingB = b['rating'] ?? 0.0;

        if (ratingA != ratingB) {
          return ratingB.compareTo(ratingA); // Higher rating first
        }

        int jobsA = a['completedJobs'] ?? 0;
        int jobsB = b['completedJobs'] ?? 0;
        return jobsB.compareTo(jobsA); // More experience first
      });

      return availableHandymen;
    } catch (e) {
      throw Exception('Failed to get available handymen: $e');
    }
  }

  // Add review and update handyman rating
  static Future<void> addReview({
    required String bookingId,
    required String handymanId,
    required double rating,
    required String comment,
  }) async {
    try {
      User? user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('User not authenticated');

      // Get user and booking data
      DocumentSnapshot userDoc = await _firestore.collection('users').doc(
          user.uid).get();
      DocumentSnapshot bookingDoc = await _firestore.collection('bookings').doc(
          bookingId).get();

      if (!userDoc.exists || !bookingDoc.exists) {
        throw Exception('User or booking not found');
      }

      Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;
      Map<String, dynamic> bookingData = bookingDoc.data() as Map<
          String,
          dynamic>;

      // Add review
      await _firestore.collection('reviews').add({
        'handymanId': handymanId,
        'userId': user.uid,
        'userName': userData['fullName'],
        'rating': rating,
        'comment': comment,
        'serviceType': bookingData['category'],
        'bookingId': bookingId,
        'date': DateTime.now().toIso8601String().split('T')[0],
        'createdAt': FieldValue.serverTimestamp(),
      });

      // Update booking with review
      await _firestore.collection('bookings').doc(bookingId).update({
        'rating': rating,
        'review': comment,
        'reviewedAt': FieldValue.serverTimestamp(),
      });

      // Update handyman's average rating
      await _updateHandymanRating(handymanId);

      // Notify handyman about new review
      String reviewText = rating >= 4.0 ? 'Great news! You received a ${rating
          .toInt()}-star review.'
          : 'You received a ${rating.toInt()}-star review.';
      await _notificationService.sendNotificationToUser(
        handymanId,
        'New Review',
        reviewText,
      );
    } catch (e) {
      throw Exception('Failed to add review: $e');
    }
  }

  // Update handyman's average rating
  static Future<void> _updateHandymanRating(String handymanId) async {
    try {
      QuerySnapshot reviews = await _firestore
          .collection('reviews')
          .where('handymanId', isEqualTo: handymanId)
          .get();

      if (reviews.docs.isNotEmpty) {
        double totalRating = 0;
        for (var doc in reviews.docs) {
          totalRating += (doc.data() as Map<String, dynamic>)['rating'];
        }
        double averageRating = totalRating / reviews.docs.length;

        await _firestore.collection('users').doc(handymanId).update({
          'rating': double.parse(averageRating.toStringAsFixed(1)),
          'reviewCount': reviews.docs.length,
        });
      }
    } catch (e) {
      print('Error updating handyman rating: $e');
    }
  }

  // Get handyman's schedule with bookings
  static Future<Map<DateTime, List<Map<String, dynamic>>>> getHandymanSchedule(
      String handymanId) async {
    try {
      DateTime now = DateTime.now();
      DateTime startDate = DateTime(now.year, now.month, 1);
      DateTime endDate = DateTime(now.year, now.month + 2, 0);

      QuerySnapshot bookings = await _firestore
          .collection('bookings')
          .where('handymanId', isEqualTo: handymanId)
          .where('scheduledDate',
          isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
          .where(
          'scheduledDate', isLessThanOrEqualTo: Timestamp.fromDate(endDate))
          .where('status', whereIn: ['accepted', 'in_progress', 'completed'])
          .get();

      Map<DateTime, List<Map<String, dynamic>>> schedule = {};

      for (var doc in bookings.docs) {
        Map<String, dynamic> bookingData = doc.data() as Map<String, dynamic>;
        DateTime date = (bookingData['scheduledDate'] as Timestamp).toDate();
        DateTime normalizedDate = DateTime(date.year, date.month, date.day);

        if (schedule[normalizedDate] == null) {
          schedule[normalizedDate] = [];
        }

        schedule[normalizedDate]!.add({
          'id': doc.id,
          ...bookingData,
        });
      }

      return schedule;
    } catch (e) {
      throw Exception('Failed to get handyman schedule: $e');
    }
  }

  // Helper method to format date
  static String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}