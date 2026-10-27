class_name HowToPlayScreen
extends Control

## Screen 11: How to Play Tutorial Screen (matching Reference Image 11).
## Features:
## - Top header with Back arrow ← and Title "How to Play".
## - Illustrated Arrow Diagram card with arrows and clear exit trajectories.
## - 3 Numbered Steps with circular badges:
##   * 1: "Tap an arrow to move it."
##   * 2: "The arrow moves in its direction if the path is clear."
##   * 3: "Clear all arrows from the grid to complete the level."
## - Large rounded orange "Got It" CTA button.

signal got_it_pressed
signal back_pressed

const SafeAreaHelper = preload("res://scripts/safe_area_helper.gd")

var bg_rect: ColorRect
var main_margin: MarginContainer
var btn_back: Button
var btn_got_it: Button

func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	if ThemeManager.instance:
		ThemeManager.instance.theme_changed.connect(apply_theme)
	_build_ui()

	resized.connect(_update_safe_areas)
	if get_tree() and get_tree().root:
		get_tree().root.size_changed.connect(_update_safe_areas)

	if ThemeManager.instance:
		apply_theme(ThemeManager.instance.get_current_theme())

func _update_safe_areas() -> void:
	if main_margin:
		SafeAreaHelper.apply_safe_area_margins(main_margin, get_viewport(), 0.0, 16.0, 16.0, 16.0)

func apply_theme(theme: Dictionary) -> void:
	if bg_rect:
		bg_rect.color = theme.get("bg", Color("#FAF4E8"))

func _build_ui() -> void:
	bg_rect = ColorRect.new()
	bg_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg_rect.color = Color("#FAF4E8")
	add_child(bg_rect)

	main_margin = MarginContainer.new()
	main_margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(main_margin)
	_update_safe_areas()

	var vbox = VBoxContainer.new()
	vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	vbox.add_theme_constant_override("separation", 18)
	main_margin.add_child(vbox)

	# --- 1. TOP HEADER: [ ← ] [ How to Play ] ---
	var top_bar = HBoxContainer.new()
	top_bar.alignment = BoxContainer.ALIGNMENT_BEGIN
	vbox.add_child(top_bar)

	btn_back = Button.new()
	btn_back.text = "←"
	btn_back.custom_minimum_size = Vector2(44, 44)
	btn_back.focus_mode = Control.FOCUS_NONE
	var back_sb = StyleBoxFlat.new()
	back_sb.bg_color = Color(0, 0, 0, 0)
	btn_back.add_theme_stylebox_override("normal", back_sb)
	btn_back.add_theme_stylebox_override("hover", back_sb)
	btn_back.add_theme_stylebox_override("pressed", back_sb)
	btn_back.add_theme_font_size_override("font_size", 28)
	btn_back.add_theme_color_override("font_color", Color("#4A3525"))
	btn_back.pressed.connect(func():
		_play_click()
		back_pressed.emit()
	)
	top_bar.add_child(btn_back)

	var title_center = CenterContainer.new()
	title_center.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top_bar.add_child(title_center)

	var lbl_title = Label.new()
	lbl_title.text = "How to Play"
	lbl_title.add_theme_font_size_override("font_size", 22)
	lbl_title.add_theme_color_override("font_color", Color("#4A3525"))
	title_center.add_child(lbl_title)

	var dummy = Control.new()
	dummy.custom_minimum_size = Vector2(44, 44)
	top_bar.add_child(dummy)

	# --- 2. ILLUSTRATED ARROW DIAGRAM CARD (Image 11) ---
	var diag_card = PanelContainer.new()
	diag_card.custom_minimum_size = Vector2(0, 240)
	var dc_sb = StyleBoxFlat.new()
	dc_sb.bg_color = Color("#FFFDF9")
	dc_sb.border_width_left = 1
	dc_sb.border_width_top = 1
	dc_sb.border_width_right = 1
	dc_sb.border_width_bottom = 1
	dc_sb.border_color = Color("#EAE0D0")
	dc_sb.set_corner_radius_all(24)
	dc_sb.shadow_size = 4
	dc_sb.shadow_color = Color(0, 0, 0, 0.06)
	dc_sb.shadow_offset = Vector2(0, 2)
	diag_card.add_theme_stylebox_override("panel", dc_sb)
	vbox.add_child(diag_card)

	var diag_ctrl = Control.new()
	diag_ctrl.set_anchors_preset(Control.PRESET_FULL_RECT)
	diag_ctrl.draw.connect(func():
		var w = diag_ctrl.size.x
		var h = diag_ctrl.size.y
		var c = Vector2(w * 0.5, h * 0.5)

		# Draw subtle dotted grid
		for gx in range(-3, 4):
			for gy in range(-3, 4):
				var dot_p = c + Vector2(gx * 30, gy * 30)
				diag_ctrl.draw_circle(dot_p, 1.8, Color(0.78, 0.72, 0.65, 0.45))

		# Arrow 1 (Pointing UP, Dark Brown): from (c.x - 30, c.y + 40) to (c.x - 30, c.y - 50)
		var p1_start = c + Vector2(-30, 40)
		var p1_end = c + Vector2(-30, -50)
		diag_ctrl.draw_line(p1_start, p1_end, Color("#4A3525"), 4.0, true)
		diag_ctrl.draw_colored_polygon([
			p1_end,
			p1_end + Vector2(-7, 12),
			p1_end + Vector2(7, 12)
		], Color("#4A3525"))

		# Arrow 2 (Orange Free Exit Arrow, L-shaped: right then up):
		# from (c.x - 45, c.y + 10) -> (c.x + 20, c.y + 10) -> (c.x + 20, c.y - 40) -> (c.x + 45, c.y - 40)
		var o1 = c + Vector2(-40, 10)
		var o2 = c + Vector2(15, 10)
		var o3 = c + Vector2(15, -45)
		var o4 = c + Vector2(45, -45)
		diag_ctrl.draw_line(o1, o2, Color("#E67E22"), 4.0, true)
		diag_ctrl.draw_line(o2, o3, Color("#E67E22"), 4.0, true)
		diag_ctrl.draw_line(o3, o4, Color("#E67E22"), 4.0, true)
		diag_ctrl.draw_colored_polygon([
			o4,
			o4 + Vector2(-12, -7),
			o4 + Vector2(-12, 7)
		], Color("#E67E22"))

		# Arrow 3 (Pointing DOWN, Dark Brown): from (c.x + 35, c.y - 15) to (c.x + 35, c.y + 55)
		var p3_start = c + Vector2(35, -15)
		var p3_end = c + Vector2(35, 55)
		diag_ctrl.draw_line(p3_start, p3_end, Color("#4A3525"), 4.0, true)
		diag_ctrl.draw_colored_polygon([
			p3_end,
			p3_end + Vector2(-7, -12),
			p3_end + Vector2(7, -12)
		], Color("#4A3525"))
	)
	diag_card.add_child(diag_ctrl)

	# --- 3. NUMBERED STEP INSTRUCTIONS (Image 11) ---
	var steps_vbox = VBoxContainer.new()
	steps_vbox.add_theme_constant_override("separation", 16)
	vbox.add_child(steps_vbox)

	steps_vbox.add_child(_create_step_row("1", "Tap an arrow to move it."))
	steps_vbox.add_child(_create_step_row("2", "The arrow moves in its direction\nif the path is clear."))
	steps_vbox.add_child(_create_step_row("3", "Clear all arrows from the grid\nto complete the level."))

	# Flexible Spacer
	var s_fill = Control.new()
	s_fill.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(s_fill)

	# --- 4. LARGE ORANGE "GOT IT" CTA BUTTON (Image 11) ---
	var btn_center = CenterContainer.new()
	vbox.add_child(btn_center)

	btn_got_it = Button.new()
	btn_got_it.text = "Got It"
	btn_got_it.custom_minimum_size = Vector2(340, 56)
	btn_got_it.focus_mode = Control.FOCUS_NONE
	var gi_sb = StyleBoxFlat.new()
	gi_sb.bg_color = Color("#E67E22")
	gi_sb.set_corner_radius_all(18)
	gi_sb.shadow_size = 5
	gi_sb.shadow_color = Color(0.9, 0.5, 0.2, 0.25)
	gi_sb.shadow_offset = Vector2(0, 3)
	btn_got_it.add_theme_stylebox_override("normal", gi_sb)
	var gi_h = gi_sb.duplicate() as StyleBoxFlat
	gi_h.bg_color = Color("#E67E22").lightened(0.1)
	btn_got_it.add_theme_stylebox_override("hover", gi_h)
	var gi_p = gi_sb.duplicate() as StyleBoxFlat
	gi_p.bg_color = Color("#E67E22").darkened(0.1)
	btn_got_it.add_theme_stylebox_override("pressed", gi_p)
	btn_got_it.add_theme_font_size_override("font_size", 18)
	btn_got_it.add_theme_color_override("font_color", Color.WHITE)
	btn_got_it.pressed.connect(func():
		_play_click()
		got_it_pressed.emit()
	)
	btn_center.add_child(btn_got_it)

	var b_spacer = Control.new()
	b_spacer.custom_minimum_size = Vector2(0, 16)
	vbox.add_child(b_spacer)

func _create_step_row(num_str: String, text_str: String) -> Control:
	var hbox = HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 16)

	# Circular badge
	var badge = PanelContainer.new()
	badge.custom_minimum_size = Vector2(32, 32)
	badge.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	var b_sb = StyleBoxFlat.new()
	b_sb.bg_color = Color("#D9532F")
	b_sb.set_corner_radius_all(16)
	badge.add_theme_stylebox_override("panel", b_sb)
	hbox.add_child(badge)

	var lbl_n = Label.new()
	lbl_n.text = num_str
	lbl_n.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl_n.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	lbl_n.add_theme_font_size_override("font_size", 15)
	lbl_n.add_theme_color_override("font_color", Color.WHITE)
	badge.add_child(lbl_n)

	var lbl_t = Label.new()
	lbl_t.text = text_str
	lbl_t.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	lbl_t.add_theme_font_size_override("font_size", 15)
	lbl_t.add_theme_color_override("font_color", Color("#4A3525"))
	hbox.add_child(lbl_t)

	return hbox

func _play_click() -> void:
	if SoundManager.instance:
		SoundManager.instance.play_click()
