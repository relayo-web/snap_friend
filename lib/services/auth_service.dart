import 'package:firebase_auth/firebase_auth.dart';

/// 認証関連サービス
class AuthService {
  AuthService._();
  static final AuthService instance = AuthService._();

  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// 現在のユーザー取得
  User? get currentUser => _auth.currentUser;

  /// 匿名ログイン（初期用）
  Future<void> signInAnonymouslyIfNeeded() async {
    if (_auth.currentUser == null) {
      await _auth.signInAnonymously();
    }
  }

  /// メールアドレスでログイン
  Future<UserCredential> signInWithEmail({
    required String email,
    required String password,
  }) async {
    return await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  /// メールアドレスで新規登録
  Future<UserCredential> registerWithEmail({
    required String email,
    required String password,
  }) async {
    return await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  /// 匿名アカウントをメール認証アカウントへ昇格
  Future<void> linkAnonymousWithEmail({
    required String email,
    required String password,
  }) async {
    final cred = EmailAuthProvider.credential(
      email: email,
      password: password,
    );
    await _auth.currentUser!.linkWithCredential(cred);
  }

  /// サインアウト（匿名 or メール問わず）
  Future<void> signOut() async {
    await _auth.signOut();
  }

  /// メール認証ユーザーかチェック
  bool isEmailUser() {
    final user = _auth.currentUser;
    return user != null && !user.isAnonymous;
  }
}
