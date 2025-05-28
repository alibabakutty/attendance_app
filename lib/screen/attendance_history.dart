import 'package:attendance_app/modals/mark_attendance_data.dart';
import 'package:attendance_app/service/firebase_service.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class AttendanceHistory extends StatefulWidget {
  const AttendanceHistory({super.key});

  @override
  State<AttendanceHistory> createState() => _AttendanceHistoryState();
}

class _AttendanceHistoryState extends State<AttendanceHistory> {
  final FirebaseService _firebaseService = FirebaseService();
  final _employeeNameController = TextEditingController();
  final _employeeIdController = TextEditingController();
  final _employeeMobileNumberController = TextEditingController();

  DateTime? _startDate;
  DateTime? _endDate;
  DateTime? _specificDate;
  String _searchType = 'date';
  bool _isLoading = false;
  bool _hasSearched = false;
  List<MarkAttendanceData> _attendanceList = [];
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _employeeNameController.addListener(() => setState(() {}));
    _employeeIdController.addListener(() => setState(() {}));
    _employeeMobileNumberController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _employeeNameController.dispose();
    _employeeIdController.dispose();
    _employeeMobileNumberController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context,
      {bool isStartDate = false,
      bool isEndDate = false,
      bool isSpecificDate = false}) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: isSpecificDate
          ? _specificDate ?? DateTime.now()
          : isStartDate
              ? _startDate ?? DateTime.now()
              : _endDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        if (isSpecificDate) {
          _specificDate = picked;
        } else if (isStartDate) {
          _startDate = picked;
        } else {
          _endDate = picked;
        }
      });
    }
  }

  Future<void> _searchAttendanceHistories() async {
    setState(() {
      _isLoading = true;
      _hasSearched = true;
      _errorMessage = '';
      _attendanceList.clear();
    });

    try {
      List<MarkAttendanceData> results = [];

      if (_searchType == 'date') {
        if (_specificDate != null) {
          results = await _searchBySpecificDate(_specificDate!);
        } else if (_startDate != null && _endDate != null) {
          results = await _searchByDateRange(_startDate!, _endDate!);
        }
      } else if (_searchType == 'name' &&
          _employeeNameController.text.isNotEmpty) {
        results =
            await _searchByEmployeeName(_employeeNameController.text.trim());
      } else if (_searchType == 'id' && _employeeIdController.text.isNotEmpty) {
        results = await _searchByEmployeeId(_employeeIdController.text.trim());
      } else if (_searchType == 'mobile' &&
          _employeeMobileNumberController.text.isNotEmpty) {
        results = await _searchByMobileNumber(
            _employeeMobileNumberController.text.trim());
      }

      setState(() {
        _attendanceList = results;
        if (results.isEmpty) {
          _errorMessage = 'No attendance records found';
        }
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Error searching attendance: ${e.toString()}';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<List<MarkAttendanceData>> _searchBySpecificDate(DateTime date) async {
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = DateTime(date.year, date.month, date.day, 23, 59, 59);

    final snapshot = await _firebaseService.getAllMarkAttendanceData();
    return snapshot.where((record) {
      final recordDate = record.attendanceDate.toDate();
      return recordDate.isAfter(startOfDay) && recordDate.isBefore(endOfDay);
    }).toList();
  }

  Future<List<MarkAttendanceData>> _searchByDateRange(
      DateTime start, DateTime end) async {
    final startDate = DateTime(start.year, start.month, start.day);
    final endDate = DateTime(end.year, end.month, end.day, 23, 59, 59);

    final snapshot = await _firebaseService.getAllMarkAttendanceData();
    return snapshot.where((record) {
      final recordDate = record.attendanceDate.toDate();
      return recordDate.isAfter(startDate) && recordDate.isBefore(endDate);
    }).toList();
  }

  Future<List<MarkAttendanceData>> _searchByEmployeeName(String name) async {
    final snapshot = await _firebaseService.getAllMarkAttendanceData();
    return snapshot.where((record) {
      return record.employeeName.toLowerCase().contains(name.toLowerCase());
    }).toList();
  }

  Future<List<MarkAttendanceData>> _searchByEmployeeId(String id) async {
    final snapshot = await _firebaseService.getAllMarkAttendanceData();
    return snapshot.where((record) {
      return record.employeeId.toLowerCase().contains(id.toLowerCase());
    }).toList();
  }

  Future<List<MarkAttendanceData>> _searchByMobileNumber(String mobile) async {
    final snapshot = await _firebaseService.getAllMarkAttendanceData();
    return snapshot.where((record) {
      return record.mobileNumber?.contains(mobile) ?? false;
    }).toList();
  }

  Widget _buildSearchTypeSelector() {
    return DropdownButtonFormField<String>(
      value: _searchType,
      decoration: const InputDecoration(
        labelText: 'Search By',
        border: OutlineInputBorder(),
      ),
      items: const [
        DropdownMenuItem(value: 'date', child: Text('Date')),
        DropdownMenuItem(value: 'name', child: Text('Employee Name')),
        DropdownMenuItem(value: 'id', child: Text('Employee ID')),
        DropdownMenuItem(value: 'mobile', child: Text('Mobile Number')),
      ],
      onChanged: (value) {
        setState(() {
          _searchType = value!;
          _hasSearched = false;
          _attendanceList.clear();
          _errorMessage = '';
        });
      },
    );
  }

  Widget _buildDateSearchOptions() {
    return Column(
      children: [
        RadioListTile(
          title: const Text('Specific Date'),
          value: 'specific',
          groupValue: _specificDate != null ? 'specific' : 'range',
          onChanged: (value) {
            setState(() {
              _startDate = null;
              _endDate = null;
            });
          },
        ),
        if (_specificDate != null || (_startDate == null && _endDate == null))
          _buildSpecificDateSelector(),
        RadioListTile(
          title: const Text('Date Range'),
          value: 'range',
          groupValue:
              _startDate != null || _endDate != null ? 'range' : 'specific',
          onChanged: (value) {
            setState(() {
              _specificDate = null;
            });
          },
        ),
        if (_startDate != null || _endDate != null || _specificDate == null)
          _buildDateRangeSelector(),
      ],
    );
  }

  Widget _buildDateRangeSelector() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: InkWell(
                onTap: () => _selectDate(context, isStartDate: true),
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Start Date',
                    border: OutlineInputBorder(),
                  ),
                  child: Text(
                    _startDate != null
                        ? DateFormat('dd-MM-yyyy').format(_startDate!)
                        : 'Select start date',
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: InkWell(
                onTap: () => _selectDate(context, isEndDate: true),
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'End Date',
                    border: OutlineInputBorder(),
                  ),
                  child: Text(
                    _endDate != null
                        ? DateFormat('dd-MM-yyyy').format(_endDate!)
                        : 'Select end date',
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        ElevatedButton(
          onPressed: (_startDate != null && _endDate != null)
              ? _searchAttendanceHistories
              : null,
          child: const Text('Search by Date Range'),
        ),
      ],
    );
  }

  Widget _buildSpecificDateSelector() {
    return Column(
      children: [
        InkWell(
          onTap: () => _selectDate(context, isSpecificDate: true),
          child: InputDecorator(
            decoration: const InputDecoration(
              labelText: 'Select Date',
              border: OutlineInputBorder(),
            ),
            child: Text(
              _specificDate != null
                  ? DateFormat('dd-MM-yyyy').format(_specificDate!)
                  : 'Select a date',
            ),
          ),
        ),
        const SizedBox(height: 16),
        ElevatedButton(
          onPressed: _specificDate != null ? _searchAttendanceHistories : null,
          child: const Text('Search by Specific Date'),
        ),
      ],
    );
  }

  Widget _buildNameSearchField() {
    return Column(
      children: [
        TextFormField(
          controller: _employeeNameController,
          decoration: const InputDecoration(
            labelText: 'Employee Name',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 16),
        ElevatedButton(
          onPressed: _employeeNameController.text.isNotEmpty
              ? _searchAttendanceHistories
              : null,
          child: const Text('Search by Name'),
        ),
      ],
    );
  }

  Widget _buildIdSearchField() {
    return Column(
      children: [
        TextFormField(
          controller: _employeeIdController,
          decoration: const InputDecoration(
            labelText: 'Employee ID',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 16),
        ElevatedButton(
          onPressed: _employeeIdController.text.isNotEmpty
              ? _searchAttendanceHistories
              : null,
          child: const Text('Search by ID'),
        ),
      ],
    );
  }

  Widget _buildMobileSearchField() {
    return Column(
      children: [
        TextFormField(
          controller: _employeeMobileNumberController,
          decoration: const InputDecoration(
            labelText: 'Mobile Number',
            border: OutlineInputBorder(),
          ),
          keyboardType: TextInputType.phone,
        ),
        const SizedBox(height: 16),
        ElevatedButton(
          onPressed: _employeeMobileNumberController.text.isNotEmpty
              ? _searchAttendanceHistories
              : null,
          child: const Text('Search by Mobile'),
        ),
      ],
    );
  }

  Widget _buildSearchResults() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (!_hasSearched) {
      return const Center(
        child: Text('Please perform a search to view attendance records'),
      );
    }

    if (_errorMessage.isNotEmpty) {
      return Center(child: Text(_errorMessage));
    }

    if (_attendanceList.isEmpty) {
      return const Center(child: Text('No attendance records found'));
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _attendanceList.length,
      itemBuilder: (context, index) {
        final attendance = _attendanceList[index];
        final attendanceDate = attendance.attendanceDate.toDate();

        return Card(
          margin: const EdgeInsets.symmetric(vertical: 8),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  attendance.employeeName,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                Text('ID: ${attendance.employeeId}'),
                Text(
                    'Date: ${DateFormat('dd-MM-yyyy').format(attendanceDate)}'),
                const SizedBox(height: 8),
                if (attendance.officeTimeIn != null)
                  Text(
                      'Check-in: ${DateFormat('HH:mm').format(attendance.officeTimeIn!.toDate())}'),
                if (attendance.officeTimeOut != null)
                  Text(
                      'Check-out: ${DateFormat('HH:mm').format(attendance.officeTimeOut!.toDate())}'),
                if (attendance.lunchTimeStart != null)
                  Text(
                      'Lunch Start: ${DateFormat('HH:mm').format(attendance.lunchTimeStart!.toDate())}'),
                if (attendance.lunchTimeEnd != null)
                  Text(
                      'Lunch End: ${DateFormat('HH:mm').format(attendance.lunchTimeEnd!.toDate())}'),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Attendance History'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildSearchTypeSelector(),
            const SizedBox(height: 20),
            if (_searchType == 'date') _buildDateSearchOptions(),
            if (_searchType == 'name') _buildNameSearchField(),
            if (_searchType == 'id') _buildIdSearchField(),
            if (_searchType == 'mobile') _buildMobileSearchField(),
            const SizedBox(height: 20),
            const Divider(),
            const SizedBox(height: 20),
            Text(
              'Search Results',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 10),
            _buildSearchResults(),
          ],
        ),
      ),
    );
  }
}
