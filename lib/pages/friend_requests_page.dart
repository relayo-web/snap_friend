import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FriendRequestsPage extends StatefulWidget {
  const FriendRequestsPage({super.key});

  @override
  State<FriendRequestsPage> createState() => _FriendRequestsPageState();
}

class _FriendRequestsPageState extends State<FriendRequestsPage>
    with SingleTickerProviderStateMixin {
  late TabController _tab;

  String get uid => FirebaseAuth.instance.currentUser!.uid;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 2, vsync: this);
  }

  /// 受信 or 送信サブコレクションをストリームで取得
  Stream<QuerySnapshot<Map<String, dynamic>>> _reqStream(String sub) {
    return FirebaseFirestore.instance
        .collection('friendRequests')
        .doc(uid)
        .collection(sub) // 'received' or 'sent'
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  /// Firestore ドキュメントを削除して「拒否」「取消」を実行
  Future<void> _removeRequest({
    required String sub,
    required String otherUid,
    required String action,
  }) async {
    final doc = FirebaseFirestore.instance
        .collection('friendRequests')
        .doc(uid)
        .collection(sub)
        .doc(otherUid);

    await doc.delete();

    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text('✅ $actionしました')));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('フレンド申請'),
        bottom: TabBar(
          controller: _tab,
          tabs: const [
            Tab(text: '受信'),
            Tab(text: '送信'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tab,
        children: [
          // 受信タブ：拒否ボタン
          _buildList(
            stream: _reqStream('received'),
            buttonLabel: '拒否',
            onPressed: (otherUid) => _removeRequest(
              sub: 'received',
              otherUid: otherUid,
              action: '拒否',
            ),
          ),

          // 送信タブ：取消ボタン
          _buildList(
            stream: _reqStream('sent'),
            buttonLabel: '取消',
            onPressed: (otherUid) => _removeRequest(
              sub: 'sent',
              otherUid: otherUid,
              action: '取消',
            ),
          ),
        ],
      ),
    );
  }

  /// 共通リスト UI
  Widget _buildList({
    required Stream<QuerySnapshot<Map<String, dynamic>>> stream,
    required String buttonLabel,
    required Function(String) onPressed,
  }) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: stream,
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final docs = snap.data?.docs ?? [];
        if (docs.isEmpty) {
          return const Center(child: Text('申請はありません'));
        }
        return ListView.separated(
          itemCount: docs.length,
          separatorBuilder: (_, __) => const Divider(height: 0),
          itemBuilder: (_, i) {
            final data = docs[i].data();
            final otherUid = docs[i].id;
            final displayName = data['displayName'] ?? otherUid;

            return ListTile(
              leading: const CircleAvatar(child: Icon(Icons.person)),
              title: Text(displayName),
              trailing: TextButton(
                onPressed: () => onPressed(otherUid),
                child: Text(buttonLabel),
              ),
            );
          },
        );
      },
    );
  }
}
