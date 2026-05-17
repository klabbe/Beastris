"""Generate Play Store phone screenshots (1080x1920, 9:16) for BeastBlocks.

Outputs:
  assets/store/screenshot_1_menu.png
  assets/store/screenshot_2_gameplay.png
  assets/store/screenshot_3_leaderboard.png
  assets/store/screenshot_4_gameover.png
"""
import os
from PIL import Image, ImageDraw, ImageFont

OUT_DIR  = os.path.join(os.path.dirname(__file__), '..', 'assets', 'store')
os.makedirs(OUT_DIR, exist_ok=True)

ICON_PATH = os.path.join(os.path.dirname(__file__), '..', 'assets', 'icon', 'app_icon.png')

W, H = 1080, 1920

# ── Palette ───────────────────────────────────────────────────────────────────
BG          = (15, 52, 96)     # #0F3460  main background
BOARD_BG    = (26, 26, 46)     # #1A1A2E  board background
CARD_BG     = (22, 33, 62)     # #16213E  card/dialog background
ACCENT      = (83, 52, 131)    # #533483  purple accent
ACCENT2     = (83, 52, 131)
BORDER      = (83, 52, 131, 128)
WHITE       = (255, 255, 255)
WHITE70     = (180, 190, 210)
WHITE54     = (138, 148, 168)
WHITE24     = (61,  71,  91)
GOLD        = (255, 215, 0)
RED         = (244, 67, 54)

# Piece colors
SNAKE_C  = (76,  175, 80)
CROC_C   = (139, 195, 74)
CATER_C  = (0,   188, 212)
TURTLE_C = (255, 193, 7)
EAGLE_C  = (156, 39,  176)
DOG_C    = (255, 152, 0)
CAT_C    = (244, 67,  54)
EMPTY_C  = None

# Piece shapes (row,col offsets)
PIECES = {
    'snake':  {'color': SNAKE_C,  'shape': [[0,1],[0,2],[1,0],[1,1]]},
    'croc':   {'color': CROC_C,   'shape': [[0,0],[0,1],[1,1],[1,2]]},
    'cater':  {'color': CATER_C,  'shape': [[0,0],[0,1],[0,2],[0,3]]},
    'turtle': {'color': TURTLE_C, 'shape': [[0,0],[0,1],[1,0],[1,1]]},
    'eagle':  {'color': EAGLE_C,  'shape': [[0,0],[0,1],[0,2],[1,1]]},
    'dog':    {'color': DOG_C,    'shape': [[0,0],[1,0],[2,0],[2,1]]},
    'cat':    {'color': CAT_C,    'shape': [[0,1],[1,1],[2,0],[2,1]]},
}

# ── Font helpers ──────────────────────────────────────────────────────────────
font_paths = [
    '/System/Library/Fonts/Helvetica.ttc',
    '/System/Library/Fonts/SFNS.ttf',
    '/Library/Fonts/Arial.ttf',
]
found_font = next((p for p in font_paths if os.path.exists(p)), None)

def font(size):
    if found_font:
        try:
            return ImageFont.truetype(found_font, size)
        except Exception:
            pass
    return ImageFont.load_default()

# ── Drawing helpers ───────────────────────────────────────────────────────────
def rounded_rect(draw, x0, y0, x1, y1, radius, fill, outline=None, outline_width=2):
    draw.rounded_rectangle([x0, y0, x1, y1], radius=radius, fill=fill,
                           outline=outline, width=outline_width)

def center_text(draw, text, cx, y, fnt, fill=WHITE):
    bbox = draw.textbbox((0, 0), text, font=fnt)
    w = bbox[2] - bbox[0]
    draw.text((cx - w // 2, y), text, font=fnt, fill=fill)

def pill_button(draw, cx, y, w, h, label, fnt, bg=ACCENT, fg=WHITE):
    rounded_rect(draw, cx - w//2, y, cx + w//2, y + h, h//2, bg)
    center_text(draw, label, cx, y + (h - (draw.textbbox((0,0), label, font=fnt)[3])//1)//2, fnt, fg)

# ── Board drawing helper ──────────────────────────────────────────────────────
BOARD_COLS = 10
BOARD_ROWS = 20

def draw_board(canvas, bx, by, bw, bh, cells, active_piece=None, active_r=0, active_c=0):
    """cells: 20×10 list of color tuples or None"""
    draw = ImageDraw.Draw(canvas)
    cell_w = bw / BOARD_COLS
    cell_h = bh / BOARD_ROWS
    # background
    rounded_rect(draw, bx, by, bx+bw, by+bh, 4, BOARD_BG, outline=(255,255,255,40))
    # grid lines
    gp = (255, 255, 255, 12)
    for c in range(1, BOARD_COLS):
        draw.line([(bx + c*cell_w, by), (bx + c*cell_w, by+bh)], fill=gp, width=1)
    for r in range(1, BOARD_ROWS):
        draw.line([(bx, by + r*cell_h), (bx+bw, by + r*cell_h)], fill=gp, width=1)
    # cells
    for r in range(BOARD_ROWS):
        for c in range(BOARD_COLS):
            col = cells[r][c]
            if col:
                cx0 = bx + c*cell_w + 2
                cy0 = by + r*cell_h + 2
                cx1 = bx + (c+1)*cell_w - 2
                cy1 = by + (r+1)*cell_h - 2
                rounded_rect(draw, int(cx0), int(cy0), int(cx1), int(cy1), 3, col)
                # highlight
                draw.line([(int(cx0)+1, int(cy0)+1), (int(cx1)-2, int(cy0)+1)],
                          fill=(255,255,255,80), width=2)
    # active piece
    if active_piece:
        ac = PIECES[active_piece]['color']
        ghost_c = (ac[0], ac[1], ac[2], 38)
        for (pr, pc) in PIECES[active_piece]['shape']:
            r2 = active_r + pr
            c2 = active_c + pc
            if 0 <= r2 < BOARD_ROWS and 0 <= c2 < BOARD_COLS:
                cx0 = bx + c2*cell_w + 2
                cy0 = by + r2*cell_h + 2
                cx1 = bx + (c2+1)*cell_w - 2
                cy1 = by + (r2+1)*cell_h - 2
                rounded_rect(draw, int(cx0), int(cy0), int(cx1), int(cy1), 3, ac)

def make_board_cells():
    """Create a realistic partially-filled board state"""
    cells = [[None]*BOARD_COLS for _ in range(BOARD_ROWS)]
    # rows 14-19 nearly full, with various pieces
    patterns = [
        # (row, col, color)
        *[(14, c, EAGLE_C) for c in range(0, 8)],
        *[(15, c, SNAKE_C) for c in range(0, 10)],
        *[(16, c, TURTLE_C) for c in range(0, 10)],
        *[(17, c, CROC_C)   for c in range(0, 9)],
        *[(18, c, DOG_C)    for c in range(0, 10)],
        *[(19, c, CAT_C)    for c in range(0, 10)],
        # mid-board clusters
        *[(10, c, CATER_C)  for c in range(2, 6)],
        *[(11, c, EAGLE_C)  for c in [2, 3, 4, 5, 6]],
        *[(12, c, SNAKE_C)  for c in [4, 5, 6, 7]],
        *[(12, c, CROC_C)   for c in [1, 2]],
        *[(13, c, TURTLE_C) for c in [0, 1, 5, 6, 7, 8]],
        *[(9,  c, CAT_C)    for c in [7, 8]],
    ]
    for (r, c, col) in patterns:
        if 0 <= r < BOARD_ROWS and 0 <= c < BOARD_COLS:
            cells[r][c] = col
    return cells

# ── Status bar placeholder ────────────────────────────────────────────────────
def draw_statusbar(draw, y=48):
    """Draw a minimal status-bar-like strip"""
    draw.text((80, y), '9:41', font=font(36), fill=WHITE70)

# ── SCREENSHOT 1: Start / Menu screen ────────────────────────────────────────
def screenshot_menu():
    img = Image.new('RGB', (W, H), BG)
    draw = ImageDraw.Draw(img)

    draw_statusbar(draw)

    # Sign In (top right)
    rounded_rect(draw, W-220, 36, W-56, 88, 24, (255,255,255,18), outline=WHITE24)
    draw.text((W-195, 47), 'Sign In', font=font(30), fill=WHITE54)

    # App icon
    try:
        icon = Image.open(ICON_PATH).convert('RGBA')
        icon = icon.resize((260, 260), Image.LANCZOS)
        bg_patch = Image.new('RGB', (260, 260), BG)
        bg_patch.paste(icon, (0, 0), icon)
        img.paste(bg_patch, (W//2 - 130, 120))
    except Exception:
        rounded_rect(draw, W//2-80, 140, W//2+80, 300, 20, ACCENT)

    # Title
    center_text(draw, 'BEASTBLOCKS', W//2, 410, font(72), WHITE)
    center_text(draw, 'Animal Blocks Falling!', W//2, 504, font(38), WHITE54)

    # Piece icons row (colored squares with single-letter labels)
    piece_colors = [SNAKE_C, CROC_C, CATER_C, TURTLE_C, EAGLE_C, DOG_C, CAT_C]
    piece_labels = ['S', 'C', 'I', 'O', 'T', 'L', 'J']
    px_start = W//2 - 3*80 - 24
    for i, (pc, pl) in enumerate(zip(piece_colors, piece_labels)):
        px = px_start + i * 78
        rounded_rect(draw, px, 570, px+62, 632, 10, pc)
        center_text(draw, pl, px+31, 580, font(30), WHITE)

    # START GAME button
    bw, bh = 520, 100
    by = 680
    rounded_rect(draw, W//2-bw//2, by, W//2+bw//2, by+bh, bh//2, ACCENT)
    center_text(draw, 'START GAME', W//2, by+22, font(46), WHITE)

    # Best scores section
    center_text(draw, 'YOUR BEST', W//2, 830, font(30), WHITE54)
    scores_data = [
        ('1.', '12 850', '5 lines  · Lv.2'),
        ('2.', '9 120',  '4 lines  · Lv.2'),
        ('3.', '6 400',  '3 lines  · Lv.1'),
    ]
    for i, (rank, score, detail) in enumerate(scores_data):
        ry = 875 + i * 72
        rounded_rect(draw, 140, ry, W-140, ry+60, 10, CARD_BG)
        draw.text((170, ry+14), rank, font=font(30), fill=WHITE54)
        draw.text((220, ry+14), score, font=font(30), fill=WHITE)
        draw.text((W-380, ry+14), detail, font=font(26), fill=WHITE54)

    # Global leaderboard
    lx, lw = 140, W-280
    ly = 1110
    rounded_rect(draw, lx, ly, lx+lw, ly+560, 16, CARD_BG,
                 outline=ACCENT, outline_width=2)
    center_text(draw, 'Global Leaderboard', W//2, ly+20, font(34), WHITE)

    # Tabs
    for i, (label, active) in enumerate([('All Time', True), ('This Week', False)]):
        tx = W//2 - 160 + i*160
        tab_bg = ACCENT if active else CARD_BG
        tab_border = ACCENT if active else WHITE24
        rounded_rect(draw, tx, ly+72, tx+140, ly+112, 20, tab_bg,
                     outline=tab_border, outline_width=2)
        center_text(draw, label, tx+70, ly+80, font(26), WHITE if active else WHITE54)

    # Leaderboard entries
    lb_data = [
        ('#1', 'TigerKing',    'SE', '47 320'),
        ('#2', 'BeastMaster',  'US', '42 100'),
        ('#3', 'WildCard',     'DE', '38 750'),
        ('#4', 'SnakeBoss',    'GB', '31 200'),
        ('#5', 'CatLady99',    'JP', '29 880'),
        ('#6', 'DoggoFan',     'FR', '27 440'),
        ('#7', 'CrocHunter',   'AU', '24 110'),
        ('#8', 'EagleEye',     'CA', '21 900'),
        ('#9', 'TurtlePro',    'NL', '19 500'),
        ('#10','BomberKing',   'BR', '17 200'),
    ]
    for i, (rank, name, country, score) in enumerate(lb_data):
        ey = ly + 128 + i*38
        rc = GOLD if i == 0 else WHITE54
        nc = GOLD if i == 0 else WHITE
        sc = GOLD if i == 0 else WHITE70
        draw.text((lx+20, ey), rank,   font=font(26), fill=rc)
        draw.text((lx+90, ey), name,   font=font(26), fill=nc)
        draw.text((lx+lw-200, ey), country, font=font(22), fill=WHITE54)
        draw.text((lx+lw-130, ey), score, font=font(26), fill=sc)

    img.save(os.path.join(OUT_DIR, 'screenshot_1_menu.png'))
    print('screenshot_1_menu.png saved')

# ── SCREENSHOT 2: Active gameplay ─────────────────────────────────────────────
def screenshot_gameplay():
    img = Image.new('RGB', (W, H), BG)
    draw = ImageDraw.Draw(img)

    draw_statusbar(draw)

    # Top bar: score / level / lines
    bar_y = 90
    for i, (label, value) in enumerate([('SCORE', '8 450'), ('LEVEL', '2'), ('LINES', '7')]):
        cx = 180 + i * 360
        draw.text((cx - draw.textbbox((0,0), label, font=font(26))[2]//2, bar_y),
                  label, font=font(26), fill=WHITE54)
        draw.text((cx - draw.textbbox((0,0), value, font=font(52))[2]//2, bar_y+28),
                  value, font=font(52), fill=WHITE)

    # Game board
    board_margin = 24
    board_x = board_margin
    board_y = 200
    board_w = 680
    board_h = board_w * 2  # 10:20 = 1:2
    cells = make_board_cells()
    draw_board(img, board_x, board_y, board_w, board_h, cells,
               active_piece='eagle', active_r=6, active_c=3)

    # Right panel
    rx = board_x + board_w + 24
    rw = W - rx - board_margin

    # NEXT label
    draw.text((rx, board_y + 10), 'NEXT', font=font(32), fill=WHITE54)

    # Next piece preview box
    np_size = rw
    np_y = board_y + 54
    rounded_rect(draw, rx, np_y, rx+np_size, np_y+np_size, 10, CARD_BG,
                 outline=WHITE24, outline_width=1)
    # Draw a dog piece in preview
    cell_s = np_size // 4
    dog_shape = [[0,0],[1,0],[2,0],[2,1]]
    for (pr, pc) in dog_shape:
        cx0 = rx + cell_s//2 + pc*cell_s
        cy0 = np_y + 6 + pr*cell_s
        rounded_rect(draw, cx0, cy0, cx0+cell_s-4, cy0+cell_s-4, 4, DOG_C)
        draw.line([(cx0+2, cy0+2), (cx0+cell_s-6, cy0+2)], fill=(255,255,255,80), width=2)

    # Bombs section
    bomb_y = np_y + np_size + 32
    draw.text((rx, bomb_y), 'BOMBS', font=font(28), fill=WHITE54)

    # Grenade button
    gy = bomb_y + 42
    rounded_rect(draw, rx, gy, rx+rw, gy+72, 12, CARD_BG, outline=WHITE24)
    center_text(draw, 'GRENADE', rx + rw//2, gy+18, font(26), WHITE70)
    center_text(draw, '3x3', rx + rw//2, gy+44, font(22), WHITE54)

    # Bomb button (available, shown in accent)
    by2 = gy + 90
    rounded_rect(draw, rx, by2, rx+rw, by2+72, 12, ACCENT)
    center_text(draw, 'BOMB', rx + rw//2, by2+18, font(26), WHITE)
    center_text(draw, '5x5', rx + rw//2, by2+44, font(22), (200,180,255))

    # Menu button (top left)
    rounded_rect(draw, 40, 36, 160, 76, 16, (255,255,255,18))
    draw.text((58, 44), 'Menu', font=font(28), fill=WHITE54)

    # Caption banner at bottom
    banner_y = H - 180
    img2 = img.copy()
    bd = ImageDraw.Draw(img2)
    bd.rectangle([0, banner_y, W, H], fill=(0,0,0,0))
    # gradient-ish overlay
    for dy in range(120):
        alpha = int(220 * dy / 120)
        draw.line([(0, banner_y + dy), (W, banner_y + dy)],
                  fill=(15, 52, 96, alpha), width=1)

    center_text(draw, '7 unique animal pieces', W//2, banner_y + 16, font(42), WHITE)
    center_text(draw, 'Drop. Stack. Clear!', W//2, banner_y + 72, font(34), WHITE70)

    img.save(os.path.join(OUT_DIR, 'screenshot_2_gameplay.png'))
    print('screenshot_2_gameplay.png saved')

# ── SCREENSHOT 3: Bomb in action ───────────────────────────────────────────────
def screenshot_bombs():
    img = Image.new('RGB', (W, H), BG)
    draw = ImageDraw.Draw(img)

    draw_statusbar(draw)

    # Top bar
    bar_y = 90
    for i, (label, value) in enumerate([('SCORE', '22 310'), ('LEVEL', '4'), ('LINES', '18')]):
        cx = 180 + i * 360
        draw.text((cx - draw.textbbox((0,0), label, font=font(26))[2]//2, bar_y),
                  label, font=font(26), fill=WHITE54)
        draw.text((cx - draw.textbbox((0,0), value, font=font(52))[2]//2, bar_y+28),
                  value, font=font(52), fill=WHITE)

    # Game board (fuller, bomb just cleared rows)
    board_x, board_y, board_w = 24, 200, 680
    board_h = board_w * 2
    cells = make_board_cells()
    # Add some explosion-cleared cells (show cleared area in center)
    for r in range(10, 15):
        for c in range(3, 7):
            cells[r][c] = None
    draw_board(img, board_x, board_y, board_w, board_h, cells)

    # Draw bomb blast radius highlight on board
    bx_cell = board_x + 3 * (board_w // BOARD_COLS)
    by_cell = board_y + 10 * (board_h // BOARD_ROWS)
    blast_w = 4 * (board_w // BOARD_COLS)
    blast_h = 5 * (board_h // BOARD_ROWS)

    overlay = Image.new('RGBA', (W, H), (0, 0, 0, 0))
    od = ImageDraw.Draw(overlay)
    od.rounded_rectangle([bx_cell, by_cell, bx_cell+blast_w, by_cell+blast_h],
                         radius=8, fill=(255, 120, 0, 55),
                         outline=(255, 180, 0), width=3)
    img = Image.alpha_composite(img.convert('RGBA'), overlay).convert('RGB')
    draw = ImageDraw.Draw(img)

    # Right panel
    rx = board_x + board_w + 24
    rw = W - rx - 24

    draw.text((rx, board_y + 10), 'NEXT', font=font(32), fill=WHITE54)
    np_size = rw
    np_y = board_y + 54
    rounded_rect(draw, rx, np_y, rx+np_size, np_y+np_size, 10, CARD_BG,
                 outline=WHITE24, outline_width=1)
    # Snake in preview
    cell_s = np_size // 4
    for (pr, pc) in [[0,1],[0,2],[1,0],[1,1]]:
        cx0 = rx + 8 + pc*cell_s
        cy0 = np_y + np_size//4 + pr*cell_s
        rounded_rect(draw, cx0, cy0, cx0+cell_s-4, cy0+cell_s-4, 4, SNAKE_C)

    bomb_y = np_y + np_size + 32
    draw.text((rx, bomb_y), 'BOMBS', font=font(28), fill=WHITE54)
    gy = bomb_y + 42
    rounded_rect(draw, rx, gy, rx+rw, gy+72, 12, CARD_BG, outline=WHITE24)
    center_text(draw, 'GRENADE', rx + rw//2, gy+18, font(26), WHITE70)
    center_text(draw, '3x3', rx + rw//2, gy+44, font(22), WHITE54)
    by2 = gy + 90
    rounded_rect(draw, rx, by2, rx+rw, by2+72, 12, (40, 30, 60), outline=WHITE24)
    center_text(draw, 'BOMB', rx + rw//2, by2+18, font(26), WHITE54)
    center_text(draw, 'used', rx + rw//2, by2+44, font(22), WHITE54)

    rounded_rect(draw, 40, 36, 160, 76, 16, (255,255,255,18))
    draw.text((58, 44), 'Menu', font=font(28), fill=WHITE54)

    # Banner
    banner_y = H - 180
    for dy in range(120):
        alpha = int(220 * dy / 120)
        draw.line([(0, banner_y + dy), (W, banner_y + dy)],
                  fill=(15, 52, 96, alpha), width=1)
    center_text(draw, 'Bombs blast a 5x5 area', W//2, banner_y + 16, font(42), WHITE)
    center_text(draw, 'Clear the board in one move!', W//2, banner_y + 72, font(34), WHITE70)

    img.save(os.path.join(OUT_DIR, 'screenshot_3_bombs.png'))
    print('screenshot_3_bombs.png saved')

# ── SCREENSHOT 4: Leaderboard / global ranking ────────────────────────────────
def screenshot_leaderboard():
    img = Image.new('RGB', (W, H), BG)
    draw = ImageDraw.Draw(img)

    draw_statusbar(draw)

    # Title
    center_text(draw, 'BEASTBLOCKS', W//2, 100, font(60), WHITE)

    # Global leaderboard card
    lx, lw = 60, W - 120
    ly = 200
    rounded_rect(draw, lx, ly, lx+lw, ly+1440, 20, CARD_BG,
                 outline=ACCENT, outline_width=2)

    center_text(draw, 'Global Leaderboard', W//2, ly+28, font(44), WHITE)

    # Tabs
    for i, (label, active) in enumerate([('All Time', True), ('This Week', False)]):
        tw = 220
        tx = W//2 - tw - 16 + i*(tw+32)
        tab_bg = ACCENT if active else CARD_BG
        tab_border = ACCENT if active else WHITE24
        rounded_rect(draw, tx, ly+94, tx+tw, ly+144, 25, tab_bg,
                     outline=tab_border, outline_width=2)
        center_text(draw, label, tx+tw//2, ly+106, font(32), WHITE if active else WHITE54)

    # Divider
    draw.line([(lx+30, ly+162), (lx+lw-30, ly+162)], fill=WHITE24, width=1)

    # Leaderboard entries (all time)
    lb_data = [
        ('#1',  'TigerKing',    'SE', '47 320', True),
        ('#2',  'BeastMaster',  'US', '42 100', False),
        ('#3',  'WildCard',     'DE', '38 750', False),
        ('#4',  'SnakeBoss',    'GB', '31 200', False),
        ('#5',  'CatLady99',    'JP', '29 880', False),
        ('#6',  'DoggoFan',     'FR', '27 440', False),
        ('#7',  'CrocHunter',   'AU', '24 110', False),
        ('#8',  'EagleEye',     'CA', '21 900', False),
        ('#9',  'TurtlePro',    'NL', '19 500', False),
        ('#10', 'BomberKing',   'BR', '17 200', False),
    ]

    medals = {0: (255,215,0), 1: (192,192,192), 2: (205,127,50)}

    for i, (rank, name, country, score, _) in enumerate(lb_data):
        ey = ly + 180 + i * 110
        row_bg = (30, 40, 70) if i % 2 == 0 else CARD_BG
        rounded_rect(draw, lx+16, ey, lx+lw-16, ey+94, 12, row_bg)

        rc = medals.get(i, WHITE54)
        nc = medals.get(i, WHITE)
        sc = medals.get(i, WHITE70)

        # Rank badge
        rounded_rect(draw, lx+30, ey+20, lx+100, ey+74, 8, (40,40,60))
        center_text(draw, rank, lx+65, ey+30, font(30), rc)

        draw.text((lx+120, ey+20), name, font=font(40), fill=nc)
        draw.text((lx+120, ey+62), country, font=font(28), fill=WHITE54)

        score_w = draw.textbbox((0,0), score, font=font(38))[2]
        draw.text((lx+lw-score_w-50, ey+30), score, font=font(38), fill=sc)
        pts_w = draw.textbbox((0,0), 'pts', font=font(24))[2]
        draw.text((lx+lw-pts_w-46, ey+74), 'pts', font=font(24), fill=WHITE54)

    # User rank at bottom (you = rank 12)
    sep_y = ly + 180 + 10*110 + 10
    draw.line([(lx+30, sep_y), (lx+lw-30, sep_y)], fill=WHITE24, width=1)
    user_y = sep_y + 18
    rounded_rect(draw, lx+16, user_y, lx+lw-16, user_y+94, 12, (50,40,80),
                 outline=ACCENT, outline_width=2)
    center_text(draw, '#12', lx+65, user_y+30, font(30), GOLD)
    draw.text((lx+120, user_y+20), 'You (AlskamiPlayer)', font=font(40), fill=GOLD)
    draw.text((lx+120, user_y+62), 'SE', font=font(28), fill=(200,170,255))
    s = '14 800'
    sw = draw.textbbox((0,0), s, font=font(38))[2]
    draw.text((lx+lw-sw-50, user_y+30), s, font=font(38), fill=GOLD)

    img.save(os.path.join(OUT_DIR, 'screenshot_4_leaderboard.png'))
    print('screenshot_4_leaderboard.png saved')

# ── Run all ───────────────────────────────────────────────────────────────────
screenshot_menu()
screenshot_gameplay()
screenshot_bombs()
screenshot_leaderboard()
print('All screenshots saved to assets/store/')
