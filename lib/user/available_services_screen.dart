import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/app_models.dart';
import 'booking_screen.dart';

class AvailableServicesScreen extends StatefulWidget {
  final String? initialCategory;

  const AvailableServicesScreen({super.key, this.initialCategory});

  @override
  State<AvailableServicesScreen> createState() =>
      _AvailableServicesScreenState();
}

class _AvailableServicesScreenState extends State<AvailableServicesScreen> {
  String _selectedCategory = 'All';
  String _sortBy = 'price_low_to_high';
  List<String> _categories = ['All'];

  @override
  void initState() {
    super.initState();
    if (widget.initialCategory != null && widget.initialCategory!.isNotEmpty) {
      _selectedCategory = widget.initialCategory!;
    }
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('categories')
          .get();

      final categories = ['All'];
      for (var doc in snapshot.docs) {
        categories.add(doc['name'] as String);
      }

      setState(() {
        _categories = categories;
      });
    } catch (e) {
      // If categories collection doesn't exist, use default categories
      setState(() {
        _categories = [
          'All',
          'Plumbing',
          'Electrical',
          'Carpentry',
          'Painting',
          'Cleaning',
          'AC Repair',
          'Appliance Repair',
          'Gardening',
          'Tile Work',
          'General Maintenance',
        ];
      });
    }
  }

  final List<Map<String, String>> _sortOptions = [
    {'value': 'price_low_to_high', 'label': 'Price: Low to High'},
    {'value': 'price_high_to_low', 'label': 'Price: High to Low'},
    {'value': 'newest', 'label': 'Newest First'},
    {'value': 'rating', 'label': 'Highest Rated'},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'Available Services',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF2C3E50),
        elevation: 0,
        actions: [
          IconButton(
            onPressed: _showFilterBottomSheet,
            icon: const Icon(Icons.filter_list),
            tooltip: 'Filter & Sort',
          ),
        ],
      ),
      body: Column(
        children: [
          // Filter Bar
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: Row(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: _categories.map((category) {
                        final isSelected = _selectedCategory == category;
                        return Container(
                          margin: const EdgeInsets.only(right: 8),
                          child: FilterChip(
                            label: Text(category),
                            selected: isSelected,
                            onSelected: (selected) {
                              setState(() {
                                _selectedCategory = category;
                              });
                            },
                            backgroundColor: Colors.grey[100],
                            selectedColor: const Color(0xFF4169E1).withValues(
                                alpha: 0.2),
                            checkmarkColor: const Color(0xFF4169E1),
                            labelStyle: TextStyle(
                              color: isSelected
                                  ? const Color(0xFF4169E1)
                                  : Colors.grey[700],
                              fontWeight: isSelected
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  _getSortLabel(),
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),

          // Services List
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _getServicesStream(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error, size: 64, color: Colors.red),
                        const SizedBox(height: 16),
                        Text('Error loading services: ${snapshot.error}'),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () => setState(() {}),
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  );
                }

                List<QueryDocumentSnapshot> services = snapshot.data?.docs ??
                    [];

                // Filter by category
                if (_selectedCategory != 'All') {
                  services = services.where((doc) {
                    final service = HandymanService.fromMap(
                      doc.data() as Map<String, dynamic>,
                      doc.id,
                    );
                    return service.category.toLowerCase() ==
                        _selectedCategory.toLowerCase();
                  }).toList();
                }

                // Sort services
                services = _sortServices(services);

                if (services.isEmpty) {
                  return _buildEmptyState();
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(20),
                  itemCount: services.length,
                  itemBuilder: (context, index) {
                    final doc = services[index];
                    final service = HandymanService.fromMap(
                      doc.data() as Map<String, dynamic>,
                      doc.id,
                    );
                    return _buildServiceCard(service);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Stream<QuerySnapshot> _getServicesStream() {
    return FirebaseFirestore.instance
        .collection('handyman_services')
        .where('approvalStatus', isEqualTo: 'approved')
        .where('isActive', isEqualTo: true)
        .snapshots();
  }

  List<QueryDocumentSnapshot> _sortServices(
      List<QueryDocumentSnapshot> services) {
    switch (_sortBy) {
      case 'price_low_to_high':
        services.sort((a, b) {
          final aService = HandymanService.fromMap(
              a.data() as Map<String, dynamic>, a.id);
          final bService = HandymanService.fromMap(
              b.data() as Map<String, dynamic>, b.id);
          return aService.price.compareTo(bService.price);
        });
        break;
      case 'price_high_to_low':
        services.sort((a, b) {
          final aService = HandymanService.fromMap(
              a.data() as Map<String, dynamic>, a.id);
          final bService = HandymanService.fromMap(
              b.data() as Map<String, dynamic>, b.id);
          return bService.price.compareTo(aService.price);
        });
        break;
      case 'newest':
        services.sort((a, b) {
          final aService = HandymanService.fromMap(
              a.data() as Map<String, dynamic>, a.id);
          final bService = HandymanService.fromMap(
              b.data() as Map<String, dynamic>, b.id);
          return bService.createdAt.compareTo(aService.createdAt);
        });
        break;
    // Add rating sort when handyman ratings are available
    }
    return services;
  }

  String _getSortLabel() {
    return _sortOptions.firstWhere((option) =>
    option['value'] == _sortBy)['label']!;
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: Colors.grey.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.search_off,
              size: 60,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            _selectedCategory == 'All'
                ? 'No Services Available'
                : 'No Services in $_selectedCategory',
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2C3E50),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _selectedCategory == 'All'
                ? 'Handymen haven\'t created any services yet'
                : 'Try selecting a different category',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildServiceCard(HandymanService service) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
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
          // Service images
          if (service.workSamples.isNotEmpty)
            Container(
              height: 200,
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(12),
                  topRight: Radius.circular(12),
                ),
                image: DecorationImage(
                  image: NetworkImage(service.workSamples.first),
                  fit: BoxFit.cover,
                ),
              ),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(12),
                    topRight: Radius.circular(12),
                  ),
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.3),
                    ],
                  ),
                ),
                child: Stack(
                  children: [
                    Positioned(
                      top: 12,
                      right: 12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFF4169E1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          service.category,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.white,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                    if (service.workSamples.length > 1)
                      Positioned(
                        bottom: 12,
                        right: 12,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.7),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                  Icons.photo_library, color: Colors.white,
                                  size: 16),
                              const SizedBox(width: 4),
                              Text(
                                '${service.workSamples.length}',
                                style: const TextStyle(
                                    color: Colors.white, fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),

          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Price and title
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            service.title,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF2C3E50),
                            ),
                          ),
                          const SizedBox(height: 4),
                          if (service.workSamples.isEmpty)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: const Color(0xFF4169E1).withValues(
                                    alpha: 0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                service.category,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFF4169E1),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          'OMR ${service.price.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF4169E1),
                          ),
                        ),
                        Text(
                          _getPriceTypeText(service.priceType),
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // Description
                Text(
                  service.description,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[700],
                    height: 1.4,
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),

                const SizedBox(height: 16),

                // Handyman info
                FutureBuilder<DocumentSnapshot>(
                  future: FirebaseFirestore.instance
                      .collection('service_providers')
                      .doc(service.handymanId)
                      .get(),
                  builder: (context, snapshot) {
                    if (snapshot.hasData && snapshot.data!.exists) {
                      final handyman = ServiceProvider.fromMap(
                        snapshot.data!.data() as Map<String, dynamic>,
                        snapshot.data!.id,
                      );
                      return Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.grey.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 20,
                              backgroundImage: handyman.profileImageUrl != null
                                  ? NetworkImage(handyman.profileImageUrl!)
                                  : null,
                              child: handyman.profileImageUrl == null
                                  ? Text(
                                  handyman.name.substring(0, 1).toUpperCase())
                                  : null,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    handyman.name,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF2C3E50),
                                    ),
                                  ),
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.star,
                                        size: 16,
                                        color: Colors.amber[700],
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        '${handyman.rating.toStringAsFixed(
                                            1)} • ${handyman
                                            .experienceYears} years exp',
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
                            ElevatedButton(
                              onPressed: () =>
                                  _navigateToBookingScreen(service, handyman),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF4169E1),
                                foregroundColor: Colors.white,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              child: const Text('Book Now'),
                            ),
                          ],
                        ),
                      );
                    }
                    return Container(
                      height: 64,
                      decoration: BoxDecoration(
                        color: Colors.grey.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Center(
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    );
                  },
                ),

                // Additional work samples
                if (service.workSamples.length > 1) ...[
                  const SizedBox(height: 16),
                  const Text(
                    'Work Samples:',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2C3E50),
                    ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 60,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: service.workSamples.length,
                      itemBuilder: (context, index) {
                        return GestureDetector(
                          onTap: () =>
                              _showImageDialog(service.workSamples[index]),
                          child: Container(
                            margin: const EdgeInsets.only(right: 8),
                            width: 60,
                            height: 60,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8),
                              image: DecorationImage(
                                image: NetworkImage(service.workSamples[index]),
                                fit: BoxFit.cover,
                              ),
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
        ],
      ),
    );
  }

  String _getPriceTypeText(String priceType) {
    switch (priceType) {
      case 'hourly':
        return 'per hour';
      case 'per_unit':
        return 'per unit';
      default:
        return 'fixed price';
    }
  }

  void _showImageDialog(String imageUrl) {
    showDialog(
      context: context,
      builder: (context) =>
          Dialog(
            child: Container(
              constraints: const BoxConstraints(maxHeight: 400),
              child: Image.network(
                imageUrl,
                fit: BoxFit.contain,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return const Center(child: CircularProgressIndicator());
                },
                errorBuilder: (context, error, stackTrace) {
                  return const Center(
                    child: Icon(Icons.error, size: 64, color: Colors.red),
                  );
                },
              ),
            ),
          ),
    );
  }

  void _showFilterBottomSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      builder: (context) =>
          Container(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Sort By',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2C3E50),
                  ),
                ),
                const SizedBox(height: 16),
                ...(_sortOptions.map((option) {
                  return RadioListTile<String>(
                    value: option['value']!,
                    groupValue: _sortBy,
                    onChanged: (value) {
                      setState(() {
                        _sortBy = value!;
                      });
                      Navigator.pop(context);
                    },
                    title: Text(option['label']!),
                    activeColor: const Color(0xFF4169E1),
                  );
                }).toList()),
              ],
            ),
          ),
    );
  }

  void _navigateToBookingScreen(HandymanService service,
      ServiceProvider handyman) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            BookingScreen(
              service: service,
              serviceProvider: handyman,
            ),
      ),
    );
  }
}
