import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class CitiesManagementScreen extends StatefulWidget {
  const CitiesManagementScreen({super.key});

  @override
  State<CitiesManagementScreen> createState() => _CitiesManagementScreenState();
}

class _CitiesManagementScreenState extends State<CitiesManagementScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final TextEditingController _cityNameController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();

  List<Map<String, dynamic>> _cities = [];
  List<Map<String, dynamic>> _filteredCities = [];
  bool _isLoading = true;
  bool _isAdding = false;

  @override
  void initState() {
    super.initState();
    _loadCities();
  }

  @override
  void dispose() {
    _cityNameController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadCities() async {
    setState(() => _isLoading = true);

    try {
      final querySnapshot = await _firestore
          .collection('cities')
          .orderBy('order')
          .get();

      final cities = querySnapshot.docs.map((doc) =>
      {
        'id': doc.id,
        ...doc.data(),
      }).toList();

      if (mounted) {
        setState(() {
          _cities = cities;
          _filteredCities = cities;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        _showErrorSnackBar('Error loading cities: $e');
      }
    }
  }

  Future<void> _addDefaultCities() async {
    final defaultCities = [
      'Muscat',
      'Salalah',
      'Nizwa',
      'Sur',
      'Sohar',
      'Rustaq',
      'Ibri',
      'Buraimi'
    ];

    setState(() => _isAdding = true);

    try {
      for (int i = 0; i < defaultCities.length; i++) {
        final cityName = defaultCities[i];

        // Check if city already exists
        final exists = _cities.any((city) =>
        city['name'].toString().toLowerCase() == cityName.toLowerCase());

        if (!exists) {
          await _firestore.collection('cities').add({
            'name': cityName,
            'isActive': true,
            'order': i + 1,
            'createdAt': FieldValue.serverTimestamp(),
            'updatedAt': FieldValue.serverTimestamp(),
          });
        }
      }

      _loadCities();
      _showSuccessSnackBar('Default cities added successfully!');
    } catch (e) {
      _showErrorSnackBar('Error adding default cities: $e');
    } finally {
      setState(() => _isAdding = false);
    }
  }

  Future<void> _testConnection() async {
    try {
      final snapshot = await _firestore.collection('cities').limit(1).get();
      if (snapshot.docs.isNotEmpty) {
        _showSuccessSnackBar('Successfully connected to cities collection!');
      } else {
        _showSuccessSnackBar(
            'Connected to Firebase, but cities collection is empty.');
      }
    } catch (e) {
      _showErrorSnackBar('Failed to connect to Firebase: $e');
    }
  }

  void _filterCities(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredCities = _cities;
      } else {
        _filteredCities = _cities.where((city) {
          final name = city['name'].toString().toLowerCase();
          return name.contains(query.toLowerCase());
        }).toList();
      }
    });
  }

  Future<void> _addCity() async {
    final cityName = _cityNameController.text.trim();
    if (cityName.isEmpty) {
      _showErrorSnackBar('Please enter a city name');
      return;
    }

    // Check if city already exists
    final exists = _cities.any((city) =>
    city['name'].toString().toLowerCase() == cityName.toLowerCase());
    if (exists) {
      _showErrorSnackBar('City already exists');
      return;
    }

    setState(() => _isAdding = true);

    try {
      final newOrder = _cities.length + 1;
      await _firestore.collection('cities').add({
        'name': cityName,
        'isActive': true,
        'order': newOrder,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      _cityNameController.clear();
      _loadCities();
      _showSuccessSnackBar('City added successfully!');
    } catch (e) {
      _showErrorSnackBar('Error adding city: $e');
    } finally {
      setState(() => _isAdding = false);
    }
  }

  Future<void> _toggleCityStatus(String cityId, bool isActive) async {
    try {
      await _firestore.collection('cities').doc(cityId).update({
        'isActive': !isActive,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      _loadCities();
      _showSuccessSnackBar(
          'City ${!isActive ? 'activated' : 'deactivated'} successfully!');
    } catch (e) {
      _showErrorSnackBar('Error updating city: $e');
    }
  }

  Future<void> _deleteCity(String cityId, String cityName) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) =>
          AlertDialog(
            title: const Text('Delete City'),
            content: Text('Are you sure you want to delete "$cityName"?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                style: TextButton.styleFrom(foregroundColor: Colors.red),
                child: const Text('Delete'),
              ),
            ],
          ),
    );

    if (confirm == true) {
      try {
        await _firestore.collection('cities').doc(cityId).delete();
        _loadCities();
        _showSuccessSnackBar('City deleted successfully!');
      } catch (e) {
        _showErrorSnackBar('Error deleting city: $e');
      }
    }
  }

  void _showEditDialog(Map<String, dynamic> city) {
    final controller = TextEditingController(text: city['name']);

    showDialog(
      context: context,
      builder: (context) =>
          AlertDialog(
            title: const Text('Edit City'),
            content: TextField(
              controller: controller,
              decoration: const InputDecoration(
                labelText: 'City Name',
                border: OutlineInputBorder(),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () async {
                  final newName = controller.text.trim();
                  if (newName.isNotEmpty && newName != city['name']) {
                    try {
                      await _firestore
                          .collection('cities')
                          .doc(city['id'])
                          .update({
                        'name': newName,
                        'updatedAt': FieldValue.serverTimestamp(),
                      });

                      Navigator.pop(context);
                      _loadCities();
                      _showSuccessSnackBar('City updated successfully!');
                    } catch (e) {
                      _showErrorSnackBar('Error updating city: $e');
                    }
                  } else {
                    Navigator.pop(context);
                  }
                },
                child: const Text('Save'),
              ),
            ],
          ),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Cities Management',
          style: TextStyle(
            color: Color(0xFF2C3E50),
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF2C3E50)),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          // Add City Section
          Container(
            color: Colors.white,
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Add New City',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2C3E50),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _cityNameController,
                        decoration: InputDecoration(
                          hintText: 'Enter city name (e.g., Muscat, Salalah)',
                          prefixIcon: const Icon(Icons.location_city),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          filled: true,
                          fillColor: Colors.grey[50],
                        ),
                        onSubmitted: (_) => _addCity(),
                      ),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton(
                      onPressed: _isAdding ? null : _addCity,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF4169E1),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: _isAdding
                          ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                          : const Text(
                        'Add City',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Add Default Cities Button
          Container(
            color: Colors.white,
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Quick Setup',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2C3E50),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _isAdding ? null : _addDefaultCities,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF4169E1),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: _isAdding
                            ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                            : const Text(
                          'Add Default Cities',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton(
                      onPressed: _testConnection,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Test Connection',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Search Section
          Container(
            color: Colors.white,
            padding: const EdgeInsets.only(left: 20, right: 20, bottom: 20),
            child: TextField(
              controller: _searchController,
              onChanged: _filterCities,
              decoration: InputDecoration(
                hintText: 'Search cities...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Colors.grey[50],
              ),
            ),
          ),

          // Cities List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredCities.isEmpty
                ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.location_city,
                    size: 64,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _searchController.text.isNotEmpty
                        ? 'No cities found'
                        : 'No cities added yet',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _searchController.text.isNotEmpty
                        ? 'Try a different search term'
                        : 'Add your first city using the form above',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[500],
                    ),
                  ),
                ],
              ),
            )
                : ListView.builder(
              padding: const EdgeInsets.all(20),
              itemCount: _filteredCities.length,
              itemBuilder: (context, index) {
                final city = _filteredCities[index];
                return _buildCityCard(city);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCityCard(Map<String, dynamic> city) {
    final isActive = city['isActive'] ?? true;

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
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: isActive
                ? const Color(0xFF4169E1).withValues(alpha: 0.1)
                : Colors.grey.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            Icons.location_city,
            color: isActive ? const Color(0xFF4169E1) : Colors.grey,
            size: 24,
          ),
        ),
        title: Text(
          city['name'],
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: isActive ? const Color(0xFF2C3E50) : Colors.grey,
          ),
        ),
        subtitle: Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: isActive
                    ? Colors.green.withValues(alpha: 0.1)
                    : Colors.red.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                isActive ? 'Active' : 'Inactive',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: isActive ? Colors.green : Colors.red,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              'Order: ${city['order'] ?? 0}',
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF7F8C8D),
              ),
            ),
          ],
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (value) {
            switch (value) {
              case 'edit':
                _showEditDialog(city);
                break;
              case 'toggle':
                _toggleCityStatus(city['id'], isActive);
                break;
              case 'delete':
                _deleteCity(city['id'], city['name']);
                break;
            }
          },
          itemBuilder: (context) =>
          [
            const PopupMenuItem(
              value: 'edit',
              child: Row(
                children: [
                  Icon(Icons.edit, size: 18),
                  SizedBox(width: 8),
                  Text('Edit'),
                ],
              ),
            ),
            PopupMenuItem(
              value: 'toggle',
              child: Row(
                children: [
                  Icon(
                    isActive ? Icons.visibility_off : Icons.visibility,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Text(isActive ? 'Deactivate' : 'Activate'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'delete',
              child: Row(
                children: [
                  Icon(Icons.delete, size: 18, color: Colors.red),
                  SizedBox(width: 8),
                  Text('Delete', style: TextStyle(color: Colors.red)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
