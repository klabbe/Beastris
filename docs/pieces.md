# Pieces

BeastBlocks has 7 animal-themed pieces, each mapping to a classic Tetris shape. Pieces are defined in `lib/models/piece.dart`.

## Piece List

| Animal | Emoji | Classic Shape | Color |
|--------|-------|---------------|-------|
| Snake | 🐍 | S-piece | Green `#4CAF50` |
| Croc | 🐊 | Z-piece | Light Green `#8BC34A` |
| Caterpillar | 🐛 | I-piece | Cyan `#00BCD4` |
| Turtle | 🐢 | O-piece | Amber `#FFC107` |
| Eagle | 🦅 | T-piece | Purple `#9C27B0` |
| Dog | 🐕 | L-piece | Orange `#FF9800` |
| Cat | 🐈 | J-piece | Red `#F44336` |

## Shape Definitions

Each piece is defined as a list of `[row, col]` offsets from a reference point (top-left origin):

```
Snake 🐍        Croc 🐊         Caterpillar 🐛
 ##              ##              ####
##                ##

Turtle 🐢       Eagle 🦅        Dog 🐕        Cat 🐈
##               ###             #               #
##                #              #               #
                                 ##             ##
```

## Rotation

Rotation is 90° clockwise using the transform `(r, c) → (c, -r)`, then normalized so that the minimum row and column offsets are 0. This is handled by the `BeastPiece.rotated()` method.

## BeastPiece Properties

| Property | Type | Description |
|----------|------|-------------|
| `name` | `String` | Animal name |
| `emoji` | `String` | Emoji character |
| `color` | `Color` | Fill color |
| `shape` | `List<List<int>>` | `[row, col]` offsets |
| `width` | `int` | Computed: max column + 1 |
| `height` | `int` | Computed: max row + 1 |
