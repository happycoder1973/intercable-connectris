class_name InfotainmentPopup
extends CenterContainer
## Zeigt ein Comic-Infotainment-Popup bei bestimmten Meilensteinen an.

signal closed

var initial_title: String = ""
var initial_body: String = ""

var _title_label: Label
var _body_label: Label
var _btn_close: Button


func _ready() -> void:
	process_mode = PROCESS_MODE_ALWAYS
	get_tree().paused = true

	# Set container anchors to cover full screen
	anchor_right = 1.0
	anchor_bottom = 1.0
	offset_left = 0
	offset_top = 0
	offset_right = 0
	offset_bottom = 0

	# Dark background overlay
	var overlay = ColorRect.new()
	overlay.color = Color(0, 0, 0, 0.6)
	overlay.anchor_right = 1.0
	overlay.anchor_bottom = 1.0
	add_child(overlay)
	move_child(overlay, 0)

	var panel = PanelContainer.new()
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.12, 0.12, 0.15, 0.95)
	style.border_width_left = 4
	style.border_width_top = 4
	style.border_width_right = 4
	style.border_width_bottom = 4
	style.border_color = Color("#E30613")
	style.corner_radius_top_left = 16
	style.corner_radius_top_right = 16
	style.corner_radius_bottom_left = 16
	style.corner_radius_bottom_right = 16
	style.content_margin_left = 30
	style.content_margin_right = 30
	style.content_margin_top = 25
	style.content_margin_bottom = 25
	panel.add_theme_stylebox_override("panel", style)
	add_child(panel)

	# Set panel width constraint
	panel.custom_minimum_size = Vector2(400, 250)

	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 15)
	panel.add_child(vbox)

	_title_label = Label.new()
	_title_label.name = "TitleLabel"
	_title_label.text = initial_title
	_title_label.add_theme_font_size_override("font_size", 22)
	_title_label.add_theme_color_override("font_color", Color("#FFD000"))
	_title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(_title_label)

	_body_label = Label.new()
	_body_label.name = "BodyLabel"
	_body_label.text = initial_body
	_body_label.add_theme_font_size_override("font_size", 16)
	_body_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_body_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	vbox.add_child(_body_label)

	var spacer = Control.new()
	spacer.custom_minimum_size = Vector2(0, 5)
	vbox.add_child(spacer)

	_btn_close = Button.new()
	_btn_close.name = "CloseButton"
	_btn_close.text = "WEITER"

	var btn_style_normal = StyleBoxFlat.new()
	btn_style_normal.bg_color = Color("#E30613")
	btn_style_normal.corner_radius_top_left = 8
	btn_style_normal.corner_radius_top_right = 8
	btn_style_normal.corner_radius_bottom_left = 8
	btn_style_normal.corner_radius_bottom_right = 8
	btn_style_normal.content_margin_left = 20
	btn_style_normal.content_margin_right = 20
	btn_style_normal.content_margin_top = 8
	btn_style_normal.content_margin_bottom = 8

	var btn_style_hover = btn_style_normal.duplicate()
	btn_style_hover.bg_color = Color("#f02e3b")

	_btn_close.add_theme_stylebox_override("normal", btn_style_normal)
	_btn_close.add_theme_stylebox_override("hover", btn_style_hover)
	_btn_close.add_theme_stylebox_override("pressed", btn_style_normal)
	_btn_close.add_theme_color_override("font_color", Color.WHITE)
	_btn_close.pressed.connect(_on_close_pressed)
	vbox.add_child(_btn_close)


func initialize(p_title: String, p_body: String) -> void:
	initial_title = p_title
	initial_body = p_body
	if _title_label != null:
		_title_label.text = p_title
	if _body_label != null:
		_body_label.text = p_body


func _on_close_pressed() -> void:
	var player = AudioStreamPlayer.new()
	player.stream = load("res://assets/audio/menu_klick.wav")
	player.pitch_scale = 1.0
	get_parent().add_child(player)
	player.play()
	player.finished.connect(player.queue_free)

	get_tree().paused = false
	closed.emit()
	queue_free()
