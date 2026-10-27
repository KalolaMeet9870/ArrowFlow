class_name LevelManager
extends Node

## Coordinates level lifecycle, progression, and procedural level retrieval.

signal level_loaded(level_id: int, level_data: Dictionary)

static var instance: LevelManager

var current_level_id: int = 1
var current_level_data: Dictionary = {}
var level_cache: Dictionary = {} # level_id -> level_data

func _enter_tree() -> void:
	instance = self

func _ready() -> void:
	if SaveManager.instance:
		current_level_id = SaveManager.instance.current_level

func load_level(level_id: int) -> Dictionary:
	current_level_id = maxi(1, level_id)
	if level_cache.has(current_level_id):
		current_level_data = level_cache[current_level_id]
	else:
		current_level_data = PuzzleGenerator.get_or_generate_level(current_level_id)
		level_cache[current_level_id] = current_level_data

	level_loaded.emit(current_level_id, current_level_data)
	return current_level_data

func restart_current_level() -> Dictionary:
	return load_level(current_level_id)

func load_next_level() -> Dictionary:
	return load_level(current_level_id + 1)

func load_prev_level() -> Dictionary:
	return load_level(maxi(1, current_level_id - 1))
