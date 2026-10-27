class_name HeartDisplay
extends HBoxContainer

## Displays remaining lives/hearts/drops with smooth loss animations.

var drop_labels: Array[Label] = []

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_theme_constant_override("separation", 10)
	_build_drops(3)

func _build_drops(count: int) -> void:
	for child in get_children():
		child.queue_free()
	drop_labels.clear()

	for i in range(count):
		var lbl = Label.new()
		lbl.text = "💧"
		lbl.add_theme_font_size_override("font_size", 28)
		lbl.add_theme_color_override("font_color", Color("#29B6F6"))
		lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		lbl.pivot_offset = Vector2(14, 16)
		add_child(lbl)
		drop_labels.append(lbl)

func update_hearts(current: int, maximum: int) -> void:
	if drop_labels.size() != maximum:
		_build_drops(maximum)

	for i in range(drop_labels.size()):
		var lbl = drop_labels[i]
		if i < current:
			lbl.modulate.a = 1.0
		else:
			if lbl.modulate.a > 0.35: # Just lost
				var tw = create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
				tw.tween_property(lbl, "scale", Vector2(1.35, 1.35), 0.1)
				tw.tween_property(lbl, "scale", Vector2.ONE, 0.15)
				tw.parallel().tween_property(lbl, "modulate:a", 0.28, 0.25)
			else:
				lbl.modulate.a = 0.28
				lbl.scale = Vector2.ONE
