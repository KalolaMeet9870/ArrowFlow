class_name EventScreen
extends Control

## Screen 8: Event Screen - "Countryside Dash" (matching Reference Image 8).
## Features:
## - Top header with Back arrow ← and Title "Event".
## - Picturesque countryside landscape illustration banner with barn, windmill, hills, and flora.
## - Event Title: "Countryside Dash".
## - Subtitle: "Complete event levels and earn unique rewards!".
## - Progress bar: "3/10" with floral milestone badges (flower, sprout, sunflower).
## - Large green "Play" CTA button.

signal play_pressed
signal back_pressed

const SafeAreaHelper = preload("res://scripts/safe_area_helper.gd")

var bg_rect: ColorRect
var main_margin: MarginContainer
var btn_back: Button
var btn_play: Button
var lbl_progress: Label
var event_bar: ProgressBar

func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	if ThemeManager.instance:
		ThemeManager.instance.theme_changed.connect(apply_theme)
	_build_ui()
	refresh_event_progress()

	resized.connect(_update_safe_areas)
	if get_tree() and get_tree().root:
		get_tree().root.size_changed.connect(_update_safe_areas)

	if ThemeManager.instance:
		apply_theme(ThemeManager.instance.get_current_theme())

func _update_safe_areas() -> void:
	if main_margin:
		SafeAreaHelper.apply_safe_area_margins(main_margin, get_viewport(), 0.0, 16.0, 16.0, 16.0)

func refresh_event_progress() -> void:
	var cur = 3
	var max_ev = 10
	if SaveManager.instance:
		cur = SaveManager.instance.event_progress
		max_ev = SaveManager.instance.event_max

	if lbl_progress:
		lbl_progress.text = "%d/%d" % [cur, max_ev]
	if event_bar:
		event_bar.max_value = float(max_ev)
		event_bar.value = float(cur)

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

	# --- 1. TOP HEADER: [ ← ] [ Event ] ---
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
	lbl_title.text = "Event"
	lbl_title.add_theme_font_size_override("font_size", 22)
	lbl_title.add_theme_color_override("font_color", Color("#4A3525"))
	title_center.add_child(lbl_title)

	var dummy = Control.new()
	dummy.custom_minimum_size = Vector2(44, 44)
	top_bar.add_child(dummy)

	# --- 2. COUNTRYSIDE ARTWORK BANNER (Image 8) ---
	var banner_container = PanelContainer.new()
	banner_container.custom_minimum_size = Vector2(0, 200)
	var bc_sb = StyleBoxFlat.new()
	bc_sb.set_corner_radius_all(24)
	bc_sb.shadow_size = 6
	bc_sb.shadow_color = Color(0, 0, 0, 0.1)
	bc_sb.shadow_offset = Vector2(0, 4)
	banner_container.add_theme_stylebox_override("panel", bc_sb)
	vbox.add_child(banner_container)

	var landscape_ctrl = Control.new()
	landscape_ctrl.set_anchors_preset(Control.PRESET_FULL_RECT)
	landscape_ctrl.draw.connect(func():
		var w = landscape_ctrl.size.x
		var h = landscape_ctrl.size.y
		# Sky background
		landscape_ctrl.draw_rect(Rect2(0, 0, w, h), Color("#87CEEB"), true)

		# Soft fluffy clouds
		landscape_ctrl.draw_circle(Vector2(w * 0.25, 35), 24.0, Color(1, 1, 1, 0.85))
		landscape_ctrl.draw_circle(Vector2(w * 0.32, 30), 28.0, Color(1, 1, 1, 0.85))
		landscape_ctrl.draw_circle(Vector2(w * 0.75, 45), 22.0, Color(1, 1, 1, 0.8))

		# Rolling green hills
		landscape_ctrl.draw_circle(Vector2(w * 0.3, h + 80), 220.0, Color("#55A36A"))
		landscape_ctrl.draw_circle(Vector2(w * 0.75, h + 90), 240.0, Color("#468B58"))
		landscape_ctrl.draw_circle(Vector2(w * 0.5, h + 110), 230.0, Color("#387547"))

		# Red Barn
		var barn_x = w * 0.36
		var barn_y = h * 0.42
		landscape_ctrl.draw_rect(Rect2(barn_x, barn_y, 48, 42), Color("#C0392B"), true)
		landscape_ctrl.draw_colored_polygon([
			Vector2(barn_x - 4, barn_y),
			Vector2(barn_x + 24, barn_y - 20),
			Vector2(barn_x + 52, barn_y)
		], Color("#962D22"))
		# Barn white door
		landscape_ctrl.draw_rect(Rect2(barn_x + 16, barn_y + 18, 16, 24), Color("#ECF0F1"), true)

		# Windmill on right
		var wm_x = w * 0.78
		var wm_y = h * 0.38
		landscape_ctrl.draw_rect(Rect2(wm_x - 8, wm_y, 16, 48), Color("#795548"), true)
		landscape_ctrl.draw_line(Vector2(wm_x, wm_y + 4), Vector2(wm_x - 24, wm_y - 18), Color("#FFFFFF"), 3.0, true)
		landscape_ctrl.draw_line(Vector2(wm_x, wm_y + 4), Vector2(wm_x + 24, wm_y + 26), Color("#FFFFFF"), 3.0, true)
		landscape_ctrl.draw_line(Vector2(wm_x, wm_y + 4), Vector2(wm_x - 18, wm_y + 22), Color("#FFFFFF"), 3.0, true)
		landscape_ctrl.draw_line(Vector2(wm_x, wm_y + 4), Vector2(wm_x + 18, wm_y - 14), Color("#FFFFFF"), 3.0, true)

		# Colorful flower field foreground
		var flower_colors = [Color("#E74C3C"), Color("#F1C40F"), Color("#9B59B6"), Color("#FFFFFF")]
		for i in range(16):
			var fx = 16.0 + float(i) * ((w - 32.0) / 15.0)
			var fy = h - 22.0 + sin(float(i) * 1.8) * 8.0
			var f_col = flower_colors[i % flower_colors.size()]
			landscape_ctrl.draw_circle(Vector2(fx, fy), 5.0, f_col)
			landscape_ctrl.draw_circle(Vector2(fx, fy), 2.0, Color("#F39C12"))
	)
	banner_container.add_child(landscape_ctrl)

	# --- 3. EVENT DETAILS CARD (Image 8) ---
	var card = PanelContainer.new()
	var card_sb = StyleBoxFlat.new()
	card_sb.bg_color = Color("#FFFDF9")
	card_sb.border_width_left = 1
	card_sb.border_width_top = 1
	card_sb.border_width_right = 1
	card_sb.border_width_bottom = 1
	card_sb.border_color = Color("#EAE0D0")
	card_sb.set_corner_radius_all(22)
	card_sb.shadow_size = 4
	card_sb.shadow_color = Color(0, 0, 0, 0.06)
	card_sb.shadow_offset = Vector2(0, 2)
	card.add_theme_stylebox_override("panel", card_sb)
	vbox.add_child(card)

	var card_margin = MarginContainer.new()
	card_margin.add_theme_constant_override("margin_left", 20)
	card_margin.add_theme_constant_override("margin_right", 20)
	card_margin.add_theme_constant_override("margin_top", 18)
	card_margin.add_theme_constant_override("margin_bottom", 18)
	card.add_child(card_margin)

	var card_vbox = VBoxContainer.new()
	card_vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	card_vbox.add_theme_constant_override("separation", 10)
	card_margin.add_child(card_vbox)

	var lbl_ev_name = Label.new()
	lbl_ev_name.text = "Countryside Dash"
	lbl_ev_name.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl_ev_name.add_theme_font_size_override("font_size", 22)
	lbl_ev_name.add_theme_color_override("font_color", Color("#2D4A3E"))
	card_vbox.add_child(lbl_ev_name)

	var lbl_ev_desc = Label.new()
	lbl_ev_desc.text = "Complete event levels and\nearn unique rewards!"
	lbl_ev_desc.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl_ev_desc.add_theme_font_size_override("font_size", 14)
	lbl_ev_desc.add_theme_color_override("font_color", Color("#7F8C8D"))
	card_vbox.add_child(lbl_ev_desc)

	# Progress label
	lbl_progress = Label.new()
	lbl_progress.text = "3/10"
	lbl_progress.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl_progress.add_theme_font_size_override("font_size", 14)
	lbl_progress.add_theme_color_override("font_color", Color("#4A3525"))
	card_vbox.add_child(lbl_progress)

	# Progress Bar
	event_bar = ProgressBar.new()
	event_bar.custom_minimum_size = Vector2(240, 8)
	event_bar.show_percentage = false
	var eb_bg = StyleBoxFlat.new()
	eb_bg.bg_color = Color("#E5E0D5")
	eb_bg.set_corner_radius_all(4)
	event_bar.add_theme_stylebox_override("background", eb_bg)
	var eb_fill = StyleBoxFlat.new()
	eb_fill.bg_color = Color("#E67E22")
	eb_fill.set_corner_radius_all(4)
	event_bar.add_theme_stylebox_override("fill", eb_fill)
	card_vbox.add_child(event_bar)

	# Floral checkpoint milestone badges (Image 8)
	var flora_row = HBoxContainer.new()
	flora_row.alignment = BoxContainer.ALIGNMENT_CENTER
	flora_row.add_theme_constant_override("separation", 36)
	card_vbox.add_child(flora_row)

	var lbl_f1 = Label.new()
	lbl_f1.text = "🌷"
	lbl_f1.add_theme_font_size_override("font_size", 24)
	flora_row.add_child(lbl_f1)

	var lbl_f2 = Label.new()
	lbl_f2.text = "🌱"
	lbl_f2.add_theme_font_size_override("font_size", 24)
	flora_row.add_child(lbl_f2)

	var lbl_f3 = Label.new()
	lbl_f3.text = "🌻"
	lbl_f3.add_theme_font_size_override("font_size", 24)
	flora_row.add_child(lbl_f3)

	# Flexible Spacer
	var s_fill = Control.new()
	s_fill.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(s_fill)

	# --- 4. GREEN "PLAY" CTA BUTTON (Image 8) ---
	var btn_center = CenterContainer.new()
	vbox.add_child(btn_center)

	btn_play = Button.new()
	btn_play.text = "Play"
	btn_play.custom_minimum_size = Vector2(340, 56)
	btn_play.focus_mode = Control.FOCUS_NONE
	var play_sb = StyleBoxFlat.new()
	play_sb.bg_color = Color("#2D8A4E")
	play_sb.set_corner_radius_all(18)
	play_sb.shadow_size = 5
	play_sb.shadow_color = Color(0.2, 0.6, 0.3, 0.25)
	play_sb.shadow_offset = Vector2(0, 3)
	btn_play.add_theme_stylebox_override("normal", play_sb)
	var play_h = play_sb.duplicate() as StyleBoxFlat
	play_h.bg_color = Color("#2D8A4E").lightened(0.1)
	btn_play.add_theme_stylebox_override("hover", play_h)
	var play_p = play_sb.duplicate() as StyleBoxFlat
	play_p.bg_color = Color("#2D8A4E").darkened(0.1)
	btn_play.add_theme_stylebox_override("pressed", play_p)
	btn_play.add_theme_font_size_override("font_size", 18)
	btn_play.add_theme_color_override("font_color", Color.WHITE)
	btn_play.pressed.connect(func():
		_play_click()
		play_pressed.emit()
	)
	btn_center.add_child(btn_play)

	var b_spacer = Control.new()
	b_spacer.custom_minimum_size = Vector2(0, 16)
	vbox.add_child(b_spacer)

func _play_click() -> void:
	if SoundManager.instance:
		SoundManager.instance.play_click()
