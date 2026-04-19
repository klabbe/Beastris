# Architecture

Beastris follows a clean separation between game logic, data models, and UI.

## Project Structure

```
lib/
├── main.dart                    # App entry point, Firebase init, MaterialApp
├── firebase_options.dart        # Auto-generated Firebase config (API keys)
├── game/
│   └── engine.dart              # Core game logic (GameEngine)
├── models/
│   ├── cell.dart                # Cell data model (color + emoji)
│   ├── piece.dart               # Piece definitions (BeastPiece, BeastPieces)
│   ├── game_history.dart        # Local game history (shared_preferences)
│   ├── user_profile.dart        # User profile model (uid, alias, name, country)
│   └── countries.dart           # Country list + countryCodeToFlag() helper
├── services/
│   ├── auth_service.dart        # Firebase Auth wrapper (ChangeNotifier)
│   └── leaderboard_service.dart # Firestore leaderboard read/write + dedup
├── screens/
│   └── game_screen.dart         # Main screen: game, leaderboard, dialogs
└── widgets/
    ├── game_board.dart           # Board rendering via CustomPaint
    ├── next_piece.dart           # Next piece preview widget
    └── score_panel.dart          # Score/lines/level display
```

## Design Patterns

### ChangeNotifier + setState

Both `GameEngine` and `AuthService` extend `ChangeNotifier`. `GameScreen` listens to both and calls `setState()` to trigger rebuilds. No third-party state management needed.

### CustomPainter for Rendering

The game board and next-piece preview use Flutter's `CustomPaint` widget with custom painters for efficient, pixel-level rendering of the grid, cells, and ghost piece.

### Service Layer

Business logic is separated into service classes:
- `AuthService` — wraps `firebase_auth`, stores the current user's profile in memory, exposes `isLoggedIn`, `currentUser`, `profile`
- `LeaderboardService` — stateless, all methods are async, deduplicates by uid before returning data

## Dependencies

| Package | Usage |
|---------|-------|
| `firebase_core` | Firebase initialization |
| `firebase_auth` | Email/password authentication |
| `cloud_firestore` | Global leaderboard & user profiles |
| `shared_preferences` | Local game history |
| `cupertino_icons` | iOS-style icons |

## Platforms

Platform scaffolding exists for: Android, iOS, Web, macOS, Linux, Windows.
Primary tested platforms: **Android** (Samsung S23), **Web** (Chrome).
