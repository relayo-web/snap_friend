import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:snap_friend/services/firestore_service.dart';
import 'package:snap_friend/pages/user_profile_page.dart';
import 'package:snap_friend/pages/comments_sheet.dart'; // 💬 コメントシートを読み込み

class PostsPage extends StatefulWidget {
  const PostsPage({super.key});

  @override
  State<PostsPage> createState() => _PostsPageState();
}

class _PostsPageState extends State<PostsPage> {
  Stream<List<QueryDocumentSnapshot<Map<String, dynamic>>>>? _postStream;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadPostStream();
  }

  Future<void> _loadPostStream() async {
    try {
      final myUid = FirebaseAuth.instance.currentUser!.uid;
      setState(() {
        _postStream = FirestoreService.feedStream(myUid);
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'エラー: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('投稿一覧')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    if (_error != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('投稿一覧')),
        body: Center(child: Text(_error!)),
      );
    }
    return Scaffold(
      appBar: AppBar(title: const Text('投稿一覧')),
      body: StreamBuilder<List<QueryDocumentSnapshot<Map<String, dynamic>>>>(
        stream: _postStream,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(child: Text('エラーが発生しました'));
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final docs = snapshot.data!;
          if (docs.isEmpty) {
            return const Center(child: Text('投稿はまだありません'));
          }
          return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final doc = docs[index];
              final data = doc.data();
              final imageUrl = data['imageUrl'] as String?;
              final caption = data['caption'] as String? ?? '';
              final ownerId = data['ownerId'] as String?;
              final ts = (data['ts'] as Timestamp?)?.toDate();
              if (imageUrl == null || ownerId == null) return const SizedBox.shrink();

              return _PostCard(
                postId: doc.id,
                imageUrl: imageUrl,
                caption: caption,
                ownerId: ownerId,
                timestamp: ts,
              );
            },
          );
        },
      ),
    );
  }
}

class _PostCard extends StatefulWidget {
  final String postId;
  final String imageUrl;
  final String caption;
  final String ownerId;
  final DateTime? timestamp;

  const _PostCard({
    required this.postId,
    required this.imageUrl,
    required this.caption,
    required this.ownerId,
    this.timestamp,
  });

  @override
  State<_PostCard> createState() => _PostCardState();
}

class _PostCardState extends State<_PostCard> {
  bool _liked = false;
  int _likeCount = 0;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _initLikeState();
  }

  Future<void> _initLikeState() async {
    final liked = await FirestoreService.isLiked(widget.postId);
    final count = await FirestoreService.getLikeCount(widget.postId);
    if (!mounted) return;
    setState(() {
      _liked = liked;
      _likeCount = count;
      _loading = false;
    });
  }

  Future<void> _toggleLike() async {
    if (_loading) return;
    setState(() => _loading = true);
    await FirestoreService.toggleLike(widget.postId, _liked);
    await _initLikeState();
  }

  @override
  Widget build(BuildContext context) {
    final formattedTs = widget.timestamp != null
        ? '${widget.timestamp!.year}/${widget.timestamp!.month.toString().padLeft(2, '0')}/${widget.timestamp!.day.toString().padLeft(2, '0')} '
          '${widget.timestamp!.hour.toString().padLeft(2, '0')}:${widget.timestamp!.minute.toString().padLeft(2, '0')}'
        : '日時不明';

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (widget.imageUrl.isNotEmpty)
            CachedNetworkImage(
              imageUrl: widget.imageUrl,
              width: double.infinity,
              height: 200,
              fit: BoxFit.cover,
              placeholder: (context, url) => const SizedBox(
                height: 200,
                child: Center(child: CircularProgressIndicator()),
              ),
              errorWidget: (context, url, error) => const Icon(Icons.error),
            ),
          if (widget.caption.isNotEmpty)
            Padding(
              padding: const EdgeInsets.all(8),
              child: Text(widget.caption),
            ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              children: [
                IconButton(
                  icon: Icon(
                    _liked ? Icons.favorite : Icons.favorite_border,
                    color: _liked ? Colors.red : Colors.grey,
                  ),
                  onPressed: _toggleLike,
                ),
                Text('$_likeCount'),

                // 💬 コメントボタン
                IconButton(
                  icon: const Icon(Icons.comment_outlined),
                  onPressed: () {
                    showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      builder: (_) => CommentsSheet(postId: widget.postId),
                    );
                  },
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: FutureBuilder<DocumentSnapshot>(
              future: FirebaseFirestore.instance
                  .collection('users')
                  .doc(widget.ownerId)
                  .get(),
              builder: (context, snapshot) {
                final userData = snapshot.data?.data() as Map<String, dynamic>?;
                final name = userData?['displayName'] ?? '名前未設定';
                final iconUrl = userData?['iconURL'] as String?;
                return Row(
                  children: [
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => UserProfilePage(otherUid: widget.ownerId),
                          ),
                        );
                      },
                      child: CircleAvatar(
                        radius: 24,
                        backgroundImage: iconUrl != null && iconUrl.isNotEmpty
                            ? NetworkImage(iconUrl)
                            : null,
                        child: iconUrl == null || iconUrl.isEmpty
                            ? const Icon(Icons.person)
                            : null,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          style: const TextStyle(fontSize: 14, color: Colors.black87),
                        ),
                        Text(
                          formattedTs,
                          style: const TextStyle(fontSize: 12, color: Colors.black54),
                        ),
                      ],
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
