class_name LevelCompleteScreen
extends Control

## Screen 5: Level Completed Dialog (Exact match to Reference Screenshot).
## Features:
## - 660px wide rounded card on 720px viewport (narrow horizontal margins matching SS)
## - 3 Cute puffy 3D golden stars with white halo sitting above the ribbon
## - Arched curved orange ribbon banner: "Level Completed!" overlapping card top
## - No top-right close button (clean modal look matching SS)
## - Heading: "Great Job!" (size 34) & Subtitle: "You cleared the path." (size 20)
## - Reward pill container: [ Puffy Star +2  |  Blue Gift Box ]
## - Vibrant orange pill CTA button: "Next Level" (height 76px, size 26)
## - Soft warm cream pill button: "Home" (height 68px, size 24)

signal next_level_requested
signal replay_requested
signal home_requested

var card_panel: PanelContainer
var stars_container: Control
var star_controls: Array[Control] = []
var lbl_banner: Label
var lbl_praise: Label
var lbl_subpraise: Label
var lbl_reward_coins: Label
var btn_next: Button
var btn_home: Button

func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	z_index = 60
	_build_ui()
	hide()

func display_completion(level_id: int, moves: int, hearts: int) -> void:
	if lbl_banner:
		lbl_banner.text = "Level Completed!"
	if lbl_praise:
		lbl_praise.text = "Great Job!"
	if lbl_subpraise:
		lbl_subpraise.text = "You cleared the path."
	if lbl_reward_coins:
		lbl_reward_coins.text = "+2"

	# Update star visuals based on remaining hearts
	for i in range(star_controls.size()):
		var s = star_controls[i]
		if s:
			s.modulate = Color(1.0, 1.0, 1.0, 1.0) if (i < hearts) else Color(0.45, 0.45, 0.45, 0.35)

	show()
	_animate_in()

func _animate_in() -> void:
	if card_panel:
		card_panel.scale = Vector2(0.85, 0.85)
		card_panel.modulate.a = 0.0
		var tw = create_tween().set_parallel(true).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		tw.tween_property(card_panel, "scale", Vector2.ONE, 0.32)
		tw.tween_property(card_panel, "modulate:a", 1.0, 0.22)

	if stars_container:
		stars_container.scale = Vector2(0.3, 0.3)
		var s_tw = create_tween().set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
		s_tw.tween_property(stars_container, "scale", Vector2.ONE, 0.55).set_delay(0.08)

func _build_ui() -> void:
	# 1. Dark dimmed backdrop
	var backdrop = ColorRect.new()
	backdrop.set_anchors_preset(Control.PRESET_FULL_RECT)
	backdrop.color = Color(0.12, 0.09, 0.07, 0.60)
	backdrop.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(backdrop)

	# 2. Main centered wrapper
	var center = CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(center)

	# Card container with minimal horizontal margin (660px on 720px viewport -> 30px side margins)
	var card_wrapper = Control.new()
	card_wrapper.custom_minimum_size = Vector2(660, 690)
	center.add_child(card_wrapper)

	# The white/cream rounded card panel
	card_panel = PanelContainer.new()
	card_panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	card_panel.offset_top = 96.0 # Spacing for overlapping ribbon banner & stars
	card_panel.pivot_offset = Vector2(330, 345)

	var sb = StyleBoxFlat.new()
	sb.bg_color = Color("#FFFDF7")
	sb.border_width_left = 2
	sb.border_width_top = 2
	sb.border_width_right = 2
	sb.border_width_bottom = 2
	sb.border_color = Color("#F3E6D4")
	sb.set_corner_radius_all(38)
	sb.shadow_size = 28
	sb.shadow_color = Color(0, 0, 0, 0.20)
	sb.shadow_offset = Vector2(0, 10)
	card_panel.add_theme_stylebox_override("panel", sb)
	card_wrapper.add_child(card_panel)

	# Inside content margin
	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 32)
	margin.add_theme_constant_override("margin_right", 32)
	margin.add_theme_constant_override("margin_top", 68) # Space below ribbon banner
	margin.add_theme_constant_override("margin_bottom", 32)
	card_panel.add_child(margin)

	var vbox = VBoxContainer.new()
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_theme_constant_override("separation", 18)
	margin.add_child(vbox)

	# --- 3. Heading & Subtitle ("Great Job!" & "You cleared the path.") ---
	var text_vbox = VBoxContainer.new()
	text_vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	text_vbox.add_theme_constant_override("separation", 6)
	vbox.add_child(text_vbox)

	lbl_praise = Label.new()
	lbl_praise.text = "Great Job!"
	lbl_praise.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl_praise.add_theme_font_size_override("font_size", 34)
	lbl_praise.add_theme_color_override("font_color", Color("#2D1A10"))
	text_vbox.add_child(lbl_praise)

	lbl_subpraise = Label.new()
	lbl_subpraise.text = "You cleared the path."
	lbl_subpraise.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl_subpraise.add_theme_font_size_override("font_size", 20)
	lbl_subpraise.add_theme_color_override("font_color", Color("#58453A"))
	text_vbox.add_child(lbl_subpraise)

	# --- 4. Reward Box / Pill: [ ⭐ +2  |  🎁 ] ---
	var reward_panel = PanelContainer.new()
	reward_panel.custom_minimum_size = Vector2(580, 74)
	var rew_sb = StyleBoxFlat.new()
	rew_sb.bg_color = Color("#F8F0E5")
	rew_sb.border_width_left = 1
	rew_sb.border_width_top = 1
	rew_sb.border_width_right = 1
	rew_sb.border_width_bottom = 1
	rew_sb.border_color = Color("#EFE2D2")
	rew_sb.set_corner_radius_all(26)
	reward_panel.add_theme_stylebox_override("panel", rew_sb)
	vbox.add_child(reward_panel)

	var rew_hbox = HBoxContainer.new()
	rew_hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	rew_hbox.add_theme_constant_override("separation", 24)
	reward_panel.add_child(rew_hbox)

	# Reward left: cute puffy star + "+2"
	var star_tex = load("res://assets/icons/puffy_star.png") as Texture2D
	if star_tex:
		var rew_star_rect = TextureRect.new()
		rew_star_rect.texture = star_tex
		rew_star_rect.custom_minimum_size = Vector2(38, 38)
		rew_star_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		rew_star_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		rew_hbox.add_child(rew_star_rect)

	lbl_reward_coins = Label.new()
	lbl_reward_coins.text = "+2"
	lbl_reward_coins.add_theme_font_size_override("font_size", 32)
	lbl_reward_coins.add_theme_color_override("font_color", Color("#2D1A10"))
	rew_hbox.add_child(lbl_reward_coins)

	# Thin vertical divider line
	var v_div = Control.new()
	v_div.custom_minimum_size = Vector2(2, 36)
	v_div.draw.connect(func():
		v_div.draw_line(Vector2(1, 0), Vector2(1, 36), Color("#DECFC0"), 2.0)
	)
	rew_hbox.add_child(v_div)

	# Reward right: cute blue gift box with red ribbon
	var gift_tex = load("res://assets/icons/blue_gift_box.png") as Texture2D
	if gift_tex:
		var rew_gift_rect = TextureRect.new()
		rew_gift_rect.texture = gift_tex
		rew_gift_rect.custom_minimum_size = Vector2(48, 48)
		rew_gift_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		rew_gift_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		rew_hbox.add_child(rew_gift_rect)

	# Spacer
	var spacer = Control.new()
	spacer.custom_minimum_size = Vector2(0, 4)
	vbox.add_child(spacer)

	# --- 5. Primary Big CTA: "Next Level" ---
	btn_next = Button.new()
	btn_next.text = "Next Level"
	btn_next.custom_minimum_size = Vector2(580, 76)
	btn_next.focus_mode = Control.FOCUS_NONE

	var next_sb = StyleBoxFlat.new()
	next_sb.bg_color = Color("#F5781E")
	next_sb.set_corner_radius_all(32)
	next_sb.shadow_size = 14
	next_sb.shadow_color = Color(0.88, 0.44, 0.12, 0.36)
	next_sb.shadow_offset = Vector2(0, 6)
	btn_next.add_theme_stylebox_override("normal", next_sb)

	var next_h = next_sb.duplicate() as StyleBoxFlat
	next_h.bg_color = Color("#FA8732")
	btn_next.add_theme_stylebox_override("hover", next_h)

	var next_p = next_sb.duplicate() as StyleBoxFlat
	next_p.bg_color = Color("#D86410")
	btn_next.add_theme_stylebox_override("pressed", next_p)

	btn_next.add_theme_font_size_override("font_size", 26)
	btn_next.add_theme_color_override("font_color", Color.WHITE)
	btn_next.pressed.connect(func():
		_play_click()
		hide()
		next_level_requested.emit()
	)
	vbox.add_child(btn_next)

	# --- 6. Secondary Big Button: "Home" ---
	btn_home = Button.new()
	btn_home.text = "Home"
	btn_home.custom_minimum_size = Vector2(580, 68)
	btn_home.focus_mode = Control.FOCUS_NONE

	var home_sb = StyleBoxFlat.new()
	home_sb.bg_color = Color("#FFF9F2")
	home_sb.border_width_left = 1
	home_sb.border_width_top = 1
	home_sb.border_width_right = 1
	home_sb.border_width_bottom = 1
	home_sb.border_color = Color("#E8DCD0")
	home_sb.set_corner_radius_all(28)
	btn_home.add_theme_stylebox_override("normal", home_sb)

	var home_h = home_sb.duplicate() as StyleBoxFlat
	home_h.bg_color = Color("#FFFDF8")
	btn_home.add_theme_stylebox_override("hover", home_h)

	var home_p = home_sb.duplicate() as StyleBoxFlat
	home_p.bg_color = Color("#F4E8DC")
	btn_home.add_theme_stylebox_override("pressed", home_p)

	btn_home.add_theme_font_size_override("font_size", 24)
	btn_home.add_theme_color_override("font_color", Color("#3E271E"))
	btn_home.pressed.connect(func():
		_play_click()
		hide()
		home_requested.emit()
	)
	vbox.add_child(btn_home)

	# =========================================================================
	# 7. FLOATING TOP HEADER: 3 Puffy Stars + Arched Orange Ribbon Banner
	# =========================================================================
	var top_header = Control.new()
	top_header.set_anchors_preset(Control.PRESET_TOP_WIDE)
	top_header.custom_minimum_size = Vector2(660, 180)
	top_header.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card_wrapper.add_child(top_header)

	# A. Arched Curved Orange Ribbon Banner: "Level Completed!"
	var ribbon_tex = load("res://assets/icons/orange_ribbon.png") as Texture2D
	var ribbon_wrapper = Control.new()
	ribbon_wrapper.position = Vector2((660 - 580) * 0.5, 46)
	ribbon_wrapper.custom_minimum_size = Vector2(580, 138)
	ribbon_wrapper.mouse_filter = Control.MOUSE_FILTER_IGNORE
	top_header.add_child(ribbon_wrapper)

	if ribbon_tex:
		var ribbon_rect = TextureRect.new()
		ribbon_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
		ribbon_rect.texture = ribbon_tex
		ribbon_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		ribbon_rect.stretch_mode = TextureRect.STRETCH_SCALE
		ribbon_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
		ribbon_wrapper.add_child(ribbon_rect)

	lbl_banner = Label.new()
	lbl_banner.text = "Level Completed!"
	lbl_banner.set_anchors_preset(Control.PRESET_FULL_RECT)
	lbl_banner.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl_banner.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	lbl_banner.offset_top = 18
	lbl_banner.offset_bottom = -24
	lbl_banner.add_theme_font_size_override("font_size", 30)
	lbl_banner.add_theme_color_override("font_color", Color.WHITE)
	lbl_banner.add_theme_color_override("font_shadow_color", Color(0.55, 0.18, 0.04, 0.75))
	lbl_banner.add_theme_constant_override("shadow_offset_y", 2)
	ribbon_wrapper.add_child(lbl_banner)

	# B. 3 Puffy 3D Golden Stars Floating Above Ribbon
	stars_container = Control.new()
	stars_container.custom_minimum_size = Vector2(380, 110)
	stars_container.position = Vector2((660 - 380) * 0.5, 0)
	stars_container.pivot_offset = Vector2(190, 55)
	top_header.add_child(stars_container)

	star_controls.clear()
	# Star configs matching reference image:
	# Left: tilted left (-14°), Middle: largest & highest, Right: tilted right (+14°)
	var star_configs = [
		{"pos": Vector2(62, 34), "size": Vector2(96, 96), "rot": -0.24},
		{"pos": Vector2(190, 6), "size": Vector2(120, 120), "rot": 0.0},
		{"pos": Vector2(318, 34), "size": Vector2(96, 96), "rot": 0.24}
	]

	for cfg in star_configs:
		var s_ctrl = _create_star_control(cfg["size"], star_tex)
		s_ctrl.position = cfg["pos"] - s_ctrl.pivot_offset
		s_ctrl.rotation = cfg["rot"]
		stars_container.add_child(s_ctrl)
		star_controls.append(s_ctrl)

func _create_star_control(star_size: Vector2, tex: Texture2D) -> Control:
	var ctrl = Control.new()
	ctrl.custom_minimum_size = star_size
	ctrl.pivot_offset = star_size * 0.5
	ctrl.mouse_filter = Control.MOUSE_FILTER_IGNORE

	if tex:
		var tr = TextureRect.new()
		tr.set_anchors_preset(Control.PRESET_FULL_RECT)
		tr.texture = tex
		tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		tr.mouse_filter = Control.MOUSE_FILTER_IGNORE
		ctrl.add_child(tr)

	return ctrl

func _play_click() -> void:
	if SoundManager.instance:
		SoundManager.instance.play_click()
