extends GutTest
## Testet die Touch-Gesten und Gamepad-Kopplungen.

const PlayfieldClass = preload("res://scripts/Playfield.gd")


func test_touch_tap_rotates() -> void:
	var playfield = PlayfieldClass.new()
	add_child(playfield)

	var block = playfield.current_block
	var initial_rotation = block.cells_data.duplicate(true)

	# Simulate touch tap
	var touch_down = InputEventScreenTouch.new()
	touch_down.pressed = true
	touch_down.position = Vector2(200, 200)
	playfield._unhandled_input(touch_down)

	var touch_up = InputEventScreenTouch.new()
	touch_up.pressed = false
	touch_up.position = Vector2(205, 205)
	playfield._unhandled_input(touch_up)

	assert_ne(block.cells_data, initial_rotation, "Block should rotate after a touch tap")

	playfield.free()


func test_touch_swipe_left() -> void:
	var playfield = PlayfieldClass.new()
	add_child(playfield)

	var block = playfield.current_block
	var initial_x = block.grid_position.x

	# Simulate swipe left
	var touch_down = InputEventScreenTouch.new()
	touch_down.pressed = true
	touch_down.position = Vector2(200, 200)
	playfield._unhandled_input(touch_down)

	var touch_up = InputEventScreenTouch.new()
	touch_up.pressed = false
	touch_up.position = Vector2(140, 200)
	playfield._unhandled_input(touch_up)

	assert_eq(block.grid_position.x, initial_x - 1, "Block should move left on swipe left")

	playfield.free()


func test_touch_swipe_right() -> void:
	var playfield = PlayfieldClass.new()
	add_child(playfield)

	var block = playfield.current_block
	var initial_x = block.grid_position.x

	# Simulate swipe right
	var touch_down = InputEventScreenTouch.new()
	touch_down.pressed = true
	touch_down.position = Vector2(200, 200)
	playfield._unhandled_input(touch_down)

	var touch_up = InputEventScreenTouch.new()
	touch_up.pressed = false
	touch_up.position = Vector2(260, 200)
	playfield._unhandled_input(touch_up)

	assert_eq(block.grid_position.x, initial_x + 1, "Block should move right on swipe right")

	playfield.free()


func test_joypad_rumble_does_not_crash() -> void:
	var playfield = PlayfieldClass.new()
	add_child(playfield)

	playfield._trigger_rumble(0.5, 0.5, 0.2)
	assert_true(true, "Rumble did not crash without joypads")

	playfield.free()
