import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';
import '../../models/app_models.dart';
import '../../services/auth_service.dart';

class CreateServiceScreen extends StatefulWidget {
  const CreateServiceScreen({super.key});

  @override
  State<CreateServiceScreen> createState() => _CreateServiceScreenState();
}

class _CreateServiceScreenState extends State<CreateServiceScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();

  String _selectedCategory = '';
  String _selectedPriceType = 'fixed';
  List<File> _selectedImages = [];
  List<String> _uploadedImageUrls = [];
  bool _isLoading = false;
  bool _isSubmitting = false;

  final AuthService _authService = AuthService();
  final ImagePicker _picker = ImagePicker();

  List<Map<String, dynamic>> _categories = [];
  bool _categoriesLoaded = false;

  final List<Map<String, String>> _priceTypes = [
    {'value': 'fixed', 'label': 'Fixed Price'},
    {'value': 'hourly', 'label': 'Per Hour'},
    {'value': 'per_unit', 'label': 'Per Unit/Item'},
  ];

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final categories = await _authService.getCategories();
      setState(() {
        _categories = categories;
        _categoriesLoaded = true;
      });
    } catch (e) {
      _showErrorSnackBar('Error loading categories: $e');
      // Fallback to default categories if loading fails
      setState(() {
        _categories = [
          {'id': '1', 'name': 'Plumbing', 'isActive': true},
          {'id': '2', 'name': 'Electrical', 'isActive': true},
          {'id': '3', 'name': 'Carpentry', 'isActive': true},
          {'id': '4', 'name': 'Painting', 'isActive': true},
          {'id': '5', 'name': 'Cleaning', 'isActive': true},
          {'id': '6', 'name': 'AC Repair', 'isActive': true},
          {'id': '7', 'name': 'Appliance Repair', 'isActive': true},
          {'id': '8', 'name': 'Gardening', 'isActive': true},
          {'id': '9', 'name': 'Tile Work', 'isActive': true},
          {'id': '10', 'name': 'General Maintenance', 'isActive': true},
        ];
        _categoriesLoaded = true;
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  Future<void> _pickImages() async {
    try {
      final List<XFile> images = await _picker.pickMultiImage(
        imageQuality: 80,
        maxWidth: 1024,
        maxHeight: 1024,
      );

      if (images.isNotEmpty) {
        setState(() {
          _selectedImages.addAll(
            images.take(5 - _selectedImages.length).map((xFile) =>
                File(xFile.path)),
          );
        });
      }
    } catch (e) {
      _showErrorSnackBar('Error picking images: $e');
    }
  }

  Future<void> _uploadImages() async {
    _uploadedImageUrls.clear();

    for (int i = 0; i < _selectedImages.length; i++) {
      try {
        final file = _selectedImages[i];
        final fileName = 'service_samples/${_authService
            .currentUserId}_${DateTime
            .now()
            .millisecondsSinceEpoch}_$i.jpg';
        final ref = FirebaseStorage.instance.ref().child(fileName);

        await ref.putFile(file);
        final downloadUrl = await ref.getDownloadURL();
        _uploadedImageUrls.add(downloadUrl);
      } catch (e) {
        print('Error uploading image $i: $e');
      }
    }
  }

  Future<void> _submitService() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedCategory.isEmpty) {
      _showErrorSnackBar('Please select a service category');
      return;
    }
    if (_selectedImages.isEmpty) {
      _showErrorSnackBar('Please add at least one work sample image');
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      // Upload images first
      await _uploadImages();

      // Create service document
      final service = HandymanService(
        id: '',
        handymanId: _authService.currentUserId!,
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        category: _selectedCategory,
        price: double.parse(_priceController.text.trim()),
        priceType: _selectedPriceType,
        workSamples: _uploadedImageUrls,
        approvalStatus: ServiceApprovalStatus.pending,
        createdAt: DateTime.now(),
        isActive: true,
      );

      await FirebaseFirestore.instance
          .collection('handyman_services')
          .add(service.toMap());

      _showSuccessSnackBar('Service submitted for approval!');
      Navigator.pop(context, true);
    } catch (e) {
      _showErrorSnackBar('Error creating service: $e');
    } finally {
      setState(() => _isSubmitting = false);
    }
  }

  void _removeImage(int index) {
    setState(() {
      _selectedImages.removeAt(index);
    });
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.green),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'Create New Service',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF2C3E50),
        elevation: 0,
        actions: [
          if (_isSubmitting)
            const Padding(
              padding: EdgeInsets.all(16),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
          else
            TextButton(
              onPressed: _categoriesLoaded ? _submitService : null,
              child: const Text(
                'Submit',
                style: TextStyle(
                  color: Color(0xFF4169E1),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
      body: _isLoading && !_categoriesLoaded
          ? const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: Color(0xFF4169E1)),
            SizedBox(height: 16),
            Text('Loading categories...'),
                ],
              ),
      )
          : Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionCard(
                'Service Details',
                'Provide information about your service',
                [
                  TextFormField(
                    controller: _titleController,
                          decoration: const InputDecoration(
                            labelText: 'Service Title *',
                            hintText: 'e.g., Professional Plumbing Installation',
                            border: OutlineInputBorder(),
                          ),
                          validator: (value) {
                            if (value == null || value
                                .trim()
                                .isEmpty) {
                              return 'Please enter a service title';
                            }
                            if (value
                                .trim()
                                .length < 10) {
                              return 'Title must be at least 10 characters';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),

                        DropdownButtonFormField<String>(
                          value: _selectedCategory.isEmpty
                              ? null
                              : _selectedCategory,
                          decoration: const InputDecoration(
                            labelText: 'Service Category *',
                            border: OutlineInputBorder(),
                          ),
                          items: _categories.map<DropdownMenuItem<String>>((
                              category) {
                            return DropdownMenuItem<String>(
                              value: category['name'] as String,
                              child: Text(category['name'] as String),
                            );
                          }).toList(),
                          onChanged: (value) {
                            setState(() {
                              _selectedCategory = value ?? '';
                            });
                          },
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please select a category';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),

                        TextFormField(
                          controller: _descriptionController,
                          decoration: const InputDecoration(
                            labelText: 'Service Description *',
                            hintText: 'Describe your service in detail...',
                            border: OutlineInputBorder(),
                          ),
                          maxLines: 4,
                          validator: (value) {
                            if (value == null || value
                                .trim()
                                .isEmpty) {
                              return 'Please enter a service description';
                            }
                            if (value
                                .trim()
                                .length < 50) {
                              return 'Description must be at least 50 characters';
                            }
                            return null;
                          },
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),

                    _buildSectionCard(
                      'Pricing',
                      'Set your service pricing',
                      [
                        Row(
                          children: [
                            Expanded(
                              flex: 2,
                              child: TextFormField(
                                controller: _priceController,
                                decoration: const InputDecoration(
                                  labelText: 'Price *',
                                  prefixText: 'OMR ',
                                  border: OutlineInputBorder(),
                                ),
                                keyboardType: TextInputType.number,
                                validator: (value) {
                                  if (value == null || value
                                      .trim()
                                      .isEmpty) {
                                    return 'Please enter a price';
                                  }
                                  final price = double.tryParse(value.trim());
                                  if (price == null || price <= 0) {
                                    return 'Please enter a valid price';
                                  }
                                  return null;
                                },
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              flex: 3,
                              child: DropdownButtonFormField<String>(
                                value: _selectedPriceType,
                                decoration: const InputDecoration(
                                  labelText: 'Price Type',
                                  border: OutlineInputBorder(),
                                ),
                                items: _priceTypes.map((type) {
                                  return DropdownMenuItem(
                                    value: type['value'],
                                    child: Text(type['label']!),
                                  );
                                }).toList(),
                                onChanged: (value) {
                                  setState(() {
                                    _selectedPriceType = value ?? 'fixed';
                                  });
                                },
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),

                    _buildSectionCard(
                      'Work Samples',
                      'Add photos of your previous work (max 5 images)',
                      [
                        if (_selectedImages.isNotEmpty) ...[
                          GridView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 3,
                              crossAxisSpacing: 8,
                              mainAxisSpacing: 8,
                            ),
                            itemCount: _selectedImages.length,
                            itemBuilder: (context, index) {
                              return Stack(
                                children: [
                                  Container(
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(8),
                                      image: DecorationImage(
                                        image: FileImage(
                                            _selectedImages[index]),
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                  ),
                                  Positioned(
                                    top: 4,
                                    right: 4,
                                    child: GestureDetector(
                                      onTap: () => _removeImage(index),
                                      child: Container(
                                        width: 24,
                                        height: 24,
                                        decoration: const BoxDecoration(
                                          color: Colors.red,
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(
                                          Icons.close,
                                          color: Colors.white,
                                          size: 16,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              );
                            },
                          ),
                          const SizedBox(height: 16),
                        ],

                        if (_selectedImages.length < 5)
                          OutlinedButton.icon(
                            onPressed: _pickImages,
                            icon: const Icon(Icons.add_photo_alternate),
                            label: Text(
                              _selectedImages.isEmpty
                                  ? 'Add Work Sample Photos'
                                  : 'Add More Photos',
                            ),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.all(16),
                              side: const BorderSide(color: Color(0xFF4169E1)),
                              foregroundColor: const Color(0xFF4169E1),
                            ),
                          ),

                        if (_selectedImages.isEmpty)
                          Container(
                            margin: const EdgeInsets.only(top: 12),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.orange.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: Colors.orange.withValues(alpha: 0.3),
                              ),
                            ),
                            child: const Row(
                              children: [
                                Icon(
                                  Icons.info_outline,
                                  color: Colors.orange,
                                  size: 20,
                                ),
                                SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'Adding work samples is required and helps customers trust your services.',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: Colors.orange,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),

                    const SizedBox(height: 30),

                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFF4169E1).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: const Color(0xFF4169E1).withValues(alpha: 0.2),
                        ),
                      ),
                      child: const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.approval,
                                color: Color(0xFF4169E1),
                                size: 24,
                              ),
                              SizedBox(width: 12),
                              Text(
                                'Approval Process',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF4169E1),
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Your service will be reviewed by our admin team before being shown to customers. This ensures quality and builds customer trust.',
                            style: TextStyle(
                              fontSize: 14,
                              color: Color(0xFF2C3E50),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildSectionCard(String title, String subtitle,
      List<Widget> children) {
    return Container(
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
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2C3E50),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 20),
                ...children,
              ],
            ),
          ),
        ],
      ),
    );
  }
}
