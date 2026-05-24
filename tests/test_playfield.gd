extends GutTest
## Testet die Funktionalität der Playfield-Klasse (Spielschleife, Punkte, Level).

const PlayfieldClass = preload("res://scripts/Playfield.gd")
const GridClass = preload("res://scripts/Grid.gd")
const BlockClass = preload("res://scripts/Block.gd")
const SegmentClass = preload("res://scripts/Segment.gd")
const GameOverOverlayClass = preload("res://scripts/GameOverOverlay.gd")


func test_playfield_initialization() -> void:
	var playfield = PlayfieldClass.new()
	add_child(playfield)

	assert_not_null(playfield.grid, "Playfield should have initialized a Grid")
	assert_not_null(playfield.current_block, "Playfield should have spawned an initial block")
	assert_eq(
		playfield.current_block.grid_position, Vector2i(3, 0), "Spawn position should be (3, 0)"
	)
	assert_false(playfield._game_over, "Game should not be over initially")

	playfield.free()


func test_score_progression() -> void:
	var playfield = PlayfieldClass.new()
	add_child(playfield)

	# Watch signals
	watch_signals(playfield)

	# Add 1 row
	playfield._add_score(1)
	assert_eq(playfield._score, 1, "Score should be 1 for 1 row at level 1")
	assert_signal_emitted_with_parameters(playfield, "score_changed", [1, 1])

	# Add 4 rows
	playfield._add_score(4)
	assert_eq(playfield._score, 5, "Score should be 5")
	assert_signal_emitted_with_parameters(playfield, "score_changed", [5, 1])

	# Add 6 more rows to level up (total 11)
	playfield._add_score(6)
	assert_eq(playfield._level, 2, "Level should increase to 2")
	assert_eq(playfield._score, 11, "Score should be 11")
	assert_signal_emitted_with_parameters(playfield, "score_changed", [11, 2])

	playfield.free()


func test_difficulty_adjustment() -> void:
	var playfield = PlayfieldClass.new()
	add_child(playfield)

	assert_eq(playfield._fall_interval, 1.0, "Initial fall interval should be 1.0")

	playfield._level = 3
	playfield.update_difficulty()
	assert_eq(playfield._fall_interval, 0.8, "Level 3 fall interval should be 0.8")

	playfield._level = 11
	playfield.update_difficulty()
	assert_eq(playfield._fall_interval, 0.1, "Level 11 fall interval should be clamped to 0.1")

	playfield.free()


func test_block_movement() -> void:
	var playfield = PlayfieldClass.new()
	add_child(playfield)

	var initial_y = playfield.current_block.grid_position.y
	playfield.move_block_down()
	assert_eq(playfield.current_block.grid_position.y, initial_y + 1, "Block should move down by 1")

	var initial_x = playfield.current_block.grid_position.x
	playfield.move_block_horizontal(-1)
	assert_eq(playfield.current_block.grid_position.x, initial_x - 1, "Block should move left")

	playfield.move_block_horizontal(1)
	assert_eq(playfield.current_block.grid_position.x, initial_x, "Block should move right back")

	playfield.free()


func test_invalid_rows_not_cleared_and_no_score() -> void:
	var playfield = PlayfieldClass.new()
	add_child(playfield)

	# Watch signals
	watch_signals(playfield)

	# Prepare an invalid row at the bottom (row 19)
	# E.g. all cells filled with ISOLATED segments
	var grid = playfield.grid
	for c in range(GridClass.COLUMNS):
		grid.grid_data[19][c] = SegmentClass.new(SegmentClass.Type.ISOLATED, Color.RED)

	assert_eq(playfield._score, 0, "Score should be 0 initially")

	# Position current block so it collides/locks on moving down
	playfield.current_block.grid_position = Vector2i(3, 18)

	# Clear block segments so it locks nothing, keeping grid row intact
	for r in range(playfield.current_block.cells_data.size()):
		for c in range(playfield.current_block.cells_data[r].size()):
			playfield.current_block.cells_data[r][c] = null

	# Trigger move_block_down which will lock the block and trigger row detection
	playfield.move_block_down()

	# Since row 19 is invalid, it should NOT trigger press animation
	assert_false(playfield._is_animating_press, "Press animation should NOT start for invalid row")

	# The row should NOT be cleared (cells should not be null)
	for c in range(GridClass.COLUMNS):
		assert_not_null(grid.grid_data[19][c], "Row 19 should remain filled")

	# Score should still be 0
	assert_eq(playfield._score, 0, "Score should remain 0")

	playfield.free()


func test_valid_rows_trigger_press_and_score() -> void:
	var playfield = PlayfieldClass.new()
	add_child(playfield)

	# Watch signals
	watch_signals(playfield)

	# Prepare a valid crimp row at the bottom (row 19)
	var grid = playfield.grid
	for c in range(GridClass.COLUMNS):
		var type = SegmentClass.Type.BARE
		if c == 0 or c == 9:
			type = SegmentClass.Type.CRIMP_LUG
		grid.grid_data[19][c] = SegmentClass.new(type, Color.GREEN)

	assert_eq(playfield._score, 0, "Score should be 0 initially")

	# Position current block so it collides/locks on moving down
	playfield.current_block.grid_position = Vector2i(3, 18)

	# Clear block segments so it locks nothing, keeping grid row intact
	for r in range(playfield.current_block.cells_data.size()):
		for c in range(playfield.current_block.cells_data[r].size()):
			playfield.current_block.cells_data[r][c] = null

	# Trigger move_block_down which will lock the block and trigger row detection
	playfield.move_block_down()

	# Since valid row exists, press animation is triggered
	assert_true(
		playfield._is_animating_press, "Press animation should start, blocking input/movement"
	)

	# Let's wait for the press sequence to finish
	await wait_for_signal(playfield.crimp_press_completed, 2.0)

	assert_false(playfield._is_animating_press, "Press animation should have finished")
	# Row 19 should have been cleared (which shifts upper rows down, filling 19 with nulls or empty)
	assert_null(grid.grid_data[19][0], "Cleared row should have null cells at index 0")
	# Score should have increased by 1 (since 1 valid row was cleared)
	assert_eq(playfield._score, 1, "Score should be 1 after clearing 1 valid row")

	playfield.free()


func test_input_and_gravity_blocked_during_press() -> void:
	var playfield = PlayfieldClass.new()
	add_child(playfield)

	# Prepare a valid crimp row at row 19
	var grid = playfield.grid
	for c in range(GridClass.COLUMNS):
		var type = SegmentClass.Type.BARE
		if c == 0 or c == 9:
			type = SegmentClass.Type.CRIMP_LUG
		grid.grid_data[19][c] = SegmentClass.new(type, Color.GREEN)

	# Lock block to trigger press animation
	playfield.current_block.grid_position = Vector2i(3, 18)

	# Clear block segments so it locks nothing, keeping grid row intact
	for r in range(playfield.current_block.cells_data.size()):
		for c in range(playfield.current_block.cells_data[r].size()):
			playfield.current_block.cells_data[r][c] = null

	playfield.move_block_down()

	assert_true(playfield._is_animating_press, "Should be animating press")

	# During animation, block is freed, current_block is null (until animation
	# completes and new block spawns)
	var old_fall_timer = playfield._fall_timer
	playfield._process(0.5)
	assert_eq(
		playfield._fall_timer,
		old_fall_timer,
		"process should not increment fall_timer during press animation"
	)

	# Let's create a temporary block and assign it
	var temp_block = BlockClass.new()
	playfield.add_child(temp_block)
	temp_block.initialize(0)
	temp_block.grid_position = Vector2i(3, 5)
	playfield.current_block = temp_block

	var initial_pos = temp_block.grid_position
	playfield.move_block_horizontal(1)
	assert_eq(temp_block.grid_position, initial_pos, "move_block_horizontal should be blocked")

	playfield.move_block_down()
	assert_eq(temp_block.grid_position, initial_pos, "move_block_down should be blocked")

	playfield.rotate_block()
	assert_eq(temp_block.grid_position, initial_pos, "rotate_block should be blocked")

	playfield.hard_drop()
	assert_eq(temp_block.grid_position, initial_pos, "hard_drop should be blocked")

	# Wait for animation to finish
	await wait_for_signal(playfield.crimp_press_completed, 2.0)

	playfield.free()


func test_shield_activation_and_decay() -> void:
	var playfield = PlayfieldClass.new()
	add_child(playfield)

	assert_false(playfield.is_shield_active(), "Shield should be inactive initially")
	playfield.activate_vde_shield()
	assert_true(playfield.is_shield_active(), "Shield should be active after activation")
	assert_eq(playfield._shield_time_left, 20.0, "Shield time left should be 20.0")

	# Decay shield
	playfield._process(5.0)
	assert_true(playfield.is_shield_active(), "Shield should still be active")
	assert_eq(playfield._shield_time_left, 15.0, "Shield time should decay")

	playfield._process(16.0)
	assert_false(playfield.is_shield_active(), "Shield should deactivate after 20s")

	playfield.free()


func test_shield_game_over_prevention() -> void:
	var playfield = PlayfieldClass.new()
	add_child(playfield)

	# Put segments at the bottom so we can check if they are cleared
	var grid = playfield.grid
	for r in range(15, 20):
		grid.grid_data[r][0] = SegmentClass.new(SegmentClass.Type.BARE, Color.RED)

	# Put segments at spawn position to force immediate collision
	# A spawned block has its center at column 3, row 0, 1, 2 etc.
	# We can just fill rows 0, 1, 2 with segments
	for r in range(3):
		for c in range(GridClass.COLUMNS):
			grid.grid_data[r][c] = SegmentClass.new(SegmentClass.Type.BARE, Color.RED)

	# Activate shield
	playfield.activate_vde_shield()

	# Call spawn_new_block which will collide immediately
	playfield.spawn_new_block()

	# Verify Game Over was prevented and shield is consumed
	assert_false(playfield._game_over, "Game Over should be prevented by shield")
	assert_false(playfield.is_shield_active(), "Shield should be consumed")

	# Verify bottom 5 rows are cleared (all cells should be null)
	for r in range(15, 20):
		for c in range(GridClass.COLUMNS):
			assert_null(grid.grid_data[r][c], "Bottom 5 rows should be cleared")

	playfield.free()


func test_camera_shake_does_not_crash() -> void:
	var playfield = PlayfieldClass.new()
	add_child(playfield)

	# Directly trigger camera shake (camera node is present via scene/onready)
	# Since new() doesn't instantiate children from scene, let's create a camera
	# manually if it's null or we can instantiate from tscn.
	# Let's instantiate from playfield.tscn to test real scene structure.
	playfield.free()

	var scene = load("res://scenes/playfield.tscn")
	playfield = scene.instantiate()
	add_child(playfield)

	# Check that camera is present
	assert_not_null(playfield._camera, "Camera2D should be in playfield scene")
	assert_not_null(playfield._shield_overlay, "ShieldOverlay should be in scene")
	assert_not_null(playfield._sfx_laser, "SfxLaser should be in scene")
	assert_not_null(playfield._sfx_cut, "SfxCut should be in scene")

	# Trigger camera shake
	playfield._trigger_camera_shake()
	# The tween is active, we just check it runs without crash.
	# We can also check shield activation visibility
	playfield.activate_vde_shield()
	assert_true(playfield._shield_overlay.visible, "Shield overlay visible when active")

	playfield.free()


func test_expo_timer_countdown() -> void:
	SettingsManager.current_mode = SettingsManager.GameMode.EXPO
	SettingsManager.expo_round_duration = 180.0

	var playfield = PlayfieldClass.new()
	add_child(playfield)

	assert_eq(playfield._time_left, 180.0, "Time left should be initialized to 180s")

	watch_signals(playfield)
	playfield._process(10.0)

	assert_eq(playfield._time_left, 170.0, "Time left should decrease to 170s after 10s delta")
	assert_signal_emitted(playfield, "timer_updated")

	playfield.free()
	# Restore Settings
	SettingsManager.current_mode = SettingsManager.GameMode.CLASSIC


func test_timeout_triggers_game_over() -> void:
	SettingsManager.current_mode = SettingsManager.GameMode.EXPO
	SettingsManager.expo_round_duration = 5.0

	var playfield = PlayfieldClass.new()
	add_child(playfield)

	watch_signals(playfield)
	playfield._process(6.0)

	assert_true(playfield._game_over, "Timeout should trigger game over")
	assert_signal_emitted(playfield, "game_over_triggered")

	# Find the GameOverOverlay child
	var overlay = null
	for child in playfield.get_children():
		if child.get_script() == GameOverOverlayClass:
			overlay = child
			break
	assert_not_null(overlay, "GameOverOverlay should be instantiated on timeout")
	if overlay != null:
		assert_eq(overlay._title_label.text, "ZEIT ABGELAUFEN!", "Title should indicate timeout")

	playfield.free()
	SettingsManager.current_mode = SettingsManager.GameMode.CLASSIC
	SettingsManager.expo_round_duration = 180.0


func test_spawn_collision_triggers_game_over() -> void:
	SettingsManager.current_mode = SettingsManager.GameMode.CLASSIC

	var playfield = PlayfieldClass.new()
	add_child(playfield)

	# Put segments at spawn position to force immediate collision
	var grid = playfield.grid
	for r in range(3):
		for c in range(GridClass.COLUMNS):
			grid.grid_data[r][c] = SegmentClass.new(SegmentClass.Type.BARE, Color.RED)

	watch_signals(playfield)
	playfield.spawn_new_block()

	assert_true(playfield._game_over, "Spawn collision should trigger game over")
	assert_signal_emitted(playfield, "game_over_triggered")

	# Find the GameOverOverlay child
	var overlay = null
	for child in playfield.get_children():
		if child.get_script() == GameOverOverlayClass:
			overlay = child
			break
	assert_not_null(overlay, "GameOverOverlay should be instantiated on spawn collision")
	if overlay != null:
		assert_eq(overlay._title_label.text, "GAME OVER", "Title should indicate game over")

	playfield.free()


func test_game_over_overlay_initialization() -> void:
	var scene = load("res://scenes/game_over_overlay.tscn")
	var overlay = scene.instantiate() as GameOverOverlayClass
	add_child(overlay)

	overlay.initialize(250, 5, false)
	assert_eq(overlay._title_label.text, "GAME OVER")
	assert_string_contains(overlay._score_label.text, "250")
	assert_string_contains(overlay._level_label.text, "5")

	overlay.initialize(120, 2, true)
	assert_eq(overlay._title_label.text, "ZEIT ABGELAUFEN!")
	assert_string_contains(overlay._score_label.text, "120")
	assert_string_contains(overlay._level_label.text, "2")

	watch_signals(overlay)
	overlay._on_ContinueButton_pressed()
	assert_signal_emitted(overlay, "name_input_requested")

	# Since queue_free is called, let's wait a frame or check that it's queued for deletion
	assert_true(overlay.is_queued_for_deletion())


func test_level_progression_signal_and_background_change() -> void:
	var playfield = PlayfieldClass.new()
	add_child(playfield)

	watch_signals(playfield)

	# Initial level theme is Level 1 "Werkstatt"
	assert_eq(playfield._level, 1)
	var theme1 = playfield.LEVEL_THEMES[1]
	var bg_gradient = playfield._bg_rect.texture.gradient
	assert_eq(bg_gradient.get_color(0), theme1["color_start"])

	# Trigger level up to level 2 by clearing 10 rows
	playfield._add_score(10)

	assert_eq(playfield._level, 2)
	assert_signal_emitted_with_parameters(playfield, "level_up", [2, "Baustelle"])

	# Let's check that update_difficulty adjusted fall interval to 0.9s
	assert_eq(playfield._fall_interval, 0.9)

	# We can't immediately assert the color matches theme2 start color because of the tween,
	# but we can verify immediate state by checking LEVEL_THEMES lookup.
	var theme2 = playfield.LEVEL_THEMES[2]
	assert_eq(theme2["name"], "Baustelle")

	playfield.free()
