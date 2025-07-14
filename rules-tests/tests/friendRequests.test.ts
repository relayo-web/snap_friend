import { initializeTestEnvironment, RulesTestEnvironment } from '@firebase/rules-unit-testing';
import { doc, setDoc, deleteDoc, getDoc } from 'firebase/firestore';
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

describe('friendRequests', () => {
  const sender = 'alice';
  const receiver = 'bob';

  it('allows sender to create sent and received request', async () => {
    const ctx = env.authenticatedContext(sender);
    const db = ctx.firestore();

    // sent/{toUid}
    await expect(
      setDoc(doc(db, 'friendRequests', sender, 'sent', receiver), {
        fromUid: sender,
        toUid: receiver,
        ts: new Date().toISOString(),
      })
    ).resolves.toBeUndefined();

    // received/{fromUid}
    await expect(
      setDoc(doc(db, 'friendRequests', receiver, 'received', sender), {
        fromUid: sender,
        toUid: receiver,
        ts: new Date().toISOString(),
      })
    ).resolves.toBeUndefined();
  });

  it('denies others from writing to received/sent', async () => {
    const ctx = env.authenticatedContext('charlie');
    const db = ctx.firestore();

    await expect(
      setDoc(doc(db, 'friendRequests', receiver, 'received', sender), {
        fromUid: sender,
        toUid: receiver,
        ts: new Date().toISOString(),
      })
    ).rejects.toThrow();
  });

  it('allows sender and receiver to delete the requests', async () => {
    const db1 = env.authenticatedContext(sender).firestore();
    const db2 = env.authenticatedContext(receiver).firestore();

    await expect(
      deleteDoc(doc(db1, 'friendRequests', sender, 'sent', receiver))
    ).resolves.toBeUndefined();

    await expect(
      deleteDoc(doc(db2, 'friendRequests', receiver, 'received', sender))
    ).resolves.toBeUndefined();
  });

  it('denies other user from deleting any request', async () => {
    const ctx = env.authenticatedContext('david');
    const db = ctx.firestore();

    await expect(
      deleteDoc(doc(db, 'friendRequests', sender, 'sent', receiver))
    ).rejects.toThrow();

    await expect(
      deleteDoc(doc(db, 'friendRequests', receiver, 'received', sender))
    ).rejects.toThrow();
  });

  it('allows sender and receiver to read their own requests', async () => {
    const db1 = env.authenticatedContext(sender).firestore();
    const db2 = env.authenticatedContext(receiver).firestore();

    await expect(
      getDoc(doc(db1, 'friendRequests', sender, 'sent', receiver))
    ).resolves.toBeDefined();

    await expect(
      getDoc(doc(db2, 'friendRequests', receiver, 'received', sender))
    ).resolves.toBeDefined();
  });
});
