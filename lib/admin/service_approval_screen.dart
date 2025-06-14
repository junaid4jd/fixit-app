import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/app_models.dart';

class ServiceApprovalScreen extends StatefulWidget {
  const ServiceApprovalScreen({super.key});

  @override
  State<ServiceApprovalScreen> createState() => _ServiceApprovalScreenState();
}

class _ServiceApprovalScreenState extends State<ServiceApprovalScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _adminNotesController = TextEditingController();

  // Cache for handyman data to prevent repeated loading and errors
  final Map<String, Map<String, dynamic>> _handymanCache = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _adminNotesController.dispose();
    super.dispose();
  }

  Future<Map<String, dynamic>?> _getHandymanData(String handymanId) async {
    // Check cache first
    if (_handymanCache.containsKey(handymanId)) {
      return _handymanCache[handymanId];
    }

    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(handymanId)
          .get();

      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        _handymanCache[handymanId] = data; // Cache the data
        return data;
      }
      return null;
    } catch (e) {
      print('Error loading handyman $handymanId: $e');
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'Service Approvals',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF2C3E50),
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          labelColor: const Color(0xFF4169E1),
          unselectedLabelColor: Colors.grey,
          indicatorColor: const Color(0xFF4169E1),
          tabs: const [
            Tab(text: 'Pending'),
            Tab(text: 'Approved'),
            Tab(text: 'Rejected'),
            Tab(text: 'Revisions'),
          ],
        ),
        actions: [
          IconButton(
            onPressed: () {
              // Debug info
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Refreshing service data...'),
                  duration: Duration(seconds: 1),
                ),
              );
              setState(() {});
            },
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildServicesList(ServiceApprovalStatus.pending),
          _buildServicesList(ServiceApprovalStatus.approved),
          _buildServicesList(ServiceApprovalStatus.rejected),
          _buildServicesList(ServiceApprovalStatus.revision_required),
        ],
      ),
    );
  }

  Widget _buildServicesList(ServiceApprovalStatus status) {
    final statusString = status
        .toString()
        .split('.')
        .last;
    print(
        'ServiceApprovalScreen: Querying services with status: $statusString');

    return StreamBuilder<QuerySnapshot>(
      stream: _getServicesStream(statusString),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          print('ServiceApprovalScreen: Error loading services: ${snapshot
              .error}');
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

        final services = snapshot.data?.docs ?? [];
        print('ServiceApprovalScreen: Found ${services
            .length} services with status: $statusString');

        if (services.isEmpty) {
          return _buildEmptyState(status);
        }

        // Sort services locally by createdAt (most recent first)
        final sortedServices = services.toList();
        sortedServices.sort((a, b) {
          try {
            final aData = a.data() as Map<String, dynamic>;
            final bData = b.data() as Map<String, dynamic>;
            final aTimestamp = aData['createdAt'] as Timestamp?;
            final bTimestamp = bData['createdAt'] as Timestamp?;

            if (aTimestamp != null && bTimestamp != null) {
              return bTimestamp.compareTo(
                  aTimestamp); // Descending (newest first)
            }
            return 0;
          } catch (e) {
            return 0;
          }
        });

        return ListView.builder(
          padding: const EdgeInsets.all(20),
          itemCount: sortedServices.length,
          itemBuilder: (context, index) {
            final doc = sortedServices[index];
            try {
              final service = HandymanService.fromMap(
                doc.data() as Map<String, dynamic>,
                doc.id,
              );
              return _buildServiceCard(service);
            } catch (e) {
              print(
                  'ServiceApprovalScreen: Error parsing service ${doc.id}: $e');
              return Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
                ),
                child: Column(
                  children: [
                    const Icon(Icons.error, color: Colors.red),
                    const SizedBox(height: 8),
                    Text('Error loading service: $e'),
                  ],
                ),
              );
            }
          },
        );
      },
    );
  }

  Stream<QuerySnapshot> _getServicesStream(String statusString) {
    // Use simple query without orderBy to avoid composite index requirement
    return FirebaseFirestore.instance
        .collection('handyman_services')
        .where('approvalStatus', isEqualTo: statusString)
        .snapshots();
  }

  Widget _buildEmptyState(ServiceApprovalStatus status) {
    String title;
    String subtitle;
    IconData icon;

    switch (status) {
      case ServiceApprovalStatus.pending:
        title = 'No Pending Services';
        subtitle = 'All services have been reviewed';
        icon = Icons.pending_actions;
        break;
      case ServiceApprovalStatus.approved:
        title = 'No Approved Services';
        subtitle = 'No services have been approved yet';
        icon = Icons.check_circle;
        break;
      case ServiceApprovalStatus.rejected:
        title = 'No Rejected Services';
        subtitle = 'No services have been rejected';
        icon = Icons.cancel;
        break;
      case ServiceApprovalStatus.revision_required:
        title = 'No Revision Requests';
        subtitle = 'No services require revisions';
        icon = Icons.edit;
        break;
    }

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
            child: Icon(
              icon,
              size: 60,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            title,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2C3E50),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
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
          // Header with handyman info
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey.withValues(alpha: 0.05),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Row(
              children: [
                FutureBuilder<Map<String, dynamic>?>(
                  future: _getHandymanData(service.handymanId),
                  builder: (context, snapshot) {
                    if (snapshot.hasData && snapshot.data != null) {
                      final handymanData = snapshot.data!;
                      return Expanded(
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 20,
                              backgroundImage: handymanData['profileImageUrl'] !=
                                  null
                                  ? NetworkImage(
                                  handymanData['profileImageUrl'])
                                  : null,
                              child: handymanData['profileImageUrl'] == null
                                  ? Text(
                                (handymanData['fullName'] ?? 'H').substring(
                                    0, 1).toUpperCase(),
                                style: const TextStyle(fontSize: 14),
                              )
                                  : null,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    handymanData['fullName'] ??
                                        'Unknown Handyman',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF2C3E50),
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  Text(
                                    '${handymanData['experienceYears'] ??
                                        0} years experience',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    }
                    if (snapshot.hasError) {
                      return Expanded(
                        child: Row(
                          children: [
                            const CircleAvatar(
                              radius: 20,
                              child: Icon(Icons.error, size: 16),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Error loading handyman',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.red,
                                    ),
                                  ),
                                  Text(
                                    'ID: ${service.handymanId}',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[600],
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    }
                    return const Expanded(
                      child: Row(
                        children: [
                          CircleAvatar(radius: 20),
                          SizedBox(width: 12),
                          Text('Loading...'),
                        ],
                      ),
                    );
                  },
                ),
                const Spacer(),
                Text(
                  'OMR ${service.price.toStringAsFixed(2)} ${_getPriceTypeText(
                      service.priceType)}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF4169E1),
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        service.title,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2C3E50),
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF4169E1).withValues(alpha: 0.1),
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
                const SizedBox(height: 12),

                Text(
                  service.description,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[700],
                    height: 1.4,
                  ),
                ),

                if (service.workSamples.isNotEmpty) ...[
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
                    height: 80,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: service.workSamples.length,
                      itemBuilder: (context, index) {
                        return GestureDetector(
                          onTap: () =>
                              _showImageDialog(service.workSamples[index]),
                          child: Container(
                            margin: const EdgeInsets.only(right: 8),
                            width: 80,
                            height: 80,
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

                if (service.adminNotes != null &&
                    service.adminNotes!.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: Colors.blue.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Previous Admin Notes:',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.blue,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          service.adminNotes!,
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.blue[700],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 16),
                Column(
                  children: [
                    Row(
                      children: [
                        Text(
                          'Submitted: ${_formatDate(service.createdAt)}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[500],
                          ),
                        ),
                      ],
                    ),
                    if (service.approvalStatus ==
                        ServiceApprovalStatus.pending ||
                        service.approvalStatus ==
                            ServiceApprovalStatus.revision_required) ...[
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          TextButton.icon(
                            onPressed: () =>
                                _showApprovalDialog(
                                    service,
                                    ServiceApprovalStatus.revision_required),
                            icon: const Icon(Icons.edit, size: 16),
                            label: const Text('Request Revision'),
                            style: TextButton.styleFrom(
                              foregroundColor: Colors.orange,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 8),
                            ),
                          ),
                          TextButton.icon(
                            onPressed: () =>
                                _showApprovalDialog(
                                service, ServiceApprovalStatus.rejected),
                            icon: const Icon(Icons.close, size: 16),
                            label: const Text('Reject'),
                            style: TextButton.styleFrom(
                              foregroundColor: Colors.red,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 8),
                            ),
                          ),
                          ElevatedButton.icon(
                            onPressed: () => _approveService(service),
                            icon: const Icon(Icons.check, size: 16),
                            label: const Text('Approve'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 8),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
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
        return '/hr';
      case 'per_unit':
        return '/unit';
      default:
        return '';
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
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

  void _showApprovalDialog(HandymanService service,
      ServiceApprovalStatus newStatus) {
    _adminNotesController.clear();

    showDialog(
      context: context,
      builder: (context) =>
          AlertDialog(
            title: Text(
              newStatus == ServiceApprovalStatus.rejected
                  ? 'Reject Service'
                  : 'Request Revision',
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  newStatus == ServiceApprovalStatus.rejected
                      ? 'Please provide a reason for rejecting this service:'
                      : 'Please specify what needs to be revised:',
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _adminNotesController,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    hintText: 'Enter your notes here...',
                  ),
                  maxLines: 4,
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () =>
                    _updateServiceStatus(
                        service, newStatus, _adminNotesController.text),
                style: ElevatedButton.styleFrom(
                  backgroundColor: newStatus == ServiceApprovalStatus.rejected
                      ? Colors.red
                      : Colors.orange,
                  foregroundColor: Colors.white,
                ),
                child: Text(newStatus == ServiceApprovalStatus.rejected
                    ? 'Reject'
                    : 'Request Revision'),
              ),
            ],
          ),
    );
  }

  Future<void> _approveService(HandymanService service) async {
    try {
      await FirebaseFirestore.instance
          .collection('handyman_services')
          .doc(service.id)
          .update({
        'approvalStatus': ServiceApprovalStatus.approved
            .toString()
            .split('.')
            .last,
        'approvedAt': FieldValue.serverTimestamp(),
        'adminNotes': null,
      });

      _showSuccessSnackBar('Service approved successfully!');
    } catch (e) {
      _showErrorSnackBar('Error approving service: $e');
    }
  }

  Future<void> _updateServiceStatus(HandymanService service,
      ServiceApprovalStatus status, String notes) async {
    if (notes
        .trim()
        .isEmpty) {
      _showErrorSnackBar('Please provide a reason/note');
      return;
    }

    try {
      await FirebaseFirestore.instance
          .collection('handyman_services')
          .doc(service.id)
          .update({
        'approvalStatus': status
            .toString()
            .split('.')
            .last,
        'adminNotes': notes.trim(),
      });

      Navigator.pop(context);
      _showSuccessSnackBar(
          status == ServiceApprovalStatus.rejected
              ? 'Service rejected'
              : 'Revision requested'
      );
    } catch (e) {
      _showErrorSnackBar('Error updating service: $e');
    }
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
}
