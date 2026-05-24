extends GutTest
## Testet die Funktionalität der Block-Klasse (Tetrominos).

const BlockClass = preload("res://scripts/Block.gd")
const SegmentClass = preload("res://scripts/Segment.gd")


func test_block_initialization() -> void:
	var block = BlockClass.new()
	block.initialize(BlockClass.ShapeType.I)
	assert_eq(block.shape_type, BlockClass.ShapeType.I, "Shape type should be I")
	assert_eq(block.shape_matrix.size(), 4, "I shape should have a 4x4 matrix")
	assert_eq(block.cells_data.size(), 4, "cells_data should have a 4x4 matrix")

	# Check that active segments have data and inactive are null
	for r in range(4):
		for c in range(4):
			if block.shape_matrix[r][c]:
				assert_not_null(block.cells_data[r][c], "Active cells should have Segment data")
				var segment = block.cells_data[r][c]
				assert_eq(
					segment.color, block.block_color, "Segment color should match block color"
				)
			else:
				assert_null(block.cells_data[r][c], "Inactive cells should be null")

	block.free()


func test_block_rotation() -> void:
	var block = BlockClass.new()
	block.initialize(BlockClass.ShapeType.L)
	var orig_matrix: Array = block.shape_matrix.duplicate(true)

	block.rotate_right()
	# Matrix should be different after rotation (L is not symmetric)
	assert_ne(block.shape_matrix, orig_matrix, "Matrix should change after rotation")

	block.rotate_left()
	assert_eq(block.shape_matrix, orig_matrix, "Matrix should return to original after rotate left")

	block.free()


func test_get_active_segments() -> void:
	var block = BlockClass.new()
	block.initialize(BlockClass.ShapeType.O)
	block.grid_position = Vector2i(2, 3)

	var active: Array[Dictionary] = block.get_active_segments()
	# O piece has 4 active blocks
	assert_eq(active.size(), 4, "O tetromino should have 4 active segments")

	for item in active:
		assert_true(item.has("grid_pos"), "Active dictionary should have grid_pos")
		assert_true(item.has("segment"), "Active dictionary should have segment")
		assert_true(item.segment is SegmentClass, "segment should be a Segment instance")

	block.free()
