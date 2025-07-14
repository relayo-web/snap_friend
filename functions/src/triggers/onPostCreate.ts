// functions/src/triggers/onPostCreate.ts

import * as functions from "firebase-functions"; // ✅ v1 API
import * as admin from "firebase-admin";

const db = admin.firestore();

export const fanOutPostToFeeds = functions.firestore
  .document("posts/{postId}")
  .onCreate(async (snap, ctx) => {
    const post = snap.data();
    const postId = ctx.params.postId;
    const ownerId = post.ownerId;

    if (!ownerId) {
      console.error("Missing ownerId in post:", postId);
      return;
    }

    const friendsSnap = await db
      .collection("users")
      .doc(ownerId)
      .collection("friends")
      .where("blocked", "==", false)
      .get();

    const batch = db.batch();

    friendsSnap.forEach((doc) => {
      const feedRef = db
        .collection("feeds")
        .doc(doc.id)
        .collection("posts")
        .doc(postId);
      batch.set(feedRef, post);
    });

    // 自分のフィードにも複製
    const selfFeedRef = db
      .collection("feeds")
      .doc(ownerId)
      .collection("posts")
      .doc(postId);
    batch.set(selfFeedRef, post);

    await batch.commit();
    console.log(`Post ${postId} fan-out to ${friendsSnap.size + 1} users`);
  });
