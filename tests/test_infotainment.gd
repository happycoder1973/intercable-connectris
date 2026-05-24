extends GutTest
## Testet die Infotainment- und Meilenstein-Popups.

const PlayfieldClass = preload("res://scripts/Playfield.gd")
const InfotainmentPopupClass = preload("res://scripts/InfotainmentPopup.gd")


func test_loading_screen_initialization() -> void:
	var playfield = PlayfieldClass.new()
	playfield.force_loading_screen = true
	add_child(playfield)

	var loading_layer = playfield.get_node_or_null("LoadingLayer")
	assert_not_null(loading_layer, "Loading layer should be created on ready")
	assert_true(playfield._is_animating_press, "Should block input during loading screen")

	playfield.free()


func test_milestone_popup_pauses_game() -> void:
	var playfield = PlayfieldClass.new()
	add_child(playfield)

	# Trigger VDE shield activation which should trigger shield milestone popup
	playfield.activate_vde_shield()

	var ui_layer = playfield.get_node_or_null("UILayer")
	assert_not_null(ui_layer, "UILayer should exist")

	var popup = null
	for child in ui_layer.get_children():
		if child is InfotainmentPopupClass:
			popup = child
			break

	assert_not_null(popup, "InfotainmentPopup should have been instantiated")
	if popup != null:
		assert_true(get_tree().paused, "Game should be paused during milestone popup")
		assert_eq(popup.process_mode, Node.PROCESS_MODE_ALWAYS, "Popup should process when paused")

		# Click close button to unpause and close
		watch_signals(popup)
		popup._on_close_pressed()
		assert_signal_emitted(popup, "closed")
		assert_false(get_tree().paused, "Game should be unpaused after closing popup")
		assert_true(popup.is_queued_for_deletion(), "Popup should be freed")

	playfield.free()
