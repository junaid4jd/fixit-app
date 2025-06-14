import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';

class BookingTestScreen extends StatefulWidget {
  const BookingTestScreen({super.key});

  @override
  State<BookingTestScreen> createState() => _BookingTestScreenState();
}

class _BookingTestScreenState extends State<BookingTestScreen> {
  final AuthService _authService = AuthService();
  String _testResults = '';
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Booking System Test'),
        backgroundColor: const Color(0xFF4169E1),
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Current User Info
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Current User Status',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF2C3E50),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text('User ID: ${_authService.currentUserId ??
                        'Not logged in'}'),
                    Text('Is Logged In: ${_authService.isLoggedIn}'),
                    if (_authService.currentUser != null)
                      Text('Email: ${_authService.currentUser!.email}'),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Test Buttons
            ElevatedButton(
              onPressed: _isLoading ? null : _testBookingRetrieval,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4169E1),
                foregroundColor: Colors.white,
              ),
              child: _isLoading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text('Test Booking Retrieval'),
            ),

            const SizedBox(height: 8),

            ElevatedButton(
              onPressed: _isLoading ? null : _testCreateTestBooking,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
              ),
              child: const Text('Create Test Booking'),
            ),

            const SizedBox(height: 8),

            ElevatedButton(
              onPressed: _clearResults,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.grey,
                foregroundColor: Colors.white,
              ),
              child: const Text('Clear Results'),
            ),

            const SizedBox(height: 16),

            // Results
            Expanded(
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Test Results',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF2C3E50),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(_testResults.isEmpty
                            ? 'No tests run yet'
                            : _testResults),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _testBookingRetrieval() async {
    setState(() {
      _isLoading = true;
      _testResults += '\n--- TESTING BOOKING RETRIEVAL ---\n';
    });

    try {
      final currentUserId = _authService.currentUserId;
      if (currentUserId == null) {
        setState(() {
          _testResults += '❌ ERROR: User not logged in\n';
        });
        return;
      }

      setState(() {
        _testResults += '✅ User logged in: $currentUserId\n';
      });

      // Test getUserBookings
      final bookings = await _authService.getUserBookings(currentUserId);
      setState(() {
        _testResults += '✅ Retrieved ${bookings.length} bookings\n';
      });

      for (int i = 0; i < bookings.length && i < 3; i++) {
        final booking = bookings[i];
        setState(() {
          _testResults += '  Booking ${i + 1}:\n';
          _testResults += '    ID: ${booking['id']}\n';
          _testResults += '    Status: ${booking['status']}\n';
          _testResults += '    Category: ${booking['category']}\n';
          _testResults += '    Handyman ID: ${booking['handyman_id']}\n';
          _testResults += '    Created: ${booking['created_at']}\n';
        });
      }

      if (bookings.length > 3) {
        setState(() {
          _testResults += '  ... and ${bookings.length - 3} more bookings\n';
        });
      }
    } catch (e) {
      setState(() {
        _testResults += '❌ ERROR retrieving bookings: $e\n';
      });
    } finally {
      setState(() {
        _isLoading = false;
        _testResults += '--- END BOOKING RETRIEVAL TEST ---\n\n';
      });
    }
  }

  Future<void> _testCreateTestBooking() async {
    setState(() {
      _isLoading = true;
      _testResults += '\n--- TESTING BOOKING CREATION ---\n';
    });

    try {
      final currentUserId = _authService.currentUserId;
      if (currentUserId == null) {
        setState(() {
          _testResults += '❌ ERROR: User not logged in\n';
        });
        return;
      }

      setState(() {
        _testResults += '✅ User logged in: $currentUserId\n';
      });

      // Create a test booking
      final bookingId = await _authService.createBookingRequest(
        userId: currentUserId,
        handymanId: 'test_handyman_id',
        // This would be a real handyman ID in production
        category: 'Test Service',
        serviceDescription: 'This is a test booking created for debugging purposes.',
        scheduledDate: DateTime.now().add(const Duration(days: 1)),
        timeSlot: '10:00 - 12:00',
        estimatedCost: 25.0,
        address: 'Test Address, Muscat, Oman',
        contactInfo: {
          'phone': '+968 12345678',
          'notes': 'Test booking notes',
        },
      );

      setState(() {
        _testResults += '✅ Created test booking with ID: $bookingId\n';
      });

      // Try to retrieve it immediately
      await Future.delayed(const Duration(seconds: 2)); // Wait for Firestore

      final bookings = await _authService.getUserBookings(currentUserId);
      final testBooking = bookings.where((b) => b['id'] == bookingId).toList();

      if (testBooking.isNotEmpty) {
        setState(() {
          _testResults += '✅ Successfully retrieved the test booking\n';
          _testResults += '  Status: ${testBooking.first['status']}\n';
          _testResults +=
          '  Description: ${testBooking.first['description']}\n';
        });
      } else {
        setState(() {
          _testResults +=
          '⚠️  Test booking created but not found in user bookings\n';
        });
      }
    } catch (e) {
      setState(() {
        _testResults += '❌ ERROR creating test booking: $e\n';
      });
    } finally {
      setState(() {
        _isLoading = false;
        _testResults += '--- END BOOKING CREATION TEST ---\n\n';
      });
    }
  }

  void _clearResults() {
    setState(() {
      _testResults = '';
    });
  }
}