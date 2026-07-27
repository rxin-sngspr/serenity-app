# Serenity — Future Ideas

> **Owner:** Product team
> **Purpose:** Parking lot for ideas that are not part of the current milestone. These are captured so they don't distract from execution but aren't lost either.
> **Status:** 🗄️ Parked — revisit after Connected Alpha passes
> **Related:** [Product Guide](PRODUCT.md) | [Roadmap](ROADMAP.md)

---

## How This Works

Ideas live here until they pass the [Feature Review Process](PRODUCT.md#feature-review-process). At that point they graduate to a roadmap milestone.

No idea here is committed. Some will never be built. That's fine.

---

## Rich Media

**Idea:** Optional photo attachments for memories.

**Why parked:** Increases scope significantly (image picker, storage, compression, sync of binary data, Supabase Storage integration). Text-only MVP is sufficient for validation.

**Open questions:**
- Where are photos stored? (Supabase Storage, device only, or both?)
- How does sync handle large images?
- Do we compress? What resolution?
- Does this change the privacy model?

---

## Advanced Reflections

**Idea:** Guided journaling prompts, weekly digests, timed reflection schedules.

**Why parked:** Reflections work and are personal-only (no sync). Adding structure before Connected Alpha risks scope creep.

**Open questions:**
- Should reflections become syncable (partner can see if you reflected, but not content)?
- Weekly email/notification digests violate the "no notifications" principle — would need to be optional and minimal.

---

## Export

**Idea:** Download your relationship story as a document (PDF, Markdown, or JSON).

**Why parked:** Pure polish feature. No validation value.

---

## Private Appreciations

**Idea:** Scheduled gratitude prompts with optional partner sharing.

**Why parked:** Appreciation is thin in the current MVP. Let's see how users use it before building more.

---

## Partner Profile Photos

**Idea:** Visual identity within the app (avatar, profile photo).

**Why parked:** Pure UI polish. No sync validation value.

---

## Anniversary Enhancements

**Idea:** Custom milestone celebrations, anniversary countdown, "On This Day" memories.

**Why parked:** Delight features. Should be informed by real user behavior.

---

## Calendar Enhancements

**Idea:** Heatmap, richer month view, week view, integration with timeline.

**Why parked:** Calendar works. Let's see what users actually want from it.

---

## "On This Day"

**Idea:** Show memories from this day in previous years.

**Why parked:** Classic app feature that creates delight. But it requires data accumulation — useless at launch. Revisit when couples have been using the app for 6+ months.

---

## Time Capsule

**Idea:** Lock a memory to open on a future date. Like a letter to your future selves.

**Why parked:** Novel feature but adds encryption, scheduling, and notification complexity. Pure delight, no validation value.

---

## AI Features

**Idea:** AI-generated relationship summaries, writing prompts based on past entries, sentiment trends.

**Why parked:** AI is expensive, unpredictable, and privacy-sensitive. Serenity's privacy-first model makes cloud AI difficult. On-device AI (ML Kit, local LLMs) could work but adds significant complexity.

**Open questions:**
- Can we do this on-device only?
- Do users want AI analyzing their relationship?
- What's the privacy model for prompts and responses?

---

## Widgets

**Idea:** Home screen widgets (iOS + Android) showing timeline preview, daily question, or partner's recent entry.

**Why parked:** Platform-specific development. Requires data sharing with widget extension. Pure delight.

---

## On This Day Notifications

**Idea:** A gentle daily notification: "On this day X years ago, you wrote about..."

**Why parked:** Violates "no notifications" principle. If implemented, must be opt-in with zero defaults.

---

## Multi-Device Sync

**Idea:** Same user, multiple devices (phone + tablet). Not currently supported.

**Why parked:** One user = one device for MVP. Adds ID conflict complexity.

---

## Collaborative Editing

**Idea:** Both partners editing the same memory simultaneously (like Google Docs).

**Why parked:** CRDT complexity. Not in scope for a journal app.

---

## Real-Time Sync

**Idea:** Switch from REST polling to WebSocket-based real-time sync (Supabase Realtime).

**Why parked:** REST polling is sufficient for MVP. Real-time adds cost and complexity. Revisit if sync latency becomes a user complaint.

---

## Image/Media Sync

**Idea:** Sync photos attached to memories between devices.

**Why parked:** Binary data sync is significantly more complex than text. Requires Supabase Storage, compression, progress indicators, and bandwidth awareness. Post-MVP.

---

## Gamification (Anti-Idea)

**Idea:** Add streaks, badges, leaderboards, or "relationship scores."

**Status:** ❌ Permanently rejected. See [Product Principles](PRODUCT.md#product-principles). Serenity never gamifies relationships.

---

## Social Features (Anti-Idea)

**Idea:** Share memories to Instagram, "like" partner's entries, public profiles.

**Status:** ❌ Permanently rejected. Serenity is a private space. Broadcasting undermines intimacy.
