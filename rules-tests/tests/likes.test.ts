import { initializeTestEnvironment, RulesTestEnvironment } from '@firebase/rules-unit-testing';
import { setDoc, deleteDoc, doc } from 'firebase/firestore';
import fs from 'fs';

let env: RulesTestEnvironment;

beforeAll(async () => {
  env = await initializeTestEnvironment({
    projectId: 'snap-friend',
    firestore: {
      rules: fs.readFileSync('../firestore.rules', 'utf8'),
    },
  });
});

afterAll(async () => {
  await env.cleanup();
});

describe('likes subcollection under posts', () => {
  const user = 'alice';
  const other = 'bob';
  const postId = 'post123';
  const likeId = `${user}_${postId}`; // e.g. "alice_post123"

  it('allows authenticated user to like a post', async () => {
    const ctx = env.authenticatedContext(user);
    const db = ctx.firestore();

    await expect(
      setDoc(doc(db, 'posts', postId, 'likes', likeId), {
        ownerId: user,
        postId: postId,
      })
    ).resolves.toBeUndefined();
  });

  it('denies unauthenticated user from liking a post', async () => {
    const ctx = env.unauthenticatedContext();
    const db = ctx.firestore();

    await expect(
      setDoc(doc(db, 'posts', postId, 'likes', likeId), {
        ownerId: user,
        postId: postId,
      })
    ).rejects.toThrow();
  });

  it('allows owner to delete like', async () => {
    const ctx = env.authenticatedContext(user);
    const db = ctx.firestore();

    await expect(
      deleteDoc(doc(db, 'posts', postId, 'likes', likeId))
    ).resolves.toBeUndefined();
  });

  it('denies other user from deleting someone else’s like', async () => {
    const ctx = env.authenticatedContext(other);
    const db = ctx.firestore();

    await expect(
      deleteDoc(doc(db, 'posts', postId, 'likes', likeId))
    ).rejects.toThrow();
  });
});
