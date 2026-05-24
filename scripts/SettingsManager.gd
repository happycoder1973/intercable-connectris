# SettingsManager.gd
extends Node

enum GameMode { CLASSIC, EXPO }

const SAVE_PATH = "user://settings.cfg"

var current_mode: GameMode = GameMode.CLASSIC
var expo_round_duration: float = 180.0
var is_kiosk_mode: bool = false
var is_sound_enabled: bool = true


func _ready() -> void:
	load_settings()
	apply_kiosk_settings()


func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT:
		if is_kiosk_mode and not _is_running_in_test():
			_handle_focus_loss()


func save_settings() -> void:
	var config = ConfigFile.new()
	config.set_value("general", "current_mode", current_mode)
	config.set_value("general", "expo_round_duration", expo_round_duration)
	config.set_value("general", "is_kiosk_mode", is_kiosk_mode)
	config.set_value("general", "is_sound_enabled", is_sound_enabled)
	config.save(SAVE_PATH)


func load_settings() -> void:
	var config = ConfigFile.new()
	var err = config.load(SAVE_PATH)
	if err == OK:
		current_mode = config.get_value("general", "current_mode", GameMode.CLASSIC) as GameMode
		expo_round_duration = config.get_value("general", "expo_round_duration", 180.0) as float
		is_kiosk_mode = config.get_value("general", "is_kiosk_mode", false) as bool
		is_sound_enabled = config.get_value("general", "is_sound_enabled", true) as bool

	# CLI argument check to override kiosk mode
	for arg in OS.get_cmdline_args():
		if arg == "--kiosk":
			is_kiosk_mode = true


func apply_kiosk_settings() -> void:
	if is_kiosk_mode and not _is_running_in_test():
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
		DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_ALWAYS_ON_TOP, true)


func _handle_focus_loss() -> void:
	get_window().grab_focus()


func _is_running_in_test() -> bool:
	for arg in OS.get_cmdline_args():
		if "gut" in arg:
			return true
	return false
