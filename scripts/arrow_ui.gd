class_name ArrowUI
extends CanvasLayer

## UI Controller for Arrow Maze Escape ("Tap to Clear").
## Accurately implements the Eye Comfort aesthetic, top header, water drops,
## circular grid/hint buttons, kraft paper bottom banner, and 50-level selector.

@export var game: ArrowGame

# Visual containers & elements
var bg_rect: ColorRect
var top_container: VBoxContainer
var level_title_label: Label
var level_subtitle_label: Label
var drops_container: HBoxContainer
var drop_labels: Array[Label] = []

# Action buttons
var btn_back: Button
var btn_theme: Button
var btn_settings: Button
var btn_grid: Button
var btn_hint: Button

# Bottom banner
var bottom_banner_panel: PanelContainer
var bottom_banner_label: Label

# Modals
var win_modal: PanelContainer
var win_title: Label
var win_subtitle: Label
var btn_win_next: Button

var fail_modal: PanelContainer
var btn_fail_retry: Button
var btn_fail_refill: Button

var level_select_modal: PanelContainer
var levels_grid_container: GridContainer
var current_filter_tab: String = "Simple"

var current_theme: Dictionary = {}

func _ready() -> void:
	_create_ui()

	if game:
		game.level_started.connect(_on_level_started)
		game.drops_updated.connect(_on_drops_updated)
		game.arrow_cleared.connect(_on_arrow_cleared)
		game.level_completed.connect(_on_level_completed)
		game.game_over.connect(_on_game_over)
		game.theme_changed.connect(_on_theme_changed)

func _create_ui() -> void:
	# Root full rect
	var root = Control.new()
	root.name = "Root"
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root)

	# Background Color
	bg_rect = ColorRect.new()
	bg_rect.name = "Background"
	bg_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg_rect.color = Color("#FAF4E8")
	bg_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(bg_rect)

	# Main Vertical Layout
	var main_vbox = VBoxContainer.new()
	main_vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	main_vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(main_vbox)

	# --- TOP HEADER ---
	_create_top_header(main_vbox)

	# --- DROPS CONTAINER ---
	_create_drops_bar(main_vbox)

	# --- CENTER SPACER / CANVAS HOLDER ---
	var canvas_holder = MarginContainer.new()
	canvas_holder.size_flags_vertical = Control.SIZE_EXPAND_FILL
	canvas_holder.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	canvas_holder.add_theme_constant_override("margin_left", 36)
	canvas_holder.add_theme_constant_override("margin_right", 36)
	canvas_holder.add_theme_constant_override("margin_top", 12)
	canvas_holder.add_theme_constant_override("margin_bottom", 12)
	canvas_holder.mouse_filter = Control.MOUSE_FILTER_IGNORE
	main_vbox.add_child(canvas_holder)

	# If game has canvas or needs one
	if game:
		if game.canvas == null:
			var ac = ArrowCanvas.new()
			ac.name = "ArrowCanvas"
			ac.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			ac.size_flags_vertical = Control.SIZE_EXPAND_FILL
			canvas_holder.add_child(ac)
			game.canvas = ac
			ac.path_clicked.connect(game._on_path_clicked)
		elif game.canvas.get_parent() != canvas_holder:
			if game.canvas.get_parent():
				game.canvas.get_parent().remove_child(game.canvas)
			game.canvas.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			game.canvas.size_flags_vertical = Control.SIZE_EXPAND_FILL
			canvas_holder.add_child(game.canvas)

	# --- FLOATING ACTION BUTTONS (Grid & Hint) ---
	_create_floating_action_buttons(main_vbox)

	# --- BOTTOM PAPER BANNER ---
	_create_bottom_banner(main_vbox)

	# --- MODALS ---
	_create_modals(root)

func _create_top_header(parent: VBoxContainer) -> void:
	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 20)
	margin.add_theme_constant_override("margin_right", 20)
	margin.add_theme_constant_override("margin_top", 18)
	margin.add_theme_constant_override("margin_bottom", 6)
	margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(margin)

	var hbox = HBoxContainer.new()
	hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	hbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	margin.add_child(hbox)

	# Back button
	btn_back = _create_text_button("←", 24)
	btn_back.tooltip_text = "Select Level"
	btn_back.pressed.connect(func():
		_play_click()
		_show_level_select_modal()
	)
	hbox.add_child(btn_back)

	# Center Title & Subtitle
	var title_box = VBoxContainer.new()
	title_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title_box.alignment = BoxContainer.ALIGNMENT_CENTER
	title_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hbox.add_child(title_box)

	level_title_label = Label.new()
	level_title_label.text = "Level 10"
	level_title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	level_title_label.add_theme_font_size_override("font_size", 24)
	level_title_label.add_theme_color_override("font_color", Color("#B37B24"))
	title_box.add_child(level_title_label)

	level_subtitle_label = Label.new()
	level_subtitle_label.text = "Trophy Cup"
	level_subtitle_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	level_subtitle_label.add_theme_font_size_override("font_size", 12)
	level_subtitle_label.add_theme_color_override("font_color", Color("#8D6E63"))
	title_box.add_child(level_subtitle_label)

	# Right Buttons: Palette & Settings
	btn_theme = _create_text_button("🎨", 20)
	btn_theme.tooltip_text = "Toggle Theme"
	btn_theme.pressed.connect(func():
		_play_click()
		if game:
			game.toggle_theme()
	)
	hbox.add_child(btn_theme)

	btn_settings = _create_text_button("⚙", 20)
	btn_settings.tooltip_text = "Toggle Audio"
	btn_settings.pressed.connect(func():
		_play_click()
		if SoundManager.instance:
			var muted = SoundManager.instance.toggle_mute()
			btn_settings.modulate.a = 0.5 if muted else 1.0
	)
	hbox.add_child(btn_settings)

func _create_drops_bar(parent: VBoxContainer) -> void:
	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 28)
	margin.add_theme_constant_override("margin_bottom", 4)
	margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(margin)

	drops_container = HBoxContainer.new()
	drops_container.add_theme_constant_override("separation", 10)
	drops_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	margin.add_child(drops_container)

	drop_labels.clear()
	for i in range(5):
		var drop = Label.new()
		drop.text = "💧"
		drop.add_theme_font_size_override("font_size", 26)
		drop.add_theme_color_override("font_color", Color("#29B6F6"))
		drops_container.add_child(drop)
		drop_labels.append(drop)

func _create_floating_action_buttons(parent: VBoxContainer) -> void:
	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_bottom", 16)
	margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(margin)

	var hbox = HBoxContainer.new()
	hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	hbox.add_theme_constant_override("separation", 36)
	hbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	margin.add_child(hbox)

	# Left: Grid button
	btn_grid = _create_circular_button()
	btn_grid.tooltip_text = "Level List"
	var grid_drawer = Control.new()
	grid_drawer.set_anchors_preset(Control.PRESET_FULL_RECT)
	grid_drawer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	grid_drawer.draw.connect(func():
		var col = current_theme.get("btn_icon", Color("#5D4037"))
		var r = Rect2(17, 17, 28, 28)
		grid_drawer.draw_rect(r, col, false, 2.2)
		grid_drawer.draw_line(Vector2(r.position.x + 9.3, r.position.y), Vector2(r.position.x + 9.3, r.end.y), col, 2.0)
		grid_drawer.draw_line(Vector2(r.position.x + 18.6, r.position.y), Vector2(r.position.x + 18.6, r.end.y), col, 2.0)
		grid_drawer.draw_line(Vector2(r.position.x, r.position.y + 9.3), Vector2(r.end.x, r.position.y + 9.3), col, 2.0)
		grid_drawer.draw_line(Vector2(r.position.x, r.position.y + 18.6), Vector2(r.end.x, r.position.y + 18.6), col, 2.0)
	)
	btn_grid.add_child(grid_drawer)
	btn_grid.pressed.connect(func():
		_play_click()
		_show_level_select_modal()
	)
	hbox.add_child(btn_grid)

	# Right: Hint button
	btn_hint = _create_circular_button()
	btn_hint.tooltip_text = "Hint"
	var bulb_drawer = Control.new()
	bulb_drawer.set_anchors_preset(Control.PRESET_FULL_RECT)
	bulb_drawer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bulb_drawer.draw.connect(func():
		var col = current_theme.get("btn_icon", Color("#5D4037"))
		bulb_drawer.draw_arc(Vector2(31, 24), 10.0, 0.45, PI - 0.45, 24, col, 2.2)
		bulb_drawer.draw_line(Vector2(24, 32), Vector2(26, 38), col, 2.2)
		bulb_drawer.draw_line(Vector2(38, 32), Vector2(36, 38), col, 2.2)
		bulb_drawer.draw_line(Vector2(26, 38), Vector2(36, 38), col, 2.2)
		bulb_drawer.draw_line(Vector2(27, 41), Vector2(35, 41), col, 2.0)
		var w_pts = PackedVector2Array([
			Vector2(26, 25), Vector2(28.5, 29.5), Vector2(31, 26), Vector2(33.5, 29.5), Vector2(36, 25)
		])
		bulb_drawer.draw_polyline(w_pts, col, 1.8)
	)
	btn_hint.add_child(bulb_drawer)
	btn_hint.pressed.connect(func():
		_play_click()
		if game:
			var success = game.request_hint()
			if success:
				var tw = create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
				tw.tween_property(btn_hint, "scale", Vector2(1.2, 1.2), 0.1)
				tw.tween_property(btn_hint, "scale", Vector2.ONE, 0.15)
	)
	hbox.add_child(btn_hint)

func _create_bottom_banner(parent: VBoxContainer) -> void:
	bottom_banner_panel = PanelContainer.new()
	bottom_banner_panel.custom_minimum_size = Vector2(0, 72)
	bottom_banner_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var b_style = StyleBoxFlat.new()
	b_style.bg_color = Color("#D8C3A5")
	b_style.border_width_top = 2
	b_style.border_color = Color("#B89F7D")
	b_style.corner_radius_top_left = 6
	b_style.corner_radius_top_right = 6
	bottom_banner_panel.add_theme_stylebox_override("panel", b_style)
	parent.add_child(bottom_banner_panel)

	var center = CenterContainer.new()
	bottom_banner_panel.add_child(center)

	bottom_banner_label = Label.new()
	bottom_banner_label.text = "EYE COMFORT"
	bottom_banner_label.add_theme_font_size_override("font_size", 28)
	bottom_banner_label.add_theme_color_override("font_color", Color("#5D4037"))
	center.add_child(bottom_banner_label)

func _create_circular_button() -> Button:
	var btn = Button.new()
	btn.custom_minimum_size = Vector2(62, 62)
	btn.pivot_offset = Vector2(31, 31)
	btn.focus_mode = Control.FOCUS_NONE

	var normal_sb = StyleBoxFlat.new()
	normal_sb.bg_color = Color("#FFFFFF")
	normal_sb.border_width_left = 1
	normal_sb.border_width_top = 1
	normal_sb.border_width_right = 1
	normal_sb.border_width_bottom = 1
	normal_sb.border_color = Color("#E0D5C1")
	normal_sb.corner_radius_top_left = 31
	normal_sb.corner_radius_top_right = 31
	normal_sb.corner_radius_bottom_left = 31
	normal_sb.corner_radius_bottom_right = 31
	normal_sb.shadow_size = 6
	normal_sb.shadow_color = Color(0, 0, 0, 0.08)
	normal_sb.shadow_offset = Vector2(0, 3)
	btn.add_theme_stylebox_override("normal", normal_sb)

	var hover_sb = normal_sb.duplicate() as StyleBoxFlat
	hover_sb.bg_color = Color("#FBF8F2")
	btn.add_theme_stylebox_override("hover", hover_sb)

	var pressed_sb = normal_sb.duplicate() as StyleBoxFlat
	pressed_sb.bg_color = Color("#EDE3D2")
	btn.add_theme_stylebox_override("pressed", pressed_sb)

	return btn

func _create_text_button(icon_text: String, font_size: int) -> Button:
	var btn = Button.new()
	btn.text = icon_text
	btn.custom_minimum_size = Vector2(40, 40)
	btn.focus_mode = Control.FOCUS_NONE
	btn.add_theme_font_size_override("font_size", font_size)
	btn.add_theme_color_override("font_color", Color("#5D4037"))

	var empty_sb = StyleBoxEmpty.new()
	btn.add_theme_stylebox_override("normal", empty_sb)
	btn.add_theme_stylebox_override("hover", empty_sb)
	btn.add_theme_stylebox_override("pressed", empty_sb)
	return btn

func _create_modals(root: Control) -> void:
	# Wrapper CenterContainer
	var modal_center = CenterContainer.new()
	modal_center.set_anchors_preset(Control.PRESET_FULL_RECT)
	modal_center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(modal_center)

	# --- WIN MODAL ---
	win_modal = PanelContainer.new()
	win_modal.custom_minimum_size = Vector2(330, 280)
	win_modal.pivot_offset = Vector2(165, 140)
	win_modal.visible = false

	var win_sb = StyleBoxFlat.new()
	win_sb.bg_color = Color("#FFFDF9")
	win_sb.border_width_left = 2
	win_sb.border_width_top = 2
	win_sb.border_width_right = 2
	win_sb.border_width_bottom = 2
	win_sb.border_color = Color("#D9B86C")
	win_sb.corner_radius_top_left = 24
	win_sb.corner_radius_top_right = 24
	win_sb.corner_radius_bottom_left = 24
	win_sb.corner_radius_bottom_right = 24
	win_sb.shadow_size = 24
	win_sb.shadow_color = Color(0, 0, 0, 0.15)
	win_sb.content_margin_left = 28
	win_sb.content_margin_right = 28
	win_sb.content_margin_top = 28
	win_sb.content_margin_bottom = 28
	win_modal.add_theme_stylebox_override("panel", win_sb)
	modal_center.add_child(win_modal)

	var win_vbox = VBoxContainer.new()
	win_vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	win_vbox.add_theme_constant_override("separation", 16)
	win_modal.add_child(win_vbox)

	var stars = Label.new()
	stars.text = "★ ★ ★"
	stars.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	stars.add_theme_font_size_override("font_size", 34)
	stars.add_theme_color_override("font_color", Color("#FFB300"))
	win_vbox.add_child(stars)

	win_title = Label.new()
	win_title.text = "LEVEL CLEARED!"
	win_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	win_title.add_theme_font_size_override("font_size", 24)
	win_title.add_theme_color_override("font_color", Color("#4A3525"))
	win_vbox.add_child(win_title)

	win_subtitle = Label.new()
	win_subtitle.text = "All arrows escaped safely!"
	win_subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	win_subtitle.add_theme_font_size_override("font_size", 14)
	win_subtitle.add_theme_color_override("font_color", Color("#795548"))
	win_vbox.add_child(win_subtitle)

	btn_win_next = Button.new()
	btn_win_next.text = "NEXT LEVEL ▶"
	btn_win_next.custom_minimum_size = Vector2(200, 48)
	btn_win_next.focus_mode = Control.FOCUS_NONE

	var next_sb = StyleBoxFlat.new()
	next_sb.bg_color = Color("#B37B24")
	next_sb.corner_radius_top_left = 16
	next_sb.corner_radius_top_right = 16
	next_sb.corner_radius_bottom_left = 16
	next_sb.corner_radius_bottom_right = 16
	btn_win_next.add_theme_stylebox_override("normal", next_sb)

	var next_h_sb = next_sb.duplicate() as StyleBoxFlat
	next_h_sb.bg_color = Color("#C48A2C")
	btn_win_next.add_theme_stylebox_override("hover", next_h_sb)

	btn_win_next.add_theme_font_size_override("font_size", 16)
	btn_win_next.pressed.connect(func():
		_play_click()
		win_modal.visible = false
		if game:
			game.next_level()
	)
	win_vbox.add_child(btn_win_next)

	# --- FAIL / OUT OF DROPS MODAL ---
	fail_modal = PanelContainer.new()
	fail_modal.custom_minimum_size = Vector2(330, 260)
	fail_modal.pivot_offset = Vector2(165, 130)
	fail_modal.visible = false
	fail_modal.add_theme_stylebox_override("panel", win_sb)
	modal_center.add_child(fail_modal)

	var fail_vbox = VBoxContainer.new()
	fail_vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	fail_vbox.add_theme_constant_override("separation", 14)
	fail_modal.add_child(fail_vbox)

	var fail_icon = Label.new()
	fail_icon.text = "💧"
	fail_icon.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	fail_icon.add_theme_font_size_override("font_size", 38)
	fail_vbox.add_child(fail_icon)

	var fail_title = Label.new()
	fail_title.text = "OUT OF DROPS!"
	fail_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	fail_title.add_theme_font_size_override("font_size", 22)
	fail_title.add_theme_color_override("font_color", Color("#D32F2F"))
	fail_vbox.add_child(fail_title)

	var fail_sub = Label.new()
	fail_sub.text = "Watch out for blocked paths!"
	fail_sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	fail_sub.add_theme_font_size_override("font_size", 13)
	fail_sub.add_theme_color_override("font_color", Color("#795548"))
	fail_vbox.add_child(fail_sub)

	var fail_btns = HBoxContainer.new()
	fail_btns.alignment = BoxContainer.ALIGNMENT_CENTER
	fail_btns.add_theme_constant_override("separation", 12)
	fail_vbox.add_child(fail_btns)

	btn_fail_retry = Button.new()
	btn_fail_retry.text = "RETRY"
	btn_fail_retry.custom_minimum_size = Vector2(110, 44)
	btn_fail_retry.focus_mode = Control.FOCUS_NONE
	btn_fail_retry.add_theme_stylebox_override("normal", next_sb)
	btn_fail_retry.pressed.connect(func():
		_play_click()
		fail_modal.visible = false
		if game:
			game.restart_level()
	)
	fail_btns.add_child(btn_fail_retry)

	btn_fail_refill = Button.new()
	btn_fail_refill.text = "+3 DROPS"
	btn_fail_refill.custom_minimum_size = Vector2(110, 44)
	btn_fail_refill.focus_mode = Control.FOCUS_NONE
	var blue_sb = next_sb.duplicate() as StyleBoxFlat
	blue_sb.bg_color = Color("#0288D1")
	btn_fail_refill.add_theme_stylebox_override("normal", blue_sb)
	btn_fail_refill.pressed.connect(func():
		_play_click()
		fail_modal.visible = false
		if game:
			game.refill_drops()
	)
	fail_btns.add_child(btn_fail_refill)

	# --- LEVEL SELECTION MODAL ---
	_create_level_select_modal(modal_center)

func _create_level_select_modal(parent: Control) -> void:
	level_select_modal = PanelContainer.new()
	level_select_modal.custom_minimum_size = Vector2(360, 520)
	level_select_modal.visible = false

	var ls_sb = StyleBoxFlat.new()
	ls_sb.bg_color = Color("#FFFDF9")
	ls_sb.border_width_left = 2
	ls_sb.border_width_top = 2
	ls_sb.border_width_right = 2
	ls_sb.border_width_bottom = 2
	ls_sb.border_color = Color("#D9B86C")
	ls_sb.corner_radius_top_left = 24
	ls_sb.corner_radius_top_right = 24
	ls_sb.corner_radius_bottom_left = 24
	ls_sb.corner_radius_bottom_right = 24
	ls_sb.shadow_size = 28
	ls_sb.shadow_color = Color(0, 0, 0, 0.2)
	ls_sb.content_margin_left = 20
	ls_sb.content_margin_right = 20
	ls_sb.content_margin_top = 20
	ls_sb.content_margin_bottom = 20
	level_select_modal.add_theme_stylebox_override("panel", ls_sb)
	parent.add_child(level_select_modal)

	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 14)
	level_select_modal.add_child(vbox)

	# Header (Title + Close)
	var h_bar = HBoxContainer.new()
	vbox.add_child(h_bar)

	var ls_title = Label.new()
	ls_title.text = "SELECT LEVEL (50)"
	ls_title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	ls_title.add_theme_font_size_override("font_size", 20)
	ls_title.add_theme_color_override("font_color", Color("#B37B24"))
	h_bar.add_child(ls_title)

	var btn_close = _create_text_button("✕", 20)
	btn_close.pressed.connect(func():
		_play_click()
		level_select_modal.visible = false
	)
	h_bar.add_child(btn_close)

	# Difficulty Filter Tabs
	var tabs_hbox = HBoxContainer.new()
	tabs_hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	tabs_hbox.add_theme_constant_override("separation", 10)
	vbox.add_child(tabs_hbox)

	var tabs = ["Simple", "Medium", "Hard"]
	for tab_name in tabs:
		var tab_btn = Button.new()
		tab_btn.text = tab_name
		tab_btn.custom_minimum_size = Vector2(90, 32)
		tab_btn.focus_mode = Control.FOCUS_NONE

		var tab_sb = StyleBoxFlat.new()
		tab_sb.bg_color = Color("#EADBC8")
		tab_sb.corner_radius_top_left = 12
		tab_sb.corner_radius_top_right = 12
		tab_sb.corner_radius_bottom_left = 12
		tab_sb.corner_radius_bottom_right = 12
		tab_btn.add_theme_stylebox_override("normal", tab_sb)
		tab_btn.add_theme_color_override("font_color", Color("#4A3525"))
		tab_btn.add_theme_font_size_override("font_size", 13)

		var t_name = tab_name
		tab_btn.pressed.connect(func():
			_play_click()
			current_filter_tab = t_name
			_refresh_levels_grid()
		)
		tabs_hbox.add_child(tab_btn)

	# Scrollable Levels Grid
	var scroll = ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	vbox.add_child(scroll)

	levels_grid_container = GridContainer.new()
	levels_grid_container.columns = 5
	levels_grid_container.add_theme_constant_override("h_separation", 12)
	levels_grid_container.add_theme_constant_override("v_separation", 12)
	levels_grid_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(levels_grid_container)

func _show_level_select_modal() -> void:
	_refresh_levels_grid()
	level_select_modal.visible = true
	level_select_modal.scale = Vector2(0.8, 0.8)
	var tw = create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(level_select_modal, "scale", Vector2.ONE, 0.25)

func _refresh_levels_grid() -> void:
	for child in levels_grid_container.get_children():
		child.queue_free()

	if ArrowData.instance == null:
		return

	var all_levels = ArrowData.instance.levels
	for i in range(all_levels.size()):
		var lvl = all_levels[i]
		var diff = lvl.get("difficulty", "Simple")
		if diff != current_filter_tab:
			continue

		var lvl_id = int(lvl.get("id", i + 1))
		var is_done = ArrowData.instance.is_level_completed(lvl_id)
		var is_cur = (ArrowData.instance.current_level_idx == i)

		var btn = Button.new()
		btn.text = "%d" % lvl_id
		btn.tooltip_text = "%s (%s)" % [lvl.get("name", "Maze"), diff]
		btn.custom_minimum_size = Vector2(52, 52)
		btn.focus_mode = Control.FOCUS_NONE

		var btn_sb = StyleBoxFlat.new()
		if is_done:
			btn_sb.bg_color = Color("#D4EDDA") # Soft green
			btn_sb.border_color = Color("#28A745")
			btn.add_theme_color_override("font_color", Color("#155724"))
		elif is_cur:
			btn_sb.bg_color = Color("#FFF3CD") # Soft gold
			btn_sb.border_color = Color("#B37B24")
			btn.add_theme_color_override("font_color", Color("#B37B24"))
		else:
			btn_sb.bg_color = Color("#F8F9FA")
			btn_sb.border_color = Color("#E0D5C1")
			btn.add_theme_color_override("font_color", Color("#4A3525"))

		btn_sb.border_width_left = 2 if (is_done or is_cur) else 1
		btn_sb.border_width_top = 2 if (is_done or is_cur) else 1
		btn_sb.border_width_right = 2 if (is_done or is_cur) else 1
		btn_sb.border_width_bottom = 2 if (is_done or is_cur) else 1
		btn_sb.corner_radius_top_left = 14
		btn_sb.corner_radius_top_right = 14
		btn_sb.corner_radius_bottom_left = 14
		btn_sb.corner_radius_bottom_right = 14
		btn.add_theme_stylebox_override("normal", btn_sb)
		btn.add_theme_font_size_override("font_size", 16)

		var target_idx = i
		btn.pressed.connect(func():
			_play_click()
			level_select_modal.visible = false
			if game:
				game.load_level(target_idx)
		)
		levels_grid_container.add_child(btn)

func _play_click() -> void:
	if SoundManager.instance:
		SoundManager.instance.play_click()

func _on_level_started(level_idx: int, level_data: Dictionary, theme: Dictionary) -> void:
	current_theme = theme
	win_modal.visible = false
	fail_modal.visible = false

	var lvl_id = int(level_data.get("id", level_idx + 1))
	level_title_label.text = "Level %d" % lvl_id
	level_subtitle_label.text = level_data.get("name", "Maze")

	_apply_theme(theme)

func _on_drops_updated(current: int, maximum: int) -> void:
	# Show exactly maximum drops
	for i in range(drop_labels.size()):
		var label = drop_labels[i]
		if i < maximum:
			label.visible = true
			if i < current:
				label.text = "💧"
				label.modulate.a = 1.0
			else:
				label.text = "💧"
				label.modulate.a = 0.28 # Empty/spent
		else:
			label.visible = false

func _on_arrow_cleared(remaining: int, total: int) -> void:
	bottom_banner_label.text = "%d / %d REMAINING" % [remaining, total]

func _on_level_completed(_level_idx: int, level_data: Dictionary) -> void:
	bottom_banner_label.text = "TAP TO CLEAR"
	win_title.text = "LEVEL %d CLEARED!" % int(level_data.get("id", 1))
	win_subtitle.text = "%s completed!" % level_data.get("name", "Shape")

	win_modal.visible = true
	win_modal.scale = Vector2(0.7, 0.7)
	var tw = create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(win_modal, "scale", Vector2.ONE, 0.3)

func _on_game_over(_level_idx: int) -> void:
	fail_modal.visible = true
	fail_modal.scale = Vector2(0.7, 0.7)
	var tw = create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(fail_modal, "scale", Vector2.ONE, 0.3)

func _on_theme_changed(theme: Dictionary) -> void:
	current_theme = theme
	_apply_theme(theme)

func _apply_theme(theme: Dictionary) -> void:
	bg_rect.color = theme.get("bg", Color("#FAF4E8"))
	level_title_label.add_theme_color_override("font_color", theme.get("header", Color("#B37B24")))

	var p_style = bottom_banner_panel.get_theme_stylebox("panel") as StyleBoxFlat
	if p_style:
		p_style.bg_color = theme.get("banner_bg", Color("#D8C3A5"))
	bottom_banner_label.add_theme_color_override("font_color", theme.get("banner_text", Color("#5D4037")))
