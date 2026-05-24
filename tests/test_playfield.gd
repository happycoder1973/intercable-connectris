extends GutTest
## Testet die Funktionalität der Playfield-Klasse (Spielschleife, Punkte, Level).

const PlayfieldClass = preload("res://scripts/Playfield.gd")
const GridClass = preload("res://scripts/Grid.gd")
const BlockClass = preload("res://scripts/Block.gd")


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
	assert_eq(playfield._score, 100, "Score should be 100 for 1 row at level 1")
	assert_signal_emitted_with_parameters(playfield, "score_changed", [100, 1])

	# Add 4 rows (Tetris!)
	playfield._add_score(4)
	assert_eq(playfield._score, 900, "Score should be 900")
	assert_signal_emitted_with_parameters(playfield, "score_changed", [900, 1])

	# Add 6 more rows to level up
	playfield._add_score(6)
	assert_eq(playfield._level, 2, "Level should increase to 2")
	assert_eq(playfield._score, 2100, "Score should be 2100")
	assert_signal_emitted_with_parameters(playfield, "score_changed", [2100, 2])

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
