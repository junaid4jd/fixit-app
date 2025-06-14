import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/notification_service.dart';

class AdminUserManagementService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final NotificationService _notificationService = NotificationService();

  // Suspend user and notify them
  static Future<void> suspendUser(String userId, String reason) async {
    await _firestore.collection('users').doc(userId).update({
      'isSuspended': true,
      'suspensionReason': reason,
      'suspendedAt': FieldValue.serverTimestamp(),
      'suspendedBy': FirebaseAuth.instance.currentUser?.uid,
    });

    // Notify user about suspension
    await _notificationService.sendNotificationToUser(
      userId,
      'Account Suspended',
      'Your account has been suspended. Reason: $reason',
    );
  }

  // Activate user and notify them
  static Future<void> activateUser(String userId) async {
    await _firestore.collection('users').doc(userId).update({
      'isSuspended': false,
      'suspensionReason': FieldValue.delete(),
      'activatedAt': FieldValue.serverTimestamp(),
      'activatedBy': FirebaseAuth.instance.currentUser?.uid,
    });

    // Notify user about activation
    await _notificationService.sendNotificationToUser(
      userId,
      'Account Activated',
      'Your account has been activated. You can now use the app normally.',
    );
  }

  // Verify handyman and notify them
  static Future<void> verifyHandyman(String handymanId) async {
    await _firestore.collection('users').doc(handymanId).update({
      'isVerified': true,
      'verifiedAt': FieldValue.serverTimestamp(),
      'verifiedBy': FirebaseAuth.instance.currentUser?.uid,
    });

    // Notify handyman about verification
    await _notificationService.sendNotificationToUser(
      handymanId,
      'Account Verified!',
      'Congratulations! Your account has been verified. You can now receive booking requests.',
    );

    // Update all pending bookings for this handyman
    QuerySnapshot pendingBookings = await _firestore
        .collection('bookings')
        .where('handymanId', isEqualTo: handymanId)
        .where('status', isEqualTo: 'pending_verification')
        .get();

    for (var doc in pendingBookings.docs) {
      await doc.reference.update({'status': 'pending'});

      // Notify customer that handyman is now verified
      Map<String, dynamic> bookingData = doc.data() as Map<String, dynamic>;
      await _notificationService.sendNotificationToUser(
        bookingData['userId'],
        'Handyman Verified',
        'Your selected handyman has been verified and can now process your booking.',
      );
    }
  }

  // Reject handyman verification
  static Future<void> rejectHandyman(String handymanId, String reason) async {
    await _firestore.collection('users').doc(handymanId).update({
      'isVerified': false,
      'verificationRejected': true,
      'rejectionReason': reason,
      'rejectedAt': FieldValue.serverTimestamp(),
      'rejectedBy': FirebaseAuth.instance.currentUser?.uid,
    });

    // Notify handyman about rejection
    await _notificationService.sendNotificationToUser(
      handymanId,
      'Verification Rejected',
      'Your verification has been rejected. Reason: $reason. Please resubmit with correct information.',
    );

    // Cancel all pending bookings for this handyman
    QuerySnapshot pendingBookings = await _firestore
        .collection('bookings')
        .where('handymanId', isEqualTo: handymanId)
        .where('status', whereIn: ['pending', 'pending_verification'])
        .get();

    for (var doc in pendingBookings.docs) {
      await doc.reference.update({
        'status': 'cancelled',
        'cancellationReason': 'Handyman verification rejected',
      });

      Map<String, dynamic> bookingData = doc.data() as Map<String, dynamic>;
      await _notificationService.sendNotificationToUser(
        bookingData['userId'],
        'Booking Cancelled',
        'Your booking has been cancelled because the handyman\'s verification was rejected.',
      );
    }
  }

  // Update category status and notify affected users
  static Future<void> updateCategoryStatus(String categoryId,
      bool isActive) async {
    await _firestore.collection('categories').doc(categoryId).update({
      'isActive': isActive,
      'updatedAt': FieldValue.serverTimestamp(),
    });

    if (!isActive) {
      // Cancel all pending bookings in this category
      DocumentSnapshot categoryDoc = await _firestore
          .collection('categories')
          .doc(categoryId)
          .get();
      String categoryName = (categoryDoc.data() as Map<String,
          dynamic>)['name'];

      QuerySnapshot pendingBookings = await _firestore
          .collection('bookings')
          .where('category', isEqualTo: categoryName)
          .where('status', isEqualTo: 'pending')
          .get();

      for (var doc in pendingBookings.docs) {
        await doc.reference.update({
          'status': 'cancelled',
          'cancellationReason': 'Service category has been deactivated',
        });

        Map<String, dynamic> bookingData = doc.data() as Map<String, dynamic>;
        await _notificationService.sendNotificationToUser(
          bookingData['userId'],
          'Booking Cancelled',
          'Your booking for $categoryName has been cancelled as this service is temporarily unavailable.',
        );

        await _notificationService.sendNotificationToUser(
          bookingData['handymanId'],
          'Booking Cancelled',
          'A booking for $categoryName has been cancelled as this service category is temporarily unavailable.',
        );
      }
    }
  }

  // Get comprehensive user statistics
  static Future<Map<String, dynamic>> getUserStatistics() async {
    DateTime now = DateTime.now();
    DateTime startOfMonth = DateTime(now.year, now.month, 1);
    DateTime startOfWeek = now.subtract(Duration(days: 7));

    // User statistics
    QuerySnapshot allUsers = await _firestore.collection('users').get();
    QuerySnapshot customers = await _firestore
        .collection('users')
        .where('userType', isEqualTo: 'user')
        .get();
    QuerySnapshot handymen = await _firestore
        .collection('users')
        .where('userType', isEqualTo: 'service_provider')
        .get();
    QuerySnapshot verifiedHandymen = await _firestore
        .collection('users')
        .where('userType', isEqualTo: 'service_provider')
        .where('isVerified', isEqualTo: true)
        .get();

    // New users this month
    QuerySnapshot newUsersThisMonth = await _firestore
        .collection('users')
        .where(
        'createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfMonth))
        .get();

    // Active users this week (users who have bookings)
    QuerySnapshot activeUsersThisWeek = await _firestore
        .collection('bookings')
        .where(
        'createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfWeek))
        .get();

    Set<String> activeUserIds = {};
    for (var doc in activeUsersThisWeek.docs) {
      Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
      activeUserIds.add(data['userId']);
      activeUserIds.add(data['handymanId']);
    }

    return {
      'totalUsers': allUsers.docs.length,
      'totalCustomers': customers.docs.length,
      'totalHandymen': handymen.docs.length,
      'verifiedHandymen': verifiedHandymen.docs.length,
      'newUsersThisMonth': newUsersThisMonth.docs.length,
      'activeUsersThisWeek': activeUserIds.length,
    };
  }

  // Send broadcast notification to all users
  static Future<void> sendBroadcastNotification(String title, String message,
      {String? userType}) async {
    Query query = _firestore.collection('users');

    if (userType != null) {
      query = query.where('userType', isEqualTo: userType);
    }

    QuerySnapshot users = await query.get();

    for (var doc in users.docs) {
      await _notificationService.sendNotificationToUser(doc.id, title, message);
    }

    // Save broadcast record
    await _firestore.collection('broadcast_notifications').add({
      'title': title,
      'message': message,
      'userType': userType,
      'sentAt': FieldValue.serverTimestamp(),
      'sentBy': FirebaseAuth.instance.currentUser?.uid,
      'recipientCount': users.docs.length,
    });
  }
}
