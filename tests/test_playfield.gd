extends GutTest
## Testet die Funktionalität der Playfield-Klasse (Spielschleife, Punkte, Level).

const PlayfieldClass = preload("res://scripts/Playfield.gd")
const GridClass = preload("res://scripts/Grid.gd")
const BlockClass = preload("res://scripts/Block.gd")
const SegmentClass = preload("res://scripts/Segment.gd")


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
