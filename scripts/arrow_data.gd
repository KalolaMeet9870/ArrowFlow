class_name ArrowData
extends Node

## Manages 50 verified solvable levels, user progress, and visual themes.

static var instance: ArrowData

var levels: Array = []
var current_level_idx: int = 0
var completed_levels: Dictionary = {} # level_id -> bool
var current_theme_idx: int = 0 # 0 = Eye Comfort, 1 = Dark Slate

const THEMES = [
	# 0: Eye Comfort (Warm Paper & Espresso Brown)
	{
		"name": "Eye Comfort",
		"bg": Color("#FAF4E8"),
		"line": Color("#4A3525"),
		"head": Color("#4A3525"),
		"blocked": Color("#E53935"),
		"hint": Color("#FFB300"),
		"header": Color("#B37B24"),
		"drop_active": Color("#29B6F6"),
		"drop_empty": Color("#D7CCC8"),
		"card_bg": Color("#FFFDF9"),
		"card_border": Color("#E0D5C1"),
		"banner_bg": Color("#D8C3A5"),
		"banner_text": Color("#5D4037"),
		"btn_bg": Color("#FFFFFF"),
		"btn_icon": Color("#4A3525")
	},
	# 1: Dark Slate (Night Comfort)
	{
		"name": "Dark Slate",
		"bg": Color("#181A20"),
		"line": Color("#E2E8F0"),
		"head": Color("#E2E8F0"),
		"blocked": Color("#FF5252"),
		"hint": Color("#FFD54F"),
		"header": Color("#FFD54F"),
		"drop_active": Color("#38BDF8"),
		"drop_empty": Color("#334155"),
		"card_bg": Color("#1E222B"),
		"card_border": Color("#334155"),
		"banner_bg": Color("#282D37"),
		"banner_text": Color("#E2E8F0"),
		"btn_bg": Color("#282D37"),
		"btn_icon": Color("#F1F5F9")
	}
]

func _enter_tree() -> void:
	instance = self
	_load_levels()
	_load_progress()

func _load_levels() -> void:
	var path = "res://data/levels.json"
	if FileAccess.file_exists(path):
		var file = FileAccess.open(path, FileAccess.READ)
		var json_str = file.get_as_text()
		file.close()
		var json = JSON.new()
		if json.parse(json_str) == OK:
			levels = json.data
			print("Loaded %d levels from %s" % [levels.size(), path])
		else:
			push_error("JSON Parse Error: %s" % json.get_error_message())
	else:
		push_error("Levels file not found: %s" % path)

func get_current_theme() -> Dictionary:
	return THEMES[current_theme_idx % THEMES.size()]

func toggle_theme() -> Dictionary:
	current_theme_idx = (current_theme_idx + 1) % THEMES.size()
	return get_current_theme()

func get_level(idx: int) -> Dictionary:
	if levels.is_empty():
		return {}
	current_level_idx = clampi(idx, 0, levels.size() - 1)
	return levels[current_level_idx]

func mark_level_completed(level_id: int) -> void:
	completed_levels[level_id] = true
	_save_progress()

func is_level_completed(level_id: int) -> bool:
	return completed_levels.get(level_id, false)

func _save_progress() -> void:
	var file = FileAccess.open("user://arrow_progress.json", FileAccess.WRITE)
	if file:
		var data = {
			"completed": completed_levels,
			"current_idx": current_level_idx,
			"theme_idx": current_theme_idx
		}
		file.store_string(JSON.stringify(data))
		file.close()

func _load_progress() -> void:
	if FileAccess.file_exists("user://arrow_progress.json"):
		var file = FileAccess.open("user://arrow_progress.json", FileAccess.READ)
		if file:
			var json = JSON.new()
			if json.parse(file.get_as_text()) == OK and json.data is Dictionary:
				completed_levels = json.data.get("completed", {})
				current_level_idx = int(json.data.get("current_idx", 0))
				current_theme_idx = int(json.data.get("theme_idx", 0))
			file.close()
