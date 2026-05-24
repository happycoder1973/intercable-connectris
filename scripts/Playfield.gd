class_name Playfield
extends Node2D
## Verwaltet die Spielschleife, Punkteberechnung, Eingaben und den fallenden Block.

signal score_changed(new_score: int, level: int)
signal level_up(new_level: int, level_name: String)
signal game_over_triggered(final_score: int)
signal crimp_press_started(row_index: int)
signal crimp_press_completed(row_index: int)
signal timer_updated(time_left: float)

const LEVEL_THEMES: Dictionary = {
	1: {"name": "Werkstatt", "color_start": Color("#1a1e29"), "color_end": Color("#10121a")},
	2: {"name": "Baustelle", "color_start": Color("#262016"), "color_end": Color("#14100b")},
	3: {"name": "Industrieanlage", "color_start": Color("#1c2420"), "color_end": Color("#0e1210")},
	4: {"name": "E-Verteilerraum", "color_start": Color("#132237"), "color_end": Color("#0a121e")},
	5: {"name": "Windpark", "color_start": Color("#1b2e2d"), "color_end": Color("#0f1a1a")},
	6: {"name": "Automobilwerk", "color_start": Color("#2b181a"), "color_end": Color("#160c0d")},
	7: {"name": "Solarpark", "color_start": Color("#2d2715"), "color_end": Color("#17130b")},
	8: {"name": "Rechenzentrum", "color_start": Color("#112d1b"), "color_end": Color("#09170e")},
	9: {"name": "U-Bahn-Tunnel", "color_start": Color("#261e1b"), "color_end": Color("#130f0d")},
	10:
	{
		"name": "Dolomiten-Entwicklungslabor",
		"color_start": Color("#291515"),
		"color_end": Color("#150a0a")
	}
}

const LOADING_TIPS: Array[String] = [
	"Werkzeuge werden in den Dolomiten entwickelt – Praezision wie bei gutem Speck.",
	"AMX-Laser laedt... Abisolieren auf Knopfdruck. Schneller als jeder Seitenschneider!",
	"STILO60 sagt: Sicherheit zuerst! Eine saubere Pressung verhindert den Kurzschluss.",
	"Crimpen ist wie Knoedel drehen: Es braucht den richtigen Druck und das richtige Gefuehl.",
	"Der Slick-Cutter schneidet sauberer als Oma den Apfelstrudel portioniert.",
	"VDE-Schutzschild bereit. Sicherer als ein Doppelpass beim Wattn im Wirtshaus.",
	"Wichtig: Ein schief gecrimpter Kabelschuh ist wie warmer Lagrein – einfach ungeniessbar.",
	"Hast du gewusst? Unsere Werkzeuge halten laenger als der kaelteste Winter."
]

@export var fall_interval_start: float = 1.0

var grid: Grid
var current_block: Block
var force_loading_screen: bool = false

var _fall_timer: float = 0.0
var _fall_interval: float = 1.0
var _score: int = 0
var _level: int = 1
var _total_rows_cleared: int = 0
var _game_over: bool = false
var _is_animating_press: bool = false
var _shield_time_left: float = 0.0
var _time_left: float = 0.0

var _milestones_shown: Dictionary = {
	"shield": false, "level_3": false, "level_5": false, "level_10": false
}

var _touch_start_pos: Vector2 = Vector2.ZERO
var _touch_start_time: int = 0
var _last_joy_axis_x: float = 0.0
var _last_joy_axis_y: float = 0.0
var _highscore_db: HighscoreDB

# Programmatische UI-Referenzen
var _bg_rect: TextureRect
var _level_label: Label
var _score_label: Label
var _timer_label: Label
var _level_up_banner: CenterContainer
var _level_up_title: Label
var _level_up_name: Label

@onready var _press_overlay: Node2D = get_node_or_null("PressOverlay")
@onready var _sfx_press: AudioStreamPlayer = get_node_or_null("SfxPress")
@onready var _spark_particles: CPUParticles2D = get_node_or_null("SparkParticles")
@onready var _camera: Camera2D = get_node_or_null("Camera2D")
@onready var _shield_overlay: Panel = get_node_or_null("ShieldOverlay")
@onready var _sfx_laser: AudioStreamPlayer = get_node_or_null("SfxLaser")
@onready var _sfx_cut: AudioStreamPlayer = get_node_or_null("SfxCut")


func _ready() -> void:
	_score = 0
	_level = 1
	_total_rows_cleared = 0
	_game_over = false
	_highscore_db = HighscoreDB.new()
	_fall_interval = fall_interval_start

	_create_ui_and_background()

	if grid == null:
		if has_node("Grid"):
			grid = $Grid as Grid
		else:
			grid = Grid.new()
			add_child(grid)

	update_difficulty()
	_update_background_colors()
	spawn_new_block()

	if SettingsManager.current_mode == SettingsManager.GameMode.EXPO:
		_time_left = SettingsManager.expo_round_duration
		if _timer_label != null:
			_timer_label.visible = true

	if not _is_running_in_test() or force_loading_screen:
		_show_loading_screen()


func _process(p_delta: float) -> void:
	if _shield_time_left > 0.0:
		_shield_time_left = max(0.0, _shield_time_left - p_delta)
		if _shield_overlay != null:
			_shield_overlay.visible = _shield_time_left > 0.0

	if SettingsManager.current_mode == SettingsManager.GameMode.EXPO and not _game_over:
		_time_left = max(0.0, _time_left - p_delta)
		timer_updated.emit(_time_left)
		if _timer_label != null:
			_timer_label.text = "ZEIT: %d" % ceil(_time_left)
		if _time_left <= 0.0:
			_trigger_game_over(true)

	if _game_over or _is_animating_press:
		return

	handle_input()

	_fall_timer += p_delta
	if _fall_timer >= _fall_interval:
		_fall_timer = 0.0
		move_block_down()


func _unhandled_input(p_event: InputEvent) -> void:
	if _game_over or _is_animating_press or current_block == null:
		return

	# Keyboard Input
	if p_event is InputEventKey and p_event.pressed:
		match p_event.keycode:
			KEY_LEFT, KEY_A:
				move_block_horizontal(-1)
			KEY_RIGHT, KEY_D:
				move_block_horizontal(1)
			KEY_UP, KEY_W:
				rotate_block()
			KEY_DOWN, KEY_S:
				move_block_down()
				_fall_timer = 0.0
			KEY_SPACE:
				hard_drop()

	# Touch Input (Wischgesten & Taps)
	elif p_event is InputEventScreenTouch:
		if p_event.pressed:
			_touch_start_pos = p_event.position
			_touch_start_time = Time.get_ticks_msec()
		else:
			var swipe_vec = p_event.position - _touch_start_pos
			var elapsed = Time.get_ticks_msec() - _touch_start_time
			if swipe_vec.length() < 30 and elapsed < 300:
				rotate_block()
			elif swipe_vec.length() >= 50:
				if abs(swipe_vec.x) > abs(swipe_vec.y):
					if swipe_vec.x < 0:
						move_block_horizontal(-1)
					else:
						move_block_horizontal(1)
				else:
					if swipe_vec.y > 0:
						hard_drop()
						_fall_timer = 0.0

	# Gamepad Buttons Input
	elif p_event is InputEventJoypadButton and p_event.pressed:
		var pm = get_node_or_null("PowerUpManager")
		match p_event.button_index:
			JOY_BUTTON_A, JOY_BUTTON_DPAD_UP:
				rotate_block()
			JOY_BUTTON_DPAD_LEFT:
				move_block_horizontal(-1)
			JOY_BUTTON_DPAD_RIGHT:
				move_block_horizontal(1)
			JOY_BUTTON_DPAD_DOWN:
				move_block_down()
				_fall_timer = 0.0
			JOY_BUTTON_X:
				if pm != null:
					pm.trigger_powerup(1)
			JOY_BUTTON_Y:
				if pm != null:
					pm.trigger_powerup(2)
			JOY_BUTTON_B:
				if pm != null:
					pm.trigger_powerup(3)
			JOY_BUTTON_LEFT_SHOULDER, JOY_BUTTON_RIGHT_SHOULDER:
				if pm != null:
					pm.trigger_powerup(4)

	# Gamepad Stick Analog Input
	elif p_event is InputEventJoypadMotion:
		if p_event.axis == JOY_AXIS_LEFT_X:
			if abs(p_event.axis_value) < 0.2:
				_last_joy_axis_x = 0.0
			elif p_event.axis_value < -0.5 and _last_joy_axis_x >= -0.5:
				_last_joy_axis_x = p_event.axis_value
				move_block_horizontal(-1)
			elif p_event.axis_value > 0.5 and _last_joy_axis_x <= 0.5:
				_last_joy_axis_x = p_event.axis_value
				move_block_horizontal(1)
		elif p_event.axis == JOY_AXIS_LEFT_Y:
			if abs(p_event.axis_value) < 0.2:
				_last_joy_axis_y = 0.0
			elif p_event.axis_value > 0.5 and _last_joy_axis_y <= 0.5:
				_last_joy_axis_y = p_event.axis_value
				move_block_down()
				_fall_timer = 0.0


func handle_input() -> void:
	pass


func spawn_new_block() -> void:
	if _game_over:
		return

	var shape: int = randi() % 7
	current_block = Block.new()
	add_child(current_block)
	current_block.initialize(shape)

	# Startposition in der Mitte der ersten Zeile
	current_block.grid_position = Vector2i(3, 0)
	_update_block_visual_position()

	# Auf sofortige Kollision prüfen (Game Over)
	if not grid.is_valid_position(current_block, Vector2i.ZERO):
		if is_shield_active():
			_shield_time_left = 0.0
			if _shield_overlay != null:
				_shield_overlay.visible = false
			grid.clear_bottom_rows(5)
			_trigger_camera_shake()
			if _sfx_press != null:
				_sfx_press.play()
			_update_block_visual_position()
		else:
			_trigger_game_over(false)


func move_block_down() -> void:
	if current_block == null or _game_over or _is_animating_press:
		return

	if grid.is_valid_position(current_block, Vector2i(0, 1)):
		current_block.grid_position.y += 1
		_update_block_visual_position()
	else:
		grid.lock_block(current_block)
		current_block.queue_free()
		current_block = null

		var status: Dictionary = grid.check_full_rows_status()
		var valid_rows: Array = status["valid"]

		if valid_rows.size() > 0:
			_animate_press_sequence(valid_rows)
		else:
			spawn_new_block()


func move_block_horizontal(p_dir: int) -> void:
	if current_block == null or _game_over or _is_animating_press:
		return

	if grid.is_valid_position(current_block, Vector2i(p_dir, 0)):
		current_block.grid_position.x += p_dir
		_update_block_visual_position()


func rotate_block() -> void:
	if current_block == null or _game_over or _is_animating_press:
		return

	current_block.rotate_right()
	if not grid.is_valid_position(current_block, Vector2i.ZERO):
		current_block.rotate_left()


func hard_drop() -> void:
	if current_block == null or _game_over or _is_animating_press:
		return

	while grid.is_valid_position(current_block, Vector2i(0, 1)):
		current_block.grid_position.y += 1
	_update_block_visual_position()
	move_block_down()


func update_difficulty() -> void:
	_fall_interval = max(0.1, fall_interval_start - (_level - 1) * 0.1)


func _update_block_visual_position() -> void:
	if current_block != null:
		current_block.position = Vector2(
			current_block.grid_position.x * Grid.CELL_SIZE,
			current_block.grid_position.y * Grid.CELL_SIZE
		)


func _add_score(p_cleared_rows: int) -> void:
	_score += p_cleared_rows
	_total_rows_cleared += p_cleared_rows
	var old_level = _level
	_level = 1 + (_total_rows_cleared / 10)

	if _score_label != null:
		_score_label.text = "PUNKTE: %d" % _score
	if _level_label != null:
		_level_label.text = "LEVEL: %d" % _level

	if _level > old_level:
		_on_level_up(old_level, _level)

	update_difficulty()
	score_changed.emit(_score, _level)


func _animate_press_sequence(p_valid_rows: Array) -> void:
	_is_animating_press = true
	p_valid_rows.sort()

	for row in p_valid_rows:
		crimp_press_started.emit(row)

		if _press_overlay != null:
			_press_overlay.position.x = 0
			_press_overlay.position.y = -Grid.CELL_SIZE
			_press_overlay.show()

		var tween := create_tween()
		var target_y: float = row * Grid.CELL_SIZE

		if _press_overlay != null:
			(
				tween
				. tween_property(_press_overlay, "position:y", target_y, 0.4)
				. set_trans(Tween.TRANS_QUAD)
				. set_ease(Tween.EASE_OUT)
			)
		else:
			tween.tween_interval(0.1)

		tween.tween_callback(
			func():
				_trigger_rumble(0.4, 0.4, 0.2)
				if _sfx_press != null:
					_sfx_press.play()
				if _spark_particles != null:
					var half_w: float = (Grid.COLUMNS * Grid.CELL_SIZE) / 2.0
					var center_y: float = target_y + Grid.CELL_SIZE / 2.0
					_spark_particles.position = Vector2(half_w, center_y)
					_spark_particles.restart()
		)

		tween.tween_interval(0.15)

		tween.tween_callback(func(): grid.clear_row(row))

		if _press_overlay != null:
			(
				tween
				. tween_property(_press_overlay, "position:y", -Grid.CELL_SIZE, 0.3)
				. set_trans(Tween.TRANS_QUAD)
				. set_ease(Tween.EASE_IN)
			)
		else:
			tween.tween_interval(0.1)

		tween.tween_callback(
			func():
				if _press_overlay != null:
					_press_overlay.hide()
				crimp_press_completed.emit(row)
		)

		await tween.finished
		_add_score(1)

	_is_animating_press = false
	spawn_new_block()


func activate_vde_shield() -> void:
	_shield_time_left = 20.0
	if _shield_overlay != null:
		_shield_overlay.visible = true
	_show_milestone_popup(
		"shield",
		"VDE-SICHERHEITSSCHILD ANE!",
		(
			"Das VDE-Schutzschild schuetzt dich vor Fehlern. "
			+ "Mit isolierten Werkzeugen bist du bis 1000 Volt geschuetzt."
		)
	)


func is_shield_active() -> bool:
	return _shield_time_left > 0.0


func _trigger_camera_shake() -> void:
	_trigger_rumble(0.6, 0.6, 0.4)
	if _camera == null:
		return

	var tween = create_tween()
	var shake_strength: float = 15.0
	var step_time: float = 0.03

	for i in range(10):
		var random_offset = Vector2(
			randf_range(-shake_strength, shake_strength),
			randf_range(-shake_strength, shake_strength)
		)
		tween.tween_property(_camera, "offset", random_offset, step_time)
		shake_strength *= 0.9

	tween.tween_property(_camera, "offset", Vector2.ZERO, step_time)


func _trigger_game_over(p_was_time_out: bool) -> void:
	if _game_over:
		return
	_game_over = true
	_trigger_rumble(0.8, 0.8, 0.5)
	game_over_triggered.emit(_score)
	if current_block != null:
		current_block.queue_free()
		current_block = null

	var overlay_scene = load("res://scenes/game_over_overlay.tscn")
	var overlay = overlay_scene.instantiate()
	add_child(overlay)
	overlay.initialize(_score, _level, p_was_time_out)
	overlay.name_input_requested.connect(_on_name_input_requested)


func _on_name_input_requested() -> void:
	var keyboard = KeyboardOverlay.new()
	keyboard.name = "KeyboardOverlay"
	var ui_layer = get_node_or_null("UILayer")
	if ui_layer != null:
		ui_layer.add_child(keyboard)
	else:
		add_child(keyboard)
	keyboard.initials_entered.connect(_on_initials_entered)


func _on_initials_entered(p_initials: String) -> void:
	if _highscore_db != null:
		_highscore_db.add_highscore(p_initials, _score, _level)
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")


func _create_ui_and_background() -> void:
	# Background CanvasLayer
	var bg_layer = CanvasLayer.new()
	bg_layer.name = "BackgroundLayer"
	bg_layer.layer = -100
	add_child(bg_layer)

	_bg_rect = TextureRect.new()
	_bg_rect.name = "BackgroundRect"
	_bg_rect.anchor_right = 1.0
	_bg_rect.anchor_bottom = 1.0
	_bg_rect.offset_left = 0
	_bg_rect.offset_top = 0
	_bg_rect.offset_right = 0
	_bg_rect.offset_bottom = 0
	_bg_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	bg_layer.add_child(_bg_rect)

	var bg_texture = GradientTexture2D.new()
	bg_texture.width = 256
	bg_texture.height = 256
	bg_texture.fill = GradientTexture2D.FILL_LINEAR
	bg_texture.fill_from = Vector2(0.5, 0.0)
	bg_texture.fill_to = Vector2(0.5, 1.0)

	var gradient = Gradient.new()
	bg_texture.gradient = gradient
	_bg_rect.texture = bg_texture

	# UI CanvasLayer
	var ui_layer = CanvasLayer.new()
	ui_layer.name = "UILayer"
	ui_layer.layer = 10
	add_child(ui_layer)

	var hud = MarginContainer.new()
	hud.name = "HUD"
	hud.anchor_right = 1.0
	hud.offset_left = 0
	hud.offset_top = 0
	hud.offset_right = 0
	hud.offset_bottom = 60
	hud.add_theme_constant_override("margin_left", 20)
	hud.add_theme_constant_override("margin_right", 20)
	hud.add_theme_constant_override("margin_top", 20)
	ui_layer.add_child(hud)

	var hbox = HBoxContainer.new()
	hud.add_child(hbox)

	_level_label = Label.new()
	_level_label.name = "LevelLabel"
	_level_label.text = "LEVEL: 1"
	_level_label.add_theme_color_override("font_color", Color("#FFD000"))
	hbox.add_child(_level_label)

	var spacer1 = Control.new()
	spacer1.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox.add_child(spacer1)

	_timer_label = Label.new()
	_timer_label.name = "TimerLabel"
	_timer_label.text = ""
	_timer_label.visible = false
	hbox.add_child(_timer_label)

	var spacer2 = Control.new()
	spacer2.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox.add_child(spacer2)

	_score_label = Label.new()
	_score_label.name = "ScoreLabel"
	_score_label.text = "PUNKTE: 0"
	_score_label.add_theme_color_override("font_color", Color("#E30613"))
	hbox.add_child(_score_label)

	# Level Up Banner Container
	_level_up_banner = CenterContainer.new()
	_level_up_banner.name = "LevelUpBanner"
	_level_up_banner.anchor_right = 1.0
	_level_up_banner.anchor_bottom = 1.0
	_level_up_banner.offset_left = 0
	_level_up_banner.offset_top = 0
	_level_up_banner.offset_right = 0
	_level_up_banner.offset_bottom = 0
	_level_up_banner.visible = false
	_level_up_banner.pivot_offset = Vector2(0.5, 0.5)
	ui_layer.add_child(_level_up_banner)

	var panel = PanelContainer.new()
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.1, 0.1, 0.15, 0.85)
	style.border_width_left = 4
	style.border_width_top = 4
	style.border_width_right = 4
	style.border_width_bottom = 4
	style.border_color = Color("#FFD000")
	style.corner_radius_top_left = 12
	style.corner_radius_top_right = 12
	style.corner_radius_bottom_left = 12
	style.corner_radius_bottom_right = 12
	style.content_margin_left = 40
	style.content_margin_right = 40
	style.content_margin_top = 20
	style.content_margin_bottom = 20
	panel.add_theme_stylebox_override("panel", style)
	_level_up_banner.add_child(panel)

	var vbox = VBoxContainer.new()
	panel.add_child(vbox)

	_level_up_title = Label.new()
	_level_up_title.name = "TitleLabel"
	_level_up_title.text = "LEVEL UP!"
	_level_up_title.add_theme_font_size_override("font_size", 32)
	_level_up_title.add_theme_color_override("font_color", Color("#FFD000"))
	_level_up_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(_level_up_title)

	_level_up_name = Label.new()
	_level_up_name.name = "NameLabel"
	_level_up_name.text = "Werkstatt"
	_level_up_name.add_theme_font_size_override("font_size", 24)
	_level_up_name.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(_level_up_name)


func _update_background_colors() -> void:
	if _bg_rect == null or _bg_rect.texture == null:
		return
	var theme = LEVEL_THEMES.get(min(_level, 10))
	if theme:
		var gradient = _bg_rect.texture.gradient
		gradient.set_color(0, theme["color_start"])
		gradient.set_color(1, theme["color_end"])


func _on_level_up(p_old_level: int, p_new_level: int) -> void:
	var old_theme = LEVEL_THEMES.get(min(p_old_level, 10))
	var new_theme = LEVEL_THEMES.get(min(p_new_level, 10))

	if new_theme:
		level_up.emit(p_new_level, new_theme["name"])

		# Animate background transition
		if _bg_rect != null and _bg_rect.texture != null and old_theme != null:
			var gradient = _bg_rect.texture.gradient
			var tween = create_tween()
			tween.tween_method(
				func(c): gradient.set_color(0, c),
				old_theme["color_start"],
				new_theme["color_start"],
				1.5
			)
			tween.parallel().tween_method(
				func(c): gradient.set_color(1, c),
				old_theme["color_end"],
				new_theme["color_end"],
				1.5
			)

		# Play level-up visual animation
		_show_level_up_animation(new_theme["name"], p_new_level)

		# Trigger milestone popups
		if p_new_level == 3:
			_show_milestone_popup(
				"level_3",
				"BAUSTELLEN-TIPP!",
				(
					"Stufe 3 erreicht! Draußen auf der Baustelle weht ein rauer Wind. "
					+ "Sauber abisolieren mit dem AMX-Laser spart Zeit und schont die Nerven."
				)
			)
		elif p_new_level == 5:
			_show_milestone_popup(
				"level_5",
				"WINDPARK-PROFI!",
				(
					"Stufe 5 erreicht! In luftiger Höhe müssen Verbindungen standhalten. "
					+ "Die STILO60-Presse sorgt für rüttelfeste Crimpungen."
				)
			)
		elif p_new_level == 10:
			_show_milestone_popup(
				"level_10",
				"DOLOMITEN-LABOR!",
				(
					"Wahnsinn! Stufe 10 erreicht! Du bist jetzt im Entwicklungslabor. "
					+ "Hier testen wir die Grenzen der Belastbarkeit. Weiter so!"
				)
			)


func _show_level_up_animation(p_name: String, p_level: int) -> void:
	if _level_up_banner == null:
		return

	_level_up_name.text = "Stufe %d: %s" % [p_level, p_name]
	_level_up_banner.scale = Vector2(0.1, 0.1)
	_level_up_banner.pivot_offset = get_viewport_rect().size / 2.0
	_level_up_banner.visible = true

	var tween = create_tween()
	# Pop in
	(
		tween
		. tween_property(_level_up_banner, "scale", Vector2(1, 1), 0.5)
		. set_trans(Tween.TRANS_BACK)
		. set_ease(Tween.EASE_OUT)
	)
	# Play sound (pitched menu click)
	tween.tween_callback(
		func():
			var player = AudioStreamPlayer.new()
			player.stream = load("res://assets/audio/menu_klick.wav")
			player.pitch_scale = 1.5
			add_child(player)
			player.play()
			player.finished.connect(player.queue_free)
	)
	# Stay
	tween.tween_interval(1.5)
	# Pop out/fade
	(
		tween
		. tween_property(_level_up_banner, "scale", Vector2(0, 0), 0.3)
		. set_trans(Tween.TRANS_QUAD)
		. set_ease(Tween.EASE_IN)
	)
	tween.tween_callback(func(): _level_up_banner.visible = false)


func _show_milestone_popup(p_id: String, p_title: String, p_body: String) -> void:
	if _milestones_shown.get(p_id, false):
		return
	_milestones_shown[p_id] = true

	var popup = InfotainmentPopup.new()
	popup.initialize(p_title, p_body)
	var ui_layer = get_node_or_null("UILayer")
	if ui_layer != null:
		ui_layer.add_child(popup)
	else:
		add_child(popup)


func _show_loading_screen() -> void:
	var loading_layer = CanvasLayer.new()
	loading_layer.name = "LoadingLayer"
	loading_layer.layer = 20
	add_child(loading_layer)

	var bg = ColorRect.new()
	bg.name = "Background"
	bg.color = Color("#121212")
	bg.anchor_right = 1.0
	bg.anchor_bottom = 1.0
	loading_layer.add_child(bg)

	var vbox = VBoxContainer.new()
	vbox.anchor_right = 1.0
	vbox.anchor_bottom = 1.0
	vbox.offset_left = 50
	vbox.offset_right = -50
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_theme_constant_override("separation", 20)
	bg.add_child(vbox)

	var title = Label.new()
	title.text = "INTERCABLE CONNECTRIS"
	title.add_theme_font_size_override("font_size", 28)
	title.add_theme_color_override("font_color", Color("#E30613"))
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(title)

	var spinner = Label.new()
	spinner.text = "Lade Werkzeuge..."
	spinner.add_theme_font_size_override("font_size", 16)
	spinner.add_theme_color_override("font_color", Color.GRAY)
	spinner.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(spinner)

	var spin_tween = create_tween().set_loops()
	spin_tween.bind_node(spinner)
	spin_tween.tween_property(spinner, "modulate:a", 0.3, 0.4)
	spin_tween.tween_property(spinner, "modulate:a", 1.0, 0.4)

	var separator = Control.new()
	separator.custom_minimum_size = Vector2(0, 20)
	vbox.add_child(separator)

	var tip_label = Label.new()
	randomize()
	var random_tip = LOADING_TIPS[randi() % LOADING_TIPS.size()]
	tip_label.text = "TIPP:\n%s" % random_tip
	tip_label.add_theme_font_size_override("font_size", 16)
	tip_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	tip_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	vbox.add_child(tip_label)

	_is_animating_press = true

	var fade_tween = create_tween()
	fade_tween.tween_interval(2.0)
	fade_tween.tween_property(bg, "modulate:a", 0.0, 0.5)
	fade_tween.tween_callback(
		func():
			if spin_tween.is_valid():
				spin_tween.kill()
			_is_animating_press = false
			loading_layer.queue_free()
	)


func _is_running_in_test() -> bool:
	for arg in OS.get_cmdline_args():
		if "gut" in arg.to_lower():
			return true
	if get_parent() != null and "gut" in get_parent().name.to_lower():
		return true
	return false


func _trigger_rumble(p_weak: float, p_strong: float, p_duration: float) -> void:
	var joypads = Input.get_connected_joypads()
	if joypads.size() > 0:
		Input.start_joy_vibration(joypads[0], p_weak, p_strong, p_duration)
