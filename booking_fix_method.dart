// Create a booking request
Future<String> createBookingRequest({
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
        .trim()
        .isEmpty) {
      throw Exception('Phone number is required');
    }

    Map<String, dynamic> bookingData = {
      'user_id': userId,
      'handyman_id': handymanId,
      'category': category,
      'description': serviceDescription.trim(),
      'scheduled_date': Timestamp.fromDate(scheduledDate),
      'scheduled_time': timeSlot,
      'estimated_cost': estimatedCost,
      'address': address.trim(),
      'phone_number': contactInfo['phone'].trim(),
      'special_instructions': contactInfo['notes']?.trim() ?? '',
      'status': 'pending',
      'created_at': FieldValue.serverTimestamp(),
      'updated_at': FieldValue.serverTimestamp(),
      'payment_status': 'pending',
      'is_reviewed': false,
    };

    // Add service-specific fields if this is a service booking
    if (serviceId != null) {
      bookingData['service_id'] = serviceId;
      bookingData['service_title'] = serviceTitle ?? '';
      bookingData['booking_type'] = 'service';
    } else {
      bookingData['booking_type'] = 'general';
    }

    debugPrint('🔧 Creating booking with data: $bookingData');

    DocumentReference bookingRef = await _firestore.collection('bookings').add(
        bookingData);

    debugPrint('✅ Booking created with ID: ${bookingRef.id}');

    return bookingRef.id;
  } catch (e) {
    debugPrint('💥 Error creating booking request: $e');
    throw Exception('Failed to create booking request: ${e.toString()}');
  }
}