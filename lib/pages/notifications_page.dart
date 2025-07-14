import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/firestore_service.dart';

class NotificationsPage extends StatelessWidget {
  const NotificationsPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final stream = FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('notifications')
        .orderBy('ts', descending: true)
        .snapshots();

    return Scaffold(
      appBar: AppBar(title: const Text('通知')),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: stream,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('エラーが発生しました: \${snapshot.error}'));
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final docs = snapshot.data!.docs;
          if (docs.isEmpty) {
            return const Center(child: Text('通知はありません'));
          }
          return ListView.separated(
            itemCount: docs.length,
            separatorBuilder: (_, __) => const Divider(height: 0),
            itemBuilder: (context, index) {
              final data = docs[index].data();
              final unread = data['read'] == false;
              final fromUid = data['fromUid'] as String? ?? '';
              final postId = data['postId'] as String? ?? '';
              final type = data['type'] as String? ?? 'comment';

              return FutureBuilder<String>(
                future: FirestoreService.getDisplayName(fromUid),
                builder: (context, userSnap) {
                  final name = userSnap.data ?? fromUid;
                  final message = type == 'comment'
                      ? '\$name があなたの投稿にコメントしました'
                      : '\$name があなたの投稿にリアクションしました';

                  return ListTile(
                    tileColor: unread ? Colors.blue.shade50 : null,
                    leading: Icon(
                      type == 'comment' ? Icons.comment : Icons.favorite,
                      color: unread ? Theme.of(context).colorScheme.primary : null,
                    ),
                    title: Text(message),
                    onTap: () async {
                      // TODO: 投稿詳細画面へ遷移する
                      await docs[index].reference.update({'read': true});
                    },
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
