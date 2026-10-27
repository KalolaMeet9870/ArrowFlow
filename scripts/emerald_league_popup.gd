class_name EmeraldLeaguePopup
extends Control

## Emerald League Modal Dialog matching Reference Image 5.
## Displays the Emerald League badge, remaining tournament time, player standings,
## and progression feedback.

signal closed
signal play_requested

var panel_container: PanelContainer

func _ready() -> void:
	anchor_left = 0.0
	anchor_top = 0.0
	anchor_right = 1.0
	anchor_bottom = 1.0
	offset_left = 0.0
	offset_top = 0.0
	offset_right = 0.0
	offset_bottom = 0.0
	mouse_filter = Control.MOUSE_FILTER_STOP
	_build_ui()
	hide()

func show_popup() -> void:
	anchor_left = 0.0
	anchor_top = 0.0
	anchor_right = 1.0
	anchor_bottom = 1.0
	offset_left = 0.0
	offset_top = 0.0
	offset_right = 0.0
	offset_bottom = 0.0
	show()
	modulate.a = 0.0
	var tw = create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.tween_property(self, "modulate:a", 1.0, 0.22)

func hide_popup() -> void:
	var tw = create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tw.tween_property(self, "modulate:a", 0.0, 0.18)
	await tw.finished
	hide()
	closed.emit()

func _build_ui() -> void:
	# 1. Dimmed semi-transparent backdrop
	var dim_rect = ColorRect.new()
	dim_rect.anchor_left = 0.0
	dim_rect.anchor_top = 0.0
	dim_rect.anchor_right = 1.0
	dim_rect.anchor_bottom = 1.0
	dim_rect.offset_left = 0.0
	dim_rect.offset_top = 0.0
	dim_rect.offset_right = 0.0
	dim_rect.offset_bottom = 0.0
	dim_rect.color = Color(0, 0, 0, 0.76)
	dim_rect.mouse_filter = Control.MOUSE_FILTER_STOP
	dim_rect.gui_input.connect(func(event: InputEvent):
		if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			hide_popup()
	)
	add_child(dim_rect)

	var center = CenterContainer.new()
	center.anchor_left = 0.0
	center.anchor_top = 0.0
	center.anchor_right = 1.0
	center.anchor_bottom = 1.0
	center.offset_left = 0.0
	center.offset_top = 0.0
	center.offset_right = 0.0
	center.offset_bottom = 0.0
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(center)

	# 2. Main Dialog Card
	panel_container = PanelContainer.new()
	panel_container.custom_minimum_size = Vector2(480, 720)
	var card_sb = StyleBoxFlat.new()
	card_sb.bg_color = Color(0.12, 0.12, 0.12, 0.95)
	card_sb.set_corner_radius_all(32)
	card_sb.shadow_size = 24
	card_sb.shadow_color = Color(0, 0, 0, 0.45)
	card_sb.shadow_offset = Vector2(0, 8)
	card_sb.border_width_left = 1
	card_sb.border_width_top = 1
	card_sb.border_width_right = 1
	card_sb.border_width_bottom = 1
	card_sb.border_color = Color(0.3, 0.28, 0.24, 0.6)
	panel_container.add_theme_stylebox_override("panel", card_sb)
	center.add_child(panel_container)

	var card_margin = MarginContainer.new()
	card_margin.add_theme_constant_override("margin_left", 28)
	card_margin.add_theme_constant_override("margin_right", 28)
	card_margin.add_theme_constant_override("margin_top", 28)
	card_margin.add_theme_constant_override("margin_bottom", 28)
	panel_container.add_child(card_margin)

	var vbox = VBoxContainer.new()
	vbox.alignment = BoxContainer.ALIGNMENT_BEGIN
	vbox.add_theme_constant_override("separation", 14)
	card_margin.add_child(vbox)

	# Title: 🌾 Emerald League 🌾
	var lbl_title = Label.new()
	lbl_title.text = "🌾 Emerald League 🌾"
	lbl_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl_title.add_theme_font_size_override("font_size", 28)
	lbl_title.add_theme_color_override("font_color", Color("#F5D77F"))
	vbox.add_child(lbl_title)

	# Timer Pill: 🕒 20h49m
	var timer_center = CenterContainer.new()
	var timer_pill = PanelContainer.new()
	timer_pill.custom_minimum_size = Vector2(120, 26)
	var tp_sb = StyleBoxFlat.new()
	tp_sb.bg_color = Color(0.32, 0.24, 0.14, 0.8)
	tp_sb.set_corner_radius_all(13)
	timer_pill.add_theme_stylebox_override("panel", tp_sb)
	var lbl_timer = Label.new()
	lbl_timer.text = "🕒 20h49m"
	lbl_timer.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl_timer.add_theme_font_size_override("font_size", 12)
	lbl_timer.add_theme_color_override("font_color", Color("#FFE29A"))
	timer_pill.add_child(lbl_timer)
	timer_center.add_child(timer_pill)
	vbox.add_child(timer_center)

	# Emblem Box with Emerald Badge
	var badge_box = CenterContainer.new()
	badge_box.custom_minimum_size = Vector2(0, 110)
	var badge_ctrl = Control.new()
	badge_ctrl.custom_minimum_size = Vector2(100, 100)
	badge_ctrl.draw.connect(func():
		var c = Vector2(50, 50)
		# Golden wings
		badge_ctrl.draw_circle(c + Vector2(-32, -4), 16.0, Color("#F5B041"))
		badge_ctrl.draw_circle(c + Vector2(32, -4), 16.0, Color("#F5B041"))
		# Emerald Hexagon
		var hex_pts = PackedVector2Array()
		for i in range(6):
			var a = (float(i) * TAU / 6.0) - (PI * 0.5)
			hex_pts.append(c + Vector2(cos(a), sin(a)) * 36.0)
		badge_ctrl.draw_colored_polygon(hex_pts, Color("#1E8449"))
		# Inner lighter hexagon
		var hex_inner = PackedVector2Array()
		for i in range(6):
			var a = (float(i) * TAU / 6.0) - (PI * 0.5)
			hex_inner.append(c + Vector2(cos(a), sin(a)) * 28.0)
		badge_ctrl.draw_colored_polygon(hex_inner, Color("#2ECC71"))
		# Gold upward arrow
		var arrow_pts = PackedVector2Array([
			c + Vector2(0, -18),
			c + Vector2(14, -2),
			c + Vector2(7, -2),
			c + Vector2(7, 16),
			c + Vector2(-7, 16),
			c + Vector2(-7, -2),
			c + Vector2(-14, -2)
		])
		badge_ctrl.draw_colored_polygon(arrow_pts, Color("#F7DC6F"))
	)
	badge_box.add_child(badge_ctrl)
	vbox.add_child(badge_box)

	# Zone Banner: 🔻 🔻 To be demoted 🔻 🔻
	var zone_panel = PanelContainer.new()
	var zp_sb = StyleBoxFlat.new()
	zp_sb.bg_color = Color("#FFF6E9")
	zp_sb.set_corner_radius_all(14)
	zone_panel.add_theme_stylebox_override("panel", zp_sb)
	var lbl_zone = Label.new()
	lbl_zone.text = "🔻 🔻  To be demoted  🔻 🔻"
	lbl_zone.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl_zone.add_theme_font_size_override("font_size", 13)
	lbl_zone.add_theme_color_override("font_color", Color("#C0392B"))
	zone_panel.add_child(lbl_zone)
	vbox.add_child(zone_panel)

	# Leaderboard list (4 rows matching Image 5)
	var lb_vbox = VBoxContainer.new()
	lb_vbox.add_theme_constant_override("separation", 8)
	vbox.add_child(lb_vbox)

	var rows = [
		{"rank": "31", "name": "praline...", "score": "16", "is_me": false, "avatar": "🐷"},
		{"rank": "32", "name": "ArrowFlow Player", "score": "12", "is_me": true, "avatar": "👤"},
		{"rank": "33", "name": "Landon_...", "score": "12", "is_me": false, "avatar": "🐷"},
		{"rank": "34", "name": "Hannah_...", "score": "12", "is_me": false, "avatar": "🦁"}
	]

	for r in rows:
		var row_card = PanelContainer.new()
		row_card.custom_minimum_size = Vector2(0, 48)
		var r_sb = StyleBoxFlat.new()
		if r["is_me"]:
			r_sb.bg_color = Color("#F8C471") # Golden highlight for Me
			r_sb.border_width_left = 2
			r_sb.border_width_top = 2
			r_sb.border_width_right = 2
			r_sb.border_width_bottom = 2
			r_sb.border_color = Color("#E67E22")
		else:
			r_sb.bg_color = Color("#FFF9F0")
		r_sb.set_corner_radius_all(14)
		row_card.add_theme_stylebox_override("panel", r_sb)

		var r_margin = MarginContainer.new()
		r_margin.add_theme_constant_override("margin_left", 14)
		r_margin.add_theme_constant_override("margin_right", 14)
		row_card.add_child(r_margin)

		var r_hbox = HBoxContainer.new()
		r_hbox.alignment = BoxContainer.ALIGNMENT_CENTER
		r_hbox.add_theme_constant_override("separation", 10)
		r_margin.add_child(r_hbox)

		var lbl_r = Label.new()
		lbl_r.text = r["rank"]
		lbl_r.custom_minimum_size = Vector2(28, 0)
		lbl_r.add_theme_font_size_override("font_size", 16)
		lbl_r.add_theme_color_override("font_color", Color("#784212"))
		r_hbox.add_child(lbl_r)

		var lbl_av = Label.new()
		lbl_av.text = r["avatar"]
		lbl_av.add_theme_font_size_override("font_size", 20)
		r_hbox.add_child(lbl_av)

		if r["is_me"]:
			var me_pill = PanelContainer.new()
			var mp_sb = StyleBoxFlat.new()
			mp_sb.bg_color = Color("#27AE60")
			mp_sb.set_corner_radius_all(8)
			me_pill.add_theme_stylebox_override("panel", mp_sb)
			var lbl_me = Label.new()
			lbl_me.text = " Me "
			lbl_me.add_theme_font_size_override("font_size", 10)
			lbl_me.add_theme_color_override("font_color", Color.WHITE)
			me_pill.add_child(lbl_me)
			r_hbox.add_child(me_pill)

		var lbl_n = Label.new()
		lbl_n.text = r["name"]
		lbl_n.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		lbl_n.add_theme_font_size_override("font_size", 15)
		lbl_n.add_theme_color_override("font_color", Color("#4A235A") if r["is_me"] else Color("#333333"))
		r_hbox.add_child(lbl_n)

		# Score Pill
		var score_pill = PanelContainer.new()
		var sp_sb = StyleBoxFlat.new()
		sp_sb.bg_color = Color("#FFF0DC")
		sp_sb.set_corner_radius_all(12)
		score_pill.add_theme_stylebox_override("panel", sp_sb)
		var sp_hbox = HBoxContainer.new()
		sp_hbox.add_theme_constant_override("separation", 4)
		score_pill.add_child(sp_hbox)
		var lbl_arr = Label.new()
		lbl_arr.text = "🏹"
		lbl_arr.add_theme_font_size_override("font_size", 13)
		sp_hbox.add_child(lbl_arr)
		var lbl_s = Label.new()
		lbl_s.text = r["score"]
		lbl_s.add_theme_font_size_override("font_size", 14)
		lbl_s.add_theme_color_override("font_color", Color("#B9770E"))
		sp_hbox.add_child(lbl_s)
		r_hbox.add_child(score_pill)

		lb_vbox.add_child(row_card)

	# Bottom encouragement text
	var lbl_feedback = Label.new()
	lbl_feedback.text = "Impressive progress! You jumped up 6 places."
	lbl_feedback.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl_feedback.add_theme_font_size_override("font_size", 14)
	lbl_feedback.add_theme_color_override("font_color", Color("#FAD7A0"))
	vbox.add_child(lbl_feedback)

	# Action Button: "Continue"
	var btn_continue = Button.new()
	btn_continue.text = "Continue"
	btn_continue.custom_minimum_size = Vector2(0, 64)
	btn_continue.focus_mode = Control.FOCUS_NONE
	var c_sb = StyleBoxFlat.new()
	c_sb.bg_color = Color("#C8782E")
	c_sb.set_corner_radius_all(22)
	c_sb.shadow_size = 8
	c_sb.shadow_color = Color(0, 0, 0, 0.25)
	c_sb.shadow_offset = Vector2(0, 4)
	btn_continue.add_theme_stylebox_override("normal", c_sb)
	var c_h_sb = c_sb.duplicate() as StyleBoxFlat
	c_h_sb.bg_color = Color("#D98538")
	btn_continue.add_theme_stylebox_override("hover", c_h_sb)
	btn_continue.add_theme_font_size_override("font_size", 22)
	btn_continue.add_theme_color_override("font_color", Color.WHITE)
	btn_continue.pressed.connect(func():
		hide_popup()
		play_requested.emit()
	)
	vbox.add_child(btn_continue)
