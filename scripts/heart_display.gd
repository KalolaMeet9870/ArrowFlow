class_name HeartDisplay
extends HBoxContainer

## Displays remaining lives/hearts/drops with smooth loss animations matching ArrowFlow design.

const TEXTURE_DROP = preload("res://assets/icons/water_drop.png")
const TEXTURE_EMPTY = preload("res://assets/icons/water_drop_empty.png")

var drop_labels: Array[Control] = []

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_theme_constant_override("separation", 16)
	_build_drops(3)

func _build_drops(count: int) -> void:
	for child in get_children():
		child.queue_free()
	drop_labels.clear()

	for i in range(count):
		var drop = TextureRect.new()
		drop.name = "Drop%d" % i
		drop.texture = TEXTURE_DROP
		drop.custom_minimum_size = Vector2(46, 64)
		drop.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		drop.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		drop.mouse_filter = Control.MOUSE_FILTER_IGNORE
		drop.pivot_offset = Vector2(23, 32)
		add_child(drop)
		drop_labels.append(drop)

func update_hearts(current: int, maximum: int) -> void:
	if drop_labels.size() != maximum:
		_build_drops(maximum)

	for i in range(drop_labels.size()):
		var drop = drop_labels[i] as TextureRect
		if drop == null:
			continue
		if i < current:
			drop.texture = TEXTURE_DROP
			drop.modulate.a = 1.0
			drop.scale = Vector2.ONE
		else:
			if drop.modulate.a > 0.35: # Just lost
				var tw = create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
				tw.tween_property(drop, "scale", Vector2(1.3, 1.3), 0.1)
				tw.tween_property(drop, "scale", Vector2.ONE, 0.15)
				tw.parallel().tween_property(drop, "modulate:a", 0.28, 0.25)
			else:
				drop.modulate.a = 0.28
				drop.scale = Vector2.ONE
