#!/usr/bin/env python3
"""Draws the 630 by 500 itch.io cover from the game's own tile sheets and font.

Run from the repo root:  python3 tools/make_cover.py
Writes ITCH_COVER.png. Needs Pillow.
"""
from PIL import Image

A = "assets/"
SHEETS = {n: Image.open(A + n + ".png").convert("RGBA") for n in ("natural", "civilized", "creatures", "people", "font")}

PAPER, GRASS, ROAD, TREE, HOUSE, BARN, CAR, TEXT = (
    0x2B0A6E, 0x00C040, 0xFFD800, 0xFF00A0, 0x00E0FF, 0xFF7000, 0xFFFFFF, 0xFFFF60)


def rgb(v):
    return ((v >> 16) & 255, (v >> 8) & 255, v & 255, 255)


W, H = 630, 500
img = Image.new("RGBA", (W, H), rgb(PAPER))


def piece(sheet, sx, sy, sw, sh, dx, dy, dw, dh, color):
    """Copies a piece of a sheet, tinted, scaled with nearest neighbour."""
    crop = SHEETS[sheet].crop((sx, sy, sx + sw, sy + sh))
    px = crop.load()
    tinted = Image.new("RGBA", crop.size, (0, 0, 0, 0))
    tp = tinted.load()
    c = rgb(color)
    for y in range(sh):
        for x in range(sw):
            if px[x, y][3] > 0:
                tp[x, y] = c
    img.alpha_composite(tinted.resize((dw, dh), Image.NEAREST), (dx, dy))


def tile(sheet, col, row, dx, dy, size, color):
    piece(sheet, col * 10, row * 10, 10, 10, dx, dy, size, size, color)


def text(s, x, y, scale, color):
    for ch in s:
        c = ord(ch)
        piece("font", (c % 16) * 6, (c // 16) * 8, 6, 8, x, y, 6 * scale, 8 * scale, color)
        x += 6 * scale


def centred(s, y, scale, color):
    text(s, (W - len(s) * 6 * scale) // 2, y, scale, color)


T = 40  # one 10 px tile drawn at 4x

# Grass with a few wrong-coloured tiles, like a ransom note.
for ty in range(5, 13):  # rows 5 to 12 (y = 200 to 520)
    for tx in range(0, 16):
        bad = (tx * 7 + ty * 13) % 11 == 0
        tile("natural", 1, 5, tx * T, ty * T, T, BARN if bad else GRASS)

# Scenery: trees, an oak, a house and a barn arch, all at slightly wrong sizes.
for tx, ty in ((1, 6), (13, 6), (5, 11), (14, 11), (9, 5)):
    tile("natural", 24, 2, tx * T, ty * T, T, TREE)
tile("natural", 1, 18, 2 * T - 8, 7 * T - 20, 56, TREE)
tile("civilized", 2, 1, 13 * T - 10, 6 * T - 6, 64, HOUSE)
tile("civilized", 17, 2, 3 * T - 20, 6 * T - 40, 96, BARN)

# The road, straight across.
for tx in range(0, 16):
    tile("natural", 9, 3, tx * T, 8 * T, T, ROAD)

# The car (the game draws it in code; this is the same shape, facing east).
cx, cy = 3 * T, 8 * T
img.alpha_composite(Image.new("RGBA", (8 * 4, 6 * 4), rgb(CAR)), (cx + 4, cy + 8))
img.alpha_composite(Image.new("RGBA", (2 * 4, 4 * 4), rgb(BARN)), (cx - 4, cy + 12))
img.alpha_composite(Image.new("RGBA", (1 * 4, 2 * 4), rgb(HOUSE)), (cx + 36, cy + 16))
img.alpha_composite(Image.new("RGBA", (2 * 4, 1 * 4), rgb(TREE)), (cx + 8, cy + 4))
img.alpha_composite(Image.new("RGBA", (2 * 4, 1 * 4), rgb(TREE)), (cx + 24, cy + 36))

# The cow, large, standing on the road where it should not be, and Grandma.
piece("creatures", 60, 90, 10, 10, 10 * T - 20, 6 * T + 6, 130, 130, TEXT)
piece("people", 0, 20, 10, 10, 12 * T + 10, 7 * T + 30, 110, 110, HOUSE)

# Title.
centred("TURN LEFT", 16, 10, TEXT)
centred("AT THE COW", 100, 10, TEXT)
centred("A WORST GAME JAM ENTRY", 184, 2, BARN)

img.convert("RGB").save("ITCH_COVER.png")
print("wrote ITCH_COVER.png", img.size)
