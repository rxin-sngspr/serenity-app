# Serenity — Product Guide

> **Owner:** Product team
> **Purpose:** This is the single source of truth for what Serenity is, what it isn't, and why it exists. Every feature decision traces back here.
> **Status:** Execution Phase — Phase 5 Connected Alpha
> **Related:** [Roadmap](ROADMAP.md) | [Changelog](CHANGELOG.md) | [Architecture](ARCHITECTURE.md)

---

## Vision

Serenity is a private digital home for your relationship story.

Most relationship tools are about tracking — what you did, how often you did it, whether you're doing enough. Serenity is the opposite. It's a quiet space where couples can remember, reflect, appreciate, and understand each other without performance pressure.

It's not a habit tracker. Not a couples therapist. Not a social network. Just a shared journal that respects your privacy and works whether you have internet or not.

---

## Positioning

Serenity sits in a space most apps ignore:

- **Privacy-first, local-first.** Your memories live on your phone. Sync is a transparent bridge to your partner's device, not a cloud dependency.
- **No gamification.** No streaks, no stats, no scores. The value comes from writing and reading, not from numbers.
- **For couples who reflect.** Not for new couples tracking milestones (though it works for that). For any relationship stage where depth matters more than volume.
- **Your own private space.** There is no feed, no likes, no comments. Just you, your partner, and your shared story.

---

## The Four Pillars

### Remember

> Capture and preserve your shared moments.

Memories are the heart of Serenity. A memory can be anything — a date night, a conversation, a quiet morning. Each memory gets a date, a title, a story, and optional tags. Memories appear on your timeline in reverse chronological order.

The timeline is not a feed. There is no algorithm. Every memory stays where you put it.

### Reflect

> Understand your relationship patterns over time.

Reflection comes in two forms:

**Daily Questions** — Each day, Serenity presents a question for both partners to answer independently. Questions span categories like appreciation, growth, dreams, and challenges. Partners can see each other's answers or keep them private. There is no right answer.

**Timed Reflections** — Periodic prompts (daily, weekly) invite deeper writing. These are private to each partner. They help you notice patterns you might miss in day-to-day life.

### Appreciate

> Notice and name what you're grateful for.

Gratitude is a practice, not a metric. Appreciation entries are lightweight — a sentence, a moment, a small thing your partner did. They accumulate over time and become a record of what matters most.

### Understand

> See the shape of your shared story.

Milestones mark significant dates. The calendar shows when things happened. Trends emerge naturally as you write more. Understanding comes from looking back, not from dashboards or charts.

---

## Emotional Design Principles

These principles guide every visual and interaction decision:

1. **Warmth over precision.** Serenity should feel like a cozy room, not a spreadsheet. Corners are rounded. Colors are soft. Typography is human.

2. **Dark mode first.** The app is designed for quiet moments — late nights, early mornings, rainy afternoons. Dark mode is the primary experience.

3. **Subtlety over notification.** Serenity does not push. There are no badges, no reminders, no "you haven't written in 3 days" messages. The app waits for you.

4. **Intimacy over broadcasting.** Content is shared only between partners. There is no sharing to social media, no public profiles, no "streak" to post.

5. **Simplicity over features.** Every feature must justify its existence against the four pillars. If it doesn't serve Remember, Reflect, Appreciate, or Understand, it doesn't belong.

---

## What Serenity Is NOT

| Not this | Because |
|----------|---------|
| A habit tracker | We don't measure frequency or set goals |
| A therapy app | We don't diagnose, treat, or intervene |
| A social network | There is no feed, no likes, no comments |
| A gamified app | No streaks, badges, scores, or leaderboards |
| A photo album | Photos are optional, not primary |
| A wedding planner | Milestones include all relationship stages |
| A shared calendar | The timeline is retrospective, not planning |
| A cloud service | The cloud exists to support the relationship, not to replace local ownership |

---

## Data Philosophy

Serenity distinguishes between shared and personal data. This boundary is intentional and enforced at the architecture level.

### Shared (synchronizes automatically)

- Memories
- Milestones
- Appreciations
- Couple information
- Shared daily questions
- Relationship timeline

### Personal (remains local unless intentionally designed otherwise)

- Reflections (private journaling)
- Device settings
- Theme preference
- Security preferences
- App lock
- Local preferences

Shared content belongs to the couple. Personal content belongs to the individual. Sync only touches shared data.

---

## Hero Feature

**Your shared story, synced invisibly.**

Two phones. One relationship story. Partner A writes a memory. Partner B sees it on their timeline. No "share" button. No cloud icon. It just appears.

This is the magic of Serenity. The sync engine works quietly in the background. You never have to think about it. When you're offline, you write. When you reconnect, your words find their way to your partner.

---

## Navigation

Serenity has three main tabs:

| Tab | Pillar | Primary Action |
|-----|--------|----------------|
| **Story** | Remember | Browse timeline, view calendar, create memory/milestone |
| **Reflect** | Reflect + Appreciate | Daily question, timed reflections, view history |
| **Me** | Understand | Profile, themes, settings, sync status, couple management |

All major creation flows (memory, milestone, reflection) open as full-screen modal pages with slide-up transitions.

---

## MVP Scope

The MVP is one working couple sharing memories. Specifically:

- Email + password authentication
- Couple linking via 6-character invite code
- Create and view memories (text only, no media)
- Create and view milestones
- Daily question with answer
- Timeline shows both partners' content
- Background sync when online
- 5 themes with dark mode
- Tag system (preset + custom)

The MVP intentionally excludes:

- Photo/video upload
- Real-time sync (REST polling is sufficient)
- Multi-device for a single user
- Collaborative editing
- Offline queue UI

See [ROADMAP.md](ROADMAP.md) for the full milestone plan.

---

## Current Priority: Connected Alpha

**No new features until Connected Alpha passes.**

The only milestone that matters is producing a working build where two real users can install the app, sign up, link as a couple, and share memories. See [ROADMAP.md](ROADMAP.md) Phase 5 for the full definition of done.

---

## Future Directions (Post-Alpha)

After Connected Alpha validation, potential directions include:

- **Rich media** — optional photo attachments for memories
- **Advanced reflections** — guided journaling prompts, weekly digests
- **Export** — download your relationship story as a document
- **Private appreciations** — scheduled gratitude prompts with optional partner sharing
- **Partner profile photos** — visual identity within the app
- **Anniversary enhancements** — custom milestone celebrations

These are not commitments. Each is evaluated against the four pillars and the product philosophy before implementation.

---

## Product Philosophy

1. **Privacy is not a feature, it's the foundation.** Serenity stores data on your device. Cloud sync exists only to bridge two devices. No third parties ever read your content.

2. **No empty states.** If there's nothing to show, the app should feel peaceful, not empty. A blank timeline should feel like a fresh notebook, not a void.

3. **Every interaction must earn its place.** If a button, animation, or screen doesn't serve the four pillars, remove it.

4. **The app should age well.** Avoid trends. Avoid UI fads. Serenity in 5 years should feel the same as Serenity today.

5. **The couples are the users.** Product decisions are made for the couple, not for one partner. Features that benefit one at the expense of the other are carefully scrutinized.

6. **Local-first, always.** Local storage provides speed. Sync provides continuity. Supabase enables shared experiences. Offline capability provides resilience.

---

## Product Principles

These principles define what Serenity should always feel like — and what it should never become.

### What Serenity Always Is

| Feeling | Meaning |
|---------|---------|
| **Private** | Your relationship story belongs to you and your partner. No third parties. No analytics. No data mining. |
| **Warm** | The app feels like a cozy room — soft colors, rounded corners, human typography. Not a dashboard. |
| **Calm** | No notifications, no badges, no alerts. Serenity waits for you. It never demands attention. |
| **Timeless** | Designed for longevity, not trends. The app should feel the same in 5 years. Avoid UI fads, seasonal redesigns, and "what's hot" patterns. |
| **Intentional** | Every pixel earns its place. If it doesn't serve Remember, Reflect, Appreciate, or Understand, it doesn't belong. |
| **Gentle** | No judgment. No "you haven't written in 3 days." No performance pressure. The app is a space, not a taskmaster. |

### What Serenity Never Becomes

| Never | Because |
|-------|---------|
| **Gamified** | No streaks, points, badges, levels, or leaderboards. Relationship depth cannot be measured in numbers. |
| **Social** | No feed, no likes, no comments, no sharing to other platforms. Intimacy is the opposite of broadcasting. |
| **Productivity-focused** | Not a tool to "optimize your relationship." No goals, no tasks, no completion rates. |
| **Addictive** | No infinite scroll, no pull-to-refresh, no "you might also like." Serenity is not competing for your attention. |
| **Clinical** | No therapy claims, no diagnoses, no interventions. We are not healthcare. We are a journal. |
| **Surveilled** | No tracking pixels, no behavioral analytics, no ad targeting. Privacy is not optional. |

### How Principles Guide Decisions

When evaluating any feature, ask:

1. Does this make the app feel less private? → Reject or redesign
2. Does this add noise or urgency? → Reject or minimize
3. Does this optimize for time spent instead of value received? → Reject
4. Would this feel dated in 3 years? → Reject or simplify
5. Does this pressure users to "do more"? → Reject

---

## Definition of Success

Serenity does not measure success by engagement metrics. Success is defined by **relationship value**.

### Primary Metrics (What Matters)

- **Couples actively sharing** — A couple that has written at least one entry in the last week
- **Sync reliability** — Entries appear on the partner's device within expected timeframes
- **Offline resilience** — No data loss when writing offline, regardless of how long between connections
- **Partner satisfaction** — Both partners feel the app serves their relationship, not that one person is "doing the work"

### Secondary Metrics (Leading Indicators)

- **Return rate after first week** — Does the couple come back?
- **Feature adoption** — Are couples using memories, milestones, and reflections, or just one?
- **Unlink rate** — How often do couples unlink? Is there a pattern?

### Anti-Metrics (What We Never Optimize For)

| Metric | Why We Ignore It |
|--------|-----------------|
| Daily active users (DAU) | Incentivizes addictive patterns. We want quality, not frequency. |
| Time spent in app | A user writing one thoughtful memory in 5 minutes has more value than 30 minutes of scrolling. |
| Total entries created | More is not better. A single meaningful entry is worth more than 100 empty ones. |
| Streak length | Streaks create pressure and guilt. Neither belongs in a relationship journal. |
| Notification open rate | We don't send notifications. We never will. |
| Share rate | Content is private by design. Sharing undermines the product. |

### How Success Feels

A successful Serenity installation looks like this:

- A couple opens the app a few times a week
- They write when they have something to capture or reflect on
- They see their partner's entries appear naturally
- They never think about sync, cloud, or data management
- They would notice if the app disappeared, because it holds a piece of their story

That is success. Not retention curves. Not growth loops. Not monetization.

---

## Feature Review Process

Every feature must pass this five-gate review before implementation:

### 1. Purpose
Why does this feature exist? Which pillar does it serve (Remember, Reflect, Appreciate, Understand)? If none, reject it.

### 2. Alternatives
Present 2-3 approaches with trade-offs. Recommend one.

### 3. MVP Cut
Reduce complexity aggressively. Prefer the smallest implementation that preserves the emotional experience.

### 4. Design Review
Confirm the feature matches Serenity's identity. No gamification. No streaks. No stats. No social feed. Warm. Intentional. Private. Calm.

### 5. Engineering Review
Verify maintainability, simplicity, scalability, documentation impact, and long-term cost before writing code.

---

## Design System Philosophy

Serenity uses a custom design system built on three ideas:

1. **Calm hierarchy.** Big titles. Generous whitespace. Nothing screams for attention.
2. **Consistent but not rigid.** Components share patterns but adapt to content. A memory card and a milestone card look related but distinct.
3. **Dark-first palette.** Warm, muted backgrounds. Low contrast. Colors chosen for emotional tone, not accessibility minimums (though we respect accessibility).

The design system is detailed in [ARCHITECTURE.md](ARCHITECTURE.md#design-system).
