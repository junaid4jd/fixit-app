import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../models/app_models.dart';

class BookingScreen extends StatefulWidget {
  final Map<String, dynamic>? handyman;
  final String? category;
  final HandymanService? service;
  final ServiceProvider? serviceProvider;

  const BookingScreen({
    super.key,
    this.handyman,
    this.category,
    this.service,
    this.serviceProvider,
  });

  @override
  State<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends State<BookingScreen> {
  final AuthService _authService = AuthService();
  final _formKey = GlobalKey<FormState>();

  final _serviceDescriptionController = TextEditingController();
  final _addressController = TextEditingController();
  final _phoneController = TextEditingController();
  final _notesController = TextEditingController();

  DateTime _selectedDate = DateTime.now().add(const Duration(days: 1));
  String _selectedTimeSlot = '';
  double _estimatedCost = 0.0;
  bool _isLoading = false;

  final List<String> _timeSlots = [
    '08:00 - 10:00',
    '10:00 - 12:00',
    '12:00 - 14:00',
    '14:00 - 16:00',
    '16:00 - 18:00',
    '18:00 - 20:00',
  ];

  @override
  void initState() {
    super.initState();
    _selectedTimeSlot = _timeSlots.first;
    _calculateEstimatedCost();
    _prefilServiceDescription();
  }

  void _prefilServiceDescription() {
    if (widget.service != null) {
      _serviceDescriptionController.text = widget.service!.title;
    }
  }

  void _calculateEstimatedCost() {
    if (widget.service != null) {
      _estimatedCost = widget.service!.price;
    } else {
      final hourlyRate = widget.handyman?['hourlyRate'] ?? 0.0;
      _estimatedCost = hourlyRate * 2; // Assume 2 hours minimum
    }
  }

  String get _handymanName {
    if (widget.serviceProvider != null) {
      return widget.serviceProvider!.name;
    }
    return widget.handyman?['fullName'] ?? 'Handyman';
  }

  String get _handymanId {
    if (widget.serviceProvider != null) {
      return widget.serviceProvider!.id;
    }
    return widget.handyman?['id'] ?? '';
  }

  String get _serviceCategory {
    if (widget.service != null) {
      return widget.service!.category;
    }
    return widget.category ?? 'General Service';
  }

  double get _handymanRating {
    if (widget.serviceProvider != null) {
      return widget.serviceProvider!.rating;
    }
    return widget.handyman?['rating'] ?? 0.0;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text('Book $_handymanName'),
        backgroundColor: const Color(0xFF4169E1),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Service Info Card (if booking specific service)
              if (widget.service != null) ...[
                Container(
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
                          Expanded(
                            child: Text(
                              widget.service!.title,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF2C3E50),
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFF4169E1).withValues(
                                  alpha: 0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              widget.service!.category,
                              style: const TextStyle(
                                fontSize: 12,
                                color: Color(0xFF4169E1),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        widget.service!.description,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[700],
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Text(
                            'OMR ${widget.service!.price.toStringAsFixed(2)}',
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF4169E1),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _getPriceTypeText(widget.service!.priceType),
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
                const SizedBox(height: 20),
              ],

              // Handyman Info Card
              Container(
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
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 30,
                      backgroundColor: const Color(0xFF4169E1).withValues(
                          alpha: 0.1),
                      child: Text(
                        _handymanName.isNotEmpty
                            ? _handymanName
                            .split(' ')
                            .where((e) => e.isNotEmpty)
                            .map((e) => e[0])
                            .join()
                            .toUpperCase()
                            : 'H',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF4169E1),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _handymanName,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF2C3E50),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _serviceCategory,
                            style: const TextStyle(
                              fontSize: 14,
                              color: Color(0xFF7F8C8D),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const Icon(
                                  Icons.star, color: Colors.amber, size: 16),
                              const SizedBox(width: 4),
                              Text(
                                _handymanRating.toStringAsFixed(1),
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF2C3E50),
                                ),
                              ),
                              if (widget.serviceProvider != null) ...[
                                const SizedBox(width: 8),
                                Text(
                                  '${widget.serviceProvider!
                                      .experienceYears} years exp',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Color(0xFF7F8C8D),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 30),

              // Service Description (editable if not specific service)
              const Text(
                'Service Description',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2C3E50),
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _serviceDescriptionController,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: widget.service != null
                      ? 'Add additional details or requirements...'
                      : 'Describe the service you need...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFF4169E1)),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                ),
                validator: (value) {
                  if (value == null || value
                      .trim()
                      .isEmpty) {
                    if (widget.service == null) {
                      return 'Please describe the service you need';
                    } else {
                      return 'Please add details about your requirements';
                    }
                  }
                  if (value
                      .trim()
                      .length < 10) {
                    return 'Please provide more details (at least 10 characters)';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 24),

              // Date Selection
              const Text(
                'Preferred Date',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2C3E50),
                ),
              ),
              const SizedBox(height: 12),
              GestureDetector(
                onTap: _selectDate,
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFE0E0E0)),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                          Icons.calendar_today, color: Color(0xFF4169E1)),
                      const SizedBox(width: 12),
                      Text(
                        '${_selectedDate.day}/${_selectedDate
                            .month}/${_selectedDate.year}',
                        style: const TextStyle(
                          fontSize: 16,
                          color: Color(0xFF2C3E50),
                        ),
                      ),
                      const Spacer(),
                      const Icon(
                          Icons.arrow_forward_ios, color: Color(0xFF7F8C8D),
                          size: 16),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Time Slot Selection
              const Text(
                'Preferred Time',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2C3E50),
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _timeSlots.map((slot) {
                  final isSelected = slot == _selectedTimeSlot;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedTimeSlot = slot),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: isSelected ? const Color(0xFF4169E1) : Colors
                            .white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isSelected
                              ? const Color(0xFF4169E1)
                              : const Color(0xFFE0E0E0),
                        ),
                      ),
                      child: Text(
                        slot,
                        style: TextStyle(
                          color: isSelected ? Colors.white : const Color(
                              0xFF2C3E50),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),

              const SizedBox(height: 24),

              // Address
              const Text(
                'Service Address',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2C3E50),
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _addressController,
                maxLines: 2,
                decoration: InputDecoration(
                  hintText: 'Enter your full address...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFF4169E1)),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                ),
                validator: (value) {
                  if (value == null || value
                      .trim()
                      .isEmpty) {
                    return 'Please enter the service address';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 24),

              // Contact Phone
              const Text(
                'Contact Phone',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2C3E50),
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(
                  hintText: '+968 12345678',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFF4169E1)),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                ),
                validator: (value) {
                  if (value == null || value
                      .trim()
                      .isEmpty) {
                    return 'Please enter your phone number';
                  }
                  // Remove all non-digit characters for validation
                  String digitsOnly = value.replaceAll(RegExp(r'[^\d]'), '');
                  if (digitsOnly.length < 8) {
                    return 'Please enter a valid phone number';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 24),

              // Additional Notes
              const Text(
                'Additional Notes (Optional)',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2C3E50),
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _notesController,
                maxLines: 2,
                decoration: InputDecoration(
                  hintText: 'Any special instructions or requirements...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFF4169E1)),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                ),
              ),

              const SizedBox(height: 30),

              // Cost Estimate
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF4169E1).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: const Color(0xFF4169E1).withValues(alpha: 0.3)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Estimated Cost (2 hours minimum)',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF2C3E50),
                      ),
                    ),
                    Text(
                      '${_estimatedCost.toStringAsFixed(0)} OMR',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF4169E1),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 30),

              // Submit Button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submitBooking,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4169E1),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                    'Send Booking Request',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  String _getPriceTypeText(String priceType) {
    switch (priceType) {
      case 'fixed':
        return 'Fixed Price';
      case 'hourly':
        return 'Hourly Rate';
      case 'negotiable':
        return 'Negotiable';
      default:
        return 'Fixed Price';
    }
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 30)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF4169E1),
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Color(0xFF2C3E50),
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _submitBooking() async {
    try {
      debugPrint('🔄 Starting booking submission process...');

      // Form validation
      if (!_formKey.currentState!.validate()) {
        debugPrint('❌ Form validation failed');
        return;
      }

      // Additional validation
      if (_handymanId.isEmpty) {
        debugPrint('❌ Empty handyman ID detected');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Invalid handyman selection. Please try again.'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      if (_selectedDate.isBefore(
          DateTime.now().subtract(const Duration(hours: 1)))) {
        debugPrint('❌ Invalid date selected: $_selectedDate');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Please select a future date and time.'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      // Set loading state
      if (mounted) {
        setState(() => _isLoading = true);
      }

      // Check authentication
      final currentUserId = _authService.currentUserId;
      if (currentUserId == null) {
        throw Exception('User not logged in. Please sign in and try again.');
      }

      debugPrint('✅ Validation passed. Creating booking request...');
      debugPrint('👤 User ID: $currentUserId');
      debugPrint('🔧 Handyman ID: $_handymanId');

      // Create booking request
      final bookingId = await _authService.createBookingRequest(
        userId: currentUserId,
        handymanId: _handymanId,
        category: _serviceCategory,
        serviceDescription: _serviceDescriptionController.text.trim(),
        scheduledDate: _selectedDate,
        timeSlot: _selectedTimeSlot,
        estimatedCost: _estimatedCost,
        address: _addressController.text.trim(),
        contactInfo: {
          'phone': _phoneController.text.trim(),
          'notes': _notesController.text.trim(),
        },
        serviceId: widget.service?.id,
        serviceTitle: widget.service?.title,
      );

      debugPrint('🎉 Booking created successfully with ID: $bookingId');

      // Reset loading state immediately
      if (mounted) {
        setState(() => _isLoading = false);
      }

      // Show immediate success feedback without navigation issues
      if (mounted) {
        // Show success dialog instead of navigation
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (BuildContext context) {
            return Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Success Icon
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: const Color(0xFF2ECC71).withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.check_circle,
                        size: 50,
                        color: Color(0xFF2ECC71),
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Success Title
                    const Text(
                      'Booking Request Sent!',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2C3E50),
                      ),
                      textAlign: TextAlign.center,
                    ),

                    const SizedBox(height: 12),

                    // Success Message
                    const Text(
                      'Your booking request has been sent successfully. You will receive a notification once the handyman responds.',
                      style: TextStyle(
                        fontSize: 14,
                        color: Color(0xFF7F8C8D),
                        height: 1.4,
                      ),
                      textAlign: TextAlign.center,
                    ),

                    const SizedBox(height: 16),

                    // Booking ID
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF4169E1).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        children: [
                          const Text(
                            'Booking ID',
                            style: TextStyle(
                              fontSize: 12,
                              color: Color(0xFF7F8C8D),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            bookingId.length > 8 ? bookingId
                                .substring(0, 8)
                                .toUpperCase() : bookingId.toUpperCase(),
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF4169E1),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Action Buttons
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () {
                              Navigator.of(context).pop(); // Close dialog
                              Navigator
                                  .of(context)
                                  .pop(); // Go back to previous screen
                            },
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: Color(0xFF4169E1)),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: const Text(
                              'Done',
                              style: TextStyle(
                                color: Color(0xFF4169E1),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      }

    } catch (e) {
      debugPrint('💥 Error in booking submission: $e');

      // Reset loading state
      if (mounted) {
        setState(() => _isLoading = false);
      }

      if (mounted) {
        String errorMessage = 'Failed to create booking request.';

        // Parse specific error messages for better UX
        String errorString = e.toString().toLowerCase();
        if (errorString.contains('service description is required')) {
          errorMessage = 'Please describe the service you need.';
        } else if (errorString.contains('service address is required')) {
          errorMessage = 'Please enter your service address.';
        } else if (errorString.contains('phone number is required')) {
          errorMessage = 'Please enter your phone number.';
        } else if (errorString.contains('user not found')) {
          errorMessage = 'Your account was not found. Please sign in again.';
        } else if (errorString.contains('handyman not found')) {
          errorMessage = 'The selected handyman is no longer available.';
        } else if (errorString.contains('user not logged in')) {
          errorMessage = 'Please sign in to create a booking.';
        } else if (errorString.contains('permission-denied')) {
          errorMessage = 'You don\'t have permission to create bookings.';
        } else if (errorString.contains('network') ||
            errorString.contains('connection')) {
          errorMessage =
          'Network error. Please check your connection and try again.';
        } else if (errorString.contains('firebase') ||
            errorString.contains('firestore')) {
          errorMessage = 'Database error. Please try again in a moment.';
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
            action: SnackBarAction(
              label: 'Retry',
              textColor: Colors.white,
              onPressed: () => _submitBooking(),
            ),
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _serviceDescriptionController.dispose();
    _addressController.dispose();
    _phoneController.dispose();
    _notesController.dispose();
    super.dispose();
  }
}
