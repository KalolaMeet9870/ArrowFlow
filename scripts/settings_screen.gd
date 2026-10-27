class_name SettingsScreen
extends Control

## Screen 10: Settings Screen (matching Reference Image 10).
## Features:
## - Top Header with Back arrow ← and "Settings" title.
## - Card 1 (Toggles): Sound, Music, Vibration with animated green switches.
## - Card 2 (Preferences): Language ("English ›"), Theme ("Light ›").
## - Card 3 (Info & Links): Privacy Policy, Terms of Service, Rate Us, More Games, How to Play.

signal back_pressed
signal theme_requested
signal how_to_play_requested

const SafeAreaHelper = preload("res://scripts/safe_area_helper.gd")

var bg_rect: ColorRect
var main_margin: MarginContainer
var scroll_box: ScrollContainer
var switch_controls: Dictionary = {}
var lbl_theme_val: Label

func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	if ThemeManager.instance:
		ThemeManager.instance.theme_changed.connect(apply_theme)
	_build_ui()
	_update_all_switches()

	resized.connect(_update_safe_areas)
	if get_tree() and get_tree().root:
		get_tree().root.size_changed.connect(_update_safe_areas)

	if ThemeManager.instance:
		apply_theme(ThemeManager.instance.get_current_theme())

func _update_safe_areas() -> void:
	if main_margin:
		SafeAreaHelper.apply_safe_area_margins(main_margin, get_viewport(), 0.0, 16.0, 14.0, 14.0)

func apply_theme(theme: Dictionary) -> void:
	if bg_rect:
		bg_rect.color = theme.get("bg", Color("#FAF4E8"))
	if lbl_theme_val and ThemeManager.instance:
		var cur_name = ThemeManager.instance.get_current_theme().get("name", "Light")
		lbl_theme_val.text = cur_name

func _update_all_switches() -> void:
	if not SaveManager.instance:
		return
	_set_switch_state("sound", SaveManager.instance.sound_enabled)
	_set_switch_state("music", SaveManager.instance.music_enabled)
	_set_switch_state("vibration", SaveManager.instance.vibration_enabled)

func _set_switch_state(key: String, is_on: bool) -> void:
	if switch_controls.has(key):
		var sw = switch_controls[key]
		sw.set_meta("is_on", is_on)
		sw.set_meta("knob_x", 38.0 if is_on else 14.0)
		sw.queue_redraw()

func _build_ui() -> void:
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

	# --- 1. TOP HEADER: [ ← ] [ Settings ] ---
	var header_bar = HBoxContainer.new()
	header_bar.alignment = BoxContainer.ALIGNMENT_BEGIN
	main_vbox.add_child(header_bar)

	var btn_back = Button.new()
	btn_back.text = "←"
	btn_back.custom_minimum_size = Vector2(56, 56)
	btn_back.focus_mode = Control.FOCUS_NONE
	var back_sb = StyleBoxFlat.new()
	back_sb.bg_color = Color(0, 0, 0, 0)
	btn_back.add_theme_stylebox_override("normal", back_sb)
	btn_back.add_theme_stylebox_override("hover", back_sb)
	btn_back.add_theme_stylebox_override("pressed", back_sb)
	btn_back.add_theme_font_size_override("font_size", 34)
	btn_back.add_theme_color_override("font_color", Color("#4A3525"))
	btn_back.pressed.connect(func():
		_play_click()
		back_pressed.emit()
	)
	header_bar.add_child(btn_back)

	var title_center = CenterContainer.new()
	title_center.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header_bar.add_child(title_center)

	var lbl_header_title = Label.new()
	lbl_header_title.text = "Settings"
	lbl_header_title.add_theme_font_size_override("font_size", 28)
	lbl_header_title.add_theme_color_override("font_color", Color("#4A3525"))
	title_center.add_child(lbl_header_title)

	var dummy = Control.new()
	dummy.custom_minimum_size = Vector2(56, 56)
	header_bar.add_child(dummy)

	# --- 2. SCROLL CONTENT ---
	scroll_box = ScrollContainer.new()
	scroll_box.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll_box.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll_box.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	main_vbox.add_child(scroll_box)

	var content_vbox = VBoxContainer.new()
	content_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content_vbox.add_theme_constant_override("separation", 16)
	scroll_box.add_child(content_vbox)

	# --- CARD 1: AUDIO & HAPTIC TOGGLES (Image 10) ---
	var card_toggles = _create_card()
	content_vbox.add_child(card_toggles)
	var toggles_vbox = VBoxContainer.new()
	toggles_vbox.add_theme_constant_override("separation", 6)
	card_toggles.get_node("Margin/VBox").add_child(toggles_vbox)

	toggles_vbox.add_child(_create_switch_row("🔊", "Sound", "sound", true, func(val: bool):
		if SaveManager.instance:
			SaveManager.instance.sound_enabled = val
			SaveManager.instance.save_data()
	))
	toggles_vbox.add_child(_create_divider())

	toggles_vbox.add_child(_create_switch_row("🎵", "Music", "music", true, func(val: bool):
		if SaveManager.instance:
			SaveManager.instance.music_enabled = val
			SaveManager.instance.save_data()
	))
	toggles_vbox.add_child(_create_divider())

	toggles_vbox.add_child(_create_switch_row("📳", "Vibration", "vibration", true, func(val: bool):
		if SaveManager.instance:
			SaveManager.instance.vibration_enabled = val
			SaveManager.instance.save_data()
	))

	# --- CARD 2: PREFERENCES (Language & Theme, Image 10) ---
	var card_prefs = _create_card()
	content_vbox.add_child(card_prefs)
	var prefs_vbox = VBoxContainer.new()
	prefs_vbox.add_theme_constant_override("separation", 6)
	card_prefs.get_node("Margin/VBox").add_child(prefs_vbox)

	prefs_vbox.add_child(_create_chevron_row("🌐", "Language", "English", func():
		_play_click()
	))
	prefs_vbox.add_child(_create_divider())

	var cur_theme_name = "Light"
	if ThemeManager.instance:
		cur_theme_name = ThemeManager.instance.get_current_theme().get("name", "Light")
	var theme_row = _create_chevron_row("🎨", "Theme", cur_theme_name, func():
		_play_click()
		theme_requested.emit()
	)
	lbl_theme_val = theme_row.get_meta("val_label") as Label
	prefs_vbox.add_child(theme_row)

	# --- CARD 3: LINKS & TUTORIAL (Image 10) ---
	var card_links = _create_card()
	content_vbox.add_child(card_links)
	var links_vbox = VBoxContainer.new()
	links_vbox.add_theme_constant_override("separation", 6)
	card_links.get_node("Margin/VBox").add_child(links_vbox)

	links_vbox.add_child(_create_link_row("📄", "Privacy Policy", func():
		_play_click()
		OS.shell_open("https://arrowflow.game/privacy")
	))
	links_vbox.add_child(_create_divider())

	links_vbox.add_child(_create_link_row("📋", "Terms of Service", func():
		_play_click()
		OS.shell_open("https://arrowflow.game/terms")
	))
	links_vbox.add_child(_create_divider())

	links_vbox.add_child(_create_link_row("⭐", "Rate Us", func():
		_play_click()
	))
	links_vbox.add_child(_create_divider())

	links_vbox.add_child(_create_link_row("🎮", "More Games", func():
		_play_click()
	))
	links_vbox.add_child(_create_divider())

	links_vbox.add_child(_create_link_row("❓", "How to Play", func():
		_play_click()
		how_to_play_requested.emit()
	))

func _create_card() -> PanelContainer:
	var card = PanelContainer.new()
	var sb = StyleBoxFlat.new()
	sb.bg_color = Color("#FFFDF9")
	sb.border_width_left = 1
	sb.border_width_top = 1
	sb.border_width_right = 1
	sb.border_width_bottom = 1
	sb.border_color = Color("#EAE0D0")
	sb.set_corner_radius_all(20)
	sb.shadow_size = 4
	sb.shadow_color = Color(0, 0, 0, 0.05)
	sb.shadow_offset = Vector2(0, 2)
	card.add_theme_stylebox_override("panel", sb)

	var margin = MarginContainer.new()
	margin.name = "Margin"
	margin.add_theme_constant_override("margin_left", 16)
	margin.add_theme_constant_override("margin_right", 16)
	margin.add_theme_constant_override("margin_top", 10)
	margin.add_theme_constant_override("margin_bottom", 10)
	card.add_child(margin)

	var vbox = VBoxContainer.new()
	vbox.name = "VBox"
	margin.add_child(vbox)
	return card

func _create_switch_row(icon_str: String, label_str: String, key: String, default_val: bool, callback: Callable) -> Control:
	var row = HBoxContainer.new()
	row.custom_minimum_size = Vector2(0, 58)
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 16)

	var lbl_icon = Label.new()
	lbl_icon.text = icon_str
	lbl_icon.add_theme_font_size_override("font_size", 24)
	row.add_child(lbl_icon)

	var lbl_text = Label.new()
	lbl_text.text = label_str
	lbl_text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	lbl_text.add_theme_font_size_override("font_size", 20)
	lbl_text.add_theme_color_override("font_color", Color("#4A3525"))
	row.add_child(lbl_text)

	# Animated Green Toggle Switch
	var sw_btn = Button.new()
	sw_btn.custom_minimum_size = Vector2(60, 32)
	sw_btn.focus_mode = Control.FOCUS_NONE
	var sw_empty = StyleBoxFlat.new()
	sw_empty.bg_color = Color(0, 0, 0, 0)
	sw_btn.add_theme_stylebox_override("normal", sw_empty)
	sw_btn.add_theme_stylebox_override("hover", sw_empty)
	sw_btn.add_theme_stylebox_override("pressed", sw_empty)

	var is_on = default_val
	if SaveManager.instance:
		match key:
			"sound": is_on = SaveManager.instance.sound_enabled
			"music": is_on = SaveManager.instance.music_enabled
			"vibration": is_on = SaveManager.instance.vibration_enabled

	sw_btn.set_meta("is_on", is_on)
	sw_btn.set_meta("knob_x", 44.0 if is_on else 16.0)

	sw_btn.draw.connect(func():
		var on = sw_btn.get_meta("is_on", false)
		var kx = sw_btn.get_meta("knob_x", 16.0)
		var bg_c = Color("#4CAF50") if on else Color("#D8C8B5")
		# Pill background
		var pill_sb = StyleBoxFlat.new()
		pill_sb.set_corner_radius_all(16)
		pill_sb.bg_color = bg_c
		sw_btn.draw_style_box(pill_sb, Rect2(0, 0, 60, 32))
		# Circular knob
		sw_btn.draw_circle(Vector2(kx, 16.0), 12.0, Color.WHITE)
	)

	sw_btn.pressed.connect(func():
		_play_click()
		var cur = sw_btn.get_meta("is_on", false)
		var nxt = not cur
		sw_btn.set_meta("is_on", nxt)

		var target_x = 44.0 if nxt else 16.0
		var tw = create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tw.tween_method(func(val: float):
			sw_btn.set_meta("knob_x", val)
			sw_btn.queue_redraw()
		, sw_btn.get_meta("knob_x", 16.0), target_x, 0.16)

		callback.call(nxt)
	)

	switch_controls[key] = sw_btn
	row.add_child(sw_btn)
	return row

func _create_chevron_row(icon_str: String, title_str: String, val_str: String, on_click: Callable) -> Control:
	var btn = Button.new()
	btn.custom_minimum_size = Vector2(0, 58)
	btn.focus_mode = Control.FOCUS_NONE
	var sb = StyleBoxFlat.new()
	sb.bg_color = Color(0, 0, 0, 0)
	btn.add_theme_stylebox_override("normal", sb)

	var hbox = HBoxContainer.new()
	hbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	hbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hbox.add_theme_constant_override("separation", 16)
	btn.add_child(hbox)

	var lbl_i = Label.new()
	lbl_i.text = icon_str
	lbl_i.add_theme_font_size_override("font_size", 24)
	hbox.add_child(lbl_i)

	var lbl_t = Label.new()
	lbl_t.text = title_str
	lbl_t.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	lbl_t.add_theme_font_size_override("font_size", 20)
	lbl_t.add_theme_color_override("font_color", Color("#4A3525"))
	hbox.add_child(lbl_t)

	var lbl_val = Label.new()
	lbl_val.text = val_str
	lbl_val.add_theme_font_size_override("font_size", 18)
	lbl_val.add_theme_color_override("font_color", Color("#8D6E63"))
	hbox.add_child(lbl_val)
	btn.set_meta("val_label", lbl_val)

	var lbl_arr = Label.new()
	lbl_arr.text = "›"
	lbl_arr.add_theme_font_size_override("font_size", 26)
	lbl_arr.add_theme_color_override("font_color", Color("#BDBDBD"))
	hbox.add_child(lbl_arr)

	btn.pressed.connect(on_click)
	return btn

func _create_link_row(icon_str: String, title_str: String, on_click: Callable) -> Control:
	var btn = Button.new()
	btn.custom_minimum_size = Vector2(0, 58)
	btn.focus_mode = Control.FOCUS_NONE
	var sb = StyleBoxFlat.new()
	sb.bg_color = Color(0, 0, 0, 0)
	btn.add_theme_stylebox_override("normal", sb)

	var hbox = HBoxContainer.new()
	hbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	hbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hbox.add_theme_constant_override("separation", 16)
	btn.add_child(hbox)

	var lbl_i = Label.new()
	lbl_i.text = icon_str
	lbl_i.add_theme_font_size_override("font_size", 24)
	hbox.add_child(lbl_i)

	var lbl_t = Label.new()
	lbl_t.text = title_str
	lbl_t.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	lbl_t.add_theme_font_size_override("font_size", 20)
	lbl_t.add_theme_color_override("font_color", Color("#4A3525"))
	hbox.add_child(lbl_t)

	var lbl_arr = Label.new()
	lbl_arr.text = "›"
	lbl_arr.add_theme_font_size_override("font_size", 26)
	lbl_arr.add_theme_color_override("font_color", Color("#BDBDBD"))
	hbox.add_child(lbl_arr)

	btn.pressed.connect(on_click)
	return btn

func _create_divider() -> ColorRect:
	var div = ColorRect.new()
	div.custom_minimum_size = Vector2(0, 1)
	div.color = Color("#F3ECE0")
	return div

func _play_click() -> void:
	if SoundManager.instance:
		SoundManager.instance.play_click()
