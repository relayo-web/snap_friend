import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Firestore 関連サービス
class FirestoreService {
  static final FirebaseFirestore _db = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  /// feeds/{uid}/posts から最新の投稿を取得
  static Stream<List<QueryDocumentSnapshot<Map<String, dynamic>>>> feedStream(String uid) {
    return _db
        .collection('feeds')
        .doc(uid)
        .collection('posts')
        .orderBy('ts', descending: true)
        .snapshots()
        .map((snap) => snap.docs);
  }

  /// UID から displayName を取得
  static Future<String> getDisplayName(String uid) async {
    final doc = await _db.collection('users').doc(uid).get();
    if (doc.exists) {
      return doc.data()?['displayName'] as String? ?? '名前未設定';
    }
    return '不明なユーザー';
  }

  /// UID から iconURL を取得
  static Future<String> getUserIconURL(String uid) async {
    final doc = await _db.collection('users').doc(uid).get();
    if (doc.exists) {
      return doc.data()?['iconURL'] as String? ?? '';
    }
    return '';
  }

  /// 投稿を追加（Cloud Functions が feeds へ自動複製）
  static Future<void> addPost({
    required String imageUrl,
    required String caption,
  }) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) throw Exception('ログインしていません');

    final postDoc = _db.collection('posts').doc();
    final postData = {
      'id': postDoc.id,
      'imageUrl': imageUrl,
      'caption': caption,
      'ts': Timestamp.now(),
      'ownerId': uid,
    };
    await postDoc.set(postData);
  }

  // === いいね系 ===

  /// 自分がこの投稿をいいね済みか
  static Future<bool> isLiked(String postId) async {
    final uid = _auth.currentUser!.uid;
    final doc = await _db
        .collection('posts')
        .doc(postId)
        .collection('likes')
        .doc(uid)
        .get();
    return doc.exists;
  }

  /// いいねをトグル（付ける or 外す）
  static Future<void> toggleLike(String postId, bool currentlyLiked) async {
    final uid = _auth.currentUser!.uid;
    final ref = _db.collection('posts').doc(postId).collection('likes').doc(uid);
    if (currentlyLiked) {
      await ref.delete();
    } else {
      await ref.set({'createdAt': FieldValue.serverTimestamp()});
    }
  }

  /// いいね数を取得（集約クエリ）
  static Future<int> getLikeCount(String postId) async {
    final agg = await _db
        .collection('posts')
        .doc(postId)
        .collection('likes')
        .count()
        .get();
    return agg.count ?? 0;
  }

  /// === コメント系 ===

  /// コメント一覧を取得（QuerySnapshot をそのまま返す）
  static Stream<QuerySnapshot<Map<String, dynamic>>> commentStream(String postId) {
    return _db
        .collection('posts')
        .doc(postId)
        .collection('comments')
        .orderBy('ts', descending: true)
        .snapshots();
  }

  /// コメントを追加
  static Future<void> addComment(String postId, String text) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) throw Exception('ログインしていません');

    final trimmed = text.trim();
    if (trimmed.isEmpty) throw Exception('コメントが入力されていません');

    final docRef = _db
        .collection('posts')
        .doc(postId)
        .collection('comments')
        .doc();
    await docRef.set({
      'id': docRef.id,
      'ownerId': uid,
      'text': trimmed,
      'ts': FieldValue.serverTimestamp(),
    });
  }

  /// コメントを更新
  static Future<void> updateComment(String postId, String commentId, String newText) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) throw Exception('ログインしていません');

    final trimmed = newText.trim();
    if (trimmed.isEmpty) throw Exception('コメントが入力されていません');

    final ref = _db
        .collection('posts')
        .doc(postId)
        .collection('comments')
        .doc(commentId);
    await ref.update({'text': trimmed});
  }

  /// コメントを削除
  static Future<void> deleteComment(String postId, String commentId) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) throw Exception('ログインしていません');

    final ref = _db
        .collection('posts')
        .doc(postId)
        .collection('comments')
        .doc(commentId);
    await ref.delete();
  }

  /// 投稿の DocumentReference を取得（一覧描画で利用）
  static DocumentReference<Map<String, dynamic>> postRef(String postId) {
    return _db.collection('posts').doc(postId);
  }
}