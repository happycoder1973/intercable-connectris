class_name Block
extends Node2D
## Repräsentiert das fallende Tetromino mit individuellen Segmenten pro Zelle.

enum ShapeType { I, O, T, S, Z, J, L }

const CELL_SIZE: int = 48

const SHAPE_COLORS: Dictionary = {
	ShapeType.I: Color(0.0, 1.0, 1.0),
	ShapeType.O: Color(1.0, 1.0, 0.0),
	ShapeType.T: Color(0.5, 0.0, 0.5),
	ShapeType.S: Color(0.0, 1.0, 0.0),
	ShapeType.Z: Color(1.0, 0.0, 0.0),
	ShapeType.J: Color(0.0, 0.0, 1.0),
	ShapeType.L: Color(1.0, 0.5, 0.0)
}

var shape_matrix: Array = []
var cells_data: Array = []
var grid_position: Vector2i = Vector2i.ZERO
var block_color: Color = Color.WHITE
var shape_type: ShapeType = ShapeType.I

var _isolated_tex: Texture2D = preload("res://assets/textures/isoliert.png")
var _bare_tex: Texture2D = preload("res://assets/textures/blank.png")
var _crimp_tex: Texture2D = preload("res://assets/textures/gecrimpt.png")


func _ready() -> void:
	pass


func _draw() -> void:
	for r in range(shape_matrix.size()):
		for c in range(shape_matrix[r].size()):
			if shape_matrix[r][c] and cells_data[r][c] != null:
				var segment: Segment = cells_data[r][c]
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


func initialize(p_shape_type: int) -> void:
	shape_type = p_shape_type as ShapeType
	block_color = SHAPE_COLORS.get(shape_type, Color.WHITE)

	match shape_type:
		ShapeType.I:
			shape_matrix = [
				[false, false, false, false],
				[true, true, true, true],
				[false, false, false, false],
				[false, false, false, false]
			]
		ShapeType.O:
			shape_matrix = [[true, true], [true, true]]
		ShapeType.T:
			shape_matrix = [[false, true, false], [true, true, true], [false, false, false]]
		ShapeType.S:
			shape_matrix = [[false, true, true], [true, true, false], [false, false, false]]
		ShapeType.Z:
			shape_matrix = [[true, true, false], [false, true, true], [false, false, false]]
		ShapeType.J:
			shape_matrix = [[true, false, false], [true, true, true], [false, false, false]]
		ShapeType.L:
			shape_matrix = [[false, false, true], [true, true, true], [false, false, false]]

	cells_data = []
	for r in range(shape_matrix.size()):
		var cells_row: Array = []
		for c in range(shape_matrix[r].size()):
			if shape_matrix[r][c]:
				var rand_type: Segment.Type = (randi() % 3) as Segment.Type
				var segment: Segment = Segment.new(rand_type, block_color)
				cells_row.append(segment)
			else:
				cells_row.append(null)
		cells_data.append(cells_row)

	queue_redraw()


func rotate_right() -> void:
	var n: int = shape_matrix.size()
	var new_shape: Array = []
	var new_cells: Array = []
	for i in range(n):
		var shape_row: Array = []
		var cells_row: Array = []
		shape_row.resize(n)
		cells_row.resize(n)
		shape_row.fill(false)
		cells_row.fill(null)
		new_shape.append(shape_row)
		new_cells.append(cells_row)

	for r in range(n):
		for c in range(n):
			new_shape[c][n - 1 - r] = shape_matrix[r][c]
			new_cells[c][n - 1 - r] = cells_data[r][c]

	shape_matrix = new_shape
	cells_data = new_cells
	queue_redraw()


func rotate_left() -> void:
	var n: int = shape_matrix.size()
	var new_shape: Array = []
	var new_cells: Array = []
	for i in range(n):
		var shape_row: Array = []
		var cells_row: Array = []
		shape_row.resize(n)
		cells_row.resize(n)
		shape_row.fill(false)
		cells_row.fill(null)
		new_shape.append(shape_row)
		new_cells.append(cells_row)

	for r in range(n):
		for c in range(n):
			new_shape[n - 1 - c][r] = shape_matrix[r][c]
			new_cells[n - 1 - c][r] = cells_data[r][c]

	shape_matrix = new_shape
	cells_data = new_cells
	queue_redraw()


func get_active_segments() -> Array[Dictionary]:
	var active: Array[Dictionary] = []
	for r in range(shape_matrix.size()):
		for c in range(shape_matrix[r].size()):
			if shape_matrix[r][c] and cells_data[r][c] != null:
				var pos: Vector2i = grid_position + Vector2i(c, r)
				active.append({"grid_pos": pos, "segment": cells_data[r][c]})
	return active
