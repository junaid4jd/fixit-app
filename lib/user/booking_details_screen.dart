import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/auth_service.dart';
import 'chat_screen.dart';

class BookingDetailsScreen extends StatefulWidget {
  final Map<String, dynamic> serviceData;
  final String serviceId;
  final Map<String, dynamic> handymanData;
  final String handymanId;

  const BookingDetailsScreen({
    super.key,
    required this.serviceData,
    required this.serviceId,
    required this.handymanData,
    required this.handymanId,
  });

  @override
  State<BookingDetailsScreen> createState() => _BookingDetailsScreenState();
}

class _BookingDetailsScreenState extends State<BookingDetailsScreen> {
  final AuthService _authService = AuthService();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();

  DateTime _selectedDate = DateTime.now();
  TimeOfDay _selectedTime = TimeOfDay.now();
  String _selectedPaymentMethod = 'cash';
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  @override
  void dispose() {
    _addressController.dispose();
    _notesController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    if (_authService.currentUserId != null) {
      final userData = await _authService.getUserData(
          _authService.currentUserId!);
      if (userData != null && mounted) {
        setState(() {
          _addressController.text = userData['address'] ?? '';
          _phoneController.text = userData['phoneNumber'] ?? '';
        });
      }
    }
  }

  Future<void> _submitBookingRequest() async {
    if (_authService.currentUserId == null) return;

    if (_addressController.text
        .trim()
        .isEmpty || _phoneController.text
        .trim()
        .isEmpty) {
      _showErrorSnackBar('Please fill in all required fields');
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Create booking document
      final bookingData = {
        'serviceId': widget.serviceId,
        'handyman_id': widget.handymanId,
        // Changed from 'handymanId' to 'handyman_id'
        'user_id': _authService.currentUserId!,
        // Changed from 'userId' to 'user_id'
        'serviceTitle': widget.serviceData['title'],
        'serviceDescription': widget.serviceData['description'],
        'servicePrice': widget.serviceData['price'],
        'category': widget.serviceData['category'],
        // Changed from 'serviceCategory' to 'category'
        'handymanName': widget.handymanData['fullName'],
        'handymanEmail': widget.handymanData['email'],
        'scheduled_date': Timestamp.fromDate(_selectedDate),
        // Changed from 'scheduledDate' to 'scheduled_date'
        'scheduled_time': '${_selectedTime.hour}:${_selectedTime.minute
            .toString().padLeft(2, '0')}',
        // Changed from 'scheduledTime' to 'scheduled_time'
        'address': _addressController.text.trim(),
        // Changed from 'customerAddress' to 'address'
        'phone_number': _phoneController.text.trim(),
        // Changed from 'customerPhone' to 'phone_number'
        'special_instructions': _notesController.text.trim(),
        // Changed from 'customerNotes' to 'special_instructions'
        'payment_method': _selectedPaymentMethod,
        // Changed from 'paymentMethod' to 'payment_method'
        'status': 'pending',
        // pending, accepted, rejected, in_progress, completed, cancelled
        'estimated_cost': widget.serviceData['price'],
        // Changed from 'totalAmount' to 'estimated_cost'
        'created_at': Timestamp.now(),
        // Changed from 'createdAt' to 'created_at'
        'updated_at': Timestamp.now(),
        // Changed from 'updatedAt' to 'updated_at'
      };

      // Add booking to Firestore
      final docRef = await FirebaseFirestore.instance
          .collection('bookings')
          .add(bookingData);

      // Update booking with ID
      await docRef.update({
        'booking_id': docRef.id
      }); // Changed from 'bookingId' to 'booking_id'

      // Create chat room for this booking
      await _createChatRoom(docRef.id);

      if (mounted) {
        _showSuccessSnackBar('Booking request sent successfully!');
        Navigator.of(context).pop();
        Navigator.of(context).pop(); // Go back to home screen
      }
    } catch (e) {
      if (mounted) {
        _showErrorSnackBar('Failed to send booking request: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _createChatRoom(String bookingId) async {
    if (_authService.currentUserId == null) return;

    try {
      await FirebaseFirestore.instance.collection('chats').doc(bookingId).set({
        'booking_id': bookingId, // Changed from 'bookingId' to 'booking_id'
        'user_id': _authService.currentUserId!,
        'handyman_id': widget.handymanId,
        'participants': [_authService.currentUserId!, widget.handymanId],
        'last_message': 'Booking request created',
        // Changed from 'lastMessage' to 'last_message'
        'last_message_time': Timestamp.now(),
        // Changed from 'lastMessageTime' to 'last_message_time'
        'unread_count': {'user': 0, 'handyman': 1},
        // Changed from 'unreadCount' to 'unread_count'
        'created_at': Timestamp.now(),
        // Changed from 'createdAt' to 'created_at'
      });
    } catch (e) {
      print('Error creating chat room: $e');
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.green),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: const Color(0xFF4169E1),
        foregroundColor: Colors.white,
        title: const Text('Book Service'),
        elevation: 0,
        actions: [
          IconButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      ChatScreen(
                        bookingId: 'temp_${DateTime
                            .now()
                            .millisecondsSinceEpoch}',
                        handyman: widget.handymanData,
                        currentUserId: _authService.currentUserId!,
                      ),
                ),
              );
            },
            icon: const Icon(Icons.chat),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
          child: CircularProgressIndicator(color: Color(0xFF4169E1)))
          : SingleChildScrollView(
        child: Column(
          children: [
            // Service Summary Card
            _buildServiceSummaryCard(),

            // Date & Time Selection
            _buildDateTimeSection(),

            // Customer Details
            _buildCustomerDetailsSection(),

            // Payment Method
            _buildPaymentMethodSection(),

            // Additional Notes
            _buildNotesSection(),

            // Total and Book Button
            _buildBookingFooter(),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildServiceSummaryCard() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 25,
                backgroundColor: const Color(0xFF4169E1).withValues(alpha: 0.1),
                child: widget.handymanData['profileImageUrl'] != null
                    ? ClipOval(
                  child: Image.network(
                    widget.handymanData['profileImageUrl'],
                    fit: BoxFit.cover,
                    width: 50,
                    height: 50,
                    errorBuilder: (context, error, stackTrace) {
                      return Text(
                        (widget.handymanData['fullName'] ?? 'H')[0]
                            .toUpperCase(),
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF4169E1),
                        ),
                      );
                    },
                  ),
                )
                    : Text(
                  (widget.handymanData['fullName'] ?? 'H')[0].toUpperCase(),
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF4169E1),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.handymanData['fullName'] ?? 'Handyman',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2C3E50),
                      ),
                    ),
                    Row(
                      children: [
                        const Icon(Icons.star, color: Colors.amber, size: 16),
                        const SizedBox(width: 4),
                        Text(
                          '${(widget.handymanData['rating'] ?? 0.0)
                              .toStringAsFixed(1)}',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF2C3E50),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${widget.handymanData['experienceYears'] ??
                              0} years exp',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const Divider(height: 24),
          Text(
            widget.serviceData['title'] ?? 'Service',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2C3E50),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            widget.serviceData['description'] ?? '',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFF4169E1).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  widget.serviceData['category'] ?? '',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF4169E1),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              Text(
                'OMR ${(widget.serviceData['price'] ?? 0).toStringAsFixed(2)}',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF4169E1),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDateTimeSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Select Date & Time',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2C3E50),
            ),
          ),
          const SizedBox(height: 16),
          // Calendar
          TableCalendar<Event>(
            firstDay: DateTime.now(),
            lastDay: DateTime.now().add(const Duration(days: 365)),
            focusedDay: _selectedDate,
            calendarFormat: CalendarFormat.month,
            selectedDayPredicate: (day) => isSameDay(_selectedDate, day),
            onDaySelected: (selectedDay, focusedDay) {
              setState(() {
                _selectedDate = selectedDay;
              });
            },
            calendarStyle: const CalendarStyle(
              outsideDaysVisible: false,
              selectedDecoration: BoxDecoration(
                color: Color(0xFF4169E1),
                shape: BoxShape.circle,
              ),
              todayDecoration: BoxDecoration(
                color: Colors.orange,
                shape: BoxShape.circle,
              ),
            ),
            headerStyle: const HeaderStyle(
              formatButtonVisible: false,
              titleCentered: true,
            ),
          ),
          const SizedBox(height: 16),
          // Time Selection
          Row(
            children: [
              const Icon(Icons.access_time, color: Color(0xFF4169E1)),
              const SizedBox(width: 8),
              const Text(
                'Preferred Time:',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF2C3E50),
                ),
              ),
              const Spacer(),
              GestureDetector(
                onTap: () async {
                  final TimeOfDay? time = await showTimePicker(
                    context: context,
                    initialTime: _selectedTime,
                  );
                  if (time != null) {
                    setState(() {
                      _selectedTime = time;
                    });
                  }
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF4169E1).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFF4169E1)),
                  ),
                  child: Text(
                    _selectedTime.format(context),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF4169E1),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCustomerDetailsSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Customer Details',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2C3E50),
            ),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _phoneController,
            keyboardType: TextInputType.phone,
            decoration: InputDecoration(
              labelText: 'Phone Number *',
              prefixIcon: const Icon(Icons.phone, color: Color(0xFF4169E1)),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Color(0xFF4169E1)),
              ),
            ),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _addressController,
            maxLines: 3,
            decoration: InputDecoration(
              labelText: 'Service Address *',
              prefixIcon: const Icon(
                  Icons.location_on, color: Color(0xFF4169E1)),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Color(0xFF4169E1)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentMethodSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Payment Method',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2C3E50),
            ),
          ),
          const SizedBox(height: 16),
          _buildPaymentOption('cash', 'Cash on Completion', Icons.money),
          _buildPaymentOption('card', 'Credit/Debit Card', Icons.credit_card),
          _buildPaymentOption('bank', 'Bank Transfer', Icons.account_balance),
        ],
      ),
    );
  }

  Widget _buildPaymentOption(String value, String title, IconData icon) {
    return RadioListTile<String>(
      value: value,
      groupValue: _selectedPaymentMethod,
      onChanged: (String? val) {
        setState(() {
          _selectedPaymentMethod = val!;
        });
      },
      title: Row(
        children: [
          Icon(icon, color: const Color(0xFF4169E1)),
          const SizedBox(width: 8),
          Text(title),
        ],
      ),
      activeColor: const Color(0xFF4169E1),
    );
  }

  Widget _buildNotesSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Additional Notes',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2C3E50),
            ),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _notesController,
            maxLines: 4,
            decoration: InputDecoration(
              hintText: 'Any specific instructions or requirements...',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Color(0xFF4169E1)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBookingFooter() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Total Amount:',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2C3E50),
                ),
              ),
              Text(
                'OMR ${(widget.serviceData['price'] ?? 0).toStringAsFixed(2)}',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF4169E1),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _submitBookingRequest,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4169E1),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: _isLoading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text(
                'Send Booking Request',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Event class for calendar
class Event {
  final String title;

  const Event(this.title);
}