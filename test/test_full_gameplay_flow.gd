extends SceneTree

func _init() -> void:
	print("--- Running Full End-to-End Acceptance Test ---")
	var scene = load("res://scenes/main/Main.tscn")
	var main_inst = scene.instantiate() as Main
	root.add_child(main_inst)

	# 1. Start at Home Screen
	var frames = 0
	while frames < 5:
		await process_frame
		frames += 1

	print("1. Home Screen loaded. Progress text: ", main_inst.home_screen.lbl_progress.text)

	# 2. Press Play to start current level
	main_inst.home_screen.play_pressed.emit()
	frames = 0
	while frames < 5:
		await process_frame
		frames += 1

	var cur_lvl = main_inst.game_manager.current_level_id
	print("2. GameScreen active. Level ID: %d, title: %s" % [cur_lvl, main_inst.game_screen.lbl_level_title.text])
	var board = main_inst.game_screen.board
	print("   Active arrows on board: %d" % board.active_arrows.size())

	# 3. Clear all arrows one by one
	print("3. Clearing board...")
	while board.active_arrows.size() > 0:
		var candidate: Arrow = null
		for a in board.active_arrows:
			if CollisionChecker.can_arrow_exit(a, board.active_arrows, board.grid_size):
				candidate = a
				break

		if candidate == null:
			printerr("No candidate free to exit!")
			quit(1)
			return

		print("   Tapping Arrow ID %d..." % candidate.arrow_id)
		board._on_arrow_tapped(candidate)

		# Wait for exit animation
		frames = 0
		while frames < 25:
			await process_frame
			frames += 1

	# Wait for final exit tween callback to trigger board_cleared
	frames = 0
	while frames < 30:
		await process_frame
		frames += 1

	print("   Board cleared! Remaining arrows: %d" % board.active_arrows.size())

	# 4. Verify navigation to LevelSelectScreen (Requirement 4)
	var lss = main_inst.level_select_screen
	print("4. LevelSelectScreen visible: %s, banner visible: %s, banner text: '%s'" % [lss.visible, lss.status_banner.visible, lss.lbl_status_banner.text])
	print("   Next level button text: '%s', disabled: %s" % [lss.btn_next_level.text, lss.btn_next_level.disabled])

	# 5. Verify SaveManager recorded progress
	var is_cleared = SaveManager.instance.is_level_completed(cur_lvl)
	print("5. Level %d marked completed in SaveManager: %s" % [cur_lvl, is_cleared])
	print("   Highest unlocked level: %d" % SaveManager.instance.highest_unlocked_level)

	if lss.visible and lss.status_banner.visible and not lss.btn_next_level.disabled and is_cleared:
		print("\n>>> FULL ACCEPTANCE TEST PASSED WITH 100% SUCCESS! <<<")
		quit(0)
	else:
		printerr("\n>>> ACCEPTANCE TEST FAILED! <<<")
		quit(1)
