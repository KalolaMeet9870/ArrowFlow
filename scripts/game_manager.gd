class_name GameManager
extends Node

## Master Game Manager for Arrow Puzzle Game.
## Coordinates LevelManager, SaveManager, SoundManager, and game lifecycle state.

signal level_started(level_data: Dictionary)
signal level_completed(level_id: int, moves: int, hearts: int)
signal level_failed(level_id: int)

static var instance: GameManager

var current_level_id: int = 1
var current_level_data: Dictionary = {}

func _enter_tree() -> void:
	instance = self

func _ready() -> void:
	# Ensure foundational managers exist
	if SaveManager.instance == null:
		var sm = SaveManager.new()
		sm.name = "SaveManager"
		add_child(sm)

	if ThemeManager.instance == null:
		var tm = ThemeManager.new()
		tm.name = "ThemeManager"
		add_child(tm)

	if SoundManager.instance == null:
		var snd = SoundManager.new()
		snd.name = "SoundManager"
		add_child(snd)

	if LevelManager.instance == null:
		var lm = LevelManager.new()
		lm.name = "LevelManager"
		add_child(lm)

	if SaveManager.instance:
		current_level_id = SaveManager.instance.current_level

func start_level(level_id: int) -> Dictionary:
	current_level_id = maxi(1, level_id)
	if LevelManager.instance:
		current_level_data = LevelManager.instance.load_level(current_level_id)
	else:
		current_level_data = PuzzleGenerator.get_or_generate_level(current_level_id)

	level_started.emit(current_level_data)
	return current_level_data

func restart_current_level() -> Dictionary:
	return start_level(current_level_id)

func next_level() -> Dictionary:
	return start_level(current_level_id + 1)

func complete_level(moves: int, hearts: int) -> void:
	if SaveManager.instance:
		SaveManager.instance.record_level_completion(current_level_id, moves, hearts)
	level_completed.emit(current_level_id, moves, hearts)

func fail_level() -> void:
	level_failed.emit(current_level_id)
