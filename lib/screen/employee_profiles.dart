import 'package:flutter/material.dart';

class EmployeeProfiles extends StatefulWidget {
  const EmployeeProfiles({super.key});

  @override
  State<EmployeeProfiles> createState() => _EmployeeProfilesState();
}

class _EmployeeProfilesState extends State<EmployeeProfiles> {
  // This list will store your employee names
  final List<String> _employees = [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Employee Profiles'),
      ),
      body: _employees.isEmpty
          ? const Center(
              child: Text('No employees added yet'),
            )
          : ListView.builder(
              itemCount: _employees.length,
              itemBuilder: (context, index) {
                return ListTile(
                  title: Text(_employees[index]),
                  // You can add more details here later
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.pushNamed(context, '/employeeMaster');
        },
        tooltip: 'Add Employee',
        child: const Icon(Icons.add),
      ),
    );
  }
}
