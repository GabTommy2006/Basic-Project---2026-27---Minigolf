"""Verify grid, palette, native sources and Godot validation before packaging."""
from pathlib import Path
from collections import defaultdict
import json
import zipfile
from PIL import Image, ImageDraw, ImageFont

root = Path(__file__).resolve().parent
manifest = json.loads((root / "SummerUI-v2.json").read_text(encoding="utf-8"))
palette = set()
for line in (root / "SummerTile.gpl").read_text().splitlines():
    p = line.split()
    if len(p) >= 3 and all(v.isdigit() for v in p[:3]):
        palette.add(tuple(map(int, p[:3])) + (255,))
assert len(palette) == 43
expected = {
    "button_primary": (96, 16), "button_secondary": (96, 16), "button_icon": (16, 16),
    "panel": (32, 32), "hud_panel": (96, 32), "icons": (16, 16), "audio_icons": (16, 16),
    "logo": (112, 32), "menu_background": (320, 192), "level_card": (48, 48), "lock": (16, 16),
    "star_small": (16, 16), "star_large": (16, 16), "power_frame": (96, 16), "power_fill": (96, 16),
    "slider_track": (96, 16), "slider_fill": (96, 16), "slider_handle": (16, 16), "checkbox": (16, 16),
    "mouse_drag_hint": (48, 32), "check": (16, 16), "aim_head": (16, 16), "ball_ready_ring": (16, 16),
    "result_banner": (112, 32),
}
atlas = Image.open(root / manifest["atlas"]).convert("RGBA")
groups = defaultdict(list)
for index, r in enumerate(manifest["regions"]):
    im = Image.open(root / r["png"]).convert("RGBA")
    assert im.size == expected[r["group"]]
    assert all(r[k] % 16 == 0 for k in ("x", "y", "width", "height"))
    assert r["tile_x"] * 16 == r["x"] and r["tile_y"] * 16 == r["y"]
    assert r["tile_columns"] * 16 == im.width and r["tile_rows"] * 16 == im.height
    pixels = set(im.get_flattened_data())
    assert all(p[3] in (0, 255) for p in pixels)
    assert {p for p in pixels if p[3]} <= palette
    x, y = r["x"], r["y"]
    assert atlas.crop((x, y, x + im.width, y + im.height)).tobytes() == im.tobytes()
    c = r["content_rect"]
    assert 0 <= c["x"] and 0 <= c["y"] and c["x"] + c["width"] <= im.width and c["y"] + c["height"] <= im.height
    for previous in manifest["regions"][:index]:
        gap = max(r["x"] - previous["x"] - previous["width"], previous["x"] - r["x"] - r["width"],
                  r["y"] - previous["y"] - previous["height"], previous["y"] - r["y"] - r["height"])
        assert gap >= 16, "Atlas gutter below one tile"
    assert (root / r["godot_texture"]).is_file()
    if "godot_style" in r:
        assert r["nine_patch_margin"] == 2 and (root / r["godot_style"]).is_file()
    groups[r["group"]].append(r["state"])
assert set(groups) == set(expected)
assert len(list((root / "sources").glob("*.aseprite"))) == 24
for group, size in expected.items():
    raw = (root / "sources" / f"{group}.aseprite").read_bytes()
    assert int.from_bytes(raw[4:6], "little") == 0xA5E0
    assert (int.from_bytes(raw[8:10], "little"), int.from_bytes(raw[10:12], "little")) == size
    assert int.from_bytes(raw[6:8], "little") == (1 if group == "menu_background" else len(groups[group]))
for group in ("button_primary", "button_secondary", "button_icon"):
    assert groups[group] == ["normal", "hover", "pressed", "disabled"]
assert groups["star_small"] == groups["star_large"] == ["empty", "full"]
steel = {(int(h[0:2], 16), int(h[2:4], 16), int(h[4:6], 16), 255) for h in
         ("2A2D36", "484C57", "6C717D", "A1A1AA", "E4E4E7", "B91C1C", "7F1D1D")}
for group in ("button_primary", "button_secondary", "button_icon", "panel", "hud_panel", "level_card", "result_banner"):
    for state in groups[group]:
        r = next(r for r in manifest["regions"] if r["group"] == group and r["state"] == state)
        im = Image.open(root / r["png"]).convert("RGBA")
        assert {p for p in im.get_flattened_data() if p[3]} <= steel, "Nonmetal frame color"
background = Image.open(root / "png/menu_background.png").convert("RGBA")
assert background.crop((0, 180, 320, 192)).getbbox() is None
godot_output = (root / "godot-check.stdout.txt").read_text(encoding="utf-8")
assert "SUMMER_UI_V2_OK: 55 AtlasTextures, 21 StyleBoxTextures, 55 multi-cell tiles on 16px grid" in godot_output
assert not (root / "godot-check.stderr.txt").read_text(encoding="utf-8").strip()
assert not (root / "godot-import.stderr.txt").read_text(encoding="utf-8").strip()

# A close-up proof sheet, keeping all art at integer scale and labeling actual cell sizes.
board = Image.new("RGB", (1440, 820), "#E4E4E7")
d = ImageDraw.Draw(board)
title = ImageFont.truetype("C:/Windows/Fonts/segoeuib.ttf", 32)
font = ImageFont.truetype("C:/Windows/Fonts/segoeui.ttf", 22)
small = ImageFont.truetype("C:/Windows/Fonts/consola.ttf", 18)
d.text((32, 20), "SummerUI v2 · Khung sắt · Viền 1 px + bevel 1 px", font=title, fill="#151D2E")
d.text((32, 68), "Tất cả vùng cắt nằm đúng lưới 16×16 px của SummerTile", font=font, fill="#484C57")
for i, state in enumerate(("normal", "hover", "pressed", "disabled")):
    x, y = 32 + i * 352, 150
    im = Image.open(root / f"png/button_primary_{state}.png").convert("RGBA").resize((288, 48), Image.Resampling.NEAREST)
    board.paste(im, (x, y), im)
    d.text((x, y + 62), state, font=font, fill="#151D2E")
    d.text((x, y + 96), "96×16 · 6×1 ô", font=small, fill="#484C57")
for x, file, label in [(32, "button_icon_normal", "Nút icon 16×16 · 1 ô"), (360, "panel", "Panel 32×32 · 2×2 ô"),
                       (720, "level_card_hover", "Level 48×48 · 3×3 ô"), (1110, "checkbox_checked", "Checkbox 16×16")]:
    im = Image.open(root / f"png/{file}.png").convert("RGBA")
    im = im.resize((im.width * 3, im.height * 3), Image.Resampling.NEAREST)
    board.paste(im, (x, 340), im)
    d.text((x, 510), label, font=font, fill="#151D2E")
for i, h in enumerate(("2A2D36", "484C57", "6C717D", "A1A1AA", "E4E4E7", "B91C1C")):
    x = 32 + i * 232
    d.rectangle((x, 610, x + 48, 658), fill="#" + h, outline="#151D2E")
    d.text((x + 60, 620), "#" + h, font=small, fill="#151D2E")
d.text((32, 720), "Aseprite: grid 16 px · Godot: AtlasTexture + StyleBoxTexture margin 2 px", font=font, fill="#151D2E")
d.text((32, 758), "Đã nạp và kiểm tra trong Godot 4.7.2 · Project game chính chưa thay đổi", font=font, fill="#484C57")
board.save(root / "previews/SummerUI-v2-metal-detail.png")

with (root / "validation.txt").open("a", encoding="utf-8") as f:
    f.write("Python independent checks: all 55 PNGs exact palette, binary alpha, 16px bounds, >=16px gutters, source sizes and state sets passed\n")
    f.write("Godot 4.7.2: 55 AtlasTextures, 21 StyleBoxTextures, 55 multi-cell tiles loaded and verified\n")
zip_path = root.parent / "SummerUI-v2.zip"
with zipfile.ZipFile(zip_path, "w", zipfile.ZIP_DEFLATED) as archive:
    for path in sorted(root.rglob("*")):
        if path.is_file() and not path.name.endswith((".stdout.txt", ".stderr.txt", ".log")):
            archive.write(path, Path("SummerUI-v2") / path.relative_to(root))
with zipfile.ZipFile(zip_path) as archive:
    assert archive.testzip() is None
print(f"Verified {len(groups)} asset groups, {len(manifest['regions'])} PNGs, grid16 and Godot resources. ZIP: {zip_path.stat().st_size:,} bytes")
