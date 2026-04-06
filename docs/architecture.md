# Architecture

Beastris follows a clean separation between game logic, data models, and UI.

## Project Structure

```
lib/
├── main.dart              # App entry point, MaterialApp setup
├── game/
│   └── engine.dart        # Core game logic (GameEngine)
├── models/
│   ├── cell.dart          # Cell data model (color + emoji)
│   └── piece.dart         # Piece definitions (BeastPiece, BeastPieces)
├── screens/
│   └── game_screen.dart   # Main game screen with layout & controls
└── widgets/
    ├── game_board.dart    # Board rendering via CustomPaint
    ├── next_piece.dart    # Next piece preview widget
    └── score_panel.dart   # Score/lines/level display
```

## Design Patterns

### ChangeNotifier + setState

`GameEngine` extends `ChangeNotifier`. The `GameScreen` widget listens to engine updates and calls `setState()` to trigger rebuilds. This keeps state management simple with no third-party packages.

### CustomPainter for Rendering

The game board and next-piece preview use Flutter's `CustomPaint` widget with custom painters for efficient, pixel-level rendering of the grid, cells, and ghost piece.

## Dependencies

The project uses only Flutter SDK dependencies — no third-party packages are required for game functionality:

- `flutter` SDK
- `cupertino_icons` (for iOS-style icons)

## Platforms

Platform scaffolding exists for: Android, iOS, Web, macOS, Linux, Windows.
