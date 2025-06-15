import 'package:cloud_firestore/cloud_firestore.dart';

class AdminStatsService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Calculate comprehensive dashboard statistics with real data
  static Future<Map<String, dynamic>> getDashboardStats() async {
    try {
      print('🔧 Starting getDashboardStats...');

      // Get current month data
      DateTime now = DateTime.now();
      DateTime currentMonthStart = DateTime(now.year, now.month, 1);
      DateTime lastMonthStart = DateTime(now.year, now.month - 1, 1);
      DateTime lastMonthEnd = DateTime(now.year, now.month, 1).subtract(
          const Duration(days: 1));

      print(
          '📅 Date ranges: Current month start: $currentMonthStart, Last month: $lastMonthStart to $lastMonthEnd');

      // Get comprehensive user statistics
      Map<String, dynamic> userStats = await _getComprehensiveUserStats(
          currentMonthStart, lastMonthStart, lastMonthEnd);
      print('👥 User stats loaded: $userStats');

      // Get booking statistics  
      Map<String, dynamic> bookingStats = await _getBookingStats(
          currentMonthStart, lastMonthStart, lastMonthEnd);
      print('📋 Booking stats loaded: $bookingStats');

      // Get revenue statistics
      Map<String, dynamic> revenueStats = await _getRevenueStats(
          currentMonthStart, lastMonthStart, lastMonthEnd);
      print('💰 Revenue stats loaded: $revenueStats');

      // Get additional comprehensive stats
      Map<String, dynamic> serviceStats = await _getServiceStats();
      print('🔧 Service stats loaded: $serviceStats');

      Map<String, dynamic> reviewStats = await _getReviewStats();
      print('⭐ Review stats loaded: $reviewStats');

      Map<String, dynamic> categoryStats = await _getCategoryStats();
      print('📂 Category stats loaded: $categoryStats');

      final allStats = {
        ...userStats,
        ...bookingStats,
        ...revenueStats,
        ...serviceStats,
        ...reviewStats,
        ...categoryStats,
      };

      print('✅ Final stats: $allStats');
      return allStats;
    } catch (e) {
      print('❌ Error in getDashboardStats: $e');
      print('Stack trace: ${StackTrace.current}');
      // Return default values if error occurs
      return {
        'totalUsers': 0,
        'userGrowth': 0.0,
        'totalHandymen': 0,
        'verifiedHandymen': 0,
        'unverifiedHandymen': 0,
        'pendingVerifications': 0,
        'handymenGrowth': 0.0,
        'verificationRate': 0.0,
        'totalBookings': 0,
        'pendingBookings': 0,
        'activeBookings': 0,
        'completedBookings': 0,
        'cancelledBookings': 0,
        'rejectedBookings': 0,
        'bookingGrowth': 0.0,
        'completionRate': 0.0,
        'totalRevenue': 0.0,
        'revenueGrowth': 0.0,
        'totalServices': 0,
        'approvedServices': 0,
        'pendingServices': 0,
        'rejectedServices': 0,
        'activeServices': 0,
        'totalReviews': 0,
        'pendingReviews': 0,
        'approvedReviews': 0,
        'averageRating': 0.0,
        'totalCategories': 0,
        'activeCategories': 0,
        'totalCommission': 0.0,
        'averageOrderValue': 0.0,
      };
    }
  }

  static Future<Map<String, dynamic>> _getComprehensiveUserStats(
      DateTime currentStart,
      DateTime lastStart, DateTime lastEnd) async {
    try {
      print('🔍 Starting user stats collection...');

      // First, let's debug what's in the users collection
      QuerySnapshot allUsersDebug = await _firestore.collection('users').get();
      print('👥 Total users in database: ${allUsersDebug.docs.length}');

      // Debug: Print ALL users to see structure
      for (int i = 0; i < allUsersDebug.docs.length; i++) {
        var doc = allUsersDebug.docs[i];
        var data = doc.data() as Map<String, dynamic>;
        print('👤 User ${i + 1} (${doc
            .id}): fullName=${data['fullName']}, role=${data['role']}, isVerified=${data['isVerified']}, verification_status=${data['verification_status']}');
      }

      // Total users count
      QuerySnapshot totalUsers = await _firestore.collection('users').get();
      print('👥 Total users query result: ${totalUsers.docs.length}');

      // Regular users (customers) - simple approach
      int customerCount = 0;
      int serviceProviderCount = 0;
      int verifiedProviderCount = 0;
      int unverifiedProviderCount = 0;
      int pendingProviderCount = 0;

      for (var doc in totalUsers.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final role = data['role']?.toString() ?? '';

        if (role == 'user') {
          customerCount++;
        } else if (role == 'service_provider') {
          serviceProviderCount++;

          final isVerified = data['isVerified'];
          final verificationStatus = data['verification_status']?.toString() ??
              '';

          print(
              '🔧 Provider analysis: ${data['fullName']} - isVerified: $isVerified, status: $verificationStatus');

          if (isVerified == true) {
            verifiedProviderCount++;
          } else {
            unverifiedProviderCount++;
          }

          if (verificationStatus == 'pending') {
            pendingProviderCount++;
          }
        }
      }

      print('📊 Manual count results:');
      print('  - Total users: ${totalUsers.docs.length}');
      print('  - Customers: $customerCount');
      print('  - Service providers: $serviceProviderCount');
      print('  - Verified providers: $verifiedProviderCount');
      print('  - Unverified providers: $unverifiedProviderCount');
      print('  - Pending providers: $pendingProviderCount');

      // Try regular queries for comparison
      try {
        QuerySnapshot customers = await _firestore
            .collection('users')
            .where('role', isEqualTo: 'user')
            .get();
        print('🧑‍💼 Customers (query): ${customers.docs.length}');
      } catch (e) {
        print('❌ Error querying customers: $e');
      }

      try {
        QuerySnapshot allHandymen = await _firestore
            .collection('users')
            .where('role', isEqualTo: 'service_provider')
            .get();
        print('🔧 Service providers (query): ${allHandymen.docs.length}');
      } catch (e) {
        print('❌ Error querying service providers: $e');
      }

      // Calculate verification rate
      double verificationRate = serviceProviderCount > 0 ?
      (verifiedProviderCount / serviceProviderCount) * 100 : 0.0;

      final result = {
        'totalUsers': totalUsers.docs.length,
        'totalCustomers': customerCount,
        'userGrowth': 0.0, // Simplified for now
        'totalHandymen': serviceProviderCount,
        'verifiedHandymen': verifiedProviderCount,
        'unverifiedHandymen': unverifiedProviderCount,
        'pendingVerifications': pendingProviderCount,
        'handymenGrowth': 0.0, // Simplified for now
        'verificationRate': verificationRate,
      };

      print('📊 Final user stats result: $result');
      return result;
    } catch (e) {
      print('❌ Error in _getComprehensiveUserStats: $e');
      print('Stack trace: ${StackTrace.current}');
      return {
        'totalUsers': 0,
        'totalCustomers': 0,
        'userGrowth': 0.0,
        'totalHandymen': 0,
        'verifiedHandymen': 0,
        'unverifiedHandymen': 0,
        'pendingVerifications': 0,
        'handymenGrowth': 0.0,
        'verificationRate': 0.0,
      };
    }
  }

  static Future<Map<String, dynamic>> _getBookingStats(DateTime currentStart,
      DateTime lastStart, DateTime lastEnd) async {
    try {
      // Total bookings
      QuerySnapshot totalBookings = await _firestore
          .collection('bookings')
          .get();

      // Bookings by status
      Map<String, int> statusCounts = {
        'pending': 0,
        'accepted': 0,
        'in_progress': 0,
        'completed': 0,
        'cancelled': 0,
        'rejected': 0,
      };

      // Count bookings by status
      for (var doc in totalBookings.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final status = data['status']?.toString().toLowerCase() ?? 'unknown';
        if (statusCounts.containsKey(status)) {
          statusCounts[status] = statusCounts[status]! + 1;
        }
      }

      // Current month bookings
      QuerySnapshot currentBookings = await _firestore
          .collection('bookings')
          .where('created_at',
          isGreaterThanOrEqualTo: Timestamp.fromDate(currentStart))
          .get();

      // Last month bookings (with error handling)
      QuerySnapshot lastBookings;
      try {
        lastBookings = await _firestore
            .collection('bookings')
            .where(
            'created_at', isGreaterThanOrEqualTo: Timestamp.fromDate(lastStart))
            .where(
            'created_at', isLessThanOrEqualTo: Timestamp.fromDate(lastEnd))
            .get();
      } catch (e) {
        print('Error querying last month bookings: $e');
        lastBookings = await _firestore.collection('bookings').limit(0).get();
      }

      // Calculate active bookings (accepted + in_progress)
      int activeBookings = statusCounts['accepted']! +
          statusCounts['in_progress']!;

      // Calculate booking growth
      double bookingGrowth = _calculateGrowth(
          currentBookings.docs.length.toDouble(),
          lastBookings.docs.length.toDouble());

      // Calculate completion rate
      double completionRate = totalBookings.docs.isEmpty ? 0.0 :
      (statusCounts['completed']! / totalBookings.docs.length) * 100;

      return {
        'totalBookings': totalBookings.docs.length,
        'pendingBookings': statusCounts['pending']!,
        'acceptedBookings': statusCounts['accepted']!,
        'activeBookings': activeBookings,
        'inProgressBookings': statusCounts['in_progress']!,
        'completedBookings': statusCounts['completed']!,
        'cancelledBookings': statusCounts['cancelled']!,
        'rejectedBookings': statusCounts['rejected']!,
        'bookingGrowth': bookingGrowth,
        'completionRate': completionRate,
        'cancellationRate': totalBookings.docs.isEmpty ? 0.0 :
        (statusCounts['cancelled']! / totalBookings.docs.length) * 100,
      };
    } catch (e) {
      print('Error in _getBookingStats: $e');
      return {
        'totalBookings': 0,
        'pendingBookings': 0,
        'acceptedBookings': 0,
        'activeBookings': 0,
        'inProgressBookings': 0,
        'completedBookings': 0,
        'cancelledBookings': 0,
        'rejectedBookings': 0,
        'bookingGrowth': 0.0,
        'completionRate': 0.0,
        'cancellationRate': 0.0,
      };
    }
  }

  static Future<Map<String, dynamic>> _getRevenueStats(DateTime currentStart,
      DateTime lastStart, DateTime lastEnd) async {
    try {
      // All completed bookings for total revenue
      QuerySnapshot allCompletedBookings = await _firestore
          .collection('bookings')
          .where('status', isEqualTo: 'completed')
          .get();

      // Current month completed bookings for revenue
      QuerySnapshot currentRevenue = await _firestore
          .collection('bookings')
          .where('status', isEqualTo: 'completed')
          .where('completed_at',
          isGreaterThanOrEqualTo: Timestamp.fromDate(currentStart))
          .get();

      // Last month completed bookings for revenue (with error handling)
      QuerySnapshot lastRevenue;
      try {
        lastRevenue = await _firestore
            .collection('bookings')
            .where('status', isEqualTo: 'completed')
            .where('completed_at',
            isGreaterThanOrEqualTo: Timestamp.fromDate(lastStart))
            .where(
            'completed_at', isLessThanOrEqualTo: Timestamp.fromDate(lastEnd))
            .get();
      } catch (e) {
        print('Error querying last month revenue: $e');
        lastRevenue = await _firestore.collection('bookings').limit(0).get();
      }

      // Calculate current month revenue
      double currentMonthRevenue = 0;
      for (var doc in currentRevenue.docs) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        currentMonthRevenue +=
            (data['final_cost'] ?? data['estimated_cost'] ?? 0).toDouble();
      }

      // Calculate last month revenue
      double lastMonthRevenue = 0;
      for (var doc in lastRevenue.docs) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        lastMonthRevenue +=
            (data['final_cost'] ?? data['estimated_cost'] ?? 0).toDouble();
      }

      // Calculate total revenue
      double totalRevenue = 0;
      double totalCommission = 0;
      const double commissionRate = 0.05; // 5% commission rate

      for (var doc in allCompletedBookings.docs) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        double amount = (data['final_cost'] ?? data['estimated_cost'] ?? 0)
            .toDouble();
        totalRevenue += amount;
        totalCommission += amount * commissionRate;
      }

      // Calculate average order value
      double averageOrderValue = allCompletedBookings.docs.isEmpty ? 0.0 :
      totalRevenue / allCompletedBookings.docs.length;

      // Calculate growth
      double revenueGrowth = _calculateGrowth(
          currentMonthRevenue, lastMonthRevenue);

      return {
        'totalRevenue': totalRevenue,
        'currentMonthRevenue': currentMonthRevenue,
        'lastMonthRevenue': lastMonthRevenue,
        'totalCommission': totalCommission,
        'averageOrderValue': averageOrderValue,
        'revenueGrowth': revenueGrowth,
      };
    } catch (e) {
      print('Error in _getRevenueStats: $e');
      return {
        'totalRevenue': 0.0,
        'currentMonthRevenue': 0.0,
        'lastMonthRevenue': 0.0,
        'totalCommission': 0.0,
        'averageOrderValue': 0.0,
        'revenueGrowth': 0.0,
      };
    }
  }

  static Future<Map<String, dynamic>> _getServiceStats() async {
    try {
      // Check if handyman_services collection exists and has documents
      QuerySnapshot totalServices = await _firestore
          .collection('handyman_services')
          .limit(1)
          .get();

      if (totalServices.docs.isEmpty) {
        // Collection doesn't exist or is empty, return zeros
        return {
          'totalServices': 0,
          'approvedServices': 0,
          'pendingServices': 0,
          'rejectedServices': 0,
          'activeServices': 0,
          'serviceApprovalRate': 0.0,
        };
      }

      // Get all services
      QuerySnapshot allServices = await _firestore
          .collection('handyman_services')
          .get();

      // Count services by status
      Map<String, int> statusCounts = {
        'approved': 0,
        'pending': 0,
        'rejected': 0,
        'active': 0,
      };

      for (var doc in allServices.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final approvalStatus = data['approval_status']
            ?.toString()
            .toLowerCase();
        final isActive = data['is_active'] == true;

        if (approvalStatus == 'approved')
          statusCounts['approved'] = statusCounts['approved']! + 1;
        if (approvalStatus == 'pending')
          statusCounts['pending'] = statusCounts['pending']! + 1;
        if (approvalStatus == 'rejected')
          statusCounts['rejected'] = statusCounts['rejected']! + 1;
        if (isActive && approvalStatus == 'approved')
          statusCounts['active'] = statusCounts['active']! + 1;
      }

      double approvalRate = allServices.docs.isEmpty ? 0.0 :
      (statusCounts['approved']! / allServices.docs.length) * 100;

      return {
        'totalServices': allServices.docs.length,
        'approvedServices': statusCounts['approved']!,
        'pendingServices': statusCounts['pending']!,
        'rejectedServices': statusCounts['rejected']!,
        'activeServices': statusCounts['active']!,
        'serviceApprovalRate': approvalRate,
      };
    } catch (e) {
      print('Error in _getServiceStats: $e');
      return {
        'totalServices': 0,
        'approvedServices': 0,
        'pendingServices': 0,
        'rejectedServices': 0,
        'activeServices': 0,
        'serviceApprovalRate': 0.0,
      };
    }
  }

  static Future<Map<String, dynamic>> _getReviewStats() async {
    try {
      // Check if reviews collection exists
      QuerySnapshot testReviews = await _firestore
          .collection('reviews')
          .limit(1)
          .get();

      if (testReviews.docs.isEmpty) {
        return {
          'totalReviews': 0,
          'pendingReviews': 0,
          'approvedReviews': 0,
          'averageRating': 0.0,
        };
      }

      // Total reviews
      QuerySnapshot totalReviews = await _firestore
          .collection('reviews')
          .get();

      // Count reviews by status
      Map<String, int> statusCounts = {
        'pending': 0,
        'approved': 0,
      };

      double totalRating = 0;
      int ratingCount = 0;

      for (var doc in totalReviews.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final status = data['status']?.toString().toLowerCase() ?? 'approved';

        if (status == 'pending')
          statusCounts['pending'] = statusCounts['pending']! + 1;
        if (status == 'approved')
          statusCounts['approved'] = statusCounts['approved']! + 1;

        // Calculate average rating from approved reviews
        if (status == 'approved' && data['rating'] != null) {
          totalRating += (data['rating'] as num).toDouble();
          ratingCount++;
        }
      }

      double averageRating = ratingCount > 0 ? totalRating / ratingCount : 0.0;

      return {
        'totalReviews': totalReviews.docs.length,
        'pendingReviews': statusCounts['pending']!,
        'approvedReviews': statusCounts['approved']!,
        'averageRating': averageRating,
      };
    } catch (e) {
      print('Error in _getReviewStats: $e');
      return {
        'totalReviews': 0,
        'pendingReviews': 0,
        'approvedReviews': 0,
        'averageRating': 0.0,
      };
    }
  }

  static Future<Map<String, dynamic>> _getCategoryStats() async {
    try {
      // Check if categories collection exists
      QuerySnapshot testCategories = await _firestore
          .collection('categories')
          .limit(1)
          .get();

      if (testCategories.docs.isEmpty) {
        return {
          'totalCategories': 0,
          'activeCategories': 0,
        };
      }

      // Total categories
      QuerySnapshot totalCategories = await _firestore
          .collection('categories')
          .get();

      // Count active categories
      int activeCount = 0;
      for (var doc in totalCategories.docs) {
        final data = doc.data() as Map<String, dynamic>;
        if (data['isActive'] == true) {
          activeCount++;
        }
      }

      return {
        'totalCategories': totalCategories.docs.length,
        'activeCategories': activeCount,
      };
    } catch (e) {
      print('Error in _getCategoryStats: $e');
      return {
        'totalCategories': 0,
        'activeCategories': 0,
      };
    }
  }

  // Get detailed analytics for admin dashboard
  static Future<Map<String, dynamic>> getDetailedAnalytics() async {
    try {
      DateTime now = DateTime.now();
      DateTime startOfWeek = now.subtract(Duration(days: now.weekday - 1));
      DateTime startOfMonth = DateTime(now.year, now.month, 1);
      DateTime startOfYear = DateTime(now.year, 1, 1);

      // Weekly stats
      QuerySnapshot weeklyBookings = await _firestore
          .collection('bookings')
          .where(
          'created_at', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfWeek))
          .get();

      QuerySnapshot weeklyUsers = await _firestore
          .collection('users')
          .where(
          'createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfWeek))
          .get();

      // Monthly stats  
      QuerySnapshot monthlyBookings = await _firestore
          .collection('bookings')
          .where('created_at',
          isGreaterThanOrEqualTo: Timestamp.fromDate(startOfMonth))
          .get();

      QuerySnapshot monthlyUsers = await _firestore
          .collection('users')
          .where(
          'createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfMonth))
          .get();

      // Yearly stats
      QuerySnapshot yearlyBookings = await _firestore
          .collection('bookings')
          .where(
          'created_at', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfYear))
          .get();

      QuerySnapshot yearlyUsers = await _firestore
          .collection('users')
          .where(
          'createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfYear))
          .get();

      return {
        'weeklyBookings': weeklyBookings.docs.length,
        'weeklyUsers': weeklyUsers.docs.length,
        'monthlyBookings': monthlyBookings.docs.length,
        'monthlyUsers': monthlyUsers.docs.length,
        'yearlyBookings': yearlyBookings.docs.length,
        'yearlyUsers': yearlyUsers.docs.length,
      };
    } catch (e) {
      print('Error in getDetailedAnalytics: $e');
      return {
        'weeklyBookings': 0,
        'weeklyUsers': 0,
        'monthlyBookings': 0,
        'monthlyUsers': 0,
        'yearlyBookings': 0,
        'yearlyUsers': 0,
      };
    }
  }

  static double _calculateGrowth(double current, double previous) {
    if (previous == 0) {
      return current > 0 ? 100.0 : 0.0;
    }
    return ((current - previous) / previous) * 100;
  }

  static String formatGrowth(double growth) {
    if (growth > 0) {
      return '+${growth.toStringAsFixed(1)}%';
    } else if (growth < 0) {
      return '${growth.toStringAsFixed(1)}%';
    } else {
      return '0%';
    }
  }

  static String formatCurrency(double amount) {
    return '${amount.toStringAsFixed(3)} OMR';
  }

  static String formatPercentage(double percentage) {
    return '${percentage.toStringAsFixed(1)}%';
  }
}
