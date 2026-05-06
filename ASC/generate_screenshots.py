#!/usr/bin/env python3
"""Generate App Store Connect marketing screenshots.

Creates 8 × 4 languages = 32 images at 1320×2868px (iPhone 16 Pro Max).
Each image: gradient background + localized caption + rounded screenshot with shadow.

Usage:
    pip3 install Pillow
    python3 ASC/generate_screenshots.py
"""

import math
from pathlib import Path

from PIL import Image, ImageDraw, ImageFilter, ImageFont

# --- Configuration ---

CANVAS_W, CANVAS_H = 1320, 2868
SCRIPT_DIR = Path(__file__).parent
SCREENSHOTS_DIR = SCRIPT_DIR / "screenshots"
OUTPUT_DIR = SCRIPT_DIR / "output"

# Colors (from Color+Theme.swift)
BG_COLOR = (10, 8, 23)         # #0A0817
ACCENT = (188, 130, 243)       # #BC82F3
DEEP_PURPLE = (170, 110, 238)  # #AA6EEE
TEXT_COLOR = (255, 255, 255)   # White

# Layout
CAPTION_Y_CENTER = 290
SCREENSHOT_TOP = 570
SCREENSHOT_WIDTH = 1040
CORNER_RADIUS = 48
BORDER_WIDTH = 3
BORDER_COLOR = (40, 35, 60)

# Shadow
SHADOW_BLUR = 50
SHADOW_OPACITY = 100
SHADOW_OFFSET_Y = 15

# Font
FONT_PATH = "/Library/Fonts/SF-Pro-Display-Bold.otf"
FALLBACK_FONT = "/Library/Fonts/SF-Pro-Display-Semibold.otf"
FONT_SIZE = 74
LINE_SPACING = 20

# Screenshot filenames (must match ASC/screenshots/)
SCREENSHOTS = [
    "01_camera_scan.png",
    "02_ai_analysis.png",
    "03_result_score.png",
    "04_mood_board.png",
    "05_radar_chart.png",
    "06_result_personality.png",
    "07_history.png",
    "08_profile.png",
]

# Localized captions: 8 screenshots × 4 languages
LOCALES = {
    "en-US": [
        "Snap any room",
        "AI analyzes in seconds",
        "Get your design score",
        "Personalized mood board",
        "5 detailed sub-scores",
        "What your room\nsays about you",
        "Track your progress",
        "Your design profile",
    ],
    "fr-FR": [
        "Scanne ta pièce",
        "L'IA analyse en secondes",
        "Obtiens ton score déco",
        "Mood board personnalisé",
        "5 sous-scores détaillés",
        "Ce que ta pièce\ndit de toi",
        "Suis ta progression",
        "Ton profil design",
    ],
    "de-DE": [
        "Fotografiere jeden Raum",
        "KI analysiert in Sekunden",
        "Dein Design-Score",
        "Dein persönliches\nMood Board",
        "5 detaillierte Sub-Scores",
        "Was dein Zimmer\nüber dich verrät",
        "Verfolge deinen\nFortschritt",
        "Dein Design-Profil",
    ],
    "es-ES": [
        "Escanea cualquier\nhabitación",
        "La IA analiza en segundos",
        "Tu puntaje de diseño",
        "Mood board personalizado",
        "5 sub-puntajes detallados",
        "Lo que tu habitación\ndice de ti",
        "Sigue tu progreso",
        "Tu perfil de diseño",
    ],
}


def lerp_color(c1: tuple, c2: tuple, t: float) -> tuple:
    """Linear interpolation between two RGB colors."""
    return tuple(int(c1[i] + (c2[i] - c1[i]) * t) for i in range(3))


def create_gradient_background() -> Image.Image:
    """Create dark background with a soft purple radial glow."""
    img = Image.new("RGB", (CANVAS_W, CANVAS_H), BG_COLOR)

    # Radial glow: soft ellipse centered upper-third
    glow = Image.new("RGBA", (CANVAS_W, CANVAS_H), (0, 0, 0, 0))
    draw = ImageDraw.Draw(glow)

    cx, cy = CANVAS_W // 2, int(CANVAS_H * 0.30)
    rx, ry = 700, 900  # ellipse radii

    steps = 120
    for i in range(steps, 0, -1):
        t = i / steps  # 1.0 = edge, 0.0 = center
        # Smooth falloff using cosine ease
        alpha = int((1 - t) * 45 * (0.5 + 0.5 * math.cos(math.pi * t)))
        color = DEEP_PURPLE + (alpha,)
        ex = int(rx * t)
        ey = int(ry * t)
        draw.ellipse(
            [cx - ex, cy - ey, cx + ex, cy + ey],
            fill=color,
        )

    img.paste(Image.alpha_composite(Image.new("RGBA", img.size, BG_COLOR + (255,)), glow).convert("RGB"))
    return img


def round_corners_mask(size: tuple, radius: int) -> Image.Image:
    """Create an antialiased rounded-rectangle alpha mask at 2x then downscale."""
    scale = 2
    big = Image.new("L", (size[0] * scale, size[1] * scale), 0)
    draw = ImageDraw.Draw(big)
    draw.rounded_rectangle(
        [0, 0, big.width, big.height],
        radius=radius * scale,
        fill=255,
    )
    return big.resize(size, Image.LANCZOS)


def create_shadow(width: int, height: int) -> Image.Image:
    """Create a blurred drop shadow matching the screenshot shape."""
    pad = SHADOW_BLUR * 2
    shadow = Image.new("RGBA", (width + pad, height + pad), (0, 0, 0, 0))
    draw = ImageDraw.Draw(shadow)
    draw.rounded_rectangle(
        [pad // 2, pad // 2, width + pad // 2, height + pad // 2],
        radius=CORNER_RADIUS,
        fill=(0, 0, 0, SHADOW_OPACITY),
    )
    return shadow.filter(ImageFilter.GaussianBlur(SHADOW_BLUR))


def draw_caption(canvas: Image.Image, caption: str, font: ImageFont.FreeTypeFont):
    """Draw centered, multi-line caption text."""
    draw = ImageDraw.Draw(canvas)
    lines = caption.split("\n")

    # Measure total height
    line_heights = []
    line_widths = []
    for line in lines:
        bbox = draw.textbbox((0, 0), line, font=font)
        line_widths.append(bbox[2] - bbox[0])
        line_heights.append(bbox[3] - bbox[1])

    total_h = sum(line_heights) + LINE_SPACING * (len(lines) - 1)
    y = CAPTION_Y_CENTER - total_h // 2

    for i, line in enumerate(lines):
        x = (CANVAS_W - line_widths[i]) // 2
        draw.text((x, y), line, fill=TEXT_COLOR, font=font)
        y += line_heights[i] + LINE_SPACING


def compose_screenshot(
    bg: Image.Image,
    screenshot_path: Path,
    caption: str,
    font: ImageFont.FreeTypeFont,
    output_path: Path,
):
    """Compose one final marketing screenshot."""
    canvas = bg.copy().convert("RGBA")

    # --- Screenshot ---
    screenshot = Image.open(screenshot_path).convert("RGBA")
    aspect = screenshot.height / screenshot.width
    sc_w = SCREENSHOT_WIDTH
    sc_h = int(sc_w * aspect)
    screenshot = screenshot.resize((sc_w, sc_h), Image.LANCZOS)

    # Rounded corners
    mask = round_corners_mask((sc_w, sc_h), CORNER_RADIUS)
    screenshot.putalpha(mask)

    # Thin border
    border_layer = Image.new("RGBA", (sc_w, sc_h), (0, 0, 0, 0))
    border_draw = ImageDraw.Draw(border_layer)
    border_draw.rounded_rectangle(
        [0, 0, sc_w - 1, sc_h - 1],
        radius=CORNER_RADIUS,
        outline=BORDER_COLOR + (180,),
        width=BORDER_WIDTH,
    )

    # Position centered
    sc_x = (CANVAS_W - sc_w) // 2
    sc_y = SCREENSHOT_TOP

    # Shadow
    shadow = create_shadow(sc_w, sc_h)
    shadow_x = sc_x - SHADOW_BLUR + 0
    shadow_y = sc_y - SHADOW_BLUR + SHADOW_OFFSET_Y
    canvas.paste(shadow, (shadow_x, shadow_y), shadow)

    # Paste screenshot + border
    canvas.paste(screenshot, (sc_x, sc_y), screenshot)
    canvas.paste(border_layer, (sc_x, sc_y), border_layer)

    # --- Bottom fade (blend screenshot bottom into background) ---
    fade_h = 120
    fade_y = CANVAS_H - fade_h
    fade = Image.new("RGBA", (CANVAS_W, fade_h), (0, 0, 0, 0))
    fade_draw = ImageDraw.Draw(fade)
    for row in range(fade_h):
        alpha = int(255 * (row / fade_h))
        fade_draw.line([(0, row), (CANVAS_W, row)], fill=BG_COLOR + (alpha,))
    canvas.paste(fade, (0, fade_y), fade)

    # --- Caption ---
    draw_caption(canvas, caption, font)

    # --- Save as RGB PNG ---
    final = Image.new("RGB", (CANVAS_W, CANVAS_H), BG_COLOR)
    final.paste(canvas, (0, 0), canvas)
    final.save(output_path, "PNG", optimize=True)


def main():
    # Load font
    font = None
    for path in [FONT_PATH, FALLBACK_FONT]:
        try:
            font = ImageFont.truetype(path, FONT_SIZE)
            print(f"Font: {Path(path).name}")
            break
        except OSError:
            continue
    if font is None:
        print("WARNING: SF Pro Display not found, using default font")
        font = ImageFont.load_default()

    # Pre-render shared gradient background
    print("Generating gradient background...")
    bg = create_gradient_background()

    total = len(LOCALES) * len(SCREENSHOTS)
    count = 0

    for locale, captions in LOCALES.items():
        locale_dir = OUTPUT_DIR / locale
        locale_dir.mkdir(parents=True, exist_ok=True)

        for screenshot_file, caption in zip(SCREENSHOTS, captions):
            screenshot_path = SCREENSHOTS_DIR / screenshot_file
            if not screenshot_path.exists():
                print(f"  SKIP (missing): {screenshot_path}")
                continue

            output_path = locale_dir / screenshot_file
            compose_screenshot(bg, screenshot_path, caption, font, output_path)
            count += 1
            print(f"  [{count:2d}/{total}] {locale}/{screenshot_file}")

    print(f"\nDone — {count} screenshots generated in {OUTPUT_DIR}/")


if __name__ == "__main__":
    main()
