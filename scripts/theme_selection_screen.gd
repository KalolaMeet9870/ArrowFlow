class_name ThemeSelectionScreen
extends Control

## Screen 12: Theme Selection Screen (matching Reference Image 12).
## Features:
## - Top header with Back arrow ← and Title "Theme".
## - 2x2 Grid of Theme Preview Cards:
##   * Card 0: Light / Eye Comfort (warm cream bg, espresso arrows, orange checkmark badge ✓)
##   * Card 1: Matcha Garden (light sage bg, forest green arrows)
##   * Card 2: Midnight Zen (dark slate bg, porcelain arrows)
##   * Card 3: Nordic Frost (cool slate blue bg, navy arrows)
## - Interactive selection that immediately updates ThemeManager and persists in SaveManager.

signal back_pressed
signal theme_selected(theme_index: int)

const SafeAreaHelper = preload("res://scripts/safe_area_helper.gd")

var bg_rect: ColorRect
var main_margin: MarginContainer
var btn_back: Button
var cards_grid: GridContainer
var card_controls: Array[Control] = []
var badge_controls: Array[Control] = []

func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	if ThemeManager.instance:
		ThemeManager.instance.theme_changed.connect(apply_theme)
	_build_ui()
	refresh_selection()

	resized.connect(_update_safe_areas)
	if get_tree() and get_tree().root:
		get_tree().root.size_changed.connect(_update_safe_areas)

	if ThemeManager.instance:
		apply_theme(ThemeManager.instance.get_current_theme())

func _update_safe_areas() -> void:
	if main_margin:
		SafeAreaHelper.apply_safe_area_margins(main_margin, get_viewport(), 0.0, 16.0, 16.0, 16.0)

func refresh_selection() -> void:
	var cur_idx = 0
	if ThemeManager.instance:
		cur_idx = ThemeManager.instance.current_theme_index

	for i in range(badge_controls.size()):
		badge_controls[i].visible = (i == cur_idx)

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
	vbox.add_theme_constant_override("separation", 24)
	main_margin.add_child(vbox)

	# --- 1. TOP HEADER: [ ← ] [ Theme ] ---
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
	lbl_title.text = "Theme"
	lbl_title.add_theme_font_size_override("font_size", 22)
	lbl_title.add_theme_color_override("font_color", Color("#4A3525"))
	title_center.add_child(lbl_title)

	var dummy = Control.new()
	dummy.custom_minimum_size = Vector2(44, 44)
	top_bar.add_child(dummy)

	# --- 2. 2x2 THEME PREVIEW CARDS (Image 12) ---
	var grid_center = CenterContainer.new()
	grid_center.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(grid_center)

	cards_grid = GridContainer.new()
	cards_grid.columns = 2
	cards_grid.add_theme_constant_override("h_separation", 20)
	cards_grid.add_theme_constant_override("v_separation", 24)
	grid_center.add_child(cards_grid)

	card_controls.clear()
	badge_controls.clear()

	# Map theme indices:
	# 0: Warm Paper / Light Eye Comfort
	# 2: Matcha Garden
	# 1: Midnight Zen
	# 3: Nordic Frost
	var theme_order = [0, 2, 1, 3]

	for i in range(theme_order.size()):
		var t_idx = theme_order[i]
		var theme_def = ThemeManager.THEMES[t_idx] if ThemeManager.THEMES.size() > t_idx else {}
		var card = _create_theme_card(t_idx, theme_def)
		cards_grid.add_child(card)

func _create_theme_card(theme_idx: int, theme_def: Dictionary) -> Control:
	var card_btn = Button.new()
	card_btn.custom_minimum_size = Vector2(160, 200)
	card_btn.focus_mode = Control.FOCUS_NONE

	var bg_col = theme_def.get("bg", Color("#FAF4E8"))
	var arrow_col = theme_def.get("arrow_line", Color("#4A3525"))

	var sb = StyleBoxFlat.new()
	sb.bg_color = bg_col
	sb.border_width_left = 2
	sb.border_width_top = 2
	sb.border_width_right = 2
	sb.border_width_bottom = 2
	sb.border_color = Color("#D5C8B5") if bg_col.get_luminance() > 0.4 else Color("#3A404D")
	sb.set_corner_radius_all(20)
	sb.shadow_size = 6
	sb.shadow_color = Color(0, 0, 0, 0.12)
	sb.shadow_offset = Vector2(0, 4)
	card_btn.add_theme_stylebox_override("normal", sb)

	var h_sb = sb.duplicate() as StyleBoxFlat
	h_sb.border_color = Color("#E67E22")
	card_btn.add_theme_stylebox_override("hover", h_sb)
	card_btn.add_theme_stylebox_override("pressed", h_sb)

	# Drawing mini arrow puzzle motif inside card
	var preview_ctrl = Control.new()
	preview_ctrl.set_anchors_preset(Control.PRESET_FULL_RECT)
	preview_ctrl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	preview_ctrl.draw.connect(func():
		var w = preview_ctrl.size.x
		var h = preview_ctrl.size.y
		var c = Vector2(w * 0.5, h * 0.5)

		# Mini arrows motif
		# Arrow 1: left then down
		var a1_1 = c + Vector2(-36, -30)
		var a1_2 = c + Vector2(-12, -30)
		var a1_3 = c + Vector2(-12, 10)
		preview_ctrl.draw_line(a1_1, a1_2, arrow_col, 3.5, true)
		preview_ctrl.draw_line(a1_2, a1_3, arrow_col, 3.5, true)
		preview_ctrl.draw_colored_polygon([
			a1_3,
			a1_3 + Vector2(-5, -8),
			a1_3 + Vector2(5, -8)
		], arrow_col)

		# Arrow 2: right then up
		var a2_1 = c + Vector2(-20, 36)
		var a2_2 = c + Vector2(24, 36)
		var a2_3 = c + Vector2(24, -20)
		preview_ctrl.draw_line(a2_1, a2_2, arrow_col, 3.5, true)
		preview_ctrl.draw_line(a2_2, a2_3, arrow_col, 3.5, true)
		preview_ctrl.draw_colored_polygon([
			a2_3,
			a2_3 + Vector2(-5, 8),
			a2_3 + Vector2(5, 8)
		], arrow_col)

		# Arrow 3: straight right
		var a3_1 = c + Vector2(-36, -5)
		var a3_2 = c + Vector2(6, -5)
		preview_ctrl.draw_line(a3_1, a3_2, arrow_col, 3.5, true)
		preview_ctrl.draw_colored_polygon([
			a3_2,
			a3_2 + Vector2(-8, -5),
			a3_2 + Vector2(-8, 5)
		], arrow_col)
	)
	card_btn.add_child(preview_ctrl)

	# Checkmark Badge on top-right (Image 12)
	var badge = PanelContainer.new()
	badge.custom_minimum_size = Vector2(28, 28)
	var b_sb = StyleBoxFlat.new()
	b_sb.bg_color = Color("#E67E22")
	b_sb.set_corner_radius_all(14)
	badge.add_theme_stylebox_override("panel", b_sb)
	badge.position = Vector2(120, 10)
	var lbl_check = Label.new()
	lbl_check.text = "✓"
	lbl_check.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl_check.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	lbl_check.add_theme_font_size_override("font_size", 14)
	lbl_check.add_theme_color_override("font_color", Color.WHITE)
	badge.add_child(lbl_check)
	card_btn.add_child(badge)

	card_controls.append(card_btn)
	badge_controls.append(badge)

	card_btn.pressed.connect(func():
		_play_click()
		_select_theme(theme_idx)
	)

	return card_btn

func _select_theme(idx: int) -> void:
	if ThemeManager.instance:
		ThemeManager.instance.set_theme(idx)
	refresh_selection()
	theme_selected.emit(idx)

func _play_click() -> void:
	if SoundManager.instance:
		SoundManager.instance.play_click()
