class_name GameScreen
extends Control

## Main Gameplay Screen for ArrowFlow ("Clear The Path").
## Features:
## - Full Safe Area support respecting top status bar, notches, Dynamic Island, and home indicator.
## - Top Header: Circular Back button ←, Level title, subtitle "Clear all arrows from the grid", Theme 🎨, Settings ⚙.
## - Life droplets (💧 💧 💧) centered cleanly below header.
## - Centered square puzzle grid with warm beige paper and subtle dotted grid.
## - Bottom Bar matching design mockup:
##   * Circular "Restart" button with ↺
##   * Circular "Hint" button with 💡 and orange count badge ("3" / "AD")
##   * Circular "Undo" button with ↶ to step back moves
## - Precise, non-overlapping touch dispatching for accurate arrow selection.
## - Pause popup and guidance interaction.

signal home_requested
signal level_completed(level_id: int, moves: int, hearts: int)
signal level_failed(level_id: int)
signal level_select_requested
signal settings_requested
signal theme_selection_requested

const SafeAreaHelper = preload("res://scripts/safe_area_helper.gd")

@export var max_hearts: int = 3

var current_hearts: int = 3
var current_moves: int = 0
var current_combo: int = 0
var current_level_data: Dictionary = {}

var bg_rect: ColorRect
var safe_margin_container: MarginContainer
var board: GameBoard
var board_holder: Control
var heart_display: HeartDisplay
var pause_popup: PausePopup

var lbl_level_title: Label
var lbl_subtitle: Label
var btn_hint: Button
var btn_restart: Button
var btn_undo: Button
var btn_theme: Button
var btn_settings: Button
var hint_badge_lbl: Label

var current_theme: Dictionary = {}

func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	if ThemeManager.instance:
		current_theme = ThemeManager.instance.get_current_theme()
		ThemeManager.instance.theme_changed.connect(apply_theme)
	_build_ui()
	apply_theme(current_theme)

	resized.connect(_on_viewport_resized)
	if get_tree() and get_tree().root:
		get_tree().root.size_changed.connect(_on_viewport_resized)

func _on_viewport_resized() -> void:
	_update_safe_areas()

func _update_safe_areas() -> void:
	if safe_margin_container:
		SafeAreaHelper.apply_safe_area_margins(safe_margin_container, get_viewport())

func start_level(level_data: Dictionary) -> void:
	current_level_data = level_data
	current_moves = 0
	current_combo = 0
	current_hearts = max_hearts

	var lvl_id = int(level_data.get("id", 1))

	if lbl_level_title:
		lbl_level_title.text = "Level %d" % lvl_id
		lbl_level_title.add_theme_font_size_override("font_size", 26)
		lbl_level_title.add_theme_color_override("font_color", Color("#4A3525"))

	if lbl_subtitle:
		lbl_subtitle.visible = false

	if heart_display:
		heart_display.update_hearts(current_hearts, max_hearts)

	# Determine board display area size safely (full screen height)
	var board_size = Vector2(680, 960)
	if board_holder and board_holder.size.x > 50 and board_holder.size.y > 50:
		board_size = board_holder.size
	elif size.x > 50 and size.y > 50:
		var insets = SafeAreaHelper.get_safe_insets(get_viewport())
		board_size = Vector2(size.x - insets["left"] - insets["right"], size.y - insets["top"] - insets["bottom"] - 100.0)

	if board:
		board.setup_level(level_data, board_size)
		if not current_theme.is_empty():
			board.apply_theme(current_theme)

func apply_theme(theme: Dictionary) -> void:
	current_theme = theme
	if bg_rect:
		bg_rect.color = theme.get("bg", Color("#FAF4E8"))
	if lbl_level_title:
		lbl_level_title.add_theme_color_override("font_color", theme.get("arrow_line", Color("#3A2E26")))

	if board:
		board.apply_theme(theme)

func _build_ui() -> void:
	# 1. Warm cream zen background
	bg_rect = ColorRect.new()
	bg_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg_rect.color = Color("#FAF4E8")
	bg_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg_rect)

	# Safe area container to prevent system indicator and home bar overlaps
	safe_margin_container = MarginContainer.new()
	safe_margin_container.set_anchors_preset(Control.PRESET_FULL_RECT)
	safe_margin_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(safe_margin_container)
	_update_safe_areas()

	var main_vbox = VBoxContainer.new()
	main_vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	main_vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	safe_margin_container.add_child(main_vbox)

	# ========================================================
	# A. TOP HEADER BAR (←, Level X + Subtitle, 🎨, ⚙)
	# ========================================================
	var top_margin = MarginContainer.new()
	top_margin.add_theme_constant_override("margin_left", 16)
	top_margin.add_theme_constant_override("margin_right", 16)
	top_margin.add_theme_constant_override("margin_top", 6)
	top_margin.add_theme_constant_override("margin_bottom", 2)
	top_margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	main_vbox.add_child(top_margin)

	var header_bar = HBoxContainer.new()
	header_bar.alignment = BoxContainer.ALIGNMENT_CENTER
	header_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	header_bar.add_theme_constant_override("separation", 10)
	top_margin.add_child(header_bar)

	# 1. Back button ← (Circular card)
	var btn_back = _create_circle_btn("←", 30, 56.0)
	btn_back.pressed.connect(func():
		_play_click()
		home_requested.emit()
	)
	header_bar.add_child(btn_back)

	# Center: Level Title (e.g. "Level 97") + Subtitle ("Super Hard")
	var title_box = VBoxContainer.new()
	title_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title_box.alignment = BoxContainer.ALIGNMENT_CENTER
	title_box.add_theme_constant_override("separation", 1)
	title_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	header_bar.add_child(title_box)

	lbl_level_title = Label.new()
	lbl_level_title.text = "Level 1"
	lbl_level_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl_level_title.add_theme_font_size_override("font_size", 32)
	lbl_level_title.add_theme_color_override("font_color", Color("#4A3525"))
	title_box.add_child(lbl_level_title)

	lbl_subtitle = Label.new()
	lbl_subtitle.text = "Clear all arrows from the grid"
	lbl_subtitle.visible = false
	title_box.add_child(lbl_subtitle)

	# 2. Theme switch button 🎨
	btn_theme = _create_circle_btn("🎨", 26, 56.0)
	btn_theme.tooltip_text = "Switch Color Theme"
	btn_theme.pressed.connect(func():
		_play_click()
		theme_selection_requested.emit()
	)
	header_bar.add_child(btn_theme)

	# 3. Settings gear button ⚙
	btn_settings = _create_circle_btn("⚙", 28, 56.0)
	btn_settings.tooltip_text = "Settings"
	btn_settings.pressed.connect(func():
		_play_click()
		settings_requested.emit()
	)
	header_bar.add_child(btn_settings)

	# ========================================================
	# B. SUBHEADER ROW (💧 💧 💧 on Left, 💡 AD on Right)
	# ========================================================
	var subheader_margin = MarginContainer.new()
	subheader_margin.add_theme_constant_override("margin_left", 20)
	subheader_margin.add_theme_constant_override("margin_right", 20)
	subheader_margin.add_theme_constant_override("margin_top", 4)
	subheader_margin.add_theme_constant_override("margin_bottom", 4)
	subheader_margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	main_vbox.add_child(subheader_margin)

	var subheader_hbox = HBoxContainer.new()
	subheader_hbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	subheader_margin.add_child(subheader_hbox)

	heart_display = HeartDisplay.new()
	subheader_hbox.add_child(heart_display)

	var sub_spacer = Control.new()
	sub_spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sub_spacer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	subheader_hbox.add_child(sub_spacer)

	# Top right Hint Button with AD badge matching Image 5
	var hint_wrapper = _create_top_hint_button()
	btn_hint = hint_wrapper["button"]
	hint_badge_lbl = hint_wrapper["badge_label"]
	subheader_hbox.add_child(hint_wrapper["container"])

	# ========================================================
	# C. GAME BOARD AREA (Full Screen, expanding to safe area)
	# ========================================================
	board_holder = Control.new()
	board_holder.size_flags_vertical = Control.SIZE_EXPAND_FILL
	board_holder.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	board_holder.mouse_filter = Control.MOUSE_FILTER_STOP

	# Touch, Pinch Zoom & Guidance dispatcher:
	board_holder.gui_input.connect(func(event: InputEvent):
		if not board or not is_instance_valid(board):
			return
		if event is InputEventScreenTouch:
			var st = event as InputEventScreenTouch
			if st.pressed:
				board.handle_holder_touch_down(st.position, st.index)
			else:
				board.handle_holder_touch_up(st.position, st.index)
		elif event is InputEventScreenDrag:
			var sd = event as InputEventScreenDrag
			board.handle_holder_touch_move(sd.position, sd.index)
		elif event is InputEventMouseButton:
			var mb = event as InputEventMouseButton
			if mb.button_index == MOUSE_BUTTON_WHEEL_UP and mb.pressed:
				board.zoom_in(1.15, mb.position)
			elif mb.button_index == MOUSE_BUTTON_WHEEL_DOWN and mb.pressed:
				board.zoom_out(1.15, mb.position)
			elif mb.button_index == MOUSE_BUTTON_LEFT:
				if mb.pressed:
					board.handle_holder_touch_down(mb.position, -1)
				else:
					board.handle_holder_touch_up(mb.position, -1)
		elif event is InputEventMouseMotion:
			var mm = event as InputEventMouseMotion
			if mm.button_mask & MOUSE_BUTTON_MASK_LEFT:
				board.handle_holder_touch_move(mm.position, -1)
	)

	board_holder.resized.connect(func():
		if board and is_instance_valid(board) and board_holder.size.x > 50 and board_holder.size.y > 50:
			board.update_board_size(board_holder.size)
	)

	main_vbox.add_child(board_holder)

	board = GameBoard.new()
	board.board_area_size = Vector2(680, 960)
	board.move_succeeded.connect(_on_move_succeeded)
	board.move_failed.connect(_on_move_failed)
	board.board_cleared.connect(_on_board_cleared)
	board_holder.add_child(board)

	# Floating Zoom Action Dock: [ − ] [ 100% ⟲ ] [ + ]
	var zoom_margin = MarginContainer.new()
	zoom_margin.name = "ZoomMargin"
	zoom_margin.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	zoom_margin.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	zoom_margin.grow_vertical = Control.GROW_DIRECTION_BEGIN
	zoom_margin.offset_right = -16.0
	zoom_margin.offset_bottom = -72.0 # Elevated safely above bottom navigation/ad banner
	zoom_margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	board_holder.add_child(zoom_margin)

	var zoom_dock = PanelContainer.new()
	zoom_dock.name = "ZoomDock"
	var dock_sb = StyleBoxFlat.new()
	dock_sb.bg_color = Color(0.99, 0.98, 0.96, 0.95)
	dock_sb.border_width_left = 1
	dock_sb.border_width_top = 1
	dock_sb.border_width_right = 1
	dock_sb.border_width_bottom = 1
	dock_sb.border_color = Color("#DFCBB5")
	dock_sb.set_corner_radius_all(27)
	dock_sb.shadow_size = 10
	dock_sb.shadow_color = Color(0, 0, 0, 0.16)
	dock_sb.shadow_offset = Vector2(0, 4)
	zoom_dock.add_theme_stylebox_override("panel", dock_sb)
	zoom_margin.add_child(zoom_dock)

	var zoom_hbox = HBoxContainer.new()
	zoom_hbox.add_theme_constant_override("separation", 6)
	zoom_dock.add_child(zoom_hbox)

	# 1. Zoom Out Button [ − ]
	var btn_zoom_out = Button.new()
	btn_zoom_out.text = "−"
	btn_zoom_out.custom_minimum_size = Vector2(54, 54)
	btn_zoom_out.focus_mode = Control.FOCUS_NONE
	btn_zoom_out.flat = true
	btn_zoom_out.add_theme_font_size_override("font_size", 30)
	btn_zoom_out.add_theme_color_override("font_color", Color("#5A4A3E"))
	btn_zoom_out.pressed.connect(func():
		_play_click()
		if board:
			board.zoom_out(1.25)
	)
	zoom_hbox.add_child(btn_zoom_out)

	# 2. Reset Zoom Pill [ 100% / ⟲ ]
	var btn_zoom_reset = Button.new()
	btn_zoom_reset.text = "100%"
	btn_zoom_reset.custom_minimum_size = Vector2(84, 54)
	btn_zoom_reset.focus_mode = Control.FOCUS_NONE
	btn_zoom_reset.flat = true
	btn_zoom_reset.add_theme_font_size_override("font_size", 16)
	btn_zoom_reset.add_theme_color_override("font_color", Color("#8D6E63"))
	btn_zoom_reset.pressed.connect(func():
		_play_click()
		if board:
			board.smooth_reset_zoom()
	)
	zoom_hbox.add_child(btn_zoom_reset)

	# 3. Zoom In Button [ + ]
	var btn_zoom_in = Button.new()
	btn_zoom_in.text = "+"
	btn_zoom_in.custom_minimum_size = Vector2(54, 54)
	btn_zoom_in.focus_mode = Control.FOCUS_NONE
	btn_zoom_in.flat = true
	btn_zoom_in.add_theme_font_size_override("font_size", 28)
	btn_zoom_in.add_theme_color_override("font_color", Color("#5A4A3E"))
	btn_zoom_in.pressed.connect(func():
		_play_click()
		if board:
			board.zoom_in(1.25)
	)
	zoom_hbox.add_child(btn_zoom_in)

	board.zoom_changed.connect(func(z_val: float):
		var pct = int(round(z_val * 100.0))
		btn_zoom_out.modulate.a = 0.45 if z_val <= 1.02 else 1.0
		btn_zoom_in.modulate.a = 0.45 if z_val >= 2.75 else 1.0
		if pct > 105:
			btn_zoom_reset.text = "%d%% ⟲" % pct
			btn_zoom_reset.add_theme_color_override("font_color", Color("#B57538"))
		else:
			btn_zoom_reset.text = "100%"
			btn_zoom_reset.add_theme_color_override("font_color", Color("#8D6E63"))
	)

	# Hidden action helpers for tests and modal control (keeps board full-screen)
	var hidden_controls = Control.new()
	hidden_controls.visible = false
	add_child(hidden_controls)

	btn_restart = Button.new()
	btn_restart.text = "Restart"
	btn_restart.pressed.connect(func():
		_play_click()
		restart_level()
	)
	hidden_controls.add_child(btn_restart)

	btn_undo = Button.new()
	btn_undo.text = "Undo"
	btn_undo.pressed.connect(func():
		_on_undo_pressed()
	)
	hidden_controls.add_child(btn_undo)

	# Pause Popup instantiation
	var modal_center = CenterContainer.new()
	modal_center.set_anchors_preset(Control.PRESET_FULL_RECT)
	modal_center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(modal_center)

	pause_popup = PausePopup.new()
	pause_popup.resumed.connect(func(): pass)
	pause_popup.restarted.connect(func(): restart_level())
	pause_popup.home_requested.connect(func(): home_requested.emit())
	modal_center.add_child(pause_popup)

func _on_undo_pressed() -> void:
	_play_click()
	if board and board.undo_move():
		if current_moves > 0:
			current_moves -= 1
		# Gentle bounce animation on Undo button
		if btn_undo:
			var tw = create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
			tw.tween_property(btn_undo, "scale", Vector2(1.15, 1.15), 0.08)
			tw.tween_property(btn_undo, "scale", Vector2.ONE, 0.12)

func _on_move_succeeded(_arrow: Arrow) -> void:
	current_moves += 1
	current_combo += 1
	if SoundManager.instance:
		SoundManager.instance.play_pentatonic_combo(current_combo)

func _on_move_failed(_arrow: Arrow) -> void:
	current_combo = 0
	current_hearts -= 1
	if heart_display:
		heart_display.update_hearts(current_hearts, max_hearts)

	if current_hearts <= 0:
		if board:
			board.is_input_locked = true
		level_failed.emit(int(current_level_data.get("id", 1)))

func _on_board_cleared() -> void:
	var lvl_id = int(current_level_data.get("id", 1))
	level_completed.emit(lvl_id, current_moves, current_hearts)

func _on_hint_pressed() -> void:
	if board:
		var hint_arr = board.show_hint()
		if hint_arr and btn_hint:
			var tw = create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
			tw.tween_property(btn_hint, "scale", Vector2(1.18, 1.18), 0.1)
			tw.tween_property(btn_hint, "scale", Vector2.ONE, 0.15)

func restart_level() -> void:
	start_level(current_level_data)

func _create_circle_btn(text: String, font_size: int, btn_size: float = 44.0) -> Button:
	var btn = Button.new()
	btn.text = text
	btn.custom_minimum_size = Vector2(btn_size, btn_size)
	btn.focus_mode = Control.FOCUS_NONE
	btn.add_theme_font_size_override("font_size", font_size)
	btn.add_theme_color_override("font_color", Color("#4A3525"))
	btn.add_theme_color_override("font_pressed_color", Color("#C8782E"))

	var norm_sb = StyleBoxFlat.new()
	norm_sb.bg_color = Color(0, 0, 0, 0) # Clean transparent background matching Reference Image 3

	var press_sb = StyleBoxFlat.new()
	press_sb.bg_color = Color(0.8, 0.75, 0.68, 0.22)
	press_sb.set_corner_radius_all(int(btn_size * 0.5))

	btn.add_theme_stylebox_override("normal", norm_sb)
	btn.add_theme_stylebox_override("hover", norm_sb)
	btn.add_theme_stylebox_override("pressed", press_sb)
	return btn

func _create_bottom_action_card(icon_text: String, label_text: String, badge_text: String = "") -> Dictionary:
	var vbox = VBoxContainer.new()
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_theme_constant_override("separation", 6)
	vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var wrapper = Control.new()
	wrapper.custom_minimum_size = Vector2(56, 56)
	vbox.add_child(wrapper)

	var btn = Button.new()
	btn.set_anchors_preset(Control.PRESET_FULL_RECT)
	btn.text = icon_text
	btn.pivot_offset = Vector2(28, 28)
	btn.focus_mode = Control.FOCUS_NONE
	btn.add_theme_font_size_override("font_size", 24)
	btn.add_theme_color_override("font_color", Color("#3A2E26"))
	btn.add_theme_color_override("font_pressed_color", Color("#F28C28"))

	var norm_sb = StyleBoxFlat.new()
	norm_sb.bg_color = Color("#F5EBD7")
	norm_sb.border_color = Color("#EADCC6")
	norm_sb.set_border_width_all(1)
	norm_sb.set_corner_radius_all(28)

	var press_sb = StyleBoxFlat.new()
	press_sb.bg_color = Color("#EADCC6")
	press_sb.border_color = Color("#DFCFB7")
	press_sb.set_border_width_all(1)
	press_sb.set_corner_radius_all(28)

	btn.add_theme_stylebox_override("normal", norm_sb)
	btn.add_theme_stylebox_override("hover", norm_sb)
	btn.add_theme_stylebox_override("pressed", press_sb)
	wrapper.add_child(btn)

	var badge_panel: PanelContainer = null
	var badge_lbl: Label = null
	if not badge_text.is_empty():
		badge_panel = PanelContainer.new()
		badge_panel.position = Vector2(36, -2)
		badge_panel.custom_minimum_size = Vector2(20, 20)
		badge_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var b_sb = StyleBoxFlat.new()
		b_sb.bg_color = Color("#F28C28")
		b_sb.set_corner_radius_all(10)
		badge_panel.add_theme_stylebox_override("panel", b_sb)
		wrapper.add_child(badge_panel)

		badge_lbl = Label.new()
		badge_lbl.text = badge_text
		badge_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		badge_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		badge_lbl.add_theme_font_size_override("font_size", 11)
		badge_lbl.add_theme_color_override("font_color", Color.WHITE)
		badge_panel.add_child(badge_lbl)

	var lbl = Label.new()
	lbl.text = label_text
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.add_theme_font_size_override("font_size", 13)
	lbl.add_theme_color_override("font_color", Color("#7A6A5E"))
	vbox.add_child(lbl)

	return {
		"container": vbox,
		"button": btn,
		"badge": badge_panel,
		"badge_label": badge_lbl,
		"label": lbl
	}

func _create_top_hint_button() -> Dictionary:
	var wrapper = Control.new()
	wrapper.custom_minimum_size = Vector2(68, 56)

	var btn = Button.new()
	btn.set_anchors_preset(Control.PRESET_FULL_RECT)
	btn.text = "💡"
	btn.focus_mode = Control.FOCUS_NONE
	btn.add_theme_font_size_override("font_size", 30)
	btn.add_theme_color_override("font_color", Color("#54483F"))

	var norm_sb = StyleBoxFlat.new()
	norm_sb.bg_color = Color(0, 0, 0, 0)
	btn.add_theme_stylebox_override("normal", norm_sb)
	btn.add_theme_stylebox_override("hover", norm_sb)
	btn.add_theme_stylebox_override("pressed", norm_sb)
	wrapper.add_child(btn)

	# AD Badge pill attached to top right corner of the bulb matching Image 5
	var badge_panel = PanelContainer.new()
	badge_panel.position = Vector2(34, 2)
	badge_panel.custom_minimum_size = Vector2(30, 20)
	badge_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var b_sb = StyleBoxFlat.new()
	b_sb.bg_color = Color("#E68A2E")
	b_sb.set_corner_radius_all(10)
	badge_panel.add_theme_stylebox_override("panel", b_sb)
	wrapper.add_child(badge_panel)

	var badge_lbl = Label.new()
	badge_lbl.text = "3"
	badge_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	badge_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	badge_lbl.add_theme_font_size_override("font_size", 12)
	badge_lbl.add_theme_color_override("font_color", Color.WHITE)
	badge_panel.add_child(badge_lbl)

	btn.pressed.connect(func():
		_play_click()
		_on_hint_pressed()
	)

	return {
		"container": wrapper,
		"button": btn,
		"badge": badge_panel,
		"badge_label": badge_lbl
	}

func _create_icon_btn(text: String, font_size: int) -> Button:
	return _create_circle_btn(text, font_size, 44.0)

func _play_click() -> void:
	if SoundManager.instance:
		SoundManager.instance.play_click()
