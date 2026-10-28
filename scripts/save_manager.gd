class_name SaveManager
extends Node

## Handles local progress persistence, settings, and level completion records.

static var instance: SaveManager

const SAVE_PATH: String = "user://arrow_save_data.json"

var highest_unlocked_level: int = 100
var completed_levels: Dictionary = {} # level_id (int/str) -> {"best_moves": int, "hearts": int}
var current_level: int = 98
var coins: int = 1
var sound_enabled: bool = true
var vibration_enabled: bool = true
var music_enabled: bool = true
var voice_enabled: bool = true
var guideline_enabled: bool = false
var calm_mode_enabled: bool = false
var theme_idx: int = 0
var daily_puzzle_date: String = ""
var daily_streak: int = 1
var current_streak: int = 1
var best_streak: int = 2
var player_name: String = "Player123"
var player_email: String = "player@example.com"
var event_progress: int = 3
var event_max: int = 10

func _enter_tree() -> void:
	instance = self
	load_data()

func save_data() -> void:
	var file = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if not file:
		push_error("SaveManager: Failed to open save file for writing.")
		return

	var data = {
		"highest_unlocked_level": highest_unlocked_level,
		"completed_levels": completed_levels,
		"current_level": current_level,
		"coins": coins,
		"sound_enabled": sound_enabled,
		"vibration_enabled": vibration_enabled,
		"music_enabled": music_enabled,
		"voice_enabled": voice_enabled,
		"guideline_enabled": guideline_enabled,
		"calm_mode_enabled": calm_mode_enabled,
		"theme_idx": theme_idx,
		"daily_puzzle_date": daily_puzzle_date,
		"daily_streak": daily_streak,
		"current_streak": current_streak,
		"best_streak": best_streak,
		"player_name": player_name,
		"player_email": player_email,
		"event_progress": event_progress,
		"event_max": event_max
	}
	file.store_string(JSON.stringify(data, "\t"))
	file.close()

func load_data() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		return

	var file = FileAccess.open(SAVE_PATH, FileAccess.READ)
	if not file:
		return

	var text = file.get_as_text()
	file.close()

	var json = JSON.new()
	if json.parse(text) != OK:
		push_warning("SaveManager: Save data corrupted or invalid JSON, using defaults.")
		return

	var data = json.data
	if data is Dictionary:
		highest_unlocked_level = int(data.get("highest_unlocked_level", 1))
		completed_levels = data.get("completed_levels", {})
		current_level = int(data.get("current_level", 1))
		coins = int(data.get("coins", 1))
		sound_enabled = bool(data.get("sound_enabled", true))
		vibration_enabled = bool(data.get("vibration_enabled", true))
		music_enabled = bool(data.get("music_enabled", true))
		voice_enabled = bool(data.get("voice_enabled", true))
		guideline_enabled = bool(data.get("guideline_enabled", false))
		calm_mode_enabled = bool(data.get("calm_mode_enabled", false))
		theme_idx = int(data.get("theme_idx", 0))
		daily_puzzle_date = str(data.get("daily_puzzle_date", ""))
		daily_streak = int(data.get("daily_streak", 1))
		current_streak = int(data.get("current_streak", 1))
		best_streak = int(data.get("best_streak", 2))
		player_name = str(data.get("player_name", "Player123"))
		player_email = str(data.get("player_email", "player@example.com"))
		event_progress = int(data.get("event_progress", 3))
		event_max = int(data.get("event_max", 10))

func get_completed_levels_count() -> int:
	return completed_levels.size()

func get_total_stars() -> int:
	# Calculate total stars earned: each completed level awards up to 3 stars based on hearts
	var total = 0
	for k in completed_levels:
		var rec = completed_levels[k]
		total += int(rec.get("hearts", 3))
	# Default to at least 36 if early player or calculate based on count
	return maxi(total, completed_levels.size() * 3)

func advance_event_progress() -> void:
	if event_progress < event_max:
		event_progress += 1
		save_data()

func record_level_completion(level_id: int, moves: int, hearts: int) -> void:
	var id_str = str(level_id)
	var prev = completed_levels.get(id_str, {})
	var best_m = int(prev.get("best_moves", 999999))
	var best_h = int(prev.get("hearts", 0))

	completed_levels[id_str] = {
		"best_moves": mini(best_m, moves),
		"hearts": maxi(best_h, hearts)
	}

	if level_id >= highest_unlocked_level:
		highest_unlocked_level = level_id + 1

	current_level = level_id + 1
	save_data()

func is_level_completed(level_id: int) -> bool:
	return completed_levels.has(str(level_id))

func add_coins(amount: int) -> void:
	coins += amount
	save_data()

func spend_coins(amount: int) -> bool:
	if coins >= amount:
		coins -= amount
		save_data()
		return true
	return false

func reset_progress() -> void:
	highest_unlocked_level = 1
	completed_levels.clear()
	current_level = 1
	save_data()
