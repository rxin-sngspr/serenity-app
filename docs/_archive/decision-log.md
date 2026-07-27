# Decision Log

## Purpose
Every architecture call, dependency choice, or trade-off gets logged here. Future us needs to know why things are the way they are.

---

### Entry 1: TagsDao + colored pills (Phase A1)

**Date:** 2026-06-29
**Context:** Phase 1 schema migration deleted `MemoryTags` table and replaced with `Tags` + `TagAssignments` tables. Three files broke (timeline_dao.dart, create_memory_screen.dart, memory_detail_screen.dart).

**Decision:** Minimal TagsDao fix + colored pill rendering. Created TagsDao, updated type chain to pass `List<Tag>` instead of `List<String>`, rendered tag pills using `tag.color` hex with fallback.

**Trade-offs:**
+ Compilation restored, colored tags visible on timeline and memory detail
- Tag creation is still text-input only (no preset picker)
- No tag editing or management screen

### Entry 2: NDK r28 / CMake 3.22.1 incompatibility

**Date:** 2026-06-29
**Context:** Release APK build failed at CMake configure step. NDK r28 (28.2.13676358) requires CMake 3.28+, but Android SDK had CMake 3.22.1 installed. Plugins (app_links, device_info_plus, etc.) depend on NDK.

**Decision:** Install CMake 3.31.4 via Android SDK Manager. Reverted ndkVersion from pinned "25.0.8775105" back to `flutter.ndkVersion` (defaults to NDK r28). Build succeeded after CMake upgrade.

**Trade-offs:**
+ Minimal change (3.31.4 compatible with NDK r28)
+ No project config changes needed (Gradle auto-discovers newer CMake)
- CMake is a build-time dependency only, no runtime impact
- Not all team members may have the newer CMake (need to run sdkmanager)
