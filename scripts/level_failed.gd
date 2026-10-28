class_name LevelFailedScreen
extends Control

## Screen 6: Level Failed Dialog (Exact match to Reference Screenshot with large size).
## Features:
## - Large rounded card with warm cream backdrop and soft elevation shadow
## - Floating Broken Red Heart 💔 with white sticker outline overlapping top edge
## - Top-right circular close button ✕ inside card
## - Title: "Level Failed" (size 30, bold dark brown)
## - Subtitle: "You made 3 wrong moves." (size 19)
## - Big green pill button: "Continue / Watch an ad to continue" with white circle play icon ▶ (height 82px)
## - Big red pill button: "Restart" with refresh icon ↻ (height 72px)

signal retry_requested
signal extra_life_requested
signal home_requested

var card_panel: PanelContainer
var heart_emblem: Control
var lbl_failed_title: Label
var lbl_failed_sub: Label
var btn_continue: Button
var btn_restart: Button
var btn_close: Button

func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	z_index = 60
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
		card_panel.scale = Vector2(0.82, 0.82)
		card_panel.modulate.a = 0.0
		var tw = create_tween().set_parallel(true).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		tw.tween_property(card_panel, "scale", Vector2.ONE, 0.32)
		tw.tween_property(card_panel, "modulate:a", 1.0, 0.22)

	if heart_emblem:
		heart_emblem.scale = Vector2(0.4, 0.4)
		var h_tw = create_tween().set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
		h_tw.tween_property(heart_emblem, "scale", Vector2.ONE, 0.45).set_delay(0.08)

func _build_ui() -> void:
	# 1. Dark dimmed backdrop
	var backdrop = ColorRect.new()
	backdrop.set_anchors_preset(Control.PRESET_FULL_RECT)
	backdrop.color = Color(0.10, 0.08, 0.06, 0.65)
	backdrop.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(backdrop)

	# 2. Main centered wrapper
	var center = CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(center)

	# Main card container with top overflow for floating heart
	var card_wrapper = Control.new()
	card_wrapper.custom_minimum_size = Vector2(540, 620)
	center.add_child(card_wrapper)

	# The white rounded card panel
	card_panel = PanelContainer.new()
	card_panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	card_panel.offset_top = 48.0 # Leave top space for overlapping broken heart
	card_panel.pivot_offset = Vector2(270, 310)

	var sb = StyleBoxFlat.new()
	sb.bg_color = Color("#FFFDF9")
	sb.border_width_left = 2
	sb.border_width_top = 2
	sb.border_width_right = 2
	sb.border_width_bottom = 2
	sb.border_color = Color("#EEDDC8")
	sb.set_corner_radius_all(38)
	sb.shadow_size = 32
	sb.shadow_color = Color(0, 0, 0, 0.24)
	sb.shadow_offset = Vector2(0, 12)
	card_panel.add_theme_stylebox_override("panel", sb)
	card_wrapper.add_child(card_panel)

	# Top right circular Close Button ✕ (inside the card corner, matching reference image)
	btn_close = Button.new()
	btn_close.text = "✕"
	btn_close.custom_minimum_size = Vector2(46, 46)
	btn_close.position = Vector2(540 - 68, 48 + 14)
	btn_close.focus_mode = Control.FOCUS_NONE

	var close_sb = StyleBoxFlat.new()
	close_sb.bg_color = Color("#F3EAE0") # Soft tan circular pill matching Image 6
	close_sb.set_corner_radius_all(23)
	btn_close.add_theme_stylebox_override("normal", close_sb)

	var close_h = close_sb.duplicate() as StyleBoxFlat
	close_h.bg_color = Color("#FAFAF6")
	btn_close.add_theme_stylebox_override("hover", close_h)

	var close_p = close_sb.duplicate() as StyleBoxFlat
	close_p.bg_color = Color("#E8DDD0")
	btn_close.add_theme_stylebox_override("pressed", close_p)

	btn_close.add_theme_font_size_override("font_size", 22)
	btn_close.add_theme_color_override("font_color", Color("#8D6E63"))
	btn_close.pressed.connect(func():
		_play_click()
		hide()
		home_requested.emit()
	)
	card_wrapper.add_child(btn_close)

	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 36)
	margin.add_theme_constant_override("margin_right", 36)
	margin.add_theme_constant_override("margin_top", 64) # Spacing below overlapping heart
	margin.add_theme_constant_override("margin_bottom", 36)
	card_panel.add_child(margin)

	var vbox = VBoxContainer.new()
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_theme_constant_override("separation", 20)
	margin.add_child(vbox)

	# --- 3. Title & Subtitle ("Level Failed" & "You made 3 wrong moves.") ---
	var text_vbox = VBoxContainer.new()
	text_vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	text_vbox.add_theme_constant_override("separation", 6)
	vbox.add_child(text_vbox)

	lbl_failed_title = Label.new()
	lbl_failed_title.text = "Level Failed"
	lbl_failed_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl_failed_title.add_theme_font_size_override("font_size", 32)
	lbl_failed_title.add_theme_color_override("font_color", Color("#3E2723"))
	text_vbox.add_child(lbl_failed_title)

	lbl_failed_sub = Label.new()
	lbl_failed_sub.text = "You made 3 wrong moves."
	lbl_failed_sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl_failed_sub.add_theme_font_size_override("font_size", 20)
	lbl_failed_sub.add_theme_color_override("font_color", Color("#6D5548"))
	text_vbox.add_child(lbl_failed_sub)

	# Spacer
	var spacer = Control.new()
	spacer.custom_minimum_size = Vector2(0, 10)
	vbox.add_child(spacer)

	# --- 4. Green Big Button: "Continue / Watch an ad to continue" ---
	btn_continue = Button.new()
	btn_continue.custom_minimum_size = Vector2(460, 84)
	btn_continue.focus_mode = Control.FOCUS_NONE

	var cont_sb = StyleBoxFlat.new()
	cont_sb.bg_color = Color("#4CAF50")
	cont_sb.set_corner_radius_all(28)
	cont_sb.shadow_size = 12
	cont_sb.shadow_color = Color(0.2, 0.6, 0.25, 0.35)
	cont_sb.shadow_offset = Vector2(0, 6)
	btn_continue.add_theme_stylebox_override("normal", cont_sb)

	var cont_h = cont_sb.duplicate() as StyleBoxFlat
	cont_h.bg_color = Color("#58BA5C")
	btn_continue.add_theme_stylebox_override("hover", cont_h)

	var cont_p = cont_sb.duplicate() as StyleBoxFlat
	cont_p.bg_color = Color("#419845")
	btn_continue.add_theme_stylebox_override("pressed", cont_p)

	# Custom internal content matching reference image:
	# [ (▶) | Continue \n Watch an ad to continue ]
	var cont_margin = MarginContainer.new()
	cont_margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	cont_margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	cont_margin.add_theme_constant_override("margin_left", 26)
	cont_margin.add_theme_constant_override("margin_right", 26)
	btn_continue.add_child(cont_margin)

	var cont_hbox = HBoxContainer.new()
	cont_hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	cont_hbox.add_theme_constant_override("separation", 18)
	cont_hbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	cont_margin.add_child(cont_hbox)

	# Circular white badge with green play triangle ▶
	var play_circle = PanelContainer.new()
	play_circle.custom_minimum_size = Vector2(52, 52)
	var pc_sb = StyleBoxFlat.new()
	pc_sb.bg_color = Color.WHITE
	pc_sb.set_corner_radius_all(26)
	play_circle.add_theme_stylebox_override("panel", pc_sb)
	cont_hbox.add_child(play_circle)

	var lbl_play_icon = Label.new()
	lbl_play_icon.text = "▶"
	lbl_play_icon.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl_play_icon.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	lbl_play_icon.add_theme_font_size_override("font_size", 24)
	lbl_play_icon.add_theme_color_override("font_color", Color("#4CAF50"))
	play_circle.add_child(lbl_play_icon)

	var cont_text_vbox = VBoxContainer.new()
	cont_text_vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	cont_text_vbox.add_theme_constant_override("separation", 2)
	cont_text_vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	cont_hbox.add_child(cont_text_vbox)

	var lbl_cont_title = Label.new()
	lbl_cont_title.text = "Continue"
	lbl_cont_title.add_theme_font_size_override("font_size", 26)
	lbl_cont_title.add_theme_color_override("font_color", Color.WHITE)
	cont_text_vbox.add_child(lbl_cont_title)

	var lbl_cont_sub = Label.new()
	lbl_cont_sub.text = "Watch an ad to continue"
	lbl_cont_sub.add_theme_font_size_override("font_size", 15)
	lbl_cont_sub.add_theme_color_override("font_color", Color("#DCFCE7"))
	cont_text_vbox.add_child(lbl_cont_sub)

	btn_continue.text = "CONTINUE"
	btn_continue.add_theme_color_override("font_color", Color.TRANSPARENT)
	btn_continue.pressed.connect(_on_continue_pressed)
	vbox.add_child(btn_continue)

	# --- 5. Red Big Button: "Restart" ---
	btn_restart = Button.new()
	btn_restart.text = "RESTART"
	btn_restart.add_theme_color_override("font_color", Color.TRANSPARENT)
	btn_restart.custom_minimum_size = Vector2(460, 74)
	btn_restart.focus_mode = Control.FOCUS_NONE

	var rest_sb = StyleBoxFlat.new()
	rest_sb.bg_color = Color("#E53935")
	rest_sb.set_corner_radius_all(28)
	rest_sb.shadow_size = 12
	rest_sb.shadow_color = Color(0.8, 0.2, 0.2, 0.35)
	rest_sb.shadow_offset = Vector2(0, 6)
	btn_restart.add_theme_stylebox_override("normal", rest_sb)

	var rest_h = rest_sb.duplicate() as StyleBoxFlat
	rest_h.bg_color = Color("#F04743")
	btn_restart.add_theme_stylebox_override("hover", rest_h)

	var rest_p = rest_sb.duplicate() as StyleBoxFlat
	rest_p.bg_color = Color("#C62828")
	btn_restart.add_theme_stylebox_override("pressed", rest_p)

	var rest_margin = MarginContainer.new()
	rest_margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	rest_margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	rest_margin.add_theme_constant_override("margin_left", 22)
	rest_margin.add_theme_constant_override("margin_right", 22)
	btn_restart.add_child(rest_margin)

	var rest_hbox = HBoxContainer.new()
	rest_hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	rest_hbox.add_theme_constant_override("separation", 16)
	rest_hbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	rest_margin.add_child(rest_hbox)

	var lbl_rest_icon = Label.new()
	lbl_rest_icon.text = "↻"
	lbl_rest_icon.add_theme_font_size_override("font_size", 28)
	lbl_rest_icon.add_theme_color_override("font_color", Color.WHITE)
	rest_hbox.add_child(lbl_rest_icon)

	var lbl_rest_title = Label.new()
	lbl_rest_title.text = "Restart"
	lbl_rest_title.add_theme_font_size_override("font_size", 26)
	lbl_rest_title.add_theme_color_override("font_color", Color.WHITE)
	rest_hbox.add_child(lbl_rest_title)

	btn_restart.pressed.connect(func():
		_play_click()
		hide()
		retry_requested.emit()
	)
	vbox.add_child(btn_restart)

	# =========================================================================
	# 6. FLOATING BROKEN RED HEART WITH WHITE STICKER OUTLINE OVERLAPPING TOP
	# =========================================================================
	heart_emblem = Control.new()
	heart_emblem.custom_minimum_size = Vector2(110, 110)
	heart_emblem.position = Vector2((540 - 110) * 0.5, 0) # Center top overlapping border
	heart_emblem.pivot_offset = Vector2(55, 55)
	heart_emblem.mouse_filter = Control.MOUSE_FILTER_IGNORE

	# Check for 3D broken heart texture asset:
	var heart_tex = load("res://assets/icons/broken_heart.png") as Texture2D
	if heart_tex:
		var tex_rect = TextureRect.new()
		tex_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
		tex_rect.texture = heart_tex
		tex_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		tex_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		tex_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
		heart_emblem.add_child(tex_rect)
	else:
		# Fallback sticker outline and emoji if texture missing:
		var halo_heart = Label.new()
		halo_heart.text = "💔"
		halo_heart.add_theme_font_size_override("font_size", 84)
		halo_heart.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		halo_heart.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		halo_heart.set_anchors_preset(Control.PRESET_CENTER)
		halo_heart.modulate = Color(1.0, 1.0, 1.0, 0.95)
		heart_emblem.add_child(halo_heart)

		var main_heart = Label.new()
		main_heart.text = "💔"
		main_heart.add_theme_font_size_override("font_size", 76)
		main_heart.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		main_heart.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		main_heart.set_anchors_preset(Control.PRESET_CENTER)
		heart_emblem.add_child(main_heart)

	card_wrapper.add_child(heart_emblem)

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

