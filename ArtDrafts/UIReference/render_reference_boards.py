"""Compose instructional contact sheets from native Aseprite pixel examples.
Example artwork is pasted at integer scale with nearest filtering; labels are not game assets.
"""
from pathlib import Path
from PIL import Image, ImageDraw, ImageFont

ROOT = Path(__file__).resolve().parent
MENU = ROOT.parent / "Menu"
BG = "#E4E4E7"
INK = "#151D2E"
MUTED = "#484C57"
RULE = "#A1A1AA"
FONT = "C:/Windows/Fonts/segoeui.ttf"
BOLD = "C:/Windows/Fonts/segoeuib.ttf"

def font(size=24, bold=False):
    return ImageFont.truetype(BOLD if bold else FONT, size)

def text(board, xy, value, size=24, bold=False, fill=INK):
    ImageDraw.Draw(board).text(xy, value, font=font(size, bold), fill=fill)

def new_board(title, height):
    b = Image.new("RGB", (1600, height), BG)
    text(b, (56, 26), title, 40, True)
    text(b, (56, 83), "Mẫu tham khảo để tự vẽ · Kích thước ghi là pixel gốc · Màu lấy từ SummerTile", 23, fill=MUTED)
    ImageDraw.Draw(b).line((56, 122, 1544, 122), fill=RULE, width=2)
    return b

def separator(b, y):
    ImageDraw.Draw(b).line((56, y, 1544, y), fill=RULE, width=1)

def heading(b, xy, value):
    text(b, xy, value, 27, True)

def sample(b, name, x, y, scale=4):
    im = Image.open(ROOT / f"{name}.png").convert("RGBA")
    im = im.resize((im.width * scale, im.height * scale), Image.Resampling.NEAREST)
    b.paste(im, (x, y), im)
    return im.width, im.height

def swatch(b, x, y, hexcode, label="", size=22):
    d = ImageDraw.Draw(b)
    d.rectangle((x, y + 4, x + 24, y + 28), fill=hexcode, outline=INK)
    text(b, (x + 35, y), f"{hexcode} {label}".rstrip(), size, fill=MUTED)

def footer(b):
    y = b.height - 49
    separator(b, y - 12)
    text(b, (56, y), "CHỈ THAM KHẢO · Không đưa các mẫu này vào game · Chữ/số giao diện đặt trong Godot", 21, fill=MUTED)

states = ["normal", "hover", "pressed", "disabled"]
state_labels = ["Normal", "Hover / Focus", "Pressed", "Disabled"]
columns = [64, 440, 816, 1192]

b = new_board("01 · NÚT, KHUNG BẢNG VÀ ICON", 1260)
for y, prefix, title, faces in [
    (146, "primary", "01. Nút chính · 88 × 18 px", ["#F0D69F", "#FCE9BD", "#E5C687", "#A1A1AA"]),
    (336, "secondary", "02. Nút phụ · 88 × 18 px", ["#FCE9BD", "#E4E4E7", "#E5C687", "#A1A1AA"]),
]:
    heading(b, (56, y), title)
    for x, state, label, face in zip(columns, states, state_labels, faces):
        sample(b, f"{prefix}-{state}", x, y + 48, 3)
        text(b, (x, y + 111), label, 23, True)
        swatch(b, x, y + 145, face)
    separator(b, y + 184)

heading(b, (56, 532), "03. Nền nút icon · 20 × 20 px · Dùng màu nút phụ")
for x, state, label in zip(columns, states, state_labels):
    sample(b, f"icon-button-{state}", x, 580, 3)
    text(b, (x + 78, 594), label, 23)
separator(b, 658)

heading(b, (56, 674), "04. Khung bảng · 32 × 32 px")
sample(b, "panel", 64, 724, 3)
text(b, (188, 726), "Viền 4 px mỗi cạnh", 23, True)
text(b, (188, 762), "Dùng chung cho popup và HUD", 23, fill=MUTED)
for i, (hexcode, label) in enumerate([
    ("#54311F", "Viền"), ("#7A4C32", "Bóng"), ("#9C6546", "Gỗ"),
    ("#C7A663", "Sáng gỗ"), ("#FCE9BD", "Mặt bảng")
]):
    swatch(b, 650 + (i % 3) * 290, 724 + (i // 3) * 52, hexcode, label)
separator(b, 840)

heading(b, (56, 856), "05. Icon thao tác · 16 × 16 px mỗi hình")
icons = [("pause", "Pause"), ("back", "Back"), ("restart", "Restart"), ("home", "Home"),
         ("settings", "Settings"), ("close", "Close"), ("next", "Next"), ("help", "Help")]
for i, (name, label) in enumerate(icons):
    x = 64 + i * 185
    sample(b, f"icon-{name}", x, 908, 4)
    text(b, (x, 983), label, 22)
separator(b, 1020)

heading(b, (56, 1036), "06. Icon âm thanh · 16 × 16 px mỗi hình")
for x, name, label in zip(columns, ["music-on", "music-off", "sound-on", "sound-off"],
                          ["Nhạc bật", "Nhạc tắt", "Âm thanh bật", "Âm thanh tắt"]):
    sample(b, name, x, 1084, 4)
    text(b, (x + 82, 1094), label, 23)
    text(b, (x + 82, 1131), "#B91C1C" if "off" in name else "#54311F", 22, fill=MUTED)
footer(b)
b.save(ROOT / "01-buttons-panels-icons.png")

b = new_board("02 · MENU, LEVEL, SAO VÀ MÀU", 1450)
heading(b, (56, 148), "07. Logo · 112 × 32 px")
ImageDraw.Draw(b).rectangle((60, 200, 516, 348), fill="#67C794")
sample(b, "logo", 64, 212, 4)
swatch(b, 64, 380, "#F0D69F", "Chữ")
swatch(b, 64, 424, "#54311F", "Viền")
swatch(b, 360, 380, "#FCE9BD", "Sáng")
swatch(b, 360, 424, "#C7A663", "Bóng")

heading(b, (820, 148), "08. Background tĩnh · 320 × 180 px")
background = Image.open(MENU / "menu-background-v1-summertile-colors.png").convert("RGB")
b.paste(background.resize((640, 360), Image.Resampling.NEAREST), (820, 200))
text(b, (820, 570), "Bản v1 đổi màu SummerTile · Không vẽ nút dính vào nền", 21, fill=MUTED)
separator(b, 612)

heading(b, (56, 628), "09. Ô level · 40 × 40 px")
for i, (state, label) in enumerate(zip(["normal", "hover", "pressed", "locked"],
                                     ["Normal", "Đang chọn", "Pressed", "Locked"])):
    x = 64 + i * 230
    sample(b, f"level-{state}", x, 684, 3)
    if state == "locked":
        sample(b, "lock", x + 42, 712, 3)
    else:
        text(b, (x + 43, 701), "03", 29, True, fill="#54311F")
        for j in range(3):
            sample(b, "star-8-full" if j == 0 else "star-8-empty", x + 17 + j * 29, 765, 3)
    text(b, (x, 820), label, 23, True)
    swatch(b, x, 856, ["#FCE9BD", "#FCE128", "#E5C687", "#A1A1AA"][i])
heading(b, (1100, 628), "10. Khóa · 12 × 12 px")
sample(b, "lock", 1110, 700, 7)
swatch(b, 1100, 820, "#C7A663", "Thân")
swatch(b, 1100, 864, "#54311F", "Viền")
text(b, (56, 912), "Số màn, sao và khóa được ghép lên nền ô; không cần vẽ 10 ô khác nhau.", 22, fill=MUTED)
separator(b, 958)

heading(b, (56, 976), "11. Sao nhỏ · 8 × 8 px")
heading(b, (540, 976), "12. Sao lớn · 16 × 16 px")
for x, state, label in [(64, "empty", "Rỗng"), (230, "full", "Đầy")]:
    sample(b, f"star-8-{state}", x, 1040, 8)
    text(b, (x, 1120), label, 23)
for x, state, label in [(550, "empty", "Rỗng"), (720, "full", "Đầy")]:
    sample(b, f"star-16-{state}", x, 1030, 5)
    text(b, (x, 1120), label, 23)
for i, (hexcode, label) in enumerate([("#FCE128", "Đầy"), ("#8A7200", "Viền sao"),
                                     ("#D1B008", "Bóng"), ("#A1A1AA", "Rỗng")]):
    swatch(b, 1010 + (i % 2) * 280, 1020 + (i // 2) * 56, hexcode, label)
separator(b, 1170)

heading(b, (56, 1186), "A. Dấu hoàn thành · 8 × 8 px · Tùy chọn")
sample(b, "optional-check", 64, 1250, 7)
swatch(b, 150, 1260, "#2D7D51")
heading(b, (650, 1186), "B. Băng rôn · 112 × 24 px · Tùy chọn")
sample(b, "optional-banner", 660, 1240, 4)
swatch(b, 1160, 1250, "#F0D69F", "Mặt")
swatch(b, 1160, 1296, "#54311F", "Viền")
footer(b)
b.save(ROOT / "02-menu-level-stars.png")

b = new_board("03 · HUD, CÀI ĐẶT VÀ HƯỚNG DẪN", 1540)
heading(b, (56, 146), "13. Khung HUD · 80 × 24 px")
sample(b, "hud-panel", 64, 204, 4)
text(b, (64, 315), "Nền trống để vẽ", 22, fill=MUTED)
sample(b, "hud-panel", 440, 204, 4)
text(b, (465, 220), "MÀN 03/10", 23, True, fill="#54311F")
text(b, (465, 253), "GẬY: 2", 23, True, fill="#151D2E")
text(b, (440, 315), "Ví dụ ghép chữ trong Godot", 22, fill=MUTED)
swatch(b, 900, 211, "#FCE9BD", "Nền")
swatch(b, 900, 260, "#54311F", "Viền / chữ")
separator(b, 360)

heading(b, (56, 378), "14–15. Thanh lực · Vỏ 80 × 10 px + ruột 76 × 6 px")
sample(b, "power-frame", 64, 444, 4)
text(b, (64, 500), "Vỏ / rãnh #2A2D36", 22)
sample(b, "power-fill", 530, 452, 4)
text(b, (530, 500), "Ruột riêng #FCE128", 22)
assembled = Image.open(ROOT / "power-frame.png").convert("RGBA")
fill = Image.open(ROOT / "power-fill.png").convert("RGBA").crop((0, 0, 46, 6))
assembled.paste(fill, (2, 2), fill)
assembled = assembled.resize((320, 40), Image.Resampling.NEAREST)
b.paste(assembled, (1030, 444), assembled)
text(b, (1030, 500), "Ví dụ ghép khoảng 60%", 22)
separator(b, 548)

heading(b, (56, 564), "16–17. Âm lượng · Rãnh 80 × 6 px + ruột 76 × 2 px")
sample(b, "slider-track", 64, 628, 4)
text(b, (64, 675), "Rãnh #484C57 / #2A2D36", 22)
sample(b, "slider-fill", 530, 636, 4)
text(b, (530, 675), "Ruột #F0D69F", 22)
heading(b, (1000, 564), "18. Tay nắm · 8 × 12 px")
for x, state, label in [(1010, "normal", "Normal"), (1190, "hover", "Hover"), (1370, "dragging", "Dragging")]:
    sample(b, "slider-handle-" + state, x, 620, 4)
    text(b, (x - 5, 681), label, 22)
separator(b, 730)

heading(b, (56, 748), "19. Checkbox · 12 × 12 px")
for x, state, label in zip([64, 340, 616, 892],
                          ["unchecked", "checked", "unchecked-focus", "checked-focus"],
                          ["Unchecked", "Checked", "Unchecked · focus", "Checked · focus"]):
    sample(b, "checkbox-" + state, x, 808, 5)
    text(b, (x, 885), label, 22)
swatch(b, 1210, 803, "#2D7D51", "Tích")
swatch(b, 1210, 856, "#FCE128", "Focus")
separator(b, 938)

heading(b, (56, 955), "20. Hướng dẫn chuột · 48 × 24 px / hình · Có thể bỏ")
for x, step, label in [(64, 1, "Nhấn giữ"), (360, 2, "Kéo ngược"), (656, 3, "Thả")]:
    ImageDraw.Draw(b).rectangle((x, 1018, x + 191, 1113), fill="#67C794")
    sample(b, f"mouse-hint-{step}", x, 1018, 4)
    text(b, (x, 1132), label, 24, True)
text(b, (1030, 1016), "Chỉ là hình hướng dẫn.", 24, True)
text(b, (1030, 1057), "Game đã có kéo–thả.", 23, fill=MUTED)
text(b, (1030, 1095), "Kéo trái → bóng đánh sang phải.", 23, fill=MUTED)
separator(b, 1196)

heading(b, (56, 1214), "C. Đầu ngắm · 8 × 8 px · Tùy chọn")
sample(b, "optional-aim", 64, 1280, 8)
swatch(b, 170, 1285, "#FCE128", "Mặt")
swatch(b, 170, 1335, "#54311F", "Viền")
heading(b, (820, 1214), "D. Vòng sẵn sàng · 16 × 16 px · Tùy chọn")
sample(b, "optional-ring", 830, 1280, 5)
swatch(b, 960, 1285, "#FCE9BD", "Nét sáng")
swatch(b, 960, 1335, "#2D7D51", "Viền")
text(b, (56, 1420), "Giữ nguyên cơ chế ngắm đang có nếu thấy đã đủ rõ; thanh lực và hình ngắm mới không bắt buộc.", 23, fill=MUTED)
footer(b)
b.save(ROOT / "03-hud-settings-hints.png")

for name in ("01-buttons-panels-icons.png", "02-menu-level-stars.png", "03-hud-settings-hints.png"):
    with Image.open(ROOT / name) as im:
        print(f"{name}: {im.width} x {im.height}")
