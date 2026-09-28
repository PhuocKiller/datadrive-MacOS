"""Sinh anh cho bo cai NSIS va file .ico Windows tu tai nguyen thuong hieu DataDrive.

NSIS MUI2 doi dung kich thuoc: welcome.bmp 164x314, page_header.bmp 150x57.
File .ico Windows can nhieu kich thuoc trong mot file: 16/32/48/256.
"""

import sys
from pathlib import Path

from PIL import Image

REPO = Path(r"C:\projects\datadrive")
LOGO_DIR = REPO / "Logo" / "Logo"
BG_DIR = REPO / "BackGround" / "BackGround"
NSI_DIR = REPO / "admin" / "win" / "nsi"

BRAND_BG = (10, 147, 224)  # #0A93E0, mau chu dao lay tu logo


def fit_centred(source: Image.Image, size: tuple[int, int], background: tuple[int, int, int]) -> Image.Image:
    """Dat anh vao khung dung kich thuoc, giu ty le, nen mau thuong hieu."""
    canvas = Image.new("RGB", size, background)
    scaled = source.copy()
    scaled.thumbnail(size, Image.LANCZOS)
    offset = ((size[0] - scaled.width) // 2, (size[1] - scaled.height) // 2)
    canvas.paste(scaled, offset, scaled if scaled.mode == "RGBA" else None)
    return canvas


def main() -> int:
    icon_512 = LOGO_DIR / "png" / "datadrive-icon-512.png"
    if not icon_512.is_file():
        print(f"THIEU: {icon_512}", file=sys.stderr)
        return 1

    icon = Image.open(icon_512).convert("RGBA")

    # 1. File .ico da kich thuoc cho bo cai
    ico_path = NSI_DIR / "installer.ico"
    icon.save(ico_path, format="ICO", sizes=[(16, 16), (32, 32), (48, 48), (64, 64), (128, 128), (256, 256)])
    print(f"da ghi {ico_path.name}: 16/32/48/64/128/256")

    # 2. welcome.bmp - cot doc ben trai trang dau va trang cuoi
    welcome_source = icon
    login_bg = BG_DIR / "datadrive-login-bg-light-1920x1080.png"
    if login_bg.is_file():
        # Cat mot dai doc tu anh nen roi dat logo len tren
        bg = Image.open(login_bg).convert("RGB")
        ratio = 164 / 314
        crop_w = int(bg.height * ratio)
        left = (bg.width - crop_w) // 2
        panel = bg.crop((left, 0, left + crop_w, bg.height)).resize((164, 314), Image.LANCZOS)
        badge = icon.copy()
        badge.thumbnail((110, 110), Image.LANCZOS)
        panel.paste(badge, ((164 - badge.width) // 2, (314 - badge.height) // 2), badge)
        welcome = panel
    else:
        welcome = fit_centred(welcome_source, (164, 314), BRAND_BG)
    welcome.save(NSI_DIR / "welcome.bmp", format="BMP")
    print("da ghi welcome.bmp: 164x314")

    # 3. page_header.bmp - dai ngang tren dau cac trang giua
    header = Image.new("RGB", (150, 57), (255, 255, 255))
    mark = icon.copy()
    mark.thumbnail((45, 45), Image.LANCZOS)
    header.paste(mark, (6, (57 - mark.height) // 2), mark)
    wordmark = LOGO_DIR / "png" / "datadrive-logo-840.png"
    if wordmark.is_file():
        word = Image.open(wordmark).convert("RGBA")
        word.thumbnail((92, 34), Image.LANCZOS)
        header.paste(word, (56, (57 - word.height) // 2), word)
    header.save(NSI_DIR / "page_header.bmp", format="BMP")
    print("da ghi page_header.bmp: 150x57")

    return 0


if __name__ == "__main__":
    raise SystemExit(main())
