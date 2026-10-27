class_name LevelCompleteScreen
extends Control

## Screen 5: Level Completed Dialog (matching Reference Image 5).
## Features:
## - 3 Golden stars with pop-in scale animation
## - Ribbon banner: "Level Completed!"
## - "Great Job! You cleared the path."
## - Reward pill: ⭐ +2 and Gift Box 🎁
## - Large rounded orange "Next Level" button
## - Soft cream "Home" button

signal next_level_requested
signal replay_requested
signal home_requested

var card_panel: PanelContainer
var stars_container: HBoxContainer
var lbl_banner: Label
var lbl_praise: Label
var lbl_reward_coins: Label
var btn_next: Button
var btn_home: Button

func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	z_index = 50
	_build_ui()
	hide()

func display_completion(level_id: int, moves: int, hearts: int) -> void:
	if lbl_banner:
		lbl_banner.text = "Level Completed!"
	if lbl_praise:
		lbl_praise.text = "Great Job!\nYou cleared the path."
	if lbl_reward_coins:
		lbl_reward_coins.text = "⭐ +2"

	# Update stars display
	if stars_container:
		var star_labels = stars_container.get_children()
		for i in range(star_labels.size()):
			var s_lbl = star_labels[i] as Label
			if s_lbl:
				if i < hearts:
					s_lbl.modulate = Color(1.0, 1.0, 1.0, 1.0)
				else:
					s_lbl.modulate = Color(0.6, 0.6, 0.6, 0.4)

	show()
	_animate_in()

func _animate_in() -> void:
	if card_panel:
		card_panel.scale = Vector2(0.85, 0.85)
		card_panel.modulate.a = 0.0
		var tw = create_tween().set_parallel(true).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		tw.tween_property(card_panel, "scale", Vector2.ONE, 0.35)
		tw.tween_property(card_panel, "modulate:a", 1.0, 0.25)

	if stars_container:
		stars_container.scale = Vector2(0.5, 0.5)
		var s_tw = create_tween().set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
		s_tw.tween_property(stars_container, "scale", Vector2.ONE, 0.45).set_delay(0.12)

func _build_ui() -> void:
	# Semi-transparent dark dimmed backdrop
	var backdrop = ColorRect.new()
	backdrop.set_anchors_preset(Control.PRESET_FULL_RECT)
	backdrop.color = Color(0.12, 0.09, 0.06, 0.65)
	backdrop.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(backdrop)

	var center = CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(center)

	card_panel = PanelContainer.new()
	card_panel.custom_minimum_size = Vector2(340, 480)
	card_panel.pivot_offset = Vector2(170, 240)

	var sb = StyleBoxFlat.new()
	sb.bg_color = Color("#FFFDF9")
	sb.border_width_left = 2
	sb.border_width_top = 2
	sb.border_width_right = 2
	sb.border_width_bottom = 2
	sb.border_color = Color("#EADCC6")
	sb.set_corner_radius_all(28)
	sb.shadow_size = 20
	sb.shadow_color = Color(0, 0, 0, 0.22)
	sb.shadow_offset = Vector2(0, 8)
	card_panel.add_theme_stylebox_override("panel", sb)
	center.add_child(card_panel)

	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 24)
	margin.add_theme_constant_override("margin_right", 24)
	margin.add_theme_constant_override("margin_top", 24)
	margin.add_theme_constant_override("margin_bottom", 24)
	card_panel.add_child(margin)

	var vbox = VBoxContainer.new()
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_theme_constant_override("separation", 14)
	margin.add_child(vbox)

	# 1. Three Golden Stars (Image 5)
	var stars_center = CenterContainer.new()
	vbox.add_child(stars_center)

	stars_container = HBoxContainer.new()
	stars_container.alignment = BoxContainer.ALIGNMENT_CENTER
	stars_container.add_theme_constant_override("separation", 10)
	stars_container.pivot_offset = Vector2(75, 20)
	stars_center.add_child(stars_container)

	for i in range(3):
		var star_lbl = Label.new()
		star_lbl.text = "⭐"
		var s_size = 38 if i == 1 else 30
		star_lbl.add_theme_font_size_override("font_size", s_size)
		stars_container.add_child(star_lbl)

	# 2. Orange Banner Ribbon: "Level Completed!" (Image 5)
	var banner_panel = PanelContainer.new()
	banner_panel.custom_minimum_size = Vector2(250, 44)
	var bp_sb = StyleBoxFlat.new()
	bp_sb.bg_color = Color("#E67E22")
	bp_sb.set_corner_radius_all(22)
	bp_sb.shadow_size = 4
	bp_sb.shadow_color = Color(0.9, 0.5, 0.2, 0.25)
	bp_sb.shadow_offset = Vector2(0, 2)
	banner_panel.add_theme_stylebox_override("panel", bp_sb)
	vbox.add_child(banner_panel)

	lbl_banner = Label.new()
	lbl_banner.text = "Level Completed!"
	lbl_banner.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl_banner.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	lbl_banner.add_theme_font_size_override("font_size", 18)
	lbl_banner.add_theme_color_override("font_color", Color.WHITE)
	banner_panel.add_child(lbl_banner)

	# 3. Praise Text: "Great Job! You cleared the path." (Image 5)
	lbl_praise = Label.new()
	lbl_praise.text = "Great Job!\nYou cleared the path."
	lbl_praise.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl_praise.add_theme_font_size_override("font_size", 14)
	lbl_praise.add_theme_color_override("font_color", Color("#5D4037"))
	vbox.add_child(lbl_praise)

	# 4. Reward Row: ⭐ +2 and Gift Box 🎁 (Image 5)
	var reward_row = HBoxContainer.new()
	reward_row.alignment = BoxContainer.ALIGNMENT_CENTER
	reward_row.add_theme_constant_override("separation", 18)
	vbox.add_child(reward_row)

	lbl_reward_coins = Label.new()
	lbl_reward_coins.text = "⭐ +2"
	lbl_reward_coins.add_theme_font_size_override("font_size", 18)
	lbl_reward_coins.add_theme_color_override("font_color", Color("#C8782E"))
	reward_row.add_child(lbl_reward_coins)

	var lbl_gift = Label.new()
	lbl_gift.text = "🎁"
	lbl_gift.add_theme_font_size_override("font_size", 22)
	reward_row.add_child(lbl_gift)

	# Spacer
	var spacer = Control.new()
	spacer.custom_minimum_size = Vector2(0, 8)
	vbox.add_child(spacer)

	# 5. Primary CTA: "Next Level" (Image 5)
	btn_next = Button.new()
	btn_next.text = "Next Level"
	btn_next.custom_minimum_size = Vector2(250, 52)
	btn_next.focus_mode = Control.FOCUS_NONE
	var next_sb = StyleBoxFlat.new()
	next_sb.bg_color = Color("#E67E22")
	next_sb.set_corner_radius_all(18)
	next_sb.shadow_size = 4
	next_sb.shadow_color = Color(0, 0, 0, 0.1)
	next_sb.shadow_offset = Vector2(0, 3)
	btn_next.add_theme_stylebox_override("normal", next_sb)
	var next_h = next_sb.duplicate() as StyleBoxFlat
	next_h.bg_color = Color("#E67E22").lightened(0.1)
	btn_next.add_theme_stylebox_override("hover", next_h)
	var next_p = next_sb.duplicate() as StyleBoxFlat
	next_p.bg_color = Color("#E67E22").darkened(0.1)
	btn_next.add_theme_stylebox_override("pressed", next_p)
	btn_next.add_theme_font_size_override("font_size", 17)
	btn_next.add_theme_color_override("font_color", Color.WHITE)
	btn_next.pressed.connect(func():
		_play_click()
		hide()
		next_level_requested.emit()
	)
	vbox.add_child(btn_next)

	# 6. Secondary Action: "Home" (Image 5)
	btn_home = Button.new()
	btn_home.text = "Home"
	btn_home.custom_minimum_size = Vector2(250, 48)
	btn_home.focus_mode = Control.FOCUS_NONE
	var home_sb = StyleBoxFlat.new()
	home_sb.bg_color = Color("#F5EFE4")
	home_sb.border_width_left = 1
	home_sb.border_width_top = 1
	home_sb.border_width_right = 1
	home_sb.border_width_bottom = 1
	home_sb.border_color = Color("#DFD3C1")
	home_sb.set_corner_radius_all(18)
	btn_home.add_theme_stylebox_override("normal", home_sb)
	var home_h = home_sb.duplicate() as StyleBoxFlat
	home_h.bg_color = Color("#F5EFE4").lightened(0.08)
	btn_home.add_theme_stylebox_override("hover", home_h)
	var home_p = home_sb.duplicate() as StyleBoxFlat
	home_p.bg_color = Color("#F5EFE4").darkened(0.08)
	btn_home.add_theme_stylebox_override("pressed", home_p)
	btn_home.add_theme_font_size_override("font_size", 16)
	btn_home.add_theme_color_override("font_color", Color("#5D4037"))
	btn_home.pressed.connect(func():
		_play_click()
		hide()
		home_requested.emit()
	)
	vbox.add_child(btn_home)

func _play_click() -> void:
	if SoundManager.instance:
		SoundManager.instance.play_click()
