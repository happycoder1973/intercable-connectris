extends GutTest

const PlayfieldClass = preload("res://scripts/Playfield.gd")
const PowerUpManagerClass = preload("res://scripts/PowerUpManager.gd")
const SegmentClass = preload("res://scripts/Segment.gd")


func test_cooldown_mechanics() -> void:
	var playfield = PlayfieldClass.new()
	add_child(playfield)

	var manager = PowerUpManagerClass.new()
	playfield.add_child(manager)

	# Trigger power-up 1
	var success = manager.trigger_powerup(1)
	assert_true(success, "Triggering powerup first time should succeed")
	assert_eq(manager.cooldowns[1], 20.0, "Cooldown should be set to 20s")

	# Trigger again immediately
	var success_again = manager.trigger_powerup(1)
	assert_false(success_again, "Triggering on active cooldown should fail")

	# Process delta time
	manager._process(5.0)
	assert_eq(manager.cooldowns[1], 15.0, "Cooldown should decrease to 15s after 5s delta")

	# Check signal emission
	watch_signals(manager)
	manager._process(1.0)
	assert_signal_emitted(manager, "cooldown_changed")

	playfield.free()


func test_powerup_effects() -> void:
	var playfield = PlayfieldClass.new()
	add_child(playfield)

	var manager = PowerUpManagerClass.new()
	playfield.add_child(manager)

	# 1. Strip all isolated segments
	playfield.grid.grid_data[10][2] = SegmentClass.new(SegmentClass.Type.ISOLATED, Color.RED)
	var success1 = manager.trigger_powerup(1)
	assert_true(success1)
	assert_eq(
		playfield.grid.grid_data[10][2].type,
		SegmentClass.Type.BARE,
		"Powerup 1 should strip isolated to bare"
	)

	# Reset cooldown for testing next ones
	manager.cooldowns[2] = 0.0
	manager.cooldowns[3] = 0.0
	manager.cooldowns[4] = 0.0

	# 2. Slick Cutter (clears lowest non-empty row)
	playfield.grid.grid_data[19][5] = SegmentClass.new(SegmentClass.Type.BARE, Color.BLUE)
	var success2 = manager.trigger_powerup(2)
	assert_true(success2)
	assert_null(playfield.grid.grid_data[19][5], "Powerup 2 should clear lowest non-empty row")

	# 3. Heavy Press (clears bottom 3 rows)
	playfield.grid.grid_data[19][2] = SegmentClass.new(SegmentClass.Type.BARE, Color.GREEN)
	playfield.grid.grid_data[18][2] = SegmentClass.new(SegmentClass.Type.BARE, Color.GREEN)
	playfield.grid.grid_data[17][2] = SegmentClass.new(SegmentClass.Type.BARE, Color.GREEN)
	playfield.grid.grid_data[16][2] = SegmentClass.new(SegmentClass.Type.BARE, Color.GREEN)

	var success3 = manager.trigger_powerup(3)
	assert_true(success3)
	assert_null(playfield.grid.grid_data[18][2], "Row 18 should be null after shift")
	assert_null(playfield.grid.grid_data[17][2], "Row 17 should be null after shift")
	assert_not_null(playfield.grid.grid_data[19][2], "Row 16 segment should shift down to row 19")

	# 4. VDE Shield activation
	assert_false(playfield.is_shield_active(), "Shield should not be active initially")
	var success4 = manager.trigger_powerup(4)
	assert_true(success4)
	assert_true(playfield.is_shield_active(), "Powerup 4 should activate VDE shield")

	playfield.free()


func test_input_handling() -> void:
	var playfield = PlayfieldClass.new()
	add_child(playfield)

	var manager = PowerUpManagerClass.new()
	playfield.add_child(manager)

	# Simulate pressing KEY_1
	var event = InputEventKey.new()
	event.pressed = true
	event.keycode = KEY_1

	manager._unhandled_input(event)
	assert_eq(manager.cooldowns[1], 20.0, "Input event KEY_1 should trigger powerup 1")

	playfield.free()
