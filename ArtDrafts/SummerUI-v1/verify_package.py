"""Check the delivered native asset exports and prepare a reusable ZIP."""
from pathlib import Path
from collections import defaultdict
from PIL import Image
import json
import zipfile

root = Path(__file__).resolve().parent
manifest = json.loads((root / "SummerUI-v1.json").read_text(encoding="utf-8"))
palette = set()
for line in (root / "SummerTile.gpl").read_text().splitlines():
    parts = line.split()
    if len(parts) >= 3 and all(p.isdigit() for p in parts[:3]):
        palette.add(tuple(map(int, parts[:3])) + (255,))
assert len(palette) == 43
atlas = Image.open(root / manifest["atlas"]).convert("RGBA")
groups = defaultdict(list)
expected = {
    "button_primary": (88, 18), "button_secondary": (88, 18), "button_icon": (20, 20),
    "panel": (32, 32), "hud_panel": (80, 24), "icons": (16, 16), "audio_icons": (16, 16),
    "logo": (112, 32), "menu_background": (320, 180), "level_card": (40, 40), "lock": (12, 12),
    "star_small": (8, 8), "star_large": (16, 16), "power_frame": (80, 10), "power_fill": (76, 6),
    "slider_track": (80, 6), "slider_fill": (76, 2), "slider_handle": (8, 12), "checkbox": (12, 12),
    "mouse_drag_hint": (48, 24), "check": (8, 8), "aim_head": (8, 8), "ball_ready_ring": (16, 16),
    "result_banner": (112, 24),
}
for region in manifest["regions"]:
    im = Image.open(root / region["png"]).convert("RGBA")
    assert im.size == expected[region["group"]]
    visible = {p for p in im.getdata() if p[3]}
    assert visible <= palette, region["id"]
    x, y = region["x"], region["y"]
    assert atlas.crop((x, y, x + im.width, y + im.height)).tobytes() == im.tobytes()
    groups[region["group"]].append(region["state"])
assert set(groups) == set(expected)
assert len(list((root / "sources").glob("*.aseprite"))) == 24
for group in groups:
    raw = (root / "sources" / f"{group}.aseprite").read_bytes()
    assert int.from_bytes(raw[4:6], "little") == 0xA5E0
    assert int.from_bytes(raw[8:10], "little") == expected[group][0]
    assert int.from_bytes(raw[10:12], "little") == expected[group][1]
for group in ("button_primary", "button_secondary", "button_icon"):
    assert groups[group] == ["normal", "hover", "pressed", "disabled"]
assert set(groups["level_card"]) == {"normal", "hover", "pressed", "locked"}
assert set(groups["star_small"]) == set(groups["star_large"]) == {"empty", "full"}
assert len(groups["icons"]) == 8 and len(groups["audio_icons"]) == 4
zip_path = root.parent / "SummerUI-v1.zip"
with zipfile.ZipFile(zip_path, "w", zipfile.ZIP_DEFLATED) as archive:
    for path in sorted(root.rglob("*")):
        if path.is_file() and not path.name.endswith((".stdout.txt", ".stderr.txt")):
            archive.write(path, Path("SummerUI-v1") / path.relative_to(root))
with zipfile.ZipFile(zip_path) as archive:
    assert archive.testzip() is None
print(f"Verified {len(groups)} groups, {len(manifest['regions'])} PNGs, 24 native Aseprite sources, exact palette and atlas regions.")
print(f"ZIP: {zip_path} ({zip_path.stat().st_size:,} bytes)")
