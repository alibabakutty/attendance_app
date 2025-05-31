import 'package:attendance_app/authentication/auth/auth_exception.dart';
import 'package:attendance_app/authentication/auth/auth_service.dart';
import 'package:attendance_app/authentication/auth/user_data_service.dart';
import 'package:firebase_auth/firebase_auth.dart';

class EmailAuthService implements AuthService {
  final FirebaseAuth _firebaseAuth;
  final UserDataService _userDataService;

  EmailAuthService(this._firebaseAuth, this._userDataService);

  @override
  User? get currentUser => _firebaseAuth.currentUser;

  @override
  Stream<User?> get authStateChanges => _firebaseAuth.authStateChanges();

  @override
  Future<void> signInWithEmailAndPassword(String email, String password) async {
    try {
      email = email.trim();
      password = password.trim();

      if (email.isEmpty || password.isEmpty) {
        throw AuthException(
          'Email and password cannot be empty',
          code: 'invalid-email-or-password',
        );
      }

      final userCredential = await _firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (userCredential.user == null) {
        throw AuthException(
          'Authentication succeeded but no user returned',
          code: 'no-user',
        );
      }

      // update last login time
      await _userDataService.updateLastLogin(userCredential.user!.uid);

      try {
        await userCredential.user?.getIdToken(true);
      } catch (e) {
        print('Token refresh failed but continuing: $e');
      }
    } on FirebaseAuthException catch (e) {
      throw _handleFirebaseAuthException(e);
    } catch (e) {
      throw AuthException(
          'An unexpected error occurred during authentication: ${e.toString()}');
    }
  }

  @override
  Future<void> createAdminAccount({
    required String username,
    required String email,
    required String password,
    required String employeeId,
    required String mobileNumber,
  }) async {
    try {
      final userCredential = await _firebaseAuth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
      );

      if (userCredential.user == null) {
        throw AdminCreationException('User creation failed');
      }

      await _userDataService.createAdminRecord(
        uid: userCredential.user!.uid,
        username: username,
        email: email,
        employeeId: employeeId,
        mobileNumber: mobileNumber,
      );
    } on FirebaseAuthException catch (e) {
      throw AdminCreationException(_handleFirebaseAuthException(e).message);
    } catch (e) {
      throw AdminCreationException(
          'Failed to create admin account: ${e.toString()}');
    }
  }

  AuthException _handleFirebaseAuthException(FirebaseAuthException e) {
    switch (e.code) {
      case 'invalid-email':
        return AuthException(
          'The email address is invalid',
          code: e.code,
        );
      case 'user-disabled':
        return AuthException(
          'This account has been disabled',
          code: e.code,
        );
      case 'user-not-found':
        return AuthException(
          'No user found for this email',
          code: e.code,
        );
      case 'wrong-password':
        return AuthException(
          'Invalid email or password',
          code: e.code,
        );
      case 'email-already-in-use':
        return AuthException(
          'This email is already in use',
          code: e.code,
        );
      case 'weak-password':
        return AuthException(
          'The password is too weak',
          code: e.code,
        );
      default:
        return AuthException(
          'Authentication failed: ${e.message}',
          code: e.code,
        );
    }
  }

  @override
  Future<bool> isUserAdmin(String uid) async {
    return await _userDataService.isUserAdmin(uid);
  }

  @override
  Future<void> resetPassword(String email) async {
    try {
      await _firebaseAuth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      throw _handleFirebaseAuthException(e);
    }
  }

  @override
  Future<void> signOut() async {
    await _firebaseAuth.signOut();
  }

  @override
  Future<void> updatePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    final user = _firebaseAuth.currentUser;
    if (user == null) throw AuthException('No user is currently signed in');

    try {
      final credential = EmailAuthProvider.credential(
        email: user.email!,
        password: currentPassword,
      );
      await user.reauthenticateWithCredential(credential);
      await user.updatePassword(newPassword);
    } on FirebaseAuthException catch (e) {
      throw _handleFirebaseAuthException(e);
    }
  }

  @override
  Future<bool> checkEmailVerified() async {
    await _firebaseAuth.currentUser?.reload();
    return _firebaseAuth.currentUser?.emailVerified ?? false;
  }

  @override
  Future<void> updateEmail({
    required String currentPassword,
    required String newEmail,
  }) async {
    final user = _firebaseAuth.currentUser;
    if (user == null) throw AuthException('No user is currently signed in');

    try {
      final credential = EmailAuthProvider.credential(
        email: user.email!,
        password: currentPassword,
      );
      await user.reauthenticateWithCredential(credential);
      await user.verifyBeforeUpdateEmail(newEmail);
    } on FirebaseAuthException catch (e) {
      throw _handleFirebaseAuthException(e);
    }
  }

  @override
  Future<void> deleteAccount({required String currentPassword}) async {
    final user = _firebaseAuth.currentUser;
    if (user == null) throw AuthException('No user is currently signed in');

    try {
      final credential = EmailAuthProvider.credential(
        email: user.email!,
        password: currentPassword,
      );
      await user.reauthenticateWithCredential(credential);
      await _userDataService.deleteUserRecord(user.uid);
      await user.delete();
    } on FirebaseAuthException catch (e) {
      throw _handleFirebaseAuthException(e);
    }
  }

  @override
  Future<bool> validateCurrentCredentials() async {
    try {
      final user = _firebaseAuth.currentUser;
      if (user == null) return false;

      final tokenResult = await user.getIdTokenResult(true);
      if (tokenResult.expirationTime != null &&
          DateTime.now().isAfter(tokenResult.expirationTime!)) {
        return false;
      }

      await user.reload();
      return _firebaseAuth.currentUser != null;
    } catch (e) {
      return false;
    }
  }
}
