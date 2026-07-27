# Serenity Sync Architecture Plan (Path A)

**Product:** Auth + couple linking + sync
**Version:** 1.1.0
**Date:** 2026-06-29
**Author:** onyx-architect

---

## Product Layer

### Vision

Serenity stays offline-first and private. Sync is a transparent bridge between two phones, not a cloud dependency. Partners see each other's memories, milestones, reflections, and appreciations without managing accounts or thinking about "the cloud."

### Principles

1. **Local first, always.** The app works fully offline. Sync is a background feature, not a gate.
2. **No lock-in.** Couples can unlink at any time. Each partner keeps their local data.
3. **No social features.** No feed, no likes, no comments. Just shared retrospection.
4. **No streaks or stats.** Gamification-free sync is invisible. No "sync streak" counters.
5. **Privacy by design.** Supabase stores encrypted-at-rest data. No third-party analytics. No reading couple content.

### User Stories

| Priority | Story |
|----------|-------|
| P0 | As a user, I can create an account with email + password |
| P0 | As a user, I can sign in on any device and restore my data |
| P0 | As a user, I can generate a couple invite code for my partner |
| P0 | As a user, I can enter my partner's invite code to link our accounts |
| P1 | As a linked partner, I see my partner's memories on my timeline |
| P1 | As a linked partner, I see my partner's milestones on my timeline |
| P1 | As a linked partner, I see my partner's reflections in the reflect tab |
| P2 | As a linked partner, I can edit entries I created (my partner cannot edit mine) |
| P2 | As a linked partner, I see a sync status indicator (last synced time) |
| P2 | As a user, I can unlink from my partner |
| P2 | As a user, I can delete my account and all cloud data |

### Non-Goals (Phase A2)

- Real-time sync (WebSockets / Realtime). Initial sync uses REST polling.
- Media sync (photos live on-device only for now).
- Multi-device sync for a single user (phone + tablet). One user = one device.
- Collaborative editing (both editing same entry simultaneously). Sync is eventual.
- Offline queue UI (no "pending sync" badge on each entry). Batch sync state only.

---

## UX Layer

### Flow: New User Sign Up

```
[Onboarding: Enter Name] → [Sign Up: Email + Password] → [Create or Join Couple]
```

1. User opens Serenity, sees the existing OnboardingScreen (name + partner name).
2. After entering names, user is prompted: "Create an account to sync with your partner?"
3. User enters email + password on a new screen.
4. User is offered: "Create a couple code" or "Join a couple."
5. If creating: a 6-character code is generated and displayed. User shares it with partner.
6. If joining: user enters the 6-character code from partner.
7. Both users are now linked in the `couples` Supabase table.
8. The app proceeds to the main timeline.

### Flow: Returning User Sign In

```
[App Launch] → [Auth Check] → [Sign In Screen] → [Timeline]
```

1. App checks for persisted Supabase session.
2. If session valid and couple link exists → go to timeline.
3. If session valid but no couple link → show couple linking screen.
4. If no session → show sign in screen.
5. If sign in fails → show error with retry.

### Flow: Sync Visualization

- A subtle sync icon (LucideIcons.cloud or LucideIcons.refreshCw) in the app bar or Me screen status area.
- Shows "Synced" (checkmark), "Syncing..." (spinner), or "Sync paused" (offline).
- No per-entry sync state. Too noisy for a journal app.

### Edge Cases

- **Both partners open app offline**: Both write entries. When back online, sync merges both sides.
- **Partner unlinks**: Sync stops. Both keep local data. A confirmation dialog warns before unlinking.
- **Partner deletes account**: The remaining user is notified and can choose to keep syncing solo or unlink.
- **Wrong invite code**: Clear error message with option to retry.
- **Code expired**: Invite codes expire after 24 hours. Generate a new one.
- **Email already registered**: Standard "account exists" error with "Sign in" link.

---

## Design Layer

### Auth Screens (Dark mode first, consistent with existing 5 themes)

**Sign In Screen:**
- SerenityHeader at top (existing component)
- Email text field
- Password text field (obscured)
- "Sign In" filled button
- "Don't have an account? Sign Up" text button
- Error state: red inline message below fields
- Loading state: button shows CircularProgressIndicator

**Sign Up Screen:**
- Same layout as Sign In
- Confirm password field
- "Create Account" filled button
- "Already have an account? Sign In" text button
- Loading state: button shows CircularProgressIndicator

**Couple Code Screen (Create):**
- Large generated code (6 chars, monospace, bold)
- "Share this code with your partner" subtitle
- Code auto-copied to clipboard
- "Waiting for partner..." state with subtle pulse animation
- On success: smooth transition to timeline

**Couple Code Screen (Join):**
- 6 individual character input boxes (PIN-entry style)
- "Enter your partner's code" subtitle
- Auto-submit on 6th character
- Loading state while verifying
- Error: shake animation on wrong code

### Existing Screens Impact

**Onboarding Screen:** Needs refactor. Currently collects name + partner name. After Path A, it should:
- Step 1: Enter name + partner name (existing)
- Step 2: Email + password (new)
- Step 3: Create or join couple (new)

**Me Screen:** Needs additions:
- Sync status row (between profile and theme sections)
- Couple settings section (invite code, couple name, unlink button)
- Sign out button (replaces or augments the data section)
- Partner profile photo (if synced)

**Router:** Auth guard needs to wrap all app routes. Unauthenticated users see auth flow.

---

## Architecture Layer

### Supabase Schema (New, Remote Only)

```sql
-- Profiles: extends Supabase auth.users
create table profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  display_name text not null,
  partner_name text,
  theme_index integer default 0,
  brightness text default 'dark',
  profile_photo_url text,
  created_at timestamptz default now(),
  updated_at timestamptz default now()
);

-- Couples: links two users
create table couples (
  id uuid primary key default gen_random_uuid(),
  invite_code text unique not null,
  code_expires_at timestamptz not null,
  created_at timestamptz default now(),
  partner_a_id uuid references profiles(id) on delete set null,
  partner_b_id uuid references profiles(id) on delete set null,
  linked_at timestamptz
);

-- Memories: synced per couple
create table memories (
  id bigint primary key,
  couple_id uuid references couples(id) on delete cascade,
  created_by uuid references profiles(id) on delete set null,
  type text not null default 'memory',
  title text not null,
  body text not null,
  date date not null,
  is_favorite boolean default false,
  created_at timestamptz not null,
  updated_at timestamptz not null,
  is_deleted boolean default false
);

-- Milestones: synced per couple
create table milestones (
  id bigint primary key,
  couple_id uuid references couples(id) on delete cascade,
  created_by uuid references profiles(id) on delete set null,
  title text not null,
  date date not null,
  description text,
  icon text,
  color text,
  type text not null default 'milestone',
  created_at timestamptz not null,
  updated_at timestamptz not null,
  is_deleted boolean default false
);

-- Reflections: synced per couple
create table reflections (
  id bigint primary key,
  couple_id uuid references couples(id) on delete cascade,
  created_by uuid references profiles(id) on delete set null,
  prompt_type text not null,
  prompt_text text not null,
  content text not null,
  mood_score integer,
  date date not null,
  created_at timestamptz not null,
  is_deleted boolean default false
);

-- Question Answers: synced per couple
create table question_answers (
  id bigint primary key,
  couple_id uuid references couples(id) on delete cascade,
  created_by uuid references profiles(id) on delete set null,
  question_id integer not null,
  category text not null,
  answer_text text not null,
  date_answered date not null,
  created_at timestamptz not null,
  is_deleted boolean default false
);

-- Tags: shared per couple (synced)
create table tags (
  id bigint primary key,
  couple_id uuid references couples(id) on delete cascade,
  name text not null,
  color text,
  icon text,
  is_preset boolean default false,
  created_at timestamptz default now(),
  is_deleted boolean default false
);

-- Tag Assignments: links tags to memories
create table tag_assignments (
  id bigint primary key,
  tag_id bigint references tags(id) on delete cascade,
  memory_id bigint references memories(id) on delete cascade,
  created_at timestamptz default now()
);

-- Create indexes
create index memories_couple_date_idx on memories(couple_id, date desc);
create index milestones_couple_date_idx on milestones(couple_id, date desc);
create index reflections_couple_date_idx on reflections(couple_id, date desc);
create index question_answers_couple_date_idx on question_answers(couple_id, date_answered desc);
create index tags_couple_idx on tags(couple_id);
```

### Drift Schema Changes (Local, v3)

Add these columns to all syncable tables:

```dart
// In Memories, Milestones, Reflections, QuestionAnswers tables:
TextColumn get createdBy => text().nullable()();  // Supabase user UUID
TextColumn get coupleId => text().nullable()();  // Supabase couple UUID
BoolColumn get isDeleted => boolean().withDefault(const Constant(false))();
```

The `isSynced` column already exists on all 4 tables. No change needed there.

New table for sync metadata:

```dart
class SyncMetadata extends Table {
  TextColumn get key => text()();  // 'last_pull_at', 'couple_id', 'user_id'
  TextColumn get value => text().nullable()();
  @override
  Set<Column> get primaryKey => {key};
}
```

### Local Database v3 Migration

Schema upgrade from v2 to v3:

```dart
if (from < 3) {
  // Add created_by to Memories
  await m.addColumn(memories, memories.createdBy);
  // Add couple_id to Memories
  await m.addColumn(memories, memories.coupleId);
  // Add is_deleted to Memories
  await m.addColumn(memories, memories.isDeleted);

  // Repeat for Milestones, Reflections, QuestionAnswers
  // ...

  // Create SyncMetadata table
  await m.createTable(syncMetadata);
}
```

### File Organization

```
lib/
  core/
    auth/                               # NEW
      auth_provider.dart                # Auth state + sign in/out via Riverpod
      auth_gate.dart                    # Widget that redirects based on auth state
    supabase/                           # NEW
      supabase_config.dart              # URL, anon key, initialization
    sync/                               # NEW
      sync_service.dart                 # Push/pull engine (core sync logic)
      sync_provider.dart                # Provider that triggers sync on connectivity
      sync_state.dart                   # Enum: idle, syncing, error, offline
      sync_metadata_dao.dart            # DAO for SyncMetadata table
    database/
      tables/
        sync_metadata_table.dart        # NEW
      app_database.dart                 # MODIFIED: v3 migration, add SyncMetadata
      daos/
        memories_dao.dart               # MODIFIED: mark isSynced = false on writes
        milestones_dao.dart             # MODIFIED: mark isSynced = false on writes
        reflections_dao.dart            # MODIFIED: mark isSynced = false on writes
        question_answers_dao.dart       # MODIFIED: mark isSynced = false on writes
        tags_dao.dart                   # MODIFIED: mark isSynced = false on writes
        sync_metadata_dao.dart          # NEW
      database_provider.dart            # MODIFIED: register sync metadata DAO
    router/
      app_router.dart                   # MODIFIED: auth-aware route guards
    providers/
      app_providers.dart                # MODIFIED: add auth-related providers
    components/
      sync_status_indicator.dart        # NEW: small cloud icon in app bar
      auth_text_field.dart              # NEW: styled email/password field

  features/
    auth/                               # NEW
      screens/
        sign_in_screen.dart
        sign_up_screen.dart
        create_couple_screen.dart
        join_couple_screen.dart
        couple_linking_screen.dart      # Entry point: create or join
    couple/                             # NEW
      providers/
        couple_provider.dart            # Couple state, invite code generation
      screens/
        couple_settings_screen.dart     # Couple info, unlink, invite code
    me/
      screens/
        me_screen.dart                  # MODIFIED: add sync status, couple section
        onboarding_screen.dart          # MODIFIED: multi-step with auth
    story/
      providers/
        timeline_provider.dart          # MODIFIED: include partner entries
```

---

## Engineering Layer

### Dependencies (New)

Add to `pubspec.yaml`:

```yaml
dependencies:
  supabase_flutter: ^2.8.0              # Already added
  connectivity_plus: ^6.0.0             # Network state detection
  uuid: ^4.0.0                          # Generate IDs for sync (optional)
```

### Supabase Initialization

```dart
// lib/core/supabase/supabase_config.dart
class SupabaseConfig {
  static const String url = 'https://keynxnucfkxovlvysgym.supabase.co';
  static const String anonKey = 'NEED_FROM_JOHN';  // John needs to provide this

  static Future<void> initialize() async {
    await Supabase.initialize(
      url: url,
      anonKey: anonKey,
    );
  }
}
```

```dart
// lib/main.dart (modified)
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SupabaseConfig.initialize();
  runApp(const ProviderScope(child: SerenityApp()));
}
```

### Auth Provider

```dart
// lib/core/auth/auth_provider.dart
enum AuthStatus { unknown, authenticated, unauthenticated }

final authStatusProvider = StreamProvider<AuthStatus>((ref) {
  return Supabase.instance.client.auth.onAuthStateChange.map((state) {
    return state.session != null
        ? AuthStatus.authenticated
        : AuthStatus.unauthenticated;
  });
});

final currentUserProvider = Provider<User?>((ref) {
  return Supabase.instance.client.auth.currentUser;
});

final authProvider = Provider<AuthProvider>((ref) => AuthProvider(ref));

class AuthProvider {
  final Ref _ref;
  AuthProvider(this._ref);

  Future<void> signIn(String email, String password) async {
    final response = await Supabase.instance.client.auth.signInWithPassword(
      email: email,
      password: password,
    );
    if (response.error != null) throw Exception(response.error!.message);
  }

  Future<void> signUp(String email, String password) async {
    final response = await Supabase.instance.client.auth.signUp(
      email: email,
      password: password,
    );
    if (response.error != null) throw Exception(response.error!.message);
  }

  Future<void> signOut() async {
    await Supabase.instance.client.auth.signOut();
  }
}
```

### Auth Gate (Router Integration)

```dart
// lib/core/auth/auth_gate.dart
class AuthGate extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authStatus = ref.watch(authStatusProvider);
    final onboarded = ref.watch(onboardedProvider);

    return authStatus.when(
      data: (status) {
        if (status == AuthStatus.unauthenticated) {
          return const SignInScreen();
        }
        if (!onboarded) {
          return const OnboardingScreen();
        }
        return const MainShell();
      },
      loading: () => const SplashScreen(),
      error: (_, _) => const SignInScreen(),
    );
  }
}
```

### Couple Linking

```dart
// lib/features/couple/providers/couple_provider.dart
final coupleProvider = FutureProvider<CoupleData?>((ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return null;

  final response = await Supabase.instance.client
    .from('couples')
    .select()
    .or('partner_a_id.eq.${user.id},partner_b_id.eq.${user.id}')
    .single();

  return response != null ? CoupleData.fromJson(response) : null;
});

class CoupleService {
  Future<String> createInviteCode() async {
    final code = _generateCode();
    final user = Supabase.instance.client.auth.currentUser!;
    final expiresAt = DateTime.now().add(const Duration(hours: 24));

    await Supabase.instance.client.from('couples').insert({
      'invite_code': code,
      'code_expires_at': expiresAt.toIso8601String(),
      'partner_a_id': user.id,
    });

    return code;
  }

  Future<void> joinWithCode(String code) async {
    final user = Supabase.instance.client.auth.currentUser!;
    final couple = await Supabase.instance.client
      .from('couples')
      .select()
      .eq('invite_code', code)
      .gt('code_expires_at', DateTime.now().toIso8601String())
      .is_('partner_b_id', null)
      .single();

    if (couple == null) throw Exception('Invalid or expired code');

    await Supabase.instance.client
      .from('couples')
      .update({
        'partner_b_id': user.id,
        'linked_at': DateTime.now().toIso8601String(),
      })
      .eq('id', couple['id']);
  }
}
```

### Sync Engine (Core)

```dart
// lib/core/sync/sync_service.dart
class SyncService {
  final AppDatabase _db;
  final SupabaseClient _supabase;

  SyncService(this._db, this._supabase);

  /// Push: send local unsynced changes to Supabase
  Future<SyncResult> push() async {
    final coupleId = await _db.syncMetadataDao.get('couple_id');
    if (coupleId == null) return SyncResult.noCouple;

    await _pushTable(_db.memories, coupleId);
    await _pushTable(_db.milestones, coupleId);
    await _pushTable(_db.reflections, coupleId);
    await _pushTable(_db.questionAnswers, coupleId);
    await _pushTags(coupleId);

    return SyncResult.success;
  }

  /// Pull: fetch remote changes newer than last pull
  Future<SyncResult> pull() async {
    final coupleId = await _db.syncMetadataDao.get('couple_id');
    if (coupleId == null) return SyncResult.noCouple;

    final lastPull = await _db.syncMetadataDao.get('last_pull_at');
    final since = lastPull != null ? DateTime.parse(lastPull) : DateTime(2000);

    await _pullTable('memories', _db.memories, coupleId, since);
    await _pullTable('milestones', _db.milestones, coupleId, since);
    await _pullTable('reflections', _db.reflections, coupleId, since);
    await _pullTable('question_answers', _db.questionAnswers, coupleId, since);
    await _pullTags(coupleId, since);

    await _db.syncMetadataDao.set('last_pull_at', DateTime.now().toUtc().toIso8601String());
    return SyncResult.success;
  }

  Future<void> _pushTable(TableInfo table, String coupleId) async {
    final unsynced = await (_db.select(table)..where((t) => t.isSynced.equals(false))).get();
    for (final row in unsynced) {
      // Convert to JSON, upsert to Supabase
      // On success: mark isSynced = true locally
    }
  }

  Future<void> _pullTable(String remoteTable, TableInfo table, String coupleId, DateTime since) async {
    final response = await _supabase
      .from(remoteTable)
      .select()
      .eq('couple_id', coupleId)
      .gte('updated_at', since.toIso8601String());

    for (final row in response) {
      // Upsert into local DB
      // If local updatedAt > remote updatedAt, skip (local wins on conflict)
      // If remote is_deleted, soft-delete locally
    }
  }
}
```

### Conflict Resolution Policy

**Last-write-wins with local preference:**

```
On push: Local changes always overwrite remote (remote is the sync target).
On pull: Compare updatedAt timestamps.
  - Remote row is newer: accept remote version (overwrite local).
  - Local row is newer: keep local version (skip remote update).
  - Same timestamp: local wins (the device writing is the source of truth).
  - Row is deleted remotely: soft-delete locally (isDeleted = true).
  - Row is deleted locally and synced: remote soft-delete.
```

This means:
- If both partners edit the same entry offline and come online:
  - The first push wins.
  - The second pull sees the remote is newer and accepts it.
  - No data loss. The later editor's changes are silently overwritten.
- Acceptable trade-off for a journal app where simultaneous editing of the same entry is rare and not collaborative.

**Future enhancement:** Store conflict copies in a `conflicts` table and show a "merge" UI. Not needed for v1.

### Sync Triggers

Every DAO write method (createMemory, updateMemory, createMilestone, etc.) must set `isSynced = false` so the sync engine picks it up:

```dart
// Example pattern in memories_dao.dart
Future<int> createMemory(MemoriesCompanion entry) async {
  final id = await db.into(db.memories).insert(entry.copyWith(
    isSynced: const Value(false),
    updatedAt: Value(DateTime.now()),
  ));
  // Optional: trigger sync immediately if online
  return id;
}

Future<bool> updateMemory(MemoriesCompanion entry) async {
  return db.update(db.memories).replace(entry.copyWith(
    isSynced: const Value(false),
    updatedAt: Value(DateTime.now()),
  ));
}
```

### Sync Provider

```dart
// lib/core/sync/sync_provider.dart
final syncProvider = StateNotifierProvider<SyncNotifier, SyncState>((ref) {
  return SyncNotifier(ref);
});

class SyncNotifier extends StateNotifier<SyncState> {
  SyncNotifier(this._ref) : super(SyncState.idle);

  Future<void> triggerSync() async {
    if (state == SyncState.syncing) return;

    state = SyncState.syncing;
    try {
      final service = _ref.read(syncServiceProvider);
      await service.push();
      await service.pull();
      state = SyncState.synced(DateTime.now());
    } catch (e) {
      state = SyncState.error(e.toString());
    }
  }
}

// Connectivity watcher
final connectivitySyncProvider = Provider<void>((ref) {
  final hasConnection = ref.watch(connectivityProvider);
  if (hasConnection) {
    ref.read(syncProvider.notifier).triggerSync();
  }
});
```

### AppDatabase v3 Migration

```dart
// In app_database.dart, add to onUpgrade:
if (from < 3) {
  await m.addColumn(memories, memories.createdBy);
  await m.addColumn(memories, memories.coupleId);
  await m.addColumn(memories, memories.isDeleted);

  await m.addColumn(milestones, milestones.createdBy);
  await m.addColumn(milestones, milestones.coupleId);
  await m.addColumn(milestones, milestones.isDeleted);

  await m.addColumn(reflections, reflections.createdBy);
  await m.addColumn(reflections, reflections.coupleId);
  await m.addColumn(reflections, reflections.isDeleted);

  await m.addColumn(questionAnswers, questionAnswers.createdBy);
  await m.addColumn(questionAnswers, questionAnswers.coupleId);
  await m.addColumn(questionAnswers, questionAnswers.isDeleted);

  await m.addColumn(tags, tags.createdBy);
  await m.addColumn(tags, tags.coupleId);

  await m.createTable(syncMetadata);

  // Mark existing rows as synced (they already exist locally)
  await customStatement('UPDATE memories SET is_synced = 1');
  await customStatement('UPDATE milestones SET is_synced = 1');
  await customStatement('UPDATE reflections SET is_synced = 1');
  await customStatement('UPDATE question_answers SET is_synced = 1');
}
```

### Error Handling & Edge Cases

1. **Supabase unreachable**: Sync fails gracefully. Local writes continue. User sees "Sync paused" indicator.
2. **Auth token expired**: Supabase SDK handles auto-refresh via refresh token. If refresh fails, user is signed out and sees sign in screen.
3. **Duplicate local IDs**: Since Drift uses autoIncrement locally, local IDs may clash between devices. Solution: use composite keys or UUIDs. **Recommendation:** Keep local integer autoIncrement IDs for local queries. Add a `remote_id` UUID column for Supabase lookups. The sync engine maps local IDs to remote IDs via a lookup table or by using the same autoincrement value (since each couple gets their own partition, IDs won't clash).
4. **Large initial sync**: First sync after couple linking pulls all existing entries. Show a progress indicator. For v1, this is fast (< 1s for typical journal size).
5. **Database locked**: Drift handles concurrent access. Sync runs on a single isolate.
6. **App killed during sync**: Incomplete sync. Next sync push picks up unsynced rows. No data corruption.
7. **Both partners sign up independently then try to link**: Invite code flow handles this. One generates code, other enters it.
8. **Partner's account deleted**: Supabase cascade deletes their profile. Couple row gets `partner_b_id = null`. Other partner sees "Partner disconnected" state.

### Security (Row Level Security)

Every Supabase table needs RLS policies:

```sql
-- Profiles: users can read/write only their own profile
create policy "Users can read own profile"
  on profiles for select using (auth.uid() = id);

create policy "Users can update own profile"
  on profiles for update using (auth.uid() = id);

-- Couples: read/write for members of the couple
create policy "Couple members can read couple"
  on couples for select using (
    auth.uid() = partner_a_id or auth.uid() = partner_b_id
  );

create policy "Couple members can update couple"
  on couples for update using (
    auth.uid() = partner_a_id or auth.uid() = partner_b_id
  );

-- Memories: couple members can read/write couple's memories
create policy "Couple members can read memories"
  on memories for select using (
    couple_id in (
      select id from couples
      where partner_a_id = auth.uid() or partner_b_id = auth.uid()
    )
  );

create policy "Couple members can insert memories"
  on memories for insert with check (
    couple_id in (
      select id from couples
      where partner_a_id = auth.uid() or partner_b_id = auth.uid()
    )
  );

create policy "Couple members can update memories"
  on memories for update using (
    couple_id in (
      select id from couples
      where partner_a_id = auth.uid() or partner_b_id = auth.uid()
    )
  );

-- Repeat for milestones, reflections, question_answers, tags, tag_assignments
```

### Row Level Security: Invite Code

The invite code creation needs special handling. When user A creates a couple (no partner yet), only `partner_a_id` is set. User B needs to find the code. The RLS on `couples` for `partner_a_id` only won't help B find it. Solution:

```sql
-- Allow anyone to look up a valid invite code (only code + expiry)
create policy "Anyone can look up valid invite codes"
  on couples for select using (
    invite_code is not null
    and code_expires_at > now()
    and partner_b_id is null
  );

-- But restrict the columns returned (only code, no other data)
-- Supabase doesn't support column-level RLS natively,
-- so the app only queries invite_code and id columns
```

---

## Build Order

### Phase 1: Foundation (Build Days 1-2)

| Step | File | Description |
|------|------|-------------|
| 1.1 | `pubspec.yaml` | Add `connectivity_plus`, `uuid` dependencies. Run `flutter pub get` |
| 1.2 | `lib/core/supabase/supabase_config.dart` | Create config with URL + anon key placeholder |
| 1.3 | `lib/main.dart` | Initialize Supabase before `runApp` |
| 1.4 | Supabase Console | Create all SQL tables, enable RLS, create policies |
| 1.5 | `lib/core/database/tables/sync_metadata_table.dart` | New Drift table |
| 1.6 | `lib/core/database/app_database.dart` | Add v3 migration, register SyncMetadata table |
| 1.7 | `lib/core/database/daos/sync_metadata_dao.dart` | DAO for sync metadata |
| 1.8 | `lib/core/database/database_provider.dart` | Register sync metadata DAO |
| 1.9 | Run `dart run build_runner build` | Regenerate drift files |

### Phase 2: Auth (Build Days 2-3)

| Step | File | Description |
|------|------|-------------|
| 2.1 | `lib/core/auth/auth_provider.dart` | Auth state stream, sign in/out/up methods |
| 2.2 | `lib/core/auth/auth_gate.dart` | Widget that redirects based on auth state |
| 2.3 | `lib/features/auth/screens/sign_in_screen.dart` | Sign in UI |
| 2.4 | `lib/features/auth/screens/sign_up_screen.dart` | Sign up UI |
| 2.5 | `lib/core/router/app_router.dart` | Add auth routes, update router to use AuthGate |
| 2.6 | `lib/app.dart` | Wire AuthGate as root of app |
| 2.7 | Test: sign up, sign in, sign out flow | Validate end-to-end |

### Phase 3: Couple Linking (Build Days 3-4)

| Step | File | Description |
|------|------|-------------|
| 3.1 | `lib/features/couple/providers/couple_provider.dart` | Couple state, invite code service |
| 3.2 | `lib/features/auth/screens/create_couple_screen.dart` | Generate and display code |
| 3.3 | `lib/features/auth/screens/join_couple_screen.dart` | Enter code (6-char input) |
| 3.4 | `lib/features/auth/screens/couple_linking_screen.dart` | Choose create or join |
| 3.5 | `lib/features/me/screens/onboarding_screen.dart` | Refactor to multi-step (name → auth → couple) |
| 3.6 | Test: full sign up + couple link flow | Validate end-to-end |

### Phase 4: Sync Engine (Build Days 4-6)

| Step | File | Description |
|------|------|-------------|
| 4.1 | `lib/core/sync/sync_service.dart` | Push/pull engine (core logic) |
| 4.2 | `lib/core/sync/sync_state.dart` | Enum: idle, syncing, synced, error |
| 4.3 | `lib/core/sync/sync_provider.dart` | StateNotifier + connectivity watcher |
| 4.4 | All DAOs (memories, milestones, etc.) | Set `isSynced = false` on writes |
| 4.5 | DAO column updates | Add `createdBy`, `coupleId`, `isDeleted` to all write companions |
| 4.6 | `lib/core/database/daos/sync_metadata_dao.dart` | Getter/setter for sync timestamps |
| 4.7 | Run `dart run build_runner build` | Regenerate drift files |
| 4.8 | Test: write offline, go online, sync | Validate sync engine |

### Phase 5: UI Integration (Build Days 6-7)

| Step | File | Description |
|------|------|-------------|
| 5.1 | `lib/core/components/sync_status_indicator.dart` | Small cloud icon in app bar |
| 5.2 | `lib/features/me/screens/me_screen.dart` | Add sync status, couple section, sign out |
| 5.3 | `lib/features/couple/screens/couple_settings_screen.dart` | Couple info, unlink, regenerate code |
| 5.4 | `lib/features/story/providers/timeline_provider.dart` | Include partner entries |
| 5.5 | `lib/features/story/models/timeline_entry.dart` | Add `createdBy` info to entries |
| 5.6 | Timeline card rendering | Show partner name on entries they wrote |
| 5.7 | Test: full integration test | Validate everything works together |

### Phase 6: Polish & Edge Cases (Build Day 7-8)

| Step | Description |
|------|-------------|
| 6.1 | Add RLS policies to Supabase console |
| 6.2 | Handle token refresh errors gracefully |
| 6.3 | Handle account deletion cascade |
| 6.4 | Handle couple unlinking (confirm dialog, local data preserved) |
| 6.5 | Handle invite code expiry with clear message |
| 6.6 | Add loading states to all auth screens |
| 6.7 | Run `flutter analyze` and fix all issues |
| 6.8 | Run `flutter test` and add sync unit tests |
| 6.9 | Build release APK |

---

## Risk Register

| Risk | Likelihood | Impact | Mitigation |
|------|-----------|--------|------------|
| John doesn't have the Supabase anon key | High | Blocking | He may need to create a new anon key in Supabase dashboard under Settings > API. If the service_role key is all he has, generate a new anon key from the dashboard. |
| Local autoincrement IDs conflict between devices | Medium | Medium | Use a composite key strategy or remote_id UUID. Since each couple's data is in a separate partition, SQLite autoIncrement values are unlikely to clash (user A has IDs 1-50, user B has IDs 1-30). The Supabase IDs are independent of local IDs. Sync mapping uses local ID to look up and upsert by matching date + content. |
| Large data sets slow initial sync | Low | Low | Journal data is text + small dates. Even 1000 entries sync in < 1 second. |
| Partner links wrong account | Low | High | Unlinking + re-linking flow. Also, invite code expires after 24h and can only be used once. |
| Supabase free tier limits | Medium | Low | 50,000 rows per table, 2 GB database. Sufficient for millions of text entries. Monitor usage. |

---

## Open Questions for John

1. **Anon key:** Do you have the Supabase anon key? It's different from the service_role key. You can find it in the Supabase dashboard under Settings > API > Project API keys > anon/public.
2. **Email auth vs. magic link:** Is email + password fine, or would you prefer magic link (passwordless, email only)?
3. **Supabase hosted region:** Any preference on where the database is hosted (default is usually fine)?
4. **Testing devices:** Do you have two Android devices or an emulator to test the couple linking flow?
5. **Invite code UX:** Single-use code (new one each time) or re-usable until used? I recommend single-use with 24h expiry.
