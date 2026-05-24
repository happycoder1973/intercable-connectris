class_name Grid
extends Node2D
## Verwaltet das 2D-Spielfeld-Gitter (10x20), Kollisionsprüfungen und Reihenlöschungen.

const COLUMNS: int = 10
const ROWS: int = 20
const CELL_SIZE: int = 48

var grid_data: Array = []

var _isolated_tex: Texture2D = preload("res://assets/textures/isoliert.png")
var _bare_tex: Texture2D = preload("res://assets/textures/blank.png")
var _crimp_tex: Texture2D = preload("res://assets/textures/gecrimpt.png")


func _ready() -> void:
	_init_grid()


func _draw() -> void:
	# Gitterrahmen und Hilfslinien zeichnen
	for c in range(COLUMNS + 1):
		draw_line(
			Vector2(c * CELL_SIZE, 0),
			Vector2(c * CELL_SIZE, ROWS * CELL_SIZE),
			Color(0.2, 0.2, 0.2)
		)
	for r in range(ROWS + 1):
		draw_line(
			Vector2(0, r * CELL_SIZE),
			Vector2(COLUMNS * CELL_SIZE, r * CELL_SIZE),
			Color(0.2, 0.2, 0.2)
		)

	draw_rect(Rect2(0, 0, COLUMNS * CELL_SIZE, ROWS * CELL_SIZE), Color.DARK_GRAY, false, 2.0)

	# Feste Segmente zeichnen
	for r in range(ROWS):
		for c in range(COLUMNS):
			if grid_data[r][c] != null:
				var segment: Segment = grid_data[r][c]
				var tex: Texture2D = null
				match segment.type:
					Segment.Type.ISOLATED:
						tex = _isolated_tex
					Segment.Type.BARE:
						tex = _bare_tex
					Segment.Type.CRIMP_LUG:
						tex = _crimp_tex

				var rect: Rect2 = Rect2(c * CELL_SIZE, r * CELL_SIZE, CELL_SIZE, CELL_SIZE)
				if tex != null:
					draw_texture_rect(tex, rect, false)
				else:
					draw_rect(rect, segment.color)


func _init_grid() -> void:
	grid_data = []
	for r in range(ROWS):
		var row: Array = []
		row.resize(COLUMNS)
		row.fill(null)
		grid_data.append(row)


func is_valid_position(p_block: Block, p_offset: Vector2i) -> bool:
	var target_pos: Vector2i = p_block.grid_position + p_offset

	for r in range(p_block.shape_matrix.size()):
		for c in range(p_block.shape_matrix[r].size()):
			if p_block.shape_matrix[r][c]:
				var gp: Vector2i = target_pos + Vector2i(c, r)

				# X-Grenzen prüfen
				if gp.x < 0 or gp.x >= COLUMNS:
					return false
				# Untere Grenze prüfen
				if gp.y >= ROWS:
					return false
				# Kollision mit festen Segmenten im Gitter (nur wenn gp.y im gültigen Bereich ist)
				if gp.y >= 0:
					if grid_data[gp.y][gp.x] != null:
						return false

	return true


func lock_block(p_block: Block) -> void:
	for r in range(p_block.shape_matrix.size()):
		for c in range(p_block.shape_matrix[r].size()):
			if p_block.shape_matrix[r][c] and p_block.cells_data[r][c] != null:
				var gp: Vector2i = p_block.grid_position + Vector2i(c, r)
				if gp.y >= 0 and gp.y < ROWS and gp.x >= 0 and gp.x < COLUMNS:
					grid_data[gp.y][gp.x] = p_block.cells_data[r][c]
	queue_redraw()


func check_and_clear_rows() -> int:
	var cleared: int = 0
	var r: int = ROWS - 1

	while r >= 0:
		var is_full: bool = true
		for c in range(COLUMNS):
			if grid_data[r][c] == null:
				is_full = false
				break

		if is_full:
			grid_data.remove_at(r)
			var new_row: Array = []
			new_row.resize(COLUMNS)
			new_row.fill(null)
			grid_data.insert(0, new_row)
			cleared += 1
		else:
			r -= 1

	if cleared > 0:
		queue_redraw()

	return cleared


func clear_row(p_row_index: int) -> void:
	if p_row_index >= 0 and p_row_index < ROWS:
		grid_data.remove_at(p_row_index)
		var new_row: Array = []
		new_row.resize(COLUMNS)
		new_row.fill(null)
		grid_data.insert(0, new_row)
		queue_redraw()


func clear_column(p_col_index: int) -> void:
	if p_col_index >= 0 and p_col_index < COLUMNS:
		for r in range(ROWS - 1, -1, -1):
			for r2 in range(r, 0, -1):
				grid_data[r2][p_col_index] = grid_data[r2 - 1][p_col_index]
			grid_data[0][p_col_index] = null
		queue_redraw()


func shake_grid() -> void:
	for c in range(COLUMNS):
		var col_segments: Array = []
		for r in range(ROWS):
			if grid_data[r][c] != null:
				col_segments.append(grid_data[r][c])

		var null_count: int = ROWS - col_segments.size()
		for r in range(null_count):
			grid_data[r][c] = null
		for r in range(col_segments.size()):
			grid_data[null_count + r][c] = col_segments[r]
	queue_redraw()
