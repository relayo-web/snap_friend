import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FriendsPage extends StatefulWidget {
  const FriendsPage({super.key});

  @override
  State<FriendsPage> createState() => _FriendsPageState();
}

class _FriendsPageState extends State<FriendsPage> {
  final _searchController = TextEditingController();
  String _keyword = '';

  /// 現ログイン UID
  String get uid => FirebaseAuth.instance.currentUser!.uid;

  /// 友だちリストを検索付きで取得
  Stream<QuerySnapshot<Map<String, dynamic>>> _friendsStream() {
    final col = FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('friends');

    if (_keyword.isEmpty) {
      return col.orderBy('createdAt', descending: true).snapshots();
    }

    // displayName 前方一致検索
    return col
        .where('displayName',
            isGreaterThanOrEqualTo: _keyword,
            isLessThan: '$_keyword\uf8ff')
        .snapshots();
  }

  /// 削除／ブロック共通ダイアログ
  Future<void> _confirmAndRun(
      {required BuildContext ctx,
      required String friendUid,
      required String action}) async {
    final ok = await showDialog<bool>(
      context: ctx,
      builder: (_) => AlertDialog(
        title: Text('$actionしますか？'),
        content: const Text('取り消すことはできません。'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('キャンセル')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('OK')),
        ],
      ),
    );

    if (ok != true) return;

    final doc = FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('friends')
        .doc(friendUid);

    if (action == '削除') {
      await doc.delete();
    } else if (action == 'ブロック') {
      await doc.update({'blocked': true});
    }

    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text('✅ $actionしました')));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('友だち一覧')),
      body: Column(
        children: [
          // 🔍 検索バー
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search),
                hintText: 'displayName で検索',
                suffixIcon: _keyword.isEmpty
                    ? null
                    : IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _keyword = '');
                        },
                      ),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onChanged: (v) => setState(() => _keyword = v.trim()),
            ),
          ),
          const Divider(height: 0),
          // 📜 友だち一覧
          Expanded(
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: _friendsStream(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                final docs = snapshot.data?.docs ?? [];
                if (docs.isEmpty) {
                  return const Center(child: Text('友だちが見つかりません'));
                }
                return ListView.separated(
                  itemCount: docs.length,
                  separatorBuilder: (_, __) => const Divider(height: 0),
                  itemBuilder: (ctx, i) {
                    final data = docs[i].data();
                    final friendUid = docs[i].id;
                    final displayName = data['displayName'] ?? '名無し';
                    final blocked = data['blocked'] == true;

                    return Dismissible(
                      key: ValueKey(friendUid),
                      background: Container(
                        color: Colors.red,
                        alignment: Alignment.centerLeft,
                        padding: const EdgeInsets.only(left: 20),
                        child: const Icon(Icons.delete, color: Colors.white),
                      ),
                      secondaryBackground: Container(
                        color: Colors.orange,
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.only(right: 20),
                        child: const Icon(Icons.block, color: Colors.white),
                      ),
                      confirmDismiss: (direction) async {
                        final action =
                            direction == DismissDirection.startToEnd ? '削除' : 'ブロック';
                        await _confirmAndRun(
                            ctx: ctx, friendUid: friendUid, action: action);
                        return false; // 自前で削除したのでスワイプUIだけ戻す
                      },
                      child: ListTile(
                        leading: const CircleAvatar(child: Icon(Icons.person)),
                        title: Text(displayName),
                        subtitle: blocked ? const Text('🔒 ブロック中') : null,
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
