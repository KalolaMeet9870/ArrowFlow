class_name LevelCompleteScreen
extends Control

## Level Complete Screen with star animations, moves count, hearts left, and progression buttons.

signal next_level_requested
signal replay_requested
signal home_requested

var lbl_level_title: Label
var lbl_stats: Label
var hearts_container: HBoxContainer
var card_panel: PanelContainer
var star_label: Label

func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	z_index = 50
	_build_ui()
	hide()

func display_completion(level_id: int, moves: int, hearts: int) -> void:
	if lbl_level_title:
		lbl_level_title.text = "LEVEL %d COMPLETED!" % level_id
	if lbl_stats:
		lbl_stats.text = "Completed in %d moves  •  ⭐ +10 Coins" % moves

	if hearts_container:
		for c in hearts_container.get_children():
			c.queue_free()
		for i in range(3):
			var drop_lbl = Label.new()
			drop_lbl.text = "💧"
			drop_lbl.add_theme_font_size_override("font_size", 34)
			if i < hearts:
				drop_lbl.modulate = Color(1.0, 1.0, 1.0, 1.0)
			else:
				drop_lbl.modulate = Color(0.4, 0.4, 0.4, 0.3)
			hearts_container.add_child(drop_lbl)

	show()
	_animate_card_in()

func _animate_card_in() -> void:
	if card_panel:
		card_panel.scale = Vector2(0.85, 0.85)
		card_panel.modulate.a = 0.0
		var tw = create_tween().set_parallel(true).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		tw.tween_property(card_panel, "scale", Vector2.ONE, 0.35)
		tw.tween_property(card_panel, "modulate:a", 1.0, 0.25)

	if star_label:
		star_label.scale = Vector2(0.4, 0.4)
		var s_tw = create_tween().set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
		s_tw.tween_property(star_label, "scale", Vector2.ONE, 0.5).set_delay(0.12)

func _build_ui() -> void:
	# Semi-transparent backdrop
	var backdrop = ColorRect.new()
	backdrop.set_anchors_preset(Control.PRESET_FULL_RECT)
	backdrop.color = Color(0.12, 0.09, 0.06, 0.65)
	add_child(backdrop)

	var center = CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(center)

	card_panel = PanelContainer.new()
	card_panel.custom_minimum_size = Vector2(360, 440)
	card_panel.pivot_offset = Vector2(180, 220)

	var sb = StyleBoxFlat.new()
	sb.bg_color = Color("#FFFDF8")
	sb.border_width_left = 3
	sb.border_width_top = 3
	sb.border_width_right = 3
	sb.border_width_bottom = 3
	sb.border_color = Color("#E6CE9D")
	sb.set_corner_radius_all(28)
	sb.shadow_size = 20
	sb.shadow_color = Color(0, 0, 0, 0.2)
	sb.shadow_offset = Vector2(0, 8)
	card_panel.add_theme_stylebox_override("panel", sb)
	center.add_child(card_panel)

	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 26)
	margin.add_theme_constant_override("margin_right", 26)
	margin.add_theme_constant_override("margin_top", 28)
	margin.add_theme_constant_override("margin_bottom", 28)
	card_panel.add_child(margin)

	var vbox = VBoxContainer.new()
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_theme_constant_override("separation", 12)
	margin.add_child(vbox)

	star_label = Label.new()
	star_label.text = "★ ★ ★"
	star_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	star_label.pivot_offset = Vector2(80, 20)
	star_label.add_theme_font_size_override("font_size", 38)
	star_label.add_theme_color_override("font_color", Color("#F5A623"))
	vbox.add_child(star_label)

	lbl_level_title = Label.new()
	lbl_level_title.text = "LEVEL COMPLETED!"
	lbl_level_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl_level_title.add_theme_font_size_override("font_size", 24)
	lbl_level_title.add_theme_color_override("font_color", Color("#4A3525"))
	vbox.add_child(lbl_level_title)

	lbl_stats = Label.new()
	lbl_stats.text = "Completed in 5 moves  •  ⭐ +10 Coins"
	lbl_stats.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl_stats.add_theme_font_size_override("font_size", 14)
	lbl_stats.add_theme_color_override("font_color", Color("#8D6E63"))
	vbox.add_child(lbl_stats)

	hearts_container = HBoxContainer.new()
	hearts_container.alignment = BoxContainer.ALIGNMENT_CENTER
	hearts_container.add_theme_constant_override("separation", 10)
	vbox.add_child(hearts_container)

	# Spacer
	var spacer = Control.new()
	spacer.custom_minimum_size = Vector2(0, 8)
	vbox.add_child(spacer)

	# Action Buttons (Primary: CONTINUE TO HOME)
	var btn_home = _create_action_btn("CONTINUE TO HOME 🏠", Color("#9E4040"), 52)
	btn_home.pressed.connect(func():
		_play_click()
		hide()
		home_requested.emit()
	)
	vbox.add_child(btn_home)

	var btn_next = _create_action_btn("NEXT LEVEL ▶", Color("#B57538"), 46)
	btn_next.pressed.connect(func():
		_play_click()
		hide()
		next_level_requested.emit()
	)
	vbox.add_child(btn_next)

	var btn_replay = _create_action_btn("REPLAY ↺", Color("#8D6E63"), 40)
	btn_replay.pressed.connect(func():
		_play_click()
		hide()
		replay_requested.emit()
	)
	vbox.add_child(btn_replay)

func _create_action_btn(text: String, bg_col: Color, min_height: int) -> Button:
	var btn = Button.new()
	btn.text = text
	btn.custom_minimum_size = Vector2(220, min_height)
	btn.focus_mode = Control.FOCUS_NONE

	var sb = StyleBoxFlat.new()
	sb.bg_color = bg_col
	sb.corner_radius_top_left = 12
	sb.corner_radius_top_right = 12
	sb.corner_radius_bottom_left = 12
	sb.corner_radius_bottom_right = 12
	sb.shadow_size = 4
	sb.shadow_color = Color(0, 0, 0, 0.08)
	btn.add_theme_stylebox_override("normal", sb)

	var h_sb = sb.duplicate() as StyleBoxFlat
	h_sb.bg_color = bg_col.lightened(0.12)
	btn.add_theme_stylebox_override("hover", h_sb)

	var p_sb = sb.duplicate() as StyleBoxFlat
	p_sb.bg_color = bg_col.darkened(0.1)
	btn.add_theme_stylebox_override("pressed", p_sb)

	btn.add_theme_font_size_override("font_size", 15)
	btn.add_theme_color_override("font_color", Color("#FFFFFF"))
	return btn

func _play_click() -> void:
	if SoundManager.instance:
		SoundManager.instance.play_click()
