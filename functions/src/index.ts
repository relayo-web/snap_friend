import * as functions from "firebase-functions";
import * as admin from "firebase-admin";

admin.initializeApp();

export const onPostCreate = functions.firestore
  .document("posts/{postId}")
  .onCreate(async (snap, context) => {
    const post = snap.data();
    const ownerId = post.ownerId as string;
    const postId = context.params.postId;

    const db = admin.firestore();

    // 投稿者自身 + フレンド一覧を取得
    const targetUids = new Set<string>([ownerId]);

    const friendsSnap = await db
      .collection("users")
      .doc(ownerId)
      .collection("friends")
      .get();

    friendsSnap.forEach((doc) => targetUids.add(doc.id));

    // feeds/{uid}/posts/{postId} に複製（batch 書き込み）
    const batch = db.batch();
    for (const uid of targetUids) {
      const ref = db
        .collection("feeds")
        .doc(uid)
        .collection("posts")
        .doc(postId);

      batch.set(ref, post);
    }

    await batch.commit();
    console.log(
      `Post ${postId} fan-out to ${targetUids.size} feeds.`
    );
  });
