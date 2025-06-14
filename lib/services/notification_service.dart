import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();

  factory NotificationService() => _instance;

  NotificationService._internal();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();

  Future<void> initialize() async {
    await _requestPermission();
    await _setupLocalNotifications();
    await _setupBackgroundMessageHandling();
    await _saveDeviceToken();
  }

  Future<void> _requestPermission() async {
    await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      announcement: false,
    );
  }

  Future<void> _setupLocalNotifications() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
    AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings initializationSettings =
    InitializationSettings(android: initializationSettingsAndroid);

    await _localNotifications.initialize(initializationSettings);
  }

  Future<void> _setupBackgroundMessageHandling() async {
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      _showLocalNotification(message);
    });
  }

  Future<void> _saveDeviceToken() async {
    String? token = await _messaging.getToken();
    if (token != null) {
      User? user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .update({'deviceToken': token});
      }
    }
  }

  Future<void> _showLocalNotification(RemoteMessage message) async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
    AndroidNotificationDetails(
      'fixit_channel',
      'FixIt Notifications',
      importance: Importance.max,
      priority: Priority.high,
    );

    const NotificationDetails platformChannelSpecifics =
    NotificationDetails(android: androidPlatformChannelSpecifics);

    await _localNotifications.show(
      0,
      message.notification?.title,
      message.notification?.body,
      platformChannelSpecifics,
    );
  }

  // Send notification to user
  Future<void> sendNotificationToUser(String userId, String title,
      String body) async {
    try {
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();

      if (userDoc.exists) {
        Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;
        String? deviceToken = userData['deviceToken'];

        if (deviceToken != null) {
          // Send push notification
          await _sendPushNotification(deviceToken, title, body);
        }

        // Save notification to Firestore
        await _saveNotificationToFirestore(userId, title, body);
      }
    } catch (e) {
      print('Error sending notification: $e');
    }
  }

  Future<void> _sendPushNotification(String token, String title,
      String body) async {
    // This would typically use Firebase Cloud Functions or a server
    // For now, we'll just save to Firestore
  }

  Future<void> _saveNotificationToFirestore(String userId, String title,
      String body) async {
    await FirebaseFirestore.instance.collection('notifications').add({
      'userId': userId,
      'title': title,
      'body': body,
      'read': false,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  // Get notifications for current user
  Stream<QuerySnapshot> getNotifications() {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      return FirebaseFirestore.instance
          .collection('notifications')
          .where('userId', isEqualTo: user.uid)
          .orderBy('createdAt', descending: true)
          .snapshots();
    }
    return const Stream.empty();
  }

  // Mark notification as read
  Future<void> markAsRead(String notificationId) async {
    await FirebaseFirestore.instance
        .collection('notifications')
        .doc(notificationId)
        .update({'read': true});
  }

  // Send booking status update notifications
  Future<void> sendBookingNotification(String bookingId, String status) async {
    DocumentSnapshot bookingDoc = await FirebaseFirestore.instance
        .collection('bookings')
        .doc(bookingId)
        .get();

    if (bookingDoc.exists) {
      Map<String, dynamic> bookingData = bookingDoc.data() as Map<
          String,
          dynamic>;
      String userId = bookingData['userId'];
      String handymanId = bookingData['handymanId'];

      String title = 'Booking Update';
      String body = 'Your booking status has been updated to: $status';

      // Notify user
      await sendNotificationToUser(userId, title, body);

      // Notify handyman
      await sendNotificationToUser(
          handymanId, 'Booking Update', 'Booking status updated to: $status');
    }
  }
}

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  print('Background message: ${message.messageId}');
}