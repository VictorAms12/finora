from __future__ import annotations

from pathlib import Path
from PIL import Image, ImageDraw

BLACK = (5, 5, 6, 255)
WHITE = (248, 248, 248, 255)
SOFT_WHITE = (220, 220, 222, 255)
GRAY = (150, 150, 154, 255)


def _pt(size: int, x: float, y: float) -> tuple[int, int]:
    return round(size * x / 64), round(size * y / 64)


def draw_finora_icon(size: int) -> Image.Image:
    # Render em resolução maior para manter bordas suaves em tamanhos pequenos.
    render_size = size * 4
    image = Image.new("RGBA", (render_size, render_size), BLACK)
    draw = ImageDraw.Draw(image)

    def p(x: float, y: float) -> tuple[int, int]:
        return _pt(render_size, x, y)

    # Moldura branca sobre fundo preto: alta legibilidade em ícones pequenos.
    margin = round(render_size * 2 / 64)
    radius = round(render_size * 14 / 64)
    border_width = max(2, round(render_size * 2.2 / 64))
    draw.rounded_rectangle(
        [margin, margin, render_size - margin, render_size - margin],
        radius=radius,
        fill=BLACK,
        outline=WHITE,
        width=border_width,
    )

    # F estilizado do Finora.
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
    draw.polygon(f_points, fill=WHITE)

    # Barras financeiras em branco/cinza para reforçar leitura monocromática.
    for x, y, w, h, color in [
        (17, 49, 7, 6, SOFT_WHITE),
        (27, 44, 7, 11, WHITE),
        (37, 39, 7, 16, SOFT_WHITE),
    ]:
        box = [p(x, y), p(x + w, y + h)]
        draw.rounded_rectangle(
            box,
            radius=max(2, render_size // 96),
            fill=color,
        )

    # Linha de tendência e seta: crescimento/planejamento financeiro.
    trend = [p(15, 47), p(27, 37), p(36, 41), p(50, 29)]
    draw.line(
        trend,
        fill=WHITE,
        width=max(4, round(render_size * 2.5 / 64)),
        joint="curve",
    )
    arrow = [p(46, 29), p(52, 27), p(51, 33)]
    draw.polygon(arrow, fill=WHITE)

    # Pequeno recorte cinza cria profundidade sem abandonar o preto e branco.
    draw.line(
        [p(15.5, 44.5), p(25.5, 36.7), p(35.2, 36.7)],
        fill=GRAY,
        width=max(1, render_size // 128),
    )

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
        draw_finora_icon(size).convert("RGB").save(
            target,
            "PNG",
            optimize=True,
        )


def generate_windows() -> None:
    target = Path("windows/runner/resources/app_icon.ico")
    if not target.parent.exists():
        return
    image = draw_finora_icon(256).convert("RGBA")
    image.save(
        target,
        format="ICO",
        sizes=[
            (16, 16),
            (24, 24),
            (32, 32),
            (48, 48),
            (64, 64),
            (128, 128),
            (256, 256),
        ],
    )


def generate_preview() -> None:
    target = Path("build/branding/finora_icon.png")
    target.parent.mkdir(parents=True, exist_ok=True)
    draw_finora_icon(512).convert("RGB").save(
        target,
        "PNG",
        optimize=True,
    )


if __name__ == "__main__":
    generate_android()
    generate_windows()
    generate_preview()
    print("Identidade visual Finora preto e branco aplicada.")
