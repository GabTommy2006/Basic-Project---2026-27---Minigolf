extends SceneTree

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
