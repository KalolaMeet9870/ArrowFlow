class_name UIOverlay
extends CanvasLayer

## UI Overlay for ArrowFlow
## Modern, polished mobile-first HUD with progress pill, level selector,
## sound toggle, animated victory modal, and star rating.

signal restart_requested
signal next_level_requested
signal prev_level_requested
signal sound_toggled

# Top HUD
var level_label: Label
var theme_label: Label
var progress_bar: ProgressBar
var progress_label: Label
var btn_restart: Button
var btn_sound: Button
var btn_prev: Button
var btn_next: Button

# Hint
var hint_label: Label

# Win Modal
var win_modal: PanelContainer
var win_stars_container: HBoxContainer
var win_stars: Array[Label] = []
var btn_win_next: Button
var is_win_showing: bool = false

var current_theme: Dictionary = {}

func _ready() -> void:
	_create_ui_tree()

	var lm = LevelManager.instance
	if lm:
		lm.level_loaded.connect(_on_level_loaded)
		lm.tile_painted.connect(_on_tile_painted)
		lm.level_completed.connect(_on_level_completed)

func _create_ui_tree() -> void:
	# Root Control filling screen
	var root_control = Control.new()
	root_control.name = "RootControl"
	root_control.set_anchors_preset(Control.PRESET_FULL_RECT)
	root_control.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root_control)

	# --- TOP HUD CONTAINER ---
	var top_margin = MarginContainer.new()
	top_margin.name = "TopMargin"
	top_margin.set_anchors_preset(Control.PRESET_TOP_WIDE)
	top_margin.add_theme_constant_override("margin_left", 24)
	top_margin.add_theme_constant_override("margin_top", 32)
	top_margin.add_theme_constant_override("margin_right", 24)
	top_margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root_control.add_child(top_margin)

	var top_vbox = VBoxContainer.new()
	top_vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	top_vbox.add_theme_constant_override("separation", 12)
	top_margin.add_child(top_vbox)

	# Row 1: Header (Prev, Level Title, Sound, Restart, Next)
	var header_hbox = HBoxContainer.new()
	header_hbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	header_hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	header_hbox.add_theme_constant_override("separation", 10)
	top_vbox.add_child(header_hbox)

	btn_prev = _create_icon_button("◀", "Previous level")
	btn_prev.pressed.connect(func():
		_play_click()
		prev_level_requested.emit()
	)
	header_hbox.add_child(btn_prev)

	var title_vbox = VBoxContainer.new()
	title_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title_vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	title_vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	header_hbox.add_child(title_vbox)

	level_label = Label.new()
	level_label.text = "LEVEL 1"
	level_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	level_label.add_theme_font_size_override("font_size", 26)
	level_label.add_theme_color_override("font_color", Color(1, 1, 1, 0.95))
	title_vbox.add_child(level_label)

	theme_label = Label.new()
	theme_label.text = "Coral Sunset"
	theme_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	theme_label.add_theme_font_size_override("font_size", 13)
	theme_label.add_theme_color_override("font_color", Color(1, 1, 1, 0.6))
	title_vbox.add_child(theme_label)

	btn_restart = _create_icon_button("↺", "Restart level")
	btn_restart.pressed.connect(func():
		_play_click()
		restart_requested.emit()
	)
	header_hbox.add_child(btn_restart)

	btn_sound = _create_icon_button("🔊", "Toggle sound")
	btn_sound.pressed.connect(func():
		_play_click()
		sound_toggled.emit()
		_update_sound_button()
	)
	header_hbox.add_child(btn_sound)

	btn_next = _create_icon_button("▶", "Next level")
	btn_next.pressed.connect(func():
		_play_click()
		next_level_requested.emit()
	)
	header_hbox.add_child(btn_next)

	# Row 2: Sleek Progress Bar
	var progress_panel = PanelContainer.new()
	progress_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var p_style = StyleBoxFlat.new()
	p_style.bg_color = Color(0.1, 0.12, 0.18, 0.8)
	p_style.corner_radius_top_left = 14
	p_style.corner_radius_top_right = 14
	p_style.corner_radius_bottom_left = 14
	p_style.corner_radius_bottom_right = 14
	p_style.content_margin_left = 12
	p_style.content_margin_right = 12
	p_style.content_margin_top = 6
	p_style.content_margin_bottom = 6
	progress_panel.add_theme_stylebox_override("panel", p_style)
	top_vbox.add_child(progress_panel)

	var prog_vbox = VBoxContainer.new()
	prog_vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	progress_panel.add_child(prog_vbox)

	progress_bar = ProgressBar.new()
	progress_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	progress_bar.custom_minimum_size = Vector2(0, 16)
	progress_bar.show_percentage = false
	progress_bar.min_value = 0.0
	progress_bar.max_value = 100.0
	progress_bar.value = 0.0

	var bg_bar_style = StyleBoxFlat.new()
	bg_bar_style.bg_color = Color(0.18, 0.22, 0.32, 0.6)
	bg_bar_style.corner_radius_top_left = 8
	bg_bar_style.corner_radius_top_right = 8
	bg_bar_style.corner_radius_bottom_left = 8
	bg_bar_style.corner_radius_bottom_right = 8
	progress_bar.add_theme_stylebox_override("background", bg_bar_style)

	var fill_bar_style = StyleBoxFlat.new()
	fill_bar_style.bg_color = Color(1.0, 0.38, 0.16)
	fill_bar_style.corner_radius_top_left = 8
	fill_bar_style.corner_radius_top_right = 8
	fill_bar_style.corner_radius_bottom_left = 8
	fill_bar_style.corner_radius_bottom_right = 8
	progress_bar.add_theme_stylebox_override("fill", fill_bar_style)
	prog_vbox.add_child(progress_bar)

	progress_label = Label.new()
	progress_label.text = "0% PAINTED"
	progress_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	progress_label.add_theme_font_size_override("font_size", 12)
	progress_label.add_theme_color_override("font_color", Color(1, 1, 1, 0.85))
	prog_vbox.add_child(progress_label)

	# --- BOTTOM HINT ---
	var bottom_center = CenterContainer.new()
	bottom_center.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	bottom_center.position = Vector2(0, -90)
	bottom_center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root_control.add_child(bottom_center)

	var hint_panel = PanelContainer.new()
	hint_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var h_style = StyleBoxFlat.new()
	h_style.bg_color = Color(0.1, 0.13, 0.20, 0.88)
	h_style.border_width_left = 1
	h_style.border_width_top = 1
	h_style.border_width_right = 1
	h_style.border_width_bottom = 1
	h_style.border_color = Color(1, 1, 1, 0.12)
	h_style.corner_radius_top_left = 20
	h_style.corner_radius_top_right = 20
	h_style.corner_radius_bottom_left = 20
	h_style.corner_radius_bottom_right = 20
	h_style.content_margin_left = 20
	h_style.content_margin_right = 20
	h_style.content_margin_top = 10
	h_style.content_margin_bottom = 10
	hint_panel.add_theme_stylebox_override("panel", h_style)
	bottom_center.add_child(hint_panel)

	hint_label = Label.new()
	hint_label.text = "Swipe or use Arrow / WASD keys to roll!"
	hint_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint_label.add_theme_font_size_override("font_size", 14)
	hint_label.add_theme_color_override("font_color", Color(1, 1, 1, 0.85))
	hint_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hint_panel.add_child(hint_label)

	# Breathing animation
	var pulse_tw = create_tween().set_loops().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	pulse_tw.tween_property(hint_panel, "modulate:a", 0.65, 1.2)
	pulse_tw.tween_property(hint_panel, "modulate:a", 1.0, 1.2)

	# --- VICTORY WIN MODAL ---
	_create_win_modal(root_control)

func _create_icon_button(icon_text: String, tooltip: String) -> Button:
	var btn = Button.new()
	btn.text = icon_text
	btn.tooltip_text = tooltip
	btn.custom_minimum_size = Vector2(44, 44)
	btn.focus_mode = Control.FOCUS_NONE

	var normal_sb = StyleBoxFlat.new()
	normal_sb.bg_color = Color(0.12, 0.16, 0.24, 0.85)
	normal_sb.corner_radius_top_left = 12
	normal_sb.corner_radius_top_right = 12
	normal_sb.corner_radius_bottom_left = 12
	normal_sb.corner_radius_bottom_right = 12
	btn.add_theme_stylebox_override("normal", normal_sb)

	var hover_sb = normal_sb.duplicate() as StyleBoxFlat
	hover_sb.bg_color = Color(0.20, 0.26, 0.38, 0.95)
	btn.add_theme_stylebox_override("hover", hover_sb)

	var pressed_sb = normal_sb.duplicate() as StyleBoxFlat
	pressed_sb.bg_color = Color(0.08, 0.10, 0.16, 0.95)
	btn.add_theme_stylebox_override("pressed", pressed_sb)

	btn.add_theme_font_size_override("font_size", 18)
	return btn

func _create_win_modal(parent: Control) -> void:
	var center_wrapper = CenterContainer.new()
	center_wrapper.set_anchors_preset(Control.PRESET_FULL_RECT)
	center_wrapper.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(center_wrapper)

	win_modal = PanelContainer.new()
	win_modal.name = "WinModal"
	win_modal.pivot_offset = Vector2(170, 150)
	win_modal.custom_minimum_size = Vector2(340, 300)
	win_modal.visible = false
	center_wrapper.add_child(win_modal)

	var modal_sb = StyleBoxFlat.new()
	modal_sb.bg_color = Color(0.08, 0.10, 0.16, 0.96)
	modal_sb.border_width_left = 2
	modal_sb.border_width_top = 2
	modal_sb.border_width_right = 2
	modal_sb.border_width_bottom = 2
	modal_sb.border_color = Color(1.0, 0.8, 0.2, 0.4)
	modal_sb.corner_radius_top_left = 24
	modal_sb.corner_radius_top_right = 24
	modal_sb.corner_radius_bottom_left = 24
	modal_sb.corner_radius_bottom_right = 24
	modal_sb.shadow_size = 28
	modal_sb.shadow_color = Color(0, 0, 0, 0.6)
	modal_sb.content_margin_left = 28
	modal_sb.content_margin_right = 28
	modal_sb.content_margin_top = 32
	modal_sb.content_margin_bottom = 32
	win_modal.add_theme_stylebox_override("panel", modal_sb)

	var modal_vbox = VBoxContainer.new()
	modal_vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	modal_vbox.add_theme_constant_override("separation", 18)
	win_modal.add_child(modal_vbox)

	# Stars Row
	win_stars_container = HBoxContainer.new()
	win_stars_container.alignment = BoxContainer.ALIGNMENT_CENTER
	win_stars_container.add_theme_constant_override("separation", 14)
	modal_vbox.add_child(win_stars_container)

	win_stars.clear()
	for i in range(3):
		var star = Label.new()
		star.text = "★"
		star.add_theme_font_size_override("font_size", 42)
		star.add_theme_color_override("font_color", Color(1.0, 0.85, 0.1))
		star.pivot_offset = Vector2(21, 21)
		win_stars_container.add_child(star)
		win_stars.append(star)

	var victory_title = Label.new()
	victory_title.text = "AMAZING!"
	victory_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	victory_title.add_theme_font_size_override("font_size", 28)
	victory_title.add_theme_color_override("font_color", Color(1, 1, 1, 1.0))
	modal_vbox.add_child(victory_title)

	var victory_subtitle = Label.new()
	victory_subtitle.text = "100% Maze Painted!"
	victory_subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	victory_subtitle.add_theme_font_size_override("font_size", 15)
	victory_subtitle.add_theme_color_override("font_color", Color(1, 1, 1, 0.75))
	modal_vbox.add_child(victory_subtitle)

	# Next Level Button
	btn_win_next = Button.new()
	btn_win_next.text = "NEXT LEVEL ▶"
	btn_win_next.custom_minimum_size = Vector2(220, 52)
	btn_win_next.focus_mode = Control.FOCUS_NONE

	var next_sb = StyleBoxFlat.new()
	next_sb.bg_color = Color(1.0, 0.38, 0.16)
	next_sb.corner_radius_top_left = 18
	next_sb.corner_radius_top_right = 18
	next_sb.corner_radius_bottom_left = 18
	next_sb.corner_radius_bottom_right = 18
	btn_win_next.add_theme_stylebox_override("normal", next_sb)

	var next_hover_sb = next_sb.duplicate() as StyleBoxFlat
	next_hover_sb.bg_color = next_sb.bg_color.lightened(0.12)
	btn_win_next.add_theme_stylebox_override("hover", next_hover_sb)

	btn_win_next.add_theme_font_size_override("font_size", 18)
	btn_win_next.pressed.connect(func():
		_play_click()
		_hide_win_modal()
		next_level_requested.emit()
	)
	modal_vbox.add_child(btn_win_next)

func _play_click() -> void:
	if SoundManager.instance:
		SoundManager.instance.play_click()

func _update_sound_button() -> void:
	if SoundManager.instance:
		btn_sound.text = "🔇" if SoundManager.instance.is_muted else "🔊"

func _on_level_loaded(level_index: int, total_levels: int, theme: Dictionary) -> void:
	current_theme = theme
	is_win_showing = false
	win_modal.visible = false

	level_label.text = "LEVEL %d / %d" % [level_index + 1, total_levels]
	theme_label.text = theme.get("name", "Maze")

	# Update fill bar color
	var fill_style = progress_bar.get_theme_stylebox("fill") as StyleBoxFlat
	if fill_style:
		fill_style.bg_color = theme.get("paint", Color(1.0, 0.38, 0.16))

	# Update win next button color
	var next_sb = btn_win_next.get_theme_stylebox("normal") as StyleBoxFlat
	if next_sb:
		next_sb.bg_color = theme.get("paint", Color(1.0, 0.38, 0.16))
		var hover_sb = btn_win_next.get_theme_stylebox("hover") as StyleBoxFlat
		if hover_sb:
			hover_sb.bg_color = next_sb.bg_color.lightened(0.12)

	var lm = LevelManager.instance
	if lm:
		_update_progress(lm.painted_count, lm.total_paintable, lm.get_progress_percentage())
	else:
		_update_progress(0, 1, 0.0)

func _on_tile_painted(_pos: Vector2i, painted_count: int, total_tiles: int, pct: float) -> void:
	_update_progress(painted_count, total_tiles, pct)

	# Fade hint if painted more than 2 tiles
	if painted_count > 2 and hint_label.modulate.a > 0.0:
		var tw = create_tween()
		tw.tween_property(hint_label, "modulate:a", 0.0, 0.6)

func _update_progress(painted: int, total: int, pct: float) -> void:
	var tween = create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(progress_bar, "value", pct, 0.15)
	progress_label.text = "%d / %d (%d%% PAINTED)" % [painted, total, int(pct)]

func _on_level_completed(_level_index: int) -> void:
	if is_win_showing:
		return
	is_win_showing = true

	if SoundManager.instance:
		SoundManager.instance.play_win()

	# Show modal with spring animation
	win_modal.visible = true
	win_modal.scale = Vector2(0.6, 0.6)
	win_modal.modulate.a = 0.0

	var tw = create_tween().set_parallel(true)
	tw.tween_property(win_modal, "scale", Vector2.ONE, 0.35).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(win_modal, "modulate:a", 1.0, 0.25)

	# Staggered star animation
	for i in range(win_stars.size()):
		var star = win_stars[i]
		star.scale = Vector2.ZERO
		var s_tw = create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		s_tw.tween_interval(0.2 + float(i) * 0.15)
		s_tw.tween_property(star, "scale", Vector2.ONE, 0.25)

func _hide_win_modal() -> void:
	if not is_win_showing:
		return
	is_win_showing = false
	var tw = create_tween().set_parallel(true)
	tw.tween_property(win_modal, "scale", Vector2(0.6, 0.6), 0.2).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tw.tween_property(win_modal, "modulate:a", 0.0, 0.2)
	tw.chain().tween_callback(func(): win_modal.visible = false)
