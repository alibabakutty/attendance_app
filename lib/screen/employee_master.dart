import 'package:attendance_app/authentication/auth_provider.dart';
import 'package:attendance_app/modals/employee_master_data.dart';
import 'package:attendance_app/service/firebase_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class EmployeeMaster extends StatefulWidget {
  const EmployeeMaster({super.key, this.mobileNumber});
  final String? mobileNumber;

  @override
  State<EmployeeMaster> createState() => _EmployeeMasterState();
}

class _EmployeeMasterState extends State<EmployeeMaster> {
  final FirebaseService _firebaseService = FirebaseService();
  final _formKey = GlobalKey<FormState>();
  Timestamp? _dateOfJoining;
  final TextEditingController _employeeIdController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _mobileNumberController =
      TextEditingController(); // New mobile controller
  final TextEditingController _aadhaarController = TextEditingController();
  final TextEditingController _panController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isSubmitting = false;
  bool _obscurePassword = true;
  bool _isEditing = false;

  EmployeeMasterData? _employeeData;
  String? mobileNumberFromArgs;

  @override
  void initState() {
    super.initState();
    mobileNumberFromArgs = widget.mobileNumber;
    if (mobileNumberFromArgs != null) {
      _mobileNumberController.text = mobileNumberFromArgs!;
    }
    _fetchEmployeeData();
  }

  Future<void> _fetchEmployeeData() async {
    if (mobileNumberFromArgs != null) {
      try {
        _employeeData = await _firebaseService
            .fetchEmployeeMasterDataByMobileNumber(mobileNumberFromArgs!);
        if (_employeeData != null) {
          setState(() {
            _employeeIdController.text = _employeeData!.employeeId;
            _nameController.text = _employeeData!.employeeName;
            _mobileNumberController.text = _employeeData!.mobileNumber;
            _dateOfJoining = _employeeData!.dateOfJoining;
            _aadhaarController.text = _employeeData!.aadhaarNumber;
            _panController.text = _employeeData!.panNumber;
            _emailController.text = _employeeData!.email;
            // Password should not be pre-filled for security reasons
            _passwordController.text = _employeeData!.password;
            _isEditing = true;
          });
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error fetching employee data: $e')),
        );
      }
    }
  }

  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isSubmitting = true);

      try {
        if (_dateOfJoining == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Please select a date of joining')),
          );
          return;
        }

        final employeeDataMap = {
          'employee_id': _employeeIdController.text.trim(),
          'employee_name': _nameController.text.trim(),
          'mobile_number': _mobileNumberController.text.trim(),
          'date_of_joining': _dateOfJoining!,
          'aadhaar_number': _aadhaarController.text.trim(),
          'pan_number': _panController.text.trim(),
          'email': _emailController.text.trim(),
          'password': _passwordController.text.trim(),
          'updated_at': Timestamp.now(),
        };

        bool success;

        if (_isEditing) {
          // ✅ Call update function
          success =
              await _firebaseService.updateEmployeeMasterDataByMobileNumber(
            _mobileNumberController.text.trim(),
            employeeDataMap,
          );
        } else {
          // ✅ First create auth account
          final authProvider =
              Provider.of<AuthProvider>(context, listen: false);

          await authProvider.createAccount(
            username: _nameController.text.trim(),
            email: _emailController.text.trim(),
            password: _passwordController.text.trim(),
            employeeId: _employeeIdController.text.trim(),
            mobileNumber: _mobileNumberController.text.trim(),
            isAdmin: false,
          );

          // ✅ Then add employee data
          final employeeMasterData = EmployeeMasterData(
            employeeId: _employeeIdController.text.trim(),
            employeeName: _nameController.text.trim(),
            mobileNumber: _mobileNumberController.text.trim(),
            dateOfJoining: _dateOfJoining!,
            aadhaarNumber: _aadhaarController.text.trim(),
            panNumber: _panController.text.trim(),
            email: _emailController.text.trim(),
            password: _passwordController.text.trim(),
            createdAt: Timestamp.now(),
          );

          success =
              await _firebaseService.addNewEmployeeData(employeeMasterData);
        }

        if (success && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                _isEditing
                    ? 'Employee updated successfully!'
                    : 'Employee added successfully!',
              ),
            ),
          );
          Navigator.pop(context);
        } else if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('Operation failed. Please try again.')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: ${e.toString()}')),
          );
        }
      } finally {
        if (mounted) setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  void dispose() {
    _employeeIdController.dispose();
    _nameController.dispose();
    _mobileNumberController.dispose(); // Dispose mobile controller
    _aadhaarController.dispose();
    _panController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _dateOfJoining = null;
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        _dateOfJoining = Timestamp.fromDate(picked);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add New Employee'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _isSubmitting ? null : _submitForm,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              children: [
                // Employee ID Field
                TextFormField(
                  controller: _employeeIdController,
                  decoration: const InputDecoration(
                    labelText: 'Employee ID',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.badge),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter employee ID';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Employee Name Field
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Employee Name',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.person),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter employee name';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Mobile Number Field (New)
                TextFormField(
                  controller: _mobileNumberController,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    labelText: 'Mobile Number',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.phone),
                    hintText: '10-digit mobile number',
                    prefixText: '+91 ',
                  ),
                  maxLength: 10,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter mobile number';
                    }
                    if (value.length != 10) {
                      return 'Mobile number must be 10 digits';
                    }
                    if (!RegExp(r'^[0-9]+$').hasMatch(value)) {
                      return 'Only numbers are allowed';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Date of Joining Field
                InkWell(
                  onTap: () => _selectDate(context),
                  child: InputDecorator(
                    decoration: const InputDecoration(
                      labelText: 'Date of Joining',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.calendar_today),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _dateOfJoining == null
                              ? 'Select date'
                              : DateFormat('dd/MM/yyyy')
                                  .format(_dateOfJoining!.toDate()),
                        ),
                        const Icon(Icons.arrow_drop_down),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Aadhaar Number Field
                TextFormField(
                  controller: _aadhaarController,
                  decoration: const InputDecoration(
                    labelText: 'Aadhaar Number',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.credit_card),
                    hintText: 'XXXX XXXX XXXX',
                  ),
                  keyboardType: TextInputType.number,
                  maxLength: 12,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter Aadhaar number';
                    }
                    if (value.length < 12) {
                      return 'Aadhaar must be 12 digits';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // PAN Number Field
                TextFormField(
                  controller: _panController,
                  decoration: const InputDecoration(
                    labelText: 'PAN Number',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.credit_card),
                    hintText: 'ABCDE1234F',
                  ),
                  maxLength: 10,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter PAN number';
                    }
                    if (value.length < 10) {
                      return 'PAN must be 10 characters';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Email Field
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.email),
                    hintText: 'employee@company.com',
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter email address';
                    }
                    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
                        .hasMatch(value)) {
                      return 'Please enter a valid email';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Password Field
                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  decoration: InputDecoration(
                    labelText: 'Password',
                    border: const OutlineInputBorder(),
                    prefixIcon: const Icon(Icons.lock),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility_off
                            : Icons.visibility,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscurePassword = !_obscurePassword;
                        });
                      },
                    ),
                    hintText: 'At least 6 characters',
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter password';
                    }
                    if (value.length < 6) {
                      return 'Password must be at least 6 characters';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 24),

                // Submit Button
                ElevatedButton(
                  onPressed: _isSubmitting ? null : _submitForm,
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 50),
                    backgroundColor: Colors.blue,
                  ),
                  child: _isSubmitting
                      ? const CircularProgressIndicator(
                          color: Colors.white,
                        )
                      : Text(
                          _isEditing ? 'Update Employee' : 'Add Employee',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
