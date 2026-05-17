"""Generate Play Store graphics from the existing app icon.

Outputs:
  assets/store/hi_res_icon_512.png      — 512x512 hi-res icon
  assets/store/feature_graphic_1024x500.png — 1024x500 feature graphic
"""
import os
from PIL import Image, ImageDraw, ImageFont

SRC_ICON = os.path.join(os.path.dirname(__file__), '..', 'assets', 'icon', 'app_icon.png')
OUT_DIR   = os.path.join(os.path.dirname(__file__), '..', 'assets', 'store')
os.makedirs(OUT_DIR, exist_ok=True)

icon_src = Image.open(SRC_ICON).convert('RGBA')

# ── Hi-res icon 512x512 ──────────────────────────────────────────────────────
icon_512 = icon_src.resize((512, 512), Image.LANCZOS)
icon_512.save(os.path.join(OUT_DIR, 'hi_res_icon_512.png'))
print('hi_res_icon_512.png saved')

# ── Feature graphic 1024x500 ─────────────────────────────────────────────────
W, H = 1024, 500
BG = (15, 25, 35)

canvas = Image.new('RGBA', (W, H), BG)

# Icon on the left
icon_fg = icon_src.resize((360, 360), Image.LANCZOS)
icon_x = 80
icon_y = (H - 360) // 2
canvas.paste(icon_fg, (icon_x, icon_y), icon_fg)

draw = ImageDraw.Draw(canvas)

# Load a system font; fall back to PIL default if unavailable
font_path = None
for path in [
    '/System/Library/Fonts/Helvetica.ttc',
    '/System/Library/Fonts/SFNS.ttf',
    '/Library/Fonts/Arial.ttf',
]:
    if os.path.exists(path):
        font_path = path
        break

text_x       = icon_x + 360 + 24
right_margin = 24
max_text_w   = W - text_x - right_margin  # available width for text
title_y      = H // 2 - 70

def fit_font(text, start_size):
    """Return largest truetype font (or default) where text fits max_text_w."""
    size = start_size
    while size > 14:
        try:
            f = ImageFont.truetype(font_path, size) if font_path else ImageFont.load_default()
        except Exception:
            return ImageFont.load_default()
        if draw.textlength(text, font=f) <= max_text_w:
            return f
        size -= 1
    return ImageFont.load_default()

TITLE   = 'BeastBlocks'
SUB     = 'The block puzzle with a wild twist'
TAG     = '7 animals  \u00b7  Bombs  \u00b7  Global leaderboard'

font_title = fit_font(TITLE, 80)
font_sub   = fit_font(SUB,   32)
font_tag   = fit_font(TAG,   27)

draw.text((text_x, title_y),       TITLE, fill=(255, 255, 255),   font=font_title)
draw.text((text_x, title_y + 100), SUB,   fill=(180, 190, 210),   font=font_sub)
draw.text((text_x, title_y + 148), TAG,   fill=(140, 160, 180),   font=font_tag)

# Save as RGB PNG
out = Image.new('RGB', (W, H), BG)
out.paste(canvas, mask=canvas.split()[3])
out.save(os.path.join(OUT_DIR, 'feature_graphic_1024x500.png'))
print('feature_graphic_1024x500.png saved')
