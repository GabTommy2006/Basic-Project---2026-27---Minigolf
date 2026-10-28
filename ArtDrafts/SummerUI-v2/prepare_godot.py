"""Create native Godot resources and a separate headless validation fixture."""
from pathlib import Path
import json
import shutil
from PIL import Image, ImageDraw, ImageFont

ROOT = Path(__file__).resolve().parent
manifest_path = ROOT / "SummerUI-v2.json"
data = json.loads(manifest_path.read_text(encoding="utf-8"))
PREFIX = "res://Assets/UI/SummerUI-v2/"
texture_count = style_count = 0

for region in data["regions"]:
    stem = Path(region["png"]).stem
    resource_path = f"godot/regions/{stem}.tres"
    x, y, w, h = (region[k] for k in ("x", "y", "width", "height"))
    if region["group"] == "menu_background":
        content = region["content_rect"]
        x, y, w, h = x + content["x"], y + content["y"], content["width"], content["height"]
    (ROOT / resource_path).write_text(f'''[gd_resource type="AtlasTexture" load_steps=2 format=3]

[ext_resource type="Texture2D" path="{PREFIX}SummerUI-v2.png" id="1_atlas"]

[resource]
atlas = ExtResource("1_atlas")
region = Rect2({x}, {y}, {w}, {h})
filter_clip = true
''', encoding="utf-8")
    region["godot_texture"] = resource_path
    region["godot_texture_size"] = {"width": w, "height": h}
    texture_count += 1
    if "nine_patch_margin" in region:
        margin = region["nine_patch_margin"]
        style_path = f"godot/styles/{stem}.tres"
        content_y = 2 if region["group"].startswith("button_") else 4
        (ROOT / style_path).write_text(f'''[gd_resource type="StyleBoxTexture" load_steps=2 format=3]

[ext_resource type="Texture2D" path="{PREFIX}{resource_path}" id="1_texture"]

[resource]
content_margin_left = 4.0
content_margin_top = {content_y}.0
content_margin_right = 4.0
content_margin_bottom = {content_y}.0
texture = ExtResource("1_texture")
texture_margin_left = {margin}.0
texture_margin_top = {margin}.0
texture_margin_right = {margin}.0
texture_margin_bottom = {margin}.0
''', encoding="utf-8")
        region["godot_style"] = style_path
        style_count += 1

lines = ['[gd_resource type="TileSet" load_steps=3 format=3]', '',
         f'[ext_resource type="Texture2D" path="{PREFIX}SummerUI-v2.png" id="1_atlas"]', '',
         '[sub_resource type="TileSetAtlasSource" id="UIAtlas"]',
         'texture = ExtResource("1_atlas")', 'texture_region_size = Vector2i(16, 16)']
for r in data["regions"]:
    key = f"{int(r['tile_x'])}:{int(r['tile_y'])}"
    lines += [f"{key}/size_in_atlas = Vector2i({int(r['tile_columns'])}, {int(r['tile_rows'])})", f"{key}/0 = 0"]
lines += ['', '[resource]', 'tile_size = Vector2i(16, 16)', 'sources/0 = SubResource("UIAtlas")', '']
(ROOT / "godot/tileset_16.tres").write_text("\n".join(lines), encoding="utf-8")
data["godot_import_folder"] = "Assets/UI/SummerUI-v2"
data["godot_texture_count"] = texture_count
data["godot_style_count"] = style_count
data["godot_tileset"] = "godot/tileset_16.tres"
manifest_path.write_text(json.dumps(data, ensure_ascii=False, indent=2), encoding="utf-8")

# Show the actual atlas on its 16px grid; grid strokes/labels are preview-only.
atlas = Image.open(ROOT / "SummerUI-v2.png").convert("RGBA")
scale, pad = 3, 48
grid = Image.new("RGB", (atlas.width * scale + pad * 2, atlas.height * scale + pad * 2), "#151D2E")
d = ImageDraw.Draw(grid)
for ty in range(32):
    for tx in range(32):
        x, y = pad + tx * 48, pad + ty * 48
        d.rectangle((x, y, x + 47, y + 47), fill="#2A2D36" if (tx + ty) % 2 else "#484C57")
enlarged = atlas.resize((1536, 1536), Image.Resampling.NEAREST)
grid.paste(enlarged, (pad, pad), enlarged)
label_font = ImageFont.truetype("C:/Windows/Fonts/consola.ttf", 15)
for index in range(33):
    p = pad + index * 48
    d.line((p, pad, p, pad + 1536), fill="#6C717D", width=1)
    d.line((pad, p, pad + 1536, p), fill="#6C717D", width=1)
    if index < 32:
        d.text((p + 14, 22), str(index), font=label_font, fill="#E4E4E7")
        d.text((14, p + 14), str(index), font=label_font, fill="#E4E4E7")
grid.save(ROOT / "previews/SummerUI-v2-grid16.png")

fixture = ROOT.parent / "_SummerUI-v2-GodotCheck"
target = fixture / "Assets/UI/SummerUI-v2"
target.mkdir(parents=True, exist_ok=True)
for name in ("SummerUI-v2.png", "SummerUI-v2.json"):
    shutil.copy2(ROOT / name, target / name)
shutil.copytree(ROOT / "godot", target / "godot", dirs_exist_ok=True)
(fixture / "project.godot").write_text('''config_version=5

[application]
config/name="SummerUI isolated resource verification"

[rendering]
renderer/rendering_method="gl_compatibility"
textures/default_filters/use_nearest_mipmap_filter=false
textures/canvas_textures/default_texture_filter=0
''', encoding="utf-8")
(fixture / "verify.gd").write_text('''extends SceneTree

func _initialize() -> void:
    var prefix := "res://Assets/UI/SummerUI-v2/"
    var manifest: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(prefix + "SummerUI-v2.json"))
    var styles := 0
    for row: Dictionary in manifest["regions"]:
        var tex := load(prefix + row["godot_texture"]) as AtlasTexture
        assert(tex != null, "AtlasTexture failed: " + row["id"])
        var expected := Vector2(row["godot_texture_size"]["width"], row["godot_texture_size"]["height"])
        assert(tex.get_size() == expected, "Texture dimensions failed: " + row["id"])
        if row.has("godot_style"):
            var style := load(prefix + row["godot_style"]) as StyleBoxTexture
            assert(style != null, "StyleBoxTexture failed: " + row["id"])
            assert(style.get_texture_margin(SIDE_LEFT) == 2.0, "Border must be 2px")
            assert(style.get_texture_margin(SIDE_TOP) == 2.0, "Border must be 2px")
            styles += 1
    var tiles := load(prefix + "godot/tileset_16.tres") as TileSet
    assert(tiles != null and tiles.tile_size == Vector2i(16, 16), "TileSet must be 16x16")
    var atlas := tiles.get_source(0) as TileSetAtlasSource
    assert(atlas != null and atlas.texture_region_size == Vector2i(16,16))
    assert(atlas.get_tiles_count() == manifest["regions"].size())
    for row: Dictionary in manifest["regions"]:
        var cell := Vector2i(row["tile_x"], row["tile_y"])
        assert(atlas.has_tile(cell), "Missing tile: " + row["id"])
        assert(atlas.get_tile_size_in_atlas(cell) == Vector2i(row["tile_columns"], row["tile_rows"]), "Multi-cell size mismatch")
    print("SUMMER_UI_V2_OK: %d AtlasTextures, %d StyleBoxTextures, %d multi-cell tiles on 16px grid" % [manifest["regions"].size(), styles, atlas.get_tiles_count()])
    quit(0)
''', encoding="utf-8")
print(f"Prepared {texture_count} AtlasTextures, {style_count} StyleBoxTextures and a 16px TileSet")
print(f"Isolated validation project: {fixture}")
