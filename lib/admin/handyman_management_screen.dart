import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class HandymanManagementScreen extends StatefulWidget {
  const HandymanManagementScreen({super.key});

  @override
  State<HandymanManagementScreen> createState() =>
      _HandymanManagementScreenState();
}

class _HandymanManagementScreenState extends State<HandymanManagementScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedFilter = 'All';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'Handyman Management',
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
            child: _buildHandymenList(),
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
              hintText: 'Search handymen...',
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
                      _buildFilterChip('Verified'),
                      _buildFilterChip('Pending'),
                      _buildFilterChip('Rejected'),
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

  Widget _buildHandymenList() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .where('role', isEqualTo: 'service_provider')
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
            child: Text('No handymen found'),
          );
        }

        List<DocumentSnapshot> handymen = snapshot.data!.docs;

        // Apply search filter
        if (_searchQuery.isNotEmpty) {
          handymen = handymen.where((doc) {
            Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
            String name = data['fullName']?.toLowerCase() ?? '';
            String email = data['email']?.toLowerCase() ?? '';
            String category = data['primaryCategory']?.toLowerCase() ?? '';
            return name.contains(_searchQuery.toLowerCase()) ||
                email.contains(_searchQuery.toLowerCase()) ||
                category.contains(_searchQuery.toLowerCase());
          }).toList();
        }

        // Apply status filter
        if (_selectedFilter != 'All') {
          handymen = handymen.where((doc) {
            Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
            switch (_selectedFilter) {
              case 'Verified':
                return data['isVerified'] == true;
              case 'Pending':
                return data['verification_status'] == 'pending' ||
                    (data['verificationSubmitted'] == true &&
                        data['isVerified'] != true);
              case 'Rejected':
                return data['verification_status'] == 'rejected';
              case 'Suspended':
                return data['isActive'] == false;
              default:
                return true;
            }
          }).toList();
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: handymen.length,
          itemBuilder: (context, index) {
            return _buildHandymanCard(handymen[index]);
          },
        );
      },
    );
  }

  Widget _buildHandymanCard(DocumentSnapshot handymanDoc) {
    Map<String, dynamic> handyman = handymanDoc.data() as Map<String, dynamic>;
    String handymanId = handymanDoc.id;

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
                  backgroundImage: handyman['profileImage'] != null
                      ? NetworkImage(handyman['profileImage'])
                      : null,
                  child: handyman['profileImage'] == null
                      ? Text(
                    (handyman['fullName'] ?? 'H')[0].toUpperCase(),
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
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              handyman['fullName'] ?? 'Unknown',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF2C3E50),
                              ),
                            ),
                          ),
                          if (handyman['isVerified'] == true)
                            const Icon(
                              Icons.verified,
                              color: Colors.green,
                              size: 20,
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        handyman['primaryCategory'] ?? 'General',
                        style: const TextStyle(
                          fontSize: 14,
                          color: Color(0xFF4169E1),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.star, color: Colors.amber, size: 16),
                          const SizedBox(width: 4),
                          Text(
                            '${handyman['rating'] ??
                                0.0} (${handyman['reviewCount'] ?? 0})',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFF7F8C8D),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            '${handyman['hourlyRate'] ?? 0} OMR/hr',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFF2ECC71),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                _buildStatusChip(handyman),
              ],
            ),
            const SizedBox(height: 12),

            // Handyman Details
            Row(
              children: [
                _buildInfoItem(
                  icon: Icons.location_on,
                  label: 'City',
                  value: handyman['city'] ?? 'Not set',
                ),
                const SizedBox(width: 16),
                _buildInfoItem(
                  icon: Icons.work,
                  label: 'Experience',
                  value: '${handyman['experience'] ?? 0} years',
                ),
                const SizedBox(width: 16),
                _buildInfoItem(
                  icon: Icons.phone,
                  label: 'Phone',
                  value: handyman['phoneNumber'] ?? 'N/A',
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Action Buttons
            Row(
              children: [
                if (handyman['verification_status'] == 'pending' &&
                    handyman['isVerified'] != true)
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () =>
                          _viewVerificationDetails(handymanId, handyman),
                      icon: const Icon(Icons.visibility, size: 16),
                      label: const Text('Review'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF4169E1),
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                if (handyman['verification_status'] == 'pending' &&
                    handyman['isVerified'] != true)
                  const SizedBox(width: 8),
                Expanded(
                  child: TextButton.icon(
                    onPressed: () => _viewHandymanDetails(handymanId, handyman),
                    icon: const Icon(Icons.person, size: 16),
                    label: const Text('Profile'),
                    style: TextButton.styleFrom(
                      foregroundColor: const Color(0xFF4169E1),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                PopupMenuButton<String>(
                  onSelected: (value) {
                    switch (value) {
                      case 'verify':
                        _verifyHandyman(handymanId, handyman);
                        break;
                      case 'reject':
                        _rejectHandyman(handymanId, handyman);
                        break;
                      case 'suspend':
                        _suspendHandyman(handymanId, handyman);
                        break;
                      case 'activate':
                        _activateHandyman(handymanId, handyman);
                        break;
                      case 'delete':
                        _deleteHandyman(handymanId);
                        break;
                    }
                  },
                  itemBuilder: (context) =>
                  [
                    if (handyman['isVerified'] != true &&
                        handyman['verification_status'] == 'pending')
                      const PopupMenuItem(
                        value: 'verify',
                        child: Text('Verify'),
                      ),
                    if (handyman['isVerified'] != true &&
                        handyman['verification_status'] == 'pending')
                      const PopupMenuItem(
                        value: 'reject',
                        child: Text('Reject'),
                      ),
                    if (handyman['isActive'] != false)
                      const PopupMenuItem(
                        value: 'suspend',
                        child: Text('Suspend'),
                      ),
                    if (handyman['isActive'] == false)
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

  Widget _buildStatusChip(Map<String, dynamic> handyman) {
    Color color;
    String label;

    if (handyman['isActive'] == false) {
      color = Colors.red;
      label = 'Suspended';
    } else if (handyman['isVerified'] == true) {
      color = Colors.green;
      label = 'Verified';
    } else if (handyman['verification_status'] == 'pending') {
      color = Colors.orange;
      label = 'Pending';
    } else if (handyman['verification_status'] == 'rejected') {
      color = Colors.red;
      label = 'Rejected';
    } else {
      color = Colors.grey;
      label = 'Unverified';
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
        Icon(icon, size: 14, color: const Color(0xFF7F8C8D)),
        const SizedBox(width: 4),
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

  void _viewVerificationDetails(String handymanId,
      Map<String, dynamic> handyman) {
    // Fetch verification details
    FirebaseFirestore.instance
        .collection('identity_verifications')
        .where('userId', isEqualTo: handymanId)
        .get()
        .then((snapshot) {
      if (snapshot.docs.isNotEmpty) {
        Map<String, dynamic> verification = snapshot.docs.first.data();
        _showVerificationDialog(
            handymanId, handyman, verification, snapshot.docs.first.id);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No verification data found')),
        );
      }
    }).catchError((error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading verification data: $error')),
      );
    });
  }

  void _showVerificationDialog(String handymanId, Map<String, dynamic> handyman,
      Map<String, dynamic> verification, String verificationId) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          child: Container(
            width: MediaQuery
                .of(context)
                .size
                .width * 0.9,
            height: MediaQuery
                .of(context)
                .size
                .height * 0.8,
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Verify ${handyman['fullName']}',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2C3E50),
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
                const Divider(),

                // Content
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Personal Information Card
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Personal Information',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF2C3E50),
                                  ),
                                ),
                                const SizedBox(height: 12),
                                _buildDetailRow('Full Name',
                                    verification['fullName'] ?? 'N/A'),
                                _buildDetailRow('Civil ID',
                                    verification['civilId'] ?? 'N/A'),
                                _buildDetailRow('Date of Birth',
                                    verification['dateOfBirth'] ?? 'N/A'),
                                _buildDetailRow(
                                    'Email', handyman['email'] ?? 'N/A'),
                                _buildDetailRow(
                                    'Phone', handyman['phoneNumber'] ?? 'N/A'),
                                _buildDetailRow(
                                    'City', handyman['city'] ?? 'N/A'),
                                _buildDetailRow('Primary Category',
                                    handyman['primaryCategory'] ?? 'N/A'),
                                _buildDetailRow('Experience',
                                    '${handyman['experience'] ?? 0} years'),
                                _buildDetailRow('Hourly Rate',
                                    '${handyman['hourlyRate'] ?? 0} OMR'),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 16),

                        // Documents Card
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Uploaded Documents',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF2C3E50),
                                  ),
                                ),
                                const SizedBox(height: 12),

                                if (verification['uploadedFileUrls'] != null &&
                                    (verification['uploadedFileUrls'] as List)
                                        .isNotEmpty) ...[
                                  Text(
                                    'Document Files: ${(verification['uploadedFiles'] as List?)
                                        ?.length ?? 0}',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w500,
                                      color: Color(0xFF7F8C8D),
                                    ),
                                  ),
                                  const SizedBox(height: 12),

                                  // Display uploaded files
                                  Wrap(
                                    spacing: 8,
                                    runSpacing: 8,
                                    children: [
                                      for (int i = 0; i <
                                          (verification['uploadedFileUrls'] as List)
                                              .length; i++)
                                        _buildDocumentCard(
                                          fileName: (verification['uploadedFiles'] as List)[i],
                                          fileUrl: (verification['uploadedFileUrls'] as List)[i],
                                          index: i + 1,
                                        ),
                                    ],
                                  ),
                                ] else
                                  ...[
                                    Container(
                                      padding: const EdgeInsets.all(16),
                                      decoration: BoxDecoration(
                                        color: Colors.orange.withValues(
                                            alpha: 0.1),
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(
                                            color: Colors.orange.withValues(
                                                alpha: 0.3)),
                                      ),
                                      child: const Row(
                                        children: [
                                          Icon(Icons.warning,
                                              color: Colors.orange),
                                          SizedBox(width: 8),
                                          Text(
                                            'No documents uploaded',
                                            style: TextStyle(
                                                color: Colors.orange),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 16),

                        // Submission Details Card
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Submission Details',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF2C3E50),
                                  ),
                                ),
                                const SizedBox(height: 12),
                                _buildDetailRow('Status',
                                    verification['status'] ?? 'pending'),
                                _buildDetailRow('Submitted At', _formatDateTime(
                                    verification['submittedAt'])),
                                if (verification['reviewedAt'] != null)
                                  _buildDetailRow('Reviewed At',
                                      _formatDateTime(
                                          verification['reviewedAt'])),
                                if (verification['rejectionReason'] != null)
                                  _buildDetailRow('Rejection Reason',
                                      verification['rejectionReason']),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const Divider(),

                // Action Buttons
                Row(
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancel'),
                    ),
                    const Spacer(),
                    if (verification['status'] == 'pending') ...[
                      TextButton(
                        onPressed: () {
                          _rejectVerification(handymanId, verificationId);
                          Navigator.pop(context);
                        },
                        style: TextButton.styleFrom(
                            foregroundColor: Colors.red),
                        child: const Text('Reject'),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: () {
                          _approveVerification(handymanId, verificationId);
                          Navigator.pop(context);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                        ),
                        child: const Text('Approve'),
                      ),
                    ] else
                      ...[
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: verification['status'] == 'approved'
                                ? Colors.green.withValues(alpha: 0.1)
                                : Colors.red.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            verification['status'] == 'approved'
                                ? 'Already Approved'
                                : 'Already Rejected',
                            style: TextStyle(
                              color: verification['status'] == 'approved'
                                  ? Colors.green
                                  : Colors.red,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildDocumentCard({
    required String fileName,
    required String fileUrl,
    required int index,
  }) {
    return Container(
      width: 150,
      height: 120,
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () => _viewDocument(fileUrl, fileName),
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(8)),
                  color: Colors.grey[200],
                ),
                child: ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(8)),
                  child: Image.network(
                    fileUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.image_not_supported, size: 32,
                                color: Colors.grey),
                            Text('Error loading',
                                style: TextStyle(fontSize: 10)),
                          ],
                        ),
                      );
                    },
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return const Center(
                        child: CircularProgressIndicator(strokeWidth: 2),
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(4),
            decoration: const BoxDecoration(
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(8)),
            ),
            child: Column(
              children: [
                Text(
                  'Document $index',
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                ),
                ElevatedButton(
                  onPressed: () => _viewDocument(fileUrl, fileName),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4169E1),
                    foregroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, 24),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 2),
                  ),
                  child: const Text(
                    'View',
                    style: TextStyle(fontSize: 10),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _viewDocument(String documentUrl, String fileName) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          child: Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        fileName,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
                const Divider(),
                Expanded(
                  child: Image.network(
                    documentUrl,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) {
                      return const Center(
                        child: Text('Error loading document'),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
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
            width: 100,
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

  void _approveVerification(String handymanId, String verificationId) async {
    try {
      // Update verification status
      await FirebaseFirestore.instance
          .collection('identity_verifications')
          .doc(verificationId)
          .update({
        'status': 'approved',
        'reviewedAt': FieldValue.serverTimestamp(),
        'reviewedBy': 'admin', // Replace with actual admin ID
      });

      // Update handyman status - this is the key fix
      await FirebaseFirestore.instance
          .collection('users')
          .doc(handymanId)
          .update({
        'isVerified': true,
        'verification_status': 'approved',
        'verifiedAt': FieldValue.serverTimestamp(),
        'verificationSubmitted': true, // Keep this for tracking
      });

      // Also update any related collections if needed
      // For service providers, we might need to update their service provider profile
      await FirebaseFirestore.instance
          .collection('service_providers')
          .doc(handymanId)
          .set({
        'isVerified': true,
        'verification_status': 'approved',
        'verifiedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true)).catchError((error) {
        // Ignore if service_providers collection doesn't exist
        print('Service providers collection update failed: $error');
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Handyman verified successfully! Status updated.'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error approving verification: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _rejectVerification(String handymanId, String verificationId) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        final reasonController = TextEditingController();

        return AlertDialog(
          title: const Text('Reject Verification'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Reason for rejection:'),
              const SizedBox(height: 12),
              TextField(
                controller: reasonController,
                maxLines: 3,
                decoration: const InputDecoration(
                  hintText: 'Enter rejection reason...',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                try {
                  // Update verification status
                  await FirebaseFirestore.instance
                      .collection('identity_verifications')
                      .doc(verificationId)
                      .update({
                    'status': 'rejected',
                    'rejectionReason': reasonController.text.trim(),
                    'reviewedAt': FieldValue.serverTimestamp(),
                    'reviewedBy': 'admin',
                  });

                  // Update handyman status
                  await FirebaseFirestore.instance
                      .collection('users')
                      .doc(handymanId)
                      .update({
                    'isVerified': false,
                    'verification_status': 'rejected',
                    'rejectionReason': reasonController.text.trim(),
                    'rejectedAt': FieldValue.serverTimestamp(),
                  });

                  Navigator.pop(context);
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Verification rejected successfully'),
                        backgroundColor: Colors.orange,
                      ),
                    );
                  }
                } catch (e) {
                  Navigator.pop(context);
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Error rejecting verification: $e'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red, foregroundColor: Colors.white),
              child: const Text('Reject'),
            ),
          ],
        );
      },
    );
  }

  void _viewHandymanDetails(String handymanId, Map<String, dynamic> handyman) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(handyman['fullName'] ?? 'Handyman Details'),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildDetailRow('Email', handyman['email'] ?? 'Not provided'),
                _buildDetailRow(
                    'Phone', handyman['phoneNumber'] ?? 'Not provided'),
                _buildDetailRow('City', handyman['city'] ?? 'Not set'),
                _buildDetailRow(
                    'Category', handyman['primaryCategory'] ?? 'General'),
                _buildDetailRow(
                    'Experience', '${handyman['experience'] ?? 0} years'),
                _buildDetailRow(
                    'Hourly Rate', '${handyman['hourlyRate'] ?? 0} OMR'),
                _buildDetailRow('Rating', '${handyman['rating'] ?? 0.0}/5.0'),
                _buildDetailRow('Reviews', '${handyman['reviewCount'] ?? 0}'),
                _buildDetailRow('Specialties',
                    (handyman['specialties'] as List?)?.join(', ') ?? 'None'),
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

  void _verifyHandyman(String handymanId, Map<String, dynamic> handyman) async {
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(handymanId)
          .update({
        'isVerified': true,
        'verification_status': 'approved',
        'verifiedAt': FieldValue.serverTimestamp(),
      });

      // Also update service_providers collection if it exists
      await FirebaseFirestore.instance
          .collection('service_providers')
          .doc(handymanId)
          .set({
        'isVerified': true,
        'verification_status': 'approved',
        'verifiedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true)).catchError((error) {
        // Ignore if collection doesn't exist
        print('Service providers update failed: $error');
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Handyman verified successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error verifying handyman: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _rejectHandyman(String handymanId, Map<String, dynamic> handyman) async {
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(handymanId)
          .update({
        'isVerified': false,
        'verification_status': 'rejected',
        'rejectedAt': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Handyman verification rejected'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error rejecting handyman: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _suspendHandyman(String handymanId, Map<String, dynamic> handyman) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Suspend Handyman'),
          content: Text(
              'Are you sure you want to suspend ${handyman['fullName']}?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                FirebaseFirestore.instance
                    .collection('users')
                    .doc(handymanId)
                    .update({
                  'isActive': false,
                  'suspendedAt': FieldValue.serverTimestamp(),
                });
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Handyman suspended')),
                );
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('Suspend'),
            ),
          ],
        );
      },
    );
  }

  void _activateHandyman(String handymanId, Map<String, dynamic> handyman) {
    FirebaseFirestore.instance
        .collection('users')
        .doc(handymanId)
        .update({
      'isActive': true,
      'activatedAt': FieldValue.serverTimestamp(),
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Handyman activated successfully')),
    );
  }

  void _deleteHandyman(String handymanId) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete Handyman'),
          content: const Text(
              'Are you sure you want to delete this handyman? This action cannot be undone.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                FirebaseFirestore.instance
                    .collection('users')
                    .doc(handymanId)
                    .delete();
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text('Handyman deleted successfully')),
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

  String _formatDateTime(dynamic dateTime) {
    if (dateTime == null) return 'N/A';

    try {
      DateTime dt;
      if (dateTime is Timestamp) {
        dt = dateTime.toDate();
      } else if (dateTime is String) {
        dt = DateTime.parse(dateTime);
      } else {
        return dateTime.toString();
      }

      return '${dt.day}/${dt.month}/${dt.year} ${dt.hour.toString().padLeft(
          2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return dateTime.toString();
    }
  }
}
