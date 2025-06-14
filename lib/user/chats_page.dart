import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/chat_service.dart';
import 'chat_screen.dart';

class ChatsPage extends StatefulWidget {
  const ChatsPage({super.key});

  @override
  State<ChatsPage> createState() => _ChatsPageState();
}

class _ChatsPageState extends State<ChatsPage> {
  final ChatService _chatService = ChatService();
  List<Map<String, dynamic>> _conversations = [];
  bool _isLoading = true;
  String? _currentUserId;

  @override
  void initState() {
    super.initState();
    _getCurrentUser();
  }

  void _getCurrentUser() {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      _currentUserId = user.uid;
      _loadConversations();
    } else {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadConversations() async {
    if (_currentUserId == null) return;

    setState(() => _isLoading = true);

    try {
      // Get all bookings for this user
      final bookingsSnapshot = await FirebaseFirestore.instance
          .collection('bookings')
          .where('userId', isEqualTo: _currentUserId)
          .orderBy('createdAt', descending: true)
          .get();

      List<Map<String, dynamic>> conversations = [];

      for (var bookingDoc in bookingsSnapshot.docs) {
        final bookingData = bookingDoc.data();
        final bookingId = bookingDoc.id;
        final handymanId = bookingData['handymanId'];

        if (handymanId == null) continue;

        // Get handyman details
        final handymanDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(handymanId)
            .get();

        if (!handymanDoc.exists) continue;

        final handymanData = handymanDoc.data()!;

        // Get last message for this booking/chat
        final lastMessage = await _chatService.getLastMessage(bookingId);

        // Check if there's any message in this chat
        if (lastMessage != null) {
          conversations.add({
            'bookingId': bookingId,
            'handyman': handymanData,
            'handymanId': handymanId,
            'lastMessage': lastMessage,
            'booking': bookingData,
          });
        }
      }

      // Remove duplicates based on handymanId (keep the most recent conversation)
      final Map<String, Map<String, dynamic>> uniqueConversations = {};
      for (var conversation in conversations) {
        final handymanId = conversation['handymanId'];
        if (!uniqueConversations.containsKey(handymanId) ||
            (conversation['lastMessage']['timestamp'] as Timestamp)
                .compareTo(
                uniqueConversations[handymanId]!['lastMessage']['timestamp'] as Timestamp) >
                0) {
          uniqueConversations[handymanId] = conversation;
        }
      }

      setState(() {
        _conversations = uniqueConversations.values.toList();
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading conversations: $e');
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'Chats',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF2C3E50),
        elevation: 0,
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(
        child: CircularProgressIndicator(
          color: Color(0xFF4169E1),
        ),
      )
          : _conversations.isEmpty
          ? _buildEmptyState()
          : RefreshIndicator(
        onRefresh: _loadConversations,
        color: const Color(0xFF4169E1),
        child: ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: _conversations.length,
          separatorBuilder: (context, index) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final conversation = _conversations[index];
            return _buildConversationCard(conversation);
          },
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.chat_bubble_outline,
            size: 100,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 24),
          Text(
            'No Chats Yet',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Start a conversation with a handyman\nby booking a service',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[500],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context); // Go back to home to book a service
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF4169E1),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              'Book a Service',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConversationCard(Map<String, dynamic> conversation) {
    final handyman = conversation['handyman'] as Map<String, dynamic>;
    final lastMessage = conversation['lastMessage'] as Map<String, dynamic>;
    final booking = conversation['booking'] as Map<String, dynamic>;

    final timestamp = (lastMessage['timestamp'] as Timestamp).toDate();
    final timeString = _formatTime(timestamp);
    final isUnread = lastMessage['sender_id'] != _currentUserId &&
        (lastMessage['is_read'] != true);

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        onTap: () => _openChat(conversation),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Profile Avatar
              Stack(
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: const Color(0xFF4169E1),
                    backgroundImage: handyman['profileImage'] != null
                        ? NetworkImage(handyman['profileImage'])
                        : null,
                    child: handyman['profileImage'] == null
                        ? Text(
                      (handyman['fullName'] ?? 'H')[0].toUpperCase(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    )
                        : null,
                  ),
                  // Online indicator (you can implement online status later)
                  Positioned(
                    bottom: 2,
                    right: 2,
                    child: Container(
                      width: 14,
                      height: 14,
                      decoration: BoxDecoration(
                        color: Colors.green,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 16),

              // Chat Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            handyman['fullName'] ?? 'Handyman',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF2C3E50),
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (handyman['isVerified'] == true)
                          Container(
                            margin: const EdgeInsets.only(left: 8),
                            child: const Icon(
                              Icons.verified,
                              color: Colors.green,
                              size: 16,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),

                    // Service type
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFF4169E1).withAlpha(20),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        booking['serviceName'] ?? 'Service',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF4169E1),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Last message
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            _getLastMessageText(lastMessage),
                            style: TextStyle(
                              fontSize: 14,
                              color: isUnread ? const Color(0xFF2C3E50) : Colors
                                  .grey[600],
                              fontWeight: isUnread
                                  ? FontWeight.w500
                                  : FontWeight.normal,
                            ),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          timeString,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[500],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Unread indicator
              if (isUnread)
                Container(
                  margin: const EdgeInsets.only(left: 8),
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: Color(0xFF4169E1),
                    shape: BoxShape.circle,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  String _getLastMessageText(Map<String, dynamic> lastMessage) {
    if (lastMessage['sender_id'] == 'system') {
      return lastMessage['text'] ?? 'System message';
    }

    final isMe = lastMessage['sender_id'] == _currentUserId;
    final prefix = isMe ? 'You: ' : '';

    if (lastMessage['image_url'] != null) {
      return '${prefix}📷 Photo';
    }

    return '$prefix${lastMessage['text'] ?? 'Message'}';
  }

  String _formatTime(DateTime timestamp) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final messageDate = DateTime(
        timestamp.year, timestamp.month, timestamp.day);

    if (messageDate == today) {
      // Today - show time
      return '${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute
          .toString().padLeft(2, '0')}';
    } else if (messageDate == today.subtract(const Duration(days: 1))) {
      // Yesterday
      return 'Yesterday';
    } else if (now
        .difference(timestamp)
        .inDays < 7) {
      // This week - show day name
      const days = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
      return days[timestamp.weekday % 7];
    } else {
      // Older - show date
      return '${timestamp.day}/${timestamp.month}';
    }
  }

  void _openChat(Map<String, dynamic> conversation) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            ChatScreen(
              bookingId: conversation['bookingId'],
              handyman: conversation['handyman'],
              currentUserId: _currentUserId!,
            ),
      ),
    ).then((_) {
      // Refresh conversations when returning from chat
      _loadConversations();
    });
  }
}