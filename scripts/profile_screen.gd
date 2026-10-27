class_name ProfileScreen
extends Control

## Screen 9: Profile Screen (matching Reference Image 9).
## Features:
## - Top header with Back arrow ← and Title "Profile".
## - Circular avatar with edit pencil badge.
## - Player Name and email/handle (from SaveManager).
## - Stats Cards:
##   * "X Levels Completed" (with Crown icon 👑)
##   * "Y Total Stars" (with Star icon ⭐)
## - Navigation List:
##   * Achievements >
##   * Statistics >
##   * Leaderboard > (opens Emerald League)
##   * Edit Profile >
##   * Delete Account > (with red styling)

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
		SafeAreaHelper.apply_safe_area_margins(main_margin, get_viewport(), 0.0, 16.0, 16.0, 16.0)

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
		lbl_completed_val.text = "%d\nLevels Completed" % comp_count
	if lbl_stars_val:
		lbl_stars_val.text = "%d\nTotal Stars" % stars_count

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
	vbox.add_theme_constant_override("separation", 16)
	main_margin.add_child(vbox)

	# --- 1. TOP HEADER: [ ← ] [ Profile ] ---
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
	lbl_title.text = "Profile"
	lbl_title.add_theme_font_size_override("font_size", 22)
	lbl_title.add_theme_color_override("font_color", Color("#4A3525"))
	title_center.add_child(lbl_title)

	var dummy = Control.new()
	dummy.custom_minimum_size = Vector2(44, 44)
	top_bar.add_child(dummy)

	# --- 2. CIRCULAR AVATAR & USER DETAILS (Image 9) ---
	var av_center = CenterContainer.new()
	vbox.add_child(av_center)

	var av_holder = Control.new()
	av_holder.custom_minimum_size = Vector2(96, 96)
	av_holder.draw.connect(func():
		var c = Vector2(48, 48)
		# Outer soft circle
		av_holder.draw_circle(c, 46.0, Color("#EADCC6"))
		av_holder.draw_circle(c, 44.0, Color("#FFFFFF"))
		# Blue silhouette avatar
		av_holder.draw_circle(c + Vector2(0, -10), 16.0, Color("#3498DB"))
		av_holder.draw_circle(c + Vector2(0, 26), 26.0, Color("#3498DB"))
		# Edit pencil badge on bottom right
		var badge_c = Vector2(74, 74)
		av_holder.draw_circle(badge_c, 14.0, Color("#E67E22"))
		av_holder.draw_circle(badge_c, 12.0, Color("#F39C12"))
	)
	av_center.add_child(av_holder)

	var lbl_pencil = Label.new()
	lbl_pencil.text = "✏"
	lbl_pencil.position = Vector2(66, 64)
	lbl_pencil.add_theme_font_size_override("font_size", 13)
	lbl_pencil.add_theme_color_override("font_color", Color.WHITE)
	av_holder.add_child(lbl_pencil)

	lbl_username = Label.new()
	lbl_username.text = "Player123"
	lbl_username.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl_username.add_theme_font_size_override("font_size", 20)
	lbl_username.add_theme_color_override("font_color", Color("#4A3525"))
	vbox.add_child(lbl_username)

	lbl_email = Label.new()
	lbl_email.text = "player@example.com"
	lbl_email.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl_email.add_theme_font_size_override("font_size", 13)
	lbl_email.add_theme_color_override("font_color", Color("#8D6E63"))
	vbox.add_child(lbl_email)

	# --- 3. STATS CARDS: [ 👑 Levels Completed ] [ ⭐ Total Stars ] (Image 9) ---
	var stats_hbox = HBoxContainer.new()
	stats_hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	stats_hbox.add_theme_constant_override("separation", 14)
	vbox.add_child(stats_hbox)

	# Card 1: Levels Completed
	var card1 = PanelContainer.new()
	card1.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var c1_sb = StyleBoxFlat.new()
	c1_sb.bg_color = Color("#FFFDF9")
	c1_sb.border_width_left = 1
	c1_sb.border_width_top = 1
	c1_sb.border_width_right = 1
	c1_sb.border_width_bottom = 1
	c1_sb.border_color = Color("#EAE0D0")
	c1_sb.set_corner_radius_all(18)
	card1.add_theme_stylebox_override("panel", c1_sb)
	stats_hbox.add_child(card1)

	var c1_margin = MarginContainer.new()
	c1_margin.add_theme_constant_override("margin_left", 14)
	c1_margin.add_theme_constant_override("margin_right", 14)
	c1_margin.add_theme_constant_override("margin_top", 12)
	c1_margin.add_theme_constant_override("margin_bottom", 12)
	card1.add_child(c1_margin)

	var c1_row = HBoxContainer.new()
	c1_row.alignment = BoxContainer.ALIGNMENT_CENTER
	c1_row.add_theme_constant_override("separation", 10)
	c1_margin.add_child(c1_row)

	var lbl_c1_icon = Label.new()
	lbl_c1_icon.text = "👑"
	lbl_c1_icon.add_theme_font_size_override("font_size", 24)
	c1_row.add_child(lbl_c1_icon)

	lbl_completed_val = Label.new()
	lbl_completed_val.text = "12\nLevels Completed"
	lbl_completed_val.add_theme_font_size_override("font_size", 13)
	lbl_completed_val.add_theme_color_override("font_color", Color("#4A3525"))
	c1_row.add_child(lbl_completed_val)

	# Card 2: Total Stars
	var card2 = PanelContainer.new()
	card2.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var c2_sb = StyleBoxFlat.new()
	c2_sb.bg_color = Color("#FFFDF9")
	c2_sb.border_width_left = 1
	c2_sb.border_width_top = 1
	c2_sb.border_width_right = 1
	c2_sb.border_width_bottom = 1
	c2_sb.border_color = Color("#EAE0D0")
	c2_sb.set_corner_radius_all(18)
	card2.add_theme_stylebox_override("panel", c2_sb)
	stats_hbox.add_child(card2)

	var c2_margin = MarginContainer.new()
	c2_margin.add_theme_constant_override("margin_left", 14)
	c2_margin.add_theme_constant_override("margin_right", 14)
	c2_margin.add_theme_constant_override("margin_top", 12)
	c2_margin.add_theme_constant_override("margin_bottom", 12)
	card2.add_child(c2_margin)

	var c2_row = HBoxContainer.new()
	c2_row.alignment = BoxContainer.ALIGNMENT_CENTER
	c2_row.add_theme_constant_override("separation", 10)
	c2_margin.add_child(c2_row)

	var lbl_c2_icon = Label.new()
	lbl_c2_icon.text = "⭐"
	lbl_c2_icon.add_theme_font_size_override("font_size", 24)
	c2_row.add_child(lbl_c2_icon)

	lbl_stars_val = Label.new()
	lbl_stars_val.text = "36\nTotal Stars"
	lbl_stars_val.add_theme_font_size_override("font_size", 13)
	lbl_stars_val.add_theme_color_override("font_color", Color("#4A3525"))
	c2_row.add_child(lbl_stars_val)

	# --- 4. NAVIGATION LIST CARD (Image 9) ---
	var list_card = PanelContainer.new()
	list_card.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var lc_sb = StyleBoxFlat.new()
	lc_sb.bg_color = Color("#FFFDF9")
	lc_sb.border_width_left = 1
	lc_sb.border_width_top = 1
	lc_sb.border_width_right = 1
	lc_sb.border_width_bottom = 1
	lc_sb.border_color = Color("#EAE0D0")
	lc_sb.set_corner_radius_all(22)
	list_card.add_theme_stylebox_override("panel", lc_sb)
	vbox.add_child(list_card)

	var lc_margin = MarginContainer.new()
	lc_margin.add_theme_constant_override("margin_left", 18)
	lc_margin.add_theme_constant_override("margin_right", 18)
	lc_margin.add_theme_constant_override("margin_top", 12)
	lc_margin.add_theme_constant_override("margin_bottom", 12)
	list_card.add_child(lc_margin)

	var list_vbox = VBoxContainer.new()
	list_vbox.add_theme_constant_override("separation", 8)
	lc_margin.add_child(list_vbox)

	# Row 1: Achievements >
	list_vbox.add_child(_create_nav_row("🏅", "Achievements", func():
		_play_click()
	))

	# Row 2: Statistics >
	list_vbox.add_child(_create_nav_row("📊", "Statistics", func():
		_play_click()
	))

	# Row 3: Leaderboard > (opens Emerald League)
	list_vbox.add_child(_create_nav_row("🏆", "Leaderboard", func():
		_play_click()
		leaderboard_requested.emit()
	))

	# Row 4: Edit Profile >
	list_vbox.add_child(_create_nav_row("👤", "Edit Profile", func():
		_play_click()
	))

	# Divider line
	var div = ColorRect.new()
	div.custom_minimum_size = Vector2(0, 1)
	div.color = Color("#EFE5D7")
	list_vbox.add_child(div)

	# Row 5: Delete Account > (Red)
	list_vbox.add_child(_create_nav_row("🗑", "Delete Account", func():
		_play_click()
	, Color("#E74C3C")))

func _create_nav_row(icon_str: String, title_str: String, on_click: Callable, title_color: Color = Color("#4A3525")) -> Control:
	var btn = Button.new()
	btn.custom_minimum_size = Vector2(0, 48)
	btn.focus_mode = Control.FOCUS_NONE
	var sb = StyleBoxFlat.new()
	sb.bg_color = Color(0, 0, 0, 0)
	btn.add_theme_stylebox_override("normal", sb)
	var h_sb = StyleBoxFlat.new()
	h_sb.bg_color = Color("#F8F2E8")
	h_sb.set_corner_radius_all(10)
	btn.add_theme_stylebox_override("hover", h_sb)
	btn.add_theme_stylebox_override("pressed", h_sb)

	var hbox = HBoxContainer.new()
	hbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	hbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hbox.add_theme_constant_override("separation", 14)
	btn.add_child(hbox)

	var lbl_i = Label.new()
	lbl_i.text = icon_str
	lbl_i.add_theme_font_size_override("font_size", 18)
	hbox.add_child(lbl_i)

	var lbl_t = Label.new()
	lbl_t.text = title_str
	lbl_t.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	lbl_t.add_theme_font_size_override("font_size", 15)
	lbl_t.add_theme_color_override("font_color", title_color)
	hbox.add_child(lbl_t)

	var lbl_arr = Label.new()
	lbl_arr.text = "›"
	lbl_arr.add_theme_font_size_override("font_size", 22)
	lbl_arr.add_theme_color_override("font_color", Color("#BDBDBD"))
	hbox.add_child(lbl_arr)

	btn.pressed.connect(on_click)
	return btn

func _play_click() -> void:
	if SoundManager.instance:
		SoundManager.instance.play_click()
