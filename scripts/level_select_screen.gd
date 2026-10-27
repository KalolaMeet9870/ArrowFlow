class_name LevelSelectScreen
extends Control

## Screen 3: Level Selection Screen for ArrowFlow (matching Reference Image 3).
## Features:
## - Top header with Back arrow ← and "Level Select" title.
## - Top Emerald League card with crown icon 👑 and level progress bar.
## - 5-column grid of circular level nodes:
##   * Completed: Warm orange filled circles
##   * Current unlocked: Highlighted orange circle
##   * Locked: Light cream/sand circles with lock icon 🔒
## - Preserves status banner and Next Level button for completed level transitions.

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
var emerald_card: PanelContainer
var lbl_league_progress: Label
var league_progress_bar: ProgressBar

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
		SafeAreaHelper.apply_safe_area_margins(main_margin, get_viewport(), 0.0, 16.0, 14.0, 14.0)

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

	# 1. Update Emerald League Progress Card
	var completed_count = completed_dict.size()
	if lbl_league_progress:
		lbl_league_progress.text = "%d/50" % completed_count
	if league_progress_bar:
		league_progress_bar.max_value = 50.0
		league_progress_bar.value = float(completed_count)

	# 2. Update Completion Banner
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

	# 3. Update Next Level Button
	var next_id = highest_unlocked
	if just_completed_id > 0:
		next_id = just_completed_id + 1

	if btn_next_level:
		if next_id <= 50:
			btn_next_level.text = "NEXT LEVEL (LEVEL %d) ▶" % next_id
			btn_next_level.disabled = false
			btn_next_level.modulate.a = 1.0
			if just_completed_id > 0:
				btn_next_level.show()
			else:
				btn_next_level.hide()
		else:
			btn_next_level.text = "ALL 50 LEVELS COMPLETED! 🏆"
			btn_next_level.disabled = true
			btn_next_level.modulate.a = 0.8
			btn_next_level.show()

	# 4. Rebuild 5-Column Grid of 50 Levels (Reference Image 3)
	if not grid_container:
		return

	for c in grid_container.get_children():
		grid_container.remove_child(c)
		c.queue_free()

	for lvl_i in range(1, 51):
		var btn = Button.new()
		btn.custom_minimum_size = Vector2(56, 56)
		btn.focus_mode = Control.FOCUS_NONE

		var is_unlocked = (lvl_i <= highest_unlocked)
		var is_done = completed_dict.has(str(lvl_i))
		var is_current = (lvl_i == highest_unlocked)

		var sb = StyleBoxFlat.new()
		sb.set_corner_radius_all(28) # Perfectly circular buttons matching Image 3

		if is_done:
			# Completed level: Warm orange filled circle with bold white level number
			sb.bg_color = Color("#D97324")
			sb.shadow_size = 3
			sb.shadow_color = Color(0, 0, 0, 0.08)
			sb.shadow_offset = Vector2(0, 2)
			btn.add_theme_color_override("font_color", Color.WHITE)
			btn.text = str(lvl_i)
			btn.add_theme_font_size_override("font_size", 16)
			btn.disabled = false
		elif is_current:
			# Current unlocked active level: Highlighted warm orange with bright accent border
			sb.bg_color = Color("#E67E22")
			sb.border_width_left = 3
			sb.border_width_top = 3
			sb.border_width_right = 3
			sb.border_width_bottom = 3
			sb.border_color = Color("#F9E79F")
			sb.shadow_size = 5
			sb.shadow_color = Color(0.9, 0.5, 0.2, 0.25)
			sb.shadow_offset = Vector2(0, 2)
			btn.add_theme_color_override("font_color", Color.WHITE)
			btn.text = str(lvl_i)
			btn.add_theme_font_size_override("font_size", 17)
			btn.disabled = false
		else:
			# STRICTLY LOCKED LEVEL: Inaccessible light sand circle with lock icon
			sb.bg_color = Color("#ECE3D5")
			sb.border_width_left = 1
			sb.border_width_top = 1
			sb.border_width_right = 1
			sb.border_width_bottom = 1
			sb.border_color = Color("#D8CBB7")
			btn.add_theme_color_override("font_color", Color("#9E9282"))
			btn.text = "🔒\n%d" % lvl_i
			btn.add_theme_font_size_override("font_size", 11)
			btn.disabled = true
			btn.mouse_filter = Control.MOUSE_FILTER_STOP

		btn.add_theme_stylebox_override("normal", sb)
		btn.add_theme_stylebox_override("disabled", sb)
		btn.add_theme_color_override("font_disabled_color", Color("#9E9282"))
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

	# --- 1. TOP HEADER BAR: [ ← ] [ Level Select ] ---
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

	lbl_title = Label.new()
	lbl_title.text = "Level Select"
	lbl_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl_title.add_theme_font_size_override("font_size", 22)
	lbl_title.add_theme_color_override("font_color", Color("#4A3525"))
	title_center.add_child(lbl_title)

	var dummy = Control.new()
	dummy.custom_minimum_size = Vector2(44, 44)
	top_bar.add_child(dummy)

	# --- 2. EMERALD LEAGUE PROGRESS CARD (Image 3) ---
	emerald_card = PanelContainer.new()
	var ec_sb = StyleBoxFlat.new()
	ec_sb.bg_color = Color("#F5EFE4")
	ec_sb.border_width_left = 1
	ec_sb.border_width_top = 1
	ec_sb.border_width_right = 1
	ec_sb.border_width_bottom = 1
	ec_sb.border_color = Color("#E5D7C3")
	ec_sb.set_corner_radius_all(18)
	ec_sb.shadow_size = 4
	ec_sb.shadow_color = Color(0, 0, 0, 0.05)
	ec_sb.shadow_offset = Vector2(0, 2)
	emerald_card.add_theme_stylebox_override("panel", ec_sb)
	vbox.add_child(emerald_card)

	var ec_margin = MarginContainer.new()
	ec_margin.add_theme_constant_override("margin_left", 16)
	ec_margin.add_theme_constant_override("margin_right", 16)
	ec_margin.add_theme_constant_override("margin_top", 12)
	ec_margin.add_theme_constant_override("margin_bottom", 12)
	emerald_card.add_child(ec_margin)

	var ec_vbox = VBoxContainer.new()
	ec_vbox.add_theme_constant_override("separation", 8)
	ec_margin.add_child(ec_vbox)

	var ec_row = HBoxContainer.new()
	ec_row.alignment = BoxContainer.ALIGNMENT_CENTER
	ec_vbox.add_child(ec_row)

	var lbl_crown = Label.new()
	lbl_crown.text = "👑"
	lbl_crown.add_theme_font_size_override("font_size", 18)
	ec_row.add_child(lbl_crown)

	var lbl_league_name = Label.new()
	lbl_league_name.text = "Emerald League"
	lbl_league_name.add_theme_font_size_override("font_size", 15)
	lbl_league_name.add_theme_color_override("font_color", Color("#4A3525"))
	ec_row.add_child(lbl_league_name)

	var ec_spacer = Control.new()
	ec_spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	ec_row.add_child(ec_spacer)

	lbl_league_progress = Label.new()
	lbl_league_progress.text = "1/50"
	lbl_league_progress.add_theme_font_size_override("font_size", 14)
	lbl_league_progress.add_theme_color_override("font_color", Color("#8D6E63"))
	ec_row.add_child(lbl_league_progress)

	# Smooth progress bar
	league_progress_bar = ProgressBar.new()
	league_progress_bar.custom_minimum_size = Vector2(0, 8)
	league_progress_bar.show_percentage = false
	var lpb_bg = StyleBoxFlat.new()
	lpb_bg.bg_color = Color("#E6DAC8")
	lpb_bg.set_corner_radius_all(4)
	league_progress_bar.add_theme_stylebox_override("background", lpb_bg)
	var lpb_fill = StyleBoxFlat.new()
	lpb_fill.bg_color = Color("#D97324")
	lpb_fill.set_corner_radius_all(4)
	league_progress_bar.add_theme_stylebox_override("fill", lpb_fill)
	ec_vbox.add_child(league_progress_bar)

	# --- 3. COMPLETION STATUS BANNER & QUICK NEXT LEVEL CTA ---
	status_banner = PanelContainer.new()
	var s_sb = StyleBoxFlat.new()
	s_sb.bg_color = Color("#E8F5E9")
	s_sb.border_width_left = 2
	s_sb.border_width_top = 2
	s_sb.border_width_right = 2
	s_sb.border_width_bottom = 2
	s_sb.border_color = Color("#4CAF50")
	s_sb.set_corner_radius_all(14)
	status_banner.add_theme_stylebox_override("panel", s_sb)
	vbox.add_child(status_banner)

	var s_margin = MarginContainer.new()
	s_margin.add_theme_constant_override("margin_left", 12)
	s_margin.add_theme_constant_override("margin_right", 12)
	s_margin.add_theme_constant_override("margin_top", 8)
	s_margin.add_theme_constant_override("margin_bottom", 8)
	status_banner.add_child(s_margin)

	lbl_status_banner = Label.new()
	lbl_status_banner.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl_status_banner.add_theme_font_size_override("font_size", 13)
	lbl_status_banner.add_theme_color_override("font_color", Color("#2E7D32"))
	s_margin.add_child(lbl_status_banner)
	status_banner.hide()

	btn_next_level = Button.new()
	btn_next_level.custom_minimum_size = Vector2(0, 48)
	btn_next_level.focus_mode = Control.FOCUS_NONE
	var nl_sb = StyleBoxFlat.new()
	nl_sb.bg_color = Color("#C8782E")
	nl_sb.set_corner_radius_all(16)
	btn_next_level.add_theme_stylebox_override("normal", nl_sb)
	btn_next_level.add_theme_font_size_override("font_size", 15)
	btn_next_level.add_theme_color_override("font_color", Color.WHITE)
	btn_next_level.pressed.connect(func():
		_play_click()
		var n_id = SaveManager.instance.highest_unlocked_level if SaveManager.instance else 1
		if just_completed_id > 0:
			n_id = just_completed_id + 1
		next_level_pressed.emit(n_id)
	)
	vbox.add_child(btn_next_level)
	btn_next_level.hide()

	# --- 4. SCROLLABLE 5-COLUMN GRID (Reference Image 3) ---
	var scroll = ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	vbox.add_child(scroll)

	var grid_center = CenterContainer.new()
	grid_center.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(grid_center)

	grid_container = GridContainer.new()
	grid_container.columns = 5
	grid_container.add_theme_constant_override("h_separation", 14)
	grid_container.add_theme_constant_override("v_separation", 16)
	grid_center.add_child(grid_container)

func _play_click() -> void:
	if SoundManager.instance:
		SoundManager.instance.play_click()
