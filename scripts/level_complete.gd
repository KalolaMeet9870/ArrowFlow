class_name LevelCompleteScreen
extends Control

## Exact 1:1 match to Reference Screenshot (Level Completed Modal):
## - Stars floating high above the ribbon, breaking out of the card top
## - Arched curved orange ribbon banner positioned gracefully below the stars
## - Warm velvety ivory cream rounded card (#FEFBEE) with rounded shoulders behind side stars
## - Prominent "Great Job!" (size 46, bold dark espresso #26140A) & "You cleared the path." (size 24)
## - Balanced space between ribbon arch and "Great Job!"
## - Warm golden-sand reward pill [ Puffy Star +2  |  Gift Box ] with balanced horizontal padding
## - Big vibrant orange pill CTA button: "Next Level" (height 90px, font size 36, radius 45px)
## - Soft warm cream pill button: "Home" (height 80px, font size 32, radius 40px)
## - Clean, tight bottom space below Home button (~48px)

signal next_level_requested
signal replay_requested
signal home_requested

var card_wrapper: Control
var card_panel: PanelContainer
var top_header: Control
var stars_container: Control
var star_controls: Array[Control] = []
var ribbon_wrapper: Control
var lbl_banner: Label
var lbl_praise: Label
var lbl_subpraise: Label
var lbl_reward_coins: Label
var btn_next: Button
var btn_home: Button

const CARD_WIDTH := 648.0
const CARD_HEIGHT := 800.0
const CARD_TOP := 75.0 # Card panel starts at 75px, letting stars break out proudly above

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

	# Light up stars according to remaining hearts
	for i in range(star_controls.size()):
		var star := star_controls[i]
		if is_instance_valid(star):
			star.modulate = Color.WHITE if i < hearts else Color(0.55, 0.48, 0.38, 0.38)

	show()
	_animate_in()

func _animate_in() -> void:
	if is_instance_valid(card_wrapper):
		card_wrapper.scale = Vector2(0.88, 0.88)
		card_wrapper.modulate.a = 0.0
		var tw := create_tween().set_parallel(true).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		tw.tween_property(card_wrapper, "scale", Vector2.ONE, 0.30)
		tw.tween_property(card_wrapper, "modulate:a", 1.0, 0.22)

	if is_instance_valid(stars_container):
		stars_container.scale = Vector2(0.40, 0.40)
		var s_tw := create_tween().set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
		s_tw.tween_property(stars_container, "scale", Vector2.ONE, 0.48).set_delay(0.08)

func _build_ui() -> void:
	var round_font: FontFile = null
	if ResourceLoader.exists("res://assets/fonts/round_bold.ttf"):
		round_font = load("res://assets/fonts/round_bold.ttf") as FontFile

	# 1. Warm dimmed backdrop matching reference
	var backdrop := ColorRect.new()
	backdrop.set_anchors_preset(Control.PRESET_FULL_RECT)
	backdrop.color = Color(0.18, 0.14, 0.10, 0.45)
	backdrop.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(backdrop)

	# 2. Main card wrapper positioned with upward vertical offset matching reference (stars high near water drops)
	card_wrapper = Control.new()
	card_wrapper.set_anchors_preset(Control.PRESET_CENTER)
	card_wrapper.custom_minimum_size = Vector2(CARD_WIDTH, CARD_HEIGHT)
	card_wrapper.size = Vector2(CARD_WIDTH, CARD_HEIGHT)
	card_wrapper.pivot_offset = Vector2(CARD_WIDTH * 0.5, CARD_HEIGHT * 0.5)
	card_wrapper.offset_left = -CARD_WIDTH * 0.5
	card_wrapper.offset_right = CARD_WIDTH * 0.5
	card_wrapper.offset_top = -CARD_HEIGHT * 0.5 - 20.0
	card_wrapper.offset_bottom = CARD_HEIGHT * 0.5 - 20.0
	card_wrapper.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(card_wrapper)

	# 3. Warm velvety ivory cream rounded card panel matching reference #FEFBEE
	card_panel = PanelContainer.new()
	card_panel.position = Vector2(0.0, CARD_TOP)
	card_panel.size = Vector2(CARD_WIDTH, CARD_HEIGHT - CARD_TOP)
	card_panel.mouse_filter = Control.MOUSE_FILTER_STOP

	var card_style := StyleBoxFlat.new()
	card_style.bg_color = Color("#FEFBEE") # Velvet ivory cream exactly from reference image
	card_style.border_width_left = 2
	card_style.border_width_top = 2
	card_style.border_width_right = 2
	card_style.border_width_bottom = 2
	card_style.border_color = Color("#EBDCC7")
	card_style.set_corner_radius_all(50)
	card_style.shadow_size = 32
	card_style.shadow_color = Color(0.12, 0.08, 0.04, 0.24)
	card_style.shadow_offset = Vector2(0, 12)
	card_panel.add_theme_stylebox_override("panel", card_style)
	card_wrapper.add_child(card_panel)

	# Card Content Container
	var margin := MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 48)
	margin.add_theme_constant_override("margin_right", 48)
	margin.add_theme_constant_override("margin_top", 216) # Clean spacing below arched ribbon
	margin.add_theme_constant_override("margin_bottom", 42) # Snug bottom space below Home button
	card_panel.add_child(margin)

	var content := VBoxContainer.new()
	content.alignment = BoxContainer.ALIGNMENT_BEGIN
	content.add_theme_constant_override("separation", 24)
	margin.add_child(content)

	# Heading & Subtitle ("Great Job!" & "You cleared the path.")
	var heading_box := VBoxContainer.new()
	heading_box.alignment = BoxContainer.ALIGNMENT_CENTER
	heading_box.add_theme_constant_override("separation", 6)
	content.add_child(heading_box)

	lbl_praise = Label.new()
	lbl_praise.text = "Great Job!"
	lbl_praise.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl_praise.add_theme_font_size_override("font_size", 52) # Prominent, big, bold
	lbl_praise.add_theme_color_override("font_color", Color("#26140A"))
	if round_font:
		lbl_praise.add_theme_font_override("font", round_font)
	heading_box.add_child(lbl_praise)

	lbl_subpraise = Label.new()
	lbl_subpraise.text = "You cleared the path."
	lbl_subpraise.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl_subpraise.add_theme_font_size_override("font_size", 26)
	lbl_subpraise.add_theme_color_override("font_color", Color("#5C4538"))
	if round_font:
		lbl_subpraise.add_theme_font_override("font", round_font)
	heading_box.add_child(lbl_subpraise)

	# Reward pill container: [ Puffy Star +2  |  Gift Box ]
	# Centered and sized to 450px width matching reference
	var reward_panel := PanelContainer.new()
	reward_panel.custom_minimum_size = Vector2(450, 98)
	reward_panel.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	var reward_style := StyleBoxFlat.new()
	reward_style.bg_color = Color("#FAF1E4") # Warm golden-sand pill matching reference #FAF1E4
	reward_style.border_width_left = 2
	reward_style.border_width_top = 2
	reward_style.border_width_right = 2
	reward_style.border_width_bottom = 2
	reward_style.border_color = Color("#E8D8C4")
	reward_style.set_corner_radius_all(49)
	reward_panel.add_theme_stylebox_override("panel", reward_style)
	content.add_child(reward_panel)

	var reward_margin := MarginContainer.new()
	reward_margin.add_theme_constant_override("margin_left", 42)
	reward_margin.add_theme_constant_override("margin_right", 42)
	reward_margin.add_theme_constant_override("margin_top", 12)
	reward_margin.add_theme_constant_override("margin_bottom", 12)
	reward_panel.add_child(reward_margin)

	var reward_row := HBoxContainer.new()
	reward_row.alignment = BoxContainer.ALIGNMENT_CENTER
	reward_row.add_theme_constant_override("separation", 24)
	reward_margin.add_child(reward_row)

	var star_tex := load("res://assets/icons/puffy_star.png") as Texture2D
	if star_tex:
		var reward_star := TextureRect.new()
		reward_star.texture = star_tex
		reward_star.custom_minimum_size = Vector2(52, 52)
		reward_star.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		reward_star.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		reward_row.add_child(reward_star)
	else:
		var reward_star_fallback := Label.new()
		reward_star_fallback.text = "⭐"
		reward_star_fallback.add_theme_font_size_override("font_size", 42)
		reward_row.add_child(reward_star_fallback)

	lbl_reward_coins = Label.new()
	lbl_reward_coins.text = "+2"
	lbl_reward_coins.add_theme_font_size_override("font_size", 44) # Big bold reward text
	lbl_reward_coins.add_theme_color_override("font_color", Color("#26140A"))
	if round_font:
		lbl_reward_coins.add_theme_font_override("font", round_font)
	reward_row.add_child(lbl_reward_coins)

	var divider := ColorRect.new()
	divider.custom_minimum_size = Vector2(2, 48)
	divider.color = Color("#E4D2BD")
	reward_row.add_child(divider)

	var gift_tex := load("res://assets/icons/blue_gift_box.png") as Texture2D
	if gift_tex:
		var gift_rect := TextureRect.new()
		gift_rect.texture = gift_tex
		gift_rect.custom_minimum_size = Vector2(62, 62)
		gift_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		gift_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		reward_row.add_child(gift_rect)
	else:
		var gift_fallback := Label.new()
		gift_fallback.text = "🎁"
		gift_fallback.add_theme_font_size_override("font_size", 42)
		reward_row.add_child(gift_fallback)

	# Primary CTA Button: "Next Level" (Vibrant Orange Pill)
	btn_next = Button.new()
	btn_next.text = "Next Level"
	btn_next.custom_minimum_size = Vector2(0, 100)
	btn_next.focus_mode = Control.FOCUS_NONE
	btn_next.add_theme_font_size_override("font_size", 40) # Big bold button text
	btn_next.add_theme_color_override("font_color", Color.WHITE)
	if round_font:
		btn_next.add_theme_font_override("font", round_font)

	var next_style := StyleBoxFlat.new()
	next_style.bg_color = Color("#F26A1B") # Rich warm orange matching reference
	next_style.set_corner_radius_all(50)
	next_style.shadow_size = 12
	next_style.shadow_color = Color(0.85, 0.38, 0.08, 0.35)
	next_style.shadow_offset = Vector2(0, 5)
	btn_next.add_theme_stylebox_override("normal", next_style)

	var next_hover := next_style.duplicate() as StyleBoxFlat
	next_hover.bg_color = Color("#FA7C2A")
	btn_next.add_theme_stylebox_override("hover", next_hover)

	var next_pressed := next_style.duplicate() as StyleBoxFlat
	next_pressed.bg_color = Color("#D6580E")
	btn_next.add_theme_stylebox_override("pressed", next_pressed)

	btn_next.pressed.connect(func() -> void:
		_play_click()
		hide()
		next_level_requested.emit()
	)
	content.add_child(btn_next)

	# Secondary CTA Button: "Home" (Soft Warm Cream Pill)
	btn_home = Button.new()
	btn_home.text = "Home"
	btn_home.custom_minimum_size = Vector2(0, 88)
	btn_home.focus_mode = Control.FOCUS_NONE
	btn_home.add_theme_font_size_override("font_size", 35) # Big clean button text
	btn_home.add_theme_color_override("font_color", Color("#382317"))
	if round_font:
		btn_home.add_theme_font_override("font", round_font)

	var home_style := StyleBoxFlat.new()
	home_style.bg_color = Color("#FFF9F0") # Soft warm cream matching reference #FFF9F0
	home_style.border_width_left = 2
	home_style.border_width_top = 2
	home_style.border_width_right = 2
	home_style.border_width_bottom = 2
	home_style.border_color = Color("#E8DAC6")
	home_style.set_corner_radius_all(44)
	home_style.shadow_size = 6
	home_style.shadow_color = Color(0.12, 0.08, 0.04, 0.06)
	home_style.shadow_offset = Vector2(0, 3)
	btn_home.add_theme_stylebox_override("normal", home_style)

	var home_hover := home_style.duplicate() as StyleBoxFlat
	home_hover.bg_color = Color("#FFFDF8")
	btn_home.add_theme_stylebox_override("hover", home_hover)

	var home_pressed := home_style.duplicate() as StyleBoxFlat
	home_pressed.bg_color = Color("#F3E6D5")
	btn_home.add_theme_stylebox_override("pressed", home_pressed)

	btn_home.pressed.connect(func() -> void:
		_play_click()
		hide()
		home_requested.emit()
	)
	content.add_child(btn_home)

	# 4. Overlapping Header with Curved Ribbon and 3 Puffy Stars
	top_header = Control.new()
	top_header.position = Vector2.ZERO
	top_header.size = Vector2(CARD_WIDTH, 280.0)
	top_header.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card_wrapper.add_child(top_header)

	# A. 3 Golden Puffy 3D Stars Floating HIGH ABOVE breaking out of the card top
	var stars_w := 440.0
	var stars_h := 180.0
	stars_container = Control.new()
	stars_container.position = Vector2((CARD_WIDTH - stars_w) * 0.5, -40.0)
	stars_container.size = Vector2(stars_w, stars_h)
	stars_container.pivot_offset = Vector2(stars_w * 0.5, stars_h * 0.5)
	stars_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	top_header.add_child(stars_container)

	star_controls.clear()
	# Center star largest and tallest; side stars rotated slightly with ample breathing space above ribbon
	var star_configs: Array[Dictionary] = [
		{"pos": Vector2(20.0, 36.0), "size": Vector2(118.0, 118.0), "rot": -0.18, "z": 0},
		{"pos": Vector2(142.0, -8.0), "size": Vector2(156.0, 156.0), "rot": 0.0, "z": 1},
		{"pos": Vector2(302.0, 36.0), "size": Vector2(118.0, 118.0), "rot": 0.18, "z": 0}
	]
	for config in star_configs:
		var star_ctrl := _create_star_control(config["size"], star_tex)
		star_ctrl.position = config["pos"]
		star_ctrl.rotation = config["rot"]
		star_ctrl.z_index = config["z"]
		stars_container.add_child(star_ctrl)
		star_controls.append(star_ctrl)

	# B. Arched Curved Orange Ribbon Banner positioned with clear visible space below the stars
	var ribbon_w := 660.0
	var ribbon_h := 180.0
	ribbon_wrapper = Control.new()
	ribbon_wrapper.position = Vector2((CARD_WIDTH - ribbon_w) * 0.5, 118.0)
	ribbon_wrapper.size = Vector2(ribbon_w, ribbon_h)
	ribbon_wrapper.mouse_filter = Control.MOUSE_FILTER_IGNORE
	top_header.add_child(ribbon_wrapper)

	var ribbon_tex := load("res://assets/icons/orange_ribbon.png") as Texture2D
	if ribbon_tex:
		var ribbon_rect := TextureRect.new()
		ribbon_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
		ribbon_rect.texture = ribbon_tex
		ribbon_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		ribbon_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		ribbon_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
		ribbon_wrapper.add_child(ribbon_rect)

	# lbl_banner exists for test assertions and screen readers
	lbl_banner = Label.new()
	lbl_banner.text = "Level Completed!"
	lbl_banner.set_anchors_preset(Control.PRESET_FULL_RECT)
	lbl_banner.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl_banner.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	lbl_banner.modulate.a = 0.0 # Text is seamlessly arched in ribbon graphic
	ribbon_wrapper.add_child(lbl_banner)

func _create_star_control(star_size: Vector2, tex: Texture2D) -> Control:
	var ctrl := Control.new()
	ctrl.size = star_size
	ctrl.custom_minimum_size = star_size
	ctrl.pivot_offset = star_size * 0.5
	ctrl.mouse_filter = Control.MOUSE_FILTER_IGNORE

	if tex:
		var tr := TextureRect.new()
		tr.set_anchors_preset(Control.PRESET_FULL_RECT)
		tr.texture = tex
		tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		tr.mouse_filter = Control.MOUSE_FILTER_IGNORE
		ctrl.add_child(tr)
	else:
		var fallback := Label.new()
		fallback.text = "⭐"
		fallback.set_anchors_preset(Control.PRESET_FULL_RECT)
		fallback.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		fallback.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		fallback.add_theme_font_size_override("font_size", int(star_size.y * 0.8))
		ctrl.add_child(fallback)

	return ctrl

func _play_click() -> void:
	if SoundManager.instance:
		SoundManager.instance.play_click()
