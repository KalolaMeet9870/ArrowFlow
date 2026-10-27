class_name PausePopup
extends PanelContainer

## Pause modal with Resume, Restart, Sound toggle, and Return to Home.

signal resumed
signal restarted
signal sound_toggled(enabled: bool)
signal home_requested

var btn_resume: Button
var btn_restart: Button
var btn_sound: Button
var btn_home: Button

func _ready() -> void:
	visible = false
	pivot_offset = Vector2(165, 140)
	_build_ui()

func _build_ui() -> void:
	custom_minimum_size = Vector2(330, 280)

	var sb = StyleBoxFlat.new()
	sb.bg_color = Color("#FFFDF9")
	sb.border_width_left = 2
	sb.border_width_top = 2
	sb.border_width_right = 2
	sb.border_width_bottom = 2
	sb.border_color = Color("#D9B86C")
	sb.corner_radius_top_left = 24
	sb.corner_radius_top_right = 24
	sb.corner_radius_bottom_left = 24
	sb.corner_radius_bottom_right = 24
	sb.shadow_size = 24
	sb.shadow_color = Color(0, 0, 0, 0.16)
	sb.content_margin_left = 28
	sb.content_margin_right = 28
	sb.content_margin_top = 28
	sb.content_margin_bottom = 28
	add_theme_stylebox_override("panel", sb)

	var vbox = VBoxContainer.new()
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_theme_constant_override("separation", 14)
	add_child(vbox)

	var title = Label.new()
	title.text = "GAME PAUSED"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 26)
	title.add_theme_color_override("font_color", Color("#B37B24"))
	vbox.add_child(title)

	btn_resume = _create_menu_button("RESUME", Color("#B37B24"))
	btn_resume.pressed.connect(func():
		hide_popup()
		resumed.emit()
	)
	vbox.add_child(btn_resume)

	btn_restart = _create_menu_button("RESTART LEVEL", Color("#8D6E63"))
	btn_restart.pressed.connect(func():
		hide_popup()
		restarted.emit()
	)
	vbox.add_child(btn_restart)

	btn_sound = _create_menu_button("SOUND: ON", Color("#5D4037"))
	btn_sound.pressed.connect(func():
		if SoundManager.instance:
			var muted = SoundManager.instance.toggle_mute()
			btn_sound.text = "SOUND: OFF" if muted else "SOUND: ON"
			sound_toggled.emit(not muted)
	)
	vbox.add_child(btn_sound)

	btn_home = _create_menu_button("MAIN MENU", Color("#795548"))
	btn_home.pressed.connect(func():
		hide_popup()
		home_requested.emit()
	)
	vbox.add_child(btn_home)

func _create_menu_button(label_text: String, bg_color: Color) -> Button:
	var btn = Button.new()
	btn.text = label_text
	btn.custom_minimum_size = Vector2(280, 56)
	btn.focus_mode = Control.FOCUS_NONE

	var normal_sb = StyleBoxFlat.new()
	normal_sb.bg_color = bg_color
	normal_sb.corner_radius_top_left = 16
	normal_sb.corner_radius_top_right = 16
	normal_sb.corner_radius_bottom_left = 16
	normal_sb.corner_radius_bottom_right = 16
	btn.add_theme_stylebox_override("normal", normal_sb)

	var hover_sb = normal_sb.duplicate() as StyleBoxFlat
	hover_sb.bg_color = bg_color.lightened(0.12)
	btn.add_theme_stylebox_override("hover", hover_sb)

	btn.add_theme_font_size_override("font_size", 18)
	return btn

func show_popup() -> void:
	if SoundManager.instance:
		btn_sound.text = "SOUND: OFF" if SoundManager.instance.is_muted else "SOUND: ON"
	visible = true
	scale = Vector2(0.7, 0.7)
	var tw = create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(self, "scale", Vector2.ONE, 0.25)

func hide_popup() -> void:
	visible = false
