import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class PaymentCommissionScreen extends StatefulWidget {
  const PaymentCommissionScreen({super.key});

  @override
  State<PaymentCommissionScreen> createState() =>
      _PaymentCommissionScreenState();
}

class _PaymentCommissionScreenState extends State<PaymentCommissionScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  double _currentCommissionRate = 10.0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadCommissionRate();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadCommissionRate() async {
    try {
      DocumentSnapshot doc = await FirebaseFirestore.instance
          .collection('settings')
          .doc('commission')
          .get();

      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>?;
        setState(() {
          _currentCommissionRate = data?['rate'] ?? 10.0;
        });
      }
    } catch (e) {
      debugPrint('Error loading commission rate: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'Payment & Commission',
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
            Tab(text: 'Transactions'),
            Tab(text: 'Commission'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildTransactionsTab(),
          _buildCommissionTab(),
        ],
      ),
    );
  }

  Widget _buildTransactionsTab() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('bookings')
          .where('status', isEqualTo: 'completed')
          .orderBy('completedAt', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.receipt_long, size: 80, color: Colors.grey),
                SizedBox(height: 16),
                Text('No completed transactions'),
              ],
            ),
          );
        }

        return Column(
          children: [
            _buildTransactionSummary(snapshot.data!.docs),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: snapshot.data!.docs.length,
                itemBuilder: (context, index) {
                  return _buildTransactionCard(snapshot.data!.docs[index]);
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildTransactionSummary(List<DocumentSnapshot> transactions) {
    double totalRevenue = 0;
    double totalCommission = 0;

    for (var doc in transactions) {
      Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
      double amount = data['estimatedCost'] ?? 0;
      totalRevenue += amount;
      totalCommission += amount * (_currentCommissionRate / 100);
    }

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: _buildSummaryCard(
              title: 'Total Revenue',
              value: '${totalRevenue.toStringAsFixed(2)} OMR',
              icon: Icons.monetization_on,
              color: const Color(0xFF2ECC71),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildSummaryCard(
              title: 'Total Commission',
              value: '${totalCommission.toStringAsFixed(2)} OMR',
              icon: Icons.percent,
              color: const Color(0xFF4169E1),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF7F8C8D),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionCard(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    double amount = data['estimatedCost'] ?? 0;
    double commission = amount * (_currentCommissionRate / 100);

    return FutureBuilder<Map<String, String>>(
      future: _getTransactionDetails(data),
      builder: (context, snapshot) {
        Map<String, String> details = snapshot.data ?? {
          'customerName': 'Unknown',
          'handymanName': 'Unknown',
        };

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
                    Expanded(
                      child: Text(
                        data['category'] ?? 'Service',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2C3E50),
                        ),
                      ),
                    ),
                    Text(
                      _formatDate(data['completedAt']),
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF7F8C8D),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                Row(
                  children: [
                    const Icon(
                        Icons.person, size: 16, color: Color(0xFF7F8C8D)),
                    const SizedBox(width: 4),
                    Text(
                      details['customerName']!,
                      style: const TextStyle(
                          fontSize: 14, color: Color(0xFF7F8C8D)),
                    ),
                    const SizedBox(width: 16),
                    const Icon(Icons.build, size: 16, color: Color(0xFF7F8C8D)),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        details['handymanName']!,
                        style: const TextStyle(fontSize: 14, color: Color(
                            0xFF7F8C8D)),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Amount',
                            style: TextStyle(
                              fontSize: 12,
                              color: Color(0xFF7F8C8D),
                            ),
                          ),
                          Text(
                            '${amount.toStringAsFixed(2)} OMR',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF2ECC71),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        const Text(
                          'Commission',
                          style: TextStyle(
                            fontSize: 12,
                            color: Color(0xFF7F8C8D),
                          ),
                        ),
                        Text(
                          '${commission.toStringAsFixed(2)} OMR',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF4169E1),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<Map<String, String>> _getTransactionDetails(
      Map<String, dynamic> data) async {
    Map<String, String> details = {
      'customerName': 'Unknown',
      'handymanName': 'Unknown',
    };

    try {
      if (data['userId'] != null) {
        DocumentSnapshot userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(data['userId'])
            .get();
        if (userDoc.exists) {
          details['customerName'] =
              (userDoc.data() as Map<String, dynamic>)['fullName'] ?? 'Unknown';
        }
      }

      if (data['handymanId'] != null) {
        DocumentSnapshot handymanDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(data['handymanId'])
            .get();
        if (handymanDoc.exists) {
          details['handymanName'] =
              (handymanDoc.data() as Map<String, dynamic>)['fullName'] ??
                  'Unknown';
        }
      }
    } catch (e) {
      print('Error getting transaction details: $e');
    }

    return details;
  }

  Widget _buildCommissionTab() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Current Commission Rate',
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
                        child: Text(
                          '${_currentCommissionRate.toStringAsFixed(1)}%',
                          style: const TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF4169E1),
                          ),
                        ),
                      ),
                      ElevatedButton(
                        onPressed: _showUpdateCommissionDialog,
                        child: const Text('Update'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  const Text(
                    'This percentage will be charged on all completed bookings.',
                    style: TextStyle(
                      fontSize: 14,
                      color: Color(0xFF7F8C8D),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          const Text(
            'Commission History',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2C3E50),
            ),
          ),
          const SizedBox(height: 16),

          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('commission_history')
                  .orderBy('changedAt', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(
                    child: Text('No commission history'),
                  );
                }

                return ListView.builder(
                  itemCount: snapshot.data!.docs.length,
                  itemBuilder: (context, index) {
                    Map<String, dynamic> data = snapshot.data!.docs[index]
                        .data() as Map<String, dynamic>;

                    return Card(
                      child: ListTile(
                        leading: const Icon(Icons.percent,
                            color: Color(0xFF4169E1)),
                        title: Text(
                            '${data['oldRate']}% → ${data['newRate']}%'),
                        subtitle: Text(_formatDate(data['changedAt'])),
                        trailing: Text(
                          'Admin',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _showUpdateCommissionDialog() {
    final TextEditingController rateController = TextEditingController(
      text: _currentCommissionRate.toString(),
    );

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Update Commission Rate'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: rateController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Commission Rate (%)',
                  border: OutlineInputBorder(),
                  suffixText: '%',
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'This will affect all future bookings. Existing bookings will retain their original commission rate.',
                style: TextStyle(
                  fontSize: 12,
                  color: Color(0xFF7F8C8D),
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
              onPressed: () {
                double newRate = double.tryParse(rateController.text) ??
                    _currentCommissionRate;
                _updateCommissionRate(newRate);
                Navigator.pop(context);
              },
              child: const Text('Update'),
            ),
          ],
        );
      },
    );
  }

  void _updateCommissionRate(double newRate) {
    // Save commission history
    FirebaseFirestore.instance.collection('commission_history').add({
      'oldRate': _currentCommissionRate,
      'newRate': newRate,
      'changedAt': FieldValue.serverTimestamp(),
      'changedBy': 'admin', // Replace with actual admin ID
    });

    // Update current rate
    FirebaseFirestore.instance.collection('settings').doc('commission').set({
      'rate': newRate,
      'updatedAt': FieldValue.serverTimestamp(),
    }).then((_) {
      setState(() {
        _currentCommissionRate = newRate;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Commission rate updated successfully')),
      );
    }).catchError((error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating commission rate: $error')),
      );
    });
  }

  String _formatDate(dynamic timestamp) {
    if (timestamp == null) return 'No date';

    DateTime date;
    if (timestamp is Timestamp) {
      date = timestamp.toDate();
    } else {
      return 'Invalid date';
    }

    return '${date.day}/${date.month}/${date.year}';
  }
}
