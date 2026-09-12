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
- [x] **Code Health & Testing**: `flutter analyze` 0 issues, all 28 test suites passing cleanly.
