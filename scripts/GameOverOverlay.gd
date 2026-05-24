class_name GameOverOverlay
extends Control

signal name_input_requested

@onready var _title_label: Label = $Panel/VBoxContainer/TitleLabel
@onready var _score_label: Label = $Panel/VBoxContainer/ScoreLabel
@onready var _level_label: Label = $Panel/VBoxContainer/LevelLabel
@onready var _continue_button: Button = $Panel/VBoxContainer/ContinueButton


func _ready() -> void:
	if _continue_button != null:
		_continue_button.pressed.connect(_on_ContinueButton_pressed)


func initialize(p_score: int, p_level: int, p_was_time_out: bool) -> void:
	if _title_label != null:
		_title_label.text = "ZEIT ABGELAUFEN!" if p_was_time_out else "GAME OVER"
	if _score_label != null:
		_score_label.text = "Erreichte Punkte: %d" % p_score
	if _level_label != null:
		_level_label.text = "Level: %d" % p_level


func _on_ContinueButton_pressed() -> void:
	name_input_requested.emit()
	queue_free()
