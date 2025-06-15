import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class CustomerManagementScreen extends StatefulWidget {
  const CustomerManagementScreen({super.key});

  @override
  State<CustomerManagementScreen> createState() =>
      _CustomerManagementScreenState();
}

class _CustomerManagementScreenState extends State<CustomerManagementScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedFilter = 'All';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'Customer Management',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF2C3E50),
        elevation: 0,
      ),
      body: Column(
        children: [
          _buildSearchAndFilter(),
          Expanded(
            child: _buildCustomersList(),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchAndFilter() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          // Search Bar
          Container(
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey[200]!),
            ),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search customers by name, email or phone...',
                hintStyle: TextStyle(color: Colors.grey[500]),
                prefixIcon: Icon(
                    Icons.search_outlined, color: Colors.grey[600]),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                  onPressed: () {
                    _searchController.clear();
                    setState(() {
                      _searchQuery = '';
                    });
                  },
                  icon: Icon(Icons.close, color: Colors.grey[600]),
                )
                    : null,
                border: InputBorder.none,
                contentPadding: const EdgeInsets.all(16),
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
            ),
          ),
          const SizedBox(height: 16),

          // Filter Options
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFF4169E1).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.filter_list_outlined,
                      size: 18,
                      color: Color(0xFF4169E1),
                    ),
                    SizedBox(width: 6),
                    Text(
                      'Filter:',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF4169E1),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildModernFilterChip('All', Icons.people_outline),
                      _buildModernFilterChip(
                          'Active', Icons.check_circle_outline),
                      _buildModernFilterChip(
                          'Inactive', Icons.pause_circle_outline),
                      _buildModernFilterChip('Suspended', Icons.block_outlined),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildModernFilterChip(String filter, IconData icon) {
    final isSelected = _selectedFilter == filter;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 16,
              color: isSelected ? Colors.white : const Color(0xFF4169E1),
            ),
            const SizedBox(width: 6),
            Text(
              filter,
              style: TextStyle(
                color: isSelected ? Colors.white : const Color(0xFF4169E1),
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
        selected: isSelected,
        onSelected: (selected) {
          setState(() {
            _selectedFilter = filter;
          });
        },
        backgroundColor: Colors.grey[200],
        selectedColor: const Color(0xFF4169E1),
        checkmarkColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  Widget _buildCustomersList() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .where('role', isEqualTo: 'user')
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
                const SizedBox(height: 16),
                Text('Error loading customers: ${snapshot.error}'),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    setState(() {}); // Refresh the stream
                  },
                  child: const Text('Retry'),
                ),
              ],
            ),
          );
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.people_outline, size: 64, color: Colors.grey[400]),
                const SizedBox(height: 16),
                const Text(
                  'No customers found',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF7F8C8D),
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Customers will appear here once users register',
                  style: TextStyle(
                    fontSize: 14,
                    color: Color(0xFF95A5A6),
                  ),
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: _createTestCustomers,
                  icon: const Icon(Icons.add_circle_outline),
                  label: const Text('Create Test Customers'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4169E1),
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          );
        }

        List<DocumentSnapshot> customers = snapshot.data!.docs;
        print('🔍 Found ${customers.length} customers in database');

        // Apply search filter
        if (_searchQuery.isNotEmpty) {
          customers = customers.where((doc) {
            Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
            String name = data['fullName']?.toLowerCase() ?? '';
            String email = data['email']?.toLowerCase() ?? '';
            String phone = data['phoneNumber']?.toLowerCase() ?? '';
            return name.contains(_searchQuery.toLowerCase()) ||
                email.contains(_searchQuery.toLowerCase()) ||
                phone.contains(_searchQuery.toLowerCase());
          }).toList();
        }

        // Apply status filter
        if (_selectedFilter != 'All') {
          customers = customers.where((doc) {
            Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
            switch (_selectedFilter) {
              case 'Active':
                return data['isActive'] == true;
              case 'Inactive':
                return data['isActive'] != true;
              case 'Suspended':
                return data['isSuspended'] == true;
              default:
                return true;
            }
          }).toList();
        }

        print('🔍 After filtering: ${customers.length} customers');

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: customers.length,
          itemBuilder: (context, index) {
            return _buildCustomerCard(customers[index]);
          },
        );
      },
    );
  }

  void _createTestCustomers() async {
    try {
      print('🔧 Creating test customers...');

      // Create test customers with proper role field
      final testCustomers = [
        {
          'fullName': 'Fatima Al-Zahra',
          'email': 'fatima.customer@example.com',
          'role': 'user',
          'isActive': true,
          'isVerified': true,
          'isSuspended': false,
          'createdAt': FieldValue.serverTimestamp(),
          'phoneNumber': '+968 9111 1111',
          'city': 'Muscat',
          'totalBookings': 3,
          'totalSpent': 45.500,
          'favoriteCategories': ['Plumbing', 'Electrical'],
        },
        {
          'fullName': 'Mohammed Al-Said',
          'email': 'mohammed.customer@example.com',
          'role': 'user',
          'isActive': true,
          'isVerified': true,
          'isSuspended': false,
          'createdAt': FieldValue.serverTimestamp(),
          'phoneNumber': '+968 9222 2222',
          'city': 'Muscat',
          'totalBookings': 1,
          'totalSpent': 25.000,
          'favoriteCategories': ['Carpentry'],
        },
        {
          'fullName': 'Aisha Al-Rashid',
          'email': 'aisha.customer@example.com',
          'role': 'user',
          'isActive': true,
          'isVerified': true,
          'isSuspended': false,
          'createdAt': FieldValue.serverTimestamp(),
          'phoneNumber': '+968 9333 3333',
          'city': 'Salalah',
          'totalBookings': 2,
          'totalSpent': 35.750,
          'favoriteCategories': ['AC Repair', 'Painting'],
        },
        {
          'fullName': 'Omar Al-Balushi',
          'email': 'omar.customer@example.com',
          'role': 'user',
          'isActive': false,
          'isVerified': true,
          'isSuspended': false,
          'createdAt': FieldValue.serverTimestamp(),
          'phoneNumber': '+968 9444 4444',
          'city': 'Nizwa',
          'totalBookings': 0,
          'totalSpent': 0.000,
          'favoriteCategories': [],
        },
        {
          'fullName': 'Mariam Al-Hinai',
          'email': 'mariam.customer@example.com',
          'role': 'user',
          'isActive': true,
          'isVerified': true,
          'isSuspended': true, // Suspended customer for testing
          'createdAt': FieldValue.serverTimestamp(),
          'phoneNumber': '+968 9555 5555',
          'city': 'Sohar',
          'totalBookings': 5,
          'totalSpent': 82.250,
          'favoriteCategories': ['Plumbing', 'Electrical', 'Carpentry'],
        }
      ];

      for (int i = 0; i < testCustomers.length; i++) {
        DocumentReference docRef = await FirebaseFirestore.instance
            .collection('users')
            .add(testCustomers[i]);
        print('✅ Created test customer ${i +
            1}: ${testCustomers[i]['fullName']} with ID: ${docRef.id}');

        // Immediately verify it was created
        DocumentSnapshot verifyDoc = await docRef.get();
        if (verifyDoc.exists) {
          var verifyData = verifyDoc.data() as Map<String, dynamic>;
          print(
              '✅ Verified customer creation: ${verifyData['fullName']} - role: ${verifyData['role']}');
        }
      }

      print('🎉 All test customers created successfully!');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Test customers created successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      print('❌ Error creating test customers: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Error creating test customers: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Widget _buildCustomerCard(DocumentSnapshot customerDoc) {
    Map<String, dynamic> customer = customerDoc.data() as Map<String, dynamic>;
    String customerId = customerDoc.id;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 20,
            offset: const Offset(0, 4),
            spreadRadius: 0,
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
            spreadRadius: 0,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Column(
          children: [
            // Header with gradient background
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    const Color(0xFF4169E1).withValues(alpha: 0.1),
                    const Color(0xFF667eea).withValues(alpha: 0.05),
                  ],
                ),
              ),
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  // Enhanced Avatar
                  Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white,
                        width: 3,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: CircleAvatar(
                      radius: 28,
                      backgroundColor: const Color(0xFF4169E1),
                      backgroundImage: customer['profileImage'] != null
                          ? NetworkImage(customer['profileImage'])
                          : null,
                      child: customer['profileImage'] == null
                          ? Text(
                        (customer['fullName'] ?? 'U')[0].toUpperCase(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 20,
                        ),
                      )
                          : null,
                    ),
                  ),
                  const SizedBox(width: 16),

                  // Customer Info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                customer['fullName'] ?? 'Unknown Customer',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF1a1a1a),
                                ),
                              ),
                            ),
                            _buildModernStatusChip(customer),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Icon(
                              Icons.email_outlined,
                              size: 16,
                              color: Colors.grey[600],
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                customer['email'] ?? 'No email',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[600],
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(
                              Icons.phone_outlined,
                              size: 16,
                              color: Colors.grey[600],
                            ),
                            const SizedBox(width: 6),
                            Text(
                              customer['phoneNumber'] ?? 'No phone',
                              style: TextStyle(
                                fontSize: 14,
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
            ),

            // Content Section
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  // Stats Row
                  Row(
                    children: [
                      Expanded(
                        child: _buildModernStatItem(
                          icon: Icons.location_on_outlined,
                          label: 'Location',
                          value: customer['city'] ?? 'Not set',
                          color: const Color(0xFF10B981),
                        ),
                      ),
                      Container(
                        width: 1,
                        height: 40,
                        color: Colors.grey[200],
                      ),
                      Expanded(
                        child: _buildModernStatItem(
                          icon: Icons.calendar_today_outlined,
                          label: 'Member Since',
                          value: _formatDate(customer['createdAt']),
                          color: const Color(0xFF8B5CF6),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Activity Stats
                  Row(
                    children: [
                      Expanded(
                        child: _buildModernStatItem(
                          icon: Icons.receipt_long_outlined,
                          label: 'Total Bookings',
                          value: '${customer['totalBookings'] ?? 0}',
                          color: const Color(0xFF3B82F6),
                        ),
                      ),
                      Container(
                        width: 1,
                        height: 40,
                        color: Colors.grey[200],
                      ),
                      Expanded(
                        child: _buildModernStatItem(
                          icon: Icons.attach_money_outlined,
                          label: 'Total Spent',
                          value: '${(customer['totalSpent'] ?? 0.0)
                              .toStringAsFixed(1)} OMR',
                          color: const Color(0xFFF59E0B),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // Action Buttons
                  Row(
                    children: [
                      Expanded(
                        child: _buildModernActionButton(
                          icon: Icons.visibility_outlined,
                          label: 'View Details',
                          color: const Color(0xFF6366F1),
                          onPressed: () =>
                              _viewCustomerDetails(customerId, customer),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildModernActionButton(
                          icon: Icons.edit_outlined,
                          label: 'Edit',
                          color: const Color(0xFF10B981),
                          onPressed: () => _editCustomer(customerId, customer),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Container(
                        height: 40,
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey[300]!),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: PopupMenuButton<String>(
                          onSelected: (value) {
                            switch (value) {
                              case 'suspend':
                                _suspendCustomer(customerId, customer);
                                break;
                              case 'activate':
                                _activateCustomer(customerId, customer);
                                break;
                              case 'delete':
                                _deleteCustomer(customerId);
                                break;
                            }
                          },
                          itemBuilder: (context) =>
                          [
                            if (customer['isSuspended'] != true)
                              const PopupMenuItem(
                                value: 'suspend',
                                child: Row(
                                  children: [
                                    Icon(Icons.block, size: 18,
                                        color: Colors.orange),
                                    SizedBox(width: 8),
                                    Text('Suspend'),
                                  ],
                                ),
                              ),
                            if (customer['isSuspended'] == true)
                              const PopupMenuItem(
                                value: 'activate',
                                child: Row(
                                  children: [
                                    Icon(Icons.check_circle, size: 18,
                                        color: Colors.green),
                                    SizedBox(width: 8),
                                    Text('Activate'),
                                  ],
                                ),
                              ),
                            const PopupMenuItem(
                              value: 'delete',
                              child: Row(
                                children: [
                                  Icon(Icons.delete_outline, size: 18,
                                      color: Colors.red),
                                  SizedBox(width: 8),
                                  Text('Delete',
                                      style: TextStyle(color: Colors.red)),
                                ],
                              ),
                            ),
                          ],
                          icon: Icon(
                            Icons.more_horiz,
                            color: Colors.grey[600],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModernStatusChip(Map<String, dynamic> customer) {
    Color color;
    String label;

    if (customer['isSuspended'] == true) {
      color = Colors.red;
      label = 'Suspended';
    } else if (customer['isActive'] == true) {
      color = Colors.green;
      label = 'Active';
    } else {
      color = Colors.orange;
      label = 'Inactive';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildModernStatItem({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF666666),
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF1a1a1a),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModernActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 16, color: Colors.white),
      label: Text(
        label,
        style: const TextStyle(fontSize: 12),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 10),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }

  String _formatDate(dynamic timestamp) {
    if (timestamp == null) return 'Unknown';

    DateTime date;
    if (timestamp is Timestamp) {
      date = timestamp.toDate();
    } else {
      return 'Unknown';
    }

    return '${date.day}/${date.month}/${date.year}';
  }

  void _viewCustomerDetails(String customerId, Map<String, dynamic> customer) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: const Color(0xFF4169E1),
                backgroundImage: customer['profileImage'] != null
                    ? NetworkImage(customer['profileImage'])
                    : null,
                child: customer['profileImage'] == null
                    ? Text(
                  (customer['fullName'] ?? 'U')[0].toUpperCase(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                )
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  customer['fullName'] ?? 'Customer Details',
                  style: const TextStyle(fontSize: 18),
                ),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Contact Information',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2C3E50),
                  ),
                ),
                const SizedBox(height: 8),
                _buildDetailRow('Email', customer['email'] ?? 'Not provided'),
                _buildDetailRow(
                    'Phone', customer['phoneNumber'] ?? 'Not provided'),
                _buildDetailRow('City', customer['city'] ?? 'Not set'),

                const SizedBox(height: 16),
                const Text(
                  'Account Information',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2C3E50),
                  ),
                ),
                const SizedBox(height: 8),
                _buildDetailRow('Joined', _formatDate(customer['createdAt'])),
                _buildDetailRow('Status',
                    customer['isActive'] == true ? 'Active' : 'Inactive'),
                _buildDetailRow(
                    'Verified', customer['isVerified'] == true ? 'Yes' : 'No'),
                _buildDetailRow('Suspended',
                    customer['isSuspended'] == true ? 'Yes' : 'No'),

                const SizedBox(height: 16),
                const Text(
                  'Activity Summary',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2C3E50),
                  ),
                ),
                const SizedBox(height: 8),
                _buildDetailRow(
                    'Total Bookings', '${customer['totalBookings'] ?? 0}'),
                _buildDetailRow('Total Spent',
                    '${(customer['totalSpent'] ?? 0.0).toStringAsFixed(
                        3)} OMR'),

                if (customer['favoriteCategories'] != null &&
                    customer['favoriteCategories'].isNotEmpty)
                  _buildDetailRow(
                      'Favorite Categories',
                      (customer['favoriteCategories'] as List).join(', ')
                  ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
            if (customer['isSuspended'] == true)
              ElevatedButton(
                onPressed: () {
                  _activateCustomer(customerId, customer);
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                child: const Text('Activate'),
              )
            else
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  _editCustomer(customerId, customer);
                },
                child: const Text('Edit'),
              ),
          ],
        );
      },
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                color: Color(0xFF7F8C8D),
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: Color(0xFF2C3E50),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _editCustomer(String customerId, Map<String, dynamic> customer) {
    // Show edit dialog
    showDialog(
      context: context,
      builder: (BuildContext context) {
        final nameController = TextEditingController(
            text: customer['fullName']);
        final phoneController = TextEditingController(
            text: customer['phoneNumber']);
        final cityController = TextEditingController(text: customer['city']);

        return AlertDialog(
          title: const Text('Edit Customer'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Full Name',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: phoneController,
                  decoration: const InputDecoration(
                    labelText: 'Phone Number',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: cityController,
                  decoration: const InputDecoration(
                    labelText: 'City',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                _updateCustomer(customerId, {
                  'fullName': nameController.text,
                  'phoneNumber': phoneController.text,
                  'city': cityController.text,
                });
                Navigator.pop(context);
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  void _suspendCustomer(String customerId, Map<String, dynamic> customer) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Suspend Customer'),
          content: Text(
              'Are you sure you want to suspend ${customer['fullName']}?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                _updateCustomer(customerId, {'isSuspended': true});
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('Suspend'),
            ),
          ],
        );
      },
    );
  }

  void _activateCustomer(String customerId, Map<String, dynamic> customer) {
    _updateCustomer(customerId, {'isSuspended': false, 'isActive': true});
  }

  void _deleteCustomer(String customerId) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete Customer'),
          content: const Text(
              'Are you sure you want to delete this customer? This action cannot be undone.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                FirebaseFirestore.instance
                    .collection('users')
                    .doc(customerId)
                    .delete();
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text('Customer deleted successfully')),
                );
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }

  void _updateCustomer(String customerId, Map<String, dynamic> updates) {
    FirebaseFirestore.instance
        .collection('users')
        .doc(customerId)
        .update(updates)
        .then((_) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Customer updated successfully')),
      );
    }).catchError((error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating customer: $error')),
      );
    });
  }
}
