// Security Rules tests for the Community (posts, media, likes, comments,
// follows, saved posts, notifications, anti-spam, content reports).
// Run with the Firestore Emulator (see README in this folder).
import { after, before, beforeEach, describe, test } from 'node:test';
import { readFileSync } from 'node:fs';
import {
  assertFails,
  assertSucceeds,
  initializeTestEnvironment,
} from '@firebase/rules-unit-testing';
import {
  Bytes,
  collection,
  deleteDoc,
  doc,
  getCountFromServer,
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

// Fictional users.
const ANA = 'ana';
const BIA = 'bia';
const CAIO = 'caio';

const db = (uid, token = {}) => env.authenticatedContext(uid, token).firestore();
const anon = () => env.unauthenticatedContext().firestore();

async function seed(writes) {
  await env.withSecurityRulesDisabled(async (ctx) => {
    const fs = ctx.firestore();
    for (const [path, data] of Object.entries(writes)) {
      await setDoc(doc(fs, path), data);
    }
  });
}

const profile = (name) => ({
  name,
  bio: '',
  teach: ['design'],
  learn: ['excel'],
  updatedAt: Timestamp.now(),
});

/** A JPEG-looking blob of [size] bytes. */
const jpeg = (size = 64) => {
  const bytes = new Uint8Array(size);
  bytes.set([0xff, 0xd8, 0xff, 0xe0]);
  return Bytes.fromUint8Array(bytes);
};

const newPost = (author, overrides = {}) => ({
  authorId: author,
  description: 'Finalizei meu projeto!',
  type: 'project',
  skillIds: ['design'],
  tags: ['Design'],
  keywords: ['design', 'projeto'],
  visibility: 'public',
  mediaCount: 0,
  aspectRatios: [],
  createdAt: serverTimestamp(),
  updatedAt: serverTimestamp(),
  ...overrides,
});

const seededPost = (author, overrides = {}) => ({
  ...newPost(author),
  createdAt: Timestamp.fromMillis(Date.now() - 60000),
  updatedAt: Timestamp.fromMillis(Date.now() - 60000),
  ...overrides,
});

/** A post id as the app makes it: "<uid>_" + 20 letters/digits. */
const pid = (uid, tag) => `${uid}_${tag.padEnd(20, 'x')}`;

/** Batch: anti-spam stamp + post (+ media), as the app writes it. */
function postBatch(fs, uid, postId, data, media = []) {
  const batch = writeBatch(fs);
  batch.set(
    doc(fs, `rateLimits/${uid}`),
    { lastPostAt: serverTimestamp(), lastPostId: postId },
    { merge: true },
  );
  batch.set(doc(fs, `posts/${postId}`), data);
  media.forEach((m, i) => batch.set(doc(fs, `posts/${postId}/media/${i}`), m));
  return batch;
}

function commentBatch(fs, uid, postId, commentId, data) {
  const batch = writeBatch(fs);
  batch.set(
    doc(fs, `rateLimits/${uid}`),
    { lastCommentAt: serverTimestamp(), lastCommentKey: `${postId}_${commentId}` },
    { merge: true },
  );
  batch.set(doc(fs, `posts/${postId}/comments/${commentId}`), data);
  return batch;
}

const comment = (author, overrides = {}) => ({
  authorId: author,
  text: 'Ficou incrível!',
  parentId: null,
  createdAt: serverTimestamp(),
  ...overrides,
});

const notification = (type, actor, overrides = {}) => ({
  type,
  actorId: actor,
  postId: null,
  commentId: null,
  read: false,
  createdAt: serverTimestamp(),
  ...overrides,
});

const image = (overrides = {}) => ({ data: jpeg(), width: 800, height: 600, ...overrides });

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
    [`users/${ANA}`]: profile('Ana'),
    [`users/${BIA}`]: profile('Bia'),
    [`users/${CAIO}`]: profile('Caio'),
    'posts/bia1': seededPost(BIA, { mediaCount: 1, aspectRatios: [1.33] }),
    'posts/bia1/media/0': image(),
  });
});

after(async () => {
  await env?.cleanup();
});

describe('posts', () => {
  test('members read posts; visitors cannot', async () => {
    await assertSucceeds(getDoc(doc(db(ANA), 'posts/bia1')));
    await assertSucceeds(getDocs(query(collection(db(ANA), 'posts'), limit(10))));
    await assertSucceeds(getDoc(doc(db(ANA), 'posts/bia1/media/0')));
    await assertFails(getDoc(doc(anon(), 'posts/bia1')));
    await assertFails(getDoc(doc(anon(), 'posts/bia1/media/0')));
  });

  test('publish with images and the anti-spam stamp, in one batch', async () => {
    const fs = db(ANA);
    await assertSucceeds(
      postBatch(fs, ANA, pid(ANA, 'p1'), newPost(ANA, {
        mediaCount: 2,
        aspectRatios: [1, 0.8],
        thumb: jpeg(1000),
      }), [image(), image()]).commit(),
    );
  });

  test('a post without the anti-spam stamp is refused', async () => {
    await assertFails(setDoc(doc(db(ANA), `posts/${pid(ANA, 'p1')}`), newPost(ANA)));
  });

  test('anti-spam: a second post within 30 s is refused', async () => {
    await seed({ [`rateLimits/${ANA}`]: { lastPostAt: Timestamp.now(), lastPostId: 'x' } });
    await assertFails(postBatch(db(ANA), ANA, pid(ANA, 'p2'), newPost(ANA)).commit());
    // The stamp cannot be moved back to cheat the cooldown either.
    await assertFails(
      setDoc(doc(db(ANA), `rateLimits/${ANA}`), { lastPostAt: Timestamp.fromMillis(0), lastPostId: 'x' }, { merge: true }),
    );
  });

  test('nobody writes another member\'s anti-spam stamp', async () => {
    await assertFails(
      setDoc(doc(db(BIA), `rateLimits/${ANA}`), { lastPostAt: serverTimestamp() }),
    );
    await assertFails(getDoc(doc(db(BIA), `rateLimits/${ANA}`)));
  });

  test('cannot publish as someone else', async () => {
    await assertFails(postBatch(db(ANA), ANA, pid(ANA, 'p1'), newPost(BIA)).commit());
  });

  test('invalid posts are refused', async () => {
    const bad = [
      { description: '   ', mediaCount: 0 }, // empty
      { visibility: 'followers' },
      { type: 'ad' },
      { skillIds: ['design', 'hacking'] },
      { skillIds: ['excel', 'english', 'spanish', 'python', 'guitar', 'piano'] },
      { description: 'x'.repeat(2001) },
      { mediaCount: 6, aspectRatios: [1, 1, 1, 1, 1, 1] },
      { mediaCount: 1, aspectRatios: [] },
      { thumb: Bytes.fromUint8Array(new Uint8Array([1, 2, 3, 4])) }, // not JPEG
      { thumb: jpeg(24577) }, // too large
      { likeCount: 1000 }, // unknown field
      { createdAt: Timestamp.fromMillis(0) }, // forged time
    ];
    for (const [i, overrides] of bad.entries()) {
      await assertFails(
        postBatch(db(ANA), ANA, pid(ANA, `bad${i}`), newPost(ANA, overrides)).commit(),
      );
      await env.clearFirestore();
      await seed({ [`users/${ANA}`]: profile('Ana') });
    }
  });

  test('images: only in the post\'s own batch, valid JPEG, within limits', async () => {
    // Adding an image to an existing post (orphan / later addition).
    await assertFails(setDoc(doc(db(BIA), 'posts/bia1/media/1'), image()));
    // More images than mediaCount.
    await assertFails(
      postBatch(db(ANA), ANA, pid(ANA, 'p1'), newPost(ANA, { mediaCount: 1, aspectRatios: [1] }),
        [image(), image()]).commit(),
    );
    await assertFails(
      postBatch(db(ANA), ANA, pid(ANA, 'p2'), newPost(ANA, { mediaCount: 1, aspectRatios: [1] }),
        [image({ data: Bytes.fromUint8Array(new Uint8Array([0x89, 0x50, 0x4e, 0x47])) })]).commit(),
    );
    await assertFails(
      postBatch(db(ANA), ANA, pid(ANA, 'p3'), newPost(ANA, { mediaCount: 1, aspectRatios: [1] }),
        [image({ data: jpeg(307201) })]).commit(),
    );
    await assertFails(
      postBatch(db(ANA), ANA, pid(ANA, 'p4'), newPost(ANA, { mediaCount: 1, aspectRatios: [1] }),
        [image({ width: 4000 })]).commit(),
    );
    // Someone else cannot attach images to my new post.
    const fs = db(CAIO);
    const batch = writeBatch(fs);
    batch.set(doc(fs, `posts/${pid(ANA, 'p5')}/media/0`), image());
    await assertFails(batch.commit());
  });

  test('the author edits text/type/skills/tags; not images, author or others', async () => {
    await assertSucceeds(
      updateDoc(doc(db(BIA), 'posts/bia1'), {
        description: 'Texto revisado',
        type: 'tip',
        tags: ['Dica'],
        keywords: ['texto'],
        updatedAt: serverTimestamp(),
      }),
    );
    await assertFails(
      updateDoc(doc(db(BIA), 'posts/bia1'), { mediaCount: 0, aspectRatios: [], updatedAt: serverTimestamp() }),
    );
    await assertFails(
      updateDoc(doc(db(BIA), 'posts/bia1'), { authorId: ANA, updatedAt: serverTimestamp() }),
    );
    await assertFails(
      updateDoc(doc(db(ANA), 'posts/bia1'), { description: 'hack', updatedAt: serverTimestamp() }),
    );
  });

  test('only the author (or a moderator) deletes a post and its images', async () => {
    const stranger = db(ANA);
    const b1 = writeBatch(stranger);
    b1.delete(doc(stranger, 'posts/bia1/media/0'));
    b1.delete(doc(stranger, 'posts/bia1'));
    await assertFails(b1.commit());

    const author = db(BIA);
    const b2 = writeBatch(author);
    b2.delete(doc(author, 'posts/bia1/media/0'));
    b2.delete(doc(author, 'posts/bia1'));
    await assertSucceeds(b2.commit());

    await seed({ 'posts/bia2': seededPost(BIA) });
    await assertSucceeds(deleteDoc(doc(db(CAIO, { admin: true }), 'posts/bia2')));
  });
});

describe('video posts', () => {
  const CHUNK = 819200;
  const chunk = (size) => {
    const bytes = new Uint8Array(size);
    if (size >= 8) bytes.set([0, 0, 0, 0x18, 0x66, 0x74, 0x79, 0x70]); // ....ftyp
    return { data: Bytes.fromUint8Array(bytes) };
  };
  const video = (overrides = {}) => ({
    chunks: 2,
    bytes: CHUNK + 1000,
    durationMs: 17458,
    width: 768,
    height: 576,
    ...overrides,
  });
  /** Chunks whose sizes add up to the declared video, as the app splits it. */
  const chunksFor = (v) => {
    const count = Math.min(Math.max(Math.trunc(Number(v.chunks)) || 1, 1), 3);
    return Array.from({ length: count }, (_, i) =>
      chunk(i < count - 1 ? CHUNK : Math.max(1, Number(v.bytes) - i * CHUNK)));
  };
  const videoPost = (author, videoOverrides = {}, overrides = {}) => newPost(author, {
    type: 'knowledge',
    mediaCount: 1,
    aspectRatios: [1.33],
    thumb: jpeg(1000),
    video: video(videoOverrides),
    ...overrides,
  });

  /** Stamps (post + video) + post + poster + chunks, as the app writes them. */
  function videoBatch(fs, uid, postId, data, chunks = chunksFor(data.video), { stampVideo = true } = {}) {
    const batch = writeBatch(fs);
    batch.set(
      doc(fs, `rateLimits/${uid}`),
      {
        lastPostAt: serverTimestamp(),
        lastPostId: postId,
        ...(stampVideo ? { lastVideoAt: serverTimestamp() } : {}),
      },
      { merge: true },
    );
    batch.set(doc(fs, `posts/${postId}`), data);
    batch.set(doc(fs, `posts/${postId}/media/0`), image());
    chunks.forEach((c, i) => batch.set(doc(fs, `posts/${postId}/video/${i}`), c));
    return batch;
  }

  const resetAna = async () => {
    await env.clearFirestore();
    await seed({ [`users/${ANA}`]: profile('Ana') });
  };

  test('publish a video with its poster and every chunk, in one batch', async () => {
    await assertSucceeds(videoBatch(db(ANA), ANA, pid(ANA, 'v1'), videoPost(ANA)).commit());
    // Members read the chunks; visitors do not; nobody lists them.
    await assertSucceeds(getDoc(doc(db(BIA), `posts/${pid(ANA, 'v1')}/video/0`)));
    await assertFails(getDoc(doc(anon(), `posts/${pid(ANA, 'v1')}/video/0`)));
    await assertFails(getDocs(collection(db(BIA), `posts/${pid(ANA, 'v1')}/video`)));
  });

  test('the largest video (3 full chunks) fits the rules limits', async () => {
    const data = videoPost(ANA, { chunks: 3, bytes: CHUNK * 3 });
    await assertSucceeds(videoBatch(db(ANA), ANA, pid(ANA, 'v1'), data).commit());
  });

  test('a video post missing a chunk is refused', async () => {
    await assertFails(
      videoBatch(db(ANA), ANA, pid(ANA, 'v1'), videoPost(ANA), [chunk(CHUNK)]).commit(),
    );
  });

  test('chunk sizes must add up to the declared video', async () => {
    const attempts = [
      [chunk(CHUNK), chunk(999)], // last chunk short
      [chunk(CHUNK - 1), chunk(1001)], // first chunk not full
      [chunk(CHUNK), chunk(0)], // empty chunk
    ];
    for (const [i, chunks] of attempts.entries()) {
      await assertFails(videoBatch(db(ANA), ANA, pid(ANA, `s${i}`), videoPost(ANA), chunks).commit());
      await resetAna();
    }
  });

  test('chunks beyond the declared count, oversized, misnamed or with extra fields are refused', async () => {
    const one = { chunks: 1, bytes: 1000 };
    await assertFails(
      videoBatch(db(ANA), ANA, pid(ANA, 'v1'), videoPost(ANA),
        [chunk(CHUNK), chunk(1000), chunk(10)]).commit(),
    );
    await assertFails(
      videoBatch(db(ANA), ANA, pid(ANA, 'v2'), videoPost(ANA, { chunks: 1, bytes: CHUNK + 1 }),
        [chunk(CHUNK + 1)]).commit(),
    );
    await assertFails(
      videoBatch(db(ANA), ANA, pid(ANA, 'v3'), videoPost(ANA, one),
        [{ ...chunk(1000), note: 'x' }]).commit(),
    );
    await assertFails(
      videoBatch(db(ANA), ANA, pid(ANA, 'v4'), videoPost(ANA, one), [{ data: 'not bytes' }]).commit(),
    );
    for (const name of ['3', '01', 'a']) {
      const fs = db(ANA);
      const batch = videoBatch(fs, ANA, pid(ANA, `n${name}`), videoPost(ANA, { chunks: 3, bytes: CHUNK * 3 }));
      batch.set(doc(fs, `posts/${pid(ANA, `n${name}`)}/video/${name}`), chunk(10));
      await assertFails(batch.commit());
      await resetAna();
    }
  });

  test('invalid video metadata is refused', async () => {
    const bad = [
      [{ chunks: 4, bytes: CHUNK * 3 + 1 }, {}], // too many chunks
      [{ chunks: 2, bytes: 1000 }, {}], // more chunks than the size needs
      [{ chunks: 1, bytes: CHUNK + 1 }, {}], // fewer chunks than the size needs
      [{ durationMs: 60001 }, {}], // too long
      [{ durationMs: 0 }, {}],
      [{ durationMs: 1000.5 }, {}],
      [{ chunks: 1.5 }, {}],
      [{ width: 0 }, {}],
      [{ height: 5000 }, {}],
      [{ chunks: '2' }, {}],
      [{ codec: 'h264' }, {}], // unknown key
      [{}, { mediaCount: 0, aspectRatios: [], thumb: undefined }], // no poster
      [{}, { mediaCount: 2, aspectRatios: [1, 1] }], // video plus a gallery
    ];
    for (const [i, [videoOverrides, overrides]] of bad.entries()) {
      const data = videoPost(ANA, videoOverrides, overrides);
      if (data.thumb === undefined) delete data.thumb;
      await assertFails(videoBatch(db(ANA), ANA, pid(ANA, `bad${i}`), data).commit());
      await resetAna();
    }
  });

  test('anti-spam: at most one video per hour, even after the 30 s post cooldown', async () => {
    // Without the video stamp the post is refused.
    await assertFails(
      videoBatch(db(ANA), ANA, pid(ANA, 'v0'), videoPost(ANA), undefined, { stampVideo: false }).commit(),
    );
    await seed({
      [`rateLimits/${ANA}`]: {
        lastPostAt: Timestamp.fromMillis(Date.now() - 60000),
        lastPostId: 'x',
        lastVideoAt: Timestamp.fromMillis(Date.now() - 10 * 60000),
      },
    });
    await assertFails(videoBatch(db(ANA), ANA, pid(ANA, 'v1'), videoPost(ANA)).commit());
    // An image post is still fine, and keeps the video stamp.
    await assertSucceeds(postBatch(db(ANA), ANA, pid(ANA, 'p1'), newPost(ANA)).commit());
    // The stamp cannot be cleared or moved back either.
    await assertFails(
      setDoc(doc(db(ANA), `rateLimits/${ANA}`), { lastVideoAt: Timestamp.fromMillis(0) }, { merge: true }),
    );
    await seed({
      [`rateLimits/${ANA}`]: {
        lastPostAt: Timestamp.fromMillis(Date.now() - 60000),
        lastPostId: 'x',
        lastVideoAt: Timestamp.fromMillis(Date.now() - 61 * 60000),
      },
    });
    await assertSucceeds(videoBatch(db(ANA), ANA, pid(ANA, 'v2'), videoPost(ANA)).commit());
  });

  test('chunks cannot be added to an existing post or by someone else', async () => {
    await assertSucceeds(
      videoBatch(db(ANA), ANA, pid(ANA, 'v1'), videoPost(ANA, { chunks: 1, bytes: 1000 })).commit(),
    );
    // Replacing or adding a chunk later.
    await assertFails(setDoc(doc(db(ANA), `posts/${pid(ANA, 'v1')}/video/0`), chunk(1000)));
    await assertFails(setDoc(doc(db(ANA), `posts/${pid(ANA, 'v1')}/video/1`), chunk(1000)));
    // Someone else attaching a chunk to a new post of mine, even while
    // publishing a valid video of their own in the same batch.
    await seed({ [`users/${CAIO}`]: profile('Caio') });
    const fs = db(CAIO);
    const batch = videoBatch(fs, CAIO, pid(CAIO, 'c1'), videoPost(CAIO, { chunks: 1, bytes: 1000 }));
    batch.set(doc(fs, `posts/${pid(ANA, 'v9')}/video/0`), chunk(1000));
    await assertFails(batch.commit());
  });

  test('the video cannot be added, swapped or removed by an edit', async () => {
    await assertSucceeds(
      videoBatch(db(ANA), ANA, pid(ANA, 'v1'), videoPost(ANA, { chunks: 1, bytes: 1000 })).commit(),
    );
    await env.withSecurityRulesDisabled(async (ctx) => {
      await updateDoc(doc(ctx.firestore(), `posts/${pid(ANA, 'v1')}`), {
        updatedAt: Timestamp.fromMillis(Date.now() - 60000),
      });
    });
    await assertFails(
      updateDoc(doc(db(ANA), `posts/${pid(ANA, 'v1')}`), {
        video: video({ chunks: 1, bytes: 999, durationMs: 1 }),
        updatedAt: serverTimestamp(),
      }),
    );
    // Adding a video to an image post (bia1 has one image).
    await assertFails(
      updateDoc(doc(db(BIA), 'posts/bia1'), {
        video: video({ chunks: 1, bytes: 1000 }),
        updatedAt: serverTimestamp(),
      }),
    );
    await assertSucceeds(
      updateDoc(doc(db(ANA), `posts/${pid(ANA, 'v1')}`), {
        description: 'Texto revisado',
        type: 'tip',
        updatedAt: serverTimestamp(),
      }),
    );
  });

  test('the knowledge type is accepted on any post', async () => {
    await assertSucceeds(
      postBatch(db(ANA), ANA, pid(ANA, 'k1'), newPost(ANA, { type: 'knowledge' })).commit(),
    );
    await assertSucceeds(
      updateDoc(doc(db(BIA), 'posts/bia1'), { type: 'knowledge', updatedAt: serverTimestamp() }),
    );
  });

  test('a video post is deleted only together with its chunks and poster', async () => {
    const id = pid(ANA, 'v1');
    await assertSucceeds(videoBatch(db(ANA), ANA, id, videoPost(ANA)).commit());
    const fs = db(ANA);
    const partial = writeBatch(fs);
    partial.delete(doc(fs, `posts/${id}/media/0`));
    partial.delete(doc(fs, `posts/${id}/video/0`));
    partial.delete(doc(fs, `posts/${id}`));
    await assertFails(partial.commit()); // video/1 would be orphaned

    // A lone chunk or poster deletion would break the post: refused.
    await assertFails(deleteDoc(doc(fs, `posts/${id}/video/1`)));
    await assertFails(deleteDoc(doc(fs, `posts/${id}/media/0`)));
    const stranger = db(BIA);
    const theft = writeBatch(stranger);
    theft.delete(doc(stranger, `posts/${id}/video/0`));
    await assertFails(theft.commit());

    const full = writeBatch(fs);
    full.delete(doc(fs, `posts/${id}/media/0`));
    full.delete(doc(fs, `posts/${id}/video/0`));
    full.delete(doc(fs, `posts/${id}/video/1`));
    full.delete(doc(fs, `posts/${id}/video/2`)); // absent: harmless
    full.delete(doc(fs, `posts/${id}`));
    await assertSucceeds(full.commit());
  });

  test('a moderator deletes a video post with all its chunks', async () => {
    const id = pid(ANA, 'v1');
    await assertSucceeds(videoBatch(db(ANA), ANA, id, videoPost(ANA)).commit());
    const mod = db(CAIO, { admin: true });
    const missing = writeBatch(mod);
    missing.delete(doc(mod, `posts/${id}/media/0`));
    missing.delete(doc(mod, `posts/${id}/video/0`));
    missing.delete(doc(mod, `posts/${id}`));
    await assertFails(missing.commit());
    const all = writeBatch(mod);
    all.delete(doc(mod, `posts/${id}/media/0`));
    all.delete(doc(mod, `posts/${id}/video/0`));
    all.delete(doc(mod, `posts/${id}/video/1`));
    all.delete(doc(mod, `posts/${id}`));
    await assertSucceeds(all.commit());
  });
});

describe('likes', () => {
  test('like and unlike your own like only, once', async () => {
    const like = { createdAt: serverTimestamp() };
    await assertSucceeds(setDoc(doc(db(ANA), 'posts/bia1/likes/ana'), like));
    // A second like is an update of the same document: refused.
    await assertFails(setDoc(doc(db(ANA), 'posts/bia1/likes/ana'), like));
    // On behalf of someone else.
    await assertFails(setDoc(doc(db(ANA), 'posts/bia1/likes/caio'), like));
    await assertFails(deleteDoc(doc(db(CAIO), 'posts/bia1/likes/ana')));
    await assertSucceeds(deleteDoc(doc(db(ANA), 'posts/bia1/likes/ana')));
    // Extra fields and missing posts.
    await assertFails(setDoc(doc(db(ANA), 'posts/bia1/likes/ana'), { ...like, weight: 10 }));
    await assertFails(setDoc(doc(db(ANA), 'posts/nope/likes/ana'), like));
  });

  test('blocked in either direction: no likes', async () => {
    await seed({ 'blocks/bia_ana': { blocker: BIA, blocked: ANA, createdAt: Timestamp.now() } });
    await assertFails(setDoc(doc(db(ANA), 'posts/bia1/likes/ana'), { createdAt: serverTimestamp() }));
  });

  test('like count is an exact aggregation', async () => {
    await seed({
      'posts/bia1/likes/ana': { createdAt: Timestamp.now() },
      'posts/bia1/likes/caio': { createdAt: Timestamp.now() },
    });
    const snap = await assertSucceeds(
      getCountFromServer(collection(db(ANA), 'posts/bia1/likes')),
    );
    if (snap.data().count !== 2) throw new Error('expected 2 likes');
  });
});

describe('comments', () => {
  test('comment with the anti-spam stamp; not without it', async () => {
    await assertSucceeds(commentBatch(db(ANA), ANA, 'bia1', 'c1', comment(ANA)).commit());
    await assertFails(setDoc(doc(db(CAIO), 'posts/bia1/comments/c2'), comment(CAIO)));
  });

  test('anti-spam: two comments within 3 s are refused', async () => {
    await seed({ [`rateLimits/${ANA}`]: { lastCommentAt: Timestamp.now(), lastCommentKey: 'x' } });
    await assertFails(commentBatch(db(ANA), ANA, 'bia1', 'c1', comment(ANA)).commit());
  });

  test('invalid comments are refused', async () => {
    const bad = [
      comment(BIA), // as someone else
      comment(ANA, { text: '   ' }),
      comment(ANA, { text: 'x'.repeat(1001) }),
      comment(ANA, { likes: 3 }),
    ];
    for (const [i, data] of bad.entries()) {
      await assertFails(commentBatch(db(ANA), ANA, 'bia1', `bad${i}`, data).commit());
    }
  });

  test('one reply level only', async () => {
    await seed({
      'posts/bia1/comments/top': { ...comment(BIA), createdAt: Timestamp.now() },
      'posts/bia1/comments/reply': { ...comment(CAIO), parentId: 'top', createdAt: Timestamp.now() },
    });
    await assertSucceeds(
      commentBatch(db(ANA), ANA, 'bia1', 'r2', comment(ANA, { parentId: 'top' })).commit(),
    );
    await env.clearFirestore();
    await seed({
      [`users/${ANA}`]: profile('Ana'),
      'posts/bia1': seededPost(BIA),
      'posts/bia1/comments/top': { ...comment(BIA), createdAt: Timestamp.now() },
      'posts/bia1/comments/reply': { ...comment(CAIO), parentId: 'top', createdAt: Timestamp.now() },
    });
    await assertFails(
      commentBatch(db(ANA), ANA, 'bia1', 'r3', comment(ANA, { parentId: 'reply' })).commit(),
    );
  });

  test('blocked by the post author: cannot comment', async () => {
    await seed({ 'blocks/bia_ana': { blocker: BIA, blocked: ANA, createdAt: Timestamp.now() } });
    await assertFails(commentBatch(db(ANA), ANA, 'bia1', 'c1', comment(ANA)).commit());
  });

  test('delete: the comment author, the post author, the thread author', async () => {
    await seed({
      'posts/bia1/comments/a': { ...comment(ANA), createdAt: Timestamp.now() },
      'posts/bia1/comments/b': { ...comment(CAIO), createdAt: Timestamp.now() },
      'posts/bia1/comments/c': { ...comment(CAIO), parentId: 'a', createdAt: Timestamp.now() },
      'posts/bia1/comments/d': { ...comment(BIA), createdAt: Timestamp.now() },
    });
    await assertFails(deleteDoc(doc(db(ANA), 'posts/bia1/comments/b')));
    await assertSucceeds(deleteDoc(doc(db(BIA), 'posts/bia1/comments/b')));
    await assertSucceeds(deleteDoc(doc(db(ANA), 'posts/bia1/comments/c')));
    await assertSucceeds(deleteDoc(doc(db(ANA), 'posts/bia1/comments/a')));
    await assertFails(deleteDoc(doc(db(CAIO), 'posts/bia1/comments/d')));
    await assertFails(updateDoc(doc(db(BIA), 'posts/bia1/comments/d'), { text: 'editado' }));
  });
});

describe('follows', () => {
  const follow = (from, to) => ({ followerId: from, followingId: to, createdAt: serverTimestamp() });

  test('follow and unfollow; public to members only', async () => {
    await assertSucceeds(setDoc(doc(db(ANA), 'follows/ana_bia'), follow(ANA, BIA)));
    await assertSucceeds(
      getDocs(query(collection(db(CAIO), 'follows'), where('followingId', '==', BIA))),
    );
    await assertFails(getDoc(doc(anon(), 'follows/ana_bia')));
    // Duplicate (update) refused.
    await assertFails(setDoc(doc(db(ANA), 'follows/ana_bia'), follow(ANA, BIA)));
    await assertFails(deleteDoc(doc(db(CAIO), 'follows/ana_bia')));
    // The followed person may remove a follower.
    await assertSucceeds(deleteDoc(doc(db(BIA), 'follows/ana_bia')));
  });

  test('never yourself, never on behalf of others, consistent id', async () => {
    await assertFails(setDoc(doc(db(ANA), 'follows/ana_ana'), follow(ANA, ANA)));
    await assertFails(setDoc(doc(db(ANA), 'follows/caio_bia'), follow(CAIO, BIA)));
    await assertFails(setDoc(doc(db(ANA), 'follows/ana_caio'), follow(ANA, BIA)));
    await assertFails(setDoc(doc(db(ANA), 'follows/ana_ghost'), follow(ANA, 'ghost')));
  });

  test('blocked in either direction: no follow', async () => {
    await seed({ 'blocks/bia_ana': { blocker: BIA, blocked: ANA, createdAt: Timestamp.now() } });
    await assertFails(setDoc(doc(db(ANA), 'follows/ana_bia'), follow(ANA, BIA)));
  });
});

describe('saved posts', () => {
  test('private to the owner; only existing posts', async () => {
    const saved = { createdAt: serverTimestamp() };
    await assertSucceeds(setDoc(doc(db(ANA), 'users/ana/saved/bia1'), saved));
    await assertSucceeds(getDocs(collection(db(ANA), 'users/ana/saved')));
    await assertFails(getDocs(collection(db(BIA), 'users/ana/saved')));
    await assertFails(setDoc(doc(db(BIA), 'users/ana/saved/bia1'), saved));
    await assertFails(setDoc(doc(db(ANA), 'users/ana/saved/nope'), saved));
    await assertSucceeds(deleteDoc(doc(db(ANA), 'users/ana/saved/bia1')));
  });
});

describe('notifications', () => {
  test('a like notification needs the real like', async () => {
    const data = notification('like', ANA, { postId: 'bia1' });
    await assertFails(setDoc(doc(db(ANA), 'users/bia/notifications/like_bia1_ana'), data));
    await seed({ 'posts/bia1/likes/ana': { createdAt: Timestamp.now() } });
    await assertSucceeds(setDoc(doc(db(ANA), 'users/bia/notifications/like_bia1_ana'), data));
    // Same event twice: refused (no duplicates).
    await assertFails(setDoc(doc(db(ANA), 'users/bia/notifications/like_bia1_ana'), data));
  });

  test('forged notifications are refused', async () => {
    await seed({ 'posts/bia1/likes/ana': { createdAt: Timestamp.now() } });
    // Pretending to be someone else.
    await assertFails(
      setDoc(doc(db(ANA), 'users/bia/notifications/like_bia1_caio'),
        notification('like', CAIO, { postId: 'bia1' })),
    );
    // Wrong id (would allow spamming many notifications).
    await assertFails(
      setDoc(doc(db(ANA), 'users/bia/notifications/random'),
        notification('like', ANA, { postId: 'bia1' })),
    );
    // To the wrong person (Caio is not the author).
    await assertFails(
      setDoc(doc(db(ANA), 'users/caio/notifications/like_bia1_ana'),
        notification('like', ANA, { postId: 'bia1' })),
    );
    // Already read / unknown type / follow without following.
    await assertFails(
      setDoc(doc(db(ANA), 'users/bia/notifications/like_bia1_ana'),
        notification('like', ANA, { postId: 'bia1', read: true })),
    );
    await assertFails(
      setDoc(doc(db(ANA), 'users/bia/notifications/follow_ana'), notification('follow', ANA)),
    );
    // Learn request without the Match interest.
    await assertFails(
      setDoc(doc(db(ANA), 'users/bia/notifications/learn_ana'), notification('learn', ANA)),
    );
  });

  test('follow, learn, comment and reply notifications', async () => {
    await seed({
      'follows/ana_bia': { followerId: ANA, followingId: BIA, createdAt: Timestamp.now() },
      'likes/ana_bia': { from: ANA, to: BIA, liked: true, createdAt: Timestamp.now() },
      'posts/bia1/comments/c1': { ...comment(ANA), createdAt: Timestamp.now() },
      'posts/bia1/comments/r1': { ...comment(BIA), parentId: 'c1', createdAt: Timestamp.now() },
    });
    await assertSucceeds(
      setDoc(doc(db(ANA), 'users/bia/notifications/follow_ana'), notification('follow', ANA)),
    );
    await assertSucceeds(
      setDoc(doc(db(ANA), 'users/bia/notifications/learn_ana'),
        notification('learn', ANA, { postId: 'bia1' })),
    );
    await assertSucceeds(
      setDoc(doc(db(ANA), 'users/bia/notifications/comment_c1'),
        notification('comment', ANA, { postId: 'bia1', commentId: 'c1' })),
    );
    await assertSucceeds(
      setDoc(doc(db(BIA), 'users/ana/notifications/reply_r1'),
        notification('reply', BIA, { postId: 'bia1', commentId: 'r1' })),
    );
  });

  test('blocked actors cannot notify', async () => {
    await seed({
      'follows/ana_bia': { followerId: ANA, followingId: BIA, createdAt: Timestamp.now() },
      'blocks/bia_ana': { blocker: BIA, blocked: ANA, createdAt: Timestamp.now() },
    });
    await assertFails(
      setDoc(doc(db(ANA), 'users/bia/notifications/follow_ana'), notification('follow', ANA)),
    );
  });

  test('only the recipient reads and marks read; the actor can withdraw', async () => {
    await seed({
      'users/bia/notifications/follow_ana': { ...notification('follow', ANA), createdAt: Timestamp.now() },
    });
    await assertSucceeds(getDocs(collection(db(BIA), 'users/bia/notifications')));
    await assertFails(getDocs(collection(db(CAIO), 'users/bia/notifications')));
    await assertFails(getDoc(doc(db(ANA), 'users/bia/notifications/follow_ana')));
    await assertFails(updateDoc(doc(db(BIA), 'users/bia/notifications/follow_ana'), { type: 'like' }));
    await assertFails(updateDoc(doc(db(ANA), 'users/bia/notifications/follow_ana'), { read: true }));
    await assertSucceeds(updateDoc(doc(db(BIA), 'users/bia/notifications/follow_ana'), { read: true }));
    await assertFails(deleteDoc(doc(db(CAIO), 'users/bia/notifications/follow_ana')));
    await assertSucceeds(deleteDoc(doc(db(ANA), 'users/bia/notifications/follow_ana')));
  });
});

describe('content reports', () => {
  const report = (overrides = {}) => ({
    reporterId: ANA,
    reportedId: BIA,
    reason: 'scam',
    details: '',
    targetType: 'post',
    postId: 'bia1',
    commentId: null,
    createdAt: serverTimestamp(),
    ...overrides,
  });

  test('report a post or a comment of its real author', async () => {
    await seed({ 'posts/bia1/comments/c1': { ...comment(BIA), createdAt: Timestamp.now() } });
    await assertSucceeds(setDoc(doc(db(ANA), 'reports/r1'), report()));
    await assertSucceeds(
      setDoc(doc(db(ANA), 'reports/r2'),
        report({ targetType: 'comment', commentId: 'c1', reason: 'offensive' })),
    );
    // Blaming someone who did not write it.
    await assertFails(setDoc(doc(db(ANA), 'reports/r3'), report({ reportedId: CAIO })));
    await assertFails(setDoc(doc(db(ANA), 'reports/r4'), report({ reason: 'dislike' })));
    await assertFails(setDoc(doc(db(ANA), 'reports/r5'), report({ reporterId: CAIO })));
  });

  test('reports are private: only moderators read them', async () => {
    await seed({ 'reports/r1': { ...report(), createdAt: Timestamp.now() } });
    await assertFails(getDoc(doc(db(ANA), 'reports/r1')));
    await assertFails(getDoc(doc(db(BIA), 'reports/r1')));
    await assertSucceeds(getDoc(doc(db(CAIO, { admin: true }), 'reports/r1')));
    await assertSucceeds(
      updateDoc(doc(db(CAIO, { admin: true }), 'reports/r1'), { status: 'reviewed' }),
    );
    await assertFails(updateDoc(doc(db(CAIO, { admin: true }), 'reports/r1'), { reason: 'spam' }));
  });
});

describe('audit follow-up attacks', () => {
  test('one stamp cannot carry two posts or two comments', async () => {
    const fs = db(ANA);
    const batch = postBatch(fs, ANA, pid(ANA, 'a1'), newPost(ANA));
    batch.set(doc(fs, `posts/${pid(ANA, 'a2')}`), newPost(ANA));
    await assertFails(batch.commit());

    const c = commentBatch(fs, ANA, 'bia1', 'c1', comment(ANA));
    c.set(doc(fs, 'posts/bia1/comments/c2'), comment(ANA));
    await assertFails(c.commit());
  });

  test('post ids belong to their author (no takeover of a deleted id)', async () => {
    await assertFails(postBatch(db(ANA), ANA, 'bia1x', newPost(ANA)).commit());
    await assertFails(postBatch(db(ANA), ANA, pid(BIA, 'gone'), newPost(ANA)).commit());
    await assertFails(postBatch(db(ANA), ANA, 'ana_short', newPost(ANA)).commit());
  });

  test('tags, keywords and ratios are bounded and typed', async () => {
    const bad = [
      { tags: ['x'.repeat(5000)] },
      { tags: [{ evil: true }] },
      { keywords: ['y'.repeat(20000)] },
      { mediaCount: 1, aspectRatios: ['x'] },
      { mediaCount: 1, aspectRatios: [1000] },
    ];
    for (const [i, overrides] of bad.entries()) {
      const media = overrides.mediaCount ? [image()] : [];
      await assertFails(
        postBatch(db(ANA), ANA, pid(ANA, `t${i}`), newPost(ANA, overrides), media).commit(),
      );
    }
  });

  test('anti-spam stamp: no create with both kinds, no going back', async () => {
    await assertFails(
      setDoc(doc(db(ANA), `rateLimits/${ANA}`), {
        lastPostAt: serverTimestamp(),
        lastPostId: 'a',
        lastCommentAt: serverTimestamp(),
        lastCommentKey: 'b',
      }),
    );
    await assertFails(deleteDoc(doc(db(ANA), `rateLimits/${ANA}`)));
  });

  test('edits: at most one every 5 s', async () => {
    await seed({ 'posts/bia2': { ...seededPost(BIA), updatedAt: Timestamp.now() } });
    await assertFails(
      updateDoc(doc(db(BIA), 'posts/bia2'), { description: 'de novo', updatedAt: serverTimestamp() }),
    );
  });

  test('a post cannot be deleted leaving its images behind', async () => {
    await assertFails(deleteDoc(doc(db(BIA), 'posts/bia1')));
  });

  test('blocks also protect the person being replied to', async () => {
    await seed({
      'posts/bia1/comments/top': { ...comment(CAIO), createdAt: Timestamp.now() },
      'blocks/caio_ana': { blocker: CAIO, blocked: ANA, createdAt: Timestamp.now() },
    });
    await assertFails(
      commentBatch(db(ANA), ANA, 'bia1', 'r1', comment(ANA, { parentId: 'top' })).commit(),
    );
    // Liking when you blocked the author is refused too.
    await seed({ 'blocks/ana_bia': { blocker: ANA, blocked: BIA, createdAt: Timestamp.now() } });
    await assertFails(setDoc(doc(db(ANA), 'posts/bia1/likes/ana'), { createdAt: serverTimestamp() }));
  });

  test('notification ids and types must match the event exactly', async () => {
    await seed({
      'posts/bia1/comments/c1': { ...comment(ANA), createdAt: Timestamp.now() },
      'posts/bia1/comments/r1': { ...comment(ANA), parentId: 'c1', createdAt: Timestamp.now() },
      'posts/bia1/likes/ana': { createdAt: Timestamp.now() },
    });
    // "comment" pointing at a reply.
    await assertFails(
      setDoc(doc(db(ANA), 'users/bia/notifications/comment_r1'),
        notification('comment', ANA, { postId: 'bia1', commentId: 'r1' })),
    );
    // A path smuggled in postId makes postAuthor() read another document.
    await seed({ 'posts/bia1/comments/c2': { ...comment(CAIO), createdAt: Timestamp.now() } });
    await assertFails(
      setDoc(doc(db(ANA), 'reports/smuggled'), {
        reporterId: ANA,
        reportedId: CAIO,
        reason: 'spam',
        details: '',
        targetType: 'post',
        postId: 'bia1/comments/c2',
        commentId: null,
        createdAt: serverTimestamp(),
      }),
    );
    // To yourself.
    await assertFails(
      setDoc(doc(db(BIA), 'users/bia/notifications/follow_bia'), notification('follow', BIA)),
    );
  });

  test('the admin claim must be the boolean true', async () => {
    await seed({ 'reports/r1': { reporterId: ANA, reportedId: BIA, createdAt: Timestamp.now() } });
    await assertFails(getDoc(doc(db(CAIO, { admin: 'true' }), 'reports/r1')));
    await assertFails(getDocs(collection(db(ANA), 'reports')));
  });

  test('visitors cannot count or list posts; media is not listable', async () => {
    await assertFails(getCountFromServer(collection(anon(), 'posts')));
    await assertFails(getDocs(collection(db(ANA), 'posts/bia1/media')));
  });
});
