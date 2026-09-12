# DUWA

DUWA is a shared game-session planner. It helps a squad decide what to play,
confirm who is coming, and keep the practical details in one place.

## Product structure

- **Home** — the next useful action, an upcoming session, squads, and history.
- **Squads** — the recurring groups of people you play with.
- **Sessions** — every upcoming, action-required, and completed session.
- **Session detail** — the single home for voting, RSVPs, plans, people, and activity.
- **You** — profile, integrations, and app preferences.

The primary planning journey has three steps: choose a squad and game, set the
time and attendees, then review and create the session.

## Architecture

- `lib/models` contains domain data such as sessions, players, squads, and games.
- `lib/viewmodels` owns presentation state and user actions.
- `lib/services/firebase_service.dart` owns Firebase authentication and cloud
  operations for profiles, squads, sessions, votes, and RSVPs.
- `lib/views` contains the app’s screen hierarchy and reusable UI components.

The app is usable with local sample data. Firebase synchronisation is best-effort
so that the UI remains responsive when the device is offline or Firestore has not
yet been configured.

## Run and verify

```powershell
flutter pub get
flutter run
flutter analyze
flutter test
```
