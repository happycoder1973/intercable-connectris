class_name PowerUpManager
extends Node

signal cooldown_changed(powerup_id: int, time_left: float)

var cooldowns: Dictionary = {1: 0.0, 2: 0.0, 3: 0.0, 4: 0.0}


func _process(p_delta: float) -> void:
	for id in cooldowns.keys():
		if cooldowns[id] > 0.0:
			cooldowns[id] = max(0.0, cooldowns[id] - p_delta)
			cooldown_changed.emit(id, cooldowns[id])


func _unhandled_input(p_event: InputEvent) -> void:
	var playfield: Playfield = get_parent() as Playfield
	if playfield != null and (playfield._game_over or playfield._is_animating_press):
		return

	if p_event is InputEventKey and p_event.pressed:
		match p_event.keycode:
			KEY_1:
				trigger_powerup(1)
			KEY_2:
				trigger_powerup(2)
			KEY_3:
				trigger_powerup(3)
			KEY_4:
				trigger_powerup(4)


func trigger_powerup(p_id: int) -> bool:
	if cooldowns.get(p_id, 0.0) > 0.0:
		return false

	var playfield: Playfield = get_parent() as Playfield
	if playfield == null:
		return false

	cooldowns[p_id] = 20.0
	cooldown_changed.emit(p_id, 20.0)

	match p_id:
		1:
			playfield.grid.strip_all_isolated_segments()
			if playfield._sfx_laser != null:
				playfield._sfx_laser.play()
		2:
			playfield.grid.clear_slick_cutter_target()
			if playfield._sfx_cut != null:
				playfield._sfx_cut.play()
		3:
			playfield.grid.clear_bottom_rows(3)
			playfield._trigger_camera_shake()
			if playfield._sfx_press != null:
				playfield._sfx_press.play()
		4:
			playfield.activate_vde_shield()
			if playfield._sfx_press != null:
				playfield._sfx_press.play()

	return true
