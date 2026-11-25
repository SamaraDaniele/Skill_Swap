# 0001 — Firebase as backend

**Status:** Accepted

## Context

The course brief requires front-end, back-end and database integrated: authentication, profiles, skills, compatibility, interests, matches and real-time chat. The team is small, with a course timeline, and no budget for servers.

## Problem

Choose a backend that delivers auth, persistent relational-ish data, real-time messaging and trustworthy authorization with minimal operations work.

## Alternatives considered

1. **Firebase (Auth + Firestore)** — managed, real-time listeners, offline cache, Security Rules, free tier, first-party Flutter SDKs.
2. **Supabase (Postgres + RLS + Realtime)** — relational model fits matches well; also managed; requires SQL migrations and RLS policies.
3. **Custom REST API + database** — full control; must build and host auth, websockets, deployment.
4. **Local mock only** — fastest to demo; fails the "integrated back-end" requirement.

## Decision

Firebase Authentication (email/password) + Cloud Firestore, with authorization in `firestore.rules`. Chosen by the project owner.

## Rationale

Real-time chat and offline cache come built-in; no server to run; Security Rules can validate the match invariant (both likes exist); widely documented for Flutter.

## Consequences

- Business rules that need trust must be expressible in rules or moved to Cloud Functions (Blaze plan).
- Queries are limited (e.g., `array-contains-any` ≤ 30, no joins) → candidate ranking on the client, denormalized names in matches.
- Vendor lock-in to Firebase SDKs, contained inside repositories.
- Running the app requires each developer to run `flutterfire configure`.
