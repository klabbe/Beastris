# Game Engine

The `GameEngine` class in `lib/game/engine.dart` contains all core game logic. It extends `ChangeNotifier` to drive UI updates.

## Board

- **20 rows × 10 columns** grid of `Cell` objects
- Empty cells have `null` color; filled cells store color and emoji
- `displayBoard` merges the current falling piece onto the board for rendering

## Game States

```
GameState.idle     → Start screen, waiting for user to begin
GameState.playing  → Active gameplay, timer running
GameState.paused   → Timer stopped, game frozen
GameState.gameOver → Board is full, piece cannot spawn
```

## Game Loop

1. A `Timer.periodic` fires every `_tickMs` milliseconds
2. On each tick, the current piece moves down by one row
3. If the piece cannot move down, it **locks** onto the board
4. Completed lines are cleared and scored
5. A new piece spawns; if it cannot be placed, the game ends

## Piece Spawning

- `_nextPiece` is selected randomly at the start
- When spawning, `_currentPiece` takes the value of `_nextPiece`, and a new `_nextPiece` is generated
- The piece is centered horizontally: `col = (10 - piece.width) / 2`

## Movement & Rotation

| Method | Description |
|--------|-------------|
| `moveLeft()` | Move piece one column left if valid |
| `moveRight()` | Move piece one column right if valid |
| `rotate()` | Rotate 90° clockwise with wall kick offsets (0, -1, +1, -2, +2) |
| `softDrop()` | Move one row down, +1 score |
| `hardDrop()` | Instantly drop to lowest valid row, +2 score per row |

## Collision Detection

`_canPlace(piece, row, col)` checks that every cell of the piece shape:
- Is within board bounds (0 ≤ r < 20, 0 ≤ c < 10)
- Does not overlap an already-filled cell

## Line Clearing

After locking a piece, each row is checked bottom-to-top. Full rows are removed and empty rows are inserted at the top. The row index is re-checked after removal since rows shift down.

## Speed Progression

```
tickMs = max(100, 800 - (level - 1) × 60)
```

Level 1 = 800ms, Level 2 = 740ms, ..., Level 12+ = 100ms (cap).
