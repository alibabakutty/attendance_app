import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

class Auth {
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  User? get currentUser => _firebaseAuth.currentUser;
  Stream<User?> get authStateChanges => _firebaseAuth.authStateChanges();

  Future<void> signIn({
    required String email,
    required String password,
  }) async {
    await _firebaseAuth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  Future<void> createAdminAccount({
    required String username,
    required String email,
    required String password,
    required String employeeId,
    required String mobileNumber,
  }) async {
    try {
      // 1. Create user in Firebase Auth
      final userCredential = await _firebaseAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // 2. Store additional admin data in Firestore
      await _firestore.collection('users').doc(userCredential.user?.uid).set({
        'username': username,
        'email': email,
        'employee_id': employeeId,
        'mobile_number': mobileNumber,
        'isAdmin': true, // Mark as admin
        'createdAt': FieldValue.serverTimestamp(),
        'lastLogin': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      rethrow;
    }
  }

  Future<bool> isUserAdmin(String uid) async {
    final doc = await _firestore.collection('users').doc(uid).get();
    return doc.data()?['isAdmin'] ?? false;
  }

  Future<void> resetPassword({required String email}) async {
    await _firebaseAuth.sendPasswordResetEmail(email: email);
  }

  // Google Sign In
  Future<UserCredential?> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return null;
      
      final GoogleSignInAuthentication googleAuth = 
          await googleUser.authentication;
      final OAuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      
      final userCredential = await _firebaseAuth.signInWithCredential(credential);
      
      // Store user data if new user
      if (userCredential.additionalUserInfo?.isNewUser ?? false) {
        await _firestore.collection('users').doc(userCredential.user?.uid).set({
          'username': googleUser.displayName,
          'email': googleUser.email,
          'isAdmin': false,
          'createdAt': FieldValue.serverTimestamp(),
          'lastLogin': FieldValue.serverTimestamp(),
        });
      } else {
        // Update last login for existing user
        await _firestore.collection('users').doc(userCredential.user?.uid).update({
          'lastLogin': FieldValue.serverTimestamp(),
        });
      }
      
      return userCredential;
    } catch (e) {
      print('Error signing in with Google: $e');
      return null;
    }
  }

  Future<String?> getUserName(String uid) async {
    final doc = await _firestore.collection('users').doc(uid).get();
    return doc.data()?['username'] as String?;
  }

  Future<String?> getUserEmployeeId(String uid) async {
    final doc = await _firestore.collection('users').doc(uid).get();
    return doc.data()?['employee_id'] as String?;
  }

  Future<String?> getEmployeeMobileNumber(String uid) async {
    final doc = await _firestore.collection('users').doc(uid).get();
    return doc.data()?['mobile_number'] as String?;
  }

  Future<void> signOut() async {
    await _googleSignIn.signOut();
    await _firebaseAuth.signOut();
  }

  // Re-authentication (these are extras)
  Future<void> reauthenticateWithCredential(
      {required String email, required String password}) async {
    final user = _firebaseAuth.currentUser;
    if (user == null) throw Exception('No user is currently signed in');

    // create auth credential
    final credential = EmailAuthProvider.credential(
      email: email,
      password: password,
    );
    // Reauthenticate
    await user.reauthenticateWithCredential(credential);
  }

  Future<void> updatePassword(
      {required String currentPassword, required String newPassword}) async {
    final user = _firebaseAuth.currentUser;
    if (user == null) throw Exception('No user is currently signed in');

    // first reauthenticate
    final credential = EmailAuthProvider.credential(
      email: user.email!,
      password: currentPassword,
    );
    await user.reauthenticateWithCredential(credential);
    // update password
    await user.updatePassword(newPassword);
  }

  Future<bool> checkEmailVerified() async {
    await _firebaseAuth.currentUser?.reload();
    return _firebaseAuth.currentUser?.emailVerified ?? false;
  }

  // modify the updateemail method to be more robust
  Future<void> updateEmail(
      {required String currentPassword, required String newEmail}) async {
    final user = _firebaseAuth.currentUser;
    if (user == null) throw Exception('No user is currently signed in');
    // first reauthenticate
    final credential = EmailAuthProvider.credential(
      email: user.email!,
      password: currentPassword,
    );
    await user.reauthenticateWithCredential(credential);
    // verify before update email
    await user.verifyBeforeUpdateEmail(newEmail);
    // Note: Don't update Firestore yet - wait for email verification
    // The email will only be updated after the user clicks the verification link
    // You should listen for auth state changes to detect when the email is actually updated
  }

  Future<void> deleteAccount({required String currentPassword}) async {
    final user = _firebaseAuth.currentUser;
    if (user == null) throw Exception('No user is currently signed in');
    // first reauthenticate
    final credential = EmailAuthProvider.credential(
      email: user.email!,
      password: currentPassword,
    );
    await user.reauthenticateWithCredential(credential);
    // delete account
    await _firestore.collection('users').doc(user.uid).delete();
    // then delete auth accounts
    await user.delete();
  }

  Future<void> updatedLastLogin() async {
    final user = _firebaseAuth.currentUser;
    if (user == null) return;

    await _firestore.collection('users').doc(user.uid).update({
      'lastLogin': FieldValue.serverTimestamp(),
    });
  }
}
