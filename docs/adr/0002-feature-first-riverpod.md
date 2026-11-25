# 0002 — Feature-first structure with Riverpod and go_router, no domain layer

**Status:** Accepted

## Context

Four features (auth, profile, discover, matches/chat), about eight screens, one backend. The code must be easy to test and to extend during the course.

## Problem

How much architecture: full Clean Architecture (entities, use cases, repository interfaces, data sources, DTOs) or something lighter?

## Alternatives considered

1. **Clean Architecture per feature** — strong boundaries; ~3–4× more files, interfaces with a single implementation.
2. **Feature-first, repositories as concrete classes injected by Riverpod** — few files; tests swap Firebase via provider overrides and in-memory fakes.
3. **Bloc / Provider** for state — viable; Riverpod already provides DI, async state and overrides in one tool.

## Decision

Option 2. Each feature folder holds a model + repository + providers file and its screens. Riverpod 3 (no code generation) for state and DI; go_router with a pure, tested `resolveRedirect` for auth/profile gating.

## Rationale

YAGNI: repository interfaces add nothing while there is one backend and tests can fake Firestore itself (`fake_cloud_firestore`). No code generation keeps the build simple.

## Consequences

- Repositories depend on Firebase types directly; switching backend means rewriting them (screens stay intact because they consume providers and plain models).
- If a feature grows complex business rules, introduce a domain layer for that feature only.
