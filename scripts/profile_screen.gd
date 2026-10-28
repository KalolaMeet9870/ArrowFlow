class_name ProfileScreen
extends Control

## Screen 9: Profile Screen (matching Reference Image 9).
## Features:
## - Top header with Back button (<) matching Game Screen and Title "Profile".
## - Circular avatar with blue silhouette and overlapping orange edit pencil badge.
## - Player Name and email/handle (from SaveManager).
## - Unified Stats Card:
##   * "X Levels Completed" (with Crown badge 👑)
##   * Vertical separator line
##   * "Y Total Stars" (with 3D Golden Star icon ⭐)
## - Two separate navigation card groups:
##   * Card Group 1: Achievements >, Statistics >, Leaderboard >
##   * Card Group 2: Edit Profile >, Delete Account >

signal back_pressed
signal leaderboard_requested

const SafeAreaHelper = preload("res://scripts/safe_area_helper.gd")

var bg_rect: ColorRect
var main_margin: MarginContainer
var btn_back: Button
var lbl_username: Label
var lbl_email: Label
var lbl_completed_val: Label
var lbl_stars_val: Label

func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	if ThemeManager.instance:
		ThemeManager.instance.theme_changed.connect(apply_theme)
	_build_ui()
	refresh_profile()

	resized.connect(_update_safe_areas)
	if get_tree() and get_tree().root:
		get_tree().root.size_changed.connect(_update_safe_areas)

	if ThemeManager.instance:
		apply_theme(ThemeManager.instance.get_current_theme())

func _update_safe_areas() -> void:
	if main_margin:
		SafeAreaHelper.apply_safe_area_margins(main_margin, get_viewport(), 10.0, 24.0, 32.0, 32.0)

func refresh_profile() -> void:
	var name_str = "Player123"
	var email_str = "player@example.com"
	var comp_count = 12
	var stars_count = 36

	if SaveManager.instance:
		name_str = SaveManager.instance.player_name
		email_str = SaveManager.instance.player_email
		comp_count = SaveManager.instance.get_completed_levels_count()
		stars_count = SaveManager.instance.get_total_stars()

	if lbl_username:
		lbl_username.text = name_str
	if lbl_email:
		lbl_email.text = email_str
	if lbl_completed_val:
		lbl_completed_val.text = str(comp_count)
	if lbl_stars_val:
		lbl_stars_val.text = str(stars_count)

func apply_theme(theme: Dictionary) -> void:
	if bg_rect:
		bg_rect.color = theme.get("bg", Color("#FAF3E7"))

func _build_ui() -> void:
	# 1. Warm cream paper background
	bg_rect = ColorRect.new()
	bg_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg_rect.color = Color("#FAF3E7")
	add_child(bg_rect)

	# Subtle paper grid dots
	var dots_control = Control.new()
	dots_control.set_anchors_preset(Control.PRESET_FULL_RECT)
	dots_control.mouse_filter = Control.MOUSE_FILTER_IGNORE
	dots_control.draw.connect(func():
		var dot_color = Color(0.24, 0.14, 0.07, 0.07)
		var step = 32.0
		var sz = dots_control.size
		var r = 1.6
		for x in range(16, int(sz.x), int(step)):
			for y in range(16, int(sz.y), int(step)):
				dots_control.draw_circle(Vector2(x, y), r, dot_color)
	)
	bg_rect.add_child(dots_control)

	# 2. Main Margins
	main_margin = MarginContainer.new()
	main_margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(main_margin)
	_update_safe_areas()

	var vbox = VBoxContainer.new()
	vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	vbox.add_theme_constant_override("separation", 22)
	main_margin.add_child(vbox)

	# ========================================================
	# --- 1. TOP HEADER: [ < ] [ Profile ] [ spacer ] ---
	# ========================================================
	var top_bar = HBoxContainer.new()
	top_bar.alignment = BoxContainer.ALIGNMENT_CENTER
	top_bar.custom_minimum_size = Vector2(0, 64)
	top_bar.add_theme_constant_override("separation", 10)
	vbox.add_child(top_bar)

	# Back button (<) matching game screen 1:1
	var icon_back = preload("res://assets/icons/icon_back_chevron.png")
	btn_back = _create_circle_btn("<", 30, 56.0, icon_back)
	btn_back.pressed.connect(func():
		_play_click()
		back_pressed.emit()
	)
	top_bar.add_child(btn_back)

	var title_center = CenterContainer.new()
	title_center.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top_bar.add_child(title_center)

	var lbl_title = Label.new()
	lbl_title.text = "Profile"
	lbl_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl_title.add_theme_font_override("font", preload("res://assets/fonts/round_bold.ttf"))
	lbl_title.add_theme_font_size_override("font_size", 44)
	lbl_title.add_theme_color_override("font_color", Color("#3E2312"))
	title_center.add_child(lbl_title)

	# Right dummy spacer ensuring title stays perfectly centered
	var dummy = Control.new()
	dummy.custom_minimum_size = Vector2(56, 56)
	top_bar.add_child(dummy)

	# ========================================================
	# --- 2. CIRCULAR AVATAR & USER DETAILS ---
	# ========================================================
	var av_center = CenterContainer.new()
	vbox.add_child(av_center)

	var tr_avatar = TextureRect.new()
	tr_avatar.texture = preload("res://assets/icons/icon_avatar_profile.png")
	tr_avatar.custom_minimum_size = Vector2(230, 230)
	tr_avatar.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	tr_avatar.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	av_center.add_child(tr_avatar)

	# User Info
	var info_box = VBoxContainer.new()
	info_box.alignment = BoxContainer.ALIGNMENT_CENTER
	info_box.add_theme_constant_override("separation", 4)
	vbox.add_child(info_box)

	lbl_username = Label.new()
	lbl_username.text = "Player123"
	lbl_username.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl_username.add_theme_font_override("font", preload("res://assets/fonts/round_bold.ttf"))
	lbl_username.add_theme_font_size_override("font_size", 42)
	lbl_username.add_theme_color_override("font_color", Color("#3E2312"))
	info_box.add_child(lbl_username)

	lbl_email = Label.new()
	lbl_email.text = "player@example.com"
	lbl_email.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl_email.add_theme_font_override("font", preload("res://assets/fonts/round_bold.ttf"))
	lbl_email.add_theme_font_size_override("font_size", 24)
	lbl_email.add_theme_color_override("font_color", Color("#9B8A7E"))
	info_box.add_child(lbl_email)

	# Spacer
	var sp1 = Control.new()
	sp1.custom_minimum_size = Vector2(0, 16)
	vbox.add_child(sp1)

	# ========================================================
	# --- 3. UNIFIED STATS CARD (Image 9) ---
	# ========================================================
	var stats_card = PanelContainer.new()
	stats_card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var sc_sb = StyleBoxFlat.new()
	sc_sb.bg_color = Color("#FFFFFF")
	sc_sb.border_width_left = 1
	sc_sb.border_width_top = 1
	sc_sb.border_width_right = 1
	sc_sb.border_width_bottom = 1
	sc_sb.border_color = Color("#EDE3D5")
	sc_sb.set_corner_radius_all(28)
	sc_sb.shadow_size = 10
	sc_sb.shadow_color = Color(0.25, 0.18, 0.10, 0.05)
	sc_sb.shadow_offset = Vector2(0, 4)
	stats_card.add_theme_stylebox_override("panel", sc_sb)
	vbox.add_child(stats_card)

	var sc_margin = MarginContainer.new()
	sc_margin.add_theme_constant_override("margin_left", 24)
	sc_margin.add_theme_constant_override("margin_right", 24)
	sc_margin.add_theme_constant_override("margin_top", 22)
	sc_margin.add_theme_constant_override("margin_bottom", 22)
	stats_card.add_child(sc_margin)

	var sc_hbox = HBoxContainer.new()
	sc_hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	sc_hbox.add_theme_constant_override("separation", 18)
	sc_margin.add_child(sc_hbox)

	# --- Left Half: Levels Completed with Crown ---
	var left_box = HBoxContainer.new()
	left_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	left_box.alignment = BoxContainer.ALIGNMENT_CENTER
	left_box.add_theme_constant_override("separation", 16)
	sc_hbox.add_child(left_box)

	# Peach rounded badge for crown
	var crown_badge = Panel.new()
	crown_badge.custom_minimum_size = Vector2(80, 80)
	var cb_sb = StyleBoxFlat.new()
	cb_sb.bg_color = Color("#FDF1E3")
	cb_sb.border_color = Color("#F8DFCA")
	cb_sb.set_border_width_all(1)
	cb_sb.set_corner_radius_all(22)
	crown_badge.add_theme_stylebox_override("panel", cb_sb)
	left_box.add_child(crown_badge)

	var tr_crown = TextureRect.new()
	tr_crown.texture = preload("res://assets/icons/icon_crown.png")
	tr_crown.custom_minimum_size = Vector2(56, 56)
	tr_crown.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	tr_crown.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	tr_crown.set_anchors_preset(Control.PRESET_FULL_RECT)
	tr_crown.mouse_filter = Control.MOUSE_FILTER_IGNORE
	crown_badge.add_child(tr_crown)

	var left_txt_vbox = VBoxContainer.new()
	left_txt_vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	left_txt_vbox.add_theme_constant_override("separation", 1)
	left_box.add_child(left_txt_vbox)

	lbl_completed_val = Label.new()
	lbl_completed_val.text = "12"
	lbl_completed_val.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	lbl_completed_val.add_theme_font_override("font", preload("res://assets/fonts/round_bold.ttf"))
	lbl_completed_val.add_theme_font_size_override("font_size", 52)
	lbl_completed_val.add_theme_color_override("font_color", Color("#3E2312"))
	left_txt_vbox.add_child(lbl_completed_val)

	var lbl_comp_desc = Label.new()
	lbl_comp_desc.text = "Levels Completed"
	lbl_comp_desc.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	lbl_comp_desc.add_theme_font_override("font", preload("res://assets/fonts/round_bold.ttf"))
	lbl_comp_desc.add_theme_font_size_override("font_size", 22)
	lbl_comp_desc.add_theme_color_override("font_color", Color("#9B8A7E"))
	left_txt_vbox.add_child(lbl_comp_desc)

	# Vertical Divider Line
	var v_div = ColorRect.new()
	v_div.custom_minimum_size = Vector2(1, 68)
	v_div.color = Color("#EAE0D2")
	sc_hbox.add_child(v_div)

	# --- Right Half: Total Stars ---
	var right_box = HBoxContainer.new()
	right_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	right_box.alignment = BoxContainer.ALIGNMENT_CENTER
	right_box.add_theme_constant_override("separation", 16)
	sc_hbox.add_child(right_box)

	var tr_star = TextureRect.new()
	tr_star.texture = preload("res://assets/icons/icon_star_3d.png")
	tr_star.custom_minimum_size = Vector2(80, 80)
	tr_star.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	tr_star.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	right_box.add_child(tr_star)

	var right_txt_vbox = VBoxContainer.new()
	right_txt_vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	right_txt_vbox.add_theme_constant_override("separation", 1)
	right_box.add_child(right_txt_vbox)

	lbl_stars_val = Label.new()
	lbl_stars_val.text = "36"
	lbl_stars_val.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	lbl_stars_val.add_theme_font_override("font", preload("res://assets/fonts/round_bold.ttf"))
	lbl_stars_val.add_theme_font_size_override("font_size", 52)
	lbl_stars_val.add_theme_color_override("font_color", Color("#3E2312"))
	right_txt_vbox.add_child(lbl_stars_val)

	var lbl_stars_desc = Label.new()
	lbl_stars_desc.text = "Total Stars"
	lbl_stars_desc.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	lbl_stars_desc.add_theme_font_override("font", preload("res://assets/fonts/round_bold.ttf"))
	lbl_stars_desc.add_theme_font_size_override("font_size", 22)
	lbl_stars_desc.add_theme_color_override("font_color", Color("#9B8A7E"))
	right_txt_vbox.add_child(lbl_stars_desc)

	# ========================================================
	# --- 4. NAVIGATION CARD GROUP 1 (Image 9) ---
	# ========================================================
	var group1_card = PanelContainer.new()
	group1_card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var g1_sb = sc_sb.duplicate() as StyleBoxFlat
	group1_card.add_theme_stylebox_override("panel", g1_sb)
	vbox.add_child(group1_card)

	var g1_margin = MarginContainer.new()
	g1_margin.add_theme_constant_override("margin_left", 24)
	g1_margin.add_theme_constant_override("margin_right", 24)
	g1_margin.add_theme_constant_override("margin_top", 10)
	g1_margin.add_theme_constant_override("margin_bottom", 10)
	group1_card.add_child(g1_margin)

	var g1_vbox = VBoxContainer.new()
	g1_vbox.add_theme_constant_override("separation", 4)
	g1_margin.add_child(g1_vbox)

	# Row 1: Achievements >
	g1_vbox.add_child(_create_nav_row(
		preload("res://assets/icons/icon_profile_achieve.png"),
		"Achievements",
		func(): _play_click()
	))
	g1_vbox.add_child(_create_divider())

	# Row 2: Statistics >
	g1_vbox.add_child(_create_nav_row(
		preload("res://assets/icons/icon_profile_stats.png"),
		"Statistics",
		func(): _play_click()
	))
	g1_vbox.add_child(_create_divider())

	# Row 3: Leaderboard >
	g1_vbox.add_child(_create_nav_row(
		preload("res://assets/icons/icon_profile_leaderboard.png"),
		"Leaderboard",
		func():
			_play_click()
			leaderboard_requested.emit()
	))

	# ========================================================
	# --- 5. NAVIGATION CARD GROUP 2 (Image 9) ---
	# ========================================================
	var group2_card = PanelContainer.new()
	group2_card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var g2_sb = sc_sb.duplicate() as StyleBoxFlat
	group2_card.add_theme_stylebox_override("panel", g2_sb)
	vbox.add_child(group2_card)

	var g2_margin = MarginContainer.new()
	g2_margin.add_theme_constant_override("margin_left", 24)
	g2_margin.add_theme_constant_override("margin_right", 24)
	g2_margin.add_theme_constant_override("margin_top", 10)
	g2_margin.add_theme_constant_override("margin_bottom", 10)
	group2_card.add_child(g2_margin)

	var g2_vbox = VBoxContainer.new()
	g2_vbox.add_theme_constant_override("separation", 4)
	g2_margin.add_child(g2_vbox)

	# Row 4: Edit Profile >
	g2_vbox.add_child(_create_nav_row(
		preload("res://assets/icons/icon_profile_edit.png"),
		"Edit Profile",
		func(): _play_click()
	))
	g2_vbox.add_child(_create_divider())

	# Row 5: Delete Account >
	g2_vbox.add_child(_create_nav_row(
		preload("res://assets/icons/icon_profile_delete.png"),
		"Delete Account",
		func(): _play_click()
	))

func _create_divider() -> ColorRect:
	var div = ColorRect.new()
	div.custom_minimum_size = Vector2(0, 1)
	div.color = Color("#F3EBE0")
	return div

func _create_nav_row(icon_tex: Texture2D, title_str: String, on_click: Callable, title_color: Color = Color("#3E2312")) -> Control:
	var btn = Button.new()
	btn.custom_minimum_size = Vector2(0, 82)
	btn.focus_mode = Control.FOCUS_NONE
	var sb = StyleBoxFlat.new()
	sb.bg_color = Color(0, 0, 0, 0)
	btn.add_theme_stylebox_override("normal", sb)
	var h_sb = StyleBoxFlat.new()
	h_sb.bg_color = Color(0.9, 0.85, 0.78, 0.22)
	h_sb.set_corner_radius_all(14)
	btn.add_theme_stylebox_override("hover", h_sb)
	btn.add_theme_stylebox_override("pressed", h_sb)

	var hbox = HBoxContainer.new()
	hbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	hbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hbox.add_theme_constant_override("separation", 22)
	btn.add_child(hbox)

	var tr = TextureRect.new()
	tr.texture = icon_tex
	tr.custom_minimum_size = Vector2(50, 50)
	tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	tr.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hbox.add_child(tr)

	var lbl_t = Label.new()
	lbl_t.text = title_str
	lbl_t.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	lbl_t.add_theme_font_override("font", preload("res://assets/fonts/round_bold.ttf"))
	lbl_t.add_theme_font_size_override("font_size", 30)
	lbl_t.add_theme_color_override("font_color", title_color)
	hbox.add_child(lbl_t)

	var tr_arr = TextureRect.new()
	tr_arr.texture = preload("res://assets/icons/icon_chevron_right.png")
	tr_arr.custom_minimum_size = Vector2(20, 30)
	tr_arr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	tr_arr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	tr_arr.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hbox.add_child(tr_arr)

	btn.pressed.connect(on_click)
	return btn

func _create_circle_btn(text: String, font_size: int, btn_size: float = 48.0, icon_tex: Texture2D = null) -> Button:
	var btn = Button.new()
	btn.custom_minimum_size = Vector2(btn_size, btn_size)
	btn.focus_mode = Control.FOCUS_NONE
	if icon_tex != null:
		var tr = TextureRect.new()
		tr.texture = icon_tex
		tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		tr.set_anchors_preset(Control.PRESET_FULL_RECT)
		tr.offset_left = 4.0
		tr.offset_top = 4.0
		tr.offset_right = -4.0
		tr.offset_bottom = -4.0
		tr.mouse_filter = Control.MOUSE_FILTER_IGNORE
		btn.add_child(tr)
	else:
		btn.text = text
		btn.add_theme_font_size_override("font_size", font_size)
		btn.add_theme_color_override("font_color", Color("#3E2312"))

	var norm_sb = StyleBoxFlat.new()
	norm_sb.bg_color = Color(0, 0, 0, 0)
	var press_sb = StyleBoxFlat.new()
	press_sb.bg_color = Color(0.8, 0.75, 0.68, 0.22)
	press_sb.set_corner_radius_all(int(btn_size * 0.5))
	btn.add_theme_stylebox_override("normal", norm_sb)
	btn.add_theme_stylebox_override("hover", norm_sb)
	btn.add_theme_stylebox_override("pressed", press_sb)
	return btn

func _play_click() -> void:
	if SoundManager.instance:
		SoundManager.instance.play_click()
