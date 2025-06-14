import 'package:cloud_firestore/cloud_firestore.dart';

class AdminStatsService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Calculate comprehensive dashboard statistics with real data
  static Future<Map<String, dynamic>> getDashboardStats() async {
    try {
      // Get current month data
      DateTime now = DateTime.now();
      DateTime currentMonthStart = DateTime(now.year, now.month, 1);
      DateTime lastMonthStart = DateTime(now.year, now.month - 1, 1);
      DateTime lastMonthEnd = DateTime(now.year, now.month, 1).subtract(
          const Duration(days: 1));

      // Get comprehensive user statistics
      Map<String, dynamic> userStats = await _getComprehensiveUserStats(
          currentMonthStart, lastMonthStart, lastMonthEnd);

      // Get booking statistics  
      Map<String, dynamic> bookingStats = await _getBookingStats(
          currentMonthStart, lastMonthStart, lastMonthEnd);

      // Get revenue statistics
      Map<String, dynamic> revenueStats = await _getRevenueStats(
          currentMonthStart, lastMonthStart, lastMonthEnd);

      // Get additional comprehensive stats
      Map<String, dynamic> serviceStats = await _getServiceStats();
      Map<String, dynamic> reviewStats = await _getReviewStats();
      Map<String, dynamic> categoryStats = await _getCategoryStats();

      return {
        ...userStats,
        ...bookingStats,
        ...revenueStats,
        ...serviceStats,
        ...reviewStats,
        ...categoryStats,
      };
    } catch (e) {
      // Return default values if error occurs
      return {
        'totalUsers': 0,
        'userGrowth': 0.0,
        'totalHandymen': 0,
        'verifiedHandymen': 0,
        'unverifiedHandymen': 0,
        'pendingVerifications': 0,
        'handymenGrowth': 0.0,
        'totalBookings': 0,
        'pendingBookings': 0,
        'activeBookings': 0,
        'completedBookings': 0,
        'cancelledBookings': 0,
        'rejectedBookings': 0,
        'bookingGrowth': 0.0,
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
      };
    }
  }

  static Future<Map<String, dynamic>> _getComprehensiveUserStats(
      DateTime currentStart,
      DateTime lastStart, DateTime lastEnd) async {
    // Total users count
    QuerySnapshot totalUsers = await _firestore.collection('users').get();

    // Regular users (customers)
    QuerySnapshot customers = await _firestore
        .collection('users')
        .where('role', isEqualTo: 'user')
        .get();

    // All service providers
    QuerySnapshot allHandymen = await _firestore
        .collection('users')
        .where('role', isEqualTo: 'service_provider')
        .get();

    // Verified service providers
    QuerySnapshot verifiedHandymen = await _firestore
        .collection('users')
        .where('role', isEqualTo: 'service_provider')
        .where('isVerified', isEqualTo: true)
        .get();

    // Unverified service providers
    QuerySnapshot unverifiedHandymen = await _firestore
        .collection('users')
        .where('role', isEqualTo: 'service_provider')
        .where('isVerified', isEqualTo: false)
        .get();

    // Pending verification requests (assuming there's a verification_status field)
    QuerySnapshot pendingVerifications = await _firestore
        .collection('users')
        .where('role', isEqualTo: 'service_provider')
        .where('verification_status', isEqualTo: 'pending')
        .get();

    // Current month users
    QuerySnapshot currentUsers = await _firestore
        .collection('users')
        .where(
        'createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(currentStart))
        .get();

    // Last month users  
    QuerySnapshot lastUsers = await _firestore
        .collection('users')
        .where(
        'createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(lastStart))
        .where('createdAt', isLessThanOrEqualTo: Timestamp.fromDate(lastEnd))
        .get();

    // Current month handymen
    QuerySnapshot currentHandymen = await _firestore
        .collection('users')
        .where('role', isEqualTo: 'service_provider')
        .where(
        'createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(currentStart))
        .get();

    // Last month handymen
    QuerySnapshot lastHandymen = await _firestore
        .collection('users')
        .where('role', isEqualTo: 'service_provider')
        .where(
        'createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(lastStart))
        .where('createdAt', isLessThanOrEqualTo: Timestamp.fromDate(lastEnd))
        .get();

    // Calculate growth percentages
    double userGrowth = _calculateGrowth(
        currentUsers.docs.length.toDouble(), lastUsers.docs.length.toDouble());
    double handymenGrowth = _calculateGrowth(
        currentHandymen.docs.length.toDouble(),
        lastHandymen.docs.length.toDouble());

    return {
      'totalUsers': totalUsers.docs.length,
      'totalCustomers': customers.docs.length,
      'userGrowth': userGrowth,
      'totalHandymen': allHandymen.docs.length,
      'verifiedHandymen': verifiedHandymen.docs.length,
      'unverifiedHandymen': unverifiedHandymen.docs.length,
      'pendingVerifications': pendingVerifications.docs.length,
      'handymenGrowth': handymenGrowth,
      'verificationRate': allHandymen.docs.isEmpty ? 0.0 :
      (verifiedHandymen.docs.length / allHandymen.docs.length) * 100,
    };
  }

  static Future<Map<String, dynamic>> _getBookingStats(DateTime currentStart,
      DateTime lastStart, DateTime lastEnd) async {
    // Total bookings
    QuerySnapshot totalBookings = await _firestore.collection('bookings').get();

    // Bookings by status
    QuerySnapshot pendingBookings = await _firestore
        .collection('bookings')
        .where('status', isEqualTo: 'pending')
        .get();

    QuerySnapshot acceptedBookings = await _firestore
        .collection('bookings')
        .where('status', isEqualTo: 'accepted')
        .get();

    QuerySnapshot inProgressBookings = await _firestore
        .collection('bookings')
        .where('status', isEqualTo: 'in_progress')
        .get();

    QuerySnapshot completedBookings = await _firestore
        .collection('bookings')
        .where('status', isEqualTo: 'completed')
        .get();

    QuerySnapshot cancelledBookings = await _firestore
        .collection('bookings')
        .where('status', isEqualTo: 'cancelled')
        .get();

    QuerySnapshot rejectedBookings = await _firestore
        .collection('bookings')
        .where('status', isEqualTo: 'rejected')
        .get();

    // Current month bookings
    QuerySnapshot currentBookings = await _firestore
        .collection('bookings')
        .where(
        'created_at', isGreaterThanOrEqualTo: Timestamp.fromDate(currentStart))
        .get();

    // Last month bookings
    QuerySnapshot lastBookings = await _firestore
        .collection('bookings')
        .where(
        'created_at', isGreaterThanOrEqualTo: Timestamp.fromDate(lastStart))
        .where('created_at', isLessThanOrEqualTo: Timestamp.fromDate(lastEnd))
        .get();

    // Calculate active bookings (accepted + in_progress)
    int activeBookings = acceptedBookings.docs.length +
        inProgressBookings.docs.length;

    // Calculate booking growth
    double bookingGrowth = _calculateGrowth(
        currentBookings.docs.length.toDouble(),
        lastBookings.docs.length.toDouble());

    // Calculate completion rate
    double completionRate = totalBookings.docs.isEmpty ? 0.0 :
    (completedBookings.docs.length / totalBookings.docs.length) * 100;

    return {
      'totalBookings': totalBookings.docs.length,
      'pendingBookings': pendingBookings.docs.length,
      'acceptedBookings': acceptedBookings.docs.length,
      'activeBookings': activeBookings,
      'inProgressBookings': inProgressBookings.docs.length,
      'completedBookings': completedBookings.docs.length,
      'cancelledBookings': cancelledBookings.docs.length,
      'rejectedBookings': rejectedBookings.docs.length,
      'bookingGrowth': bookingGrowth,
      'completionRate': completionRate,
      'cancellationRate': totalBookings.docs.isEmpty ? 0.0 :
      (cancelledBookings.docs.length / totalBookings.docs.length) * 100,
    };
  }

  static Future<Map<String, dynamic>> _getRevenueStats(DateTime currentStart,
      DateTime lastStart, DateTime lastEnd) async {
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

    // Last month completed bookings for revenue
    QuerySnapshot lastRevenue = await _firestore
        .collection('bookings')
        .where('status', isEqualTo: 'completed')
        .where(
        'completed_at', isGreaterThanOrEqualTo: Timestamp.fromDate(lastStart))
        .where('completed_at', isLessThanOrEqualTo: Timestamp.fromDate(lastEnd))
        .get();

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
  }

  static Future<Map<String, dynamic>> _getServiceStats() async {
    // Total services
    QuerySnapshot totalServices = await _firestore
        .collection('handyman_services')
        .get();

    // Services by approval status
    QuerySnapshot approvedServices = await _firestore
        .collection('handyman_services')
        .where('approval_status', isEqualTo: 'approved')
        .get();

    QuerySnapshot pendingServices = await _firestore
        .collection('handyman_services')
        .where('approval_status', isEqualTo: 'pending')
        .get();

    QuerySnapshot rejectedServices = await _firestore
        .collection('handyman_services')
        .where('approval_status', isEqualTo: 'rejected')
        .get();

    // Active services
    QuerySnapshot activeServices = await _firestore
        .collection('handyman_services')
        .where('approval_status', isEqualTo: 'approved')
        .where('is_active', isEqualTo: true)
        .get();

    double approvalRate = totalServices.docs.isEmpty ? 0.0 :
    (approvedServices.docs.length / totalServices.docs.length) * 100;

    return {
      'totalServices': totalServices.docs.length,
      'approvedServices': approvedServices.docs.length,
      'pendingServices': pendingServices.docs.length,
      'rejectedServices': rejectedServices.docs.length,
      'activeServices': activeServices.docs.length,
      'serviceApprovalRate': approvalRate,
    };
  }

  static Future<Map<String, dynamic>> _getReviewStats() async {
    // Total reviews
    QuerySnapshot totalReviews = await _firestore
        .collection('reviews')
        .get();

    // Reviews by status
    QuerySnapshot pendingReviews = await _firestore
        .collection('reviews')
        .where('status', isEqualTo: 'pending')
        .get();

    QuerySnapshot approvedReviews = await _firestore
        .collection('reviews')
        .where('status', isEqualTo: 'approved')
        .get();

    // Calculate average rating
    double totalRating = 0;
    int ratingCount = 0;

    for (var doc in approvedReviews.docs) {
      Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
      if (data['rating'] != null) {
        totalRating += (data['rating'] as num).toDouble();
        ratingCount++;
      }
    }

    double averageRating = ratingCount > 0 ? totalRating / ratingCount : 0.0;

    return {
      'totalReviews': totalReviews.docs.length,
      'pendingReviews': pendingReviews.docs.length,
      'approvedReviews': approvedReviews.docs.length,
      'averageRating': averageRating,
    };
  }

  static Future<Map<String, dynamic>> _getCategoryStats() async {
    // Total categories
    QuerySnapshot totalCategories = await _firestore
        .collection('service_categories')
        .get();

    // Active categories
    QuerySnapshot activeCategories = await _firestore
        .collection('service_categories')
        .where('is_active', isEqualTo: true)
        .get();

    return {
      'totalCategories': totalCategories.docs.length,
      'activeCategories': activeCategories.docs.length,
    };
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
