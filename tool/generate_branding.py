from __future__ import annotations

from pathlib import Path
from PIL import Image, ImageDraw

DARK = (8, 9, 10, 255)
GOLD = (244, 200, 74, 255)
GOLD_LIGHT = (255, 229, 138, 255)
GOLD_DARK = (185, 122, 12, 255)


def _pt(size: int, x: float, y: float) -> tuple[int, int]:
    return round(size * x / 64), round(size * y / 64)


def draw_finora_icon(size: int) -> Image.Image:
    # Render em resolução maior para manter bordas suaves em tamanhos pequenos.
    render_size = size * 4
    image = Image.new("RGBA", (render_size, render_size), DARK)
    draw = ImageDraw.Draw(image)

    def p(x: float, y: float) -> tuple[int, int]:
        return _pt(render_size, x, y)

    # Moldura externa.
    margin = round(render_size * 2 / 64)
    radius = round(render_size * 14 / 64)
    border_width = max(2, round(render_size * 2.2 / 64))
    draw.rounded_rectangle(
        [margin, margin, render_size - margin, render_size - margin],
        radius=radius,
        fill=DARK,
        outline=GOLD,
        width=border_width,
    )

    # F estilizado.
    f_points = [
        p(17, 14),
        p(47, 14),
        p(44, 23),
        p(28, 23),
        p(27, 29),
        p(39, 29),
        p(35, 37),
        p(25, 37),
        p(15, 45),
    ]
    draw.polygon(f_points, fill=GOLD_LIGHT)

    # Sombra dourada discreta na base do monograma.
    draw.line([p(15.5, 44.5), p(25.5, 36.7), p(35.2, 36.7)], fill=GOLD_DARK, width=max(1, render_size // 128))

    # Barras financeiras.
    for x, y, w, h in [
        (17, 49, 7, 6),
        (27, 44, 7, 11),
        (37, 39, 7, 16),
    ]:
        box = [p(x, y), p(x + w, y + h)]
        draw.rounded_rectangle(box, radius=max(2, render_size // 96), fill=GOLD)

    # Linha de tendência e seta.
    trend = [p(15, 47), p(27, 37), p(36, 41), p(50, 29)]
    draw.line(
        trend,
        fill=GOLD,
        width=max(4, round(render_size * 2.5 / 64)),
        joint="curve",
    )
    arrow = [p(46, 29), p(52, 27), p(51, 33)]
    draw.polygon(arrow, fill=GOLD_LIGHT)

    return image.resize((size, size), Image.Resampling.LANCZOS)


def generate_android() -> None:
    root = Path("android/app/src/main/res")
    sizes = {
        "mipmap-mdpi": 48,
        "mipmap-hdpi": 72,
        "mipmap-xhdpi": 96,
        "mipmap-xxhdpi": 144,
        "mipmap-xxxhdpi": 192,
    }
    for folder, size in sizes.items():
        target = root / folder / "ic_launcher.png"
        target.parent.mkdir(parents=True, exist_ok=True)
        draw_finora_icon(size).convert("RGB").save(target, "PNG", optimize=True)


def generate_windows() -> None:
    target = Path("windows/runner/resources/app_icon.ico")
    if not target.parent.exists():
        return
    image = draw_finora_icon(256).convert("RGBA")
    image.save(
        target,
        format="ICO",
        sizes=[(16, 16), (24, 24), (32, 32), (48, 48), (64, 64), (128, 128), (256, 256)],
    )


def generate_preview() -> None:
    target = Path("build/branding/finora_icon.png")
    target.parent.mkdir(parents=True, exist_ok=True)
    draw_finora_icon(512).convert("RGB").save(target, "PNG", optimize=True)


if __name__ == "__main__":
    generate_android()
    generate_windows()
    generate_preview()
    print("Identidade visual Finora aplicada.")
