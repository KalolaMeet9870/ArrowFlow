class_name HomeScreen
extends Control

## Modern, mobile-first Home Screen for ArrowFlow.
## Designed to match Reference Image 2:
## - Top bar: Profile Avatar with golden frame, Coin Counter pill (⭐ / 🟡), and Settings gear.
## - Horizontal Carousel Cards:
##   * "Emerald League" (Golden-orange gradient, timer, 3D emerald badge, rank 38th, Play pill)
##   * "Daily Challenge" (Terracotta red gradient, Oct 27 date, 3-star silver trophy, Start pill)
##   * "Event Countryside Quest" (Lush green gradient, flora artwork, Play pill)
## - Center Title: "ArrowFlow" in bold warm brown typography with balanced breathing space.
## - Level Progression Track: Continuous connecting rail with 5 circular nodes centered on current level.
## - Primary CTA: Large Warm Caramel "Play / Level X" button with subtle 3D bevel.
## - AdMob bottom banner integration with zero overlap.

signal play_pressed
signal daily_puzzle_pressed
signal settings_pressed
signal level_select_pressed
signal profile_pressed
signal event_pressed

const DailyStreakPopupClass = preload("res://scripts/daily_streak_popup.gd")
const EmeraldLeaguePopupClass = preload("res://scripts/emerald_league_popup.gd")
const SafeAreaHelper = preload("res://scripts/safe_area_helper.gd")

var bg_rect: ColorRect
var bg_dots: Control
var main_margin: MarginContainer
var lbl_coins: Label
var lbl_title: Label
var cta_btn: Button
var cta_title: Label
var cta_sub: Label
var lbl_progress: Label
var level_track_container: HBoxContainer
var daily_streak_popup: Control
var emerald_league_popup: Control

func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	if ThemeManager.instance:
		ThemeManager.instance.theme_changed.connect(apply_theme)
	visibility_changed.connect(_on_visibility_changed)

	_build_ui()
	refresh_progress()

	resized.connect(_update_safe_areas)
	if get_tree() and get_tree().root:
		get_tree().root.size_changed.connect(_update_safe_areas)

	if ThemeManager.instance:
		apply_theme(ThemeManager.instance.get_current_theme())
	if visible and AdMobManager.instance:
		AdMobManager.instance.show_banner()

func _update_safe_areas() -> void:
	if main_margin:
		# Top safe inset for status bar / notch; bottom safe inset + 64px for bottom banner ad
		SafeAreaHelper.apply_safe_area_margins(main_margin, get_viewport(), 8.0, 68.0, 16.0, 16.0)

func _on_visibility_changed() -> void:
	if not AdMobManager.instance:
		return
	if visible:
		AdMobManager.instance.show_banner()
		refresh_progress()
	else:
		AdMobManager.instance.hide_banner()

func refresh_progress() -> void:
	var cur = 1
	var coins_val = 2
	if SaveManager.instance:
		cur = SaveManager.instance.current_level
		coins_val = maxi(2, SaveManager.instance.coins)

	if lbl_coins:
		lbl_coins.text = str(coins_val)

	if cta_sub:
		cta_sub.text = "Level %d" % cur

	if cta_title:
		cta_title.text = "Play"

	_rebuild_level_track(cur)

func apply_theme(theme: Dictionary) -> void:
	if bg_rect:
		bg_rect.color = theme.get("bg", Color("#FAF5EC"))
	if lbl_title:
		lbl_title.add_theme_color_override("font_color", theme.get("arrow_line", Color("#4A3525")))

func _build_ui() -> void:
	# 1. Warm zen cream background with subtle paper dots
	bg_rect = ColorRect.new()
	bg_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg_rect.color = Color("#FAF5EC")
	add_child(bg_rect)

	# Faint zen paper dot pattern matching reference image
	bg_dots = Control.new()
	bg_dots.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg_dots.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bg_dots.draw.connect(func():
		var s = size
		if s.x < 10 or s.y < 10:
			return
		var step = 32.0
		var dot_col = Color(0.78, 0.72, 0.64, 0.22)
		var cx = step * 0.5
		while cx < s.x:
			var cy = step * 0.5
			while cy < s.y:
				bg_dots.draw_circle(Vector2(cx, cy), 1.2, dot_col)
				cy += step
			cx += step
	)
	add_child(bg_dots)

	# Main vertical layout container respecting device safe areas
	main_margin = MarginContainer.new()
	main_margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(main_margin)
	_update_safe_areas()

	var main_vbox = VBoxContainer.new()
	main_vbox.alignment = BoxContainer.ALIGNMENT_BEGIN
	main_vbox.add_theme_constant_override("separation", 14)
	main_margin.add_child(main_vbox)

	# ==========================================
	# A. TOP APP BAR (Avatar, Coins Pill, Settings)
	# ==========================================
	var top_bar = HBoxContainer.new()
	top_bar.alignment = BoxContainer.ALIGNMENT_CENTER
	main_vbox.add_child(top_bar)

	# 1. Profile Avatar with golden ribbon frame (Image 2)
	var avatar_wrapper = Control.new()
	avatar_wrapper.custom_minimum_size = Vector2(50, 50)
	top_bar.add_child(avatar_wrapper)

	var avatar_btn = Button.new()
	avatar_btn.name = "AvatarBtn"
	avatar_btn.set_anchors_preset(Control.PRESET_FULL_RECT)
	avatar_btn.focus_mode = Control.FOCUS_NONE
	var av_sb = StyleBoxFlat.new()
	av_sb.bg_color = Color("#FFF9EE")
	av_sb.border_width_left = 3
	av_sb.border_width_top = 3
	av_sb.border_width_right = 3
	av_sb.border_width_bottom = 3
	av_sb.border_color = Color("#E69A52")
	av_sb.set_corner_radius_all(14)
	av_sb.shadow_size = 4
	av_sb.shadow_color = Color(0, 0, 0, 0.08)
	av_sb.shadow_offset = Vector2(0, 2)
	avatar_btn.add_theme_stylebox_override("normal", av_sb)
	avatar_btn.add_theme_stylebox_override("hover", av_sb)
	avatar_btn.add_theme_stylebox_override("pressed", av_sb)
	avatar_btn.text = "👤"
	avatar_btn.add_theme_font_size_override("font_size", 22)
	avatar_btn.pressed.connect(func():
		_play_click()
		profile_pressed.emit()
	)
	avatar_wrapper.add_child(avatar_btn)

	# Small crown/ribbon tag on top-left of avatar
	var ribbon_tag = PanelContainer.new()
	var rt_sb = StyleBoxFlat.new()
	rt_sb.bg_color = Color("#E74C3C")
	rt_sb.set_corner_radius_all(6)
	ribbon_tag.add_theme_stylebox_override("panel", rt_sb)
	ribbon_tag.position = Vector2(-2, -3)
	ribbon_tag.custom_minimum_size = Vector2(16, 12)
	var lbl_rt = Label.new()
	lbl_rt.text = "★"
	lbl_rt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl_rt.add_theme_font_size_override("font_size", 9)
	lbl_rt.add_theme_color_override("font_color", Color.WHITE)
	ribbon_tag.add_child(lbl_rt)
	avatar_wrapper.add_child(ribbon_tag)

	# Expanding Spacer
	var bar_spacer = Control.new()
	bar_spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top_bar.add_child(bar_spacer)

	# 2. Golden Coin Pill (🟡 2) matching Image 2
	var coin_pill = PanelContainer.new()
	coin_pill.custom_minimum_size = Vector2(84, 38)
	var cp_sb = StyleBoxFlat.new()
	cp_sb.bg_color = Color("#F3ECE0")
	cp_sb.border_width_left = 1
	cp_sb.border_width_top = 1
	cp_sb.border_width_right = 1
	cp_sb.border_width_bottom = 1
	cp_sb.border_color = Color("#E5D7C5")
	cp_sb.set_corner_radius_all(19)
	cp_sb.shadow_size = 3
	cp_sb.shadow_color = Color(0, 0, 0, 0.06)
	coin_pill.add_theme_stylebox_override("panel", cp_sb)
	top_bar.add_child(coin_pill)

	var cp_hbox = HBoxContainer.new()
	cp_hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	cp_hbox.add_theme_constant_override("separation", 6)
	coin_pill.add_child(cp_hbox)

	var lbl_coin_icon = Label.new()
	lbl_coin_icon.text = "🟡"
	lbl_coin_icon.add_theme_font_size_override("font_size", 15)
	cp_hbox.add_child(lbl_coin_icon)

	lbl_coins = Label.new()
	lbl_coins.text = "2"
	lbl_coins.add_theme_font_size_override("font_size", 17)
	lbl_coins.add_theme_color_override("font_color", Color("#A0652D"))
	cp_hbox.add_child(lbl_coins)

	# Spacer
	var bar_spacer2 = Control.new()
	bar_spacer2.custom_minimum_size = Vector2(10, 0)
	top_bar.add_child(bar_spacer2)

	# 3. Settings Gear Button (Image 2)
	var btn_settings = Button.new()
	btn_settings.custom_minimum_size = Vector2(44, 44)
	btn_settings.focus_mode = Control.FOCUS_NONE
	var set_sb = StyleBoxFlat.new()
	set_sb.bg_color = Color(0, 0, 0, 0)
	btn_settings.add_theme_stylebox_override("normal", set_sb)
	btn_settings.add_theme_stylebox_override("hover", set_sb)
	btn_settings.add_theme_stylebox_override("pressed", set_sb)
	btn_settings.text = "⚙"
	btn_settings.add_theme_font_size_override("font_size", 24)
	btn_settings.add_theme_color_override("font_color", Color("#7D6F64"))
	btn_settings.pressed.connect(func():
		_play_click()
		settings_pressed.emit()
	)
	top_bar.add_child(btn_settings)

	# ==========================================
	# B. FEATURED CAROUSEL CARDS (Image 2)
	# ==========================================
	var scroll_cards = ScrollContainer.new()
	scroll_cards.custom_minimum_size = Vector2(0, 295)
	scroll_cards.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	scroll_cards.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	main_vbox.add_child(scroll_cards)

	var cards_hbox = HBoxContainer.new()
	cards_hbox.add_theme_constant_override("separation", 16)
	scroll_cards.add_child(cards_hbox)

	# Card 1: Emerald League (Image 2 & 5)
	cards_hbox.add_child(_create_emerald_league_card())

	# Card 2: Daily Challenge (Image 2)
	cards_hbox.add_child(_create_daily_challenge_card())

	# Card 3: Events Countryside Quest (Image 2)
	cards_hbox.add_child(_create_event_card())

	# Balanced Spacing between Cards and Title
	var v_spacer = Control.new()
	v_spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	main_vbox.add_child(v_spacer)

	# ==========================================
	# C. GAME TITLE: "ArrowFlow"
	# ==========================================
	var title_vbox = VBoxContainer.new()
	title_vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	title_vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	main_vbox.add_child(title_vbox)

	lbl_title = Label.new()
	lbl_title.text = "ArrowFlow"
	lbl_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl_title.add_theme_font_size_override("font_size", 42)
	lbl_title.add_theme_color_override("font_color", Color("#4A3525"))
	title_vbox.add_child(lbl_title)

	var lbl_tagline = Label.new()
	lbl_tagline.text = "CLEAR THE PATH"
	lbl_tagline.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl_tagline.add_theme_font_size_override("font_size", 13)
	lbl_tagline.add_theme_color_override("font_color", Color("#8C7767"))
	title_vbox.add_child(lbl_tagline)

	# Balanced Spacing between Title and Level Track
	var v_spacer2 = Control.new()
	v_spacer2.size_flags_vertical = Control.SIZE_EXPAND_FILL
	main_vbox.add_child(v_spacer2)

	# ==========================================
	# D. LEVEL PROGRESSION TRACK (Image 2)
	# ==========================================
	var track_holder = CenterContainer.new()
	main_vbox.add_child(track_holder)

	level_track_container = HBoxContainer.new()
	level_track_container.alignment = BoxContainer.ALIGNMENT_CENTER
	track_holder.add_child(level_track_container)

	# Spacing between Level Track and Primary CTA button
	var v_spacer3 = Control.new()
	v_spacer3.custom_minimum_size = Vector2(0, 16)
	main_vbox.add_child(v_spacer3)

	# ==========================================
	# E. PRIMARY BOTTOM CTA: "Play / Level X" (Image 2)
	# ==========================================
	var cta_center = CenterContainer.new()
	main_vbox.add_child(cta_center)

	cta_btn = Button.new()
	cta_btn.custom_minimum_size = Vector2(360, 78)
	cta_btn.focus_mode = Control.FOCUS_NONE

	# Warm caramel / golden amber gradient matching Image 2
	var cta_sb = StyleBoxFlat.new()
	cta_sb.bg_color = Color("#C8782E")
	cta_sb.border_width_bottom = 4
	cta_sb.border_color = Color("#9E5517")
	cta_sb.set_corner_radius_all(22)
	cta_sb.shadow_size = 8
	cta_sb.shadow_color = Color(0, 0, 0, 0.16)
	cta_sb.shadow_offset = Vector2(0, 4)
	cta_btn.add_theme_stylebox_override("normal", cta_sb)

	var cta_h_sb = cta_sb.duplicate() as StyleBoxFlat
	cta_h_sb.bg_color = Color("#D98538")
	cta_btn.add_theme_stylebox_override("hover", cta_h_sb)

	var cta_p_sb = cta_sb.duplicate() as StyleBoxFlat
	cta_p_sb.bg_color = Color("#B36620")
	cta_p_sb.border_width_bottom = 1
	cta_btn.add_theme_stylebox_override("pressed", cta_p_sb)

	var cta_vbox = VBoxContainer.new()
	cta_vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	cta_vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	cta_vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	cta_btn.add_child(cta_vbox)

	cta_title = Label.new()
	cta_title.text = "Play"
	cta_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	cta_title.add_theme_font_size_override("font_size", 26)
	cta_title.add_theme_color_override("font_color", Color.WHITE)
	cta_vbox.add_child(cta_title)

	cta_sub = Label.new()
	cta_sub.text = "Level 1"
	cta_sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	cta_sub.add_theme_font_size_override("font_size", 15)
	cta_sub.add_theme_color_override("font_color", Color("#FDEBD6"))
	cta_vbox.add_child(cta_sub)
	lbl_progress = cta_sub

	cta_btn.pressed.connect(func():
		_play_click()
		play_pressed.emit()
	)
	cta_center.add_child(cta_btn)

	var v_spacer_bot = Control.new()
	v_spacer_bot.custom_minimum_size = Vector2(0, 10)
	main_vbox.add_child(v_spacer_bot)

	# 2. Popups instantiation
	daily_streak_popup = DailyStreakPopupClass.new()
	add_child(daily_streak_popup)

	emerald_league_popup = EmeraldLeaguePopupClass.new()
	emerald_league_popup.play_requested.connect(func():
		play_pressed.emit()
	)
	add_child(emerald_league_popup)

func _create_emerald_league_card() -> Control:
	var card = PanelContainer.new()
	card.custom_minimum_size = Vector2(215, 290)
	var sb = StyleBoxFlat.new()
	sb.bg_color = Color("#EF9737")
	sb.border_width_bottom = 3
	sb.border_color = Color("#D47E20")
	sb.set_corner_radius_all(24)
	sb.shadow_size = 8
	sb.shadow_color = Color(0, 0, 0, 0.12)
	sb.shadow_offset = Vector2(0, 4)
	card.add_theme_stylebox_override("panel", sb)

	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 16)
	margin.add_theme_constant_override("margin_right", 16)
	margin.add_theme_constant_override("margin_top", 14)
	margin.add_theme_constant_override("margin_bottom", 14)
	card.add_child(margin)

	var vbox = VBoxContainer.new()
	vbox.alignment = BoxContainer.ALIGNMENT_BEGIN
	vbox.add_theme_constant_override("separation", 6)
	margin.add_child(vbox)

	var lbl_name = Label.new()
	lbl_name.text = "Emerald League"
	lbl_name.add_theme_font_size_override("font_size", 16)
	lbl_name.add_theme_color_override("font_color", Color.WHITE)
	vbox.add_child(lbl_name)

	# Timer Pill: 🕒 20h52m
	var timer_pill = PanelContainer.new()
	var tp_sb = StyleBoxFlat.new()
	tp_sb.bg_color = Color(0, 0, 0, 0.18)
	tp_sb.set_corner_radius_all(10)
	timer_pill.add_theme_stylebox_override("panel", tp_sb)
	timer_pill.custom_minimum_size = Vector2(96, 22)
	vbox.add_child(timer_pill)

	var lbl_timer = Label.new()
	lbl_timer.text = "🕒 20h52m"
	lbl_timer.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl_timer.add_theme_font_size_override("font_size", 11)
	lbl_timer.add_theme_color_override("font_color", Color("#FFF0D6"))
	timer_pill.add_child(lbl_timer)

	# Center Emblem: Emerald Shield Badge with Golden Ribbon (Image 2)
	var emblem_vbox = VBoxContainer.new()
	emblem_vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	emblem_vbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
	emblem_vbox.add_theme_constant_override("separation", 4)
	vbox.add_child(emblem_vbox)

	var shield_box = CenterContainer.new()
	shield_box.custom_minimum_size = Vector2(0, 84)
	var shield_ctrl = Control.new()
	shield_ctrl.custom_minimum_size = Vector2(76, 76)
	shield_ctrl.draw.connect(func():
		var c = Vector2(38, 38)
		# Golden wings
		shield_ctrl.draw_circle(c + Vector2(-22, -2), 12.0, Color("#F5B041"))
		shield_ctrl.draw_circle(c + Vector2(22, -2), 12.0, Color("#F5B041"))
		# Green hexagon
		var hex_pts = PackedVector2Array()
		for i in range(6):
			var a = (float(i) * TAU / 6.0) - (PI * 0.5)
			hex_pts.append(c + Vector2(cos(a), sin(a)) * 26.0)
		shield_ctrl.draw_colored_polygon(hex_pts, Color("#1E8449"))
		# Inner bright green
		var hex_in = PackedVector2Array()
		for i in range(6):
			var a = (float(i) * TAU / 6.0) - (PI * 0.5)
			hex_in.append(c + Vector2(cos(a), sin(a)) * 20.0)
		shield_ctrl.draw_colored_polygon(hex_in, Color("#2ECC71"))
		# Upward arrow
		var arr = PackedVector2Array([
			c + Vector2(0, -12),
			c + Vector2(10, 0),
			c + Vector2(5, 0),
			c + Vector2(5, 12),
			c + Vector2(-5, 12),
			c + Vector2(-5, 0),
			c + Vector2(-10, 0)
		])
		shield_ctrl.draw_colored_polygon(arr, Color("#F7DC6F"))
	)
	shield_box.add_child(shield_ctrl)
	emblem_vbox.add_child(shield_box)

	var lbl_rank = Label.new()
	lbl_rank.text = "🎖 38th 🎖"
	lbl_rank.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl_rank.add_theme_font_size_override("font_size", 13)
	lbl_rank.add_theme_color_override("font_color", Color("#5D310C"))
	emblem_vbox.add_child(lbl_rank)

	# Action Button (Pill: "Play")
	var btn = Button.new()
	btn.text = "Play"
	btn.custom_minimum_size = Vector2(0, 44)
	btn.focus_mode = Control.FOCUS_NONE
	var b_sb = StyleBoxFlat.new()
	b_sb.bg_color = Color("#FFF9EF")
	b_sb.set_corner_radius_all(18)
	b_sb.shadow_size = 4
	b_sb.shadow_color = Color(0, 0, 0, 0.08)
	b_sb.shadow_offset = Vector2(0, 2)
	btn.add_theme_stylebox_override("normal", b_sb)
	btn.add_theme_stylebox_override("hover", b_sb)
	btn.add_theme_stylebox_override("pressed", b_sb)
	btn.add_theme_font_size_override("font_size", 16)
	btn.add_theme_color_override("font_color", Color("#B86720"))
	btn.pressed.connect(func():
		_play_click()
		if emerald_league_popup:
			emerald_league_popup.show_popup()
	)
	vbox.add_child(btn)

	return card

func _create_daily_challenge_card() -> Control:
	var card = PanelContainer.new()
	card.custom_minimum_size = Vector2(215, 290)
	var sb = StyleBoxFlat.new()
	sb.bg_color = Color("#D94A38")
	sb.border_width_bottom = 3
	sb.border_color = Color("#B83726")
	sb.set_corner_radius_all(24)
	sb.shadow_size = 8
	sb.shadow_color = Color(0, 0, 0, 0.12)
	sb.shadow_offset = Vector2(0, 4)
	card.add_theme_stylebox_override("panel", sb)

	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 16)
	margin.add_theme_constant_override("margin_right", 16)
	margin.add_theme_constant_override("margin_top", 14)
	margin.add_theme_constant_override("margin_bottom", 14)
	card.add_child(margin)

	var vbox = VBoxContainer.new()
	vbox.alignment = BoxContainer.ALIGNMENT_BEGIN
	vbox.add_theme_constant_override("separation", 6)
	margin.add_child(vbox)

	var lbl_name = Label.new()
	lbl_name.text = "Daily Challenge"
	lbl_name.add_theme_font_size_override("font_size", 16)
	lbl_name.add_theme_color_override("font_color", Color.WHITE)
	vbox.add_child(lbl_name)

	var dt = Time.get_datetime_dict_from_system()
	var months = ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"]
	var m_str = months[clampi(dt.month - 1, 0, 11)]
	var lbl_date = Label.new()
	lbl_date.text = "%s %d" % [m_str, dt.day]
	lbl_date.add_theme_font_size_override("font_size", 14)
	lbl_date.add_theme_color_override("font_color", Color("#FFE0D8"))
	vbox.add_child(lbl_date)

	# Center Artwork: Silver 3-Star Trophy Cup (Image 2)
	var emblem_vbox = VBoxContainer.new()
	emblem_vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	emblem_vbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(emblem_vbox)

	var trophy_ctrl = Control.new()
	trophy_ctrl.custom_minimum_size = Vector2(76, 76)
	trophy_ctrl.draw.connect(func():
		var c = Vector2(38, 38)
		# Black pedestal
		trophy_ctrl.draw_rect(Rect2(c.x - 18, c.y + 16, 36, 12), Color("#212121"), true)
		trophy_ctrl.draw_rect(Rect2(c.x - 14, c.y + 12, 28, 4), Color("#424242"), true)
		# Silver cup
		trophy_ctrl.draw_circle(c + Vector2(0, 0), 16.0, Color("#BDC3C7"))
		trophy_ctrl.draw_circle(c + Vector2(0, -2), 14.0, Color("#ECF0F1"))
		# 3 silver stars
		trophy_ctrl.draw_circle(c + Vector2(-12, -18), 7.0, Color("#E0E0E0"))
		trophy_ctrl.draw_circle(c + Vector2(0, -24), 9.0, Color("#FFFFFF"))
		trophy_ctrl.draw_circle(c + Vector2(12, -18), 7.0, Color("#E0E0E0"))
	)
	emblem_vbox.add_child(trophy_ctrl)

	# Action Button (Pill: "Start")
	var btn = Button.new()
	btn.text = "Start"
	btn.custom_minimum_size = Vector2(0, 44)
	btn.focus_mode = Control.FOCUS_NONE
	var b_sb = StyleBoxFlat.new()
	b_sb.bg_color = Color("#FFF9EF")
	b_sb.set_corner_radius_all(18)
	b_sb.shadow_size = 4
	b_sb.shadow_color = Color(0, 0, 0, 0.08)
	b_sb.shadow_offset = Vector2(0, 2)
	btn.add_theme_stylebox_override("normal", b_sb)
	btn.add_theme_stylebox_override("hover", b_sb)
	btn.add_theme_stylebox_override("pressed", b_sb)
	btn.add_theme_font_size_override("font_size", 16)
	btn.add_theme_color_override("font_color", Color("#B53728"))
	btn.pressed.connect(func():
		_play_click()
		daily_puzzle_pressed.emit()
	)
	vbox.add_child(btn)

	return card

func _create_event_card() -> Control:
	var card = PanelContainer.new()
	card.custom_minimum_size = Vector2(215, 290)
	var sb = StyleBoxFlat.new()
	sb.bg_color = Color("#45855E")
	sb.border_width_bottom = 3
	sb.border_color = Color("#326948")
	sb.set_corner_radius_all(24)
	sb.shadow_size = 8
	sb.shadow_color = Color(0, 0, 0, 0.12)
	sb.shadow_offset = Vector2(0, 4)
	card.add_theme_stylebox_override("panel", sb)

	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 16)
	margin.add_theme_constant_override("margin_right", 16)
	margin.add_theme_constant_override("margin_top", 14)
	margin.add_theme_constant_override("margin_bottom", 14)
	card.add_child(margin)

	var vbox = VBoxContainer.new()
	vbox.alignment = BoxContainer.ALIGNMENT_BEGIN
	vbox.add_theme_constant_override("separation", 6)
	margin.add_child(vbox)

	var lbl_name = Label.new()
	lbl_name.text = "Event"
	lbl_name.add_theme_font_size_override("font_size", 16)
	lbl_name.add_theme_color_override("font_color", Color.WHITE)
	vbox.add_child(lbl_name)

	var lbl_sub = Label.new()
	lbl_sub.text = "Countryside Quest"
	lbl_sub.add_theme_font_size_override("font_size", 13)
	lbl_sub.add_theme_color_override("font_color", Color("#D6EFE0"))
	vbox.add_child(lbl_sub)

	# Center Artwork: Garden Flora & Nature
	var emblem_vbox = VBoxContainer.new()
	emblem_vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	emblem_vbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(emblem_vbox)

	var lbl_icon = Label.new()
	lbl_icon.text = "🌾 🐛 🌻"
	lbl_icon.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl_icon.add_theme_font_size_override("font_size", 28)
	emblem_vbox.add_child(lbl_icon)

	# Action Button (Pill: "Play")
	var btn = Button.new()
	btn.text = "Play"
	btn.custom_minimum_size = Vector2(0, 44)
	btn.focus_mode = Control.FOCUS_NONE
	var b_sb = StyleBoxFlat.new()
	b_sb.bg_color = Color("#FFF9EF")
	b_sb.set_corner_radius_all(18)
	b_sb.shadow_size = 4
	b_sb.shadow_color = Color(0, 0, 0, 0.08)
	b_sb.shadow_offset = Vector2(0, 2)
	btn.add_theme_stylebox_override("normal", b_sb)
	btn.add_theme_stylebox_override("hover", b_sb)
	btn.add_theme_stylebox_override("pressed", b_sb)
	btn.add_theme_font_size_override("font_size", 16)
	btn.add_theme_color_override("font_color", Color("#306945"))
	btn.pressed.connect(func():
		_play_click()
		event_pressed.emit()
	)
	vbox.add_child(btn)

	return card

func _rebuild_level_track(cur_lvl: int) -> void:
	if not level_track_container:
		return

	for c in level_track_container.get_children():
		c.queue_free()

	# Rail container holding connected line and circle nodes
	var track_wrapper = Control.new()
	track_wrapper.custom_minimum_size = Vector2(360, 60)
	level_track_container.add_child(track_wrapper)

	var center_idx = 2
	var start_lvl = maxi(1, cur_lvl - center_idx)
	var active_node_idx = mini(cur_lvl - start_lvl, center_idx)
	var cur_center_x = 52.0 + float(active_node_idx) * 64.0

	# Draw background rail and active progression rail underneath circles
	track_wrapper.draw.connect(func():
		# Inactive rail across all 5 nodes (Image 2)
		track_wrapper.draw_line(Vector2(52, 30), Vector2(308, 30), Color("#E8DAC8"), 8.0, true)
		# Active progression rail up to current level
		if cur_center_x > 52.0:
			track_wrapper.draw_line(Vector2(52, 30), Vector2(cur_center_x, 30), Color("#C8782E"), 8.0, true)
	)

	var circles_hbox = HBoxContainer.new()
	circles_hbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	circles_hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	circles_hbox.add_theme_constant_override("separation", 16)
	track_wrapper.add_child(circles_hbox)

	for i in range(5):
		var lvl_num = start_lvl + i
		var is_current = (lvl_num == cur_lvl)
		var is_completed = (lvl_num < cur_lvl)
		var is_milestone = (lvl_num % 5 == 0 or (not is_current and i == 3))
		var is_locked = (lvl_num > cur_lvl)

		var node_box = CenterContainer.new()
		node_box.custom_minimum_size = Vector2(48, 48)
		node_box.size_flags_vertical = Control.SIZE_SHRINK_CENTER

		var circle_wrapper = Control.new()
		var node_dim = 56.0 if is_current else 44.0
		circle_wrapper.custom_minimum_size = Vector2(node_dim, node_dim)
		circle_wrapper.pivot_offset = Vector2(node_dim * 0.5, node_dim * 0.5)

		var center = Vector2(node_dim * 0.5, node_dim * 0.5)
		var radius = (node_dim * 0.5) - 1.0

		circle_wrapper.draw.connect(func():
			if is_current:
				# Outer soft glowing halo
				circle_wrapper.draw_circle(center, radius + 4.0, Color(0.92, 0.55, 0.32, 0.3))
				# Warm gold accent ring
				circle_wrapper.draw_arc(center, radius, 0.0, TAU, 32, Color("#FFDEB5"), 3.0, true)
				# Core warm caramel/amber fill matching Image 2
				circle_wrapper.draw_circle(center, radius - 1.5, Color("#BD6A2C"))
				# Highlight sheen arc
				circle_wrapper.draw_arc(center, radius - 4.5, -PI * 0.75, -PI * 0.25, 16, Color(1, 1, 1, 0.4), 2.0, true)
			elif is_completed:
				# Warm bronze/gold completed
				circle_wrapper.draw_circle(center, radius, Color("#C5A988"))
				circle_wrapper.draw_arc(center, radius, 0.0, TAU, 24, Color("#DFC9B2"), 1.5, true)
			elif is_milestone:
				# Royal purple milestone (Image 2)
				circle_wrapper.draw_circle(center, radius, Color("#7E57C2"))
				circle_wrapper.draw_arc(center, radius, 0.0, TAU, 24, Color("#B39DDB"), 1.5, true)
			else:
				# Soft caramel/sand upcoming
				circle_wrapper.draw_circle(center, radius, Color("#D5C3AC"))
		)

		var btn_node = Button.new()
		btn_node.set_anchors_preset(Control.PRESET_FULL_RECT)
		btn_node.focus_mode = Control.FOCUS_NONE
		btn_node.flat = true
		btn_node.text = str(lvl_num)
		btn_node.add_theme_font_size_override("font_size", 19 if is_current else 14)
		btn_node.add_theme_color_override("font_color", Color.WHITE)
		btn_node.pressed.connect(func():
			if is_locked:
				_play_click()
			else:
				_play_click()
				play_pressed.emit()
		)
		circle_wrapper.add_child(btn_node)

		# Subtle breathing pulse on current active level node
		if is_current:
			var tw = circle_wrapper.create_tween().set_loops().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
			tw.tween_property(circle_wrapper, "scale", Vector2(1.06, 1.06), 0.9)
			tw.tween_property(circle_wrapper, "scale", Vector2.ONE, 0.9)

		node_box.add_child(circle_wrapper)
		circles_hbox.add_child(node_box)

func _open_daily_streak() -> void:
	if daily_streak_popup:
		var cur_s = 1
		var best_s = 2
		if SaveManager.instance:
			cur_s = SaveManager.instance.current_streak
			best_s = SaveManager.instance.best_streak
		daily_streak_popup.show_popup(cur_s, best_s)

func _play_click() -> void:
	if SoundManager.instance:
		SoundManager.instance.play_click()
