# Serenity — Decision Log

> **Owner:** Engineering team
> **Purpose:** Permanent record of every major architecture decision. New contributors should read this before making changes.
> **Related:** [Architecture](ARCHITECTURE.md) | [Roadmap](ROADMAP.md)

---

## Format

Each entry captures:
- **Date** — When the decision was made
- **Context** — What prompted the decision
- **Decision** — What we chose
- **Reason** — Why we chose it
- **Alternatives considered** — What else was evaluated
- **Trade-offs** — What we accepted by choosing this
- **Long-term impact** — How this affects future development

---

### Entry 1: Auth Gate uses Navigator, not GoRouter

**Date:** 2026-06-30

**Context:** Serenity needed an auth gate that redirects unauthenticated users to sign-in, authenticated uncoupled users to couple linking, and authenticated coupled users to the main app. The main app already uses GoRouter for deep linking and bottom nav. Should the auth gate share the same GoRouter instance?

**Decision:** Auth gate uses a plain `MaterialApp` with `Navigator`. Only the authenticated app (`SerenityApp`) uses `MaterialApp.router` with GoRouter.

**Reason:**
- Auth screens don't need URL-based routing or deep linking
- Simpler code — no need to guard routes or handle redirect logic in GoRouter
- Auth gate is a wrapper widget, not a router — it switches between whole apps, not screens
- Separate navigator stacks prevent auth screens from polluting the app navigation history

**Alternatives considered:**
1. **Single GoRouter with redirect guards** — All routes in one GoRouter with redirect functions. Rejected because: redirect logic becomes complex, auth screens appear in browser history for web, harder to maintain clear separation.
2. **GoRouter shell route for auth** — Use a shell route wrapping auth screens. Rejected because: auth screens don't share the bottom nav, they're a completely different app shell.
3. **Nested Navigator** — Embed Navigator in auth gate that switches between auth screens. Rejected because: auth gate doesn't have enough screens to warrant a navigator.

**Trade-offs:**
- + Clean separation: auth UI is entirely separate from app UI
- + Simpler GoRouter config (no auth guards)
- - GoRouter features (deep linking, browser back) don't work in auth screens
- - Two MaterialApp instances means duplicate theme configuration

**Long-term impact:** Low. Auth screens are unlikely to grow complex routing needs. If they do, a dedicated GoRouter can replace the Navigator.

---

### Entry 2: DAO-based pattern instead of Repository pattern

**Date:** 2026-06-28

**Context:** Serenity needed a data access layer. Common Flutter patterns include Repository (abstraction over data sources), DAO (direct database operations), and Active Record (model knows how to persist itself).

**Decision:** Use DAOs directly without a formal repository layer. Each DAO wraps a Drift table and exposes CRUD methods. Screens and providers call DAOs directly.

**Reason:**
- Only one data source exists (local Drift database). Supabase is accessed only by SyncService, never by screens. A repository abstraction adds indirection without benefit.
- Simpler to understand and navigate — `MemoriesDao` does everything with memories.
- Fewer files to maintain.
- DAOs can be easily promoted to repositories if a second data source appears later.

**Alternatives considered:**
1. **Repository pattern** — Repository interface per entity, DAOs behind repositories. Rejected as premature abstraction for a single-data-source app.
2. **Active Record (Drift companions)** — Operations on model objects directly. Rejected because Drift companions are data objects, not suited for business logic.

**Trade-offs:**
- + Direct, simple, easy to follow
- + No boilerplate repository interfaces
- - If a second data source appears (e.g., HTTP API), DAOs need refactoring to repositories
- - DAOs are concrete, not abstract — harder to mock in tests (though Drift's built-in mocking helps)

**Long-term impact:** Medium. If sync grows to include conflicts, offline queue, or pending operations, the data layer should be refactored to repositories. That's a future concern.

---

### Entry 3: Last-write-wins conflict resolution

**Date:** 2026-06-29

**Context:** The sync engine needed a conflict resolution strategy for when both partners edit the same entry offline.

**Decision:** Last-write-wins with local preference on pull. Push always wins (sending local changes). Pull compares `updated_at` timestamps — remote wins if newer, local wins if equal or older.

**Reason:**
- Simplest strategy that works for a journal app
- Simultaneous editing of the same entry by both partners is rare
- Data loss is minimal (one partner's latest edit to one entry, recoverable from memory if truly important)
- CRDT and three-way merge are overengineered for this use case

**Alternatives considered:**
1. **CRDT (Conflict-free Replicated Data Types)** — Full conflict resolution at the character level. Rejected as massive overengineering for a text-entry app.
2. **Three-way merge (like Git)** — Store base version, compute diff. Rejected because it requires storing multiple versions and a merge UI.
3. **Manual conflict resolution** — Show both versions and let user choose. Rejected because it forces sync to be visible and interrupts the user.
4. **First-writer-wins** — First push locks the entry. Rejected because it creates confusing "your changes were rejected" scenarios.

**Trade-offs:**
- + Simple implementation, no merge UI needed
- + Predictable behavior
- - Silent data loss on concurrent edits (latest writer's changes overwrite previous)
- - No undo for overwritten entries

**Long-term impact:** Low. If concurrent edits become common, add a `conflicts` table with a "review conflict" UI. The current implementation can be extended without breaking existing data.

---

### Entry 4: Invite code RLS allows open lookup

**Date:** 2026-06-29

**Context:** Invite codes needed to be discoverable by anyone who has the code value. But Supabase RLS defaults to deny-all. The `couples` table has an RLS policy that restricts reads to the two partners. How does a new user (partner B) look up a couple by invite code if they can't read the `couples` table?

**Decision:** Create a permissive RLS policy on `couples` that allows anyone to select rows where:
- `invite_code` is not null
- `code_expires_at` > now()
- `partner_b_id` is null

This allows invite code lookup by code value only. The app never returns full couple data from the lookup — just validates the code exists and is valid.

**Reason:**
- Invite codes are designed to be shared. The code itself is the auth mechanism.
- The policy is scoped to only return valid (non-expired, unclaimed) codes.
- No sensitive data is exposed — the lookup returns only existence + expiry, not partner names or other data.

**Alternatives considered:**
1. **No RLS, application-layer validation** — All backend logic in server-side functions. Rejected because it requires Supabase Edge Functions or a separate backend.
2. **Hash-based invite URL** — Partner A sends a signed URL to Partner B. Rejected because invite codes are simpler and more natural for in-person sharing (read code aloud).
3. **Separate invite_codes table** — Isolate code lookup to a different table with permissive RLS. Rejected as overengineering for alpha.

**Trade-offs:**
- + Simple, works with Supabase RLS only (no server functions)
- + Invite code is the auth mechanism — no additional security needed
- - Anyone with a valid code can enumerate open couples (mitigated by 24h expiry)
- - Cannot prevent brute-force code guessing at the database level (mitigated by 36^6 combinations and rate limiting in app)

**Long-term impact:** Low. Before public release, switch to a hash-based or token-based invite system. The current approach is fine for alpha/beta.

---

### Entry 5: publishableKey replaces anonKey

**Date:** 2026-07-02

**Context:** `flutter analyze` showed a deprecation warning for the `anonKey:` parameter in `Supabase.initialize()`. The SDK deprecated it in favor of `publishableKey:`.

**Decision:** Replace `anonKey:` with `publishableKey:` in `lib/core/supabase/supabase_config.dart`. Use the same key value (the Supabase anon/public key).

**Reason:**
- Removing deprecation warnings keeps the codebase clean
- The value is identical — Supabase renamed the parameter for clarity
- No functional change

**Alternatives considered:**
1. **Ignore the warning** — Works but accumulates technical debt.
2. **Downgrade supabase_flutter** — Rejected because it would lose other improvements.

**Trade-offs:**
- + Clean analysis output (0 warnings)
- + Future-proof against parameter removal
- - Minor change with no functional impact

**Long-term impact:** None. Pure maintenance.

---

### Entry 6: TagsDao + colored pills (Phase A1)

**Date:** 2026-06-29

**Context:** Phase 1 schema migration deleted `MemoryTags` table and replaced with `Tags` + `TagAssignments` tables. Three files broke (timeline_dao.dart, create_memory_screen.dart, memory_detail_screen.dart) from references to the old table. TagsDao already existed from the migration but wasn't wired in. Tags had a `color` hex field that wasn't being used in pill rendering.

**Decision:** Minimal TagsDao fix + colored pill rendering. Created TagsDao, updated type chain to pass `List<Tag>` instead of `List<String>`, rendered tag pills using `tag.color` hex with fallback to primary. No TagSelector widget (scope creep before APK testing).

**Reason:**
- Restore compilation and tagged content visibility
- Colored pills provide immediate visual value with minimal code
- TagSelector can be added in a future iteration

**Trade-offs:**
- + Compilation restored, colored tags visible on timeline and memory detail
- - Tag creation is text-input only (no preset picker)
- - No tag editing or management screen

---

### Entry 7: NDK r28 / CMake 3.31.4 compatibility

**Date:** 2026-06-29

**Context:** Release APK build failed at CMake configure step. NDK r28 (28.2.13676358) requires CMake 3.28+, but Android SDK had CMake 3.22.1 installed. Plugins (app_links, device_info_plus, etc.) enforce NDK 28, so downgrading NDK wasn't viable.

**Decision:** Install CMake 3.31.4 via Android SDK Manager. Set `cmake.dir` in `android/local.properties` to point to the new version. Keep `ndkVersion` unset (defaults to `flutter.ndkVersion` = NDK r28).

**Reason:**
- Minimal change — only the local.properties path changes
- CMake 3.31.4 is fully compatible with NDK r28
- No project config changes needed (Gradle auto-discovers newer CMake when pointed)

**Alternatives considered:**
1. **Pin ndkVersion to 25.0.8775105** — Downgrade NDK to one compatible with CMake 3.22.1. Rejected because plugins enforce NDK 28; downgrading causes plugin compilation failures.
2. **Remove passkeys transitive dependency** — Remove `passkeys_doctor` by forking supabase_flutter. Rejected because it's too invasive for a build fix.
3. **Disable native compilation for passkeys** — Not possible without modifying the package source.

**Trade-offs:**
- + Minimal change (cmake.dir only)
- + No project config changes needed
- - CMake is a build-time dependency, not tracked in pubspec — each developer needs to install it separately
- - If cmake.dir is unset or wrong, the build falls back to CMake 3.22.1 and fails

---

### Entry 8: INTERNET permission in main manifest

**Date:** 2026-07-02

**Context:** Release APK had no internet access. Every Supabase request failed with `AuthRetryableFetchException`. Investigation found `<uses-permission android:name="android.permission.INTERNET" />` was only in `debug/AndroidManifest.xml` and `profile/AndroidManifest.xml` — not in `src/main/AndroidManifest.xml`.

**Decision:** Add `<uses-permission android:name="android.permission.INTERNET" />` to `android/app/src/main/AndroidManifest.xml`.

**Reason:**
- Release builds merge all AndroidManifest.xml files into one. Debug/profile manifests have their own permissions because they're in separate source sets. Main manifest is the base — missing INTERNET means release APKs have no network access.
- The app needs internet for Supabase auth and sync.
- This is the standard Android pattern — declare permissions in main manifest, add debug-only ones in debug manifest.

**Alternatives considered:**
1. **Build debug APK for release** — Use `flutter build apk --debug` and distribute that. Rejected because debug APK has debug flags, different signing, and leaks debug info.
2. **Move INTERNET to debug manifest** — Would work for debug builds only. Release would still fail.

**Trade-offs:**
- + Correct Android permission pattern
- + Both debug and release APKs work
- - Something we should have caught earlier (part of Flutter's default template, may have been accidentally removed)

**Long-term impact:** None. Standard Android configuration.

---

### Entry 9: Evolution from offline-only to local-first architecture

**Date:** 2026-07-03

**Context:** Serenity was originally designed as an offline-only app with optional sync. After implementing the sync engine, couple linking, and cloud schema, the product evolved. The app is now designed around two connected users sharing one relationship story. The previous "offline-first" framing undersold the sync experience.

**Decision:** Serenity is now a **local-first** application with seamless cloud synchronization. The architecture is described as:

```
Flutter → Drift → Sync Engine → Supabase → Partner Device
```

Key changes in philosophy:
- Local storage provides speed (primary read/write interface)
- Sync provides continuity (transparent background bridge)
- Supabase enables shared experiences (RLS-isolated multi-device)
- Offline capability provides resilience (works identically disconnected)

**Reason:**
- The product is designed around two connected users — offline-only is insufficient for the hero feature
- "Local-first" is more accurate than "offline-first" — it captures both the local ownership and the connectivity benefit
- The architecture didn't change; the framing evolved to match what was already built
- Clearer guidance for future engineering decisions (sync is expected, not optional)

**Alternatives considered:**
1. **Keep "offline-first"** — Misleading now that sync is core. Users would expect sync to be an afterthought.
2. **"Cloud-first"** — Wrong. The cloud is the sync substrate, not the primary interface.
3. **"Hybrid"** — Vague. Doesn't communicate the priority of local storage.

**Trade-offs:**
- + Accurate reflection of the current architecture
- + Clearer guidance for future decisions
- - Changes a previously documented position (requires documentation update)
- - Some early code references still say "offline-first"

**Long-term impact:** Medium. This framing affects how every future feature is evaluated. Sync is now a core capability, not an add-on.

---

### Entry 10: Environment issues are not product blockers

**Date:** 2026-07-03

**Context:** During Phase 5 development, the project spent significant time debugging an NDK 28 + CMake 3.22.1 incompatibility on one Windows machine. This created the impression that the project was "blocked" when the actual issue was machine-specific. The same build succeeded on other environments without changes.

**Decision:** Build environment issues are categorized and isolated in BUILD.md. They never appear in ROADMAP.md, PRODUCT.md, or CHANGELOG.md. If an environment cannot produce a build after a reasonable effort (documented fix attempts in BUILD.md), the team switches to an alternative environment rather than continuing to debug.

**Reason:**
- Product progress should never depend on one machine's SDK configuration
- Build environment issues follow a predictable pattern (SDK version, file locking, dependency mismatch) — none are project-blocking
- Multiple environments exist: developer machines, GitHub Actions CI, clean Android Studio installs
- Spending hours on environment debugging is expensive and produces no product value

**Alternatives considered:**
1. **Fix every machine** — Not scalable. Every machine has different SDK versions, OS patches, and configuration.
2. **Document the fix and move on** — This is what we chose. The fix is documented in BUILD.md with the CMake/NDK resolution.
3. **Dockerize the build** — Guarantees reproducible builds. Rejected for now because it adds complexity for a single-developer project. Worth revisiting at Closed Alpha.

**Trade-offs:**
- + Product progress is never falsely blocked
- + Clear escalation path when an environment fails
- - Documentation must be maintained as environments change
- - GitHub Actions CI needs to be set up (future work) for automated verification

**Long-term impact:** High. This decision establishes that the project's documentation system owns build concerns separately from product concerns. Any future contributor knows: product docs describe the product, BUILD.md describes how to build it. Never the twain shall meet.
