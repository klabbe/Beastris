# Widgets

The UI is composed of a few focused widgets in `lib/widgets/` and the main screen in `lib/screens/`.

## GameScreen (`lib/screens/game_screen.dart`)

The root game widget. Manages the `GameEngine` lifecycle and renders either the start screen or the game layout.

- **Start screen** — Title, animal emoji row, and a "START GAME" button
- **Game layout** — Top bar with title and pause button, the game board, side panel (next piece + score), and touch controls
- **Game over dialog** — Shows score, lines, and level with a "Play Again" button
- Haptic feedback on game over (`heavyImpact`) and button presses (`lightImpact`)

## GameBoard (`lib/widgets/game_board.dart`)

Renders the 10×20 game board using `CustomPaint`.

- Maintains correct aspect ratio (10:20)
- Draws a subtle grid
- Renders the ghost piece (translucent preview of landing position)
- Renders filled cells with rounded rectangles and emoji text

## NextPiecePreview (`lib/widgets/next_piece.dart`)

Displays the upcoming piece in a compact panel.

- Shows the piece emoji
- Renders a 4×4 mini grid via `CustomPaint` with the piece shape centered

## ScorePanel (`lib/widgets/score_panel.dart`)

Displays three stats in a vertical column:

- **SCORE** — Current point total
- **LINES** — Total lines cleared
- **LEVEL** — Current level (lines ÷ 10 + 1)

## Touch Controls

Built into `GameScreen._buildControls()`. Five buttons in a row:

| Button | Icon | Action |
|--------|------|--------|
| Left | ◀ | `moveLeft()` |
| Rotate | ↻ | `rotate()` |
| Soft Drop | ▼ | `softDrop()` |
| Hard Drop | ⏬ | `hardDrop()` |
| Right | ▶ | `moveRight()` |
