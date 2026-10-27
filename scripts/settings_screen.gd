class_name SettingsScreen
extends Control

## Settings Screen matching user screenshot 5.
## Features:
## - Top Header with back arrow ← and "Settings" title.
## - Card 1: Sound, Vibration, Music, Voice, Guideline, and Calm Mode toggles with animated switches.
## - Card 2: "Save Your Progress" >
## - Card 3: "Rate Us" >, "Feedback" >
## - Card 4: "Privacy Policy" >, "Terms of Service" >

signal back_pressed

const SafeAreaHelper = preload("res://scripts/safe_area_helper.gd")

var bg_rect: ColorRect
var main_margin: MarginContainer
var scroll_box: ScrollContainer
var switch_controls: Dictionary = {}

func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	if ThemeManager.instance:
		ThemeManager.instance.theme_changed.connect(apply_theme)
	_build_ui()
	_update_all_switches()

	resized.connect(_update_safe_areas)
	if get_tree() and get_tree().root:
		get_tree().root.size_changed.connect(_update_safe_areas)

func _update_safe_areas() -> void:
	if main_margin:
		SafeAreaHelper.apply_safe_area_margins(main_margin, get_viewport(), 0.0, 16.0, 8.0, 8.0)

func apply_theme(theme: Dictionary) -> void:
	if bg_rect:
		bg_rect.color = theme.get("bg", Color("#FAF4E8"))

func _update_all_switches() -> void:
	if not SaveManager.instance:
		return
	_set_switch_state("sound", SaveManager.instance.sound_enabled)
	_set_switch_state("vibration", SaveManager.instance.vibration_enabled)
	_set_switch_state("music", SaveManager.instance.music_enabled)
	_set_switch_state("voice", SaveManager.instance.voice_enabled)
	_set_switch_state("guideline", SaveManager.instance.guideline_enabled)
	_set_switch_state("calm_mode", SaveManager.instance.calm_mode_enabled)

func _set_switch_state(key: String, is_on: bool) -> void:
	if switch_controls.has(key):
		var sw = switch_controls[key]
		sw.set_meta("is_on", is_on)
		sw.set_meta("knob_x", 38.0 if is_on else 14.0)
		sw.queue_redraw()

func _build_ui() -> void:
	# Zen cream background
	bg_rect = ColorRect.new()
	bg_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg_rect.color = Color("#FAF4E8")
	add_child(bg_rect)

	main_margin = MarginContainer.new()
	main_margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(main_margin)
	_update_safe_areas()

	var main_vbox = VBoxContainer.new()
	main_vbox.add_theme_constant_override("separation", 16)
	main_margin.add_child(main_vbox)

	# --- TOP HEADER: ← Settings ---
	var header_bar = HBoxContainer.new()
	header_bar.add_theme_constant_override("separation", 14)
	main_vbox.add_child(header_bar)

	var btn_back = Button.new()
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
	header_bar.add_child(btn_back)

	var lbl_header_title = Label.new()
	lbl_header_title.text = "Settings"
	lbl_header_title.add_theme_font_size_override("font_size", 24)
	lbl_header_title.add_theme_color_override("font_color", Color("#4A3525"))
	header_bar.add_child(lbl_header_title)

	# Scrollable content for cards
	scroll_box = ScrollContainer.new()
	scroll_box.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll_box.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	main_vbox.add_child(scroll_box)

	var content_vbox = VBoxContainer.new()
	content_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content_vbox.add_theme_constant_override("separation", 14)
	scroll_box.add_child(content_vbox)

	# ========================================================
	# CARD 1: Preferences / Audio / Display Toggles
	# ========================================================
	var card1 = _create_card_container()
	content_vbox.add_child(card1)

	var card1_vbox = VBoxContainer.new()
	card1_vbox.add_theme_constant_override("separation", 0)
	card1.add_child(card1_vbox)

	# 1. Sound
	card1_vbox.add_child(_create_toggle_row("sound", "🔊", "Sound", true, func(val: bool):
		if SaveManager.instance:
			SaveManager.instance.sound_enabled = val
			SaveManager.instance.save_data()
			if SoundManager.instance:
				SoundManager.instance.is_muted = not val
	))
	card1_vbox.add_child(_create_divider())

	# 2. Vibration
	card1_vbox.add_child(_create_toggle_row("vibration", "📳", "Vibration", true, func(val: bool):
		if SaveManager.instance:
			SaveManager.instance.vibration_enabled = val
			SaveManager.instance.save_data()
	))
	card1_vbox.add_child(_create_divider())

	# 3. Music
	card1_vbox.add_child(_create_toggle_row("music", "🎵", "Music", true, func(val: bool):
		if SaveManager.instance:
			SaveManager.instance.music_enabled = val
			SaveManager.instance.save_data()
	))
	card1_vbox.add_child(_create_divider())

	# 4. Voice
	card1_vbox.add_child(_create_toggle_row("voice", "🗣️", "Voice", true, func(val: bool):
		if SaveManager.instance:
			SaveManager.instance.voice_enabled = val
			SaveManager.instance.save_data()
	))
	card1_vbox.add_child(_create_divider())

	# 5. Guideline
	card1_vbox.add_child(_create_toggle_row("guideline", "⊞", "Guideline", false, func(val: bool):
		if SaveManager.instance:
			SaveManager.instance.guideline_enabled = val
			SaveManager.instance.save_data()
	))
	card1_vbox.add_child(_create_divider())

	# 6. Calm Mode
	card1_vbox.add_child(_create_toggle_row("calm_mode", "🪷", "Calm Mode", false, func(val: bool):
		if SaveManager.instance:
			SaveManager.instance.calm_mode_enabled = val
			SaveManager.instance.save_data()
	))

	# ========================================================
	# CARD 2: Save Your Progress
	# ========================================================
	var card2 = _create_card_container()
	content_vbox.add_child(card2)

	var card2_vbox = VBoxContainer.new()
	card2.add_child(card2_vbox)
	card2_vbox.add_child(_create_nav_row("👤", "Save Your Progress", func():
		_play_click()
		if SaveManager.instance:
			SaveManager.instance.save_data()
	))

	# ========================================================
	# CARD 3: Rate Us & Feedback
	# ========================================================
	var card3 = _create_card_container()
	content_vbox.add_child(card3)

	var card3_vbox = VBoxContainer.new()
	card3.add_child(card3_vbox)
	card3_vbox.add_child(_create_nav_row("👍", "Rate Us", func():
		_play_click()
		OS.shell_open("https://play.google.com/store/apps/details?id=com.arrowflow.puzzle&hl=en&gl=US")
	))
	card3_vbox.add_child(_create_divider())
	card3_vbox.add_child(_create_nav_row("💬", "Feedback", func():
		_play_click()
	))

	# ========================================================
	# CARD 4: Privacy Policy & Terms of Service
	# ========================================================
	var card4 = _create_card_container()
	content_vbox.add_child(card4)

	var card4_vbox = VBoxContainer.new()
	card4.add_child(card4_vbox)
	card4_vbox.add_child(_create_nav_row("💾", "Privacy Policy", func():
		_play_click()
		OS.shell_open("https://policies.google.com/privacy")
	))
	card4_vbox.add_child(_create_divider())
	card4_vbox.add_child(_create_nav_row("📄", "Terms of Service", func():
		_play_click()
		OS.shell_open("https://policies.google.com/terms")
	))

func _create_card_container() -> PanelContainer:
	var pc = PanelContainer.new()
	pc.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var sb = StyleBoxFlat.new()
	sb.bg_color = Color("#FFFFFF")
	sb.corner_radius_top_left = 20
	sb.corner_radius_top_right = 20
	sb.corner_radius_bottom_left = 20
	sb.corner_radius_bottom_right = 20
	sb.shadow_size = 4
	sb.shadow_color = Color(0, 0, 0, 0.04)
	sb.shadow_offset = Vector2(0, 2)
	pc.add_theme_stylebox_override("panel", sb)
	return pc

func _create_toggle_row(key: String, icon_str: String, title_str: String, default_val: bool, callback: Callable) -> Control:
	var row = Control.new()
	row.custom_minimum_size = Vector2(0, 52)
	row.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var hbox = HBoxContainer.new()
	hbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	hbox.add_theme_constant_override("separation", 12)
	row.add_child(hbox)

	var left_pad = Control.new()
	left_pad.custom_minimum_size = Vector2(8, 0)
	hbox.add_child(left_pad)

	var lbl_icon = Label.new()
	lbl_icon.text = icon_str
	lbl_icon.add_theme_font_size_override("font_size", 18)
	hbox.add_child(lbl_icon)

	var lbl_text = Label.new()
	lbl_text.text = title_str
	lbl_text.add_theme_font_size_override("font_size", 16)
	lbl_text.add_theme_color_override("font_color", Color("#6D5D52"))
	hbox.add_child(lbl_text)

	var sp = Control.new()
	sp.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox.add_child(sp)

	# Interactive Pill Switch Drawer
	var sw = Control.new()
	sw.custom_minimum_size = Vector2(52, 28)
	sw.set_meta("is_on", default_val)
	sw.set_meta("knob_x", 38.0 if default_val else 14.0)

	sw.draw.connect(func():
		var is_on = sw.get_meta("is_on", true)
		var knob_x = sw.get_meta("knob_x", 38.0)
		var bg_c = Color("#C07838") if is_on else Color("#A3A8B0")

		# Rounded pill background
		var r = 14.0
		sw.draw_circle(Vector2(r, r), r, bg_c)
		sw.draw_circle(Vector2(52.0 - r, r), r, bg_c)
		sw.draw_rect(Rect2(r, 0, 52.0 - r * 2.0, 28.0), bg_c)

		# White Knob
		sw.draw_circle(Vector2(knob_x, r), r - 3.0, Color.WHITE)
	)

	# Switch click handling
	var sw_btn = Button.new()
	sw_btn.set_anchors_preset(Control.PRESET_FULL_RECT)
	sw_btn.focus_mode = Control.FOCUS_NONE
	var trans_sb = StyleBoxFlat.new()
	trans_sb.bg_color = Color(0, 0, 0, 0)
	sw_btn.add_theme_stylebox_override("normal", trans_sb)
	sw_btn.add_theme_stylebox_override("hover", trans_sb)
	sw_btn.add_theme_stylebox_override("pressed", trans_sb)
	sw.add_child(sw_btn)

	sw_btn.pressed.connect(func():
		_play_click()
		var new_val = not sw.get_meta("is_on", true)
		sw.set_meta("is_on", new_val)

		# Animate knob
		var target_x = 38.0 if new_val else 14.0
		var tw = sw.create_tween()
		tw.tween_method(func(val: float):
			sw.set_meta("knob_x", val)
			sw.queue_redraw()
		, sw.get_meta("knob_x", 14.0), target_x, 0.16).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

		callback.call(new_val)
	)

	hbox.add_child(sw)
	switch_controls[key] = sw

	var right_pad = Control.new()
	right_pad.custom_minimum_size = Vector2(8, 0)
	hbox.add_child(right_pad)

	return row

func _create_nav_row(icon_str: String, title_str: String, callback: Callable) -> Control:
	var btn = Button.new()
	btn.custom_minimum_size = Vector2(0, 52)
	btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	btn.focus_mode = Control.FOCUS_NONE

	var sb = StyleBoxFlat.new()
	sb.bg_color = Color(0, 0, 0, 0)
	btn.add_theme_stylebox_override("normal", sb)
	btn.add_theme_stylebox_override("hover", sb)
	btn.add_theme_stylebox_override("pressed", sb)

	var hbox = HBoxContainer.new()
	hbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	hbox.add_theme_constant_override("separation", 12)
	hbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	btn.add_child(hbox)

	var left_pad = Control.new()
	left_pad.custom_minimum_size = Vector2(8, 0)
	hbox.add_child(left_pad)

	var lbl_icon = Label.new()
	lbl_icon.text = icon_str
	lbl_icon.add_theme_font_size_override("font_size", 18)
	hbox.add_child(lbl_icon)

	var lbl_text = Label.new()
	lbl_text.text = title_str
	lbl_text.add_theme_font_size_override("font_size", 16)
	lbl_text.add_theme_color_override("font_color", Color("#6D5D52"))
	hbox.add_child(lbl_text)

	var sp = Control.new()
	sp.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox.add_child(sp)

	var lbl_chev = Label.new()
	lbl_chev.text = "›"
	lbl_chev.add_theme_font_size_override("font_size", 22)
	lbl_chev.add_theme_color_override("font_color", Color("#A1887F"))
	hbox.add_child(lbl_chev)

	var right_pad = Control.new()
	right_pad.custom_minimum_size = Vector2(8, 0)
	hbox.add_child(right_pad)

	btn.pressed.connect(callback)
	return btn

func _create_divider() -> ColorRect:
	var cr = ColorRect.new()
	cr.custom_minimum_size = Vector2(0, 1)
	cr.color = Color("#F3ECE0")
	return cr

func _play_click() -> void:
	if SoundManager.instance:
		SoundManager.instance.play_click()
