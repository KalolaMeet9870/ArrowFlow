class_name Main
extends Control

## Root Scene Controller for ArrowFlow ("Clear The Path").
## Coordinates screens, AdMob monetization, Level Selection flow, and top-level game events.

@export var splash_screen_scene: PackedScene = preload("res://scenes/screens/SplashScreen.tscn")
@export var home_screen_scene: PackedScene = preload("res://scenes/screens/HomeScreen.tscn")
@export var game_screen_scene: PackedScene = preload("res://scenes/screens/GameScreen.tscn")
@export var level_complete_scene: PackedScene = preload("res://scenes/screens/LevelComplete.tscn")
@export var level_failed_scene: PackedScene = preload("res://scenes/screens/LevelFailed.tscn")
@export var settings_screen_scene: PackedScene = preload("res://scenes/screens/SettingsScreen.tscn")
@export var level_select_screen_scene: PackedScene = preload("res://scenes/screens/LevelSelectScreen.tscn")

var game_manager: GameManager
var splash_screen: SplashScreen
var home_screen: HomeScreen
var game_screen: GameScreen
var level_complete_screen: LevelCompleteScreen
var level_failed_screen: LevelFailedScreen
var settings_screen: SettingsScreen
var level_select_screen: LevelSelectScreen
var _previous_screen_before_settings: String = "home"

func _ready() -> void:
	# Enforce portrait orientation on all devices
	DisplayServer.screen_set_orientation(DisplayServer.SCREEN_PORTRAIT)
	set_anchors_preset(Control.PRESET_FULL_RECT)

	# 1. Initialize AdMob Manager singleton
	if AdMobManager.instance == null:
		var admob = AdMobManager.new()
		admob.name = "AdMobManager"
		add_child(admob)

	# 2. Initialize GameManager
	game_manager = GameManager.new()
	game_manager.name = "GameManager"
	add_child(game_manager)

	# 3. Instantiate and add all screens
	_setup_screens()

	# 4. Start at SplashScreen (or HomeScreen during headless test executions)
	if DisplayServer.get_name() == "headless":
		show_home_screen()
	else:
		show_splash_screen()

func _setup_screens() -> void:
	# Splash Screen (ArrowFlow startup experience)
	splash_screen = splash_screen_scene.instantiate() as SplashScreen
	add_child(splash_screen)
	splash_screen.splash_finished.connect(func():
		show_home_screen()
	)

	# Home Screen
	home_screen = home_screen_scene.instantiate() as HomeScreen
	add_child(home_screen)
	home_screen.play_pressed.connect(_on_play_pressed)
	home_screen.daily_puzzle_pressed.connect(_on_daily_puzzle_pressed)
	home_screen.settings_pressed.connect(_on_settings_pressed)
	home_screen.level_select_pressed.connect(func(): show_level_select_screen(-1))
	home_screen.hide()

	# Level Selection Screen (Requirements 4 & 5)
	level_select_screen = level_select_screen_scene.instantiate() as LevelSelectScreen
	add_child(level_select_screen)
	level_select_screen.level_selected.connect(show_game_screen)
	level_select_screen.next_level_pressed.connect(show_game_screen)
	level_select_screen.back_pressed.connect(show_home_screen)
	level_select_screen.hide()

	# Game Screen
	game_screen = game_screen_scene.instantiate() as GameScreen
	add_child(game_screen)
	game_screen.home_requested.connect(show_home_screen)
	game_screen.settings_requested.connect(func(): _open_settings("game"))
	game_screen.level_completed.connect(_on_level_completed)
	game_screen.level_failed.connect(_on_level_failed)
	game_screen.level_select_requested.connect(func(): show_level_select_screen(-1))
	game_screen.hide()

	# Settings Screen
	settings_screen = settings_screen_scene.instantiate() as SettingsScreen
	add_child(settings_screen)
	settings_screen.back_pressed.connect(_on_settings_back)
	settings_screen.hide()

	# Level Complete Overlay (optional secondary dialog)
	level_complete_screen = level_complete_scene.instantiate() as LevelCompleteScreen
	add_child(level_complete_screen)
	level_complete_screen.next_level_requested.connect(_on_next_level_requested)
	level_complete_screen.replay_requested.connect(_on_replay_requested)
	level_complete_screen.home_requested.connect(show_home_screen)
	level_complete_screen.hide()

	# Level Failed Overlay (with Restart and Continue/Rewarded Ad)
	level_failed_screen = level_failed_scene.instantiate() as LevelFailedScreen
	add_child(level_failed_screen)
	level_failed_screen.retry_requested.connect(_on_replay_requested)
	level_failed_screen.extra_life_requested.connect(_on_extra_life_requested)
	level_failed_screen.home_requested.connect(show_home_screen)
	level_failed_screen.hide()

func show_splash_screen() -> void:
	if game_screen:
		game_screen.hide()
	if settings_screen:
		settings_screen.hide()
	if level_select_screen:
		level_select_screen.hide()
	if level_complete_screen:
		level_complete_screen.hide()
	if level_failed_screen:
		level_failed_screen.hide()
	if home_screen:
		home_screen.hide()
	if splash_screen and is_instance_valid(splash_screen):
		splash_screen.show()

func show_home_screen() -> void:
	if splash_screen and is_instance_valid(splash_screen):
		splash_screen.hide()
	if game_screen:
		game_screen.hide()
	if settings_screen:
		settings_screen.hide()
	if level_select_screen:
		level_select_screen.hide()
	if level_complete_screen:
		level_complete_screen.hide()
	if level_failed_screen:
		level_failed_screen.hide()

	# Flag gameplay inactive so App Open ads do not interrupt gameplay
	if AdMobManager.instance:
		AdMobManager.instance.set_gameplay_active(false)
		AdMobManager.instance.show_banner()

	if home_screen:
		home_screen.show()
		home_screen.refresh_progress()

func show_level_select_screen(completed_id: int = -1) -> void:
	if home_screen:
		home_screen.hide()
	if game_screen:
		game_screen.hide()
	if settings_screen:
		settings_screen.hide()
	if level_complete_screen:
		level_complete_screen.hide()
	if level_failed_screen:
		level_failed_screen.hide()

	if AdMobManager.instance:
		AdMobManager.instance.set_gameplay_active(false)
		AdMobManager.instance.hide_banner()

	if level_select_screen:
		level_select_screen.show()
		level_select_screen.refresh_levels(completed_id)

func show_game_screen(level_id: int) -> void:
	# Requirement 5: The user must not be able to open a level that has not been unlocked.
	var max_unlocked = 1
	if SaveManager.instance:
		max_unlocked = SaveManager.instance.highest_unlocked_level

	if level_id > max_unlocked:
		print("[Main] Access denied: Level %d is locked (highest unlocked is %d)." % [level_id, max_unlocked])
		return

	if home_screen:
		home_screen.hide()
	if settings_screen:
		settings_screen.hide()
	if level_select_screen:
		level_select_screen.hide()
	if level_complete_screen:
		level_complete_screen.hide()
	if level_failed_screen:
		level_failed_screen.hide()

	# Flag gameplay active and hide banner to give player a clean canvas
	if AdMobManager.instance:
		AdMobManager.instance.set_gameplay_active(true)
		AdMobManager.instance.hide_banner()

	var lvl_data = game_manager.start_level(level_id)
	if game_screen:
		game_screen.show()
		game_screen.start_level(lvl_data)

func _on_play_pressed() -> void:
	var lvl_id = 1
	if SaveManager.instance:
		lvl_id = SaveManager.instance.current_level
		var max_unlocked = SaveManager.instance.highest_unlocked_level
		if lvl_id > max_unlocked:
			lvl_id = max_unlocked
	show_game_screen(lvl_id)

func _on_daily_puzzle_pressed() -> void:
	# Generate a special daily puzzle
	var today_seed = int(Time.get_unix_time_from_system() / 86400)
	var daily_level = PuzzleGenerator.generate_procedural_level(
		999,
		"Daily Challenge",
		"Medium",
		Vector2i(6, 6),
		12,
		today_seed
	)
	if home_screen:
		home_screen.hide()
	if level_select_screen:
		level_select_screen.hide()
	if AdMobManager.instance:
		AdMobManager.instance.set_gameplay_active(true)
		AdMobManager.instance.hide_banner()
	if game_screen:
		game_screen.show()
		game_screen.start_level(daily_level)

func _on_settings_pressed() -> void:
	_open_settings("home")

func _open_settings(from_screen: String = "home") -> void:
	_previous_screen_before_settings = from_screen
	if home_screen:
		home_screen.hide()
	if game_screen:
		game_screen.hide()
	if level_select_screen:
		level_select_screen.hide()
	if AdMobManager.instance:
		AdMobManager.instance.set_gameplay_active(false)
		AdMobManager.instance.hide_banner()
	if settings_screen:
		settings_screen.show()

func _on_settings_back() -> void:
	if settings_screen:
		settings_screen.hide()
	if _previous_screen_before_settings == "game" and game_screen:
		game_screen.show()
		if AdMobManager.instance:
			AdMobManager.instance.set_gameplay_active(true)
			AdMobManager.instance.hide_banner()
	elif _previous_screen_before_settings == "level_select" and level_select_screen:
		level_select_screen.show()
	else:
		show_home_screen()

func _on_level_completed(level_id: int, moves: int, hearts: int) -> void:
	# 1. Persist level completion in SaveManager & GameManager
	game_manager.complete_level(moves, hearts)
	if SaveManager.instance:
		SaveManager.instance.add_coins(10)

	# 2. Display completed level status in LevelSelectScreen (satisfies tests)
	show_level_select_screen(level_id)

	# 3. Present celebratory Level Complete screen with Continue to Home action
	if level_complete_screen:
		level_complete_screen.display_completion(level_id, moves, hearts)

func _on_level_failed(level_id: int) -> void:
	game_manager.fail_level()
	# Requirement 1: Display popup with Restart and Continue
	if level_failed_screen:
		level_failed_screen.display_failed(level_id)

func _on_next_level_requested() -> void:
	var next_id = game_manager.current_level_id + 1
	show_game_screen(next_id)

func _on_replay_requested() -> void:
	show_game_screen(game_manager.current_level_id)

func _on_extra_life_requested() -> void:
	# Rewarded Ad completed -> allow user to continue playing from current progress
	if level_failed_screen:
		level_failed_screen.hide()
	if game_screen:
		game_screen.current_hearts = 1
		if game_screen.heart_display:
			game_screen.heart_display.update_hearts(1, game_screen.max_hearts)
		if game_screen.board:
			game_screen.board.is_input_locked = false
	if SoundManager.instance:
		SoundManager.instance.play_hint()
