"""Generate BeastBlocks app icon: colored animal-piece blocks on dark background with paw print."""
from PIL import Image, ImageDraw, ImageFont
import math

SIZE = 1024
PADDING = 80
BG_COLOR = (26, 26, 46)  # #1A1A2E - matches game board
GRID = 6  # 6x6 visible grid

# Animal piece colors from the game
SNAKE = (76, 175, 80)      # #4CAF50 green
CROC = (139, 195, 58)      # #8BC34A lime
CATERPILLAR = (0, 188, 212) # #00BCD4 cyan
TURTLE = (255, 193, 7)     # #FFC107 yellow/amber
EAGLE = (156, 39, 176)     # #9C27B0 purple
DOG = (255, 152, 0)        # #FF9800 orange
CAT = (233, 30, 99)        # #E91E63 pink

# Layout: arrange piece shapes on a 6x6 grid to look like a game in progress
# Each cell is either None (empty) or a color tuple
grid = [[None]*GRID for _ in range(GRID)]

# Bottom rows filled with mixed colors (like a game in progress)
# Row 5 (bottom)
grid[5] = [SNAKE, DOG, DOG, TURTLE, TURTLE, CAT]
# Row 4
grid[4] = [SNAKE, SNAKE, DOG, TURTLE, TURTLE, CAT]
# Row 3
grid[3] = [None, SNAKE, DOG, CROC, None, CAT]
# Row 2 - some blocks
grid[2] = [None, None, CATERPILLAR, CROC, CROC, None]
# Row 1 - eagle T-piece falling
grid[1] = [None, EAGLE, EAGLE, EAGLE, None, None]
# Row 0 - top of T
grid[0] = [None, None, EAGLE, None, None, None]

img = Image.new('RGBA', (SIZE, SIZE), (0, 0, 0, 0))
draw = ImageDraw.Draw(img)

# Rounded rectangle background
corner = 180
draw.rounded_rectangle([0, 0, SIZE-1, SIZE-1], radius=corner, fill=BG_COLOR)

# Draw grid cells
cell_area = SIZE - 2 * PADDING
cell_size = cell_area / GRID
margin = 4  # gap between cells
block_radius = 14

for r in range(GRID):
    for c in range(GRID):
        color = grid[r][c]
        if color is None:
            continue
        x = PADDING + c * cell_size + margin
        y = PADDING + r * cell_size + margin
        w = cell_size - 2 * margin
        h = cell_size - 2 * margin

        # Main block
        draw.rounded_rectangle(
            [x, y, x + w, y + h],
            radius=block_radius,
            fill=color,
        )

        # Highlight (top third, lighter)
        highlight = tuple(min(255, ch + 70) for ch in color)
        hl_h = h / 3
        draw.rounded_rectangle(
            [x + 3, y + 3, x + w - 3, y + hl_h],
            radius=block_radius - 2,
            fill=highlight,
        )

        # Subtle shadow at bottom
        shadow = tuple(max(0, ch - 40) for ch in color)
        sh_y = y + h - h / 5
        draw.rounded_rectangle(
            [x + 3, sh_y, x + w - 3, y + h - 3],
            radius=block_radius - 2,
            fill=shadow,
        )

# Draw a paw print overlay in the center using circles
paw_cx, paw_cy = SIZE // 2, SIZE // 2 - 20
paw_color = (255, 255, 255, 90)  # semi-transparent white

# Main pad (big oval)
pad_w, pad_h = 90, 70
draw.ellipse(
    [paw_cx - pad_w, paw_cy + 20 - pad_h, paw_cx + pad_w, paw_cy + 20 + pad_h],
    fill=paw_color,
)

# Four toe pads
toe_r = 38
toe_positions = [
    (paw_cx - 70, paw_cy - 70),
    (paw_cx - 20, paw_cy - 100),
    (paw_cx + 20, paw_cy - 100),
    (paw_cx + 70, paw_cy - 70),
]
for tx, ty in toe_positions:
    draw.ellipse(
        [tx - toe_r, ty - toe_r, tx + toe_r, ty + toe_r],
        fill=paw_color,
    )

# Save
out_path = "assets/icon/app_icon.png"
import os
os.makedirs("assets/icon", exist_ok=True)
img.save(out_path, "PNG")
print(f"Icon saved to {out_path} ({SIZE}x{SIZE})")
