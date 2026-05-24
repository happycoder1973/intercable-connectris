extends Control
## Das Hauptmenue von Intercable Connectris. Zeigt die Bestenliste und Spielmodus-Optionen.

var _sound_btn: Button
var _sfx_click: AudioStreamPlayer

@onready var _classic_button: Button = get_node_or_null("HBox/LeftPanel/VBox/ClassicButton")
@onready var _expo_button: Button = get_node_or_null("HBox/LeftPanel/VBox/ExpoButton")
@onready var _quit_button: Button = get_node_or_null("HBox/LeftPanel/VBox/QuitButton")
@onready var _highscore_list: VBoxContainer = get_node_or_null("HBox/RightPanel/VBox/HighscoreList")


func _ready() -> void:
	# Programmatic Click SFX Player
	_sfx_click = AudioStreamPlayer.new()
	add_child(_sfx_click)
	_sfx_click.stream = load("res://assets/audio/menu_klick.wav")

	if _classic_button != null:
		_classic_button.pressed.connect(_on_classic_pressed)
	if _expo_button != null:
		_expo_button.pressed.connect(_on_expo_pressed)
	if _quit_button != null:
		_quit_button.pressed.connect(_on_quit_pressed)

	# Programmatic Sound Toggle Button
	if _quit_button != null:
		_sound_btn = Button.new()
		_sound_btn.custom_minimum_size = Vector2(250, 60)
		_sound_btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		_sound_btn.theme_type_variation = "Button"
		_sound_btn.pressed.connect(_on_sound_pressed)

		var vbox = _quit_button.get_parent()
		vbox.add_child(_sound_btn)
		vbox.move_child(_sound_btn, _quit_button.get_index())

		_update_sound_button_text()

	_load_highscores()


func _load_highscores() -> void:
	if _highscore_list == null:
		return

	for child in _highscore_list.get_children():
		child.queue_free()

	var db = HighscoreDB.new()
	var top_scores = db.get_top_highscores(10)

	if top_scores.size() == 0:
		var empty_label = Label.new()
		empty_label.text = "Noch keine Highscores eingetragen."
		empty_label.add_theme_color_override("font_color", Color.GRAY)
		empty_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		_highscore_list.add_child(empty_label)
		return

	var header = HBoxContainer.new()
	_highscore_list.add_child(header)

	var h_rank = Label.new()
	h_rank.text = "Rang"
	h_rank.custom_minimum_size = Vector2(50, 0)
	h_rank.add_theme_color_override("font_color", Color("#FFD000"))
	header.add_child(h_rank)

	var h_name = Label.new()
	h_name.text = "Name"
	h_name.custom_minimum_size = Vector2(80, 0)
	h_name.add_theme_color_override("font_color", Color("#FFD000"))
	header.add_child(h_name)

	var h_score = Label.new()
	h_score.text = "Punkte"
	h_score.custom_minimum_size = Vector2(100, 0)
	h_score.add_theme_color_override("font_color", Color("#FFD000"))
	header.add_child(h_score)

	var h_level = Label.new()
	h_level.text = "Level"
	h_level.custom_minimum_size = Vector2(80, 0)
	h_level.add_theme_color_override("font_color", Color("#FFD000"))
	header.add_child(h_level)

	var rank = 1
	for score_entry in top_scores:
		var row = HBoxContainer.new()
		_highscore_list.add_child(row)

		var rank_lbl = Label.new()
		rank_lbl.text = "%d." % rank
		rank_lbl.custom_minimum_size = Vector2(50, 0)
		row.add_child(rank_lbl)

		var name_lbl = Label.new()
		name_lbl.text = str(score_entry.get("initials", "---"))
		name_lbl.custom_minimum_size = Vector2(80, 0)
		name_lbl.add_theme_color_override("font_color", Color("#E30613"))
		row.add_child(name_lbl)

		var score_lbl = Label.new()
		score_lbl.text = str(score_entry.get("score", 0))
		score_lbl.custom_minimum_size = Vector2(100, 0)
		row.add_child(score_lbl)

		var level_lbl = Label.new()
		level_lbl.text = str(score_entry.get("level", 1))
		level_lbl.custom_minimum_size = Vector2(80, 0)
		row.add_child(level_lbl)

		rank += 1


func _on_classic_pressed() -> void:
	_play_click_sound()
	SettingsManager.current_mode = SettingsManager.GameMode.CLASSIC
	SettingsManager.save_settings()
	get_tree().change_scene_to_file("res://scenes/playfield.tscn")


func _on_expo_pressed() -> void:
	_play_click_sound()
	SettingsManager.current_mode = SettingsManager.GameMode.EXPO
	SettingsManager.save_settings()
	get_tree().change_scene_to_file("res://scenes/playfield.tscn")


func _on_quit_pressed() -> void:
	_play_click_sound()
	get_tree().quit()


func _on_sound_pressed() -> void:
	SettingsManager.is_sound_enabled = not SettingsManager.is_sound_enabled
	SettingsManager.save_settings()
	_update_sound_button_text()
	_play_click_sound()


func _update_sound_button_text() -> void:
	if _sound_btn != null:
		_sound_btn.text = "Ton: AN" if SettingsManager.is_sound_enabled else "Ton: AUS"


func _play_click_sound() -> void:
	if SettingsManager.is_sound_enabled and _sfx_click != null:
		_sfx_click.play()
