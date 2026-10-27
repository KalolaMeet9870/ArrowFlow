class_name HintButton
extends Button

## Reusable Hint button with custom vector lightbulb rendering and tactile pulse.

signal hint_triggered

var bulb_drawer: Control

func _ready() -> void:
	custom_minimum_size = Vector2(62, 62)
	pivot_offset = Vector2(31, 31)
	focus_mode = Control.FOCUS_NONE
	tooltip_text = "Get a Hint"

	var sb = StyleBoxFlat.new()
	sb.bg_color = Color("#FFFFFF")
	sb.border_width_left = 1
	sb.border_width_top = 1
	sb.border_width_right = 1
	sb.border_width_bottom = 1
	sb.border_color = Color("#E0D5C1")
	sb.corner_radius_top_left = 31
	sb.corner_radius_top_right = 31
	sb.corner_radius_bottom_left = 31
	sb.corner_radius_bottom_right = 31
	sb.shadow_size = 6
	sb.shadow_color = Color(0, 0, 0, 0.08)
	sb.shadow_offset = Vector2(0, 3)
	add_theme_stylebox_override("normal", sb)

	var h_sb = sb.duplicate() as StyleBoxFlat
	h_sb.bg_color = Color("#FBF8F2")
	add_theme_stylebox_override("hover", h_sb)

	var p_sb = sb.duplicate() as StyleBoxFlat
	p_sb.bg_color = Color("#EDE3D2")
	add_theme_stylebox_override("pressed", p_sb)

	bulb_drawer = Control.new()
	bulb_drawer.set_anchors_preset(Control.PRESET_FULL_RECT)
	bulb_drawer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bulb_drawer.draw.connect(_on_draw_bulb)
	add_child(bulb_drawer)

	pressed.connect(_on_pressed)

func _on_draw_bulb() -> void:
	var col = Color("#5D4037")
	bulb_drawer.draw_arc(Vector2(31, 24), 10.0, 0.45, PI - 0.45, 24, col, 2.2)
	bulb_drawer.draw_line(Vector2(24, 32), Vector2(26, 38), col, 2.2)
	bulb_drawer.draw_line(Vector2(38, 32), Vector2(36, 38), col, 2.2)
	bulb_drawer.draw_line(Vector2(26, 38), Vector2(36, 38), col, 2.2)
	bulb_drawer.draw_line(Vector2(27, 41), Vector2(35, 41), col, 2.0)
	var w_pts = PackedVector2Array([
		Vector2(26, 25), Vector2(28.5, 29.5), Vector2(31, 26), Vector2(33.5, 29.5), Vector2(36, 25)
	])
	bulb_drawer.draw_polyline(w_pts, col, 1.8)

func _on_pressed() -> void:
	if SoundManager.instance:
		SoundManager.instance.play_click()
	var tw = create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(self, "scale", Vector2(1.15, 1.15), 0.1)
	tw.tween_property(self, "scale", Vector2.ONE, 0.12)
	hint_triggered.emit()
