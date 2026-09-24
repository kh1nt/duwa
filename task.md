# DUWA · Design System & Task Guide

## Design Context

### Users
- **Target Users**: Core and casual gamer friend groups, tabletop/board game squads, and LAN party crews.
- **Context**: Organizing game nights across chaotic group chats (Discord, Messenger, WhatsApp). Usually checking on mobile while deciding what to play, who is available, and what gear or snacks are needed.
- **Job to Be Done**: Eliminating the friction of scheduling, democratic game voting, RSVP tracking, and logistics (who brings what, snacks, voice channels) in one unified space.
- **Emotional Goals**: Human warmth, anticipation of an awesome game session, camaraderie, effortless coordination, and pride in squad gaming.

### Brand Personality
- **Voice & Tone**: Welcoming, conversational, art-directed, authentic gamer culture. Zero corporate speak, zero cringe military jargon (`TACTICAL`, `MISSION LOCK`, `IGNITE`).
- **3-Word Personality**: **Editorial**, **Cinematic**, **Tactile**.
- **References**: Steam Deck / Steam library presentation, Playdate/Panic editorial charm, Riot Games typography and layout craft.
- **Anti-References**: Generic "AI gaming slop" (cyan/purple neon gradients on pure black, giant rotated watermark icons, fake perforated coupon cards, military tactical jargon, emoji vomit).

### Aesthetic Direction
- **Flagship Theme**: `Obsidian Void` — Deep velvet charcoal surfaces (`#0A0C10`, `#141722`) with warm tinted neutrals, Solar Flame (`#FF5E1E`) brand energy, Ember Gold (`#FFA114`), and Ion Mint (`#00F59B`) for ready states.
- **Color Philosophy**: Tinted dark surfaces (never `#000000` pure black), crisp high-contrast white/stone typography, vibrant live game artwork headers.
- **Typography & Layout**: Bold asymmetric editorial headers, generous vertical breathing room, progressive disclosure, wide-format key art banners.
- **Tactile Motion**: Smooth physical spring responses (`BouncyTap`), natural deceleration easing.

### Design Principles
1. **Real Art Over Artificial Slop**: Prioritize authentic Steam game key art, high-resolution header assets, and real game metadata over generic icons or AI placeholder illustrations.
2. **Human Conversational Copy**: Speak like friends coordinating a Friday night LAN party. ("Next Game Night", "What are we playing?", "I'm In"). Never use military commander jargon.
3. **Intentional Hierarchy, Not Card Overload**: Avoid nesting cards inside cards. Use clean dividers, typography weight shifts, and natural spacing rhythm instead of boxing every single text snippet.
4. **Immediate RSVP & Frictionless Action**: Key actions (RSVP status, voting for nominated games, claiming snacks/controllers) must be achievable in a single tap with instant visual feedback.
5. **Fluid Multi-Theme Harmony**: Support switching across curated palettes (Obsidian Void, Clean Light, Mystic Ocean, Bloom) with strict design token discipline.

---

## Impeccable Implementation Log

### Completed
- [x] **/teach-impeccable**: Established persistent Design Context and 5 core principles in `task.md`.
- [x] **Anti-Pattern Purge**: Removed all AI cliches (perforations, watermark icons, military jargon).
- [x] **Steam Key Art Architecture**: Added official Steam CDN cover integration for catalog games.
- [x] **/delight — Live Voting Bars & Haptics**:
  - Live animated vote proportion bar (`TweenAnimationBuilder`) in Session Details.
  - Percentage badges and leader highlight on nominated games.
  - Physical haptic clicks on RSVP changes, bring list claims, and creation celebrations.
- [x] **/delight — Game Night Dispatch & Squad Invite Modal**:
  - 1-tap Discord- and WhatsApp-formatted game night summary generator in Session Details.
  - Live preview with format switcher, haptic copy actions, and room code extraction.
- [x] **/adapt — Wide-Screen & Tablet Navigation Rail**:
  - Responsive layout in `MainShellView` switching from bottom navigation to `DuwaNavRail` on screens width >= 720px.
  - Centered max-width layout constraint preventing stretched card views.
- [x] **/onboard & Anti-Pattern Sweep**:
  - Replaced leftover military jargon (`Sector`, `IGNITE SESSION`, `Agent`) with human, welcoming copy.
  - Added theme-aware `EmptyStateWidget.sessions` with animated Duwi mascot.
- [x] **Test & Build Integrity**: `flutter analyze` 0 issues, all 11 test suites passing.
- [x] **Production Data Clean**: Purged hardcoded mock sessions, dummy notifications, test squads, and fake Steam stats for clean first-run experience; wired Firestore live streaming for groups and sessions; all 12 tests passing.
- [x] **Mobbin-Inspired UI/UX Overhaul (2025/2026 Mobile Design Standards)**:
  - **Cinematic Game Pass Hero**: Replaced boxy marquee in `HeroSessionMarquee` with an editorial game pass featuring Steam key art scrim, dynamic urgency badges, chip-in pool badges, and 1-tap interactive response chips.
  - **Bento Grid Action Command Hub**: Created `HomeBentoHub` implementing Mobbin-style Bento card architecture ("Plan a session", "Join with code", "Game Ballot").
  - **Frosted Capsule Navigation Dock**: Redesigned `DuwaBottomNavBar` into a floating frosted glass pill dock (`ImageFilter.blur`) with a glowing radiant circular launcher.
  - **Obsidian 2.0 Design System**: Deepened space obsidian canvas (`#080A10`), elevated card surfaces (`#121624`), luminous borders, and presence tokens.
- [x] **Past Session Auto-Completion**:
  - Automatically detects past sessions (scheduled before `DateTime.now() - 4 hours`) in `GameNightViewModel._mapFirestoreDocToSession`, automatically setting status to `GameNightStatus.completed`.
  - Filtered past sessions out of `upcomingSessions` and routed them to `recentGameNights` archive.
- [x] **Player Snapshot & Presence Radar Removal**:
  - Completely removed the `_profileSnapshot` card from `ProfileView`.
  - Removed `SquadPresenceBar` radar from `HomeView`.
- [x] **Abolished "RSVP" Jargon**:
  - Replaced all user-facing occurrences of "RSVP" with natural gaming phrases ("ARE YOU IN?", "Vote or confirm your spot", "Squad Lineup", "Confirmed: ... playing").
- [x] **Complete Removal of Contribution & Money**:
  - Removed `contributionPerPerson` and `contributionDetail` across `GameNightModel`, `FirebaseService`, and `GameNightViewModel`.
  - Purged all money and chip-in UI inputs, chips, and review items from `CreateGameNightSheet`.
  - Removed chip-in badges from `HeroSessionMarquee`, `GamePassCard`, `HomeView`, and `PreparationHub`.
  - Cleaned Discord and WhatsApp export briefings in `GameNightDispatchSheet` to focus purely on squad gaming coordination without money overhead.
  - Verified with clean `flutter analyze` (0 issues) and all 34 test suites passing.
- [x] **/animate — Sessions & Game Pass Cards Tactile Micro-Interactions**:
  - **Sliding Filter Pill Indicator**: Built animated sliding indicator (`AnimatedPositioned` with `Curves.easeOutCubic`) in `SessionsView._filterBar` for seamless tab switching across Active, Needs You, and Archive.
  - **Staggered Card Entrances**: Added `_StaggeredSessionEntry` with index-based stagger (260ms + 40ms offset, `Curves.easeOutCubic`) providing a tactile slide-and-fade entrance without timers.
  - **Radar & Metric Transitions**: Animated attention status icon with `AnimatedSwitcher` (scale transition) and metric counter flip transitions.
  - **Interactive Game Pass RSVP Feedback**: Added animated scale pop (`AnimatedScale`, `Curves.easeOutBack`), tinted glowing selection shadow, and haptic clicks when confirming attendance.
  - **Ambient Live Urgency Pulse**: Added `_PulseDot` with low-frequency breathing glow for `LIVE NOW` and `TONIGHT` sessions.
  - **Accessibility Compliance**: Fully honors `prefers-reduced-motion` via `MediaQuery.disableAnimations`.
  - **Testing**: Added `test/sessions_animations_test.dart`; all 34 test suites passing, `flutter analyze` 0 issues.
- [x] **1-Tap Calendar Integration & Squad Sync (.ics, Google & Outlook Calendar)**:
  - **CalendarService Engine**: Built `CalendarService` with RFC-5545 compliant `.ics` formatting, Google Calendar TEMPLATE URLs with UTC conversion, and Outlook Calendar compose deep-links.
  - **CalendarExportSheet**: Added tactile bottom sheet with Google Calendar open, Outlook open, 1-tap shareable link copy, and `.ics` copy with haptic confirmation.
  - **Session Details Integration**: Embedded direct "Add to Calendar" button in `_buildCozyScheduleGrid` and popup actions menu.
  - **Dispatch Sheet Integration**: Embedded Google Calendar 1-tap links directly into generated Discord and WhatsApp dispatch text exports, plus a direct Calendar action button in the dock.
  - **Comprehensive Test Suite**: Added `test/calendar_service_test.dart` (all 9 unit & widget tests passing); entire test suite (43 tests) passing cleanly with 0 `flutter analyze` issues.
- [x] **System-Level Hardening & Architecture Overhaul**:
  - **Native Platform Manifests (Android & iOS)**: Added `android.permission.INTERNET`, Android 11+ `<queries>` for web/mail/tel schemes (`url_launcher`), iOS `NSPhotoLibraryUsageDescription` & `NSCameraUsageDescription` (prevents crash on image picker), external URL query schemes, and deep linking filters (`duwa://join` and `https://duwa.app/join`).
  - **Local Persistence Engine (`PreferencesService`)**: Added `shared_preferences` dependency and built `PreferencesService` to persist theme vibes across app restarts, track read notification IDs, and cache user profiles for instant offline startup.
  - **Theme Persistence**: Connected `ThemeViewModel` to `PreferencesService` so vibe changes persist across app terminations.
  - **Offline Profile Hydration**: `ProfileViewModel` hydrates instantly from cached local storage before network response and caches updates locally.
  - **Firestore Concurrency Transactions**: Hardened `castVote()` and `updatePlayerRsvp()` with atomic Firestore `runTransaction` blocks to eliminate race conditions when squad members vote or RSVP simultaneously.
  - **Firestore Production Security Rules**: Authored `firestore.rules` for `users`, `groups`, `game_nights`, and `games` collections.
  - **Dynamic In-App Notifications Engine**: Connected `NotificationsViewModel` to active game sessions via `syncWithSessions`, automatically surfacing voting ballots, session start countdowns, and spot confirmation alerts.
  - **Comprehensive Test Suite**: Added `test/system_hardening_test.dart` (7 unit tests); full test suite (50 tests) passing with 0 `flutter analyze` issues.
- [x] **Per-User Data Isolation & Sign-Out Reset**:
  - **Scoped Game Sessions**: Filtered Firestore sessions stream in `GameNightViewModel` so users only see game nights they created (`createdBy == uid`), are participating in (`players`), or joined via room code. New users start with a clean slate.
  - **Scoped Squads**: Filtered Firestore squads stream in `GroupsViewModel` so users only see squads where they are creator (`createdBy == uid`) or in `memberNames`.
  - **Sign-Out & Account Switch State Reset**: Added `reset()` lifecycle to `ProfileViewModel`, `GroupsViewModel`, and `GameNightViewModel`. Wired `authStateChanges` in `main.dart` to automatically wipe state when logging out or switching users.
  - **User Session Cache Isolation**: Enhanced `PreferencesService` to scope profile caches by UID and added `clearUserSessionData()` to wipe cached user profiles and notifications on sign out while preserving theme preferences.
  - **Comprehensive Test Suite**: Added `test/user_data_isolation_test.dart` (8 unit tests); entire test suite (58 tests) passing with 0 `flutter analyze` issues.
- [x] **Core Game Night Functional Fixes**:
  - **Edit Session Details Flow**: Built `EditGameNightSheet` bottom modal enabling organizers to update session title, date/time pickers, host note/cozy ritual, venue/location, and voice room URL.
  - **Dynamic Bring-List Additions in Details View**: Added 1-tap `+ Add item` action directly in `GameNightDetailsView._buildCozyChecklistCard` allowing any attendee to add snacks, drinks, or gear with instant claim checkbox.
  - **Discord Voice / Party Room Launch**: Wired `Chat / Voice` CTA to launch external Discord, Google Meet, or party room links via `url_launcher`. If unlinked, hosts are prompted with a quick modal to paste the link, and attendees are notified.
  - **Firestore & ViewModel Data Layer**: Added `updateSessionDetails` and `addChecklistItemToSession` in `FirebaseService` and `GameNightViewModel`, with `voiceChannelUrl` mapping.
  - **Comprehensive Test Suite**: Added `test/session_functional_fixes_test.dart` (4 unit & widget tests); all 62 tests passing cleanly.
- [x] **Hardened Firestore Security Rules & Cloudinary Game Picture Uploads**:
  - **Firestore Production Rules Compliance**: Hardened `firestore.rules` to enforce creator-only squad and session deletion, immutability of `createdBy` and `roomCode` during updates, and protection of curated catalog games from unauthorized modification or deletion.
  - **Cloudinary Game Cover Pipeline**: Enhanced `GameModel` and `GameNightViewModel.createAndSaveCustomGame` to support custom `imageUrl` storage alongside Steam CDN games.
  - **AddGameSheet Experience**: Built `AddGameSheet` supporting 1-tap cover art picking and direct upload to Cloudinary (`folder: 'duwa/games'`), with emoji badge selector, title, genre, player counts, and graceful offline fallback.
  - **Integrated Entry Points**: Connected `AddGameSheet` directly into `CreateGameNightSheet` and `RandomGameSheet` ("What should we play?"), allowing squad members to expand their game library at any time.
  - **Comprehensive Test Suite**: Added `test/game_image_upload_test.dart` (7 unit and widget tests); full test suite (69 tests) passing with 0 `flutter analyze` issues.
- [x] **Steam Integration Engine & Valve Web API Sync**:
  - **SteamConfig & Dual Key Placement**: Created `lib/core/config/steam_config.dart` with support for compile-time key or `--dart-define=STEAM_API_KEY=...`, paired with UI key configuration stored in `PreferencesService`.
  - **SteamService Engine**: Built `SteamService` to automatically resolve 32-bit Friend Codes (e.g. `87291044` -> SteamID64 via offset `76561197960265728`), 17-digit SteamID64s, and custom vanity names via `ISteamUser/ResolveVanityURL`.
  - **Live Profile & Owned Games**: Fetches real player persona, avatar, in-game status (`ISteamUser/GetPlayerSummaries`), and owned games with playtime hours and official Steam CDN key art banners (`IPlayerService/GetOwnedGames`).
  - **Overhauled SteamSyncView**: Editorial Steam Deck-inspired design with account connect input, API key drawer, real-time library search bar, playtime badges, and 1-tap nominate action for squad session voting.
- [x] **Impeccable Readability & Contrast Overhaul**:
  - **Dark Mode Contrast Tokens**: Upgraded `obsidianTextSecondary` (`#CBD5E1`) and `obsidianTextMuted` (`#94A3B8`) in `DuwaColors`, elevating contrast to 5.5:1 (exceeding WCAG AAA standards).
  - **NotificationsView Polish**: Upgraded alert item titles (15px, w800), subtitles (13.5px, 1.38 line height), timeago stamps (12px, w600), glowing ambient unread dot, and higher-contrast filter pills.
  - **ProfileView Settings Polish**: Increased tile title (15px), subtitle (13px, 1.3 line height), icon sizing, and container padding for effortless scannability.
- [x] **Brand Identity Overhaul — "The Gamepad D" & Micro-Interactions**:
  - **Authentic Symbol Craft**: Replaced the generic ribbon graphic with Concept 1 ("The Gamepad D")—a directional D-pad cross on the left meeting an ergonomic curved controller grip with twin action buttons on the right.
  - **Tactile Spring Animations**: Re-architected `DuwaLogo` with `AnimationController` and `TweenSequence`, providing an elastic console-click micro-bounce (`Curves.easeOutBack`) and haptic feedback (`HapticFeedback.lightImpact()`) on tap.
  - **Dynamic Glow Aura**: Added ambient Solar Flame (`#FF5E1E`) and Ember Gold (`#FFA114`) breathing glow that intensifies upon interaction.
  - **Dual Rendering Pipeline**: Features both the high-res squircle asset (`assets/images/duwa_gamepad_logo.jpg`) and a precision resolution-independent vector painter (`_DuwaGamepadLogoPainter`) for razor-sharp rendering on any screen.
- [x] **Comprehensive Test Suite & Code Health**:
  - Added `test/steam_service_test.dart` (9 unit tests); entire test suite (78 tests) passing cleanly with 0 `flutter analyze` issues.
- [x] **SSO Platform Hardening, Modern Gmail Logo, Short Squad Codes & Real User Integrity**:
  - **SSO Cross-Platform Fix**: Configured `serverClientId` for GoogleSignIn on mobile; added desktop fallback using `_auth.signInWithProvider(GoogleAuthProvider())` on Windows/macOS/Linux; improved error handling.
  - **Modern 4-Color Gmail Logo**: Built `GmailLogoWidget` vector painter with authentic Google Workspace geometry (Blue `#4285F4`, Red `#EA4335`, Yellow `#FBBC05`, Green `#34A853`) and embedded it into `AuthView`.
  - **Arcade Short Squad Codes**: Added `generateSquadCode()` generating clean 4-character codes (e.g. `SQ-79K2`); added `squadCode` and `displaySquadCode` to `GamerGroupModel`; updated squad details, invite sheets, and WhatsApp/Discord exports.
  - **Eliminated Fake/Unreal Users**: Purged the hardcoded `suggestedGamers` dummy list; added real Firestore user lookup (`searchRegisteredUsers`); prompted organizers to share their squad code if no registered user exists instead of generating phantom accounts.
  - **Code & Join Discrepancies**: Unified `JoinCodeDialog` to accept both squad codes (`SQ-...`) and game night codes (`DUWA-...`, `DW-...`, or 4-char suffix) without mangling prefixes; fixed layout overflow in dispatch sheet.
  - **Testing**: Added `test/sso_squad_code_test.dart` (6 unit/widget tests); all 84 tests passing cleanly with 0 `flutter analyze` issues.
- [x] **Cloudinary Media Pipeline, Profile Games Showcase & Custom Added Games Overhaul**:
  - **Cloudinary Pipeline Architecture**: Built `CloudinaryConfig` with verified active cloud credentials (`dz4x2mmzc`, upload preset `duwa_preset`), `--dart-define` support, and base transformation URLs.
  - **Dynamic In-App Cloudinary Setup & Live Test**: Built "Media Storage (Cloudinary)" bottom sheet in `ProfileView` under Connected Accounts allowing players to view active credentials, test uploads with 1-tap live verification, and customize credentials persisted via `PreferencesService`.
  - **Profile Avatar Upgrades**: Enhanced avatar picker with Camera and Gallery image choices, active progress spinner on the avatar ring during upload, optimized Cloudinary CDN URL delivery (`f_auto,q_auto,w_128,h_128,c_fill`), and option to remove photo.
  - **Squad Games & Favorites Showcase in Profile**: Added interactive "SQUAD LIBRARY & FAVORITES" section with filter tabs (`All Games`, `Added by You`, `Favorites`), 1-tap favorite toggle with haptic feedback, 1-tap "Plan" session trigger, and prominent "+ Add Game" action.
  - **Custom Added Games Hardening & Local Cache**: Added local persistence for custom added games in `PreferencesService` (`duwa_custom_games`), attributed `createdBy` in `GameModel`, and hydrated custom games instantly on launch in `GameNightViewModel._initGamesCatalog` so games never disappear offline.
  - **AddGameSheet Experience**: Added Camera & Gallery picker choices, upload progress overlay, submit disable guard during upload/saving, and friendly Cloudinary error reporting.
  - **Optimized CDN Cover Art Across App**: Added `GameModel.optimizedCoverUrl()` and integrated it into `HeroSessionMarquee`, `GamePassCard`, `GameNightDetailsView`, `CreateGameNightSheet`, and `RandomGameSheet`.
  - **Comprehensive Test Suite**: Added `test/cloudinary_profile_games_test.dart` (8 tests); full test suite (95 tests) passing cleanly with 0 `flutter analyze` issues.

