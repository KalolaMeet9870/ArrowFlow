class_name LevelSelectScreen
extends Control

## Level Selection Screen for ArrowFlow
## Displays 50 levels with progression status, completed badges,
## next level quick-launch button, and strict locking for uncompleted levels.

signal level_selected(level_id: int)
signal next_level_pressed(next_level_id: int)
signal back_pressed

const SafeAreaHelper = preload("res://scripts/safe_area_helper.gd")

var bg_rect: ColorRect
var lbl_title: Label
var lbl_subtitle: Label
var status_banner: PanelContainer
var lbl_status_banner: Label
var btn_next_level: Button
var grid_container: GridContainer
var btn_back: Button
var main_margin: MarginContainer

var just_completed_id: int = -1

func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	if ThemeManager.instance:
		ThemeManager.instance.theme_changed.connect(apply_theme)
	_build_ui()
	refresh_levels(-1)

	resized.connect(_update_safe_areas)
	if get_tree() and get_tree().root:
		get_tree().root.size_changed.connect(_update_safe_areas)

	if ThemeManager.instance:
		apply_theme(ThemeManager.instance.get_current_theme())

func _update_safe_areas() -> void:
	if main_margin:
		SafeAreaHelper.apply_safe_area_margins(main_margin, get_viewport(), 0.0, 12.0, 8.0, 8.0)

func display_with_completion(level_id: int) -> void:
	just_completed_id = level_id
	show()
	refresh_levels(level_id)

func refresh_levels(completed_id: int = -1) -> void:
	just_completed_id = completed_id
	var highest_unlocked = 1
	var completed_dict: Dictionary = {}

	if SaveManager.instance:
		highest_unlocked = SaveManager.instance.highest_unlocked_level
		completed_dict = SaveManager.instance.completed_levels

	# 1. Update Completion Banner
	if just_completed_id > 0:
		var rec = completed_dict.get(str(just_completed_id), {})
		var best_m = int(rec.get("best_moves", 0))
		var hearts = int(rec.get("hearts", 3))
		var hearts_str = "💧".repeat(maxi(1, hearts))

		if status_banner and lbl_status_banner:
			lbl_status_banner.text = "LEVEL %d COMPLETED! ✓   Moves: %d   %s" % [just_completed_id, best_m, hearts_str]
			status_banner.show()
	else:
		if status_banner:
			status_banner.hide()

	# 2. Update Next Level Button
	var next_id = highest_unlocked
	if just_completed_id > 0:
		next_id = just_completed_id + 1

	if btn_next_level:
		if next_id <= 50:
			btn_next_level.text = "NEXT LEVEL (LEVEL %d) ▶" % next_id
			btn_next_level.disabled = false
			btn_next_level.modulate.a = 1.0
		else:
			btn_next_level.text = "ALL 50 LEVELS COMPLETED! 🏆"
			btn_next_level.disabled = true
			btn_next_level.modulate.a = 0.8

	# 3. Rebuild or Update Grid of 50 Levels
	if not grid_container:
		return

	for c in grid_container.get_children():
		c.queue_free()

	for lvl_i in range(1, 51):
		var btn = Button.new()
		btn.custom_minimum_size = Vector2(76, 68)
		btn.focus_mode = Control.FOCUS_NONE

		var is_unlocked = (lvl_i <= highest_unlocked)
		var is_done = completed_dict.has(str(lvl_i))
		var is_next = (lvl_i == next_id)

		var sb = StyleBoxFlat.new()
		sb.corner_radius_top_left = 12
		sb.corner_radius_top_right = 12
		sb.corner_radius_bottom_left = 12
		sb.corner_radius_bottom_right = 12

		if is_done:
			# Completed level: soft warm beige/green badge
			sb.bg_color = Color("#D8C3A5")
			sb.border_width_left = 2
			sb.border_width_top = 2
			sb.border_width_right = 2
			sb.border_width_bottom = 2
			sb.border_color = Color("#4A7C59")
			btn.add_theme_color_override("font_color", Color("#2E4F38"))
			var moves = int(completed_dict[str(lvl_i)].get("best_moves", 0))
			btn.text = "%d ✓\n%dm" % [lvl_i, moves]
			btn.add_theme_font_size_override("font_size", 13)
			btn.disabled = false
		elif is_unlocked:
			# Current unlocked active level: vibrant amber
			sb.bg_color = Color("#B37B24")
			btn.add_theme_color_override("font_color", Color("#FFFFFF"))
			btn.text = "%d\nPLAY" % lvl_i
			btn.add_theme_font_size_override("font_size", 14)
			btn.disabled = false
		else:
			# STRICTLY LOCKED LEVEL: Inaccessible
			sb.bg_color = Color("#E6DFD5")
			btn.add_theme_color_override("font_color", Color("#A0988E"))
			btn.text = "🔒\n%d" % lvl_i
			btn.add_theme_font_size_override("font_size", 13)
			btn.disabled = true
			btn.mouse_filter = Control.MOUSE_FILTER_STOP

		btn.add_theme_stylebox_override("normal", sb)
		var h_sb = sb.duplicate() as StyleBoxFlat
		h_sb.bg_color = sb.bg_color.lightened(0.12)
		btn.add_theme_stylebox_override("hover", h_sb)
		var p_sb = sb.duplicate() as StyleBoxFlat
		p_sb.bg_color = sb.bg_color.darkened(0.12)
		btn.add_theme_stylebox_override("pressed", p_sb)

		var target_lvl = lvl_i
		if is_unlocked:
			btn.pressed.connect(func():
				_play_click()
				level_selected.emit(target_lvl)
			)
		else:
			# Locked level feedback if clicked
			btn.gui_input.connect(func(ev: InputEvent):
				if ev is InputEventMouseButton and ev.pressed and ev.button_index == MOUSE_BUTTON_LEFT:
					if lbl_status_banner and status_banner:
						lbl_status_banner.text = "Level %d is locked! Complete Level %d to unlock." % [target_lvl, target_lvl - 1]
						status_banner.show()
			)

		grid_container.add_child(btn)

func apply_theme(theme: Dictionary) -> void:
	if bg_rect:
		bg_rect.color = theme.get("bg", Color("#FAF4E8"))
	if lbl_title:
		lbl_title.add_theme_color_override("font_color", theme.get("arrow_line", Color("#4A3525")))
	if lbl_subtitle:
		lbl_subtitle.add_theme_color_override("font_color", theme.get("subtitle", Color("#8D6E63")))

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
	vbox.add_theme_constant_override("separation", 14)
	main_margin.add_child(vbox)

	# --- TOP BAR ---
	var top_bar = HBoxContainer.new()
	top_bar.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_child(top_bar)

	btn_back = Button.new()
	btn_back.text = "⌂ HOME"
	btn_back.custom_minimum_size = Vector2(90, 42)
	btn_back.focus_mode = Control.FOCUS_NONE
	var back_sb = StyleBoxFlat.new()
	back_sb.bg_color = Color("#8D6E63")
	back_sb.corner_radius_top_left = 10
	back_sb.corner_radius_top_right = 10
	back_sb.corner_radius_bottom_left = 10
	back_sb.corner_radius_bottom_right = 10
	btn_back.add_theme_stylebox_override("normal", back_sb)
	btn_back.add_theme_font_size_override("font_size", 14)
	btn_back.add_theme_color_override("font_color", Color.WHITE)
	btn_back.pressed.connect(func():
		_play_click()
		back_pressed.emit()
	)
	top_bar.add_child(btn_back)

	var header_vbox = VBoxContainer.new()
	header_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header_vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	top_bar.add_child(header_vbox)

	lbl_title = Label.new()
	lbl_title.text = "LEVEL SELECT"
	lbl_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl_title.add_theme_font_size_override("font_size", 24)
	lbl_title.add_theme_color_override("font_color", Color("#4A3525"))
	header_vbox.add_child(lbl_title)

	lbl_subtitle = Label.new()
	lbl_subtitle.text = "50 Progressive Zen Levels"
	lbl_subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl_subtitle.add_theme_font_size_override("font_size", 13)
	lbl_subtitle.add_theme_color_override("font_color", Color("#8D6E63"))
	header_vbox.add_child(lbl_subtitle)

	# Spacer to balance top bar
	var dummy = Control.new()
	dummy.custom_minimum_size = Vector2(90, 42)
	top_bar.add_child(dummy)

	# --- COMPLETION STATUS BANNER ---
	status_banner = PanelContainer.new()
	var s_sb = StyleBoxFlat.new()
	s_sb.bg_color = Color("#E8F5E9")
	s_sb.border_width_left = 2
	s_sb.border_width_top = 2
	s_sb.border_width_right = 2
	s_sb.border_width_bottom = 2
	s_sb.border_color = Color("#4CAF50")
	s_sb.corner_radius_top_left = 12
	s_sb.corner_radius_top_right = 12
	s_sb.corner_radius_bottom_left = 12
	s_sb.corner_radius_bottom_right = 12
	s_sb.content_margin_left = 14
	s_sb.content_margin_right = 14
	s_sb.content_margin_top = 10
	s_sb.content_margin_bottom = 10
	status_banner.add_theme_stylebox_override("panel", s_sb)
	vbox.add_child(status_banner)

	lbl_status_banner = Label.new()
	lbl_status_banner.text = "LEVEL COMPLETED! ✓"
	lbl_status_banner.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl_status_banner.add_theme_font_size_override("font_size", 14)
	lbl_status_banner.add_theme_color_override("font_color", Color("#2E7D32"))
	status_banner.add_child(lbl_status_banner)
	status_banner.hide()

	# --- NEXT LEVEL ACTION BUTTON ---
	btn_next_level = Button.new()
	btn_next_level.text = "NEXT LEVEL (LEVEL 1) ▶"
	btn_next_level.custom_minimum_size = Vector2(280, 52)
	btn_next_level.focus_mode = Control.FOCUS_NONE
	var n_sb = StyleBoxFlat.new()
	n_sb.bg_color = Color("#B37B24")
	n_sb.corner_radius_top_left = 14
	n_sb.corner_radius_top_right = 14
	n_sb.corner_radius_bottom_left = 14
	n_sb.corner_radius_bottom_right = 14
	n_sb.shadow_size = 8
	n_sb.shadow_color = Color(0, 0, 0, 0.12)
	btn_next_level.add_theme_stylebox_override("normal", n_sb)
	btn_next_level.add_theme_font_size_override("font_size", 16)
	btn_next_level.add_theme_color_override("font_color", Color.WHITE)
	btn_next_level.pressed.connect(func():
		_play_click()
		var n_id = 1
		if SaveManager.instance:
			n_id = SaveManager.instance.highest_unlocked_level
			if just_completed_id > 0:
				n_id = just_completed_id + 1
		next_level_pressed.emit(n_id)
	)
	vbox.add_child(btn_next_level)

	# --- SCROLLABLE 50-LEVEL GRID ---
	var scroll = ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.add_child(scroll)

	var center_grid = CenterContainer.new()
	center_grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(center_grid)

	grid_container = GridContainer.new()
	grid_container.columns = 5
	grid_container.add_theme_constant_override("h_separation", 12)
	grid_container.add_theme_constant_override("v_separation", 12)
	center_grid.add_child(grid_container)

func _play_click() -> void:
	if SoundManager.instance:
		SoundManager.instance.play_click()
