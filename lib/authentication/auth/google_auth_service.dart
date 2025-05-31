import 'package:attendance_app/authentication/auth/auth_exception.dart';
import 'package:attendance_app/authentication/auth/user_data_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

class GoogleAuthService {
  final FirebaseAuth _firebaseAuth;
  final GoogleSignIn _googleSignIn;
  final UserDataService _userDataService;

  GoogleAuthService(
    this._firebaseAuth,
    this._googleSignIn,
    this._userDataService,
  );

  Future<UserCredential?> siginInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return null;

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;
      final OAuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCredential =
          await _firebaseAuth.signInWithCredential(credential);
      // Store user data if new user
      if (userCredential.additionalUserInfo?.isNewUser ?? false) {
        await _userDataService.createUserRecord(
          uid: userCredential.user!.uid,
          username: googleUser.displayName,
          email: googleUser.email,
          isAdmin: false,
        );
      } else {
        // Update last login for existing user
        await _userDataService.updateLastLogin(userCredential.user!.uid);
      }
      return userCredential;
    } on FirebaseAuthException catch (e) {
      throw AuthException(
        'Google sign-in failed: ${e.message}',
        code: e.code,
      );
    } catch (e) {
      throw AuthException(
        'Google sign-in failed: ${e.toString()}',
      );
    }
  }

  Future<void> signOut() async {
    try {
      await _googleSignIn.signOut();
    } catch (e) {
      throw AuthException(
        'Failed to sign out from Google: ${e.toString()}',
      );
    }
  }
}
