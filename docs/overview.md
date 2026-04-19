# Overview

BeastBlocks is a falling-block puzzle game inspired by Tetris. Instead of abstract geometric shapes, each piece is themed as an animal with its own emoji and color.

## Features

- **7 animal-themed pieces** — Snake 🐍, Croc 🐊, Caterpillar 🐛, Turtle 🐢, Eagle 🦅, Dog 🐕, Cat 🐈
- **Classic Tetris mechanics** — Move, rotate, soft drop, hard drop, line clearing
- **Ghost piece** — A translucent preview showing where the piece will land
- **Next piece preview** — See the upcoming piece in the side panel
- **Scoring system** — Points for soft drops, hard drops, and line clears with level multipliers
- **Increasing difficulty** — Speed increases as you clear more lines and level up
- **Wall kicks** — Rotation near walls attempts offset positions to allow valid placement
- **Touch controls** — On-screen buttons with haptic feedback
- **Dark theme** — Deep blue/purple color scheme
- **Cross-platform** — Runs on Android, Web, iOS, macOS, Linux, and Windows

## Scoring

| Action | Points |
|--------|--------|
| Soft drop (per row) | 1 |
| Hard drop (per row) | 2 |
| 1 line clear | 100 × level |
| 2 line clear | 300 × level |
| 3 line clear | 500 × level |
| 4 line clear (Beast Combo!) | 800 × level |

## Leveling

- Level increases by 1 for every 10 lines cleared
- Each level reduces the tick interval by 60ms (minimum 100ms)
- Starting tick speed: 800ms; at level 12+ the minimum of 100ms is reached
