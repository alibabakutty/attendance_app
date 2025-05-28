import 'package:cloud_firestore/cloud_firestore.dart';

class MarkAttendanceData {
  final String employeeId;
  final String employeeName;
  final String mobileNumber;
  final Timestamp attendanceDate;
  final Timestamp officeTimeIn;
  final GeoPoint officeTimeInLocation;
  final Timestamp lunchTimeStart;
  final GeoPoint lunchTimeStartLocation;
  final Timestamp lunchTimeEnd;
  final GeoPoint lunchTimeEndLocation;
  final Timestamp officeTimeOut;
  final GeoPoint officeTimeOutLocation;

  MarkAttendanceData({
    required this.employeeId,
    required this.employeeName,
    required this.mobileNumber,
    required this.attendanceDate,
    required this.officeTimeIn,
    required this.officeTimeInLocation,
    required this.lunchTimeStart,
    required this.lunchTimeStartLocation,
    required this.lunchTimeEnd,
    required this.lunchTimeEndLocation,
    required this.officeTimeOut,
    required this.officeTimeOutLocation,
  });
  // Convert data from Firestore to MarkAttendanceData object
  factory MarkAttendanceData.fromFirestore(Map<String, dynamic> data) {
    return MarkAttendanceData(
      employeeId: data['employee_id'] ?? '',
      employeeName: data['employee_name'] ?? '',
      mobileNumber: data['mobile_number'] ?? '',
      attendanceDate: data['attendance_date'] ?? Timestamp.now(),
      officeTimeIn: data['office_time_in'] ?? Timestamp.now(),
      officeTimeInLocation: data['office_time_in_location'] ?? GeoPoint(0, 0),
      lunchTimeStart: data['lunch_time_start'] ?? Timestamp.now(),
      lunchTimeStartLocation:
          data['lunch_time_start_location'] ?? GeoPoint(0, 0),
      lunchTimeEnd: data['lunch_time_end'] ?? Timestamp.now(),
      lunchTimeEndLocation: data['lunch_time_end_location'] ?? GeoPoint(0, 0),
      officeTimeOut: data['office_time_out'] ?? Timestamp.now(),
      officeTimeOutLocation: data['office_time_out_location'] ?? GeoPoint(0, 0),
    );
  }
  // Convert MarkAttendanceData object to Firestore data
  Map<String, dynamic> toFirestore() {
    return {
      'employee_id': employeeId,
      'employee_name': employeeName,
      'mobile_number': mobileNumber,
      'attendance_date': attendanceDate,
      'office_time_in': officeTimeIn,
      'office_time_in_location': officeTimeInLocation,
      'lunch_time_start': lunchTimeStart,
      'lunch_time_start_location': lunchTimeStartLocation,
      'lunch_time_end': lunchTimeEnd,
      'lunch_time_end_location': lunchTimeEndLocation,
      'office_time_out': officeTimeOut,
      'office_time_out_location': officeTimeOutLocation,
    };
  }
}
