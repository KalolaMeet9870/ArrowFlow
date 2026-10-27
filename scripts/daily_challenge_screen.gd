class_name DailyChallengeScreen
extends Control

## Screen 7: Daily Challenge Screen (matching Reference Image 7).
## Features:
## - Top header with Back arrow ←, Title "Daily Challenge", and countdown timer pill 🕒 20h 55m.
## - Grand golden trophy illustration with red celebratory ribbon and stars.
## - Explanatory text: "Complete today's puzzle and win special rewards!"
## - Reward row: ⭐ +5 and Gift Box 🎁.
## - Large rounded orange "Start" CTA button.

signal start_pressed
signal back_pressed

const SafeAreaHelper = preload("res://scripts/safe_area_helper.gd")

var bg_rect: ColorRect
var main_margin: MarginContainer
var btn_back: Button
var btn_start: Button
var lbl_timer: Label

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
	vbox.add_theme_constant_override("separation", 20)
	main_margin.add_child(vbox)

	# --- 1. TOP HEADER: [ ← ] [ Daily Challenge ] [ 🕒 20h 55m ] ---
	var top_bar = HBoxContainer.new()
	top_bar.alignment = BoxContainer.ALIGNMENT_CENTER
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
	lbl_title.text = "Daily Challenge"
	lbl_title.add_theme_font_size_override("font_size", 22)
	lbl_title.add_theme_color_override("font_color", Color("#4A3525"))
	title_center.add_child(lbl_title)

	# Timer Pill
	var timer_pill = PanelContainer.new()
	timer_pill.custom_minimum_size = Vector2(96, 32)
	var tp_sb = StyleBoxFlat.new()
	tp_sb.bg_color = Color("#F3ECE0")
	tp_sb.border_width_left = 1
	tp_sb.border_width_top = 1
	tp_sb.border_width_right = 1
	tp_sb.border_width_bottom = 1
	tp_sb.border_color = Color("#E5D7C5")
	tp_sb.set_corner_radius_all(14)
	timer_pill.add_theme_stylebox_override("panel", tp_sb)
	top_bar.add_child(timer_pill)

	lbl_timer = Label.new()
	lbl_timer.text = "🕒 20h 55m"
	lbl_timer.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl_timer.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	lbl_timer.add_theme_font_size_override("font_size", 12)
	lbl_timer.add_theme_color_override("font_color", Color("#8D6E63"))
	timer_pill.add_child(lbl_timer)

	# Flexible Spacer
	var s1 = Control.new()
	s1.size_flags_vertical = Control.SIZE_EXPAND_FILL
	s1.size_flags_stretch_ratio = 0.8
	vbox.add_child(s1)

	# --- 2. GOLDEN TROPHY ILLUSTRATION (Image 7) ---
	var trophy_center = CenterContainer.new()
	vbox.add_child(trophy_center)

	var trophy_ctrl = Control.new()
	trophy_ctrl.custom_minimum_size = Vector2(220, 180)
	trophy_ctrl.draw.connect(func():
		var c = Vector2(110, 80)
		# Celebratory radial stars
		trophy_ctrl.draw_circle(c + Vector2(-60, -40), 6.0, Color("#F5B041"))
		trophy_ctrl.draw_circle(c + Vector2(0, -60), 8.0, Color("#F39C12"))
		trophy_ctrl.draw_circle(c + Vector2(60, -40), 6.0, Color("#F5B041"))
		trophy_ctrl.draw_circle(c + Vector2(-80, 0), 4.0, Color("#F8C471"))
		trophy_ctrl.draw_circle(c + Vector2(80, 0), 4.0, Color("#F8C471"))

		# Red celebratory banner ribbon
		trophy_ctrl.draw_rect(Rect2(c.x - 85, c.y + 40, 170, 26), Color("#D94A38"), true)
		trophy_ctrl.draw_rect(Rect2(c.x - 95, c.y + 48, 16, 20), Color("#B83726"), true)
		trophy_ctrl.draw_rect(Rect2(c.x + 79, c.y + 48, 16, 20), Color("#B83726"), true)

		# Trophy base / stem
		trophy_ctrl.draw_rect(Rect2(c.x - 22, c.y + 20, 44, 25), Color("#D4AC0D"), true)
		trophy_ctrl.draw_rect(Rect2(c.x - 38, c.y + 58, 76, 14), Color("#B7950B"), true)

		# Golden Cup body
		trophy_ctrl.draw_circle(c, 42.0, Color("#F1C40F"))
		trophy_ctrl.draw_circle(c + Vector2(0, -4), 38.0, Color("#F5B041"))
		# Handles
		trophy_ctrl.draw_arc(c + Vector2(-42, -5), 18.0, PI * 0.4, PI * 1.6, 16, Color("#D4AC0D"), 6.0, true)
		trophy_ctrl.draw_arc(c + Vector2(42, -5), 18.0, -PI * 0.6, PI * 0.6, 16, Color("#D4AC0D"), 6.0, true)
		# Star emblem on cup
		trophy_ctrl.draw_circle(c + Vector2(0, -5), 12.0, Color("#FFFFFF"))
		trophy_ctrl.draw_circle(c + Vector2(0, -5), 9.0, Color("#F39C12"))
	)
	trophy_center.add_child(trophy_ctrl)

	# --- 3. DESCRIPTION TEXT (Image 7) ---
	var lbl_desc = Label.new()
	lbl_desc.text = "Complete today's puzzle and\nwin special rewards!"
	lbl_desc.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl_desc.add_theme_font_size_override("font_size", 16)
	lbl_desc.add_theme_color_override("font_color", Color("#4A3525"))
	vbox.add_child(lbl_desc)

	# --- 4. REWARD ROW: ⭐ +5 and 🎁 (Image 7) ---
	var reward_row = HBoxContainer.new()
	reward_row.alignment = BoxContainer.ALIGNMENT_CENTER
	reward_row.add_theme_constant_override("separation", 20)
	vbox.add_child(reward_row)

	var lbl_reward = Label.new()
	lbl_reward.text = "⭐ +5"
	lbl_reward.add_theme_font_size_override("font_size", 22)
	lbl_reward.add_theme_color_override("font_color", Color("#C8782E"))
	reward_row.add_child(lbl_reward)

	var lbl_gift = Label.new()
	lbl_gift.text = "🎁"
	lbl_gift.add_theme_font_size_override("font_size", 26)
	reward_row.add_child(lbl_gift)

	# Flexible Spacer
	var s2 = Control.new()
	s2.size_flags_vertical = Control.SIZE_EXPAND_FILL
	s2.size_flags_stretch_ratio = 1.0
	vbox.add_child(s2)

	# --- 5. BIG ORANGE START CTA (Image 7) ---
	var btn_center = CenterContainer.new()
	vbox.add_child(btn_center)

	btn_start = Button.new()
	btn_start.text = "Start"
	btn_start.custom_minimum_size = Vector2(340, 56)
	btn_start.focus_mode = Control.FOCUS_NONE
	var start_sb = StyleBoxFlat.new()
	start_sb.bg_color = Color("#E67E22")
	start_sb.set_corner_radius_all(18)
	start_sb.shadow_size = 5
	start_sb.shadow_color = Color(0.9, 0.5, 0.2, 0.25)
	start_sb.shadow_offset = Vector2(0, 3)
	btn_start.add_theme_stylebox_override("normal", start_sb)
	var start_h = start_sb.duplicate() as StyleBoxFlat
	start_h.bg_color = Color("#E67E22").lightened(0.1)
	btn_start.add_theme_stylebox_override("hover", start_h)
	var start_p = start_sb.duplicate() as StyleBoxFlat
	start_p.bg_color = Color("#E67E22").darkened(0.1)
	btn_start.add_theme_stylebox_override("pressed", start_p)
	btn_start.add_theme_font_size_override("font_size", 18)
	btn_start.add_theme_color_override("font_color", Color.WHITE)
	btn_start.pressed.connect(func():
		_play_click()
		start_pressed.emit()
	)
	btn_center.add_child(btn_start)

	var bottom_spacer = Control.new()
	bottom_spacer.custom_minimum_size = Vector2(0, 16)
	vbox.add_child(bottom_spacer)

func _play_click() -> void:
	if SoundManager.instance:
		SoundManager.instance.play_click()
