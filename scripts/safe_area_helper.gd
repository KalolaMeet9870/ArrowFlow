class_name SafeAreaHelper
extends RefCounted

## Utility for managing mobile status bars, notches, Dynamic Island,
## and home indicator safe areas across iOS, Android, and Desktop platforms.

static func get_safe_insets(viewport: Viewport = null) -> Dictionary:
	var safe_rect: Rect2i = DisplayServer.get_display_safe_area()
	var win_size: Vector2i = DisplayServer.window_get_size()

	var top_inset: float = 0.0
	var bottom_inset: float = 0.0
	var left_inset: float = 0.0
	var right_inset: float = 0.0

	if win_size.y > 0 and win_size.x > 0:
		var vp_size = Vector2(720, 1280)
		if viewport:
			var visible_rect = viewport.get_visible_rect()
			if visible_rect.size.x > 50 and visible_rect.size.y > 50:
				vp_size = visible_rect.size

		var scale_y = vp_size.y / float(win_size.y)
		var scale_x = vp_size.x / float(win_size.x)

		top_inset = float(safe_rect.position.y) * scale_y
		bottom_inset = float(win_size.y - (safe_rect.position.y + safe_rect.size.y)) * scale_y
		left_inset = float(safe_rect.position.x) * scale_x
		right_inset = float(win_size.x - (safe_rect.position.x + safe_rect.size.x)) * scale_x

	# Mobile status bars on modern devices require at least 48px in 720p base space
	# Mobile home indicator / navigation bars require at least 28px in 720p base space
	const MIN_TOP_SAFE: float = 48.0
	const MIN_BOTTOM_SAFE: float = 28.0
	const MIN_SIDE_SAFE: float = 16.0

	return {
		"top": maxf(top_inset, MIN_TOP_SAFE),
		"bottom": maxf(bottom_inset, MIN_BOTTOM_SAFE),
		"left": maxf(left_inset, MIN_SIDE_SAFE),
		"right": maxf(right_inset, MIN_SIDE_SAFE)
	}

static func apply_safe_area_margins(
	margin_container: MarginContainer,
	viewport: Viewport = null,
	extra_top: float = 0.0,
	extra_bottom: float = 0.0,
	extra_left: float = 0.0,
	extra_right: float = 0.0
) -> void:
	if margin_container == null:
		return
	var insets = get_safe_insets(viewport)
	margin_container.add_theme_constant_override("margin_top", int(roundf(insets["top"] + extra_top)))
	margin_container.add_theme_constant_override("margin_bottom", int(roundf(insets["bottom"] + extra_bottom)))
	margin_container.add_theme_constant_override("margin_left", int(roundf(insets["left"] + extra_left)))
	margin_container.add_theme_constant_override("margin_right", int(roundf(insets["right"] + extra_right)))
