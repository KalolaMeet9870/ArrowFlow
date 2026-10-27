class_name LevelFailedScreen
extends Control

## Level Failed Screen shown when player makes 3 incorrect selections (out of drops).
## Displays two primary options: Restart and Continue (via AdMob Rewarded Ad).

signal retry_requested
signal extra_life_requested
signal home_requested

var lbl_failed_title: Label
var lbl_failed_sub: Label
var card_panel: PanelContainer
var btn_continue: Button
var btn_restart: Button

func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	z_index = 50
	_build_ui()
	hide()

func display_failed(level_id: int) -> void:
	if lbl_failed_title:
		lbl_failed_title.text = "LEVEL %d" % level_id
	if lbl_failed_sub:
		lbl_failed_sub.text = "You reached 3 wrong moves!\nContinue from your progress with an ad, or restart."
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
	backdrop.color = Color(0.12, 0.09, 0.06, 0.75)
	add_child(backdrop)

	var center = CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(center)

	card_panel = PanelContainer.new()
	card_panel.custom_minimum_size = Vector2(340, 380)
	card_panel.pivot_offset = Vector2(170, 190)

	var sb = StyleBoxFlat.new()
	sb.bg_color = Color("#FAF4E8")
	sb.border_width_left = 2
	sb.border_width_top = 2
	sb.border_width_right = 2
	sb.border_width_bottom = 2
	sb.border_color = Color("#E0D5C1")
	sb.corner_radius_top_left = 24
	sb.corner_radius_top_right = 24
	sb.corner_radius_bottom_left = 24
	sb.corner_radius_bottom_right = 24
	sb.shadow_size = 20
	sb.shadow_color = Color(0, 0, 0, 0.25)
	sb.shadow_offset = Vector2(0, 8)
	card_panel.add_theme_stylebox_override("panel", sb)
	center.add_child(card_panel)

	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 28)
	margin.add_theme_constant_override("margin_right", 28)
	margin.add_theme_constant_override("margin_top", 28)
	margin.add_theme_constant_override("margin_bottom", 28)
	card_panel.add_child(margin)

	var vbox = VBoxContainer.new()
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_theme_constant_override("separation", 14)
	margin.add_child(vbox)

	var emblem = Label.new()
	emblem.text = "💧"
	emblem.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	emblem.add_theme_font_size_override("font_size", 44)
	vbox.add_child(emblem)

	lbl_failed_title = Label.new()
	lbl_failed_title.text = "OUT OF DROPS"
	lbl_failed_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl_failed_title.add_theme_font_size_override("font_size", 22)
	lbl_failed_title.add_theme_color_override("font_color", Color("#D32F2F"))
	vbox.add_child(lbl_failed_title)

	lbl_failed_sub = Label.new()
	lbl_failed_sub.text = "3 incorrect selections made.\nContinue from current progress with an ad?"
	lbl_failed_sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl_failed_sub.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	lbl_failed_sub.add_theme_font_size_override("font_size", 13)
	lbl_failed_sub.add_theme_color_override("font_color", Color("#8D6E63"))
	vbox.add_child(lbl_failed_sub)

	# Spacer
	var spacer = Control.new()
	spacer.custom_minimum_size = Vector2(0, 8)
	vbox.add_child(spacer)

	# Option 1: Continue (Rewarded Ad)
	btn_continue = _create_action_btn("CONTINUE (WATCH AD 📺)", Color("#2E7D32"), 50)
	btn_continue.pressed.connect(_on_continue_pressed)
	vbox.add_child(btn_continue)

	# Option 2: Restart
	btn_restart = _create_action_btn("RESTART ↺", Color("#B37B24"), 46)
	btn_restart.pressed.connect(_on_restart_pressed)
	vbox.add_child(btn_restart)

	# Subtle Return to Home
	var btn_home = Button.new()
	btn_home.text = "Return to Home ⌂"
	btn_home.focus_mode = Control.FOCUS_NONE
	var empty_sb = StyleBoxEmpty.new()
	btn_home.add_theme_stylebox_override("normal", empty_sb)
	btn_home.add_theme_font_size_override("font_size", 12)
	btn_home.add_theme_color_override("font_color", Color("#8D6E63"))
	btn_home.pressed.connect(func():
		_play_click()
		hide()
		home_requested.emit()
	)
	vbox.add_child(btn_home)

func _on_continue_pressed() -> void:
	_play_click()
	if AdMobManager.instance:
		AdMobManager.instance.show_rewarded_ad(
			func():
				# Ad successfully completed -> Grant extra life and continue from current progress
				hide()
				extra_life_requested.emit(),
			func():
				# Ad failed or closed without reward
				if lbl_failed_sub:
					lbl_failed_sub.text = "Ad was not completed.\nWatch full ad to continue or tap Restart."
		)
	else:
		# Fallback if AdMobManager not initialized
		hide()
		extra_life_requested.emit()

func _on_restart_pressed() -> void:
	_play_click()
	hide()
	retry_requested.emit()

func _create_action_btn(text: String, bg_col: Color, min_height: int) -> Button:
	var btn = Button.new()
	btn.text = text
	btn.custom_minimum_size = Vector2(240, min_height)
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

	btn.add_theme_font_size_override("font_size", 14)
	btn.add_theme_color_override("font_color", Color("#FFFFFF"))
	return btn

func _play_click() -> void:
	if SoundManager.instance:
		SoundManager.instance.play_click()
