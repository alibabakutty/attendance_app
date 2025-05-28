import 'package:attendance_app/modals/employee_master_data.dart';
import 'package:attendance_app/modals/mark_attendance_data.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class FirebaseService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  FirebaseService();

  // add a new employee to the employee master collection
  Future<bool> addNewEmployeeData(EmployeeMasterData employeeMasterData) async {
    try {
      await _db
          .collection('employee_master_data')
          .add(employeeMasterData.toFirestore());
      return true;
    } catch (e) {
      print('Error adding new employee data: $e');
      return false;
    }
  }

  // add a new mark attendance data
  Future<bool> addNewMarkAttendanceData(
      MarkAttendanceData markAttendanceData) async {
    try {
      await _db
          .collection('mark_attendance_data')
          .add(markAttendanceData.toFirestore());
      return true;
    } catch (e) {
      print('Error adding new mark attendance data: $e');
      return false;
    }
  }

  // fetch employee master data by employee ID
  Future<EmployeeMasterData?> fetchEmployeeMasterDataById(
      String employeeId) async {
    final snapshot = await FirebaseFirestore.instance
        .collection('employee_master_data')
        .where('employee_id', isEqualTo: employeeId)
        .limit(1)
        .get();
    if (snapshot.docs.isNotEmpty) {
      return EmployeeMasterData.fromFirestore(snapshot.docs.first.data());
    }
    return null;
  }

  // fetch mark attendance data by employee ID
  Future<MarkAttendanceData?> fetchMarkAttendanceDataByEmployeeId(
      String employeeId) async {
    final snapshot = await FirebaseFirestore.instance
        .collection('mark_attendance_data')
        .where('employee_id', isEqualTo: employeeId)
        .limit(1)
        .get();
    if (snapshot.docs.isNotEmpty) {
      return MarkAttendanceData.fromFirestore(snapshot.docs.first.data());
    }
    return null;
  }

  // fetch employee master data by employee name
  Future<EmployeeMasterData?> fetchEmployeeMasterDataByName(
      String employeeName) async {
    final snapshot = await FirebaseFirestore.instance
        .collection('employee_master_data')
        .where('employee_name', isEqualTo: employeeName)
        .limit(1)
        .get();
    if (snapshot.docs.isNotEmpty) {
      return EmployeeMasterData.fromFirestore(snapshot.docs.first.data());
    }
    return null;
  }

  // fetch mark attendance data by employee name
  Future<MarkAttendanceData?> fetchMarkAttendanceDataByEmployeeName(
      String employeeName) async {
    final snapshot = await FirebaseFirestore.instance
        .collection('mark_attendance_data')
        .where('employee_name', isEqualTo: employeeName)
        .limit(1)
        .get();
    if (snapshot.docs.isNotEmpty) {
      return MarkAttendanceData.fromFirestore(snapshot.docs.first.data());
    }
    return null;
  }

  // fetch all employee master data
  Future<List<EmployeeMasterData>> getAllEmployeeMasterData() async {
    try {
      QuerySnapshot snapshot =
          await _db.collection('employee_master_data').get();

      return snapshot.docs
          .map((doc) => EmployeeMasterData.fromFirestore(
              doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      print('Error fetching all employee master data: $e');
      return [];
    }
  }

  // fetch all mark attendance data
  Future<List<MarkAttendanceData>> getAllMarkAttendanceData() async {
    try {
      QuerySnapshot snapshot =
          await _db.collection('mark_attendance_data').get();

      return snapshot.docs
          .map((doc) => MarkAttendanceData.fromFirestore(
              doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      print('Error fetching all mark attendance data: $e');
      return [];
    }
  }

  // update employee master data by old name
  Future<bool> updateEmployeeMasterData(
      String oldName, EmployeeMasterData updatedData) async {
    try {
      // first check if the new name is already taken by another employee
      if (oldName != updatedData.employeeName) {
        QuerySnapshot duplicateCheck = await _db
            .collection('employee_master_data')
            .where('employee_name', isEqualTo: updatedData.employeeName)
            .limit(1)
            .get();
        if (duplicateCheck.docs.isNotEmpty) {
          print(
              'Error. Employee name ${updatedData.employeeName} already exists.');
          return false; // Name already exists
        }
      }
      // find the document by old name
      QuerySnapshot snapshot = await _db
          .collection('employee_master_data')
          .where('employee_name', isEqualTo: oldName)
          .limit(1)
          .get();
      if (snapshot.docs.isNotEmpty) {
        String docName = snapshot.docs.first.id;
        await _db.collection('employee_master_data').doc(docName).update({
          'employee_id': updatedData.employeeId,
          'employee_name': updatedData.employeeName,
          'date_of_joining': updatedData.dateOfJoining,
          'aadhaar_number': updatedData.aadhaarNumber,
          'pan_number': updatedData.panNumber,
          'created_at': FieldValue.serverTimestamp(),
        });
        return true;
      } else {
        return false; // Document not found
      }
    } catch (e) {
      print('Error updating employee master data: $e');
      return false; // Handle error appropriately in your app
    }
  }

  // update mark attendance data by employee name
  Future<bool> updateMarkAttendanceDataByName(
      String oldName, MarkAttendanceData updatedData) async {
    try {
      // first check if the new name is already taken by another employee
      if (oldName != updatedData.employeeName) {
        QuerySnapshot duplicateCheck = await _db
            .collection('mark_attendance_data')
            .where('employee_name', isEqualTo: updatedData.employeeName)
            .limit(1)
            .get();
        if (duplicateCheck.docs.isNotEmpty) {
          print(
              'Error. Employee name ${updatedData.employeeName} already exists.');
          return false; // Name already exists
        }
      }
      // find the document by old name
      QuerySnapshot snapshot = await _db
          .collection('mark_attendance_data')
          .where('employee_name', isEqualTo: oldName)
          .limit(1)
          .get();
      if (snapshot.docs.isNotEmpty) {
        String docName = snapshot.docs.first.id;
        await _db.collection('mark_attendance_data').doc(docName).update({
          'employee_id': updatedData.employeeId,
          'employee_name': updatedData.employeeName,
          'attendance_date': updatedData.attendanceDate,
          'office_time_in': updatedData.officeTimeIn,
          'office_time_in_location': updatedData.officeTimeInLocation,
          'lunch_time_start': updatedData.lunchTimeStart,
          'lunch_time_start_location': updatedData.lunchTimeStartLocation,
          'lunch_time_end': updatedData.lunchTimeEnd,
          'lunch_time_end_location': updatedData.lunchTimeEndLocation,
          'office_time_out': updatedData.officeTimeOut,
          'office_time_out_location': updatedData.officeTimeOutLocation,
        });
        return true;
      } else {
        return false; // Document not found
      }
    } catch (e) {
      print('Error updating mark attendance data: $e');
      return false; // Handle error appropriately in your app
    }
  }

  // update employee master data by employee ID
  Future<bool> updateEmployeeMasterDataById(
      String employeeId, Map<String, dynamic> updatedData) async {
    try {
      QuerySnapshot snapshot = await _db
          .collection('employee_master_data')
          .where('employee_id', isEqualTo: employeeId)
          .limit(1)
          .get();
      if (snapshot.docs.isNotEmpty) {
        String docId = snapshot.docs.first.id;
        await _db
            .collection('employee_master_data')
            .doc(docId)
            .update(updatedData);
        return true;
      } else {
        return false; // Document not found
      }
    } catch (e, stackTrace) {
      print('Error updating employee master data by ID: $e, $stackTrace');
      return false; // Handle error appropriately in your app
    }
  }

  // update mark attendance data by employee ID
  Future<bool> updateMarkAttendanceDataById(
      String employeeId, Map<String, dynamic> updatedData) async {
    try {
      QuerySnapshot snapshot = await _db
          .collection('mark_attendance_data')
          .where('employee_id', isEqualTo: employeeId)
          .limit(1)
          .get();
      if (snapshot.docs.isNotEmpty) {
        String docId = snapshot.docs.first.id;
        await _db
            .collection('mark_attendance_data')
            .doc(docId)
            .update(updatedData);
        return true;
      } else {
        return false; // Document not found
      }
    } catch (e) {
      print('Error updating mark attendance data by ID: $e');
      return false; // Handle error appropriately in your app
    }
  }

  // delete employee master data by ID
  Future<bool> deleteEmployeeMasterDataById(String employeeId) async {
    try {
      // find the document by employee ID
      QuerySnapshot snapshot = await _db
          .collection('employee_master_data')
          .where('employee_id', isEqualTo: employeeId)
          .limit(1)
          .get();
      if (snapshot.docs.isNotEmpty) {
        await _db
            .collection('employee_master_data')
            .doc(snapshot.docs.first.id)
            .delete(); // delete the document
        return true;
      } else {
        return false; // Document not found
      }
    } catch (e) {
      print('Error deleting employee master data by ID: $e');
      return false; // Handle error appropriately in your app
    }
  }

  // delete mark attendance data by employee ID
  Future<bool> deleteMarkAttendanceDataById(String employeeId) async {
    try {
      // find the document by employee ID
      QuerySnapshot snapshot = await _db
          .collection('mark_attendance_data')
          .where('employee_id', isEqualTo: employeeId)
          .limit(1)
          .get();
      if (snapshot.docs.isNotEmpty) {
        await _db
            .collection('mark_attendance_data')
            .doc(snapshot.docs.first.id)
            .delete(); // delete the document
        return true;
      } else {
        return false; // Document not found
      }
    } catch (e) {
      print('Error deleting mark attendance data by ID: $e');
      return false; // Handle error appropriately in your app
    }
  }

  // delete employee master data by name
  Future<bool> deleteEmployeeMasterDataByName(String employeeName) async {
    try {
      // find the document by employee name
      QuerySnapshot snapshot = await _db
          .collection('employee_master_data')
          .where('employee_name', isEqualTo: employeeName)
          .limit(1)
          .get();
      if (snapshot.docs.isNotEmpty) {
        await _db
            .collection('employee_master_data')
            .doc(snapshot.docs.first.id)
            .delete();
        return true; // Document deleted successfully
      } else {
        return false; // Document not found
      }
    } catch (e) {
      print('Error deleting employee master data by name: $e');
      return false; // Handle error appropriately in your app
    }
  }

  // delete mark attendance data by name
  Future<bool> deleteMarkAttendanceDataByName(String employeeName) async {
    try {
      // find the document by employee name
      QuerySnapshot snapshot = await _db
          .collection('mark_attendance_data')
          .where('employee_name', isEqualTo: employeeName)
          .limit(1)
          .get();
      if (snapshot.docs.isNotEmpty) {
        await _db
            .collection('mark_attendance_data')
            .doc(snapshot.docs.first.id)
            .delete();
        return true; // Document deleted successfully
      } else {
        return false; // Document not found
      }
    } catch (e) {
      print('Error deleting mark attendance data by name: $e');
      return false; // Handle error appropriately in your app
    }
  }
}
