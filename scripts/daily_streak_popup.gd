class_name DailyStreakPopup
extends Control

## Daily Streak Modal Popup matching the user design screenshot.
## Displays golden sun emblem, explanation, current/best streak records, and OK action button.

signal closed

var panel_container: PanelContainer
var lbl_current_val: Label
var lbl_best_val: Label

func _ready() -> void:
	anchor_right = 1.0
	anchor_bottom = 1.0
	offset_left = 0
	offset_top = 0
	offset_right = 0
	offset_bottom = 0
	mouse_filter = Control.MOUSE_FILTER_STOP
	_build_ui()
	hide()

func show_popup(current_streak: int = 1, best_streak: int = 2) -> void:
	if lbl_current_val:
		lbl_current_val.text = str(current_streak)
	if lbl_best_val:
		lbl_best_val.text = str(best_streak)

	show()
	modulate = Color(1, 1, 1, 0)
	var tw = create_tween()
	tw.tween_property(self, "modulate:a", 1.0, 0.22).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

func hide_popup() -> void:
	var tw = create_tween()
	tw.tween_property(self, "modulate:a", 0.0, 0.18).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	await tw.finished
	hide()
	closed.emit()

func _build_ui() -> void:
	# Dimmed backdrop
	var dim_rect = ColorRect.new()
	dim_rect.anchor_right = 1.0
	dim_rect.anchor_bottom = 1.0
	dim_rect.offset_left = 0
	dim_rect.offset_top = 0
	dim_rect.offset_right = 0
	dim_rect.offset_bottom = 0
	dim_rect.color = Color(0, 0, 0, 0.5)
	dim_rect.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(dim_rect)
	dim_rect.gui_input.connect(func(event: InputEvent):
		if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			hide_popup()
	)

	var center = CenterContainer.new()
	center.anchor_right = 1.0
	center.anchor_bottom = 1.0
	center.offset_left = 0
	center.offset_top = 0
	center.offset_right = 0
	center.offset_bottom = 0
	add_child(center)

	# Main Dialog Card
	panel_container = PanelContainer.new()
	panel_container.custom_minimum_size = Vector2(460, 480)
	var card_sb = StyleBoxFlat.new()
	card_sb.bg_color = Color("#FFF9EE") # warm cream
	card_sb.corner_radius_top_left = 28
	card_sb.corner_radius_top_right = 28
	card_sb.corner_radius_bottom_left = 28
	card_sb.corner_radius_bottom_right = 28
	card_sb.shadow_size = 18
	card_sb.shadow_color = Color(0, 0, 0, 0.15)
	card_sb.shadow_offset = Vector2(0, 8)
	panel_container.add_theme_stylebox_override("panel", card_sb)
	center.add_child(panel_container)

	var card_margin = MarginContainer.new()
	card_margin.add_theme_constant_override("margin_left", 36)
	card_margin.add_theme_constant_override("margin_right", 36)
	card_margin.add_theme_constant_override("margin_top", 36)
	card_margin.add_theme_constant_override("margin_bottom", 36)
	panel_container.add_child(card_margin)

	var vbox = VBoxContainer.new()
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_theme_constant_override("separation", 20)
	card_margin.add_child(vbox)

	# 1. Golden Sun Emblem (custom drawing node)
	var sun_holder = Control.new()
	sun_holder.custom_minimum_size = Vector2(100, 100)
	sun_holder.draw.connect(func():
		var center_pt = Vector2(50, 50)
		var r_outer = 42.0
		var r_inner = 30.0
		var ray_count = 12

		# Draw rays
		for i in range(ray_count):
			var a = (float(i) / float(ray_count)) * TAU
			var a_left = a - (TAU / (ray_count * 4.0))
			var a_right = a + (TAU / (ray_count * 4.0))

			var p_tip = center_pt + Vector2(cos(a), sin(a)) * r_outer
			var p_l = center_pt + Vector2(cos(a_left), sin(a_left)) * (r_inner * 0.95)
			var p_r = center_pt + Vector2(cos(a_right), sin(a_right)) * (r_inner * 0.95)

			var tri: PackedVector2Array = [p_l, p_tip, p_r]
			sun_holder.draw_colored_polygon(tri, Color("#F5A623"))

		# Draw central sun disc
		sun_holder.draw_circle(center_pt, r_inner, Color("#FFB72B"))
		sun_holder.draw_circle(center_pt, r_inner * 0.85, Color("#FFC745"))
	)
	var sun_center = CenterContainer.new()
	sun_center.add_child(sun_holder)
	vbox.add_child(sun_center)

	# 2. Title: Daily Streak
	var lbl_title = Label.new()
	lbl_title.text = "Daily Streak"
	lbl_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl_title.add_theme_font_size_override("font_size", 32)
	lbl_title.add_theme_color_override("font_color", Color("#B57538"))
	vbox.add_child(lbl_title)

	# 3. Subtitle
	var lbl_sub = Label.new()
	lbl_sub.text = "A Daily Streak tracks your\nconsecutive winning days"
	lbl_sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl_sub.add_theme_font_size_override("font_size", 18)
	lbl_sub.add_theme_color_override("font_color", Color("#7D6F64"))
	vbox.add_child(lbl_sub)

	# 4. Records Row (Pill Panel)
	var records_panel = PanelContainer.new()
	records_panel.custom_minimum_size = Vector2(400, 90)
	var rec_sb = StyleBoxFlat.new()
	rec_sb.bg_color = Color("#F3ECE0")
	rec_sb.corner_radius_top_left = 22
	rec_sb.corner_radius_top_right = 22
	rec_sb.corner_radius_bottom_left = 22
	rec_sb.corner_radius_bottom_right = 22
	records_panel.add_theme_stylebox_override("panel", rec_sb)
	vbox.add_child(records_panel)

	var rec_hbox = HBoxContainer.new()
	rec_hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	records_panel.add_child(rec_hbox)

	# Left Column: Current Record
	var left_vbox = VBoxContainer.new()
	left_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	left_vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	rec_hbox.add_child(left_vbox)

	var lbl_cur_title = Label.new()
	lbl_cur_title.text = "Current Record"
	lbl_cur_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl_cur_title.add_theme_font_size_override("font_size", 15)
	lbl_cur_title.add_theme_color_override("font_color", Color("#A1887F"))
	left_vbox.add_child(lbl_cur_title)

	lbl_current_val = Label.new()
	lbl_current_val.text = "1"
	lbl_current_val.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl_current_val.add_theme_font_size_override("font_size", 32)
	lbl_current_val.add_theme_color_override("font_color", Color("#B57538"))
	left_vbox.add_child(lbl_current_val)

	# Right Column: Best Record
	var right_vbox = VBoxContainer.new()
	right_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	right_vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	rec_hbox.add_child(right_vbox)

	var lbl_best_title = Label.new()
	lbl_best_title.text = "Best Record"
	lbl_best_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl_best_title.add_theme_font_size_override("font_size", 15)
	lbl_best_title.add_theme_color_override("font_color", Color("#A1887F"))
	right_vbox.add_child(lbl_best_title)

	lbl_best_val = Label.new()
	lbl_best_val.text = "2"
	lbl_best_val.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl_best_val.add_theme_font_size_override("font_size", 32)
	lbl_best_val.add_theme_color_override("font_color", Color("#B57538"))
	right_vbox.add_child(lbl_best_val)

	# 5. OK Action Button
	var btn_ok = Button.new()
	btn_ok.text = "OK"
	btn_ok.custom_minimum_size = Vector2(360, 64)
	btn_ok.focus_mode = Control.FOCUS_NONE

	var ok_sb = StyleBoxFlat.new()
	ok_sb.bg_color = Color("#C07838")
	ok_sb.corner_radius_top_left = 22
	ok_sb.corner_radius_top_right = 22
	ok_sb.corner_radius_bottom_left = 22
	ok_sb.corner_radius_bottom_right = 22
	ok_sb.shadow_size = 8
	ok_sb.shadow_color = Color(0, 0, 0, 0.15)
	ok_sb.shadow_offset = Vector2(0, 4)
	btn_ok.add_theme_stylebox_override("normal", ok_sb)

	var ok_h_sb = ok_sb.duplicate() as StyleBoxFlat
	ok_h_sb.bg_color = Color("#D48642")
	btn_ok.add_theme_stylebox_override("hover", ok_h_sb)

	var ok_p_sb = ok_sb.duplicate() as StyleBoxFlat
	ok_p_sb.bg_color = Color("#A8652D")
	btn_ok.add_theme_stylebox_override("pressed", ok_p_sb)

	btn_ok.add_theme_font_size_override("font_size", 22)
	btn_ok.add_theme_color_override("font_color", Color.WHITE)
	btn_ok.pressed.connect(func():
		if SoundManager.instance:
			SoundManager.instance.play_click()
		hide_popup()
	)
	vbox.add_child(btn_ok)
