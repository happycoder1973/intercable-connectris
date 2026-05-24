extends GutTest

const SettingsManagerClass = preload("res://scripts/SettingsManager.gd")


func test_settings_manager_defaults() -> void:
	assert_eq(
		SettingsManager.current_mode,
		SettingsManager.GameMode.CLASSIC,
		"Default mode should be CLASSIC"
	)
	assert_eq(
		SettingsManager.expo_round_duration, 180.0, "Default expo round duration should be 180s"
	)
	assert_false(SettingsManager.is_kiosk_mode, "Default kiosk mode should be false")
	assert_true(SettingsManager.is_sound_enabled, "Default sound enabled should be true")


func test_save_and_load_settings() -> void:
	# Change some settings
	SettingsManager.current_mode = SettingsManager.GameMode.EXPO
	SettingsManager.expo_round_duration = 120.0
	SettingsManager.is_kiosk_mode = true
	SettingsManager.is_sound_enabled = false

	# Save
	SettingsManager.save_settings()

	# Reset settings to default
	SettingsManager.current_mode = SettingsManager.GameMode.CLASSIC
	SettingsManager.expo_round_duration = 180.0
	SettingsManager.is_kiosk_mode = false
	SettingsManager.is_sound_enabled = true

	# Load settings back
	SettingsManager.load_settings()

	assert_eq(
		SettingsManager.current_mode,
		SettingsManager.GameMode.EXPO,
		"Loaded mode should match saved"
	)
	assert_eq(SettingsManager.expo_round_duration, 120.0, "Loaded duration should match saved")
	assert_true(SettingsManager.is_kiosk_mode, "Loaded kiosk mode should match saved")
	assert_false(SettingsManager.is_sound_enabled, "Loaded sound enabled should match saved")

	# Restore to default clean state for other tests
	SettingsManager.current_mode = SettingsManager.GameMode.CLASSIC
	SettingsManager.expo_round_duration = 180.0
	SettingsManager.is_kiosk_mode = false
	SettingsManager.is_sound_enabled = true
	SettingsManager.save_settings()
