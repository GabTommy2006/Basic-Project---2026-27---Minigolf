extends RefCounted

const ROOT := "res://Assets/UI/SummerUI-v2/godot/"
const INK := Color("2a2d36")

static func texture(id: String) -> Texture2D:
	return load(ROOT + "regions/" + id + ".tres") as Texture2D

static func style(id: String) -> StyleBoxTexture:
	var box := (load(ROOT + "styles/" + id + ".tres") as StyleBoxTexture).duplicate() as StyleBoxTexture
	for side in [SIDE_LEFT, SIDE_TOP, SIDE_RIGHT, SIDE_BOTTOM]:
		box.set_texture_margin(side, 4.0)
		box.set_content_margin(side, 8.0)
	return box

static func theme() -> Theme:
	var result := Theme.new()
	result.default_font = load("res://Assets/Minecraft.otf") as Font
	result.default_font_size = 14
	for state in ["normal", "hover", "pressed", "disabled"]:
		result.set_stylebox(state, "Button", style("button_secondary_" + state))
	result.set_stylebox("focus", "Button", style("button_secondary_hover"))
	for state in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color"]:
		result.set_color(state, "Button", INK)
	result.set_color("font_disabled_color", "Button", Color("484c57"))
	result.set_color("font_color", "Label", INK)
	result.set_stylebox("panel", "Panel", style("panel"))
	result.set_stylebox("panel", "PanelContainer", style("panel"))
	result.set_stylebox("slider", "HSlider", style("slider_track"))
	result.set_stylebox("grabber_area", "HSlider", style("slider_fill"))
	result.set_stylebox("grabber_area_highlight", "HSlider", style("slider_fill"))
	for state in ["grabber", "grabber_highlight", "grabber_disabled"]:
		result.set_icon(state, "HSlider", texture("slider_handle_normal"))
	return result
