"""Sinh bộ icon trạng thái cho khay hệ thống, mang dấu hiệu DataDrive.

Icon khay phải nói lên *trạng thái đồng bộ* chỉ trong 16 pixel, nên chỉ vẽ logo thôi là không đủ.
Cách làm ở đây giống bản gốc: hình nhận diện của sản phẩm, cộng một huy hiệu nhỏ ở góc mang màu
và ký hiệu của trạng thái. Khác ở chỗ hình nhận diện là chữ DD lồng nhau của DataDrive chứ không
phải đĩa tròn xanh của Nextcloud.

Chạy lại sau khi đổi logo hoặc bảng màu:
    python packaging/craft/make-state-icons.py
"""

from pathlib import Path

REPO = Path(__file__).resolve().parents[2]

# src/gui/CMakeLists.txt:16 chi tro theme.qrc vao thu muc con "nextcloud/" khi APPLICATION_NAME
# van la cua ban goc. Ban da doi thuong hieu doc icon thang tu theme/colored/, nen icon
# DataDrive phai nam o day chu khong phai trong thu muc con.
OUT_DIR = REPO / "theme" / "colored"

# Bảng màu lấy từ Logo/Logo/datadrive-icon-simple.svg
BRAND_LIGHT = "#2DD4FF"
BRAND_MID = "#0A93E0"
BRAND_DARK = "#14336E"
BRAND_INNER_LIGHT = "#7DEFFF"
BRAND_INNER_DARK = "#18C0E8"

INACTIVE_LIGHT = "#B8B8B8"
INACTIVE_MID = "#949494"
INACTIVE_DARK = "#6E6E6E"

# Màu trạng thái giữ nguyên như bản gốc: người dùng đã quen đỏ là lỗi, vàng là cảnh báo.
STATUS_OK = "#2D7B41"
STATUS_ERROR = "#DB0606"
STATUS_WARNING = "#A37200"
STATUS_NEUTRAL = "#949494"
STATUS_SYNC = "#0A93E0"

# Chữ DD chiếm phần trên bên trái, chừa góc dưới phải cho huy hiệu.
MARK_SCALE = 0.101
MARK_OFFSET = (0.15, 0.1)

BADGE_CENTRE = (12.1, 12.1)
BADGE_RADIUS = 3.6
BADGE_RING = 0.8


def mark(active: bool) -> str:
    """Chữ DD lồng nhau, tô gradient thương hiệu hoặc xám khi không hoạt động."""
    outer = "url(#markOuter)" if active else "url(#markOuterOff)"
    inner = "url(#markInner)" if active else "url(#markInnerOff)"
    dx, dy = MARK_OFFSET
    return (
        f'<g transform="translate({dx},{dy}) scale({MARK_SCALE})" fill="none" '
        'stroke-linejoin="round" stroke-linecap="round">'
        f'<path d="M 22 36 H 47.5 A 18 18 0 0 1 47.5 72 H 22 Z" stroke="{inner}" stroke-width="11"/>'
        f'<path d="M 20.5 14 H 47.5 A 40 40 0 0 1 47.5 94 H 20.5 Z" stroke="{outer}" stroke-width="14"/>'
        "</g>"
    )


def gradients() -> str:
    return (
        "<defs>"
        '<linearGradient id="markOuter" gradientUnits="userSpaceOnUse" x1="1" y1="1" x2="13" y2="14">'
        f'<stop offset="0" stop-color="{BRAND_LIGHT}"/>'
        f'<stop offset=".48" stop-color="{BRAND_MID}"/>'
        f'<stop offset="1" stop-color="{BRAND_DARK}"/>'
        "</linearGradient>"
        '<linearGradient id="markInner" gradientUnits="userSpaceOnUse" x1="2" y1="4" x2="9" y2="11">'
        f'<stop offset="0" stop-color="{BRAND_INNER_LIGHT}"/>'
        f'<stop offset="1" stop-color="{BRAND_INNER_DARK}"/>'
        "</linearGradient>"
        '<linearGradient id="markOuterOff" gradientUnits="userSpaceOnUse" x1="1" y1="1" x2="13" y2="14">'
        f'<stop offset="0" stop-color="{INACTIVE_LIGHT}"/>'
        f'<stop offset="1" stop-color="{INACTIVE_DARK}"/>'
        "</linearGradient>"
        '<linearGradient id="markInnerOff" gradientUnits="userSpaceOnUse" x1="2" y1="4" x2="9" y2="11">'
        f'<stop offset="0" stop-color="{INACTIVE_LIGHT}"/>'
        f'<stop offset="1" stop-color="{INACTIVE_MID}"/>'
        "</linearGradient>"
        "</defs>"
    )


def badge(colour: str, glyph: str) -> str:
    """Đĩa tròn màu trạng thái, viền trắng để tách khỏi chữ DD phía sau."""
    cx, cy = BADGE_CENTRE
    return (
        f'<circle cx="{cx}" cy="{cy}" r="{BADGE_RADIUS + BADGE_RING}" fill="#FFFFFF"/>'
        f'<circle cx="{cx}" cy="{cy}" r="{BADGE_RADIUS}" fill="{colour}"/>'
        f"{glyph}"
    )


def stroke(path: str, width: float = 1.3) -> str:
    return (
        f'<path d="{path}" fill="none" stroke="#FFFFFF" stroke-width="{width}" '
        'stroke-linecap="round" stroke-linejoin="round"/>'
    )


GLYPHS = {
    # dấu kiểm
    "ok": (STATUS_OK, stroke("M 10.2 12.2 L 11.7 13.7 L 14.1 10.8")),
    # hai mũi tên xoay vòng, rút gọn thành hai cung
    "sync": (
        STATUS_SYNC,
        stroke("M 10.0 12.9 A 2.2 2.2 0 0 1 13.8 11.1", 1.2)
        + stroke("M 14.2 11.4 A 2.2 2.2 0 0 1 10.4 13.2", 1.2),
    ),
    # dấu nhân
    "error": (STATUS_ERROR, stroke("M 10.5 10.5 L 13.7 13.7") + stroke("M 13.7 10.5 L 10.5 13.7")),
    # dấu chấm than
    "warning": (STATUS_WARNING, stroke("M 12.1 10.0 L 12.1 12.4") + stroke("M 12.1 13.9 L 12.1 14.0", 1.5)),
    # hai vạch tạm dừng
    "pause": (STATUS_NEUTRAL, stroke("M 11.0 10.4 L 11.0 13.8") + stroke("M 13.2 10.4 L 13.2 13.8")),
    # một vạch ngang
    "offline": (STATUS_NEUTRAL, stroke("M 10.3 12.1 L 13.9 12.1")),
}

INACTIVE_STATES = {"offline", "pause"}

# Bộ đơn sắc dùng khi người dùng bật icon một màu. Khay sáng lấy bộ đen, khay tối lấy bộ trắng,
# nên mỗi bộ chỉ có đúng một màu vẽ và một màu để khoét ký hiệu bên trong huy hiệu.
MONO_DIRS = {
    "black": ("#000000", "#FFFFFF"),
    "white": ("#FFFFFF", "#000000"),
}

# Bộ đơn sắc có thêm trạng thái thông tin mà bộ màu không dùng tới.
MONO_EXTRA_GLYPHS = {"info"}


def monoMark(ink: str) -> str:
    dx, dy = MARK_OFFSET
    return (
        f'<g transform="translate({dx},{dy}) scale({MARK_SCALE})" fill="none" '
        f'stroke="{ink}" stroke-linejoin="round" stroke-linecap="round">'
        '<path d="M 22 36 H 47.5 A 18 18 0 0 1 47.5 72 H 22 Z" stroke-width="9" opacity="0.55"/>'
        '<path d="M 20.5 14 H 47.5 A 40 40 0 0 1 47.5 94 H 20.5 Z" stroke-width="14"/>'
        "</g>"
    )


def monoGlyph(state: str, knockout: str) -> str:
    """Ký hiệu trạng thái vẽ bằng màu nền để nó nổi lên trên huy hiệu đặc."""
    cx, cy = BADGE_CENTRE
    paths = {
        "ok": [("M 10.2 12.2 L 11.7 13.7 L 14.1 10.8", 1.3)],
        "sync": [("M 10.0 12.9 A 2.2 2.2 0 0 1 13.8 11.1", 1.2), ("M 14.2 11.4 A 2.2 2.2 0 0 1 10.4 13.2", 1.2)],
        "error": [("M 10.5 10.5 L 13.7 13.7", 1.3), ("M 13.7 10.5 L 10.5 13.7", 1.3)],
        "warning": [("M 12.1 10.0 L 12.1 12.4", 1.3), ("M 12.1 13.9 L 12.1 14.0", 1.5)],
        "pause": [("M 11.0 10.4 L 11.0 13.8", 1.3), ("M 13.2 10.4 L 13.2 13.8", 1.3)],
        "offline": [("M 10.3 12.1 L 13.9 12.1", 1.3)],
        "info": [(f"M {cx} 11.0 L {cx} 13.9", 1.3), (f"M {cx} 9.7 L {cx} 9.8", 1.5)],
    }[state]
    return "".join(
        f'<path d="{d}" fill="none" stroke="{knockout}" stroke-width="{w}" '
        'stroke-linecap="round" stroke-linejoin="round"/>'
        for d, w in paths
    )


def writeMonoSet() -> None:
    cx, cy = BADGE_CENTRE
    states = list(GLYPHS) + sorted(MONO_EXTRA_GLYPHS)
    for folder, (ink, knockout) in MONO_DIRS.items():
        outDir = REPO / "theme" / folder
        outDir.mkdir(parents=True, exist_ok=True)
        for state in states:
            svg = (
                '<svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" viewBox="0 0 16 16">'
                + monoMark(ink)
                + f'<circle cx="{cx}" cy="{cy}" r="{BADGE_RADIUS + BADGE_RING}" fill="{knockout}"/>'
                + f'<circle cx="{cx}" cy="{cy}" r="{BADGE_RADIUS}" fill="{ink}"/>'
                + monoGlyph(state, knockout)
                + "</svg>\n"
            )
            target = outDir / f"state-{state}.svg"
            target.write_text(svg, encoding="utf-8")
            print(f"da ghi {target.relative_to(REPO)}")


def main() -> None:
    OUT_DIR.mkdir(parents=True, exist_ok=True)
    for state, (colour, glyph) in GLYPHS.items():
        svg = (
            '<svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" viewBox="0 0 16 16">'
            + gradients()
            + mark(state not in INACTIVE_STATES)
            + badge(colour, glyph)
            + "</svg>\n"
        )
        target = OUT_DIR / f"state-{state}.svg"
        target.write_text(svg, encoding="utf-8")
        print(f"da ghi {target.relative_to(REPO)}")

    writeMonoSet()


if __name__ == "__main__":
    main()
