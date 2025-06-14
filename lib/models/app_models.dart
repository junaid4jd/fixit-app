import 'package:cloud_firestore/cloud_firestore.dart';

class User {
  final String id;
  final String email;
  final String? name;
  final String? phoneNumber;
  final String? profileImageUrl;
  final String? city;
  final DateTime createdAt;
  final Map<String, dynamic>? preferences;

  User({
    required this.id,
    required this.email,
    this.name,
    this.phoneNumber,
    this.profileImageUrl,
    this.city,
    required this.createdAt,
    this.preferences,
  });

  factory User.fromMap(Map<String, dynamic> map, String id) {
    return User(
      id: id,
      email: map['email'] ?? '',
      name: map['name'],
      phoneNumber: map['phoneNumber'],
      profileImageUrl: map['profileImageUrl'],
      city: map['city'],
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt'] ?? 0),
      preferences: map['preferences'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'email': email,
      'name': name,
      'phoneNumber': phoneNumber,
      'profileImageUrl': profileImageUrl,
      'city': city,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'preferences': preferences,
    };
  }
}

class ServiceProvider {
  final String id;
  final String email;
  final String name;
  final String phoneNumber;
  final String? profileImageUrl;
  final List<String> services;
  final String city;
  final double hourlyRate;
  final double rating;
  final int experienceYears;
  final bool isVerified;
  final bool isAvailable;
  final DateTime createdAt;
  final String? bio;
  final List<String>? workPhotos;

  ServiceProvider({
    required this.id,
    required this.email,
    required this.name,
    required this.phoneNumber,
    this.profileImageUrl,
    required this.services,
    required this.city,
    required this.hourlyRate,
    required this.rating,
    required this.experienceYears,
    required this.isVerified,
    required this.isAvailable,
    required this.createdAt,
    this.bio,
    this.workPhotos,
  });

  factory ServiceProvider.fromMap(Map<String, dynamic> map, String id) {
    return ServiceProvider(
      id: id,
      email: map['email'] ?? '',
      name: map['name'] ?? '',
      phoneNumber: map['phoneNumber'] ?? '',
      profileImageUrl: map['profileImageUrl'],
      services: List<String>.from(map['services'] ?? []),
      city: map['city'] ?? '',
      hourlyRate: (map['hourlyRate'] ?? 0).toDouble(),
      rating: (map['rating'] ?? 0).toDouble(),
      experienceYears: map['experienceYears'] ?? 0,
      isVerified: map['isVerified'] ?? false,
      isAvailable: map['isAvailable'] ?? true,
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt'] ?? 0),
      bio: map['bio'],
      workPhotos: List<String>.from(map['workPhotos'] ?? []),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'email': email,
      'name': name,
      'phoneNumber': phoneNumber,
      'profileImageUrl': profileImageUrl,
      'services': services,
      'city': city,
      'hourlyRate': hourlyRate,
      'rating': rating,
      'experienceYears': experienceYears,
      'isVerified': isVerified,
      'isAvailable': isAvailable,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'bio': bio,
      'workPhotos': workPhotos,
    };
  }
}

class Booking {
  final String id;
  final String userId;
  final String handymanId;
  final String serviceCategory;
  final String description;
  final DateTime scheduledDate;
  final String address;
  final double estimatedCost;
  final double? finalCost;
  final BookingStatus status;
  final DateTime createdAt;
  final DateTime? completedAt;
  final String? notes;

  Booking({
    required this.id,
    required this.userId,
    required this.handymanId,
    required this.serviceCategory,
    required this.description,
    required this.scheduledDate,
    required this.address,
    required this.estimatedCost,
    this.finalCost,
    required this.status,
    required this.createdAt,
    this.completedAt,
    this.notes,
  });

  factory Booking.fromMap(Map<String, dynamic> map, String id) {
    return Booking(
      id: id,
      userId: map['userId'] ?? '',
      handymanId: map['handymanId'] ?? '',
      serviceCategory: map['serviceCategory'] ?? '',
      description: map['description'] ?? '',
      scheduledDate: DateTime.fromMillisecondsSinceEpoch(
          map['scheduledDate'] ?? 0),
      address: map['address'] ?? '',
      estimatedCost: (map['estimatedCost'] ?? 0).toDouble(),
      finalCost: map['finalCost']?.toDouble(),
      status: BookingStatus.values.firstWhere(
            (e) =>
        e
            .toString()
            .split('.')
            .last == (map['status'] ?? 'pending'),
        orElse: () => BookingStatus.pending,
      ),
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt'] ?? 0),
      completedAt: map['completedAt'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['completedAt'])
          : null,
      notes: map['notes'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'handymanId': handymanId,
      'serviceCategory': serviceCategory,
      'description': description,
      'scheduledDate': scheduledDate.millisecondsSinceEpoch,
      'address': address,
      'estimatedCost': estimatedCost,
      'finalCost': finalCost,
      'status': status
          .toString()
          .split('.')
          .last,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'completedAt': completedAt?.millisecondsSinceEpoch,
      'notes': notes,
    };
  }
}

enum BookingStatus {
  pending,
  accepted,
  inProgress,
  completed,
  cancelled,
  rejected
}

class ServiceCategory {
  final String id;
  final String name;
  final String iconPath;
  final String color;
  final bool isActive;
  final int order;

  ServiceCategory({
    required this.id,
    required this.name,
    required this.iconPath,
    required this.color,
    required this.isActive,
    required this.order,
  });

  factory ServiceCategory.fromMap(Map<String, dynamic> map, String id) {
    return ServiceCategory(
      id: id,
      name: map['name'] ?? '',
      iconPath: map['iconPath'] ?? '',
      color: map['color'] ?? '#4169E1',
      isActive: map['isActive'] ?? true,
      order: map['order'] ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'iconPath': iconPath,
      'color': color,
      'isActive': isActive,
      'order': order,
    };
  }
}

class Review {
  final String id;
  final String bookingId;
  final String userId;
  final String handymanId;
  final double rating;
  final String comment;
  final DateTime createdAt;

  Review({
    required this.id,
    required this.bookingId,
    required this.userId,
    required this.handymanId,
    required this.rating,
    required this.comment,
    required this.createdAt,
  });

  factory Review.fromMap(Map<String, dynamic> map, String id) {
    return Review(
      id: id,
      bookingId: map['bookingId'] ?? '',
      userId: map['userId'] ?? '',
      handymanId: map['handymanId'] ?? '',
      rating: (map['rating'] ?? 0).toDouble(),
      comment: map['comment'] ?? '',
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt'] ?? 0),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'bookingId': bookingId,
      'userId': userId,
      'handymanId': handymanId,
      'rating': rating,
      'comment': comment,
      'createdAt': createdAt.millisecondsSinceEpoch,
    };
  }
}

class HandymanService {
  final String id;
  final String handymanId;
  final String title;
  final String description;
  final String category;
  final double price;
  final String priceType; // 'fixed', 'hourly', 'per_unit'
  final List<String> workSamples; // URLs of work sample images
  final ServiceApprovalStatus approvalStatus;
  final DateTime createdAt;
  final DateTime? approvedAt;
  final String? adminNotes;
  final bool isActive;
  final Map<String, dynamic>? additionalDetails;

  HandymanService({
    required this.id,
    required this.handymanId,
    required this.title,
    required this.description,
    required this.category,
    required this.price,
    required this.priceType,
    required this.workSamples,
    required this.approvalStatus,
    required this.createdAt,
    this.approvedAt,
    this.adminNotes,
    required this.isActive,
    this.additionalDetails,
  });

  factory HandymanService.fromMap(Map<String, dynamic> map, String id) {
    return HandymanService(
      id: id,
      handymanId: map['handymanId'] ?? '',
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      category: map['category'] ?? '',
      price: (map['price'] ?? 0).toDouble(),
      priceType: map['priceType'] ?? 'fixed',
      workSamples: List<String>.from(map['workSamples'] ?? []),
      approvalStatus: ServiceApprovalStatus.values.firstWhere(
            (e) =>
        e
            .toString()
            .split('.')
            .last == (map['approvalStatus'] ?? 'pending'),
        orElse: () => ServiceApprovalStatus.pending,
      ),
      createdAt: _parseDateTime(map['createdAt']),
      approvedAt: map['approvedAt'] != null
          ? _parseDateTime(map['approvedAt'])
          : null,
      adminNotes: map['adminNotes'],
      isActive: map['isActive'] ?? true,
      additionalDetails: map['additionalDetails'],
    );
  }

  // Helper method to parse both Timestamp and int values
  static DateTime _parseDateTime(dynamic value) {
    if (value == null) return DateTime.now();

    if (value is Timestamp) {
      return value.toDate();
    } else if (value is int) {
      return DateTime.fromMillisecondsSinceEpoch(value);
    } else {
      return DateTime.now();
    }
  }

  Map<String, dynamic> toMap() {
    return {
      'handymanId': handymanId,
      'title': title,
      'description': description,
      'category': category,
      'price': price,
      'priceType': priceType,
      'workSamples': workSamples,
      'approvalStatus': approvalStatus
          .toString()
          .split('.')
          .last,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'approvedAt': approvedAt?.millisecondsSinceEpoch,
      'adminNotes': adminNotes,
      'isActive': isActive,
      'additionalDetails': additionalDetails,
    };
  }
}

enum ServiceApprovalStatus {
  pending,
  approved,
  rejected,
  revision_required
}
