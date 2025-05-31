import 'package:firebase_auth/firebase_auth.dart';

abstract class AuthService {
  // Base Interface for authentication service
  User? get currentUser;
  Stream<User?> get authStateChanges;

  Future<void> signInWithEmailAndPassword(String email, String password);
  Future<void> signOut();
  Future<void> resetPassword(String email);
  Future<bool> isUserAdmin(String uid);

  // Email/password account management
  Future<void> createAdminAccount({
    required String username,
    required String email,
    required String password,
    required String emailId,
    required String mobileNumber,
  });

  Future<void> updatePassword({
    required String currentPassword,
    required String newPassword,
  });

  Future<void> updateEmail({
    required String currentPassword,
    required String newEmail,
  });

  Future<void> deleteAccount({
    required String currentPassword,
  });

  Future<bool> checkEmailVerified();
  Future<bool> validateCurrentCredentials();
}
