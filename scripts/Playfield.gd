class_name Playfield
extends Node2D
## Verwaltet die Spielschleife, Punkteberechnung, Eingaben und den fallenden Block.

signal score_changed(new_score: int, level: int)
signal game_over_triggered(final_score: int)
signal crimp_press_started(row_index: int)
signal crimp_press_completed(row_index: int)
signal timer_updated(time_left: float)

@export var fall_interval_start: float = 1.0

var grid: Grid
var current_block: Block

var _fall_timer: float = 0.0
var _fall_interval: float = 1.0
var _score: int = 0
var _level: int = 1
var _total_rows_cleared: int = 0
var _game_over: bool = false
var _is_animating_press: bool = false
var _shield_time_left: float = 0.0
var _time_left: float = 0.0

@onready var _press_overlay: Node2D = get_node_or_null("PressOverlay")
@onready var _sfx_press: AudioStreamPlayer = get_node_or_null("SfxPress")
@onready var _spark_particles: CPUParticles2D = get_node_or_null("SparkParticles")
@onready var _camera: Camera2D = get_node_or_null("Camera2D")
@onready var _shield_overlay: Panel = get_node_or_null("ShieldOverlay")
@onready var _sfx_laser: AudioStreamPlayer = get_node_or_null("SfxLaser")
@onready var _sfx_cut: AudioStreamPlayer = get_node_or_null("SfxCut")


func _ready() -> void:
	_score = 0
	_level = 1
	_total_rows_cleared = 0
	_game_over = false
	_fall_interval = fall_interval_start

	if grid == null:
		if has_node("Grid"):
			grid = $Grid as Grid
		else:
			grid = Grid.new()
			add_child(grid)

	update_difficulty()
	spawn_new_block()

	if SettingsManager.current_mode == SettingsManager.GameMode.EXPO:
		_time_left = SettingsManager.expo_round_duration


func _process(p_delta: float) -> void:
	if _shield_time_left > 0.0:
		_shield_time_left = max(0.0, _shield_time_left - p_delta)
		if _shield_overlay != null:
			_shield_overlay.visible = _shield_time_left > 0.0

	if SettingsManager.current_mode == SettingsManager.GameMode.EXPO and not _game_over:
		_time_left = max(0.0, _time_left - p_delta)
		timer_updated.emit(_time_left)
		if _time_left <= 0.0:
			_trigger_game_over(true)

	if _game_over or _is_animating_press:
		return

	handle_input()

	_fall_timer += p_delta
	if _fall_timer >= _fall_interval:
		_fall_timer = 0.0
		move_block_down()


func _unhandled_input(p_event: InputEvent) -> void:
	if _game_over or _is_animating_press or current_block == null:
		return

	if p_event is InputEventKey and p_event.pressed:
		match p_event.keycode:
			KEY_LEFT, KEY_A:
				move_block_horizontal(-1)
			KEY_RIGHT, KEY_D:
				move_block_horizontal(1)
			KEY_UP, KEY_W:
				rotate_block()
			KEY_DOWN, KEY_S:
				move_block_down()
				_fall_timer = 0.0
			KEY_SPACE:
				hard_drop()


func handle_input() -> void:
	pass


func spawn_new_block() -> void:
	if _game_over:
		return

	var shape: int = randi() % 7
	current_block = Block.new()
	add_child(current_block)
	current_block.initialize(shape)

	# Startposition in der Mitte der ersten Zeile
	current_block.grid_position = Vector2i(3, 0)
	_update_block_visual_position()

	# Auf sofortige Kollision prüfen (Game Over)
	if not grid.is_valid_position(current_block, Vector2i.ZERO):
		if is_shield_active():
			_shield_time_left = 0.0
			if _shield_overlay != null:
				_shield_overlay.visible = false
			grid.clear_bottom_rows(5)
			_trigger_camera_shake()
			if _sfx_press != null:
				_sfx_press.play()
			_update_block_visual_position()
		else:
			_trigger_game_over(false)


func move_block_down() -> void:
	if current_block == null or _game_over or _is_animating_press:
		return

	if grid.is_valid_position(current_block, Vector2i(0, 1)):
		current_block.grid_position.y += 1
		_update_block_visual_position()
	else:
		grid.lock_block(current_block)
		current_block.queue_free()
		current_block = null

		var status: Dictionary = grid.check_full_rows_status()
		var valid_rows: Array = status["valid"]

		if valid_rows.size() > 0:
			_animate_press_sequence(valid_rows)
		else:
			spawn_new_block()


func move_block_horizontal(p_dir: int) -> void:
	if current_block == null or _game_over or _is_animating_press:
		return

	if grid.is_valid_position(current_block, Vector2i(p_dir, 0)):
		current_block.grid_position.x += p_dir
		_update_block_visual_position()


func rotate_block() -> void:
	if current_block == null or _game_over or _is_animating_press:
		return

	current_block.rotate_right()
	if not grid.is_valid_position(current_block, Vector2i.ZERO):
		current_block.rotate_left()


func hard_drop() -> void:
	if current_block == null or _game_over or _is_animating_press:
		return

	while grid.is_valid_position(current_block, Vector2i(0, 1)):
		current_block.grid_position.y += 1
	_update_block_visual_position()
	move_block_down()


func update_difficulty() -> void:
	_fall_interval = max(0.1, fall_interval_start - (_level - 1) * 0.1)


func _update_block_visual_position() -> void:
	if current_block != null:
		current_block.position = Vector2(
			current_block.grid_position.x * Grid.CELL_SIZE,
			current_block.grid_position.y * Grid.CELL_SIZE
		)


func _add_score(p_cleared_rows: int) -> void:
	_score += p_cleared_rows
	_total_rows_cleared += p_cleared_rows
	_level = 1 + (_total_rows_cleared / 10)

	update_difficulty()
	score_changed.emit(_score, _level)


func _animate_press_sequence(p_valid_rows: Array) -> void:
	_is_animating_press = true
	p_valid_rows.sort()

	for row in p_valid_rows:
		crimp_press_started.emit(row)

		if _press_overlay != null:
			_press_overlay.position.x = 0
			_press_overlay.position.y = -Grid.CELL_SIZE
			_press_overlay.show()

		var tween := create_tween()
		var target_y: float = row * Grid.CELL_SIZE

		if _press_overlay != null:
			(
				tween
				. tween_property(_press_overlay, "position:y", target_y, 0.4)
				. set_trans(Tween.TRANS_QUAD)
				. set_ease(Tween.EASE_OUT)
			)
		else:
			tween.tween_interval(0.1)

		tween.tween_callback(
			func():
				if _sfx_press != null:
					_sfx_press.play()
				if _spark_particles != null:
					var half_w: float = (Grid.COLUMNS * Grid.CELL_SIZE) / 2.0
					var center_y: float = target_y + Grid.CELL_SIZE / 2.0
					_spark_particles.position = Vector2(half_w, center_y)
					_spark_particles.restart()
		)

		tween.tween_interval(0.15)

		tween.tween_callback(func(): grid.clear_row(row))

		if _press_overlay != null:
			(
				tween
				. tween_property(_press_overlay, "position:y", -Grid.CELL_SIZE, 0.3)
				. set_trans(Tween.TRANS_QUAD)
				. set_ease(Tween.EASE_IN)
			)
		else:
			tween.tween_interval(0.1)

		tween.tween_callback(
			func():
				if _press_overlay != null:
					_press_overlay.hide()
				crimp_press_completed.emit(row)
		)

		await tween.finished
		_add_score(1)

	_is_animating_press = false
	spawn_new_block()


func activate_vde_shield() -> void:
	_shield_time_left = 20.0
	if _shield_overlay != null:
		_shield_overlay.visible = true


func is_shield_active() -> bool:
	return _shield_time_left > 0.0


func _trigger_camera_shake() -> void:
	if _camera == null:
		return

	var tween = create_tween()
	var shake_strength: float = 15.0
	var step_time: float = 0.03

	for i in range(10):
		var random_offset = Vector2(
			randf_range(-shake_strength, shake_strength),
			randf_range(-shake_strength, shake_strength)
		)
		tween.tween_property(_camera, "offset", random_offset, step_time)
		shake_strength *= 0.9

	tween.tween_property(_camera, "offset", Vector2.ZERO, step_time)


func _trigger_game_over(p_was_time_out: bool) -> void:
	if _game_over:
		return
	_game_over = true
	game_over_triggered.emit(_score)
	if current_block != null:
		current_block.queue_free()
		current_block = null

	var overlay_scene = load("res://scenes/game_over_overlay.tscn")
	var overlay = overlay_scene.instantiate()
	add_child(overlay)
	overlay.initialize(_score, _level, p_was_time_out)
	overlay.name_input_requested.connect(_on_name_input_requested)


func _on_name_input_requested() -> void:
	print("Name input requested")
