# 0003 — Create matches on the client, guarded by Security Rules

**Status:** Accepted (revisit before production)

## Context

A match must exist only when two users liked each other. Firestore has no server code unless Cloud Functions are used, which require the paid Blaze plan.

## Problem

Where to create the `matches` document so that it cannot be forged.

## Alternatives considered

1. **Cloud Function** triggered on `likes` writes — trusted, but needs Blaze plan and Functions deployment.
2. **Client creates the match; rules verify** that `likes/{a}_{b}` and `likes/{b}_{a}` both exist with `liked == true`, the caller is a member and the id is the sorted pair.
3. **No match document**; derive matches by querying likes — complex queries, no place for chat metadata.

## Decision

Option 2. After liking, the client attempts to create `matches/{sortedA}_{sortedB}`; the rules accept it only when both likes exist. A `permission-denied` answer means "no mutual interest yet" (or the other person created the match a moment earlier, which a follow-up `get` detects).

*Amended 2026-11-20 (security audit):* the client no longer reads the other person's like (likes are private to their author), and the match stores no names (read from profiles instead).

## Rationale

Works on the free plan; the invariant that matters (mutual interest) is enforced on the server; deterministic id makes creation idempotent; nobody can learn who liked or skipped them.

## Consequences

- Every non-mutual like costs one denied write attempt (counted as a read for the rule's `exists()`/`get()` checks).
- Match documents contain only ids, preview and timestamps, all validated by rules; the preview must mirror a real message created in the same batch.
- Two users liking each other at the same instant: one create wins, the other gets `permission-denied` and finds the existing match.
- Rules are covered by emulator tests in `firestore_rules_test/`.
