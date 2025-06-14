import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ChatService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Get messages for a booking
  Future<List<Map<String, dynamic>>> getMessages(String bookingId) async {
    try {
      final querySnapshot = await _firestore
          .collection('chats')
          .doc(bookingId)
          .collection('messages')
          .orderBy('timestamp')
          .get();

      return querySnapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();
    } catch (e) {
      throw Exception('Failed to get messages: $e');
    }
  }

  // Get messages stream for real-time updates
  Stream<List<Map<String, dynamic>>> getMessagesStream(String bookingId) {
    return _firestore
        .collection('chats')
        .doc(bookingId)
        .collection('messages')
        .orderBy('timestamp')
        .snapshots()
        .map((snapshot) =>
        snapshot.docs.map((doc) {
          final data = doc.data();
          data['id'] = doc.id;
          return data;
        }).toList());
  }

  // Send a message
  Future<void> sendMessage({
    required String bookingId,
    required String senderId,
    required String text,
    required String senderName,
    String? imageUrl,
  }) async {
    try {
      await _firestore
          .collection('chats')
          .doc(bookingId)
          .collection('messages')
          .add({
        'sender_id': senderId,
        'sender_name': senderName,
        'text': text,
        'image_url': imageUrl,
        'timestamp': FieldValue.serverTimestamp(),
        'is_read': false,
        'type': 'message',
      });

      // Update chat metadata
      await _firestore.collection('chats').doc(bookingId).update({
        'last_message': text,
        'last_message_time': FieldValue.serverTimestamp(),
        'last_sender_id': senderId,
      });
    } catch (e) {
      throw Exception('Failed to send message: $e');
    }
  }

  // Mark messages as read
  Future<void> markMessagesAsRead(String bookingId, String userId) async {
    try {
      final querySnapshot = await _firestore
          .collection('chats')
          .doc(bookingId)
          .collection('messages')
          .where('sender_id', isNotEqualTo: userId)
          .where('is_read', isEqualTo: false)
          .get();

      final batch = _firestore.batch();
      for (var doc in querySnapshot.docs) {
        batch.update(doc.reference, {'is_read': true});
      }
      await batch.commit();
    } catch (e) {
      throw Exception('Failed to mark messages as read: $e');
    }
  }

  // Get unread message count
  Future<int> getUnreadMessageCount(String bookingId, String userId) async {
    try {
      final querySnapshot = await _firestore
          .collection('chats')
          .doc(bookingId)
          .collection('messages')
          .where('sender_id', isNotEqualTo: userId)
          .where('is_read', isEqualTo: false)
          .get();

      return querySnapshot.docs.length;
    } catch (e) {
      return 0;
    }
  }

  // Get chat info
  Future<Map<String, dynamic>?> getChatInfo(String bookingId) async {
    try {
      final chatDoc = await _firestore.collection('chats').doc(bookingId).get();
      if (chatDoc.exists) {
        return chatDoc.data() as Map<String, dynamic>;
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  // Get last message for a booking
  Future<Map<String, dynamic>?> getLastMessage(String bookingId) async {
    try {
      final querySnapshot = await _firestore
          .collection('chats')
          .doc(bookingId)
          .collection('messages')
          .orderBy('timestamp', descending: true)
          .limit(1)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        final data = querySnapshot.docs.first.data();
        data['id'] = querySnapshot.docs.first.id;
        return data;
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  // Send booking update message
  Future<void> sendBookingUpdateMessage({
    required String bookingId,
    required String message,
    required String updateType,
  }) async {
    try {
      await _firestore
          .collection('chats')
          .doc(bookingId)
          .collection('messages')
          .add({
        'sender_id': 'system',
        'sender_name': 'System',
        'text': message,
        'timestamp': FieldValue.serverTimestamp(),
        'is_read': false,
        'type': 'booking_update',
        'update_type': updateType,
      });

      // Update chat metadata
      await _firestore.collection('chats').doc(bookingId).update({
        'last_message': message,
        'last_message_time': FieldValue.serverTimestamp(),
        'last_sender_id': 'system',
      });
    } catch (e) {
      throw Exception('Failed to send booking update message: $e');
    }
  }

  // Update user's online status
  Future<void> updateUserOnlineStatus(String userId, bool isOnline) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'is_online': isOnline,
        'last_seen': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      // Don't throw error for online status - it's not critical
      print('Failed to update online status: $e');
    }
  }

  // Get user's online status
  Stream<bool> getUserOnlineStatus(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .snapshots()
        .map((doc) {
      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        final isOnline = data['is_online'] ?? false;
        final lastSeen = data['last_seen'] as Timestamp?;

        // Consider user offline if last seen was more than 5 minutes ago
        if (lastSeen != null && isOnline) {
          final now = DateTime.now();
          final lastSeenTime = lastSeen.toDate();
          final difference = now
              .difference(lastSeenTime)
              .inMinutes;
          return difference <= 5;
        }

        return isOnline;
      }
      return false;
    });
  }

  // Get user's last seen time
  Future<DateTime?> getUserLastSeen(String userId) async {
    try {
      final doc = await _firestore.collection('users').doc(userId).get();
      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        final lastSeen = data['last_seen'] as Timestamp?;
        return lastSeen?.toDate();
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  // Send image message
  Future<void> sendImageMessage({
    required String bookingId,
    required String senderId,
    required String senderName,
    required String imageUrl,
    String? caption,
  }) async {
    try {
      await _firestore
          .collection('chats')
          .doc(bookingId)
          .collection('messages')
          .add({
        'sender_id': senderId,
        'sender_name': senderName,
        'text': caption ?? '',
        'image_url': imageUrl,
        'timestamp': FieldValue.serverTimestamp(),
        'is_read': false,
        'type': 'image',
      });

      // Update chat metadata
      await _firestore.collection('chats').doc(bookingId).update({
        'last_message': caption?.isNotEmpty == true ? caption : '📷 Image',
        'last_message_time': FieldValue.serverTimestamp(),
        'last_sender_id': senderId,
      });
    } catch (e) {
      throw Exception('Failed to send image message: $e');
    }
  }

  // Delete message
  Future<void> deleteMessage(String bookingId, String messageId) async {
    try {
      await _firestore
          .collection('chats')
          .doc(bookingId)
          .collection('messages')
          .doc(messageId)
          .delete();
    } catch (e) {
      throw Exception('Failed to delete message: $e');
    }
  }

  // Clear chat
  Future<void> clearChat(String bookingId) async {
    try {
      final messages = await _firestore
          .collection('chats')
          .doc(bookingId)
          .collection('messages')
          .get();

      final batch = _firestore.batch();
      for (var doc in messages.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();

      // Update chat metadata
      await _firestore.collection('chats').doc(bookingId).update({
        'last_message': 'Chat cleared',
        'last_message_time': FieldValue.serverTimestamp(),
        'last_sender_id': 'system',
      });
    } catch (e) {
      throw Exception('Failed to clear chat: $e');
    }
  }

  // Get typing indicator
  Stream<Map<String, bool>> getTypingIndicator(String bookingId) {
    return _firestore
        .collection('chats')
        .doc(bookingId)
        .snapshots()
        .map((doc) {
      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        return Map<String, bool>.from(data['typing'] ?? {});
      }
      return <String, bool>{};
    });
  }

  // Set typing indicator
  Future<void> setTyping(String bookingId, String userId, bool isTyping) async {
    try {
      await _firestore.collection('chats').doc(bookingId).update({
        'typing.$userId': isTyping,
      });
    } catch (e) {
      // Don't throw error for typing indicator - it's not critical
      print('Failed to update typing indicator: $e');
    }
  }
}
