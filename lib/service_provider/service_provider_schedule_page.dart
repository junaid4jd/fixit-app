import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:table_calendar/table_calendar.dart';
import '../services/auth_service.dart';

class ServiceProviderSchedulePage extends StatefulWidget {
  const ServiceProviderSchedulePage({super.key});

  @override
  State<ServiceProviderSchedulePage> createState() =>
      _ServiceProviderSchedulePageState();
}

class _ServiceProviderSchedulePageState
    extends State<ServiceProviderSchedulePage> {
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  Map<DateTime, List<Map<String, dynamic>>> _events = {};
  Map<String, bool> _availability = {};
  bool _isLoading = true;

  final AuthService _authService = AuthService();

  @override
  void initState() {
    super.initState();
    _selectedDay = DateTime.now();
    _loadBookings();
    _loadAvailability();
  }

  Future<void> _loadBookings() async {
    try {
      User? user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('bookings')
          .where('handyman_id', isEqualTo: user.uid)
          .where('status', whereIn: ['accepted', 'in_progress', 'completed'])
          .get();

      Map<DateTime, List<Map<String, dynamic>>> events = {};

      for (var doc in snapshot.docs) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

        if (data['scheduled_date'] != null) {
          DateTime date = (data['scheduled_date'] as Timestamp).toDate();
          DateTime normalizedDate = DateTime(date.year, date.month, date.day);

          if (events[normalizedDate] == null) {
            events[normalizedDate] = [];
          }

          // Get user data for each booking
          String? userId = data['user_id'];
          String clientName = 'Unknown Client';
          if (userId != null) {
            try {
              final userData = await _authService.getUserData(userId);
              clientName = userData?['fullName'] ?? 'Unknown Client';
            } catch (e) {
              // Keep default name if error
            }
          }

          events[normalizedDate]!.add({
            'id': doc.id,
            'client_name': clientName,
            ...data,
          });
        }
      }

      if (mounted) {
        setState(() {
          _events = events;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading schedule: $e')),
        );
      }
    }
  }

  Future<void> _loadAvailability() async {
    try {
      User? user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      DocumentSnapshot doc = await FirebaseFirestore.instance
          .collection('handyman_availability')
          .doc(user.uid)
          .get();

      if (doc.exists) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        if (mounted) {
          setState(() {
            _availability = Map<String, bool>.from(data['availability'] ?? {});
          });
        }
      }
    } catch (e) {
      debugPrint('Error loading availability: $e');
    }
  }

  Future<void> _saveAvailability() async {
    try {
      User? user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      await FirebaseFirestore.instance
          .collection('handyman_availability')
          .doc(user.uid)
          .set({
        'availability': _availability,
        'updated_at': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Availability updated successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating availability: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  List<Map<String, dynamic>> _getEventsForDay(DateTime day) {
    DateTime normalizedDay = DateTime(day.year, day.month, day.day);
    return _events[normalizedDay] ?? [];
  }

  bool _isAvailableDay(DateTime day) {
    String dayKey = '${day.year}-${day.month.toString().padLeft(2, '0')}-${day
        .day.toString().padLeft(2, '0')}';
    return _availability[dayKey] ?? true; // Default to available
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'My Schedule',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF2C3E50),
        elevation: 0,
        actions: [
          IconButton(
            onPressed: _loadBookings,
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
          ),
          IconButton(
            onPressed: _showStatistics,
            icon: const Icon(Icons.analytics),
            tooltip: 'Statistics',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
        children: [
          Container(
            color: Colors.white,
            child: TableCalendar<Map<String, dynamic>>(
              firstDay: DateTime.utc(2020, 1, 1),
              lastDay: DateTime.utc(2030, 12, 31),
              focusedDay: _focusedDay,
              calendarFormat: _calendarFormat,
              eventLoader: _getEventsForDay,
              startingDayOfWeek: StartingDayOfWeek.monday,
              selectedDayPredicate: (day) {
                return isSameDay(_selectedDay, day);
              },
              onDaySelected: (selectedDay, focusedDay) {
                if (!isSameDay(_selectedDay, selectedDay)) {
                  setState(() {
                    _selectedDay = selectedDay;
                    _focusedDay = focusedDay;
                  });
                }
              },
              onFormatChanged: (format) {
                if (_calendarFormat != format) {
                  setState(() {
                    _calendarFormat = format;
                  });
                }
              },
              onPageChanged: (focusedDay) {
                _focusedDay = focusedDay;
              },
              calendarBuilders: CalendarBuilders(
                defaultBuilder: (context, day, focusedDay) {
                  if (!_isAvailableDay(day)) {
                    return Container(
                      margin: const EdgeInsets.all(4.0),
                      decoration: BoxDecoration(
                        color: Colors.red.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8.0),
                        border: Border.all(color: Colors.red.withValues(
                            alpha: 0.3)),
                      ),
                      child: Center(
                        child: Text(
                          '${day.day}',
                          style: const TextStyle(color: Colors.red),
                        ),
                      ),
                    );
                  }
                  return null;
                },
              ),
              calendarStyle: const CalendarStyle(
                outsideDaysVisible: false,
                selectedDecoration: BoxDecoration(
                  color: Color(0xFF4169E1),
                  shape: BoxShape.circle,
                ),
                todayDecoration: BoxDecoration(
                  color: Color(0xFF34495E),
                  shape: BoxShape.circle,
                ),
                markerDecoration: BoxDecoration(
                  color: Color(0xFFE74C3C),
                  shape: BoxShape.circle,
                ),
              ),
              headerStyle: const HeaderStyle(
                formatButtonVisible: true,
                titleCentered: true,
                formatButtonShowsNext: false,
                formatButtonDecoration: BoxDecoration(
                  color: Color(0xFF4169E1),
                  borderRadius: BorderRadius.all(Radius.circular(12.0)),
                ),
                formatButtonTextStyle: TextStyle(
                  color: Colors.white,
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: _buildEventsList(),
          ),
        ],
      ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton(
            onPressed: _showAvailabilityDialog,
            backgroundColor: const Color(0xFF4169E1),
            heroTag: "availability",
            child: const Icon(Icons.schedule, color: Colors.white),
          ),
          const SizedBox(height: 16),
          FloatingActionButton(
            onPressed: _showTimeSlotDialog,
            backgroundColor: const Color(0xFF27AE60),
            heroTag: "timeslots",
            child: const Icon(Icons.access_time, color: Colors.white),
          ),
        ],
      ),
    );
  }

  Widget _buildEventsList() {
    List<Map<String, dynamic>> events = _getEventsForDay(
        _selectedDay ?? DateTime.now());

    if (events.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.event_available,
              size: 80,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'No bookings for this day',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _isAvailableDay(_selectedDay ?? DateTime.now())
                  ? 'You\'re available for new bookings!'
                  : 'You\'re marked as unavailable',
              style: TextStyle(
                fontSize: 14,
                color: _isAvailableDay(_selectedDay ?? DateTime.now())
                    ? Colors.green[600]
                    : Colors.red[600],
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: events.length,
      itemBuilder: (context, index) {
        return _buildEventCard(events[index]);
      },
    );
  }

  Widget _buildEventCard(Map<String, dynamic> event) {
    String status = event['status'] ?? 'unknown';
    Color statusColor = _getStatusColor(status);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () => _showBookingDetails(event),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 4,
                    height: 40,
                    decoration: BoxDecoration(
                      color: statusColor,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              event['scheduled_time'] ?? 'No time',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF2C3E50),
                              ),
                            ),
                            const Spacer(),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: statusColor.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                _getStatusLabel(status),
                                style: TextStyle(
                                  color: statusColor,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          event['category'] ?? 'Service',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF4169E1),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  const Icon(Icons.person, size: 16, color: Color(0xFF7F8C8D)),
                  const SizedBox(width: 8),
                  Text(
                    event['client_name'] ?? 'Unknown Client',
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFF7F8C8D),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(
                      Icons.location_on, size: 16, color: Color(0xFF7F8C8D)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      event['address'] ?? 'No address provided',
                      style: const TextStyle(
                        fontSize: 14,
                        color: Color(0xFF7F8C8D),
                      ),
                    ),
                  ),
                  Text(
                    '${event['estimated_cost'] ?? 0} OMR',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF27AE60),
                    ),
                  ),
                ],
              ),
              if (event['description'] != null) ...[
                const SizedBox(height: 8),
                Text(
                  event['description'],
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF7F8C8D),
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'accepted':
        return const Color(0xFF3498DB);
      case 'in_progress':
        return const Color(0xFF2ECC71);
      case 'completed':
        return const Color(0xFF95A5A6);
      case 'cancelled':
        return const Color(0xFFE74C3C);
      default:
        return const Color(0xFF7F8C8D);
    }
  }

  String _getStatusLabel(String status) {
    switch (status) {
      case 'accepted':
        return 'Scheduled';
      case 'in_progress':
        return 'In Progress';
      case 'completed':
        return 'Completed';
      case 'cancelled':
        return 'Cancelled';
      default:
        return status;
    }
  }

  void _showAvailabilityDialog() {
    final now = DateTime.now();
    final thirtyDaysFromNow = now.add(const Duration(days: 30));

    showDialog(
      context: context,
      builder: (context) =>
          StatefulBuilder(
            builder: (context, setDialogState) =>
                AlertDialog(
                  title: const Text('Set Availability'),
                  content: SizedBox(
                    width: double.maxFinite,
                    height: 400,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Manage your availability for the next 30 days',
                  style: TextStyle(
                    fontSize: 14,
                    color: Color(0xFF7F8C8D),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          setDialogState(() {
                            // Mark all days as available
                            for (int i = 0; i < 30; i++) {
                              final date = now.add(Duration(days: i));
                              final dayKey = '${date.year}-${date.month
                                  .toString().padLeft(2, '0')}-${date.day
                                  .toString().padLeft(2, '0')}';
                              _availability[dayKey] = true;
                            }
                          });
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                        ),
                        child: const Text('Mark All Available'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          setDialogState(() {
                            // Mark all days as unavailable
                            for (int i = 0; i < 30; i++) {
                              final date = now.add(Duration(days: i));
                              final dayKey = '${date.year}-${date.month
                                  .toString().padLeft(2, '0')}-${date.day
                                  .toString().padLeft(2, '0')}';
                              _availability[dayKey] = false;
                            }
                          });
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                        ),
                        child: const Text('Mark All Unavailable'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: ListView.builder(
                    itemCount: 30,
                    itemBuilder: (context, index) {
                      final date = now.add(Duration(days: index));
                      final dayKey = '${date.year}-${date.month
                          .toString()
                          .padLeft(2, '0')}-${date.day.toString().padLeft(
                          2, '0')}';
                      final isAvailable = _availability[dayKey] ?? true;
                      final dayName = [
                        'Mon',
                        'Tue',
                        'Wed',
                        'Thu',
                        'Fri',
                        'Sat',
                        'Sun'
                      ][date.weekday - 1];

                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: SwitchListTile(
                          title: Text(
                              '$dayName, ${date.day}/${date.month}/${date
                                  .year}'),
                          subtitle: Text(
                              isAvailable ? 'Available' : 'Unavailable'),
                          value: isAvailable,
                          activeColor: Colors.green,
                          onChanged: (value) {
                            setDialogState(() {
                              _availability[dayKey] = value;
                            });
                          },
                        ),
                      );
                    },
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
                _saveAvailability();
                Navigator.pop(context);
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  void _showTimeSlotDialog() {
    showDialog(
      context: context,
      builder: (context) =>
          AlertDialog(
            title: const Text('Time Slot Management'),
            content: const Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.access_time,
                  size: 64,
                  color: Color(0xFF4169E1),
                ),
                SizedBox(height: 16),
                Text(
                  'Time Slot Management',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Custom time slot management will be available in future updates. Currently using standard 9 AM - 6 PM working hours.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: Color(0xFF7F8C8D),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'),
              ),
            ],
          ),
    );
  }

  void _showBookingDetails(Map<String, dynamic> event) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) =>
          Container(
            padding: const EdgeInsets.all(24),
            constraints: BoxConstraints(
              maxHeight: MediaQuery
                  .of(context)
                  .size
                  .height * 0.8,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Booking Details',
                        style: TextStyle(
                          fontSize: 20,
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
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildDetailItem('Service', event['category'] ?? 'N/A'),
                        _buildDetailItem(
                            'Description', event['description'] ?? 'N/A'),
                        _buildDetailItem(
                            'Client', event['client_name'] ?? 'Unknown Client'),
                        _buildDetailItem(
                            'Date', _formatEventDate(event['scheduled_date'])),
                        _buildDetailItem(
                            'Time', event['scheduled_time'] ?? 'N/A'),
                        _buildDetailItem('Address', event['address'] ?? 'N/A'),
                        _buildDetailItem(
                            'Phone', event['phone_number'] ?? 'N/A'),
                        _buildDetailItem('Status',
                            _getStatusLabel(event['status'] ?? 'unknown')),
                        _buildDetailItem(
                            'Cost', '${event['estimated_cost'] ?? 0} OMR'),

                        if (event['special_instructions'] != null &&
                            event['special_instructions']
                                .toString()
                                .isNotEmpty) ...[
                          const SizedBox(height: 16),
                          const Text(
                            'Special Instructions',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.blue[50],
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.blue[200]!),
                            ),
                            child: Text(
                              event['special_instructions'],
                              style: const TextStyle(
                                fontSize: 14,
                                color: Color(0xFF2C3E50),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
    );
  }

  Widget _buildDetailItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
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

  String _formatEventDate(dynamic timestamp) {
    if (timestamp == null) return 'No date';

    DateTime date;
    if (timestamp is Timestamp) {
      date = timestamp.toDate();
    } else {
      return 'Invalid date';
    }

    return '${date.day}/${date.month}/${date.year}';
  }

  void _showStatistics() {
    showDialog(
      context: context,
      builder: (context) =>
          AlertDialog(
            title: const Text('Schedule Statistics'),
            content: FutureBuilder<Map<String, int>>(
              future: _calculateStatistics(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const SizedBox(
                    height: 200,
                    child: Center(child: CircularProgressIndicator()),
                  );
                }

                if (snapshot.hasError) {
                  return const SizedBox(
                    height: 200,
                    child: Center(child: Text('Error loading statistics')),
                  );
                }

                final stats = snapshot.data ?? {};

                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildStatItem('Total Bookings', stats['total'] ?? 0),
                    _buildStatItem('This Month', stats['thisMonth'] ?? 0),
                    _buildStatItem('This Week', stats['thisWeek'] ?? 0),
                    _buildStatItem('Today', stats['today'] ?? 0),
                    _buildStatItem('Completed', stats['completed'] ?? 0),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF4169E1).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.trending_up,
                            color: Color(0xFF4169E1),
                          ),
                          const SizedBox(width: 8),
                          const Expanded(
                            child: Text(
                              'Keep up the great work!',
                              style: TextStyle(
                                fontWeight: FontWeight.w500,
                                color: Color(0xFF4169E1),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Close'),
              ),
            ],
          ),
    );
  }

  Widget _buildStatItem(String label, int value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF7F8C8D),
            ),
          ),
          Text(
            value.toString(),
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2C3E50),
            ),
          ),
        ],
      ),
    );
  }

  Future<Map<String, int>> _calculateStatistics() async {
    try {
      User? user = FirebaseAuth.instance.currentUser;
      if (user == null) return {};

      final now = DateTime.now();
      final startOfMonth = DateTime(now.year, now.month, 1);
      final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
      final startOfToday = DateTime(now.year, now.month, now.day);

      QuerySnapshot allBookings = await FirebaseFirestore.instance
          .collection('bookings')
          .where('handyman_id', isEqualTo: user.uid)
          .get();

      int total = allBookings.docs.length;
      int thisMonth = 0;
      int thisWeek = 0;
      int today = 0;
      int completed = 0;

      for (var doc in allBookings.docs) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

        if (data['status'] == 'completed') {
          completed++;
        }

        if (data['scheduled_date'] != null) {
          DateTime scheduledDate = (data['scheduled_date'] as Timestamp)
              .toDate();

          if (scheduledDate.isAfter(startOfMonth)) {
            thisMonth++;
          }

          if (scheduledDate.isAfter(startOfWeek)) {
            thisWeek++;
          }

          if (scheduledDate.isAfter(startOfToday) &&
              scheduledDate.isBefore(
                  startOfToday.add(const Duration(days: 1)))) {
            today++;
          }
        }
      }

      return {
        'total': total,
        'thisMonth': thisMonth,
        'thisWeek': thisWeek,
        'today': today,
        'completed': completed,
      };
    } catch (e) {
      debugPrint('Error calculating statistics: $e');
      return {};
    }
  }
}
