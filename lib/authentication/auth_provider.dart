import 'package:attendance_app/authentication/auth.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthProvider extends ChangeNotifier {
  final Auth _auth;
  User? _currentUser;
  bool _isAdmin = false;
  bool _isEmployee = false;
  bool _isLoggedIn = false;
  String? _username;
  String? _email;
  String? _employeeId;
  String? _mobileNumber;
  String? _errorMessage;
  bool _isLoading = false;
  late SharedPreferences _prefs;

  AuthProvider({Auth? auth}) : _auth = auth ?? Auth() {
    _initAuthState();
    _loadSession();
  }

  // Getters
  bool get isEmployee => _isEmployee;
  bool get isAdmin => _isAdmin;
  bool get isLoggedIn => _isLoggedIn;
  String? get username => _username;
  String? get email => _email;
  String? get employeeId => _employeeId;
  String? get mobileNumber => _mobileNumber;
  User? get currentUser => _currentUser;
  String? get errorMessage => _errorMessage;
  bool get isLoading => _isLoading;

  // Initialize auth state listener
  void _initAuthState() {
    _auth.authStateChanges.listen((User? user) async {
      _currentUser = user;
      if (user != null) {
        _isLoggedIn = true;
        await _loadUserData(user.uid);
        await _saveSession();
      } else {
        await _clearSession();
        _resetState();
      }
      notifyListeners();
    });
  }

  // Load saved session from SharedPreferences
  Future<void> _loadSession() async {
    _prefs = await SharedPreferences.getInstance();
    _isLoggedIn = _prefs.getBool('isLoggedIn') ?? false;
    _isAdmin = _prefs.getBool('isAdmin') ?? false;
    _isEmployee = _prefs.getBool('isEmployee') ?? false;
    _username = _prefs.getString('username');
    _email = _prefs.getString('email');
    _employeeId = _prefs.getString('employeeId');
    _mobileNumber = _prefs.getString('mobileNumber');

    if (_isLoggedIn) {
      notifyListeners();
    }
  }

  // Save current session to SharedPreferences
  Future<void> _saveSession() async {
    await _prefs.setBool('isLoggedIn', _isLoggedIn);
    await _prefs.setBool('isAdmin', _isAdmin);
    await _prefs.setBool('isEmployee', _isEmployee);
    await _prefs.setString('username', _username ?? '');
    await _prefs.setString('email', _email ?? '');
    await _prefs.setString('employeeId', _employeeId ?? '');
    await _prefs.setString('mobileNumber', _mobileNumber ?? '');
  }

  // Clear session data from SharedPreferences
  Future<void> _clearSession() async {
    await _prefs.remove('isLoggedIn');
    await _prefs.remove('isAdmin');
    await _prefs.remove('isEmployee');
    await _prefs.remove('username');
    await _prefs.remove('email');
  }

  // Reset all state variables
  void _resetState() {
    _isLoggedIn = false;
    _isAdmin = false;
    _isEmployee = false;
    _username = null;
    _email = null;
    _employeeId = null;
    _mobileNumber = null;
    _errorMessage = null;
    _currentUser = null;
  }

  // Load user data from Firestore or other sources
  Future<void> _loadUserData(String uid) async {
    try {
      _isLoading = true;
      notifyListeners();

      _username = await _auth.getUserName(uid);
      _email = _currentUser?.email;
      _employeeId = await _auth
          .getUserEmployeeId(uid); // Assuming UID is used as employee ID
      _mobileNumber = await _auth.getEmployeeMobileNumber(uid);

      // Determine user role - you might want to fetch this from your database
      // For now using the existing flags
      _isAdmin = _isAdmin; // Preserve existing value
      _isEmployee = !_isAdmin;

      await _saveSession();
    } catch (e) {
      _errorMessage = 'Failed to load user data: ${e.toString()}';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Login with email and password
  Future<bool> loginWithEmail({
    required String email,
    required String password,
    bool isAdmin = false,
  }) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      await _auth.signIn(email: email, password: password);
      _isLoggedIn = true;
      _isAdmin = isAdmin;
      _isEmployee = !isAdmin;

      if (_currentUser != null) {
        await _loadUserData(_currentUser!.uid);
      }

      await _saveSession();
      return true;
    } on FirebaseAuthException catch (e) {
      _errorMessage = _getFirebaseErrorMessage(e);
      return false;
    } catch (e) {
      _errorMessage = 'Login failed: ${e.toString()}';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Create new account
  Future<bool> createAccount({
    required String username,
    required String email,
    required String password,
    required String employeeId,
    required String mobileNumber,
    bool isAdmin = false,
  }) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      await _auth.createAdminAccount(
        username: username,
        email: email,
        password: password,
        employeeId: employeeId,
        mobileNumber: mobileNumber,
      );

      _isLoggedIn = true;
      _isAdmin = isAdmin;
      _isEmployee = !isAdmin;
      _username = username;
      _email = email;

      await _saveSession();
      return true;
    } on FirebaseAuthException catch (e) {
      _errorMessage = _getFirebaseErrorMessage(e);
      return false;
    } catch (e) {
      _errorMessage = 'Account creation failed: ${e.toString()}';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Login as guest/executive
  Future<void> loginAsExecutive() async {
    _isEmployee = true;
    _isAdmin = false;
    _isLoggedIn = true;
    _email = null;
    await _saveSession();
    notifyListeners();
  }

  // Login as admin
  Future<void> loginAsAdmin() async {
    _isEmployee = false;
    _isAdmin = true;
    _isLoggedIn = true;
    await _saveSession();
    notifyListeners();
  }

  // Logout
  Future<void> logout() async {
    try {
      _isLoading = true;
      notifyListeners();

      await _auth.signOut();
      await _clearSession();
      _resetState();
    } catch (e) {
      _errorMessage = 'Logout failed: ${e.toString()}';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Clear error message
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  // Helper to get user-friendly error messages
  String _getFirebaseErrorMessage(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return 'No user found with this email';
      case 'wrong-password':
        return 'Incorrect password';
      case 'email-already-in-use':
        return 'Email already in use';
      case 'weak-password':
        return 'Password is too weak';
      case 'invalid-email':
        return 'Invalid email address';
      default:
        return 'Authentication error: ${e.message}';
    }
  }

  Future<bool> reauthenticate(
      {required String email, required String password}) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      await _auth.reauthenticateWithCredential(
        email: email,
        password: password,
      );
      return true;
    } on FirebaseAuthException catch (e) {
      _errorMessage = _getFirebaseErrorMessage(e);
      return false;
    } catch (e) {
      _errorMessage = 'Re-authentication failed: ${e.toString()}';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> updatepassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      await _auth.updatePassword(
        currentPassword: currentPassword,
        newPassword: newPassword,
      );
      return true;
    } on FirebaseAuthException catch (e) {
      _errorMessage = _getFirebaseErrorMessage(e);
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> checkEmailVerified() async {
    try {
      return await _auth.checkEmailVerified();
    } catch (e) {
      _errorMessage = 'Email verification failed: ${e.toString()}';
      return false;
    }
  }

  // modify the updateemail method
  Future<bool> updateEmail({
    required String currentPassword,
    required String newEmail,
  }) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      await _auth.updateEmail(
        currentPassword: currentPassword,
        newEmail: newEmail,
      );

      // Don't update local state yet - wait for verification
      // just notify user to check their email
      _errorMessage =
          'Verification email sent to $newEmail. Please verify to complete the update.';
      return true;
    } on FirebaseAuthException catch (e) {
      _errorMessage = _getFirebaseErrorMessage(e);
      return false;
    } catch (e) {
      _errorMessage = 'Email update failed: ${e.toString()}';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> deleteAccount({
    required String currentPassword,
  }) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      await _auth.deleteAccount(currentPassword: currentPassword);

      // clear local state
      await _clearSession();
      _resetState();

      return true;
    } on FirebaseAuthException catch (e) {
      _errorMessage = _getFirebaseErrorMessage(e);
      return false;
    } catch (e) {
      _errorMessage = 'Account deletion failed: ${e.toString()}';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
