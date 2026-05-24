extends GutTest
## Testet die Highscore-Datenbank und die Bildschirmtastatur.

const HighscoreDBClass = preload("res://scripts/HighscoreDB.gd")
const KeyboardClass = preload("res://scripts/Keyboard.gd")


func test_highscore_db_add_and_retrieve() -> void:
	var db = HighscoreDBClass.new()

	var dir = DirAccess.open("user://")
	if dir != null:
		dir.remove("highscores.cfg")
		dir.remove("highscores_backup.cfg")

	db._initialize_fallback()

	db.add_highscore("AAA", 100, 2)
	db.add_highscore("BBB", 250, 5)
	db.add_highscore("CCC", 50, 1)

	var top_scores = db.get_top_highscores(5)
	assert_eq(top_scores.size(), 3, "Should return 3 entries")

	assert_eq(top_scores[0]["initials"], "BBB", "BBB should be first with 250")
	assert_eq(top_scores[0]["score"], 250)

	assert_eq(top_scores[1]["initials"], "AAA", "AAA should be second with 100")
	assert_eq(top_scores[1]["score"], 100)

	assert_eq(top_scores[2]["initials"], "CCC", "CCC should be third with 50")


func test_keyboard_input_limits() -> void:
	var keyboard = KeyboardClass.new()
	add_child(keyboard)

	keyboard._on_key_pressed("A")
	keyboard._on_key_pressed("B")
	keyboard._on_key_pressed("C")
	keyboard._on_key_pressed("D")

	assert_eq(keyboard._initials, "ABC", "Initials should be capped at 3 characters")

	keyboard._on_key_pressed("<")
	assert_eq(keyboard._initials, "AB", "Backspace should remove last character")

	keyboard._on_key_pressed("X")
	assert_eq(keyboard._initials, "ABX", "Should append X to get ABX")

	keyboard.free()
