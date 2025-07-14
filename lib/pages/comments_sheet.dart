import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/firestore_service.dart';

class CommentsSheet extends StatefulWidget {
  final String postId;
  const CommentsSheet({Key? key, required this.postId}) : super(key: key);

  @override
  State<CommentsSheet> createState() => _CommentsSheetState();
}

class _CommentsSheetState extends State<CommentsSheet> {
  final TextEditingController _controller = TextEditingController();
  bool _sending = false;

  @override
  Widget build(BuildContext context) {
    final padding = MediaQuery.of(context).viewInsets;

    return Padding(
      padding: padding,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 12),
          const Text('コメント', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const Divider(),

          // コメント一覧表示
          Flexible(
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: FirestoreService.commentStream(widget.postId),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const CircularProgressIndicator();
                final docs = snapshot.data!.docs;

                return ListView.builder(
                  shrinkWrap: true,
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final data = docs[index].data();
                    return ListTile(
                      leading: const CircleAvatar(child: Icon(Icons.person)), // ← 今後iconURL表示に拡張可
                      title: Text(data['text'] ?? ''),
                      subtitle: Text(data['ownerId'] ?? ''),
                    );
                  },
                );
              },
            ),
          ),

          // コメント送信欄
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    maxLength: 300,
                    decoration: const InputDecoration(
                      hintText: 'コメントを入力',
                      counterText: '',
                    ),
                  ),
                ),
                IconButton(
                  icon: _sending ? const CircularProgressIndicator() : const Icon(Icons.send),
                  onPressed: _sending || _controller.text.trim().isEmpty
                      ? null
                      : () async {
                          setState(() => _sending = true);
                          await FirestoreService.addComment(widget.postId, _controller.text);
                          _controller.clear();
                          setState(() => _sending = false);
                        },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
