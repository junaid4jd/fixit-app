import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class CategoryManagementScreen extends StatefulWidget {
  const CategoryManagementScreen({super.key});

  @override
  State<CategoryManagementScreen> createState() =>
      _CategoryManagementScreenState();
}

class _CategoryManagementScreenState extends State<CategoryManagementScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'Service Categories',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF2C3E50),
        elevation: 0,
      ),
      body: _buildCategoriesList(),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddCategoryDialog(),
        backgroundColor: const Color(0xFF4169E1),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildCategoriesList() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('categories')
          .orderBy('order')
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
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.category, size: 80, color: Colors.grey),
                SizedBox(height: 16),
                Text('No categories found'),
                SizedBox(height: 8),
                Text('Add your first category using the + button'),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: snapshot.data!.docs.length,
          itemBuilder: (context, index) {
            return _buildCategoryCard(snapshot.data!.docs[index]);
          },
        );
      },
    );
  }

  Widget _buildCategoryCard(DocumentSnapshot categoryDoc) {
    Map<String, dynamic> category = categoryDoc.data() as Map<String, dynamic>;
    String categoryId = categoryDoc.id;

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
        child: Row(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: Color(
                    int.parse(category['color'].replaceAll('#', '0xFF')))
                    .withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                _getIconFromString(category['icon']),
                color: Color(
                    int.parse(category['color'].replaceAll('#', '0xFF'))),
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    category['name'],
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2C3E50),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Order: ${category['order']}',
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFF7F8C8D),
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: category['isActive'] == true
                    ? Colors.green.withValues(alpha: 0.1)
                    : Colors.red.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                category['isActive'] == true ? 'Active' : 'Inactive',
                style: TextStyle(
                  color: category['isActive'] == true ? Colors.green : Colors
                      .red,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            const SizedBox(width: 8),
            PopupMenuButton<String>(
              onSelected: (value) {
                switch (value) {
                  case 'edit':
                    _showEditCategoryDialog(categoryId, category);
                    break;
                  case 'toggle':
                    _toggleCategoryStatus(categoryId, category);
                    break;
                  case 'delete':
                    _deleteCategory(categoryId);
                    break;
                }
              },
              itemBuilder: (context) =>
              [
                const PopupMenuItem(
                  value: 'edit',
                  child: Text('Edit'),
                ),
                PopupMenuItem(
                  value: 'toggle',
                  child: Text(
                      category['isActive'] == true ? 'Deactivate' : 'Activate'),
                ),
                const PopupMenuItem(
                  value: 'delete',
                  child: Text('Delete', style: TextStyle(color: Colors.red)),
                ),
              ],
              child: const Icon(Icons.more_vert),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getIconFromString(String iconName) {
    switch (iconName.toLowerCase()) {
      case 'plumbing':
        return Icons.plumbing;
      case 'electrical':
      case 'electrical_services':
        return Icons.electrical_services;
      case 'painting':
      case 'format_paint':
        return Icons.format_paint;
      case 'cleaning':
      case 'cleaning_services':
        return Icons.cleaning_services;
      case 'carpentry':
      case 'handyman':
        return Icons.handyman;
      case 'hvac':
      case 'ac_unit':
        return Icons.ac_unit;
      case 'gardening':
      case 'yard':
        return Icons.yard;
      case 'moving':
      case 'local_shipping':
        return Icons.local_shipping;
      default:
        return Icons.build;
    }
  }

  void _showAddCategoryDialog() {
    final nameController = TextEditingController();
    final orderController = TextEditingController();
    String selectedIcon = 'build';
    String selectedColor = '#4169E1';

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Add Category'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: nameController,
                      decoration: const InputDecoration(
                        labelText: 'Category Name',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: orderController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Display Order',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Icon Selection
                    const Text('Select Icon:',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        'build',
                        'plumbing',
                        'electrical_services',
                        'format_paint',
                        'cleaning_services',
                        'handyman',
                        'ac_unit',
                        'yard',
                        'local_shipping'
                      ].map((icon) {
                        return GestureDetector(
                          onTap: () {
                            setState(() {
                              selectedIcon = icon;
                            });
                          },
                          child: Container(
                            width: 50,
                            height: 50,
                            decoration: BoxDecoration(
                              color: selectedIcon == icon
                                  ? const Color(0xFF4169E1).withValues(
                                  alpha: 0.1)
                                  : Colors.grey.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: selectedIcon == icon
                                    ? const Color(0xFF4169E1)
                                    : Colors.transparent,
                              ),
                            ),
                            child: Icon(
                              _getIconFromString(icon),
                              color: selectedIcon == icon
                                  ? const Color(0xFF4169E1)
                                  : Colors.grey,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 16),

                    // Color Selection
                    const Text('Select Color:',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        '#4169E1', '#3498DB', '#2ECC71', '#E67E22',
                        '#9B59B6', '#E74C3C', '#F39C12', '#1ABC9C'
                      ].map((color) {
                        return GestureDetector(
                          onTap: () {
                            setState(() {
                              selectedColor = color;
                            });
                          },
                          child: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: Color(
                                  int.parse(color.replaceAll('#', '0xFF'))),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: selectedColor == color
                                    ? Colors.black
                                    : Colors.transparent,
                                width: 2,
                              ),
                            ),
                            child: selectedColor == color
                                ? const Icon(Icons.check, color: Colors.white)
                                : null,
                          ),
                        );
                      }).toList(),
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
                    if (nameController.text.isNotEmpty &&
                        orderController.text.isNotEmpty) {
                      _addCategory(
                        nameController.text,
                        int.parse(orderController.text),
                        selectedIcon,
                        selectedColor,
                      );
                      Navigator.pop(context);
                    }
                  },
                  child: const Text('Add'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showEditCategoryDialog(String categoryId,
      Map<String, dynamic> category) {
    final nameController = TextEditingController(text: category['name']);
    final orderController = TextEditingController(
        text: category['order'].toString());
    String selectedIcon = category['icon'];
    String selectedColor = category['color'];

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Edit Category'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: nameController,
                      decoration: const InputDecoration(
                        labelText: 'Category Name',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: orderController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Display Order',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Icon Selection
                    const Text('Select Icon:',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        'build',
                        'plumbing',
                        'electrical_services',
                        'format_paint',
                        'cleaning_services',
                        'handyman',
                        'ac_unit',
                        'yard',
                        'local_shipping'
                      ].map((icon) {
                        return GestureDetector(
                          onTap: () {
                            setState(() {
                              selectedIcon = icon;
                            });
                          },
                          child: Container(
                            width: 50,
                            height: 50,
                            decoration: BoxDecoration(
                              color: selectedIcon == icon
                                  ? const Color(0xFF4169E1).withValues(
                                  alpha: 0.1)
                                  : Colors.grey.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: selectedIcon == icon
                                    ? const Color(0xFF4169E1)
                                    : Colors.transparent,
                              ),
                            ),
                            child: Icon(
                              _getIconFromString(icon),
                              color: selectedIcon == icon
                                  ? const Color(0xFF4169E1)
                                  : Colors.grey,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 16),

                    // Color Selection
                    const Text('Select Color:',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        '#4169E1', '#3498DB', '#2ECC71', '#E67E22',
                        '#9B59B6', '#E74C3C', '#F39C12', '#1ABC9C'
                      ].map((color) {
                        return GestureDetector(
                          onTap: () {
                            setState(() {
                              selectedColor = color;
                            });
                          },
                          child: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: Color(
                                  int.parse(color.replaceAll('#', '0xFF'))),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: selectedColor == color
                                    ? Colors.black
                                    : Colors.transparent,
                                width: 2,
                              ),
                            ),
                            child: selectedColor == color
                                ? const Icon(Icons.check, color: Colors.white)
                                : null,
                          ),
                        );
                      }).toList(),
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
                    if (nameController.text.isNotEmpty &&
                        orderController.text.isNotEmpty) {
                      _updateCategory(
                        categoryId,
                        nameController.text,
                        int.parse(orderController.text),
                        selectedIcon,
                        selectedColor,
                      );
                      Navigator.pop(context);
                    }
                  },
                  child: const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _addCategory(String name, int order, String icon, String color) {
    FirebaseFirestore.instance.collection('categories').add({
      'name': name,
      'order': order,
      'icon': icon,
      'color': color,
      'isActive': true,
      'createdAt': FieldValue.serverTimestamp(),
      'createdBy': 'admin', // Replace with current admin ID
    }).then((_) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Category added successfully')),
      );
    }).catchError((error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error adding category: $error')),
      );
    });
  }

  void _updateCategory(String categoryId, String name, int order, String icon,
      String color) {
    FirebaseFirestore.instance.collection('categories').doc(categoryId).update({
      'name': name,
      'order': order,
      'icon': icon,
      'color': color,
      'updatedAt': FieldValue.serverTimestamp(),
    }).then((_) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Category updated successfully')),
      );
    }).catchError((error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating category: $error')),
      );
    });
  }

  void _toggleCategoryStatus(String categoryId, Map<String, dynamic> category) {
    bool newStatus = !(category['isActive'] ?? false);

    FirebaseFirestore.instance.collection('categories').doc(categoryId).update({
      'isActive': newStatus,
      'updatedAt': FieldValue.serverTimestamp(),
    }).then((_) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Category ${newStatus
            ? 'activated'
            : 'deactivated'} successfully')),
      );
    }).catchError((error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating category: $error')),
      );
    });
  }

  void _deleteCategory(String categoryId) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete Category'),
          content: const Text(
              'Are you sure you want to delete this category? This action cannot be undone.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                FirebaseFirestore.instance.collection('categories').doc(
                    categoryId).delete().then((_) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('Category deleted successfully')),
                  );
                }).catchError((error) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error deleting category: $error')),
                  );
                });
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }
}