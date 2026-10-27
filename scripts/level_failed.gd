class_name LevelFailedScreen
extends Control

## Screen 6: Level Failed Dialog (matching Reference Image 6).
## Features:
## - Top-right Close button ✕
## - Broken red heart icon 💔
## - Title: "Level Failed"
## - Subtitle: "You made 3 wrong moves."
## - Green "Continue / Watch an ad to continue" button with Play icon ▶
## - Red "Restart" button with refresh icon ⟲

signal retry_requested
signal extra_life_requested
signal home_requested

var card_panel: PanelContainer
var lbl_failed_title: Label
var lbl_failed_sub: Label
var btn_continue: Button
var btn_restart: Button
var btn_close: Button

func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	z_index = 50
	_build_ui()
	hide()

func display_failed(level_id: int) -> void:
	if lbl_failed_title:
		lbl_failed_title.text = "Level Failed"
	if lbl_failed_sub:
		lbl_failed_sub.text = "You made 3 wrong moves."
	show()
	_animate_card_in()

func _animate_card_in() -> void:
	if card_panel:
		card_panel.scale = Vector2(0.85, 0.85)
		card_panel.modulate.a = 0.0
		var tw = create_tween().set_parallel(true).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		tw.tween_property(card_panel, "scale", Vector2.ONE, 0.3)
		tw.tween_property(card_panel, "modulate:a", 1.0, 0.2)

func _build_ui() -> void:
	var backdrop = ColorRect.new()
	backdrop.set_anchors_preset(Control.PRESET_FULL_RECT)
	backdrop.color = Color(0.12, 0.09, 0.06, 0.72)
	backdrop.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(backdrop)

	var center = CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(center)

	card_panel = PanelContainer.new()
	card_panel.custom_minimum_size = Vector2(400, 560)
	card_panel.pivot_offset = Vector2(200, 280)

	var sb = StyleBoxFlat.new()
	sb.bg_color = Color("#FFFDF9")
	sb.border_width_left = 2
	sb.border_width_top = 2
	sb.border_width_right = 2
	sb.border_width_bottom = 2
	sb.border_color = Color("#EADCC6")
	sb.set_corner_radius_all(32)
	sb.shadow_size = 24
	sb.shadow_color = Color(0, 0, 0, 0.25)
	sb.shadow_offset = Vector2(0, 8)
	card_panel.add_theme_stylebox_override("panel", sb)
	center.add_child(card_panel)

	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 30)
	margin.add_theme_constant_override("margin_right", 30)
	margin.add_theme_constant_override("margin_top", 24)
	margin.add_theme_constant_override("margin_bottom", 28)
	card_panel.add_child(margin)

	var vbox = VBoxContainer.new()
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_theme_constant_override("separation", 16)
	margin.add_child(vbox)

	# 1. Close Button ✕ (top-right, Image 6)
	var top_row = HBoxContainer.new()
	vbox.add_child(top_row)

	var top_spacer = Control.new()
	top_spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top_row.add_child(top_spacer)

	btn_close = Button.new()
	btn_close.text = "✕"
	btn_close.custom_minimum_size = Vector2(40, 40)
	btn_close.focus_mode = Control.FOCUS_NONE
	var close_sb = StyleBoxFlat.new()
	close_sb.bg_color = Color(0, 0, 0, 0)
	btn_close.add_theme_stylebox_override("normal", close_sb)
	btn_close.add_theme_stylebox_override("hover", close_sb)
	btn_close.add_theme_stylebox_override("pressed", close_sb)
	btn_close.add_theme_font_size_override("font_size", 24)
	btn_close.add_theme_color_override("font_color", Color("#A08C7D"))
	btn_close.pressed.connect(func():
		_play_click()
		hide()
		home_requested.emit()
	)
	top_row.add_child(btn_close)

	# 2. Broken Red Heart Emblem 💔 (Image 6)
	var emblem_center = CenterContainer.new()
	vbox.add_child(emblem_center)

	var heart_ctrl = Control.new()
	heart_ctrl.custom_minimum_size = Vector2(84, 84)
	heart_ctrl.draw.connect(func():
		var c = Vector2(42, 40)
		# Draw soft red badge circle
		heart_ctrl.draw_circle(c, 38.0, Color("#FDE8E8"))
		heart_ctrl.draw_circle(c, 32.0, Color("#F8D7DA"))
	)
	emblem_center.add_child(heart_ctrl)

	var lbl_heart = Label.new()
	lbl_heart.text = "💔"
	lbl_heart.set_anchors_preset(Control.PRESET_FULL_RECT)
	lbl_heart.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl_heart.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	lbl_heart.add_theme_font_size_override("font_size", 44)
	heart_ctrl.add_child(lbl_heart)

	# 3. Title: "Level Failed" (Image 6)
	lbl_failed_title = Label.new()
	lbl_failed_title.text = "Level Failed"
	lbl_failed_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl_failed_title.add_theme_font_size_override("font_size", 28)
	lbl_failed_title.add_theme_color_override("font_color", Color("#3E2723"))
	vbox.add_child(lbl_failed_title)

	# 4. Subtitle: "You made 3 wrong moves." (Image 6)
	lbl_failed_sub = Label.new()
	lbl_failed_sub.text = "You made 3 wrong moves."
	lbl_failed_sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl_failed_sub.add_theme_font_size_override("font_size", 18)
	lbl_failed_sub.add_theme_color_override("font_color", Color("#8D6E63"))
	vbox.add_child(lbl_failed_sub)

	# Spacer
	var spacer = Control.new()
	spacer.custom_minimum_size = Vector2(0, 8)
	vbox.add_child(spacer)

	# 5. Green Button: "Continue / Watch an ad to continue" (Image 6)
	btn_continue = Button.new()
	btn_continue.custom_minimum_size = Vector2(320, 68)
	btn_continue.focus_mode = Control.FOCUS_NONE
	var cont_sb = StyleBoxFlat.new()
	cont_sb.bg_color = Color("#4CAF50")
	cont_sb.set_corner_radius_all(22)
	cont_sb.shadow_size = 6
	cont_sb.shadow_color = Color(0, 0, 0, 0.15)
	cont_sb.shadow_offset = Vector2(0, 3)
	btn_continue.add_theme_stylebox_override("normal", cont_sb)
	var cont_h = cont_sb.duplicate() as StyleBoxFlat
	cont_h.bg_color = Color("#4CAF50").lightened(0.1)
	btn_continue.add_theme_stylebox_override("hover", cont_h)
	var cont_p = cont_sb.duplicate() as StyleBoxFlat
	cont_p.bg_color = Color("#4CAF50").darkened(0.1)
	btn_continue.add_theme_stylebox_override("pressed", cont_p)

	var cont_margin = MarginContainer.new()
	cont_margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	cont_margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	cont_margin.add_theme_constant_override("margin_left", 18)
	cont_margin.add_theme_constant_override("margin_right", 18)
	btn_continue.add_child(cont_margin)

	var cont_hbox = HBoxContainer.new()
	cont_hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	cont_hbox.add_theme_constant_override("separation", 14)
	cont_hbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	cont_margin.add_child(cont_hbox)

	var lbl_play_icon = Label.new()
	lbl_play_icon.text = "▶"
	lbl_play_icon.add_theme_font_size_override("font_size", 24)
	lbl_play_icon.add_theme_color_override("font_color", Color.WHITE)
	cont_hbox.add_child(lbl_play_icon)

	var cont_text_vbox = VBoxContainer.new()
	cont_text_vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	cont_text_vbox.add_theme_constant_override("separation", 2)
	cont_text_vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	cont_hbox.add_child(cont_text_vbox)

	var lbl_cont_title = Label.new()
	lbl_cont_title.text = "Continue"
	lbl_cont_title.add_theme_font_size_override("font_size", 20)
	lbl_cont_title.add_theme_color_override("font_color", Color.WHITE)
	cont_text_vbox.add_child(lbl_cont_title)

	var lbl_cont_sub = Label.new()
	lbl_cont_sub.text = "Watch an ad to continue"
	lbl_cont_sub.add_theme_font_size_override("font_size", 13)
	lbl_cont_sub.add_theme_color_override("font_color", Color("#D5F5E3"))
	cont_text_vbox.add_child(lbl_cont_sub)

	btn_continue.text = "CONTINUE"
	btn_continue.add_theme_color_override("font_color", Color.TRANSPARENT)
	btn_continue.pressed.connect(_on_continue_pressed)
	vbox.add_child(btn_continue)

	# 6. Red Button: "Restart" (Image 6)
	btn_restart = Button.new()
	btn_restart.text = "RESTART"
	btn_restart.add_theme_color_override("font_color", Color.TRANSPARENT)
	btn_restart.custom_minimum_size = Vector2(320, 60)
	btn_restart.focus_mode = Control.FOCUS_NONE
	var rest_sb = StyleBoxFlat.new()
	rest_sb.bg_color = Color("#E74C3C")
	rest_sb.set_corner_radius_all(22)
	rest_sb.shadow_size = 6
	rest_sb.shadow_color = Color(0, 0, 0, 0.15)
	rest_sb.shadow_offset = Vector2(0, 3)
	btn_restart.add_theme_stylebox_override("normal", rest_sb)
	var rest_h = rest_sb.duplicate() as StyleBoxFlat
	rest_h.bg_color = Color("#E74C3C").lightened(0.1)
	btn_restart.add_theme_stylebox_override("hover", rest_h)
	var rest_p = rest_sb.duplicate() as StyleBoxFlat
	rest_p.bg_color = Color("#E74C3C").darkened(0.1)
	btn_restart.add_theme_stylebox_override("pressed", rest_p)

	var rest_margin = MarginContainer.new()
	rest_margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	rest_margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	rest_margin.add_theme_constant_override("margin_left", 14)
	rest_margin.add_theme_constant_override("margin_right", 14)
	btn_restart.add_child(rest_margin)

	var rest_hbox = HBoxContainer.new()
	rest_hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	rest_hbox.add_theme_constant_override("separation", 10)
	rest_hbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	rest_margin.add_child(rest_hbox)

	var lbl_rest_icon = Label.new()
	lbl_rest_icon.text = "⟲"
	lbl_rest_icon.add_theme_font_size_override("font_size", 22)
	lbl_rest_icon.add_theme_color_override("font_color", Color.WHITE)
	rest_hbox.add_child(lbl_rest_icon)

	var lbl_rest_title = Label.new()
	lbl_rest_title.text = "Restart"
	lbl_rest_title.add_theme_font_size_override("font_size", 16)
	lbl_rest_title.add_theme_color_override("font_color", Color.WHITE)
	rest_hbox.add_child(lbl_rest_title)

	btn_restart.pressed.connect(func():
		_play_click()
		hide()
		retry_requested.emit()
	)
	vbox.add_child(btn_restart)

func _on_continue_pressed() -> void:
	_play_click()
	if AdMobManager.instance:
		btn_continue.disabled = true
		AdMobManager.instance.show_rewarded_ad(
			func():
				btn_continue.disabled = false
				hide()
				extra_life_requested.emit(),
			func():
				btn_continue.disabled = false
				if lbl_failed_sub:
					lbl_failed_sub.text = "Ad was not completed. Tap Continue to try again."
		)
	else:
		hide()
		extra_life_requested.emit()

func _play_click() -> void:
	if SoundManager.instance:
		SoundManager.instance.play_click()
