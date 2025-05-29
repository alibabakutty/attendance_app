import 'package:attendance_app/authentication/auth_provider.dart';
import 'package:attendance_app/modals/mark_attendance_data.dart';
import 'package:attendance_app/service/firebase_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';

class MarkAttendance extends StatefulWidget {
  const MarkAttendance({super.key});

  @override
  State<MarkAttendance> createState() => _MarkAttendanceState();
}

class _MarkAttendanceState extends State<MarkAttendance> {
  FirebaseService _firebaseService = FirebaseService();

  DateTime? _officeTimeIn;
  DateTime? _lunchTimeStart;
  DateTime? _lunchTimeEnd;
  DateTime? _officeTimeOut;
  bool _isSubmitted = false;
  String _locationError = '';

  final Map<String, Position?> _locationMap = {
    'officeIn': null,
    'lunchStart': null,
    'lunchEnd': null,
    'officeOut': null,
  };

  Future<Position?> _getCurrentLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        await Geolocator.openLocationSettings();
        setState(() {
          _locationError = 'Location services are disabled.';
        });
        return null;
      }

      PermissionStatus status = await Permission.location.status;

      if (status.isDenied ||
          status.isRestricted ||
          status.isPermanentlyDenied) {
        final newStatus = await Permission.location.request();

        if (newStatus.isPermanentlyDenied) {
          setState(() {
            _locationError =
                'Location permission permanently denied. Please enable it from settings.';
          });
          openAppSettings();
          return null;
        }

        if (!newStatus.isGranted) {
          setState(() {
            _locationError = 'Location permission denied.';
          });
          return null;
        }
      }

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      setState(() {
        _locationError = '';
      });

      return position;
    } catch (e) {
      setState(() {
        _locationError = 'Error getting location: $e';
      });
      return null;
    }
  }

  String _recordTime(DateTime? time) {
    return time != null ? DateFormat('hh:mm a').format(time) : 'Pending';
  }

  String _formatLocation(Position pos) {
    return 'Lat: ${pos.latitude.toStringAsFixed(4)}, Lng: ${pos.longitude.toStringAsFixed(4)}';
  }

  Future<void> _handleAction(String actionType) async {
    final position = await _getCurrentLocation();

    if (position == null) {
      if (_locationError.isEmpty) {
        setState(() {
          _locationError = 'Location is required for attendance';
        });
      }
      return;
    }

    final now = DateTime.now();
    setState(() {
      _locationMap[actionType] = position;

      switch (actionType) {
        case 'officeIn':
          _officeTimeIn = now;
          break;
        case 'lunchStart':
          _lunchTimeStart = now;
          break;
        case 'lunchEnd':
          _lunchTimeEnd = now;
          break;
        case 'officeOut':
          _officeTimeOut = now;
          _isSubmitted = true;
          break;
      }
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
                '$actionType recorded at ${DateFormat('hh:mm a').format(now)}'),
            Text(_formatLocation(position),
                style: const TextStyle(fontSize: 12)),
          ],
        ),
      ),
    );

    Future<void> _saveAttendanceToFirestore() async {
      try {
        final authProvider = Provider.of<AuthProvider>(context, listen: false);

        final markAttendanceData = MarkAttendanceData(
          employeeId:
              '${authProvider.employeeId}', // Replace with actual employee ID
          employeeName:
              '${authProvider.username}', // Replace with actual employee name
          mobileNumber:
              '${authProvider.mobileNumber}', // Replace with actual mobile number
          attendanceDate: Timestamp.fromDate(DateTime.now()),
          officeTimeIn: Timestamp.fromDate(_officeTimeIn!),
          officeTimeInLocation: GeoPoint(
            _locationMap['officeIn']!.latitude,
            _locationMap['officeIn']!.longitude,
          ),
          lunchTimeStart: _lunchTimeStart != null
              ? Timestamp.fromDate(_lunchTimeStart!)
              : null,
          lunchTimeStartLocation: _lunchTimeStart != null
              ? GeoPoint(
                  _locationMap['lunchStart']!.latitude,
                  _locationMap['lunchStart']!.longitude,
                )
              : GeoPoint(0, 0),
          lunchTimeEnd:
              _lunchTimeEnd != null ? Timestamp.fromDate(_lunchTimeEnd!) : null,
          lunchTimeEndLocation: _lunchTimeEnd != null
              ? GeoPoint(
                  _locationMap['lunchEnd']!.latitude,
                  _locationMap['lunchEnd']!.longitude,
                )
              : GeoPoint(0, 0),
          officeTimeOut: Timestamp.fromDate(_officeTimeOut!),
          officeTimeOutLocation: GeoPoint(
            _locationMap['officeOut']!.latitude,
            _locationMap['officeOut']!.longitude,
          ),
        );

        final success =
            await _firebaseService.addNewMarkAttendanceData(markAttendanceData);

        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Attendance saved successfully!')),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to save attendance.')),
          );
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }

    // if this is office out action, save to firestore
    if (actionType == 'officeOut') {
      await _saveAttendanceToFirestore();
    }
  }

  Future<void> _confirmOfficeOut() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Office Time-Out'),
        content: const Text('Are you sure you want to mark Office Time-Out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Yes'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _handleAction('officeOut');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mark Attendance',
            style: TextStyle(fontSize: 20, color: Colors.white)),
        backgroundColor: Color(0xFF0D47A1),
        centerTitle: true,
        elevation: 0,
      ),
      // Gradient background
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFF0D47A1),
              Color(0xFF1976D2),
              Color(0xFF42A5F5),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // App bar replacement with title & logout
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '',
                      style: Theme.of(context).textTheme.titleLarge!.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    // You can add logout/profile icon here if you want
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  'Today: ${DateFormat('dd MMMM yyyy').format(DateTime.now())}',
                  style: Theme.of(context).textTheme.titleMedium!.copyWith(
                        color: Colors.white70,
                      ),
                ),
                if (_locationError.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(
                      _locationError,
                      style: const TextStyle(color: Colors.redAccent),
                    ),
                  ),
                const SizedBox(height: 24),
                Expanded(
                  child: ListView(
                    children: [
                      _buildTimeCard(
                        icon: Icons.login,
                        title: 'Office Time-In',
                        time: _recordTime(_officeTimeIn),
                        location: _locationMap['officeIn'] != null
                            ? _formatLocation(_locationMap['officeIn']!)
                            : null,
                        onPressed: _officeTimeIn == null
                            ? () => _handleAction('officeIn')
                            : null,
                      ),
                      _buildTimeCard(
                        icon: Icons.restaurant,
                        title: 'Lunch Time-Start',
                        time: _recordTime(_lunchTimeStart),
                        location: _locationMap['lunchStart'] != null
                            ? _formatLocation(_locationMap['lunchStart']!)
                            : null,
                        onPressed: _officeTimeIn != null &&
                                _lunchTimeStart == null &&
                                _officeTimeOut == null
                            ? () => _handleAction('lunchStart')
                            : null,
                      ),
                      _buildTimeCard(
                        icon: Icons.restaurant_menu,
                        title: 'Lunch Time-End',
                        time: _recordTime(_lunchTimeEnd),
                        location: _locationMap['lunchEnd'] != null
                            ? _formatLocation(_locationMap['lunchEnd']!)
                            : null,
                        onPressed: _lunchTimeStart != null &&
                                _lunchTimeEnd == null &&
                                _officeTimeOut == null
                            ? () => _handleAction('lunchEnd')
                            : null,
                      ),
                      _buildTimeCard(
                        icon: Icons.logout,
                        title: 'Office Time-Out',
                        time: _recordTime(_officeTimeOut),
                        location: _locationMap['officeOut'] != null
                            ? _formatLocation(_locationMap['officeOut']!)
                            : null,
                        onPressed:
                            _officeTimeIn != null && _officeTimeOut == null
                                ? _confirmOfficeOut
                                : null,
                      ),
                      const SizedBox(height: 30),
                      if (_isSubmitted)
                        Center(
                          child: Chip(
                            label: const Text('Attendance Submitted'),
                            backgroundColor: Colors.green,
                            labelStyle: const TextStyle(color: Colors.white),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 20, vertical: 10),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTimeCard({
    required IconData icon,
    required String title,
    required String time,
    String? location,
    VoidCallback? onPressed,
  }) {
    return Card(
      elevation: 5,
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              children: [
                Icon(icon, size: 30, color: Colors.blue[700]),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: Colors.black87,
                          )),
                      const SizedBox(height: 4),
                      Text(time,
                          style: const TextStyle(
                            fontSize: 16,
                            color: Colors.black54,
                          )),
                    ],
                  ),
                ),
                if (onPressed != null)
                  ElevatedButton(
                    onPressed: onPressed,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue[700],
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                    ),
                    child: const Text('Mark'),
                  )
                else
                  const Icon(Icons.check_circle, color: Colors.green),
              ],
            ),
            if (location != null)
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Text(
                  location,
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
