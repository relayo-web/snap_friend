import { initializeTestEnvironment, RulesTestEnvironment } from '@firebase/rules-unit-testing';
import { doc, setDoc, updateDoc, deleteDoc } from 'firebase/firestore';
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

describe('comments subcollection under posts', () => {
  const user = 'alice';
  const other = 'bob';
  const postId = 'post456';
  const commentId = 'cmt1';

  const validComment = {
    id: commentId,
    ownerId: user,
    text: 'これは有効なコメントです。',
    ts: new Date().toISOString(),
  };

  const invalidComment = {
    id: commentId,
    ownerId: user,
    text: 'あ'.repeat(301), // 301文字超過
    ts: new Date().toISOString(),
  };

  it('allows user to create a valid comment (<= 300 chars)', async () => {
    const ctx = env.authenticatedContext(user);
    const db = ctx.firestore();

    await expect(
      setDoc(doc(db, 'posts', postId, 'comments', commentId), validComment)
    ).resolves.toBeUndefined();
  });

  it('denies user to create an invalid comment (> 300 chars)', async () => {
    const ctx = env.authenticatedContext(user);
    const db = ctx.firestore();

    await expect(
      setDoc(doc(db, 'posts', postId, 'comments', 'cmt2'), invalidComment)
    ).rejects.toThrow();
  });

  it('allows owner to update their comment', async () => {
    const ctx = env.authenticatedContext(user);
    const db = ctx.firestore();

    await setDoc(doc(db, 'posts', postId, 'comments', commentId), validComment);
    await expect(
      updateDoc(doc(db, 'posts', postId, 'comments', commentId), { text: '修正済みコメント' })
    ).resolves.toBeUndefined();
  });

  it('denies other users from updating someone else’s comment', async () => {
    const ctx = env.authenticatedContext(other);
    const db = ctx.firestore();

    await expect(
      updateDoc(doc(db, 'posts', postId, 'comments', commentId), { text: 'なりすまし' })
    ).rejects.toThrow();
  });

  it('allows owner to delete their comment', async () => {
    const ctx = env.authenticatedContext(user);
    const db = ctx.firestore();

    await expect(
      deleteDoc(doc(db, 'posts', postId, 'comments', commentId))
    ).resolves.toBeUndefined();
  });

  it('denies other users from deleting someone else’s comment', async () => {
    const ctx = env.authenticatedContext(other);
    const db = ctx.firestore();

    await expect(
      deleteDoc(doc(db, 'posts', postId, 'comments', commentId))
    ).rejects.toThrow();
  });
});
