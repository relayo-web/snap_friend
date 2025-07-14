import {
  initializeTestEnvironment,
  assertFails,
  assertSucceeds,
} from '@firebase/rules-unit-testing';
import { readFileSync } from 'fs';

const rules = readFileSync('../firestore.rules', 'utf8');
let env: any;

beforeAll(async () => {
  env = await initializeTestEnvironment({
    projectId: 'snap-friend-dev',
    firestore: { rules },
  });
});

afterAll(async () => await env.cleanup());

describe('posts security rules', () => {
  /* 投稿者本人なら create できる */
  it('allows post create if uid matches', async () => {
    const ctx = env.authenticatedContext('user_123');
    await assertSucceeds(
      ctx.firestore()
         .collection('posts')
         .doc('post_ok')                             // ← 新規ドキュメント
         .set({ ownerId: 'user_123', imageUrl: 'url', createdAt: Date.now() })
    );
  });

  /* 他人の UID を ownerId にして create すると拒否される */
  it('denies post create if uid mismatches', async () => {
    const ctx = env.authenticatedContext('user_123');
    await assertFails(
      ctx.firestore()
         .collection('posts')
         .doc('post_ng')                             // ← 別 ID で新規作成
         .set({ ownerId: 'other_user', imageUrl: 'url', createdAt: Date.now() })
    );
  });
});
