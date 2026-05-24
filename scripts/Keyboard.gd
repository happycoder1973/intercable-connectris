class_name KeyboardOverlay
extends CenterContainer
## Eine touch-optimierte Bildschirmtastatur zur Eingabe von Initialen (max 3 Zeichen).

signal initials_entered(initials: String)

var _initials: String = ""
var _display_label: Label
var _ok_button: Button


func _ready() -> void:
	process_mode = PROCESS_MODE_ALWAYS

	# Full screen overlay background
	var overlay = ColorRect.new()
	overlay.color = Color(0, 0, 0, 0.7)
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
	style.border_color = Color("#FFD000")
	style.corner_radius_top_left = 16
	style.corner_radius_top_right = 16
	style.corner_radius_bottom_left = 16
	style.corner_radius_bottom_right = 16
	style.content_margin_left = 25
	style.content_margin_right = 25
	style.content_margin_top = 25
	style.content_margin_bottom = 25
	panel.add_theme_stylebox_override("panel", style)
	add_child(panel)

	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 20)
	panel.add_child(vbox)

	# Display
	var display_panel = PanelContainer.new()
	var display_style = StyleBoxFlat.new()
	display_style.bg_color = Color(0.05, 0.05, 0.07, 1.0)
	display_style.border_width_left = 2
	display_style.border_width_top = 2
	display_style.border_width_right = 2
	display_style.border_width_bottom = 2
	display_style.border_color = Color.DARK_GRAY
	display_style.corner_radius_top_left = 8
	display_style.corner_radius_top_right = 8
	display_style.corner_radius_bottom_left = 8
	display_style.corner_radius_bottom_right = 8
	display_style.content_margin_left = 20
	display_style.content_margin_right = 20
	display_style.content_margin_top = 10
	display_style.content_margin_bottom = 10
	display_panel.add_theme_stylebox_override("panel", display_style)
	vbox.add_child(display_panel)

	_display_label = Label.new()
	_display_label.text = "[ _ _ _ ]"
	_display_label.add_theme_font_size_override("font_size", 36)
	_display_label.add_theme_color_override("font_color", Color("#FFD000"))
	_display_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	display_panel.add_child(_display_label)

	# Grid Container for Keys
	var grid = GridContainer.new()
	grid.columns = 7
	grid.add_theme_constant_override("h_separation", 10)
	grid.add_theme_constant_override("v_separation", 10)
	vbox.add_child(grid)

	var keys = [
		"A",
		"B",
		"C",
		"D",
		"E",
		"F",
		"G",
		"H",
		"I",
		"J",
		"K",
		"L",
		"M",
		"N",
		"O",
		"P",
		"Q",
		"R",
		"S",
		"T",
		"U",
		"V",
		"W",
		"X",
		"Y",
		"Z",
		"<",
		"OK"
	]

	for key in keys:
		var btn = Button.new()
		btn.text = key
		btn.custom_minimum_size = Vector2(50, 50)
		btn.add_theme_font_size_override("font_size", 18)

		var style_normal = StyleBoxFlat.new()
		style_normal.corner_radius_top_left = 6
		style_normal.corner_radius_top_right = 6
		style_normal.corner_radius_bottom_left = 6
		style_normal.corner_radius_bottom_right = 6

		if key == "OK":
			style_normal.bg_color = Color("#E30613")
			_ok_button = btn
			_ok_button.disabled = true
		elif key == "<":
			style_normal.bg_color = Color("#2A2B2C")
			style_normal.border_width_left = 1
			style_normal.border_width_top = 1
			style_normal.border_width_right = 1
			style_normal.border_width_bottom = 1
			style_normal.border_color = Color("#E30613")
		else:
			style_normal.bg_color = Color("#2A2B2C")

		btn.add_theme_stylebox_override("normal", style_normal)

		var style_hover = style_normal.duplicate()
		if key == "OK":
			style_hover.bg_color = Color("#f02e3b")
		else:
			style_hover.bg_color = Color("#3e3f41")
		btn.add_theme_stylebox_override("hover", style_hover)

		btn.pressed.connect(func(): _on_key_pressed(key))
		grid.add_child(btn)


func _on_key_pressed(p_key: String) -> void:
	if p_key == "OK":
		if _initials.length() > 0:
			initials_entered.emit(_initials)
			queue_free()
	elif p_key == "<":
		if _initials.length() > 0:
			_initials = _initials.substr(0, _initials.length() - 1)
			_update_display()
	else:
		if _initials.length() < 3:
			_initials += p_key
			_update_display()


func _update_display() -> void:
	var display_text = ""
	for i in range(3):
		if i < _initials.length():
			display_text += _initials[i] + " "
		else:
			display_text += "_ "
	_display_label.text = "[ " + display_text.strip_edges() + " ]"
	if _ok_button != null:
		_ok_button.disabled = _initials.length() == 0
