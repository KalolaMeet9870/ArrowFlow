class_name LevelFailedScreen
extends Control

## Exact 1:1 match to Reference Screenshot (Level Failed Modal):
## - Velvet ivory cream rounded card (#FEFBEE) with soft elevation shadow, centered in height
## - Plump glossy 3D Broken Heart icon elevated above the card top edge with white sticker border
## - Snug, proper space between broken heart bottom and title "Level Failed"
## - Top-right circular warm apricot close button ✕
## - Title: "Level Failed" (prominent, bold espresso #26140A)
## - Subtitle: "You made 3 wrong moves." (warm brown #5C4538)
## - Big lush emerald green button: [ (▶) | Continue \n Watch an ad to continue ]
## - Big vibrant coral red button: [ ↻ | Restart ] with restart icon aligned from the start same as Continue button
## - Balanced, snug space below Restart button matching reference

signal retry_requested
signal extra_life_requested
signal home_requested

var card_wrapper: Control
var card_panel: PanelContainer
var heart_emblem: Control
var lbl_failed_title: Label
var lbl_failed_sub: Label
var btn_continue: Button
var btn_restart: Button
var btn_close: Button

const CARD_WIDTH := 644.0
const CARD_HEIGHT := 660.0

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
	if is_instance_valid(card_wrapper):
		card_wrapper.scale = Vector2(0.88, 0.88)
		card_wrapper.modulate.a = 0.0
		var tw := create_tween().set_parallel(true).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		tw.tween_property(card_wrapper, "scale", Vector2.ONE, 0.30)
		tw.tween_property(card_wrapper, "modulate:a", 1.0, 0.22)

	if is_instance_valid(heart_emblem):
		heart_emblem.scale = Vector2(0.40, 0.40)
		var h_tw := create_tween().set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
		h_tw.tween_property(heart_emblem, "scale", Vector2.ONE, 0.48).set_delay(0.08)

func _build_ui() -> void:
	var round_font: FontFile = null
	if ResourceLoader.exists("res://assets/fonts/round_bold.ttf"):
		round_font = load("res://assets/fonts/round_bold.ttf") as FontFile

	# 1. Warm dimmed backdrop matching reference
	var backdrop := ColorRect.new()
	backdrop.set_anchors_preset(Control.PRESET_FULL_RECT)
	backdrop.color = Color(0.18, 0.14, 0.10, 0.55)
	backdrop.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(backdrop)

	# 2. Main card wrapper positioned centered in height
	card_wrapper = Control.new()
	card_wrapper.set_anchors_preset(Control.PRESET_CENTER)
	card_wrapper.custom_minimum_size = Vector2(CARD_WIDTH, CARD_HEIGHT)
	card_wrapper.size = Vector2(CARD_WIDTH, CARD_HEIGHT)
	card_wrapper.pivot_offset = Vector2(CARD_WIDTH * 0.5, CARD_HEIGHT * 0.5)
	card_wrapper.offset_left = -CARD_WIDTH * 0.5
	card_wrapper.offset_right = CARD_WIDTH * 0.5
	card_wrapper.offset_top = -CARD_HEIGHT * 0.5
	card_wrapper.offset_bottom = CARD_HEIGHT * 0.5
	card_wrapper.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(card_wrapper)

	# 3. Warm velvety ivory cream rounded card panel matching reference #FEFBEE
	card_panel = PanelContainer.new()
	card_panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	card_panel.mouse_filter = Control.MOUSE_FILTER_STOP

	var card_style := StyleBoxFlat.new()
	card_style.bg_color = Color("#FEFBEE")
	card_style.border_width_left = 2
	card_style.border_width_top = 2
	card_style.border_width_right = 2
	card_style.border_width_bottom = 2
	card_style.border_color = Color("#EBDCC7")
	card_style.set_corner_radius_all(50)
	card_style.shadow_size = 32
	card_style.shadow_color = Color(0.12, 0.08, 0.04, 0.22)
	card_style.shadow_offset = Vector2(0, 10)
	card_panel.add_theme_stylebox_override("panel", card_style)
	card_wrapper.add_child(card_panel)

	# 4. Top-right circular Close Button ✕ (inside the card corner, matching reference)
	btn_close = Button.new()
	btn_close.text = "✕"
	btn_close.custom_minimum_size = Vector2(64, 64)
	btn_close.size = Vector2(64, 64)
	btn_close.position = Vector2(CARD_WIDTH - 64.0 - 26.0, 26.0)
	btn_close.focus_mode = Control.FOCUS_NONE

	var close_sb := StyleBoxFlat.new()
	close_sb.bg_color = Color("#F4DAB8") # Warm apricot tan matching reference
	close_sb.set_corner_radius_all(32)
	btn_close.add_theme_stylebox_override("normal", close_sb)

	var close_h := close_sb.duplicate() as StyleBoxFlat
	close_h.bg_color = Color("#FAE6CB")
	btn_close.add_theme_stylebox_override("hover", close_h)

	var close_p := close_sb.duplicate() as StyleBoxFlat
	close_p.bg_color = Color("#E8CAA4")
	btn_close.add_theme_stylebox_override("pressed", close_p)

	btn_close.add_theme_font_size_override("font_size", 28)
	btn_close.add_theme_color_override("font_color", Color("#8B5E3C"))
	btn_close.pressed.connect(func() -> void:
		_play_click()
		hide()
		home_requested.emit()
	)
	card_wrapper.add_child(btn_close)

	# 5. Content Container inside card panel (snug clearance below heart)
	var margin := MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 28)
	margin.add_theme_constant_override("margin_right", 28)
	margin.add_theme_constant_override("margin_top", 165) # Snug ~33px space below elevated heart
	margin.add_theme_constant_override("margin_bottom", 40)
	card_panel.add_child(margin)

	var vbox := VBoxContainer.new()
	vbox.alignment = BoxContainer.ALIGNMENT_BEGIN
	vbox.add_theme_constant_override("separation", 22)
	margin.add_child(vbox)

	# Title & Subtitle ("Level Failed" & "You made 3 wrong moves.")
	var heading_box := VBoxContainer.new()
	heading_box.alignment = BoxContainer.ALIGNMENT_CENTER
	heading_box.add_theme_constant_override("separation", 8)
	vbox.add_child(heading_box)

	lbl_failed_title = Label.new()
	lbl_failed_title.text = "Level Failed"
	lbl_failed_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl_failed_title.add_theme_font_size_override("font_size", 52)
	lbl_failed_title.add_theme_color_override("font_color", Color("#26140A"))
	if round_font:
		lbl_failed_title.add_theme_font_override("font", round_font)
	heading_box.add_child(lbl_failed_title)

	lbl_failed_sub = Label.new()
	lbl_failed_sub.text = "You made 3 wrong moves."
	lbl_failed_sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl_failed_sub.add_theme_font_size_override("font_size", 28)
	lbl_failed_sub.add_theme_color_override("font_color", Color("#5C4538"))
	if round_font:
		lbl_failed_sub.add_theme_font_override("font", round_font)
	heading_box.add_child(lbl_failed_sub)

	# Spacer between subtitle and green button matching reference
	var spacer := Control.new()
	spacer.custom_minimum_size = Vector2(0, 14)
	vbox.add_child(spacer)

	# 6. Green Button: "Continue / Watch an ad to continue" (aligned from start)
	btn_continue = Button.new()
	btn_continue.custom_minimum_size = Vector2(0, 164)
	btn_continue.focus_mode = Control.FOCUS_NONE

	var cont_sb := StyleBoxFlat.new()
	cont_sb.bg_color = Color("#52A769") # Rich leafy emerald green matching reference
	cont_sb.set_corner_radius_all(38)
	cont_sb.shadow_size = 14
	cont_sb.shadow_color = Color(0.12, 0.40, 0.20, 0.35)
	cont_sb.shadow_offset = Vector2(0, 6)
	btn_continue.add_theme_stylebox_override("normal", cont_sb)

	var cont_h := cont_sb.duplicate() as StyleBoxFlat
	cont_h.bg_color = Color("#5EB575")
	btn_continue.add_theme_stylebox_override("hover", cont_h)

	var cont_p := cont_sb.duplicate() as StyleBoxFlat
	cont_p.bg_color = Color("#45945A")
	btn_continue.add_theme_stylebox_override("pressed", cont_p)

	var cont_margin := MarginContainer.new()
	cont_margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	cont_margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	cont_margin.add_theme_constant_override("margin_left", 32)
	cont_margin.add_theme_constant_override("margin_right", 32)
	btn_continue.add_child(cont_margin)

	var cont_hbox := HBoxContainer.new()
	cont_hbox.alignment = BoxContainer.ALIGNMENT_BEGIN
	cont_hbox.add_theme_constant_override("separation", 24)
	cont_hbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	cont_margin.add_child(cont_hbox)

	# Badge: icon_continue_ad.png (size 96x96)
	var cont_tex := load("res://assets/icons/icon_continue_ad.png") as Texture2D
	if cont_tex:
		var cont_rect := TextureRect.new()
		cont_rect.texture = cont_tex
		cont_rect.custom_minimum_size = Vector2(96, 96)
		cont_rect.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		cont_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		cont_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		cont_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
		cont_hbox.add_child(cont_rect)
	else:
		var play_circle := PanelContainer.new()
		play_circle.custom_minimum_size = Vector2(80, 80)
		var pc_sb := StyleBoxFlat.new()
		pc_sb.bg_color = Color.WHITE
		pc_sb.set_corner_radius_all(40)
		play_circle.add_theme_stylebox_override("panel", pc_sb)
		var lbl_play := Label.new()
		lbl_play.text = "▶"
		lbl_play.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lbl_play.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		lbl_play.add_theme_font_size_override("font_size", 36)
		lbl_play.add_theme_color_override("font_color", Color("#52A769"))
		play_circle.add_child(lbl_play)
		cont_hbox.add_child(play_circle)

	var cont_text_vbox := VBoxContainer.new()
	cont_text_vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	cont_text_vbox.add_theme_constant_override("separation", 4)
	cont_text_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	cont_text_vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	cont_hbox.add_child(cont_text_vbox)

	var lbl_cont_title := Label.new()
	lbl_cont_title.text = "Continue"
	lbl_cont_title.add_theme_font_size_override("font_size", 42)
	lbl_cont_title.add_theme_color_override("font_color", Color.WHITE)
	if round_font:
		lbl_cont_title.add_theme_font_override("font", round_font)
	cont_text_vbox.add_child(lbl_cont_title)

	var lbl_cont_sub := Label.new()
	lbl_cont_sub.text = "Watch an ad to continue"
	lbl_cont_sub.add_theme_font_size_override("font_size", 22)
	lbl_cont_sub.add_theme_color_override("font_color", Color("#DCFCE7"))
	if round_font:
		lbl_cont_sub.add_theme_font_override("font", round_font)
	cont_text_vbox.add_child(lbl_cont_sub)

	btn_continue.pressed.connect(_on_continue_pressed)
	vbox.add_child(btn_continue)

	# 7. Red Button: "Restart" (aligned from start same as Continue button)
	btn_restart = Button.new()
	btn_restart.custom_minimum_size = Vector2(0, 140)
	btn_restart.focus_mode = Control.FOCUS_NONE

	var rest_sb := StyleBoxFlat.new()
	rest_sb.bg_color = Color("#E4534B") # Vibrant coral red matching reference
	rest_sb.set_corner_radius_all(38)
	rest_sb.shadow_size = 14
	rest_sb.shadow_color = Color(0.70, 0.18, 0.15, 0.35)
	rest_sb.shadow_offset = Vector2(0, 6)
	btn_restart.add_theme_stylebox_override("normal", rest_sb)

	var rest_h := rest_sb.duplicate() as StyleBoxFlat
	rest_h.bg_color = Color("#ED625A")
	btn_restart.add_theme_stylebox_override("hover", rest_h)

	var rest_p := rest_sb.duplicate() as StyleBoxFlat
	rest_p.bg_color = Color("#CC423A")
	btn_restart.add_theme_stylebox_override("pressed", rest_p)

	# Left margin 52 aligns restart icon center (52 + 28 = 80) with continue icon center (32 + 48 = 80)
	var rest_margin := MarginContainer.new()
	rest_margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	rest_margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	rest_margin.add_theme_constant_override("margin_left", 52)
	rest_margin.add_theme_constant_override("margin_right", 32)
	btn_restart.add_child(rest_margin)

	var rest_hbox := HBoxContainer.new()
	rest_hbox.alignment = BoxContainer.ALIGNMENT_BEGIN
	rest_hbox.add_theme_constant_override("separation", 44)
	rest_hbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	rest_margin.add_child(rest_hbox)

	var rest_tex := load("res://assets/icons/icon_restart_arrow.png") as Texture2D
	if rest_tex:
		var rest_rect := TextureRect.new()
		rest_rect.texture = rest_tex
		rest_rect.custom_minimum_size = Vector2(56, 56)
		rest_rect.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		rest_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		rest_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		rest_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
		rest_hbox.add_child(rest_rect)
	else:
		var lbl_rest_icon := Label.new()
		lbl_rest_icon.text = "↻"
		lbl_rest_icon.add_theme_font_size_override("font_size", 38)
		lbl_rest_icon.add_theme_color_override("font_color", Color.WHITE)
		lbl_rest_icon.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		rest_hbox.add_child(lbl_rest_icon)

	var lbl_rest_title := Label.new()
	lbl_rest_title.text = "Restart"
	lbl_rest_title.add_theme_font_size_override("font_size", 42)
	lbl_rest_title.add_theme_color_override("font_color", Color.WHITE)
	lbl_rest_title.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	if round_font:
		lbl_rest_title.add_theme_font_override("font", round_font)
	rest_hbox.add_child(lbl_rest_title)

	btn_restart.pressed.connect(func() -> void:
		_play_click()
		hide()
		retry_requested.emit()
	)
	vbox.add_child(btn_restart)

	# 8. Floating Broken Red Heart with White Sticker Outline Overlapping Top
	# Elevated slightly more ("some above")
	heart_emblem = Control.new()
	var heart_size := Vector2(200, 180)
	heart_emblem.custom_minimum_size = heart_size
	heart_emblem.size = heart_size
	heart_emblem.position = Vector2((CARD_WIDTH - heart_size.x) * 0.5, -48.0)
	heart_emblem.pivot_offset = heart_size * 0.5
	heart_emblem.mouse_filter = Control.MOUSE_FILTER_IGNORE
	heart_emblem.z_index = 2

	var heart_tex := load("res://assets/icons/broken_heart.png") as Texture2D
	if heart_tex:
		var tex_rect := TextureRect.new()
		tex_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
		tex_rect.texture = heart_tex
		tex_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		tex_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		tex_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
		heart_emblem.add_child(tex_rect)

	card_wrapper.add_child(heart_emblem)

func _on_continue_pressed() -> void:
	_play_click()
	if AdMobManager.instance:
		btn_continue.disabled = true
		AdMobManager.instance.show_rewarded_ad(
			func() -> void:
				btn_continue.disabled = false
				hide()
				extra_life_requested.emit(),
			func() -> void:
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
