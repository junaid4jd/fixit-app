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
      color: Colors.white,
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Search Bar
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search customers...',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: Colors.grey[300]!),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: Colors.grey[300]!),
              ),
            ),
            onChanged: (value) {
              setState(() {
                _searchQuery = value;
              });
            },
          ),
          const SizedBox(height: 16),

          // Filter Options
          Row(
            children: [
              const Text(
                'Filter: ',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildFilterChip('All'),
                      _buildFilterChip('Active'),
                      _buildFilterChip('Inactive'),
                      _buildFilterChip('Suspended'),
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

  Widget _buildFilterChip(String filter) {
    final isSelected = _selectedFilter == filter;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(filter),
        selected: isSelected,
        onSelected: (selected) {
          setState(() {
            _selectedFilter = filter;
          });
        },
        backgroundColor: Colors.grey[200],
        selectedColor: const Color(0xFF4169E1).withValues(alpha: 0.1),
        checkmarkColor: const Color(0xFF4169E1),
      ),
    );
  }

  Widget _buildCustomersList() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .where('userType', isEqualTo: 'user')
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Text('Error: ${snapshot.error}'),
          );
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(
            child: Text('No customers found'),
          );
        }

        List<DocumentSnapshot> customers = snapshot.data!.docs;

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

  Widget _buildCustomerCard(DocumentSnapshot customerDoc) {
    Map<String, dynamic> customer = customerDoc.data() as Map<String, dynamic>;
    String customerId = customerDoc.id;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
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
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 25,
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
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        customer['fullName'] ?? 'Unknown',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2C3E50),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        customer['email'] ?? 'No email',
                        style: const TextStyle(
                          fontSize: 14,
                          color: Color(0xFF7F8C8D),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        customer['phoneNumber'] ?? 'No phone',
                        style: const TextStyle(
                          fontSize: 14,
                          color: Color(0xFF7F8C8D),
                        ),
                      ),
                    ],
                  ),
                ),
                _buildStatusChip(customer),
              ],
            ),
            const SizedBox(height: 12),

            // Customer Details
            Row(
              children: [
                _buildInfoItem(
                  icon: Icons.location_on,
                  label: 'City',
                  value: customer['city'] ?? 'Not set',
                ),
                const SizedBox(width: 16),
                _buildInfoItem(
                  icon: Icons.calendar_today,
                  label: 'Joined',
                  value: _formatDate(customer['createdAt']),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Action Buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  onPressed: () => _viewCustomerDetails(customerId, customer),
                  icon: const Icon(Icons.visibility, size: 16),
                  label: const Text('View'),
                  style: TextButton.styleFrom(
                    foregroundColor: const Color(0xFF4169E1),
                  ),
                ),
                const SizedBox(width: 8),
                TextButton.icon(
                  onPressed: () => _editCustomer(customerId, customer),
                  icon: const Icon(Icons.edit, size: 16),
                  label: const Text('Edit'),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.orange,
                  ),
                ),
                const SizedBox(width: 8),
                PopupMenuButton<String>(
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
                        child: Text('Suspend'),
                      ),
                    if (customer['isSuspended'] == true)
                      const PopupMenuItem(
                        value: 'activate',
                        child: Text('Activate'),
                      ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Text(
                          'Delete', style: TextStyle(color: Colors.red)),
                    ),
                  ],
                  child: const Icon(Icons.more_vert),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusChip(Map<String, dynamic> customer) {
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
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
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

  Widget _buildInfoItem({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        Icon(icon, size: 16, color: const Color(0xFF7F8C8D)),
        const SizedBox(width: 4),
        Text(
          '$label: ',
          style: const TextStyle(
            fontSize: 12,
            color: Color(0xFF7F8C8D),
            fontWeight: FontWeight.w500,
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 12,
            color: Color(0xFF2C3E50),
          ),
        ),
      ],
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
          title: Text(customer['fullName'] ?? 'Customer Details'),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildDetailRow('Email', customer['email'] ?? 'Not provided'),
                _buildDetailRow(
                    'Phone', customer['phoneNumber'] ?? 'Not provided'),
                _buildDetailRow('City', customer['city'] ?? 'Not set'),
                _buildDetailRow('Joined', _formatDate(customer['createdAt'])),
                _buildDetailRow('Status',
                    customer['isActive'] == true ? 'Active' : 'Inactive'),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
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