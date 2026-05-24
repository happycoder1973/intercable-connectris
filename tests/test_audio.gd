extends GutTest


func before_each() -> void:
	SettingsManager.is_sound_enabled = true


func after_each() -> void:
	SettingsManager.is_sound_enabled = true
	SettingsManager.save_settings()


func test_audio_server_unmuted_by_default() -> void:
	SettingsManager.is_sound_enabled = true
	SettingsManager.apply_audio_settings()
	var master_idx = AudioServer.get_bus_index("Master")
	assert_ne(master_idx, -1, "Master bus should exist")
	assert_false(
		AudioServer.is_bus_mute(master_idx), "Master bus should not be muted when sound is enabled"
	)


func test_audio_server_muted_when_sound_disabled() -> void:
	SettingsManager.is_sound_enabled = false
	SettingsManager.apply_audio_settings()
	var master_idx = AudioServer.get_bus_index("Master")
	assert_ne(master_idx, -1, "Master bus should exist")
	assert_true(
		AudioServer.is_bus_mute(master_idx), "Master bus should be muted when sound is disabled"
	)


func test_music_manager_instantiated() -> void:
	# Verify MusicManager autoload is active in the scene tree
	var music_manager = get_tree().root.get_node_or_null("MusicManager")
	assert_not_null(music_manager, "MusicManager should be registered as an Autoload")

	# Verify it has an AudioStreamPlayer child
	var player = music_manager.get_child(0) as AudioStreamPlayer
	assert_not_null(player, "MusicManager should have an AudioStreamPlayer child")
	assert_not_null(player.stream, "AudioStreamPlayer should have an assigned stream")
