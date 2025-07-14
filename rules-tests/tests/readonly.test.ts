import { initializeTestEnvironment, RulesTestEnvironment } from '@firebase/rules-unit-testing';
import { doc, setDoc, getDoc, updateDoc, deleteDoc } from 'firebase/firestore';
import fs from 'fs';

let env: RulesTestEnvironment;

beforeAll(async () => {
  env = await initializeTestEnvironment({
    projectId: 'snap-friend',
    firestore: {
      rules: fs.readFileSync('../firestore.rules', 'utf8'),
    },
  });

  // 🔑 事前データは「ルール無効化」で注入
  await env.withSecurityRulesDisabled(async (ctx) => {
    const db = ctx.firestore();

    // feeds/{alice}/posts/post1
    await setDoc(doc(db, 'feeds', 'alice', 'posts', 'post1'), {
      ownerId: 'alice',
      postId: 'post1',
    });

    // sessions/session123
    await setDoc(doc(db, 'sessions', 'session123'), {
      participants: ['alice', 'bob'],
      active: false,
      createdAt: new Date(),          // ← Timestamp として格納
    });
  });
});

afterAll(async () => {
  await env.cleanup();
});

describe('readonly access - feeds & sessions', () => {
  const user      = 'alice';
  const friend    = 'bob';
  const stranger  = 'carol';
  const sessionId = 'session123';

  /* ---------- feeds ---------- */

  it('allows user to read their own feed', async () => {
    const db = env.authenticatedContext(user).firestore();
    await expect(
      getDoc(doc(db, 'feeds', user, 'posts', 'post1'))
    ).resolves.toBeDefined();
  });

  it('denies any write to feeds', async () => {
    const db = env.authenticatedContext(user).firestore();
    await expect(
      setDoc(doc(db, 'feeds', user, 'posts', 'post1'), { dummy: true })
    ).rejects.toThrow();
    await expect(
      updateDoc(doc(db, 'feeds', user, 'posts', 'post1'), { dummy: true })
    ).rejects.toThrow();
    await expect(
      deleteDoc(doc(db, 'feeds', user, 'posts', 'post1'))
    ).rejects.toThrow();
  });

  /* ---------- sessions ---------- */

  it('allows participant to read session', async () => {
    const db = env.authenticatedContext(user).firestore();
    await expect(
      getDoc(doc(db, 'sessions', sessionId))
    ).resolves.toBeDefined();
  });

  it('denies non-participant from reading session', async () => {
    const db = env.authenticatedContext(stranger).firestore();
    await expect(
      getDoc(doc(db, 'sessions', sessionId))
    ).rejects.toThrow();
  });

  it('allows participant to update session', async () => {
    const db = env.authenticatedContext(user).firestore();
    await expect(
      updateDoc(doc(db, 'sessions', sessionId), { active: true })
    ).resolves.toBeUndefined();
  });

  it('denies everyone from deleting session', async () => {
    const dbUser = env.authenticatedContext(user).firestore();
    const dbStr  = env.authenticatedContext(stranger).firestore();

    await expect(
      deleteDoc(doc(dbUser, 'sessions', sessionId))
    ).rejects.toThrow();
    await expect(
      deleteDoc(doc(dbStr, 'sessions', sessionId))
    ).rejects.toThrow();
  });
});
