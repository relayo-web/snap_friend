import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FriendRequestService {
  /// フレンドリクエストを送信
  static Future<void> sendRequest(String toUid) async {
    final fromUid = FirebaseAuth.instance.currentUser!.uid;

    await FirebaseFirestore.instance
        .collection('friendRequests')
        .doc(toUid)
        .collection('received')
        .doc(fromUid)
        .set({
      'ts': FieldValue.serverTimestamp(),
    });

    await FirebaseFirestore.instance
        .collection('friendRequests')
        .doc(fromUid)
        .collection('sent')
        .doc(toUid)
        .set({
      'ts': FieldValue.serverTimestamp(),
    });
  }

  /// リクエストを承認（approve）
  static Future<void> approveRequest(String otherUid) async {
    final myUid = FirebaseAuth.instance.currentUser!.uid;
    final timestamp = FieldValue.serverTimestamp();

    // 双方向に friends コレクションを作成
    await FirebaseFirestore.instance
        .collection('users')
        .doc(myUid)
        .collection('friends')
        .doc(otherUid)
        .set({'ts': timestamp});

    await FirebaseFirestore.instance
        .collection('users')
        .doc(otherUid)
        .collection('friends')
        .doc(myUid)
        .set({'ts': timestamp});

    // friendRequests（received / sent）から削除
    await FirebaseFirestore.instance
        .collection('friendRequests')
        .doc(myUid)
        .collection('received')
        .doc(otherUid)
        .delete();

    await FirebaseFirestore.instance
        .collection('friendRequests')
        .doc(otherUid)
        .collection('sent')
        .doc(myUid)
        .delete();
  }
}
