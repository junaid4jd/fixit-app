import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get current user
  User? get currentUser => _auth.currentUser;

  String? get currentUserId => _auth.currentUser?.uid;

  // Check if user is logged in
  bool get isLoggedIn => _auth.currentUser != null;

  // Listen to auth state changes
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Sign up with email and password
  Future<UserCredential?> signUpWithEmailAndPassword({
    required String email,
    required String password,
    required String fullName,
    required String phoneNumber,
    required String userType, // 'user' or 'service_provider'
    Map<String, dynamic>? additionalData,
  }) async {
    try {
      UserCredential userCredential = await _auth
          .createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Store user data in Firestore with proper role-based structure
      Map<String, dynamic> userData = {
        'uid': userCredential.user!.uid,
        'email': email,
        'fullName': fullName,
        'phoneNumber': phoneNumber,
        'role': userType, // Changed from userType to role for consistency
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'isActive': true,
        'fcmToken': null, // Will be updated when user logs in
      };

      // Add role-specific fields
      if (userType == 'user') {
        userData.addAll({
          'isVerified': true, // Users are auto-verified
          'city': null,
          'totalBookings': 0,
          'totalSpent': 0.0,
          'favoriteCategories': [],
        });
      } else if (userType == 'service_provider') {
        userData.addAll({
          'isVerified': false, // Service providers need verification
          'verification_status': 'pending',
          'businessName': additionalData?['businessName'] ?? '',
          'primaryCategory': additionalData?['serviceCategory'] ?? '',
          'yearsOfExperience': additionalData?['yearsOfExperience'] ?? 0,
          'averageRating': 0.0,
          'totalReviews': 0,
          'totalBookings': 0,
          'completedBookings': 0,
          'hourlyRate': 0.0,
          'city': null,
          'services': [additionalData?['serviceCategory'] ?? ''],
          'availability': {},
          'statistics': {
            'totalRequests': 0,
            'totalAccepted': 0,
            'totalCompleted': 0,
          },
        });
      }

      // Add any additional data
      if (additionalData != null) {
        userData.addAll(additionalData);
      }

      await _firestore.collection('users').doc(userCredential.user!.uid).set(
          userData);

      // Initialize user notification settings
      await _firestore
          .collection('user_settings')
          .doc(userCredential.user!.uid)
          .set({
        'notifications_enabled': true,
        'email_notifications': true,
        'push_notifications': true,
        'sms_notifications': false,
        'created_at': FieldValue.serverTimestamp(),
      });

      return userCredential;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      throw Exception('An unexpected error occurred: ${e.toString()}');
    }
  }

  // Sign in with email and password
  Future<UserCredential?> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return userCredential;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      throw Exception('An unexpected error occurred: ${e.toString()}');
    }
  }

  // Sign out
  Future<void> signOut() async {
    try {
      await _auth.signOut();
    } catch (e) {
      throw Exception('Failed to sign out: ${e.toString()}');
    }
  }

  // Send password reset email
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      throw Exception('Failed to send password reset email: ${e.toString()}');
    }
  }

  // Get user data
  Future<Map<String, dynamic>?> getUserData(String userId) async {
    try {
      DocumentSnapshot userDoc = await _firestore.collection('users').doc(
          userId).get();
      if (userDoc.exists) {
        return userDoc.data() as Map<String, dynamic>;
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get user data: ${e.toString()}');
    }
  }

  // Get user type
  Future<String?> getUserType(String userId) async {
    try {
      DocumentSnapshot userDoc = await _firestore.collection('users').doc(
          userId).get();
      if (userDoc.exists) {
        return userDoc.get('role');
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get user type: ${e.toString()}');
    }
  }

  // Update user data
  Future<void> updateUserData(String uid, Map<String, dynamic> data) async {
    try {
      await _firestore.collection('users').doc(uid).update(data);
    } catch (e) {
      throw Exception('Failed to update user data: ${e.toString()}');
    }
  }

  // Service provider specific: Update verification status
  Future<void> updateVerificationStatus(String userId, bool isVerified) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'isVerified': isVerified,
        'verifiedAt': isVerified ? FieldValue.serverTimestamp() : null,
      });
    } catch (e) {
      throw Exception('Failed to update verification status: ${e.toString()}');
    }
  }

  // Service provider specific: Add identity verification data
  Future<void> addIdentityVerification(String userId,
      Map<String, dynamic> verificationData) async {
    try {
      await _firestore.collection('identity_verifications').doc(userId).set({
        'userId': userId,
        'status': 'pending',
        'submittedAt': FieldValue.serverTimestamp(),
        ...verificationData,
      });

      // Update user document to indicate verification submitted
      await _firestore.collection('users').doc(userId).update({
        'verificationSubmitted': true,
      });
    } catch (e) {
      throw Exception('Failed to add identity verification: ${e.toString()}');
    }
  }

  // Get all categories
  Future<List<Map<String, dynamic>>> getCategories() async {
    try {
      QuerySnapshot categorySnapshot = await _firestore
          .collection('categories')
          .where('isActive', isEqualTo: true)
          .orderBy('order')
          .get();

      List<Map<String, dynamic>> categories = categorySnapshot.docs
          .map((doc) =>
      {
        'id': doc.id,
        ...doc.data() as Map<String, dynamic>,
      })
          .toList();

      debugPrint('Fetched ${categories.length} active categories');
      return categories;
    } catch (e) {
      debugPrint('Error fetching categories: $e');

      // Try fetching without the compound query as fallback
      try {
        debugPrint('Trying fallback query for categories...');
        QuerySnapshot fallbackSnapshot = await _firestore
            .collection('categories')
            .get();

        List<Map<String, dynamic>> allCategories = fallbackSnapshot.docs
            .map((doc) =>
        {
          'id': doc.id,
          ...doc.data() as Map<String, dynamic>,
        })
            .toList();

        // Filter and sort locally
        List<Map<String, dynamic>> activeCategories = allCategories
            .where((category) => category['isActive'] == true)
            .toList();

        activeCategories.sort((a, b) =>
            (a['order'] ?? 0).compareTo(b['order'] ?? 0));

        debugPrint('Fallback query returned ${activeCategories
            .length} active categories');
        return activeCategories;
      } catch (fallbackError) {
        debugPrint('Fallback query also failed: $fallbackError');
        return [];
      }
    }
  }

  // Get all cities
  Future<List<Map<String, dynamic>>> getCities() async {
    try {
      QuerySnapshot citySnapshot = await _firestore
          .collection('cities')
          .where('isActive', isEqualTo: true)
          .orderBy('name')
          .get();

      List<Map<String, dynamic>> cities = citySnapshot.docs
          .map((doc) =>
      {
        'id': doc.id,
        ...doc.data() as Map<String, dynamic>,
      })
          .toList();

      debugPrint('Fetched ${cities.length} active cities');
      return cities;
    } catch (e) {
      debugPrint('Error fetching cities: $e');

      // Try fetching without the compound query as fallback
      try {
        debugPrint('Trying fallback query for cities...');
        QuerySnapshot fallbackSnapshot = await _firestore
            .collection('cities')
            .get();

        List<Map<String, dynamic>> allCities = fallbackSnapshot.docs
            .map((doc) =>
        {
          'id': doc.id,
          ...doc.data() as Map<String, dynamic>,
        })
            .toList();

        // Filter and sort locally
        List<Map<String, dynamic>> activeCities = allCities
            .where((city) => city['isActive'] == true)
            .toList();

        activeCities.sort((a, b) =>
            (a['name'] ?? '').toString().compareTo(
                (b['name'] ?? '').toString()));

        debugPrint(
            'Fallback query returned ${activeCities.length} active cities');
        return activeCities;
      } catch (fallbackError) {
        debugPrint('Fallback query also failed: $fallbackError');
        return [];
      }
    }
  }

  // Get handymen by city and category
  Future<List<Map<String, dynamic>>> getHandymenByCityAndCategory({
    required String city,
    required String category,
  }) async {
    try {
      QuerySnapshot handymenSnapshot = await _firestore
          .collection('users')
          .where('role', isEqualTo: 'service_provider')
          .where('isVerified', isEqualTo: true)
          .where('isActive', isEqualTo: true)
          .where('city', isEqualTo: city)
          .where('primaryCategory', isEqualTo: category)
          .get();

      return handymenSnapshot.docs
          .map((doc) =>
      {
        'id': doc.id,
        ...doc.data() as Map<String, dynamic>,
      })
          .toList();
    } catch (e) {
      debugPrint('Error fetching handymen: $e');
      return [];
    }
  }

  // Get all verified handymen in a city
  Future<List<Map<String, dynamic>>> getHandymenByCity(String city) async {
    try {
      QuerySnapshot handymenSnapshot = await _firestore
          .collection('users')
          .where('role', isEqualTo: 'service_provider')
          .where('isVerified', isEqualTo: true)
          .where('isActive', isEqualTo: true)
          .where('city', isEqualTo: city)
          .get();

      return handymenSnapshot.docs
          .map((doc) =>
      {
        'id': doc.id,
        ...doc.data() as Map<String, dynamic>,
      })
          .toList();
    } catch (e) {
      print('Error fetching handymen by city: $e');
      return [];
    }
  }

  // Get featured handymen for home screen
  Future<List<Map<String, dynamic>>> getFeaturedHandymen(String city) async {
    try {
      QuerySnapshot handymenSnapshot = await _firestore
          .collection('users')
          .where('role', isEqualTo: 'service_provider')
          .where('isVerified', isEqualTo: true)
          .where('isActive', isEqualTo: true)
          .where('city', isEqualTo: city)
          .orderBy('averageRating', descending: true)
          .limit(10)
          .get();

      return handymenSnapshot.docs
          .map((doc) =>
      {
        'id': doc.id,
        ...doc.data() as Map<String, dynamic>,
      })
          .toList();
    } catch (e) {
      debugPrint('Error fetching featured handymen: $e');
      // Fallback without orderBy if compound query fails
      try {
        QuerySnapshot fallbackSnapshot = await _firestore
            .collection('users')
            .where('role', isEqualTo: 'service_provider')
            .where('isVerified', isEqualTo: true)
            .where('isActive', isEqualTo: true)
            .limit(10)
            .get();

        List<Map<String, dynamic>> allHandymen = fallbackSnapshot.docs
            .map((doc) =>
        {
          'id': doc.id,
          ...doc.data() as Map<String, dynamic>,
        })
            .toList();

        // Filter by city locally
        List<Map<String, dynamic>> cityHandymen = allHandymen
            .where((handyman) => handyman['city'] == city)
            .toList();

        return cityHandymen;
      } catch (fallbackError) {
        debugPrint('Fallback query also failed: $fallbackError');
        return [];
      }
    }
  }

  // Get category count for a city
  Future<int> getCategoryCountInCity(String city, String category) async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection('users')
          .where('role', isEqualTo: 'service_provider')
          .where('isVerified', isEqualTo: true)
          .where('isActive', isEqualTo: true)
          .where('city', isEqualTo: city)
          .where('primaryCategory', isEqualTo: category)
          .get();

      return snapshot.docs.length;
    } catch (e) {
      print('Error fetching category count: $e');
      return 0;
    }
  }

  // Get handyman reviews
  Future<List<Map<String, dynamic>>> getHandymanReviews(
      String handymanId) async {
    try {
      QuerySnapshot reviewSnapshot = await _firestore
          .collection('reviews')
          .where('handyman_id', isEqualTo: handymanId)
          .where('status', isEqualTo: 'approved') // Only show approved reviews
          .orderBy('created_at', descending: true)
          .limit(20)
          .get();

      return reviewSnapshot.docs
          .map((doc) =>
      {
        'id': doc.id,
        ...doc.data() as Map<String, dynamic>,
      }).toList();
    } catch (e) {
      debugPrint('Error fetching handyman reviews: $e');
      return [];
    }
  }

  // Get handyman gallery
  Future<List<Map<String, dynamic>>> getHandymanGallery(
      String handymanId) async {
    try {
      QuerySnapshot gallerySnapshot = await _firestore
          .collection('gallery')
          .where('handymanId', isEqualTo: handymanId)
          .orderBy('createdAt', descending: true)
          .get();

      return gallerySnapshot.docs
          .map((doc) =>
      {
        'id': doc.id,
        ...doc.data() as Map<String, dynamic>,
      })
          .toList();
    } catch (e) {
      print('Error fetching handyman gallery: $e');
      return [];
    }
  }

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
    String? serviceId, // For service-specific bookings
    String? serviceTitle, // For service-specific bookings
  }) async {
    try {
      // Ensure user is authenticated
      if (userId.isEmpty || handymanId.isEmpty) {
        throw Exception('Invalid user or handyman ID');
      }

      // Validate required fields
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
        bookingData['booking_type'] = 'service'; // vs 'general'
      } else {
        bookingData['booking_type'] = 'general';
      }

      debugPrint('🔧 Creating booking with data: $bookingData');

      DocumentReference bookingRef = await _firestore
          .collection('bookings')
          .add(bookingData);

      debugPrint('✅ Booking created with ID: ${bookingRef.id}');

      // Verify the booking was actually created by reading it back
      try {
        final createdDoc = await bookingRef.get();
        if (createdDoc.exists) {
          final createdData = createdDoc.data() as Map<String, dynamic>;
          debugPrint('✅ Booking verified in database: ${bookingRef.id}');
          debugPrint(
              '📋 Verified data: user_id=${createdData['user_id']}, status=${createdData['status']}');
        } else {
          debugPrint('❌ WARNING: Booking document not found after creation!');
        }
      } catch (verifyError) {
        debugPrint('⚠️ Could not verify booking creation: $verifyError');
      }

      // Get user and handyman names for notifications
      final userDoc = await _firestore.collection('users').doc(userId).get();
      return bookingRef.id;
    } catch (e) {
      debugPrint('Error creating booking request: $e');
      throw Exception('Failed to create booking request: ${e.toString()}');
    }
  }

  // Get user's bookings
  Future<List<Map<String, dynamic>>> getUserBookings(String userId) async {
    try {
      debugPrint('🔎 Fetching bookings for user: $userId');

      // Use simple query without orderBy to avoid index requirement
      QuerySnapshot bookingSnapshot = await _firestore
          .collection('bookings')
          .where('user_id', isEqualTo: userId)
          .get();

      debugPrint('📊 Found ${bookingSnapshot.docs
          .length} documents in bookings collection for user $userId');

      final bookings = bookingSnapshot.docs
          .map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        final bookingWithId = {
          'id': doc.id,
          ...data,
        };
        debugPrint('📝 Booking ${doc
            .id}: user_id=${data['user_id']}, status=${data['status']}, category=${data['category']}');
        return bookingWithId;
      }).toList();

      // Sort locally by created_at timestamp (newest first)
      bookings.sort((a, b) {
        final aTime = a['created_at'];
        final bTime = b['created_at'];

        if (aTime == null && bTime == null) return 0;
        if (aTime == null) return 1;
        if (bTime == null) return -1;

        if (aTime is Timestamp && bTime is Timestamp) {
          return bTime.compareTo(aTime); // Descending order (newest first)
        }

        return 0;
      });

      debugPrint(
        '✅ Returning ${bookings.length} bookings for user $userId (sorted locally)',
      );
      return bookings;
    } catch (e) {
      debugPrint('💥 Error fetching user bookings for $userId: $e');
      return [];
    }
  }

  // Get handyman's booking requests
  Future<List<Map<String, dynamic>>> getHandymanBookings(
      String handymanId) async {
    try {
      QuerySnapshot bookingSnapshot = await _firestore
          .collection('bookings')
          .where('handyman_id', isEqualTo: handymanId)
          .orderBy('created_at', descending: true)
          .get();

      return bookingSnapshot.docs
          .map((doc) =>
      {
        'id': doc.id,
        ...doc.data() as Map<String, dynamic>,
      }).toList();
    } catch (e) {
      debugPrint('Error fetching handyman bookings: $e');
      return [];
    }
  }

  // Update booking status
  Future<void> updateBookingStatus(String bookingId, String status) async {
    try {
      await _firestore.collection('bookings').doc(bookingId).update({
        'status': status,
        'updated_at': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Failed to update booking status: ${e.toString()}');
    }
  }

  // Update user's selected city
  Future<void> updateUserCity(String userId, String city) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'city': city,
        'updated_at': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Failed to update user city: ${e.toString()}');
    }
  }

  // Initialize chat for a booking
  Future<void> _initializeChatForBooking(String bookingId, String userId,
      String handymanId, String userName, String handymanName) async {
    try {
      debugPrint('Initializing chat for booking: $bookingId');

      // Create chat document
      await _firestore.collection('chats').doc(bookingId).set({
        'booking_id': bookingId,
        'user_id': userId,
        'handyman_id': handymanId,
        'user_name': userName,
        'handyman_name': handymanName,
        'created_at': FieldValue.serverTimestamp(),
        'last_message': 'Chat started for your booking request',
        'last_message_time': FieldValue.serverTimestamp(),
        'last_sender_id': 'system',
      });

      debugPrint('Chat document created successfully');

      // Add initial system message
      await _firestore
          .collection('chats')
          .doc(bookingId)
          .collection('messages')
          .add({
        'sender_id': 'system',
        'sender_name': 'System',
        'text': 'Chat started for your booking request. You can now communicate with each other.',
        'timestamp': FieldValue.serverTimestamp(),
        'is_read': false,
        'type': 'system',
      });

      debugPrint('Initial chat message added successfully');
    } catch (e) {
      debugPrint('Error initializing chat: $e');
      // Don't rethrow - chat initialization failure shouldn't fail the entire booking
    }
  }

  // Get user's chats
  Future<List<Map<String, dynamic>>> getUserChats(String userId) async {
    try {
      QuerySnapshot chatSnapshot = await _firestore
          .collection('chats')
          .where('user_id', isEqualTo: userId)
          .orderBy('last_message_time', descending: true)
          .get();

      return chatSnapshot.docs
          .map((doc) =>
      {
        'id': doc.id,
        ...doc.data() as Map<String, dynamic>,
      }).toList();
    } catch (e) {
      debugPrint('Error fetching user chats: $e');
      return [];
    }
  }

  // Get handyman's chats
  Future<List<Map<String, dynamic>>> getHandymanChats(String handymanId) async {
    try {
      QuerySnapshot chatSnapshot = await _firestore
          .collection('chats')
          .where('handyman_id', isEqualTo: handymanId)
          .orderBy('last_message_time', descending: true)
          .get();

      return chatSnapshot.docs
          .map((doc) =>
      {
        'id': doc.id,
        ...doc.data() as Map<String, dynamic>,
      }).toList();
    } catch (e) {
      debugPrint('Error fetching handyman chats: $e');
      return [];
    }
  }

  // Check if chat exists for booking
  Future<bool> chatExistsForBooking(String bookingId) async {
    try {
      DocumentSnapshot chatDoc = await _firestore.collection('chats').doc(
          bookingId).get();
      return chatDoc.exists;
    } catch (e) {
      debugPrint('Error checking chat existence: $e');
      return false;
    }
  }

  // Handle Firebase Auth exceptions
  String _handleAuthException(FirebaseAuthException e) {
    switch (e.code) {
      case 'weak-password':
        return 'The password provided is too weak.';
      case 'email-already-in-use':
        return 'An account already exists with this email address.';
      case 'invalid-email':
        return 'The email address is not valid.';
      case 'user-not-found':
        return 'No user found with this email address.';
      case 'wrong-password':
        return 'Incorrect password.';
      case 'user-disabled':
        return 'This user account has been disabled.';
      case 'too-many-requests':
        return 'Too many failed attempts. Please try again later.';
      case 'operation-not-allowed':
        return 'This sign-in method is not allowed.';
      default:
        return 'Authentication failed: ${e.message}';
    }
  }

  // Check if user is signed in
  bool get isSignedIn => _auth.currentUser != null;

  // Get handyman statistics
  Future<Map<String, dynamic>> getHandymanStats(String handymanId) async {
    try {
      // Get handyman bookings for stats
      final bookingsSnapshot = await _firestore
          .collection('bookings')
          .where('handyman_id', isEqualTo: handymanId)
          .get();

      // Calculate today's jobs
      final today = DateTime.now();
      final todayStart = DateTime(today.year, today.month, today.day);
      final todayEnd = todayStart.add(const Duration(days: 1));

      int todayJobs = bookingsSnapshot.docs.where((doc) {
        final data = doc.data();
        if (data['scheduled_date'] != null) {
          final scheduledDate = (data['scheduled_date'] as Timestamp).toDate();
          return scheduledDate.isAfter(todayStart) &&
              scheduledDate.isBefore(todayEnd);
        }
        return false;
      }).length;

      // Calculate this month's jobs
      final monthStart = DateTime(today.year, today.month, 1);
      final monthEnd = DateTime(today.year, today.month + 1, 1);

      int monthJobs = bookingsSnapshot.docs.where((doc) {
        final data = doc.data();
        if (data['scheduled_date'] != null) {
          final scheduledDate = (data['scheduled_date'] as Timestamp).toDate();
          return scheduledDate.isAfter(monthStart) &&
              scheduledDate.isBefore(monthEnd);
        }
        return false;
      }).length;

      // Calculate total earnings
      double totalEarnings = 0.0;
      for (var doc in bookingsSnapshot.docs) {
        final data = doc.data();
        if (data['status'] == 'completed' && data['estimated_cost'] != null) {
          totalEarnings += (data['estimated_cost'] as num).toDouble();
        }
      }

      // Get reviews for rating
      final reviewsSnapshot = await _firestore
          .collection('reviews')
          .where('handyman_id', isEqualTo: handymanId)
          .where('status', isEqualTo: 'approved')
          .get();

      double averageRating = 0.0;
      if (reviewsSnapshot.docs.isNotEmpty) {
        double totalRating = 0.0;
        for (var doc in reviewsSnapshot.docs) {
          final data = doc.data();
          if (data['rating'] != null) {
            totalRating += (data['rating'] as num).toDouble();
          }
        }
        averageRating = totalRating / reviewsSnapshot.docs.length;
      }

      return {
        'todayJobs': todayJobs,
        'monthJobs': monthJobs,
        'totalEarnings': totalEarnings,
        'averageRating': averageRating,
        'totalReviews': reviewsSnapshot.docs.length,
        'totalBookings': bookingsSnapshot.docs.length,
        'completedBookings': bookingsSnapshot.docs
            .where((doc) => doc.data()['status'] == 'completed')
            .length,
      };
    } catch (e) {
      debugPrint('Error fetching handyman stats: $e');
      return {
        'todayJobs': 0,
        'monthJobs': 0,
        'totalEarnings': 0.0,
        'averageRating': 0.0,
        'totalReviews': 0,
        'totalBookings': 0,
        'completedBookings': 0,
      };
    }
  }

  // Get recent bookings for handyman
  Future<List<Map<String, dynamic>>> getRecentHandymanBookings(
      String handymanId, {int limit = 5}) async {
    try {
      final bookingsSnapshot = await _firestore
          .collection('bookings')
          .where('handyman_id', isEqualTo: handymanId)
          .orderBy('created_at', descending: true)
          .limit(limit)
          .get();

      List<Map<String, dynamic>> bookings = [];

      for (var doc in bookingsSnapshot.docs) {
        final bookingData = {
          'id': doc.id,
          ...doc.data(),
        };

        // Get user details
        if (bookingData['user_id'] != null) {
          try {
            final userDoc = await _firestore
                .collection('users')
                .doc(bookingData['user_id'])
                .get();

            if (userDoc.exists) {
              bookingData['user_name'] =
                  userDoc.data()?['fullName'] ?? 'Unknown User';
            }
          } catch (e) {
            debugPrint('Error fetching user data: $e');
            bookingData['user_name'] = 'Unknown User';
          }
        }

        bookings.add(bookingData);
      }

      return bookings;
    } catch (e) {
      debugPrint('Error fetching recent bookings: $e');
      return [];
    }
  }

  // Change user password
  Future<void> changePassword(String currentPassword,
      String newPassword) async {
    try {
      User? user = _auth.currentUser;
      if (user == null) {
        throw Exception('No user is currently signed in');
      }

      // Re-authenticate user with current password
      AuthCredential credential = EmailAuthProvider.credential(
        email: user.email!,
        password: currentPassword,
      );

      await user.reauthenticateWithCredential(credential);

      // Update password
      await user.updatePassword(newPassword);
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      throw Exception('Failed to change password: ${e.toString()}');
    }
  }

  // Delete user account
  Future<void> deleteAccount() async {
    try {
      User? user = _auth.currentUser;
      if (user == null) {
        throw Exception('No user is currently signed in');
      }

      String userId = user.uid;

      // Delete user data from Firestore
      await _firestore.collection('users').doc(userId).delete();

      // Delete user settings
      await _firestore.collection('user_settings').doc(userId).delete();

      // Delete user's bookings (optional - you might want to keep for records)
      QuerySnapshot userBookings = await _firestore
          .collection('bookings')
          .where('user_id', isEqualTo: userId)
          .get();

      for (var doc in userBookings.docs) {
        await doc.reference.delete();
      }

      // Delete user's chats
      QuerySnapshot userChats = await _firestore
          .collection('chats')
          .where('user_id', isEqualTo: userId)
          .get();

      for (var doc in userChats.docs) {
        await doc.reference.delete();
      }

      // Delete user account from Firebase Auth
      await user.delete();
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      throw Exception('Failed to delete account: ${e.toString()}');
    }
  }
}
