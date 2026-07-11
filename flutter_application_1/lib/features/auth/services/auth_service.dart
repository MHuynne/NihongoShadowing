import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  GoogleSignIn? _googleSignInInstance;

  GoogleSignIn get _googleSignIn {
    _googleSignInInstance ??= GoogleSignIn(

      clientId: kIsWeb
          ? '56132876251-em0dkjk5g1g51agnc60h4rgk7hek5fui.apps.googleusercontent.com'
          : null,


      serverClientId:
          '56132876251-em0dkjk5g1g51agnc60h4rgk7hek5fui.apps.googleusercontent.com',
    );
    return _googleSignInInstance!;
  }

  static const String _tokenKey = 'firebase_id_token';


  Stream<User?> get authStateChanges => _auth.authStateChanges();


  User? get currentUser => _auth.currentUser;




  Future<String?> getIdToken() async {
    try {
      final token = await _auth.currentUser?.getIdToken(true);
      if (token != null) {
        await _cacheToken(token);
      }
      return token;
    } catch (_) {

      return getStoredToken();
    }
  }


  Future<String?> getStoredToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }


  Future<void> _cacheToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
  }


  Future<void> _clearToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
  }


  Future<UserCredential> registerWithEmail({
    required String email,
    required String password,
    required String displayName,
  }) async {
    final credential = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
    await credential.user?.updateDisplayName(displayName);

    final token = await credential.user?.getIdToken();
    if (token != null) await _cacheToken(token);
    return credential;
  }


  Future<UserCredential> signInWithEmail({
    required String email,
    required String password,
  }) async {
    final credential = await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );

    final token = await credential.user?.getIdToken();
    if (token != null) await _cacheToken(token);
    return credential;
  }




  Future<UserCredential?> signInWithGoogle() async {
    if (kIsWeb) {

      final googleProvider = GoogleAuthProvider()
        ..addScope('email')
        ..addScope('profile')
        ..setCustomParameters({'prompt': 'select_account'});
      final userCredential = await _auth.signInWithPopup(googleProvider);
      final token = await userCredential.user?.getIdToken();
      if (token != null) await _cacheToken(token);
      return userCredential;
    } else {

      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return null;

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCredential = await _auth.signInWithCredential(credential);
      final token = await userCredential.user?.getIdToken();
      if (token != null) await _cacheToken(token);
      return userCredential;
    }
  }


  Future<void> sendPasswordResetEmail(String email) async {
    await _auth.sendPasswordResetEmail(email: email);
  }

  Future<void> updateProfile({
    required String displayName,
    String? photoUrl,
  }) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw FirebaseAuthException(
        code: 'no-current-user',
        message: 'No signed-in user.',
      );
    }

    final nextDisplayName = displayName.trim();
    final nextPhotoUrl =
        (photoUrl == null || photoUrl.trim().isEmpty) ? null : photoUrl.trim();

    if (user.displayName != nextDisplayName) {
      await user.updateDisplayName(nextDisplayName);
    }
    if (user.photoURL != nextPhotoUrl) {
      await user.updatePhotoURL(nextPhotoUrl);
    }
  }

  Future<void> sendEmailVerification() async {
    final user = _auth.currentUser;
    if (user == null) {
      throw FirebaseAuthException(
        code: 'no-current-user',
        message: 'No signed-in user.',
      );
    }
    await user.sendEmailVerification();
  }

  Future<void> updatePassword(String newPassword) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw FirebaseAuthException(
        code: 'no-current-user',
        message: 'No signed-in user.',
      );
    }
    await user.updatePassword(newPassword);
  }

  Future<void> deleteAccount() async {
    final user = _auth.currentUser;
    if (user == null) {
      throw FirebaseAuthException(
        code: 'no-current-user',
        message: 'No signed-in user.',
      );
    }
    await _clearToken();
    await user.delete();
  }


  Future<void> signOut() async {

    await _clearToken();


    try {
      await _auth.signOut();
    } catch (_) {}


    if (!kIsWeb) {
      try {
        await _googleSignIn.signOut();
      } catch (_) {}
      try {
        await _googleSignIn.disconnect();
      } catch (_) {}
    }
  }


  static String getVietnameseError(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return 'Email này chưa được đăng ký.';
      case 'wrong-password':
        return 'Mật khẩu không chính xác.';
      case 'email-already-in-use':
        return 'Email này đã được sử dụng.';
      case 'weak-password':
        return 'Mật khẩu quá yếu. Vui lòng dùng ít nhất 6 ký tự.';
      case 'invalid-email':
        return 'Địa chỉ email không hợp lệ.';
      case 'network-request-failed':
        return 'Mất kết nối mạng. Vui lòng thử lại.';
      case 'too-many-requests':
        return 'Quá nhiều lần thử. Vui lòng đợi một lúc.';
      default:
        return 'Lỗi xác thực: ${e.message}';
    }
  }
}