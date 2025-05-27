import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';

class MarkAttendance extends StatefulWidget {
  const MarkAttendance({super.key});

  @override
  State<MarkAttendance> createState() => _MarkAttendanceState();
}

class _MarkAttendanceState extends State<MarkAttendance> {
  DateTime? _officeTimeIn;
  DateTime? _lunchTimeStart;
  DateTime? _lunchTimeEnd;
  DateTime? _officeTimeOut;
  bool _isSubmitted = false;
  Position? _currentPosition;
  String _locationError = '';

  Future<void> _getCurrentLocation() async {
    try {
      // Check if location permission is granted
      final status = await Permission.location.request();
      if (!status.isGranted) {
        setState(() {
          _locationError = 'Location permission denied';
        });
        return;
      }

      // Get current position
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      setState(() {
        _currentPosition = position;
        _locationError = '';
      });
    } catch (e) {
      setState(() {
        _locationError = 'Failed to get location: ${e.toString()}';
      });
    }
  }

  String _recordTime(DateTime? time) {
    if (time != null) {
      return DateFormat('hh:mm a').format(time);
    }
    return 'Pending';
  }

  String _getLocationText() {
    if (_currentPosition != null) {
      return 'Lat: ${_currentPosition!.latitude.toStringAsFixed(4)}, '
          'Lng: ${_currentPosition!.longitude.toStringAsFixed(4)}';
    }
    return 'Location not recorded';
  }

  Future<void> _handleAction(String actionType) async {
    await _getCurrentLocation(); // Get location first

    if (_currentPosition == null && _locationError.isEmpty) {
      // If location wasn't obtained but no error was set (user might have denied)
      setState(() {
        _locationError = 'Location is required for attendance';
      });
      return;
    }

    final now = DateTime.now();
    setState(() {
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
            if (_currentPosition != null)
              Text(_getLocationText(), style: const TextStyle(fontSize: 12)),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mark Attendance'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Today: ${DateFormat('dd MMMM yyyy').format(DateTime.now())}',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            if (_locationError.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Text(
                  _locationError,
                  style: const TextStyle(color: Colors.red),
                ),
              ),
            const SizedBox(height: 20),
            _buildTimeCard(
              icon: Icons.login,
              title: 'Office Time-In',
              time: _recordTime(_officeTimeIn),
              location: _officeTimeIn != null ? _getLocationText() : null,
              onPressed: _officeTimeIn == null
                  ? () => _handleAction('officeIn')
                  : null,
            ),
            _buildTimeCard(
              icon: Icons.restaurant,
              title: 'Lunch Time-Start',
              time: _recordTime(_lunchTimeStart),
              location: _lunchTimeStart != null ? _getLocationText() : null,
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
              location: _lunchTimeEnd != null ? _getLocationText() : null,
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
              location: _officeTimeOut != null ? _getLocationText() : null,
              onPressed: _officeTimeIn != null && _officeTimeOut == null
                  ? () => _handleAction('officeOut')
                  : null,
            ),
            const SizedBox(height: 30),
            if (_isSubmitted)
              const Center(
                child: Chip(
                  label: Text('Attendance Submitted'),
                  backgroundColor: Colors.green,
                  labelStyle: TextStyle(color: Colors.white),
                ),
              ),
          ],
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
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              children: [
                Icon(icon, size: 30, color: Colors.blue),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title,
                          style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 4),
                      Text(time, style: const TextStyle(fontSize: 16)),
                    ],
                  ),
                ),
                if (onPressed != null)
                  ElevatedButton(
                    onPressed: onPressed,
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
