class_name HighscoreDB
extends RefCounted
## Verwaltet die Highscores des Spiels.
## Verwendet godot-sqlite GDExtension falls vorhanden, sonst ConfigFile-Speicherung.

const DB_PATH: String = "user://highscore.db"
const FALLBACK_PATH: String = "user://highscores.cfg"
const BACKUP_PATH: String = "user://highscores_backup.cfg"

var _use_sqlite: bool = false
var _db_instance: RefCounted = null


func _init() -> void:
	if ClassDB.class_exists("SQLite"):
		_use_sqlite = true
		_db_instance = ClassDB.instantiate("SQLite")
		_initialize_sqlite()
	else:
		_use_sqlite = false
		_initialize_fallback()


func _initialize_sqlite() -> void:
	_db_instance.path = DB_PATH
	_db_instance.open_db()
	_db_instance.query(
		(
			"CREATE TABLE IF NOT EXISTS highscores ("
			+ "id INTEGER PRIMARY KEY AUTOINCREMENT, "
			+ "initials TEXT NOT NULL, "
			+ "score INTEGER NOT NULL, "
			+ "level INTEGER NOT NULL, "
			+ "date TEXT NOT NULL);"
		)
	)


func _initialize_fallback() -> void:
	if not FileAccess.file_exists(FALLBACK_PATH) and FileAccess.file_exists(BACKUP_PATH):
		var dir = DirAccess.open("user://")
		if dir != null:
			dir.copy(BACKUP_PATH, FALLBACK_PATH)

	if not FileAccess.file_exists(FALLBACK_PATH):
		var config = ConfigFile.new()
		config.set_value("highscores", "list", [])
		config.save(FALLBACK_PATH)


func add_highscore(p_initials: String, p_score: int, p_level: int) -> void:
	var date_str: String = Time.get_datetime_string_from_system(true) + "Z"

	if _use_sqlite:
		var query_str = (
			"INSERT INTO highscores (initials, score, level, date) VALUES ('%s', %d, %d, '%s');"
			% [p_initials, p_score, p_level, date_str]
		)
		_db_instance.query(query_str)
	else:
		var config = ConfigFile.new()
		config.load(FALLBACK_PATH)
		var list: Array = config.get_value("highscores", "list", [])

		var entry = {
			"initials": p_initials.substr(0, 3).to_upper(),
			"score": p_score,
			"level": p_level,
			"date": date_str
		}
		list.append(entry)
		config.set_value("highscores", "list", list)

		config.save(BACKUP_PATH)
		config.save(FALLBACK_PATH)


func get_top_highscores(p_limit: int = 10) -> Array[Dictionary]:
	var result: Array[Dictionary] = []

	if _use_sqlite:
		_db_instance.query(
			(
				"SELECT initials, score, level, date FROM highscores "
				+ "ORDER BY score DESC, date ASC LIMIT %d;" % p_limit
			)
		)
		for row in _db_instance.query_result:
			result.append(
				{
					"initials": str(row.get("initials", "")),
					"score": int(row.get("score", 0)),
					"level": int(row.get("level", 0)),
					"date": str(row.get("date", ""))
				}
			)
	else:
		var config = ConfigFile.new()
		config.load(FALLBACK_PATH)
		var list: Array = config.get_value("highscores", "list", [])

		list.sort_custom(
			func(a, b):
				if a["score"] != b["score"]:
					return a["score"] > b["score"]
				return a["date"] < b["date"]
		)

		var limit = min(p_limit, list.size())
		for i in range(limit):
			var entry = list[i]
			result.append(
				{
					"initials": str(entry["initials"]),
					"score": int(entry["score"]),
					"level": int(entry["level"]),
					"date": str(entry["date"])
				}
			)

	return result
