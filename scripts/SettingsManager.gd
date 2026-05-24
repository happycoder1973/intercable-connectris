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
