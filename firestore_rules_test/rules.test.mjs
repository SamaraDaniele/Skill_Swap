// Security Rules tests for ../firestore.rules.
// Run with the Firestore Emulator (see README in this folder):
//   firebase emulators:exec --only firestore --project demo-skill-swap "npm test"
// The "demo-" project id keeps everything local; nothing reaches Firebase.
import { after, before, beforeEach, describe, test } from 'node:test';
import { readFileSync } from 'node:fs';
import assert from 'node:assert/strict';
import {
  assertFails,
  assertSucceeds,
  initializeTestEnvironment,
} from '@firebase/rules-unit-testing';
import {
  Bytes,
  collection,
  deleteDoc,
  deleteField,
  doc,
  getDoc,
  getDocs,
  limit,
  query,
  serverTimestamp,
  setDoc,
  Timestamp,
  updateDoc,
  where,
  writeBatch,
} from 'firebase/firestore';

const [host, port] = (process.env.FIRESTORE_EMULATOR_HOST ?? '127.0.0.1:8080').split(':');
let env;

// Fictional users. Ids sort as ana < bia < caio < davi.
const ANA = 'ana';
const BIA = 'bia';
const CAIO = 'caio';
const MATCH_AB = 'ana_bia';

const db = (uid) => env.authenticatedContext(uid).firestore();
const anon = () => env.unauthenticatedContext().firestore();

const profile = (overrides = {}) => ({
  name: 'Ana Teste',
  bio: 'Ensino Excel.',
  teach: ['excel'],
  learn: ['english'],
  updatedAt: serverTimestamp(),
  ...overrides,
});

const like = (from, to, liked = true) => ({
  from,
  to,
  liked,
  createdAt: serverTimestamp(),
});

const newMatch = (overrides = {}) => ({
  userIds: [ANA, BIA],
  status: 'active',
  lastMessage: null,
  lastMessageId: null,
  createdAt: serverTimestamp(),
  lastMessageAt: serverTimestamp(),
  ...overrides,
});

const message = (senderId, text = 'Oi') => ({
  senderId,
  text,
  createdAt: serverTimestamp(),
});

// Writes fixtures bypassing the rules.
async function seed(writes) {
  await env.withSecurityRulesDisabled(async (ctx) => {
    const fs = ctx.firestore();
    for (const [path, data] of Object.entries(writes)) {
      await setDoc(doc(fs, path), data);
    }
  });
}

const seededProfile = (name, teach, learn) => ({
  name,
  bio: '',
  teach,
  learn,
  updatedAt: Timestamp.now(),
});

const seededLike = (from, to, liked = true) => ({
  from,
  to,
  liked,
  createdAt: Timestamp.now(),
});

const seededMatch = (status = 'active') => ({
  userIds: [ANA, BIA],
  status,
  lastMessage: null,
  lastMessageId: null,
  createdAt: Timestamp.now(),
  lastMessageAt: Timestamp.now(),
});

before(async () => {
  env = await initializeTestEnvironment({
    projectId: 'demo-skill-swap',
    firestore: {
      rules: readFileSync(new URL('../firestore.rules', import.meta.url), 'utf8'),
      host,
      port: Number(port),
    },
  });
});

beforeEach(async () => {
  await env.clearFirestore();
  await seed({
    [`users/${ANA}`]: seededProfile('Ana', ['excel'], ['english']),
    [`users/${BIA}`]: seededProfile('Bia', ['english'], ['excel']),
    [`users/${CAIO}`]: seededProfile('Caio', ['guitar'], ['excel']),
  });
});

after(async () => {
  await env?.cleanup();
});

describe('users', () => {
  test('signed-out visitors cannot read profiles', async () => {
    await assertFails(getDoc(doc(anon(), `users/${ANA}`)));
  });

  test('signed-in users can read a profile', async () => {
    await assertSucceeds(getDoc(doc(db(BIA), `users/${ANA}`)));
  });

  test('owner can update a valid profile', async () => {
    await assertSucceeds(setDoc(doc(db(ANA), `users/${ANA}`), profile()));
  });

  test('nobody can write another person\'s profile', async () => {
    await assertFails(setDoc(doc(db(BIA), `users/${ANA}`), profile({ name: 'Hacked' })));
  });

  test('[M3] skills outside the catalog are rejected', async () => {
    await assertFails(
      setDoc(doc(db(ANA), `users/${ANA}`), profile({ teach: ['excel', 'BUY CHEAP STUFF'] })),
    );
    await assertFails(setDoc(doc(db(ANA), `users/${ANA}`), profile({ learn: [42] })));
  });

  test('[M3] more skills than the catalog has are rejected', async () => {
    await assertFails(
      setDoc(doc(db(ANA), `users/${ANA}`), profile({ teach: Array(21).fill('excel') })),
    );
  });

  test('blank or oversized fields are rejected', async () => {
    await assertFails(setDoc(doc(db(ANA), `users/${ANA}`), profile({ name: '   ' })));
    await assertFails(setDoc(doc(db(ANA), `users/${ANA}`), profile({ name: 'x'.repeat(41) })));
    await assertFails(setDoc(doc(db(ANA), `users/${ANA}`), profile({ bio: 'x'.repeat(161) })));
  });

  test('extra fields are rejected', async () => {
    await assertFails(setDoc(doc(db(ANA), `users/${ANA}`), profile({ isAdmin: true })));
  });

  test('[L1] forged timestamps are rejected', async () => {
    await assertFails(
      setDoc(doc(db(ANA), `users/${ANA}`), profile({ updatedAt: Timestamp.fromDate(new Date(2000, 0, 1)) })),
    );
  });

  test('[M4] listing users requires a limit of at most 50', async () => {
    const users = collection(db(ANA), 'users');
    await assertSucceeds(getDocs(query(users, where('teach', 'array-contains-any', ['english']), limit(50))));
    await assertFails(getDocs(query(users, limit(51))));
    await assertFails(getDocs(users));
  });

  // Bytes of a fake JPEG: FF D8 FF signature, then filler.
  const jpeg = (size) => {
    const bytes = new Uint8Array(size).fill(0x11);
    bytes.set([0xff, 0xd8, 0xff, 0xe0]);
    return Bytes.fromUint8Array(bytes);
  };

  test('[photo] owner can add, replace and remove a JPEG photo', async () => {
    const ref = doc(db(ANA), `users/${ANA}`);
    await assertSucceeds(setDoc(ref, profile({ photo: jpeg(30 * 1024) })));
    await assertSucceeds(setDoc(ref, profile({ photo: jpeg(49152) }), { merge: true }));
    await assertSucceeds(setDoc(ref, profile({ photo: deleteField() }), { merge: true }));
    const stored = await getDoc(ref);
    assert.equal(stored.data().photo, undefined);
  });

  test('[photo] photos over 48 KiB are rejected', async () => {
    await assertFails(setDoc(doc(db(ANA), `users/${ANA}`), profile({ photo: jpeg(49153) })));
  });

  test('[photo] non-JPEG, empty or non-binary photos are rejected', async () => {
    const ref = doc(db(ANA), `users/${ANA}`);
    const png = new Uint8Array(1024);
    png.set([0x89, 0x50, 0x4e, 0x47, 0x0d, 0x0a, 0x1a, 0x0a]);
    await assertFails(setDoc(ref, profile({ photo: Bytes.fromUint8Array(png) })));
    await assertFails(setDoc(ref, profile({ photo: Bytes.fromUint8Array(new Uint8Array(0)) })));
    await assertFails(setDoc(ref, profile({ photo: 'https://evil.example/tracker.jpg' })));
    await assertFails(setDoc(ref, profile({ photo: '/9j/AAAA' })));
    await assertFails(setDoc(ref, profile({ photo: null })));
  });

  test("[photo] nobody can set a photo on another person's profile", async () => {
    await assertFails(
      setDoc(doc(db(BIA), `users/${ANA}`), profile({ photo: jpeg(1024) }), { merge: true }),
    );
  });

  test('[photo] a new profile with photo still requires consent', async () => {
    await env.clearFirestore();
    await assertFails(setDoc(doc(db(ANA), `users/${ANA}`), profile({ photo: jpeg(1024) })));
  });

  test('owner can delete their profile, others cannot', async () => {
    await assertFails(deleteDoc(doc(db(BIA), `users/${ANA}`)));
    await assertSucceeds(deleteDoc(doc(db(ANA), `users/${ANA}`)));
  });
});

describe('likes', () => {
  test('a user can like another user', async () => {
    await assertSucceeds(setDoc(doc(db(ANA), `likes/${ANA}_${BIA}`), like(ANA, BIA)));
  });

  test('a like cannot be written in someone else\'s name', async () => {
    await assertFails(setDoc(doc(db(ANA), `likes/${BIA}_${ANA}`), like(BIA, ANA)));
    await assertFails(setDoc(doc(db(ANA), `likes/${ANA}_${BIA}`), like(BIA, ANA)));
  });

  test('document id must match from/to', async () => {
    await assertFails(setDoc(doc(db(ANA), `likes/${ANA}_${CAIO}`), like(ANA, BIA)));
  });

  test('cannot like yourself or a user that does not exist', async () => {
    await assertFails(setDoc(doc(db(ANA), `likes/${ANA}_${ANA}`), like(ANA, ANA)));
    await assertFails(setDoc(doc(db(ANA), `likes/${ANA}_ghost`), like(ANA, 'ghost')));
  });

  test('[L1] forged timestamps and extra fields are rejected', async () => {
    await assertFails(
      setDoc(doc(db(ANA), `likes/${ANA}_${BIA}`), {
        ...like(ANA, BIA),
        createdAt: Timestamp.fromDate(new Date(2000, 0, 1)),
      }),
    );
    await assertFails(setDoc(doc(db(ANA), `likes/${ANA}_${BIA}`), { ...like(ANA, BIA), note: 'x' }));
  });

  test('[M1] the liked person cannot read who liked or skipped them', async () => {
    await seed({
      [`likes/${BIA}_${ANA}`]: seededLike(BIA, ANA, true),
      [`likes/${CAIO}_${ANA}`]: seededLike(CAIO, ANA, false),
    });
    await assertFails(getDoc(doc(db(ANA), `likes/${BIA}_${ANA}`)));
    await assertFails(getDoc(doc(db(ANA), `likes/${CAIO}_${ANA}`)));
    await assertFails(getDocs(query(collection(db(ANA), 'likes'), where('to', '==', ANA))));
  });

  test('[M1] probing a like that does not exist is also denied', async () => {
    await assertFails(getDoc(doc(db(ANA), `likes/${CAIO}_${ANA}`)));
  });

  test('the author can read their own likes', async () => {
    await seed({ [`likes/${ANA}_${BIA}`]: seededLike(ANA, BIA) });
    await assertSucceeds(getDoc(doc(db(ANA), `likes/${ANA}_${BIA}`)));
    await assertSucceeds(getDocs(query(collection(db(ANA), 'likes'), where('from', '==', ANA))));
  });

  test('likes cannot be deleted', async () => {
    await seed({ [`likes/${ANA}_${BIA}`]: seededLike(ANA, BIA) });
    await assertFails(deleteDoc(doc(db(ANA), `likes/${ANA}_${BIA}`)));
  });
});

describe('matches', () => {
  test('a match needs both likes', async () => {
    await seed({ [`likes/${ANA}_${BIA}`]: seededLike(ANA, BIA) });
    await assertFails(setDoc(doc(db(ANA), `matches/${MATCH_AB}`), newMatch()));
  });

  test('a skip on the other side blocks the match', async () => {
    await seed({
      [`likes/${ANA}_${BIA}`]: seededLike(ANA, BIA),
      [`likes/${BIA}_${ANA}`]: seededLike(BIA, ANA, false),
    });
    await assertFails(setDoc(doc(db(ANA), `matches/${MATCH_AB}`), newMatch()));
  });

  test('a member can create the match when both liked', async () => {
    await seed({
      [`likes/${ANA}_${BIA}`]: seededLike(ANA, BIA),
      [`likes/${BIA}_${ANA}`]: seededLike(BIA, ANA),
    });
    await assertSucceeds(setDoc(doc(db(ANA), `matches/${MATCH_AB}`), newMatch()));
  });

  test('an outsider cannot create a match between two others', async () => {
    await seed({
      [`likes/${ANA}_${BIA}`]: seededLike(ANA, BIA),
      [`likes/${BIA}_${ANA}`]: seededLike(BIA, ANA),
    });
    await assertFails(setDoc(doc(db(CAIO), `matches/${MATCH_AB}`), newMatch()));
  });

  test('[M2] spoofed names, previews and extra fields are rejected on create', async () => {
    await seed({
      [`likes/${ANA}_${BIA}`]: seededLike(ANA, BIA),
      [`likes/${BIA}_${ANA}`]: seededLike(BIA, ANA),
    });
    const ref = doc(db(ANA), `matches/${MATCH_AB}`);
    await assertFails(setDoc(ref, newMatch({ names: { ana: 'Ana', bia: 'Fake name' } })));
    await assertFails(setDoc(ref, newMatch({ lastMessage: 'fake preview' })));
  });

  test('match ids must be the sorted pair', async () => {
    await seed({
      [`likes/${ANA}_${BIA}`]: seededLike(ANA, BIA),
      [`likes/${BIA}_${ANA}`]: seededLike(BIA, ANA),
    });
    await assertFails(setDoc(doc(db(ANA), 'matches/bia_ana'), newMatch({ userIds: [BIA, ANA] })));
  });

  test('[L1] forged match timestamps are rejected', async () => {
    await seed({
      [`likes/${ANA}_${BIA}`]: seededLike(ANA, BIA),
      [`likes/${BIA}_${ANA}`]: seededLike(BIA, ANA),
    });
    await assertFails(
      setDoc(doc(db(ANA), `matches/${MATCH_AB}`), newMatch({ createdAt: Timestamp.fromDate(new Date(2000, 0, 1)) })),
    );
  });

  test('members can read their match; outsiders cannot even probe it', async () => {
    await seed({ [`matches/${MATCH_AB}`]: seededMatch() });
    await assertSucceeds(getDoc(doc(db(BIA), `matches/${MATCH_AB}`)));
    await assertFails(getDoc(doc(db(CAIO), `matches/${MATCH_AB}`)));
    await assertFails(getDoc(doc(db(CAIO), 'matches/ana_davi')));
  });

  test('members can list their matches, nobody else\'s', async () => {
    await seed({ [`matches/${MATCH_AB}`]: seededMatch() });
    await assertSucceeds(getDocs(query(collection(db(ANA), 'matches'), where('userIds', 'array-contains', ANA))));
    await assertFails(getDocs(query(collection(db(CAIO), 'matches'), where('userIds', 'array-contains', ANA))));
  });

  test('matches cannot be deleted', async () => {
    await seed({ [`matches/${MATCH_AB}`]: seededMatch() });
    await assertFails(deleteDoc(doc(db(ANA), `matches/${MATCH_AB}`)));
  });
});

describe('messages and match preview', () => {
  beforeEach(async () => {
    await seed({ [`matches/${MATCH_AB}`]: seededMatch() });
  });

  function sendBatch(uid, { id = 'm1', text = 'Oi', preview = text, senderId = uid } = {}) {
    const fs = db(uid);
    const batch = writeBatch(fs);
    batch.set(doc(fs, `matches/${MATCH_AB}/messages/${id}`), message(senderId, text));
    batch.update(doc(fs, `matches/${MATCH_AB}`), {
      lastMessage: preview,
      lastMessageId: id,
      lastMessageAt: serverTimestamp(),
    });
    return batch.commit();
  }

  test('a member sends a message and updates the preview in one batch', async () => {
    await assertSucceeds(sendBatch(ANA));
  });

  test('an outsider cannot send or read messages', async () => {
    await assertFails(setDoc(doc(db(CAIO), `matches/${MATCH_AB}/messages/x`), message(CAIO)));
    await assertFails(getDocs(collection(db(CAIO), `matches/${MATCH_AB}/messages`)));
  });

  test('members can read the conversation', async () => {
    await assertSucceeds(getDocs(collection(db(BIA), `matches/${MATCH_AB}/messages`)));
  });

  test('messages cannot impersonate the other member', async () => {
    await assertFails(setDoc(doc(db(ANA), `matches/${MATCH_AB}/messages/x`), message(BIA)));
  });

  test('empty, oversized, extra-field or backdated messages are rejected', async () => {
    const ref = doc(db(ANA), `matches/${MATCH_AB}/messages/x`);
    await assertFails(setDoc(ref, message(ANA, '')));
    await assertFails(setDoc(ref, message(ANA, 'x'.repeat(2001))));
    await assertFails(setDoc(ref, { ...message(ANA), pinned: true }));
    await assertFails(setDoc(ref, { ...message(ANA), createdAt: Timestamp.fromDate(new Date(2000, 0, 1)) }));
  });

  test('messages cannot be edited or deleted', async () => {
    await seed({ [`matches/${MATCH_AB}/messages/old`]: { senderId: ANA, text: 'Oi', createdAt: Timestamp.now() } });
    await assertFails(updateDoc(doc(db(ANA), `matches/${MATCH_AB}/messages/old`), { text: 'edited' }));
    await assertFails(deleteDoc(doc(db(ANA), `matches/${MATCH_AB}/messages/old`)));
  });

  test('[M2] the preview cannot be set without a real message', async () => {
    await assertFails(
      updateDoc(doc(db(ANA), `matches/${MATCH_AB}`), {
        lastMessage: 'fake preview',
        lastMessageId: 'none',
        lastMessageAt: serverTimestamp(),
      }),
    );
  });

  test('[M2] the preview must equal the message text', async () => {
    await assertFails(sendBatch(ANA, { text: 'Oi', preview: 'something else' }));
  });

  test('[M2] the preview cannot point to an existing older message', async () => {
    await seed({ [`matches/${MATCH_AB}/messages/old`]: { senderId: BIA, text: 'Oi', createdAt: Timestamp.now() } });
    await assertFails(
      updateDoc(doc(db(ANA), `matches/${MATCH_AB}`), {
        lastMessage: 'Oi',
        lastMessageId: 'old',
        lastMessageAt: serverTimestamp(),
      }),
    );
  });

  test('[M2] members cannot change who is in the match', async () => {
    await assertFails(updateDoc(doc(db(ANA), `matches/${MATCH_AB}`), { userIds: [ANA, CAIO] }));
  });
});

// ---------------------------------------------------------------------------
// H1 — safety: consent, unmatch, block, report
// ---------------------------------------------------------------------------

const consent = (overrides = {}) => ({
  termsVersion: 1,
  adult: true,
  acceptedAt: serverTimestamp(),
  ...overrides,
});

function createProfileWithConsent(uid, consentData = consent()) {
  const fs = db(uid);
  const batch = writeBatch(fs);
  batch.set(doc(fs, `users/${uid}/private/consent`), consentData);
  batch.set(doc(fs, `users/${uid}`), profile({ name: 'Nova' }));
  return batch.commit();
}

describe('[H1] consent (18+ and community rules)', () => {
  test('a new profile is accepted together with the consent record', async () => {
    await assertSucceeds(createProfileWithConsent('nova'));
  });

  test('a new profile without consent is rejected', async () => {
    await assertFails(setDoc(doc(db('nova'), 'users/nova'), profile({ name: 'Nova' })));
  });

  test('consent must say adult, current terms version and server time', async () => {
    await assertFails(createProfileWithConsent('nova', consent({ adult: false })));
    await assertFails(createProfileWithConsent('nova', consent({ termsVersion: 0 })));
    await assertFails(
      createProfileWithConsent('nova', consent({ acceptedAt: Timestamp.fromDate(new Date(2000, 0, 1)) })),
    );
    await assertFails(createProfileWithConsent('nova', consent({ extra: true })));
  });

  test('consent is private to its owner and cannot be changed', async () => {
    await assertSucceeds(createProfileWithConsent('nova'));
    await assertSucceeds(getDoc(doc(db('nova'), 'users/nova/private/consent')));
    await assertFails(getDoc(doc(db(ANA), 'users/nova/private/consent')));
    await assertFails(updateDoc(doc(db('nova'), 'users/nova/private/consent'), { adult: false }));
    await assertFails(deleteDoc(doc(db('nova'), 'users/nova/private/consent')));
  });

  test('nobody can write consent for someone else', async () => {
    await assertFails(setDoc(doc(db(ANA), 'users/nova/private/consent'), consent()));
  });

  test('an existing user without consent can accept it later', async () => {
    await assertSucceeds(setDoc(doc(db(ANA), `users/${ANA}/private/consent`), consent()));
  });
});

const close = (uid) => ({ status: 'closed', closedBy: uid, closedAt: serverTimestamp() });

describe('[H1] unmatch', () => {
  beforeEach(async () => {
    await seed({ [`matches/${MATCH_AB}`]: seededMatch() });
  });

  test('either member can close the match', async () => {
    await assertSucceeds(updateDoc(doc(db(BIA), `matches/${MATCH_AB}`), close(BIA)));
  });

  test('an outsider cannot close it', async () => {
    await assertFails(updateDoc(doc(db(CAIO), `matches/${MATCH_AB}`), close(CAIO)));
  });

  test('closing cannot be attributed to the other member or backdated', async () => {
    await assertFails(updateDoc(doc(db(ANA), `matches/${MATCH_AB}`), close(BIA)));
    await assertFails(
      updateDoc(doc(db(ANA), `matches/${MATCH_AB}`), {
        ...close(ANA),
        closedAt: Timestamp.fromDate(new Date(2000, 0, 1)),
      }),
    );
  });

  test('a closed match cannot be reopened', async () => {
    await seed({ [`matches/${MATCH_AB}`]: seededMatch('closed') });
    await assertFails(updateDoc(doc(db(ANA), `matches/${MATCH_AB}`), { status: 'active' }));
  });

  test('no messages or previews after closing', async () => {
    await seed({ [`matches/${MATCH_AB}`]: seededMatch('closed') });
    const fs = db(ANA);
    await assertFails(setDoc(doc(fs, `matches/${MATCH_AB}/messages/x`), message(ANA)));
    const batch = writeBatch(fs);
    batch.set(doc(fs, `matches/${MATCH_AB}/messages/y`), message(ANA));
    batch.update(doc(fs, `matches/${MATCH_AB}`), {
      lastMessage: 'Oi',
      lastMessageId: 'y',
      lastMessageAt: serverTimestamp(),
    });
    await assertFails(batch.commit());
  });

  test('members can still read the history of a closed match', async () => {
    await seed({ [`matches/${MATCH_AB}`]: seededMatch('closed') });
    await assertSucceeds(getDocs(collection(db(ANA), `matches/${MATCH_AB}/messages`)));
  });

  test('legacy matches without status are treated as active', async () => {
    const legacy = seededMatch();
    delete legacy.status;
    await seed({ [`matches/${MATCH_AB}`]: legacy });
    await assertSucceeds(setDoc(doc(db(ANA), `matches/${MATCH_AB}/messages/x`), message(ANA)));
    await assertSucceeds(updateDoc(doc(db(ANA), `matches/${MATCH_AB}`), close(ANA)));
  });
});

const block = (blocker, blocked) => ({ blocker, blocked, createdAt: serverTimestamp() });

describe('[H1] block', () => {
  test('a user can block another user', async () => {
    await assertSucceeds(setDoc(doc(db(ANA), `blocks/${ANA}_${BIA}`), block(ANA, BIA)));
  });

  test('blocks cannot be forged, aimed at yourself or at nobody', async () => {
    await assertFails(setDoc(doc(db(ANA), `blocks/${BIA}_${ANA}`), block(BIA, ANA)));
    await assertFails(setDoc(doc(db(ANA), `blocks/${ANA}_${CAIO}`), block(ANA, BIA)));
    await assertFails(setDoc(doc(db(ANA), `blocks/${ANA}_${ANA}`), block(ANA, ANA)));
    await assertFails(setDoc(doc(db(ANA), `blocks/${ANA}_ghost`), block(ANA, 'ghost')));
    await assertFails(
      setDoc(doc(db(ANA), `blocks/${ANA}_${BIA}`), {
        ...block(ANA, BIA),
        createdAt: Timestamp.fromDate(new Date(2000, 0, 1)),
      }),
    );
  });

  test('the blocked person cannot see the block', async () => {
    await seed({ [`blocks/${ANA}_${BIA}`]: { blocker: ANA, blocked: BIA, createdAt: Timestamp.now() } });
    await assertFails(getDoc(doc(db(BIA), `blocks/${ANA}_${BIA}`)));
    await assertFails(getDocs(query(collection(db(BIA), 'blocks'), where('blocked', '==', BIA))));
    await assertSucceeds(getDocs(query(collection(db(ANA), 'blocks'), where('blocker', '==', ANA))));
  });

  test('blocks cannot be removed or edited', async () => {
    await seed({ [`blocks/${ANA}_${BIA}`]: { blocker: ANA, blocked: BIA, createdAt: Timestamp.now() } });
    await assertFails(deleteDoc(doc(db(ANA), `blocks/${ANA}_${BIA}`)));
    await assertFails(updateDoc(doc(db(ANA), `blocks/${ANA}_${BIA}`), { blocked: CAIO }));
  });

  test('a block in either direction prevents a match even with mutual likes', async () => {
    const likes = {
      [`likes/${ANA}_${BIA}`]: seededLike(ANA, BIA),
      [`likes/${BIA}_${ANA}`]: seededLike(BIA, ANA),
    };
    await seed({ ...likes, [`blocks/${BIA}_${ANA}`]: { blocker: BIA, blocked: ANA, createdAt: Timestamp.now() } });
    await assertFails(setDoc(doc(db(ANA), `matches/${MATCH_AB}`), newMatch()));
    await env.clearFirestore();
    await seed({
      [`users/${ANA}`]: seededProfile('Ana', ['excel'], ['english']),
      [`users/${BIA}`]: seededProfile('Bia', ['english'], ['excel']),
      ...likes,
      [`blocks/${ANA}_${BIA}`]: { blocker: ANA, blocked: BIA, createdAt: Timestamp.now() },
    });
    await assertFails(setDoc(doc(db(ANA), `matches/${MATCH_AB}`), newMatch()));
  });

  test('a blocked person cannot message even if the match was left open', async () => {
    await seed({
      [`matches/${MATCH_AB}`]: seededMatch(),
      [`blocks/${ANA}_${BIA}`]: { blocker: ANA, blocked: BIA, createdAt: Timestamp.now() },
    });
    await assertFails(setDoc(doc(db(BIA), `matches/${MATCH_AB}/messages/x`), message(BIA)));
  });

  test('block and unmatch together in one batch', async () => {
    await seed({ [`matches/${MATCH_AB}`]: seededMatch() });
    const fs = db(ANA);
    const batch = writeBatch(fs);
    batch.set(doc(fs, `blocks/${ANA}_${BIA}`), block(ANA, BIA));
    batch.update(doc(fs, `matches/${MATCH_AB}`), close(ANA));
    await assertSucceeds(batch.commit());
  });
});

const report = (overrides = {}) => ({
  reporterId: ANA,
  reportedId: BIA,
  reason: 'harassment',
  details: 'Mensagens ofensivas.',
  matchId: MATCH_AB,
  createdAt: serverTimestamp(),
  ...overrides,
});

describe('[H1] report', () => {
  test('a user can report someone from a match or from discover', async () => {
    await assertSucceeds(setDoc(doc(db(ANA), 'reports/r1'), report()));
    await assertSucceeds(setDoc(doc(db(ANA), 'reports/r2'), report({ reportedId: CAIO, matchId: null })));
  });

  test('reports cannot be forged or aimed at yourself or at nobody', async () => {
    await assertFails(setDoc(doc(db(ANA), 'reports/r'), report({ reporterId: BIA })));
    await assertFails(setDoc(doc(db(ANA), 'reports/r'), report({ reportedId: ANA })));
    await assertFails(setDoc(doc(db(ANA), 'reports/r'), report({ reportedId: 'ghost', matchId: null })));
  });

  test('reason must be from the list, details at most 500 chars, no extra fields', async () => {
    await assertFails(setDoc(doc(db(ANA), 'reports/r'), report({ reason: 'dislike' })));
    await assertFails(setDoc(doc(db(ANA), 'reports/r'), report({ details: 'x'.repeat(501) })));
    await assertFails(setDoc(doc(db(ANA), 'reports/r'), report({ status: 'resolved' })));
  });

  test('a report cannot point at a match the reporter is not in', async () => {
    await assertFails(setDoc(doc(db(CAIO), 'reports/r'), report({ reporterId: CAIO, matchId: MATCH_AB })));
  });

  test('reports are write-only: nobody can read, edit or delete them', async () => {
    await seed({ 'reports/r1': { ...report(), createdAt: Timestamp.now() } });
    await assertFails(getDoc(doc(db(ANA), 'reports/r1')));
    await assertFails(getDoc(doc(db(BIA), 'reports/r1')));
    await assertFails(getDocs(collection(db(ANA), 'reports')));
    await assertFails(updateDoc(doc(db(ANA), 'reports/r1'), { details: 'edited' }));
    await assertFails(deleteDoc(doc(db(ANA), 'reports/r1')));
  });

  test('report, block and unmatch together in one batch', async () => {
    await seed({ [`matches/${MATCH_AB}`]: seededMatch() });
    const fs = db(ANA);
    const batch = writeBatch(fs);
    batch.set(doc(fs, 'reports/r1'), report());
    batch.set(doc(fs, `blocks/${ANA}_${BIA}`), block(ANA, BIA));
    batch.update(doc(fs, `matches/${MATCH_AB}`), close(ANA));
    await assertSucceeds(batch.commit());
  });
});
