import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/app_models.dart';
import '../../services/auth_service.dart';
import 'create_service_screen.dart';

class MyServicesScreen extends StatefulWidget {
  const MyServicesScreen({super.key});

  @override
  State<MyServicesScreen> createState() => _MyServicesScreenState();
}

class _MyServicesScreenState extends State<MyServicesScreen> {
  final AuthService _authService = AuthService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'My Services',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF2C3E50),
        elevation: 0,
        actions: [
          IconButton(
            onPressed: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const CreateServiceScreen(),
                ),
              );
              if (result == true) {
                setState(() {}); // Refresh the list
              }
            },
            icon: const Icon(Icons.add),
            tooltip: 'Add New Service',
          ),
        ],
      ),
      body: FutureBuilder<List<HandymanService>>(
        future: _getMyServices(),
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

          final services = snapshot.data ?? [];

          if (services.isEmpty) {
            return _buildEmptyState();
          }

          return ListView.builder(
            padding: const EdgeInsets.all(20),
            itemCount: services.length,
            itemBuilder: (context, index) {
              final service = services[index];
              return _buildServiceCard(service);
            },
          );
        },
      ),
    );
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
              color: const Color(0xFF4169E1).withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.build_circle,
              size: 60,
              color: Color(0xFF4169E1),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'No Services Yet',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2C3E50),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Create your first service to start\ngetting customers',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const CreateServiceScreen(),
                ),
              );
              if (result == true) {
                setState(() {}); // Refresh the list
              }
            },
            icon: const Icon(Icons.add),
            label: const Text('Create Service'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF4169E1),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
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
          // Header with status
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _getStatusColor(service.approvalStatus).withValues(
                  alpha: 0.1),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  _getStatusIcon(service.approvalStatus),
                  color: _getStatusColor(service.approvalStatus),
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  _getStatusText(service.approvalStatus),
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: _getStatusColor(service.approvalStatus),
                  ),
                ),
                const Spacer(),
                Text(
                  'OMR ${service.price.toStringAsFixed(2)} ${_getPriceTypeText(
                      service.priceType)}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2C3E50),
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
                Text(
                  service.title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2C3E50),
                  ),
                ),
                const SizedBox(height: 4),
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
                const SizedBox(height: 12),
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

                if (service.workSamples.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 60,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: service.workSamples.length,
                      itemBuilder: (context, index) {
                        return Container(
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
                      color: service.approvalStatus ==
                          ServiceApprovalStatus.rejected
                          ? Colors.red.withValues(alpha: 0.1)
                          : Colors.orange.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: service.approvalStatus ==
                            ServiceApprovalStatus.rejected
                            ? Colors.red.withValues(alpha: 0.3)
                            : Colors.orange.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Admin Notes:',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: service.approvalStatus ==
                                ServiceApprovalStatus.rejected
                                ? Colors.red
                                : Colors.orange,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          service.adminNotes!,
                          style: TextStyle(
                            fontSize: 13,
                            color: service.approvalStatus ==
                                ServiceApprovalStatus.rejected
                                ? Colors.red[700]
                                : Colors.orange[700],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 16),
                Row(
                  children: [
                    Text(
                      'Created: ${_formatDate(service.createdAt)}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[500],
                      ),
                    ),
                    const Spacer(),
                    if (service.approvalStatus ==
                        ServiceApprovalStatus.pending ||
                        service.approvalStatus ==
                            ServiceApprovalStatus.revision_required)
                      TextButton.icon(
                        onPressed: () => _editService(service),
                        icon: const Icon(Icons.edit, size: 16),
                        label: const Text('Edit'),
                        style: TextButton.styleFrom(
                          foregroundColor: const Color(0xFF4169E1),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 8),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(ServiceApprovalStatus status) {
    switch (status) {
      case ServiceApprovalStatus.pending:
        return Colors.orange;
      case ServiceApprovalStatus.approved:
        return Colors.green;
      case ServiceApprovalStatus.rejected:
        return Colors.red;
      case ServiceApprovalStatus.revision_required:
        return Colors.blue;
    }
  }

  IconData _getStatusIcon(ServiceApprovalStatus status) {
    switch (status) {
      case ServiceApprovalStatus.pending:
        return Icons.pending;
      case ServiceApprovalStatus.approved:
        return Icons.check_circle;
      case ServiceApprovalStatus.rejected:
        return Icons.cancel;
      case ServiceApprovalStatus.revision_required:
        return Icons.edit;
    }
  }

  String _getStatusText(ServiceApprovalStatus status) {
    switch (status) {
      case ServiceApprovalStatus.pending:
        return 'Pending Review';
      case ServiceApprovalStatus.approved:
        return 'Approved';
      case ServiceApprovalStatus.rejected:
        return 'Rejected';
      case ServiceApprovalStatus.revision_required:
        return 'Revision Required';
    }
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

  void _editService(HandymanService service) {
    // TODO: Navigate to edit service screen
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Edit service feature coming soon!')),
    );
  }

  Future<List<HandymanService>> _getMyServices() async {
    if (_authService.currentUserId == null) {
      print('MyServicesScreen: No current user ID found');
      return [];
    }

    print('MyServicesScreen: Loading services for user: ${_authService
        .currentUserId}');

    try {
      // Try to get the collection first to see if it exists
      final collection = FirebaseFirestore.instance.collection(
          'handyman_services');

      // Get all the services for this handyman
      final allSnapshot = await collection
          .where('handymanId', isEqualTo: _authService.currentUserId)
          .get();

      // Sort by creation date
      final docs = allSnapshot.docs;
      try {
        docs.sort((a, b) {
          final aData = a.data();
          final bData = b.data();
          final aDate = aData['createdAt'] as Timestamp?;
          final bDate = bData['createdAt'] as Timestamp?;

          if (aDate != null && bDate != null) {
            return bDate.compareTo(aDate); // Descending order
          }
          return 0;
        });
      } catch (e) {
        // Ignore sorting errors
      }

      return docs.map((doc) {
        return HandymanService.fromMap(
          doc.data(),
          doc.id,
        );
      }).toList();
    } catch (e) {
      print('MyServicesScreen: Error querying services: $e');
      return [];
    }
  }
}
