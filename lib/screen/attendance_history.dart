import 'package:attendance_app/modals/mark_attendance_data.dart';
import 'package:attendance_app/service/firebase_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
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
      builder: (context, child) {
        // Light yellow background for date picker dialog as well
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: Colors.orange.shade700,
              onPrimary: Colors.white,
              onSurface: Colors.black87,
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: Colors.orange.shade700,
              ),
            ),
          ),
          child: child!,
        );
      },
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
      return !recordDate.isBefore(startOfDay) && !recordDate.isAfter(endOfDay);
    }).toList();
  }

  Future<List<MarkAttendanceData>> _searchByDateRange(
      DateTime start, DateTime end) async {
    final startDate = DateTime(start.year, start.month, start.day);
    final endDate = DateTime(end.year, end.month, end.day, 23, 59, 59);

    final snapshot = await _firebaseService.getAllMarkAttendanceData();
    return snapshot.where((record) {
      final recordDate = record.attendanceDate.toDate();
      return !recordDate.isBefore(startDate) && !recordDate.isAfter(endDate);
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
      decoration: InputDecoration(
        labelText: 'Search By',
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        filled: true,
        fillColor: Colors.white,
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
          // Clear inputs on search type change
          _employeeNameController.clear();
          _employeeIdController.clear();
          _employeeMobileNumberController.clear();
          _specificDate = null;
          _startDate = null;
          _endDate = null;
        });
      },
    );
  }

  Widget _buildDateSearchOptions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: RadioListTile<String>(
                contentPadding: EdgeInsets.zero,
                title: const Text('Specific Date'),
                value: 'specific',
                groupValue: _specificDate != null ||
                        (_startDate == null && _endDate == null)
                    ? 'specific'
                    : 'range',
                onChanged: (value) {
                  setState(() {
                    _startDate = null;
                    _endDate = null;
                    if (_specificDate == null) {
                      _specificDate = DateTime.now();
                    }
                  });
                },
              ),
            ),
            Expanded(
              child: RadioListTile<String>(
                contentPadding: EdgeInsets.zero,
                title: const Text('Date Range'),
                value: 'range',
                groupValue: _startDate != null || _endDate != null
                    ? 'range'
                    : 'specific',
                onChanged: (value) {
                  setState(() {
                    _specificDate = null;
                    if (_startDate == null) _startDate = DateTime.now();
                    if (_endDate == null) _endDate = DateTime.now();
                  });
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (_specificDate != null) _buildSpecificDateSelector(),
        if (_startDate != null && _endDate != null) _buildDateRangeSelector(),
      ],
    );
  }

  Widget _buildDateRangeSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: InkWell(
                borderRadius: BorderRadius.circular(8),
                onTap: () => _selectDate(context, isStartDate: true),
                child: InputDecorator(
                  decoration: InputDecoration(
                    labelText: 'Start Date',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                  child: Text(
                    _startDate != null
                        ? DateFormat('dd-MM-yyyy').format(_startDate!)
                        : 'Select start date',
                    style: TextStyle(
                      color: _startDate != null
                          ? Colors.black87
                          : Colors.grey[600],
                      fontWeight: _startDate != null
                          ? FontWeight.w600
                          : FontWeight.normal,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: InkWell(
                borderRadius: BorderRadius.circular(8),
                onTap: () => _selectDate(context, isEndDate: true),
                child: InputDecorator(
                  decoration: InputDecoration(
                    labelText: 'End Date',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                  child: Text(
                    _endDate != null
                        ? DateFormat('dd-MM-yyyy').format(_endDate!)
                        : 'Select end date',
                    style: TextStyle(
                      color:
                          _endDate != null ? Colors.black87 : Colors.grey[600],
                      fontWeight: _endDate != null
                          ? FontWeight.w600
                          : FontWeight.normal,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: (_startDate != null && _endDate != null)
                ? _searchAttendanceHistories
                : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange.shade700,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text(
              'Search by Date Range',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSpecificDateSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: () => _selectDate(context, isSpecificDate: true),
          child: InputDecorator(
            decoration: InputDecoration(
              labelText: 'Select Date',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              filled: true,
              fillColor: Colors.white,
            ),
            child: Text(
              _specificDate != null
                  ? DateFormat('dd-MM-yyyy').format(_specificDate!)
                  : 'Select a date',
              style: TextStyle(
                color:
                    _specificDate != null ? Colors.black87 : Colors.grey[600],
                fontWeight:
                    _specificDate != null ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ),
        ),
        const SizedBox(height: 20),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed:
                _specificDate != null ? _searchAttendanceHistories : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange.shade700,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text(
              'Search by Specific Date',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTextInputField(
      {required String label,
      required TextEditingController controller,
      TextInputType keyboardType = TextInputType.text,
      String? hintText}) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        hintText: hintText,
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        suffixIcon: controller.text.isNotEmpty
            ? IconButton(
                icon: const Icon(Icons.clear),
                onPressed: () => setState(() => controller.clear()),
              )
            : null,
      ),
    );
  }

  Widget _buildSearchInputFields() {
    switch (_searchType) {
      case 'name':
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildTextInputField(
              label: 'Employee Name',
              controller: _employeeNameController,
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _employeeNameController.text.trim().isNotEmpty
                    ? _searchAttendanceHistories
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange.shade700,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
                child: const Text(
                  'Search by Name',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ],
        );
      case 'id':
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildTextInputField(
              label: 'Employee ID',
              controller: _employeeIdController,
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _employeeIdController.text.trim().isNotEmpty
                    ? _searchAttendanceHistories
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange.shade700,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
                child: const Text(
                  'Search by ID',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ],
        );
      case 'mobile':
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildTextInputField(
              label: 'Mobile Number',
              controller: _employeeMobileNumberController,
              keyboardType: TextInputType.phone,
              hintText: 'Enter mobile number',
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed:
                    _employeeMobileNumberController.text.trim().isNotEmpty
                        ? _searchAttendanceHistories
                        : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange.shade700,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
                child: const Text(
                  'Search by Mobile',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ],
        );
      case 'date':
      default:
        return _buildDateSearchOptions();
    }
  }

  Widget _buildAttendanceList() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    } else if (_errorMessage.isNotEmpty) {
      return Center(
        child: Text(
          _errorMessage,
          style: const TextStyle(
            fontSize: 16,
            color: Colors.redAccent,
            fontWeight: FontWeight.w600,
          ),
        ),
      );
    } else if (_attendanceList.isEmpty && _hasSearched) {
      return const Center(
        child: Text(
          'No attendance records found',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      );
    } else if (_attendanceList.isEmpty) {
      return const SizedBox.shrink();
    }

    return ListView.builder(
      physics: const BouncingScrollPhysics(),
      shrinkWrap: true,
      itemCount: _attendanceList.length,
      itemBuilder: (context, index) {
        final attendance = _attendanceList[index];
        final dateStr =
            DateFormat('dd-MM-yyyy').format(attendance.attendanceDate.toDate());

        String formatTimestamp(Timestamp? timestamp) {
          return timestamp != null
              ? DateFormat('hh:mm a').format(timestamp.toDate())
              : 'N/A';
        }

        // For officeTimeIn
        String timeInStr = formatTimestamp(attendance.officeTimeIn);
        String timeOutStr = formatTimestamp(attendance.officeTimeOut);
        String lunchInStr = formatTimestamp(attendance.lunchTimeStart);
        String lunchOutStr = formatTimestamp(attendance.lunchTimeEnd);

        return Card(
          margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
          elevation: 3,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          shadowColor: Colors.orange.shade200,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Date: $dateStr',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: Colors.deepOrange,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Employee: ${attendance.employeeName}',
                  style: const TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 6),
                Text(
                  'Employee ID: ${attendance.employeeId}',
                  style: const TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 6),
                Text(
                  'Mobile: ${attendance.mobileNumber ?? 'N/A'}',
                  style: const TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    // Time In
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Time In',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: Colors.green,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            timeInStr,
                            style: const TextStyle(fontSize: 16),
                          ),
                        ],
                      ),
                    ),
                    // Lunch Start
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Lunch Start',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: Colors.orange,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            lunchInStr,
                            style: const TextStyle(fontSize: 16),
                          ),
                        ],
                      ),
                    ),
                    // Lunch End
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Lunch End',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: Colors.deepOrange,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            lunchOutStr,
                            style: const TextStyle(fontSize: 16),
                          ),
                        ],
                      ),
                    ),
                    // Time Out
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Time Out',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: Colors.red,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            timeOutStr,
                            style: const TextStyle(fontSize: 16),
                          ),
                        ],
                      ),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF9E5), // Light yellow background
      appBar: AppBar(
        backgroundColor: Colors.orange.shade700,
        title: const Text('Attendance History'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildSearchTypeSelector(),
              const SizedBox(height: 20),
              _buildSearchInputFields(),
              const SizedBox(height: 30),
              if (_attendanceList.isNotEmpty ||
                  _isLoading ||
                  _errorMessage.isNotEmpty)
                _buildAttendanceList(),
            ],
          ),
        ),
      ),
    );
  }
}
