import 'package:attendance_app/modals/employee_master_data.dart';
import 'package:attendance_app/service/firebase_service.dart';
import 'package:flutter/material.dart';

class EmployeeProfiles extends StatefulWidget {
  const EmployeeProfiles({super.key});

  @override
  State<EmployeeProfiles> createState() => _EmployeeProfilesState();
}

class _EmployeeProfilesState extends State<EmployeeProfiles> {
  final FirebaseService _firebaseService = FirebaseService();
  List<EmployeeMasterData> _employeeData = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchEmployees();
  }

  Future<void> _fetchEmployees() async {
    setState(() => _isLoading = true);
    final data = await _firebaseService.getAllEmployeeMasterData();
    setState(() {
      _employeeData = data;
      _isLoading = false;
    });
  }

  Widget _buildEmployeeCard(EmployeeMasterData employee) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: const CircleAvatar(
          backgroundColor: Colors.blueAccent,
          child: Icon(Icons.person, color: Colors.white),
        ),
        title: Text(
          employee.employeeName,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text("ID: ${employee.employeeId}"),
            // Text("DOJ: ${employee.dateOfJoining}"),
          ],
        ),
        trailing: const Icon(Icons.arrow_forward_ios),
        onTap: () {
          // Optional: handle tap to show details or edit
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Employee Profiles'),
        centerTitle: true,
        backgroundColor: Colors.blueAccent,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _employeeData.isEmpty
              ? const Center(child: Text('No employees added yet'))
              : RefreshIndicator(
                  onRefresh: _fetchEmployees,
                  child: ListView.builder(
                    padding: const EdgeInsets.only(top: 8, bottom: 80),
                    itemCount: _employeeData.length,
                    itemBuilder: (context, index) =>
                        _buildEmployeeCard(_employeeData[index]),
                  ),
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.pushNamed(context, '/employeeMaster');
        },
        backgroundColor: Colors.blueAccent,
        tooltip: 'Add Employee',
        child: const Icon(Icons.add),
      ),
    );
  }
}
