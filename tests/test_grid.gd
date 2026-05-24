extends GutTest
## Testet die Funktionalität der Grid-Klasse (Spielfeld-Gitter).

const GridClass = preload("res://scripts/Grid.gd")
const BlockClass = preload("res://scripts/Block.gd")
const SegmentClass = preload("res://scripts/Segment.gd")


func test_grid_initialization() -> void:
	var grid = GridClass.new()
	grid._init_grid()
	assert_eq(grid.grid_data.size(), GridClass.ROWS, "Grid should have 20 rows")
	for r in range(GridClass.ROWS):
		assert_eq(grid.grid_data[r].size(), GridClass.COLUMNS, "Each row should have 10 columns")
		for c in range(GridClass.COLUMNS):
			assert_null(grid.grid_data[r][c], "Cells should be initialized to null")
	grid.free()


func test_is_valid_position_bounds() -> void:
	var grid = GridClass.new()
	grid._init_grid()

	var block = BlockClass.new()
	block.initialize(BlockClass.ShapeType.O)  # 2x2 block

	# Valid position in center
	block.grid_position = Vector2i(4, 5)
	assert_true(grid.is_valid_position(block, Vector2i.ZERO), "Center should be valid")

	# Offsets check
	assert_true(
		grid.is_valid_position(block, Vector2i(1, 1)), "Offset within bounds should be valid"
	)

	# Left out of bounds
	block.grid_position = Vector2i(-1, 5)
	assert_false(grid.is_valid_position(block, Vector2i.ZERO), "Negative X should be invalid")

	# Right out of bounds
	block.grid_position = Vector2i(9, 5)
	assert_false(grid.is_valid_position(block, Vector2i.ZERO), "X too large should be invalid")

	# Bottom out of bounds
	block.grid_position = Vector2i(4, 19)
	assert_false(grid.is_valid_position(block, Vector2i.ZERO), "Y too large should be invalid")

	block.free()
	grid.free()


func test_is_valid_position_collision() -> void:
	var grid = GridClass.new()
	grid._init_grid()

	# Add segment directly to grid
	var seg = SegmentClass.new(SegmentClass.Type.ISOLATED, Color.RED)
	grid.grid_data[10][4] = seg

	var block = BlockClass.new()
	block.initialize(BlockClass.ShapeType.O)  # 2x2, shape_matrix is all true

	# Position block so it overlaps (10, 4)
	block.grid_position = Vector2i(4, 10)
	assert_false(grid.is_valid_position(block, Vector2i.ZERO), "Should collide with placed segment")

	# Position block just to the side
	block.grid_position = Vector2i(2, 10)
	assert_true(grid.is_valid_position(block, Vector2i.ZERO), "Should not collide when adjacent")

	block.free()
	grid.free()


func test_lock_block() -> void:
	var grid = GridClass.new()
	grid._init_grid()

	var block = BlockClass.new()
	block.initialize(BlockClass.ShapeType.O)
	block.grid_position = Vector2i(3, 5)

	# Keep copy of segments
	var block_segs = block.cells_data.duplicate(true)

	grid.lock_block(block)

	# Verify grid contains the block segments
	assert_eq(grid.grid_data[5][3], block_segs[0][0], "Segment (0,0) should lock in grid")
	assert_eq(grid.grid_data[5][4], block_segs[0][1], "Segment (0,1) should lock in grid")
	assert_eq(grid.grid_data[6][3], block_segs[1][0], "Segment (1,0) should lock in grid")
	assert_eq(grid.grid_data[6][4], block_segs[1][1], "Segment (1,1) should lock in grid")

	block.free()
	grid.free()


func test_row_clearing() -> void:
	var grid = GridClass.new()
	grid._init_grid()

	# Fill row 18 partially and row 19 completely
	for c in range(GridClass.COLUMNS):
		grid.grid_data[19][c] = SegmentClass.new(SegmentClass.Type.ISOLATED, Color.BLUE)

	grid.grid_data[18][5] = SegmentClass.new(SegmentClass.Type.BARE, Color.GREEN)

	# Clear rows
	var cleared = grid.check_and_clear_rows()
	assert_eq(cleared, 1, "One row should have been cleared")

	# Row 19 should now be filled with what was in row 18
	assert_not_null(grid.grid_data[19][5], "Row 18 green segment should fall to row 19")
	assert_eq(
		grid.grid_data[19][5].type, SegmentClass.Type.BARE, "Fallen segment type should be BARE"
	)
	assert_null(grid.grid_data[19][0], "Row 19 index 0 should be null")
	assert_null(grid.grid_data[18][5], "Row 18 index 5 should be null (shifted down)")

	grid.free()


func test_powerups_clear() -> void:
	var grid = GridClass.new()
	grid._init_grid()

	# Place segments
	grid.grid_data[10][2] = SegmentClass.new(SegmentClass.Type.ISOLATED, Color.RED)
	grid.grid_data[11][2] = SegmentClass.new(SegmentClass.Type.ISOLATED, Color.BLUE)

	# Clear column 2
	grid.clear_column(2)
	assert_null(grid.grid_data[10][2], "Column clear: (10, 2) should be null")
	assert_null(grid.grid_data[11][2], "Column clear: (11, 2) should be null")

	# Place again
	grid.grid_data[15][2] = SegmentClass.new(SegmentClass.Type.ISOLATED, Color.RED)
	grid.grid_data[15][3] = SegmentClass.new(SegmentClass.Type.ISOLATED, Color.BLUE)

	# Clear row 15
	grid.clear_row(15)
	assert_null(grid.grid_data[15][2], "Row clear: (15, 2) should be null")
	assert_null(grid.grid_data[15][3], "Row clear: (15, 3) should be null")

	grid.free()


func test_shake_grid() -> void:
	var grid = GridClass.new()
	grid._init_grid()

	# Create gaps
	var seg1 = SegmentClass.new(SegmentClass.Type.ISOLATED, Color.RED)
	var seg2 = SegmentClass.new(SegmentClass.Type.ISOLATED, Color.BLUE)
	grid.grid_data[10][5] = seg1
	grid.grid_data[15][5] = seg2

	# Shake grid
	grid.shake_grid()

	# After shake, they should be pulled down to the bottom
	assert_eq(grid.grid_data[19][5], seg2, "Lower segment should drop to row 19")
	assert_eq(grid.grid_data[18][5], seg1, "Upper segment should drop to row 18")
	assert_null(grid.grid_data[10][5], "Original row 10 should be null")
	assert_null(grid.grid_data[15][5], "Original row 15 should be null")

	grid.free()


func test_is_row_crimp_valid() -> void:
	var grid = GridClass.new()
	grid._init_grid()

	# Create a row with correct workflow segments
	for c in range(GridClass.COLUMNS):
		var type = SegmentClass.Type.BARE
		if c == 0 or c == 9:
			type = SegmentClass.Type.CRIMP_LUG
		grid.grid_data[19][c] = SegmentClass.new(type, Color.GREEN)

	assert_true(grid.is_row_crimp_valid(19), "Row with proper workflow segments should be valid")

	# Test invalid row (incomplete)
	grid.grid_data[19][5] = null
	assert_false(grid.is_row_crimp_valid(19), "Incomplete row should be invalid")

	# Restore as invalid type
	grid.grid_data[19][5] = SegmentClass.new(SegmentClass.Type.ISOLATED, Color.RED)
	assert_false(
		grid.is_row_crimp_valid(19), "Row with ISOLATED segment in middle should be invalid"
	)

	# Test invalid edge
	grid.grid_data[19][0] = SegmentClass.new(SegmentClass.Type.BARE, Color.GREEN)
	grid.grid_data[19][5] = SegmentClass.new(SegmentClass.Type.BARE, Color.GREEN)
	assert_false(grid.is_row_crimp_valid(19), "Row with BARE segment at edge 0 should be invalid")

	grid.free()


func test_check_full_rows_status() -> void:
	var grid = GridClass.new()
	grid._init_grid()

	# Row 18: full and valid
	for c in range(GridClass.COLUMNS):
		var type = SegmentClass.Type.BARE
		if c == 0 or c == 9:
			type = SegmentClass.Type.CRIMP_LUG
		grid.grid_data[18][c] = SegmentClass.new(type, Color.GREEN)

	# Row 19: full and invalid (all ISOLATED)
	for c in range(GridClass.COLUMNS):
		grid.grid_data[19][c] = SegmentClass.new(SegmentClass.Type.ISOLATED, Color.RED)

	var status = grid.check_full_rows_status()
	assert_eq(status["valid"].size(), 1, "Should have 1 valid row")
	assert_eq(status["valid"][0], 18, "Valid row index should be 18")
	assert_eq(status["invalid"].size(), 1, "Should have 1 invalid row")
	assert_eq(status["invalid"][0], 19, "Invalid row index should be 19")

	grid.free()
