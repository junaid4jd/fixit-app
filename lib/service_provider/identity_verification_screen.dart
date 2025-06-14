import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';
import '../services/auth_service.dart';
import 'service_provider_home_screen.dart';

class IdentityVerificationScreen extends StatefulWidget {
  const IdentityVerificationScreen({super.key});

  @override
  State<IdentityVerificationScreen> createState() =>
      _IdentityVerificationScreenState();
}

class _IdentityVerificationScreenState
    extends State<IdentityVerificationScreen> {
  final TextEditingController _civilIdController = TextEditingController();
  final TextEditingController _fullNameController = TextEditingController();
  final TextEditingController _dobController = TextEditingController();

  bool _confirmAccuracy = false;
  bool _isLoading = false;
  bool _isUploading = false; // Separate flag for upload state
  final List<String> _uploadedFiles = [];
  final List<String> _uploadedFileUrls = []; // Store actual download URLs
  final List<UploadTask> _activeUploadTasks = []; // Track active uploads

  final AuthService _authService = AuthService();

  @override
  void dispose() {
    // Cancel any active uploads when disposing
    _cancelActiveUploads();
    _civilIdController.dispose();
    _fullNameController.dispose();
    _dobController.dispose();
    super.dispose();
  }

  void _cancelActiveUploads() {
    for (var task in _activeUploadTasks) {
      try {
        task.cancel();
      } catch (e) {
        // Ignore cancellation errors during dispose
      }
    }
    _activeUploadTasks.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Verify Identity',
          style: TextStyle(
            color: Color(0xFF2C3E50),
            fontWeight: FontWeight.w600,
            fontSize: 20,
          ),
        ),
        centerTitle: false,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),

              // ID Card Icon
              Center(
                child: Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    color: const Color(0xFF4169E1).withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.badge_outlined,
                    size: 60,
                    color: Color(0xFF4169E1),
                  ),
                ),
              ),

              const SizedBox(height: 40),

              // Sample Omani ID Card Info
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8F9FA),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE9ECEF)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.info_outline,
                          color: Color(0xFF4169E1),
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'Omani Civil ID Sample',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF2C3E50),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Civil ID Number: 12345678 (8 digits)\nExample: Ahmed bin Salem Al-Rashid\nDate Format: DD/MM/YYYY',
                      style: TextStyle(
                        fontSize: 14,
                        color: Color(0xFF6C757D),
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 30),

              // Civil ID Number field
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Civil ID Number',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF2C3E50),
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _civilIdController,
                    keyboardType: TextInputType.number,
                    enabled: !_isLoading,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(8),
                    ],
                    decoration: InputDecoration(
                      hintText: 'Enter your Civil ID',
                      hintStyle: const TextStyle(color: Color(0xFFBDC3C7)),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey[300]!),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey[300]!),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFF4169E1)),
                      ),
                      disabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey[200]!),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // Full Name field
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Full Name (As per ID)',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF2C3E50),
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _fullNameController,
                    keyboardType: TextInputType.name,
                    enabled: !_isLoading,
                    decoration: InputDecoration(
                      hintText: 'Enter your full name',
                      hintStyle: const TextStyle(color: Color(0xFFBDC3C7)),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey[300]!),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey[300]!),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFF4169E1)),
                      ),
                      disabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey[200]!),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // Date of Birth field
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Date of Birth',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF2C3E50),
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _dobController,
                    readOnly: true,
                    enabled: !_isLoading,
                    onTap: () => _selectDate(context),
                    decoration: InputDecoration(
                      hintText: 'mm/dd/yyyy',
                      hintStyle: const TextStyle(color: Color(0xFFBDC3C7)),
                      suffixIcon: const Icon(
                        Icons.calendar_today,
                        color: Color(0xFFBDC3C7),
                      ),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey[300]!),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey[300]!),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFF4169E1)),
                      ),
                      disabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey[200]!),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 30),

              // Upload section
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  border: Border.all(
                    color: const Color(0xFF4169E1),
                    style: BorderStyle.solid,
                    width: 2,
                  ),
                  borderRadius: BorderRadius.circular(12),
                  color: const Color(0xFF4169E1).withValues(alpha: 0.02),
                ),
                child: Column(
                  children: [
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        color: const Color(0xFF4169E1).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: const Icon(
                        Icons.cloud_upload_outlined,
                        color: Color(0xFF4169E1),
                        size: 30,
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Upload Civil ID (Front & Back)',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF2C3E50),
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Take photos or select from gallery (JPG, PNG)',
                      style: TextStyle(
                        fontSize: 14,
                        color: Color(0xFF7F8C8D),
                      ),
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        onPressed: _isLoading ? null : _chooseImages,
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Color(0xFF4169E1)),
                          foregroundColor: const Color(0xFF4169E1),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text(
                          'Select Images',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Show uploaded files
              if (_uploadedFiles.isNotEmpty) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.green.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                        color: Colors.green.withValues(alpha: 0.3)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.check_circle, color: Colors.green,
                              size: 20),
                          SizedBox(width: 8),
                          Text(
                            'Files Uploaded:',
                            style: TextStyle(
                              fontWeight: FontWeight.w500,
                              color: Colors.green,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      ..._uploadedFiles.map((file) =>
                          Text(
                            '• $file',
                            style: const TextStyle(color: Colors.green),
                          )),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 30),

              // Confirmation checkbox
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Checkbox(
                    value: _confirmAccuracy,
                    onChanged: _isLoading ? null : (value) {
                      setState(() {
                        _confirmAccuracy = value ?? false;
                      });
                    },
                    activeColor: const Color(0xFF4169E1),
                  ),
                  const Expanded(
                    child: Text(
                      'I confirm that all the information provided is accurate and matches my official documents.',
                      style: TextStyle(
                        fontSize: 14,
                        color: Color(0xFF7F8C8D),
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 30),

              // Submit button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: (_isFormValid() && !_isLoading && !_isUploading)
                      ? _submitVerification
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4169E1),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 2,
                    disabledBackgroundColor: Colors.grey[300],
                  ),
                  child: _isLoading || _isUploading
                      ? Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white),
                          strokeWidth: 2,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(_isUploading ? 'Uploading...' : 'Submitting...'),
                    ],
                  )
                      : const Text(
                    'Submit for Verification',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // Info text
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8F9FA),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'Verification usually takes 24-48 hours. You will be notified once it\'s completed.',
                  style: TextStyle(
                    fontSize: 14,
                    color: Color(0xFF6C757D),
                    height: 1.4,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _selectDate(BuildContext context) async {
    if (_isLoading) return;

    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().subtract(const Duration(days: 365 * 25)),
      firstDate: DateTime(1950),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF4169E1),
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Color(0xFF2C3E50),
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _dobController.text =
        '${picked.month.toString().padLeft(2, '0')}/${picked.day
            .toString()
            .padLeft(2, '0')}/${picked.year}';
      });
    }
  }

  void _chooseImages() async {
    if (_isLoading || _isUploading) return;

    try {
      // Show options dialog
      final ImageSource? source = await showDialog<ImageSource>(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Select Document Images'),
            content: const Text(
                'Choose how you want to add your Civil ID images:'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, ImageSource.camera),
                child: const Text('Take Photos'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, ImageSource.gallery),
                child: const Text('Choose from Gallery'),
              ),
            ],
          );
        },
      );

      if (source == null) return;

      final ImagePicker picker = ImagePicker();
      List<XFile> pickedFiles = [];

      if (source == ImageSource.gallery) {
        // Pick multiple images from gallery
        pickedFiles = await picker.pickMultiImage(
          maxWidth: 1024,
          maxHeight: 1024,
          imageQuality: 80,
        );
      } else {
        // Take photos with camera (one at a time)
        final XFile? frontImage = await picker.pickImage(
          source: ImageSource.camera,
          maxWidth: 1024,
          maxHeight: 1024,
          imageQuality: 80,
        );

        if (frontImage != null) {
          pickedFiles.add(frontImage);

          // Ask for back image
          if (mounted) {
            final bool? takeAnother = await showDialog<bool>(
              context: context,
              builder: (BuildContext context) {
                return AlertDialog(
                  title: const Text('Take Another Photo'),
                  content: const Text(
                      'Would you like to take a photo of the back of your Civil ID?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('No, Done'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: const Text('Yes, Take Back Photo'),
                    ),
                  ],
                );
              },
            );

            if (takeAnother == true) {
              final XFile? backImage = await picker.pickImage(
                source: ImageSource.camera,
                maxWidth: 1024,
                maxHeight: 1024,
                imageQuality: 80,
              );

              if (backImage != null) {
                pickedFiles.add(backImage);
              }
            }
          }
        }
      }

      if (pickedFiles.isNotEmpty && mounted) {
        await _uploadFiles(pickedFiles);
      }
    } catch (e) {
      if (mounted) {
        _showErrorSnackBar('Error selecting images: ${e.toString()}');
      }
    }
  }

  Future<void> _uploadFiles(List<XFile> files) async {
    if (mounted) {
      setState(() {
        _isUploading = true;
        _isLoading = true;
      });
    }

    List<String> newFiles = [];
    List<String> newFileUrls = [];
    _activeUploadTasks.clear();

    try {
      for (var file in files) {
        if (!mounted) break;

        // Check file size
        if (File(file.path).lengthSync() > 5 * 1024 * 1024) {
          if (mounted) {
            _showErrorSnackBar('File ${file.name} is too large (max 5MB)');
          }
          continue;
        }

        // Upload with retry logic
        String? downloadUrl = await _uploadFileWithRetry(file);
        if (downloadUrl != null) {
          newFiles.add(file.name);
          newFileUrls.add(downloadUrl);
        }
      }

      // Update UI with results
      if (mounted) {
        setState(() {
          _uploadedFiles.clear();
          _uploadedFiles.addAll(newFiles);
          _uploadedFileUrls.clear();
          _uploadedFileUrls.addAll(newFileUrls);
          _isUploading = false;
          _isLoading = false;
        });

        if (newFiles.isNotEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                  '${newFiles.length} image(s) uploaded successfully!'),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 3),
            ),
          );
        } else {
          _showErrorSnackBar(
              'No files were uploaded successfully. Please try again.');
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isUploading = false;
          _isLoading = false;
        });
        _showErrorSnackBar('Upload failed: ${e.toString()}');
      }
    } finally {
      _activeUploadTasks.clear();
    }
  }

  Future<String?> _uploadFileWithRetry(XFile file, {int maxRetries = 3}) async {
    for (int attempt = 1; attempt <= maxRetries; attempt++) {
      if (!mounted) return null;

      try {
        // Create unique file name
        String fileName = '${DateTime
            .now()
            .millisecondsSinceEpoch}_${file.name}';

        // Create storage reference
        Reference storageRef = FirebaseStorage.instance
            .ref()
            .child(
            'identity_verification/${_authService.currentUserId}/$fileName');

        // Create upload task
        UploadTask uploadTask = storageRef.putFile(
          File(file.path),
          SettableMetadata(
            contentType: 'image/jpeg',
            customMetadata: {
              'uploadedBy': _authService.currentUserId ?? 'unknown',
              'uploadedAt': DateTime.now().toIso8601String(),
            },
          ),
        );

        // Track the upload task
        _activeUploadTasks.add(uploadTask);

        // Wait for upload to complete
        TaskSnapshot taskSnapshot = await uploadTask;

        // Remove from active tasks
        _activeUploadTasks.remove(uploadTask);

        // Check if upload was successful
        if (taskSnapshot.state == TaskState.success) {
          String downloadUrl = await taskSnapshot.ref.getDownloadURL();
          return downloadUrl;
        } else {
          throw Exception('Upload failed with state: ${taskSnapshot.state}');
        }
      } on FirebaseException catch (e) {
        if (e.code == 'canceled' && attempt < maxRetries) {
          // Retry on cancellation
          if (mounted) {
            _showErrorSnackBar('Upload attempt $attempt failed, retrying...');
          }
          await Future.delayed(
              Duration(seconds: attempt)); // Exponential backoff
          continue;
        } else {
          // Handle other Firebase exceptions
          String errorMessage = _getStorageErrorMessage(e);
          if (mounted) {
            _showErrorSnackBar('Upload error: $errorMessage');
          }
          return null;
        }
      } catch (e) {
        if (attempt < maxRetries) {
          if (mounted) {
            _showErrorSnackBar('Upload attempt $attempt failed, retrying...');
          }
          await Future.delayed(Duration(seconds: attempt));
          continue;
        } else {
          if (mounted) {
            _showErrorSnackBar(
                'Upload failed after $maxRetries attempts: ${e.toString()}');
          }
          return null;
        }
      }
    }
    return null;
  }

  String _getStorageErrorMessage(FirebaseException e) {
    switch (e.code) {
      case 'canceled':
        return 'Upload was cancelled. Please try again.';
      case 'invalid-checksum':
        return 'File integrity check failed. Please try again.';
      case 'invalid-event-name':
        return 'Invalid upload event. Please try again.';
      case 'invalid-url':
        return 'Invalid storage URL. Please contact support.';
      case 'invalid-argument':
        return 'Invalid file format. Please select a valid image.';
      case 'no-default-bucket':
        return 'Storage not configured. Please contact support.';
      case 'object-not-found':
        return 'Upload destination not found. Please try again.';
      case 'project-not-found':
        return 'Project configuration error. Please contact support.';
      case 'quota-exceeded':
        return 'Storage quota exceeded. Please try again later.';
      case 'unauthenticated':
        return 'Authentication required. Please sign in again.';
      case 'unauthorized':
        return 'Upload permission denied. Please contact support.';
      case 'retry-limit-exceeded':
        return 'Too many retry attempts. Please try again later.';
      default:
        return e.message ?? 'Unknown storage error occurred.';
    }
  }

  bool _isFormValid() {
    return _civilIdController.text.isNotEmpty &&
        _fullNameController.text.isNotEmpty &&
        _dobController.text.isNotEmpty &&
        _uploadedFiles.isNotEmpty &&
        _confirmAccuracy;
  }

  Future<void> _submitVerification() async {
    // Basic validation
    if (_civilIdController.text.length != 8) {
      _showErrorSnackBar('Civil ID must be exactly 8 digits');
      return;
    }

    if (mounted) {
      setState(() {
        _isLoading = true;
      });
    }

    try {
      String? userId = _authService.currentUserId;
      if (userId != null) {
        // Prepare verification data with actual download URLs
        Map<String, dynamic> verificationData = {
          'civilId': _civilIdController.text,
          'fullName': _fullNameController.text.trim(),
          'dateOfBirth': _dobController.text,
          'uploadedFiles': _uploadedFiles, // File names for display
          'uploadedFileUrls': _uploadedFileUrls, // Actual download URLs
          'submittedAt': DateTime.now().toIso8601String(),
          'status': 'pending', // Add pending status
        };

        // Save identity verification data to Firebase
        await _authService.addIdentityVerification(userId, verificationData);

        // Show success message and navigate
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                  'Verification submitted successfully! You will be notified within 24-48 hours.'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 4),
            ),
          );

          // Navigate to service provider home screen
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (context) => const ServiceProviderHomeScreen(),
            ),
          );
        }
      } else {
        if (mounted) {
          _showErrorSnackBar('User not authenticated. Please sign in again.');
        }
      }
    } catch (e) {
      if (mounted) {
        _showErrorSnackBar('Failed to submit verification: ${e.toString()}');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showErrorSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }
}
