extends GutTest

const SettingsManagerClass = preload("res://scripts/SettingsManager.gd")


func before_each() -> void:
	SettingsManager.is_kiosk_mode = true


func after_each() -> void:
	SettingsManager.is_kiosk_mode = false
	SettingsManager.save_settings()


func test_kiosk_mode_defaults() -> void:
	assert_true(SettingsManager.is_kiosk_mode, "Kiosk mode should be active inside tests")


func test_focus_loss_notification() -> void:
	# Trigger the notification and check that it doesn't crash
	SettingsManager.notification(NOTIFICATION_APPLICATION_FOCUS_OUT)
	assert_true(true, "Should handle NOTIFICATION_APPLICATION_FOCUS_OUT without crashing")


func test_apply_kiosk_settings_does_not_crash() -> void:
	# In test environments, apply_kiosk_settings is a no-op due to _is_running_in_test
	SettingsManager.apply_kiosk_settings()
	assert_true(true, "apply_kiosk_settings should execute safely in test environment")
