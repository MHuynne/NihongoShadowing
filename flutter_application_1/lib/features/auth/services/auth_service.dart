import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  static const String _tokenKey = 'firebase_id_token';

  // ── Stream theo dõi trạng thái đăng nhập ──────────────────────────────
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // ── User hiện tại ──────────────────────────────────────────────────────
  User? get currentUser => _auth.currentUser;

  // ── Lấy token tươi từ Firebase rồi lưu vào cache ─────────────────────
  // Firebase tự động refresh token sau mỗi 1 giờ.
  // Dùng hàm này trước mỗi API call quan trọng.
  Future<String?> getIdToken() async {
    try {
      final token = await _auth.currentUser?.getIdToken(true); // force refresh
      if (token != null) {
        await _cacheToken(token);
      }
      return token;
    } catch (_) {
      // Offline hoặc token hết hạn → trả về cache
      return getStoredToken();
    }
  }

  // ── Lấy token đã lưu từ SharedPreferences ─────────────────────────────
  Future<String?> getStoredToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  // ── Nội bộ: lưu token vào SharedPreferences ───────────────────────────
  Future<void> _cacheToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
  }

  // ── Nội bộ: xóa token khi đăng xuất ──────────────────────────────────
  Future<void> _clearToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
  }

  // ── Đăng ký bằng Email/Password ───────────────────────────────────────
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
    // Lưu token ngay sau khi đăng ký thành công
    final token = await credential.user?.getIdToken();
    if (token != null) await _cacheToken(token);
    return credential;
  }

  // ── Đăng nhập bằng Email/Password ─────────────────────────────────────
  Future<UserCredential> signInWithEmail({
    required String email,
    required String password,
  }) async {
    final credential = await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
    // Lưu token ngay sau khi đăng nhập thành công
    final token = await credential.user?.getIdToken();
    if (token != null) await _cacheToken(token);
    return credential;
  }

  // ── Đăng nhập bằng Google ─────────────────────────────────────────────
  // Web  → dùng signInWithPopup (Firebase built-in)
  // Mobile → dùng google_sign_in package
  Future<UserCredential?> signInWithGoogle() async {
    if (kIsWeb) {
      // ── WEB ──────────────────────────────────────────────────────────
      final googleProvider = GoogleAuthProvider()
        ..addScope('email')
        ..addScope('profile');
      final userCredential = await _auth.signInWithPopup(googleProvider);
      final token = await userCredential.user?.getIdToken();
      if (token != null) await _cacheToken(token);
      return userCredential;
    } else {
      // ── MOBILE / DESKTOP ─────────────────────────────────────────────
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return null; // user tự cancel

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

  // ── Quên mật khẩu ─────────────────────────────────────────────────────
  Future<void> sendPasswordResetEmail(String email) async {
    await _auth.sendPasswordResetEmail(email: email);
  }

  // ── Đăng xuất (xóa token cache) ───────────────────────────────────────
  Future<void> signOut() async {
    await _clearToken();
    await Future.wait([
      _googleSignIn.signOut(),
      _auth.signOut(),
    ]);
  }

  // ── Chuyển đổi FirebaseAuthException → thông báo tiếng Việt ───────────
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
