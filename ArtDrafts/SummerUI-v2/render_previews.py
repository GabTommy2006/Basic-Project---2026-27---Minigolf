"""Review exported art in assembled screens; no Godot files or exported pixels are edited."""
from pathlib import Path
import json
from PIL import Image, ImageDraw, ImageFont

ROOT = Path(__file__).resolve().parent
OUT = ROOT / "previews"
manifest = json.loads((ROOT / "SummerUI-v2.json").read_text(encoding="utf-8"))
regions = {(r["group"], r["state"]): r for r in manifest["regions"]}
INK = "#151D2E"
CREAM = "#E4E4E7"

def asset(group, state="normal"):
    return Image.open(ROOT / regions[group, state]["png"]).convert("RGBA")

def put(canvas, group, xy, state="normal"):
    im = asset(group, state)
    canvas.alpha_composite(im, xy)

def pixel_text(canvas, value, xy, size=8, fill=INK, center=False):
    # Preview text only. No font is redistributed or baked into exported UI backgrounds.
    f = ImageFont.truetype("C:/Windows/Fonts/consolab.ttf", size)
    bounds = f.getbbox(value)
    w, h = max(1, bounds[2] - bounds[0]), max(1, bounds[3] - bounds[1])
    mask = Image.new("L", (w, h))
    ImageDraw.Draw(mask).text((-bounds[0], -bounds[1]), value, font=f, fill=255)
    mask = mask.point(lambda a: 255 if a >= 128 else 0)
    x, y = xy
    if center:
        x -= w // 2
    canvas.paste(Image.new("RGBA", (w, h), fill), (int(x), int(y)), mask)

def ninepatch(group, size):
    im = asset(group)
    margin = regions[group, "normal"]["nine_patch_margin"]
    target = Image.new("RGBA", size)
    sx = [0, margin, im.width - margin, im.width]
    sy = [0, margin, im.height - margin, im.height]
    dx = [0, margin, size[0] - margin, size[0]]
    dy = [0, margin, size[1] - margin, size[1]]
    for row in range(3):
        for col in range(3):
            tile = im.crop((sx[col], sy[row], sx[col + 1], sy[row + 1]))
            tile = tile.resize((dx[col + 1] - dx[col], dy[row + 1] - dy[row]), Image.Resampling.NEAREST)
            target.alpha_composite(tile, (dx[col], dy[row]))
    return target

def panel(canvas, xy, size):
    canvas.alpha_composite(ninepatch("panel", size), xy)

def button(canvas, xy, label, primary=False, state="normal"):
    put(canvas, "button_primary" if primary else "button_secondary", xy, state)
    pixel_text(canvas, label, (xy[0] + 48, xy[1] + (5 if state == "pressed" else 4)), 8, center=True)

def icon_button(canvas, xy, icon):
    put(canvas, "button_icon", xy)
    put(canvas, "icons", xy, icon)

def base():
    return asset("menu_background").crop((0, 0, 320, 180))

def shade(canvas):
    canvas.alpha_composite(Image.new("RGBA", canvas.size, (21, 29, 46, 135)))

screens = []

c = base()
put(c, "logo", (104, 22))
for y, label, primary in [(64, "CHƠI", True), (88, "CHỌN MÀN", False), (112, "CÀI ĐẶT", False), (136, "CÁCH CHƠI", False)]:
    button(c, (112, y), label, primary)
screens.append(("01-menu", "Menu chính", c))

c = base()
panel(c, (16, 16), (288, 144))
icon_button(c, (0, 16), "back")
pixel_text(c, "CHỌN MÀN", (160, 24), 9, center=True)
for i in range(10):
    x, y = 40 + (i % 5) * 48, 40 + (i // 5) * 56
    state = "normal" if i < 2 else "hover" if i == 2 else "locked"
    put(c, "level_card", (x, y), state)
    if i < 3:
        pixel_text(c, f"{i + 1:02}", (x + 24, y + 8), 10, center=True)
        for j in range(3):
            put(c, "star_small", (x + j * 16, y + 28), "full" if j < 3 - i else "empty")
    else:
        put(c, "lock", (x + 16, y + 16))
pixel_text(c, "3 sao: không quá 3 gậy", (160, 150), 7, center=True)
screens.append(("02-level-select", "Chọn màn · trạng thái minh họa", c))

c = base()
put(c, "hud_panel", (16, 16))
pixel_text(c, "MÀN 03/10", (22, 22), 8)
pixel_text(c, "GẬY: 2", (22, 35), 8)
icon_button(c, (288, 16), "pause")
put(c, "power_frame", (112, 160))
fill = asset("power_fill").crop((0, 0, 58, 16))
c.alpha_composite(fill, (112, 160))
pixel_text(c, "LỰC ĐÁNH", (160, 150), 7, fill=CREAM, center=True)
screens.append(("03-hud", "HUD · thanh lực tùy chọn", c))

c = base()
shade(c)
panel(c, (96, 32), (128, 112))
pixel_text(c, "TẠM DỪNG", (160, 44), 9, center=True)
button(c, (112, 64), "TIẾP TỤC", True)
button(c, (112, 88), "CHƠI LẠI")
button(c, (112, 112), "VỀ MENU")
screens.append(("04-pause", "Tạm dừng", c))

c = base()
shade(c)
panel(c, (80, 16), (160, 144))
put(c, "result_banner", (104, 24))
pixel_text(c, "HOÀN THÀNH", (160, 35), 8, center=True)
for i in range(3):
    put(c, "star_large", (128 + i * 24, 64), "full" if i < 2 else "empty")
pixel_text(c, "SỐ GẬY: 4", (160, 84), 8, center=True)
pixel_text(c, "KỶ LỤC: 3", (160, 96), 7, center=True)
button(c, (112, 112), "MÀN TIẾP", True)
button(c, (112, 136), "CHƠI LẠI")
icon_button(c, (216, 136), "home")
screens.append(("05-results", "Kết quả · số liệu minh họa", c))

c = base()
panel(c, (48, 16), (224, 144))
pixel_text(c, "CÀI ĐẶT", (160, 30), 9, center=True)
for y, kind, label, amount in [(48, "music_on", "Nhạc", 50), (80, "sound_on", "Hiệu ứng", 72)]:
    put(c, "audio_icons", (60, y), kind)
    pixel_text(c, label, (80, y + 5), 7)
    put(c, "slider_track", (144, y))
    strip = asset("slider_fill").crop((0, 0, amount, 16))
    c.alpha_composite(strip, (144, y))
    put(c, "slider_handle", (136 + amount, y), "normal")
put(c, "checkbox", (64, 112), "checked")
pixel_text(c, "Toàn màn hình", (88, 117), 8)
button(c, (112, 136), "ĐÓNG", True)
screens.append(("06-settings", "Cài đặt", c))

c = base()
panel(c, (48, 16), (224, 144))
pixel_text(c, "CÁCH CHƠI", (160, 30), 9, center=True)
for x, state, label in [(72, "press", "Nhấn giữ"), (136, "drag", "Kéo ngược"), (200, "release", "Thả")]:
    put(c, "mouse_drag_hint", (x, 56), state)
    pixel_text(c, label, (x + 24, 90), 7, center=True)
pixel_text(c, "Kéo ngược hướng muốn đánh.", (160, 106), 7, center=True)
pixel_text(c, "Thả chuột để đưa bóng vào lỗ.", (160, 117), 7, center=True)
button(c, (112, 136), "ĐÃ HIỂU", True)
screens.append(("07-how-to-play", "Hướng dẫn · hình vẽ tùy chọn", c))

for name, _, c in screens:
    assert c.size == (320, 180)
    c.resize((1280, 720), Image.Resampling.NEAREST).save(OUT / f"{name}-4x.png")

font = ImageFont.truetype("C:/Windows/Fonts/segoeuib.ttf", 30)
small_font = ImageFont.truetype("C:/Windows/Fonts/segoeui.ttf", 20)
overview = Image.new("RGB", (1408, 1760), "#E4E4E7")
d = ImageDraw.Draw(overview)
d.text((32, 20), "SUMMER UI v2 · Khung sắt gọn · Lưới 16 px", font=font, fill="#151D2E")
d.text((32, 65), "Viền 1 px + bevel 1 px · Palette SummerTile · Ghép xem trước, chưa tích hợp vào game", font=small_font, fill="#484C57")
for i, (_, title, c) in enumerate(screens):
    x, y = 32 + (i % 2) * 704, 112 + (i // 2) * 408
    d.text((x, y), title, font=small_font, fill="#151D2E")
    overview.paste(c.resize((640, 360), Image.Resampling.NEAREST).convert("RGB"), (x, y + 32))
overview.save(OUT / "SummerUI-v2-overview.png")

# Contact sheet of all 55 images, clearly labeled with native dimensions and state.
contact = Image.new("RGB", (1600, 1780), "#E4E4E7")
d = ImageDraw.Draw(contact)
d.text((32, 20), "SUMMER UI v2 · 24 nhóm asset khung sắt", font=font, fill="#151D2E")
d.text((32, 66), "PNG theo ô 16×16 · Viền 2 px tổng cộng · Aseprite grid 16 px · AtlasTexture/StyleBoxTexture sẵn", font=small_font, fill="#484C57")
group_names = list(dict.fromkeys(r["group"] for r in manifest["regions"]))
for i, group in enumerate(group_names):
    x, y = 32 + (i % 3) * 520, 118 + (i // 3) * 204
    group_regions = [r for r in manifest["regions"] if r["group"] == group]
    first = group_regions[0]
    d.text((x, y), f"{i+1:02}. {group} · {first['width']}×{first['height']}", font=small_font, fill="#151D2E")
    px, py = x, y + 42
    maxh = 0
    for region in group_regions:
        im = asset(group, region["state"])
        scale = 1 if im.width > 160 else 2
        im = im.resize((im.width * scale, im.height * scale), Image.Resampling.NEAREST)
        label_font = ImageFont.truetype("C:/Windows/Fonts/segoeui.ttf", 14)
        label_width = int(d.textlength(region["state"], font=label_font)) if len(group_regions) > 1 else 0
        cell_width = max(im.width, label_width)
        if px + cell_width > x + 490:
            px, py, maxh = x, py + maxh + 30, 0
        if group == "menu_background":
            im = im.resize((256, 144), Image.Resampling.NEAREST)
        contact.paste(im, (px, py), im)
        if len(group_regions) > 1:
            d.text((px, py + im.height + 2), region["state"], font=label_font, fill="#484C57")
        px += cell_width + 18
        maxh = max(maxh, im.height)
contact.save(OUT / "SummerUI-v2-assets.png")
print("Rendered 7 screen previews, overview, and asset contact sheet")
