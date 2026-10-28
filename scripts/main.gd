class_name Main
extends Control

## Root Scene Controller for ArrowFlow ("Clear The Path").
## Coordinates all 12 mobile app screens, AdMob monetization, Level Selection flow,
## and game progression.

@export var splash_screen_scene: PackedScene = preload("res://scenes/screens/SplashScreen.tscn")
@export var home_screen_scene: PackedScene = preload("res://scenes/screens/HomeScreen.tscn")
@export var game_screen_scene: PackedScene = preload("res://scenes/screens/GameScreen.tscn")
@export var level_complete_scene: PackedScene = preload("res://scenes/screens/LevelComplete.tscn")
@export var level_failed_scene: PackedScene = preload("res://scenes/screens/LevelFailed.tscn")
@export var settings_screen_scene: PackedScene = preload("res://scenes/screens/SettingsScreen.tscn")
@export var level_select_screen_scene: PackedScene = preload("res://scenes/screens/LevelSelectScreen.tscn")

@export var daily_challenge_scene: PackedScene = preload("res://scenes/screens/DailyChallengeScreen.tscn")
@export var event_screen_scene: PackedScene = preload("res://scenes/screens/EventScreen.tscn")
@export var profile_screen_scene: PackedScene = preload("res://scenes/screens/ProfileScreen.tscn")
@export var how_to_play_scene: PackedScene = preload("res://scenes/screens/HowToPlayScreen.tscn")
@export var theme_selection_scene: PackedScene = preload("res://scenes/screens/ThemeSelectionScreen.tscn")

const DailyChallengeScreenClass = preload("res://scripts/daily_challenge_screen.gd")
const EventScreenClass = preload("res://scripts/event_screen.gd")
const ProfileScreenClass = preload("res://scripts/profile_screen.gd")
const HowToPlayScreenClass = preload("res://scripts/how_to_play_screen.gd")
const ThemeSelectionScreenClass = preload("res://scripts/theme_selection_screen.gd")

var game_manager: GameManager
var splash_screen: SplashScreen
var home_screen: HomeScreen
var game_screen: GameScreen
var level_complete_screen: LevelCompleteScreen
var level_failed_screen: LevelFailedScreen
var settings_screen: SettingsScreen
var level_select_screen: LevelSelectScreen
var daily_challenge_screen: Control
var event_screen: Control
var profile_screen: Control
var how_to_play_screen: Control
var theme_selection_screen: Control

var _previous_screen_before_settings: String = "home"
var _previous_screen_before_theme: String = "settings"
var _previous_screen_before_tutorial: String = "settings"

func _ready() -> void:
	# Enforce portrait orientation on all mobile devices
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

	# 3. Instantiate and wire all 12 screens
	_setup_screens()

	# 4. Start at SplashScreen (or HomeScreen during headless test executions)
	if DisplayServer.get_name() == "headless":
		show_home_screen()
	else:
		show_splash_screen()

func _setup_screens() -> void:
	# Screen 1: Splash Screen
	splash_screen = splash_screen_scene.instantiate() as SplashScreen
	add_child(splash_screen)
	splash_screen.splash_finished.connect(func():
		show_home_screen()
	)

	# Screen 2: Home Screen
	home_screen = home_screen_scene.instantiate() as HomeScreen
	add_child(home_screen)
	home_screen.play_pressed.connect(_on_play_pressed)
	home_screen.daily_puzzle_pressed.connect(show_daily_challenge_screen)
	home_screen.event_pressed.connect(show_event_screen)
	home_screen.profile_pressed.connect(show_profile_screen)
	home_screen.settings_pressed.connect(_on_settings_pressed)
	home_screen.level_select_pressed.connect(func(): show_level_select_screen(-1))
	home_screen.hide()

	# Screen 3: Level Selection Screen
	level_select_screen = level_select_screen_scene.instantiate() as LevelSelectScreen
	add_child(level_select_screen)
	level_select_screen.level_selected.connect(show_game_screen)
	level_select_screen.next_level_pressed.connect(show_game_screen)
	level_select_screen.back_pressed.connect(show_home_screen)
	level_select_screen.hide()

	# Screen 4: Gameplay Screen
	game_screen = game_screen_scene.instantiate() as GameScreen
	add_child(game_screen)
	game_screen.home_requested.connect(show_home_screen)
	game_screen.settings_requested.connect(func(): _open_settings("game"))
	game_screen.theme_selection_requested.connect(func(): show_theme_selection_screen("game"))
	game_screen.level_completed.connect(_on_level_completed)
	game_screen.level_failed.connect(_on_level_failed)
	game_screen.level_select_requested.connect(func(): show_level_select_screen(-1))
	game_screen.hide()

	# Screen 5: Level Complete Dialog
	level_complete_screen = level_complete_scene.instantiate() as LevelCompleteScreen
	add_child(level_complete_screen)
	level_complete_screen.next_level_requested.connect(_on_next_level_requested)
	level_complete_screen.replay_requested.connect(_on_replay_requested)
	level_complete_screen.home_requested.connect(show_home_screen)
	level_complete_screen.hide()

	# Screen 6: Level Failed Dialog
	level_failed_screen = level_failed_scene.instantiate() as LevelFailedScreen
	add_child(level_failed_screen)
	level_failed_screen.retry_requested.connect(_on_replay_requested)
	level_failed_screen.extra_life_requested.connect(_on_extra_life_requested)
	level_failed_screen.home_requested.connect(show_home_screen)
	level_failed_screen.hide()

	# Screen 7: Daily Challenge Screen
	daily_challenge_screen = daily_challenge_scene.instantiate()
	add_child(daily_challenge_screen)
	daily_challenge_screen.start_pressed.connect(_on_daily_puzzle_pressed)
	daily_challenge_screen.back_pressed.connect(show_home_screen)
	daily_challenge_screen.hide()

	# Screen 8: Event Screen (Countryside Dash)
	event_screen = event_screen_scene.instantiate()
	add_child(event_screen)
	event_screen.play_pressed.connect(_on_event_play_pressed)
	event_screen.back_pressed.connect(show_home_screen)
	event_screen.hide()

	# Screen 9: Profile Screen
	profile_screen = profile_screen_scene.instantiate()
	add_child(profile_screen)
	profile_screen.back_pressed.connect(show_home_screen)
	profile_screen.leaderboard_requested.connect(func():
		show_home_screen()
		if home_screen and home_screen.emerald_league_popup:
			home_screen.emerald_league_popup.show_popup()
	)
	profile_screen.hide()

	# Screen 10: Settings Screen
	settings_screen = settings_screen_scene.instantiate() as SettingsScreen
	add_child(settings_screen)
	settings_screen.back_pressed.connect(_on_settings_back)
	settings_screen.theme_requested.connect(func(): show_theme_selection_screen("settings"))
	settings_screen.how_to_play_requested.connect(func(): show_how_to_play_screen("settings"))
	settings_screen.hide()

	# Screen 11: How to Play Screen
	how_to_play_screen = how_to_play_scene.instantiate()
	add_child(how_to_play_screen)
	how_to_play_screen.back_pressed.connect(_on_how_to_play_back)
	how_to_play_screen.got_it_pressed.connect(_on_how_to_play_back)
	how_to_play_screen.hide()

	# Screen 12: Theme Selection Screen
	theme_selection_screen = theme_selection_scene.instantiate()
	add_child(theme_selection_screen)
	theme_selection_screen.back_pressed.connect(_on_theme_selection_back)
	theme_selection_screen.hide()

func _hide_all_screens() -> void:
	if splash_screen and is_instance_valid(splash_screen):
		splash_screen.hide()
	if home_screen:
		home_screen.hide()
	if level_select_screen:
		level_select_screen.hide()
	if game_screen:
		game_screen.hide()
	if level_complete_screen:
		level_complete_screen.hide()
	if level_failed_screen:
		level_failed_screen.hide()
	if daily_challenge_screen:
		daily_challenge_screen.hide()
	if event_screen:
		event_screen.hide()
	if profile_screen:
		profile_screen.hide()
	if settings_screen:
		settings_screen.hide()
	if how_to_play_screen:
		how_to_play_screen.hide()
	if theme_selection_screen:
		theme_selection_screen.hide()

func show_splash_screen() -> void:
	_hide_all_screens()
	if splash_screen and is_instance_valid(splash_screen):
		splash_screen.show()

func show_home_screen() -> void:
	_hide_all_screens()

	# Flag gameplay inactive so App Open ads do not interrupt gameplay
	if AdMobManager.instance:
		AdMobManager.instance.set_gameplay_active(false)
		AdMobManager.instance.show_banner()

	if home_screen:
		home_screen.show()
		home_screen.refresh_progress()

func show_level_select_screen(completed_id: int = -1) -> void:
	_hide_all_screens()

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

	_hide_all_screens()

	# Flag gameplay active and hide banner to give player a clean canvas
	if AdMobManager.instance:
		AdMobManager.instance.set_gameplay_active(true)
		AdMobManager.instance.hide_banner()

	var lvl_data = game_manager.start_level(level_id)
	if game_screen:
		game_screen.show()
		game_screen.start_level(lvl_data)

func show_daily_challenge_screen() -> void:
	_hide_all_screens()
	if AdMobManager.instance:
		AdMobManager.instance.set_gameplay_active(false)
		AdMobManager.instance.hide_banner()
	if daily_challenge_screen:
		daily_challenge_screen.show()

func show_event_screen() -> void:
	_hide_all_screens()
	if AdMobManager.instance:
		AdMobManager.instance.set_gameplay_active(false)
		AdMobManager.instance.hide_banner()
	if event_screen:
		event_screen.show()
		event_screen.refresh_event_progress()

func show_profile_screen() -> void:
	_hide_all_screens()
	if AdMobManager.instance:
		AdMobManager.instance.set_gameplay_active(false)
		AdMobManager.instance.hide_banner()
	if profile_screen:
		profile_screen.show()
		profile_screen.refresh_profile()

func show_how_to_play_screen(from_screen: String = "settings") -> void:
	_previous_screen_before_tutorial = from_screen
	_hide_all_screens()
	if AdMobManager.instance:
		AdMobManager.instance.set_gameplay_active(false)
		AdMobManager.instance.hide_banner()
	if how_to_play_screen:
		how_to_play_screen.show()

func _on_how_to_play_back() -> void:
	if _previous_screen_before_tutorial == "home":
		show_home_screen()
	else:
		_open_settings(_previous_screen_before_settings)

func show_theme_selection_screen(from_screen: String = "settings") -> void:
	_previous_screen_before_theme = from_screen
	_hide_all_screens()
	if AdMobManager.instance:
		AdMobManager.instance.set_gameplay_active(false)
		AdMobManager.instance.hide_banner()
	if theme_selection_screen:
		theme_selection_screen.show()
		theme_selection_screen.refresh_selection()

func _on_theme_selection_back() -> void:
	if _previous_screen_before_theme == "game" and game_screen:
		_hide_all_screens()
		game_screen.show()
	else:
		_open_settings(_previous_screen_before_settings)

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
	_hide_all_screens()
	if AdMobManager.instance:
		AdMobManager.instance.set_gameplay_active(true)
		AdMobManager.instance.hide_banner()
	if game_screen:
		game_screen.show()
		game_screen.start_level(daily_level)

func _on_event_play_pressed() -> void:
	# Launch special event challenge puzzle
	var event_seed = 424242
	var event_level = PuzzleGenerator.generate_procedural_level(
		888,
		"Countryside Dash",
		"Medium",
		Vector2i(6, 6),
		14,
		event_seed
	)
	_hide_all_screens()
	if AdMobManager.instance:
		AdMobManager.instance.set_gameplay_active(true)
		AdMobManager.instance.hide_banner()
	if game_screen:
		game_screen.show()
		game_screen.start_level(event_level)

func _on_settings_pressed() -> void:
	_open_settings("home")

func _open_settings(from_screen: String = "home") -> void:
	_previous_screen_before_settings = from_screen
	_hide_all_screens()
	if AdMobManager.instance:
		AdMobManager.instance.set_gameplay_active(false)
		AdMobManager.instance.hide_banner()
	if settings_screen:
		settings_screen.show()
		settings_screen.apply_theme(ThemeManager.instance.get_current_theme() if ThemeManager.instance else {})

func _on_settings_back() -> void:
	if _previous_screen_before_settings == "game" and game_screen:
		_hide_all_screens()
		game_screen.show()
		if AdMobManager.instance:
			AdMobManager.instance.set_gameplay_active(true)
			AdMobManager.instance.hide_banner()
	elif _previous_screen_before_settings == "level_select" and level_select_screen:
		_hide_all_screens()
		level_select_screen.show()
	else:
		show_home_screen()

func _on_level_completed(level_id: int, moves: int, hearts: int) -> void:
	# 1. Persist level completion in SaveManager & GameManager
	game_manager.complete_level(moves, hearts)
	if SaveManager.instance:
		SaveManager.instance.add_coins(10)
		if level_id == 888:
			SaveManager.instance.advance_event_progress()

	# 2. Present celebratory Level Complete screen on top of gameplay
	if level_complete_screen:
		level_complete_screen.display_completion(level_id, moves, hearts)

func _on_level_failed(level_id: int) -> void:
	game_manager.fail_level()
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
