import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../services/chat_service.dart';

class ChatScreen extends StatefulWidget {
  final String bookingId;
  final Map<String, dynamic> handyman;
  final String currentUserId;

  const ChatScreen({
    super.key,
    required this.bookingId,
    required this.handyman,
    required this.currentUserId,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> with WidgetsBindingObserver {
  final ChatService _chatService = ChatService();
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  List<Map<String, dynamic>> _messages = [];
  bool _isLoading = true;
  bool _isSending = false;
  bool _isOnline = false;
  bool _isTyping = false;
  Map<String, bool> _typingIndicators = {};
  String? _otherUserId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeChat();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _chatService.updateUserOnlineStatus(widget.currentUserId, false);
    _chatService.setTyping(widget.bookingId, widget.currentUserId, false);
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    switch (state) {
      case AppLifecycleState.resumed:
        _chatService.updateUserOnlineStatus(widget.currentUserId, true);
        break;
      case AppLifecycleState.paused:
      case AppLifecycleState.inactive:
      case AppLifecycleState.detached:
        _chatService.updateUserOnlineStatus(widget.currentUserId, false);
        break;
      case AppLifecycleState.hidden:
        break;
    }
  }

  void _initializeChat() {
    // Set user online
    _chatService.updateUserOnlineStatus(widget.currentUserId, true);

    // Determine other user ID (handyman for regular users, user for service providers)
    _otherUserId = widget.handyman['uid'] ?? widget.handyman['id'];

    _loadMessages();
    _listenToMessages();
    _listenToOnlineStatus();
    _listenToTypingIndicator();
  }

  void _loadMessages() async {
    setState(() => _isLoading = true);

    try {
      final messages = await _chatService.getMessages(widget.bookingId);
      setState(() {
        _messages = messages;
        _isLoading = false;
      });
      _scrollToBottom();
    } catch (e) {
      debugPrint('Error loading messages: $e');
      setState(() => _isLoading = false);
    }
  }

  void _listenToMessages() {
    _chatService.getMessagesStream(widget.bookingId).listen((messages) {
      setState(() {
        _messages = messages;
      });
      _scrollToBottom();
      // Mark messages as read
      _chatService.markMessagesAsRead(widget.bookingId, widget.currentUserId);
    });
  }

  void _listenToOnlineStatus() {
    if (_otherUserId != null) {
      _chatService.getUserOnlineStatus(_otherUserId!).listen((isOnline) {
        if (mounted) {
          setState(() {
            _isOnline = isOnline;
          });
        }
      });
    }
  }

  void _listenToTypingIndicator() {
    _chatService.getTypingIndicator(widget.bookingId).listen((typing) {
      if (mounted) {
        setState(() {
          _typingIndicators = typing;
        });
      }
    });
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: const Color(0xFF4169E1),
        foregroundColor: Colors.white,
        elevation: 0,
        title: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: Colors.white.withValues(alpha: 0.2),
              child: Text(
                (widget.handyman['fullName'] ?? 'H')[0].toUpperCase(),
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    widget.handyman['fullName'] ?? 'Handyman',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: _isOnline ? Colors.green : Colors.grey,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        _isOnline ? 'Online' : 'Offline',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.white.withValues(alpha: 0.8),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            onPressed: () => _callHandyman(),
            icon: const Icon(Icons.call),
          ),
          IconButton(
            onPressed: () => _showMoreOptions(),
            icon: const Icon(Icons.more_vert),
          ),
        ],
      ),
      body: Column(
        children: [
          // Chat messages
          Expanded(
            child: _isLoading
                ? const Center(
              child: CircularProgressIndicator(
                color: Color(0xFF4169E1),
              ),
            )
                : _messages.isEmpty
                ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.chat_bubble_outline,
                    size: 80,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Start a conversation',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Send a message to ${widget.handyman['fullName']}',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[500],
                    ),
                  ),
                ],
              ),
            )
                : Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(16),
                    itemCount: _messages.length,
                    itemBuilder: (context, index) {
                      final message = _messages[index];
                      return _buildMessageBubble(message);
                    },
                  ),
                ),
                // Typing indicator
                if (_typingIndicators.values.any((typing) => typing)) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 8),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 12,
                          backgroundColor: const Color(0xFF4169E1).withValues(
                              alpha: 0.1),
                          child: Text(
                            (widget.handyman['fullName'] ?? 'H')[0]
                                .toUpperCase(),
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF4169E1),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              _buildTypingDot(0),
                              const SizedBox(width: 3),
                              _buildTypingDot(200),
                              const SizedBox(width: 3),
                              _buildTypingDot(400),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),

          // Message input
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: SafeArea(
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => _attachFile(),
                    icon: const Icon(
                      Icons.attach_file,
                      color: Color(0xFF7F8C8D),
                    ),
                  ),
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: TextField(
                        controller: _messageController,
                        decoration: const InputDecoration(
                          hintText: 'Type a message...',
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                        ),
                        maxLines: null,
                        textCapitalization: TextCapitalization.sentences,
                        onChanged: _onMessageChanged,
                        onSubmitted: (_) => _sendMessage(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    decoration: const BoxDecoration(
                      color: Color(0xFF4169E1),
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      onPressed: _isSending ? null : _sendMessage,
                      icon: _isSending
                          ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                          : const Icon(
                        Icons.send,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(Map<String, dynamic> message) {
    final isMe = message['sender_id'] == widget.currentUserId;
    final isSystem = message['sender_id'] == 'system';
    final timestamp = (message['timestamp'] as dynamic)?.toDate() ??
        DateTime.now();
    final timeString = '${timestamp.hour.toString().padLeft(2, '0')}:${timestamp
        .minute.toString().padLeft(2, '0')}';

    // System messages (booking updates)
    if (isSystem) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: Center(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.blue.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.blue.withValues(alpha: 0.3)),
            ),
            child: Column(
              children: [
                Icon(
                  message['type'] == 'booking_update'
                      ? Icons.info_outline
                      : Icons.chat,
                  color: Colors.blue,
                  size: 16,
                ),
                const SizedBox(height: 4),
                Text(
                  message['text'] ?? '',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.blue,
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment
            .start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isMe) ...[
            CircleAvatar(
              radius: 16,
              backgroundColor: const Color(0xFF4169E1).withValues(alpha: 0.1),
              child: Text(
                (widget.handyman['fullName'] ?? 'H')[0].toUpperCase(),
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF4169E1),
                ),
              ),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Column(
              crossAxisAlignment: isMe
                  ? CrossAxisAlignment.end
                  : CrossAxisAlignment.start,
              children: [
                GestureDetector(
                  onLongPress: () => _showMessageOptions(message),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: isMe ? const Color(0xFF4169E1) : Colors.white,
                      borderRadius: BorderRadius.circular(20).copyWith(
                        bottomLeft: isMe
                            ? const Radius.circular(20)
                            : const Radius.circular(4),
                        bottomRight: isMe
                            ? const Radius.circular(4)
                            : const Radius.circular(20),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 5,
                          offset: const Offset(0, 1),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (message['text']?.isNotEmpty == true)
                          Text(
                            message['text'] ?? '',
                            style: TextStyle(
                              fontSize: 16,
                              color: isMe ? Colors.white : const Color(
                                  0xFF2C3E50),
                            ),
                          ),
                        if (message['image_url'] != null) ...[
                          if (message['text']?.isNotEmpty == true)
                            const SizedBox(height: 8),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.network(
                              message['image_url'],
                              width: 200,
                              fit: BoxFit.cover,
                              loadingBuilder: (context, child,
                                  loadingProgress) {
                                if (loadingProgress == null) return child;
                                return Container(
                                  width: 200,
                                  height: 150,
                                  color: Colors.grey[200],
                                  child: const Center(
                                    child: CircularProgressIndicator(
                                      color: Color(0xFF4169E1),
                                    ),
                                  ),
                                );
                              },
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  width: 200,
                                  height: 150,
                                  color: Colors.grey[200],
                                  child: const Center(
                                    child: Icon(
                                      Icons.error_outline,
                                      color: Colors.red,
                                      size: 30,
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      timeString,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[500],
                      ),
                    ),
                    if (isMe) ...[
                      const SizedBox(width: 4),
                      Icon(
                        message['is_read'] == true
                            ? Icons.done_all
                            : Icons.done,
                        size: 14,
                        color: message['is_read'] == true
                            ? Colors.blue
                            : Colors.grey[500],
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          if (isMe) ...[
            const SizedBox(width: 8),
            CircleAvatar(
              radius: 16,
              backgroundColor: const Color(0xFF4169E1).withValues(alpha: 0.1),
              child: const Text(
                'U',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF4169E1),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _onMessageChanged(String text) {
    final bool typing = text.isNotEmpty;
    if (typing != _isTyping) {
      _isTyping = typing;
      _chatService.setTyping(widget.bookingId, widget.currentUserId, typing);
    }
  }

  void _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    setState(() => _isSending = true);
    _messageController.clear();

    // Stop typing indicator when sending message
    _chatService.setTyping(widget.bookingId, widget.currentUserId, false);
    _isTyping = false;

    try {
      await _chatService.sendMessage(
        bookingId: widget.bookingId,
        senderId: widget.currentUserId,
        text: text,
        senderName: 'User', // In real app, get from user data
      );
    } catch (e) {
      debugPrint('Error sending message: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to send message: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _isSending = false);
    }
  }

  void _attachFile() {
    showModalBottomSheet(
      context: context,
      builder: (context) =>
          Container(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: const Icon(
                      Icons.photo_camera, color: Color(0xFF4169E1)),
                  title: const Text('Camera'),
                  onTap: () {
                    Navigator.pop(context);
                    _takePicture();
                  },
                ),
                ListTile(
                  leading: const Icon(
                      Icons.photo_library, color: Color(0xFF4169E1)),
                  title: const Text('Gallery'),
                  onTap: () {
                    Navigator.pop(context);
                    _pickFromGallery();
                  },
                ),
                ListTile(
                  leading: const Icon(
                      Icons.attach_file, color: Color(0xFF4169E1)),
                  title: const Text('Document'),
                  onTap: () {
                    Navigator.pop(context);
                    _pickDocument();
                  },
                ),
              ],
            ),
          ),
    );
  }

  void _takePicture() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Camera feature will be implemented'),
        backgroundColor: Color(0xFF4169E1),
      ),
    );
  }

  void _pickFromGallery() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Gallery feature will be implemented'),
        backgroundColor: Color(0xFF4169E1),
      ),
    );
  }

  void _pickDocument() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Document picker will be implemented'),
        backgroundColor: Color(0xFF4169E1),
      ),
    );
  }

  void _callHandyman() {
    final phoneNumber = widget.handyman['phoneNumber'];
    if (phoneNumber != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Calling $phoneNumber...'),
          backgroundColor: const Color(0xFF2ECC71),
        ),
      );
    }
  }

  void _showMoreOptions() {
    showModalBottomSheet(
      context: context,
      builder: (context) =>
          Container(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: const Icon(Icons.block, color: Colors.red),
                  title: const Text('Block User'),
                  onTap: () {
                    Navigator.pop(context);
                    _blockUser();
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.report, color: Colors.orange),
                  title: const Text('Report Issue'),
                  onTap: () {
                    Navigator.pop(context);
                    _reportIssue();
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.delete, color: Colors.red),
                  title: const Text('Clear Chat'),
                  onTap: () {
                    Navigator.pop(context);
                    _clearChat();
                  },
                ),
              ],
            ),
          ),
    );
  }

  void _blockUser() {
    showDialog(
      context: context,
      builder: (context) =>
          AlertDialog(
            title: const Text('Block User'),
            content: Text('Are you sure you want to block ${widget
                .handyman['fullName']}?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('User blocked successfully'),
                      backgroundColor: Colors.red,
                    ),
                  );
                },
                child: const Text('Block', style: TextStyle(color: Colors.red)),
              ),
            ],
          ),
    );
  }

  void _reportIssue() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Report feature will be implemented'),
        backgroundColor: Colors.orange,
      ),
    );
  }

  void _showMessageOptions(Map<String, dynamic> message) {
    showModalBottomSheet(
      context: context,
      builder: (context) =>
          Container(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: const Icon(Icons.copy, color: Color(0xFF4169E1)),
                  title: const Text('Copy Text'),
                  onTap: () {
                    Navigator.pop(context);
                    // Copy text to clipboard
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Text copied to clipboard'),
                        backgroundColor: Color(0xFF4169E1),
                      ),
                    );
                  },
                ),
                if (message['sender_id'] == widget.currentUserId) ...[
                  ListTile(
                    leading: const Icon(Icons.delete, color: Colors.red),
                    title: const Text('Delete Message'),
                    onTap: () {
                      Navigator.pop(context);
                      _deleteMessage(message);
                    },
                  ),
                ],
                ListTile(
                  leading: const Icon(Icons.info_outline, color: Colors.grey),
                  title: const Text('Message Info'),
                  onTap: () {
                    Navigator.pop(context);
                    _showMessageInfo(message);
                  },
                ),
              ],
            ),
          ),
    );
  }

  void _deleteMessage(Map<String, dynamic> message) {
    showDialog(
      context: context,
      builder: (context) =>
          AlertDialog(
            title: const Text('Delete Message'),
            content: const Text(
                'Are you sure you want to delete this message?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () async {
                  Navigator.pop(context);
                  try {
                    await _chatService.deleteMessage(
                        widget.bookingId, message['id']);
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Message deleted'),
                          backgroundColor: Colors.green,
                        ),
                      );
                    }
                  } catch (e) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Failed to delete message: $e'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  }
                },
                child: const Text(
                    'Delete', style: TextStyle(color: Colors.red)),
              ),
            ],
          ),
    );
  }

  void _showMessageInfo(Map<String, dynamic> message) {
    final timestamp = (message['timestamp'] as dynamic)?.toDate();
    final formattedTime = timestamp != null
        ? '${timestamp.day}/${timestamp.month}/${timestamp.year} at ${timestamp
        .hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(
        2, '0')}'
        : 'Unknown';

    showDialog(
      context: context,
      builder: (context) =>
          AlertDialog(
            title: const Text('Message Info'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Sender: ${message['sender_name'] ?? 'Unknown'}'),
                const SizedBox(height: 8),
                Text('Time: $formattedTime'),
                const SizedBox(height: 8),
                Text('Status: ${message['is_read'] == true
                    ? 'Read'
                    : 'Delivered'}'),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Close'),
              ),
            ],
          ),
    );
  }

  void _clearChat() {
    showDialog(
      context: context,
      builder: (context) =>
          AlertDialog(
            title: const Text('Clear Chat'),
            content: const Text(
                'Are you sure you want to clear this chat? This action cannot be undone.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () async {
                  Navigator.pop(context);
                  try {
                    await _chatService.clearChat(widget.bookingId);
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Chat cleared successfully'),
                          backgroundColor: Colors.green,
                        ),
                      );
                    }
                  } catch (e) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Failed to clear chat: $e'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  }
                },
                child: const Text('Clear', style: TextStyle(color: Colors.red)),
              ),
            ],
          ),
    );
  }

  Widget _buildTypingDot(int delay) {
    return AnimatedContainer(
      duration: Duration(milliseconds: 600 + delay),
      curve: Curves.easeInOut,
      width: 6,
      height: 6,
      decoration: BoxDecoration(
        color: Colors.grey.withOpacity(0.6),
        shape: BoxShape.circle,
      ),
    );
  }
}
