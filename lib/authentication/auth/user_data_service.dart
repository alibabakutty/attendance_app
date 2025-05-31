import 'package:attendance_app/authentication/auth/auth_exception.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class UserDataService {
  final FirebaseFirestore _firestore;

  UserDataService(this._firestore);

  Future<void> createUserRecord({
    required String uid,
    String? username,
    String? email,
    bool isAdmin = false,
  }) async {
    try {
      await _firestore.collection('users').doc(uid).set({
        'username': username,
        'email': email,
        'isAdmin': isAdmin,
        'createdAt': FieldValue.serverTimestamp(),
        'lastLogin': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw AuthException('Failed to create user record: ${e.toString()}');
    }
  }

  Future<void> createAdminRecord({
    required String uid,
    required String username,
    required String email,
    required String employeeId,
    required String mobileNumber,
  }) async {
    try {
      await _firestore.collection('users').doc(uid).set({
        'username': username,
        'email': email,
        'employee_id': employeeId,
        'mobile_number': mobileNumber,
        'isAdmin': true,
        'createdAt': FieldValue.serverTimestamp(),
        'lastLogin': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw AuthException('Failed to create admin record: ${e.toString()}');
    }
  }

  Future<bool> isUserAdmin(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      return doc.data()?['isAdmin'] ?? false;
    } catch (e) {
      throw AuthException('Failed to check if user is admin: ${e.toString()}');
    }
  }

  Future<void> updateLastLogin(String uid) async {
    try {
      await _firestore.collection('users').doc(uid).update({
        'lastLogin': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw AuthException('Failed to update last login: ${e.toString()}');
    }
  }

  Future<String?> getUsername(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      return doc.data()?['username'] as String?;
    } catch (e) {
      throw AuthException('Failed to get username: ${e.toString()}');
    }
  }

  Future<String?> getEmployeeId(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      return doc.data()?['employee_id'] as String?;
    } catch (e) {
      throw AuthException('Failed to get employee ID: ${e.toString()}');
    }
  }

  Future<String?> getMobileNumber(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      return doc.data()?['mobile_number'] as String?;
    } catch (e) {
      throw AuthException('Failed to get mobile number: ${e.toString()}');
    }
  }

  Future<void> deleteUserRecord(String uid) async {
    try {
      await _firestore.collection('users').doc(uid).delete();
    } catch (e) {
      throw AuthException('Failed to delete user record: ${e.toString()}');
    }
  }
}
