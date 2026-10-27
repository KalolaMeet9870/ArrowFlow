class_name SplashScreen
extends Control

## Modern, mobile-first Splash Screen for ArrowFlow ("Clear The Path").
## Matches the exact aesthetic from the design mockup:
## - Full Safe Area support respecting top status bar and bottom home indicator.
## - Organic cream zen wave ambient background.
## - Centered floating 3D ArrowFlow app icon with subtle breathing animation.
## - Stylized dual-tone logo: "Arrow" in espresso brown, "Flow" in vibrant orange.
## - "CLEAR THE PATH" spaced uppercase subtitle.
## - Sleek rounded progress bar with animated warm orange fill.
## - "Loading..." status label with animated dots.
## - Smooth cross-fade transition into the Main menu.

signal splash_finished

const SafeAreaHelper = preload("res://scripts/safe_area_helper.gd")

var bg_rect: ColorRect
var bg_waves: TextureRect
var safe_margin: MarginContainer
var icon_rect: TextureRect
var progress_bar: ProgressBar
var lbl_loading: Label
var _load_progress: float = 0.0
var _dots_timer: float = 0.0
var _dot_count: int = 0
var _is_finished: bool = false

func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	_build_ui()
	_start_animations()

	resized.connect(_on_resized)
	if get_tree() and get_tree().root:
		get_tree().root.size_changed.connect(_on_resized)

func _on_resized() -> void:
	if safe_margin:
		SafeAreaHelper.apply_safe_area_margins(safe_margin, get_viewport())

func _build_ui() -> void:
	# 1. Base cream background (#FAF4E8)
	bg_rect = ColorRect.new()
	bg_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg_rect.color = Color("#FAF4E8")
	bg_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg_rect)

	# 2. Organic silky waves ambient texture
	bg_waves = TextureRect.new()
	bg_waves.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg_waves.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bg_waves.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	bg_waves.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	if ResourceLoader.exists("res://assets/splash/splash_bg_waves.png"):
		bg_waves.texture = load("res://assets/splash/splash_bg_waves.png")
	add_child(bg_waves)

	# 3. Safe Margin Container
	safe_margin = MarginContainer.new()
	safe_margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	safe_margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(safe_margin)
	SafeAreaHelper.apply_safe_area_margins(safe_margin, get_viewport())

	# 4. Vertical content layout
	var main_vbox = VBoxContainer.new()
	main_vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	main_vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	main_vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	safe_margin.add_child(main_vbox)

	# Top flexible spacer
	var top_spacer = Control.new()
	top_spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	top_spacer.size_flags_stretch_ratio = 1.3
	main_vbox.add_child(top_spacer)

	# Center branding box
	var brand_box = VBoxContainer.new()
	brand_box.alignment = BoxContainer.ALIGNMENT_CENTER
	brand_box.add_theme_constant_override("separation", 14)
	brand_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	main_vbox.add_child(brand_box)

	# Icon container
	var icon_center = CenterContainer.new()
	brand_box.add_child(icon_center)

	icon_rect = TextureRect.new()
	icon_rect.custom_minimum_size = Vector2(170, 170)
	icon_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon_rect.pivot_offset = Vector2(85, 85)

	if ResourceLoader.exists("res://assets/icons/app_card_floating.png"):
		icon_rect.texture = load("res://assets/icons/app_card_floating.png")
	elif ResourceLoader.exists("res://assets/splash/splash_icon.png"):
		icon_rect.texture = load("res://assets/splash/splash_icon.png")
	icon_center.add_child(icon_rect)

	# App Title: "ArrowFlow" (Dual-tone: Arrow in #3A2E26, Flow in #F28C28)
	var title_hbox = HBoxContainer.new()
	title_hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	title_hbox.add_theme_constant_override("separation", 0)
	brand_box.add_child(title_hbox)

	var lbl_arrow = Label.new()
	lbl_arrow.text = "Arrow"
	lbl_arrow.add_theme_font_size_override("font_size", 42)
	lbl_arrow.add_theme_color_override("font_color", Color("#3A2E26"))
	title_hbox.add_child(lbl_arrow)

	var lbl_flow = Label.new()
	lbl_flow.text = "Flow"
	lbl_flow.add_theme_font_size_override("font_size", 42)
	lbl_flow.add_theme_color_override("font_color", Color("#F28C28"))
	title_hbox.add_child(lbl_flow)

	# Subtitle: "CLEAR THE PATH"
	var lbl_subtitle = Label.new()
	lbl_subtitle.text = "CLEAR THE PATH"
	lbl_subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl_subtitle.add_theme_font_size_override("font_size", 14)
	lbl_subtitle.add_theme_color_override("font_color", Color("#8C7767"))
	brand_box.add_child(lbl_subtitle)

	# Middle flexible spacer
	var mid_spacer = Control.new()
	mid_spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	mid_spacer.size_flags_stretch_ratio = 1.0
	main_vbox.add_child(mid_spacer)

	# Loading section
	var load_box = VBoxContainer.new()
	load_box.alignment = BoxContainer.ALIGNMENT_CENTER
	load_box.add_theme_constant_override("separation", 10)
	main_vbox.add_child(load_box)

	# Sleek pill progress bar
	var progress_center = CenterContainer.new()
	load_box.add_child(progress_center)

	progress_bar = ProgressBar.new()
	progress_bar.custom_minimum_size = Vector2(210, 7)
	progress_bar.show_percentage = false
	progress_bar.min_value = 0.0
	progress_bar.max_value = 1.0
	progress_bar.value = 0.0

	var bg_sb = StyleBoxFlat.new()
	bg_sb.bg_color = Color("#EADCC6")
	bg_sb.corner_radius_top_left = 4
	bg_sb.corner_radius_top_right = 4
	bg_sb.corner_radius_bottom_left = 4
	bg_sb.corner_radius_bottom_right = 4

	var fill_sb = StyleBoxFlat.new()
	fill_sb.bg_color = Color("#F28C28")
	fill_sb.corner_radius_top_left = 4
	fill_sb.corner_radius_top_right = 4
	fill_sb.corner_radius_bottom_left = 4
	fill_sb.corner_radius_bottom_right = 4

	progress_bar.add_theme_stylebox_override("background", bg_sb)
	progress_bar.add_theme_stylebox_override("fill", fill_sb)
	progress_center.add_child(progress_bar)

	# "Loading..." label
	lbl_loading = Label.new()
	lbl_loading.text = "Loading..."
	lbl_loading.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl_loading.add_theme_font_size_override("font_size", 13)
	lbl_loading.add_theme_color_override("font_color", Color("#9E8F83"))
	load_box.add_child(lbl_loading)

	# Bottom spacing
	var bot_spacer = Control.new()
	bot_spacer.custom_minimum_size = Vector2(0, 36)
	main_vbox.add_child(bot_spacer)

func _process(delta: float) -> void:
	if _is_finished:
		return

	# Animated loading dots
	_dots_timer += delta
	if _dots_timer >= 0.35:
		_dots_timer = 0.0
		_dot_count = (_dot_count + 1) % 4
		var dots_str = ""
		for i in range(_dot_count):
			dots_str += "."
		if lbl_loading:
			lbl_loading.text = "Loading" + dots_str

func _start_animations() -> void:
	# 1. Subtle floating breath animation for the icon
	if icon_rect:
		var float_tw = create_tween().set_loops().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		float_tw.tween_property(icon_rect, "position:y", -6.0, 1.2).as_relative()
		float_tw.tween_property(icon_rect, "position:y", 6.0, 1.2).as_relative()

	# 2. Smooth loading progress animation
	var load_tw = create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	load_tw.tween_property(self, "_load_progress", 0.65, 0.7)
	load_tw.tween_interval(0.15)
	load_tw.tween_property(self, "_load_progress", 1.0, 0.6)
	load_tw.tween_callback(_on_loading_completed)

func _set(property: StringName, value: Variant) -> bool:
	if property == "_load_progress":
		_load_progress = float(value)
		if progress_bar:
			progress_bar.value = _load_progress
		return true
	return false

func _on_loading_completed() -> void:
	if _is_finished:
		return
	_is_finished = true

	# Fade out gently into main screen
	var fade_tw = create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)
	fade_tw.tween_property(self, "modulate:a", 0.0, 0.35)
	fade_tw.tween_callback(func():
		splash_finished.emit()
		hide()
		queue_free()
	)
