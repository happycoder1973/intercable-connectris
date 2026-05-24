# GDScript Stil- und Codekonventionen (CONVENTIONS.md)

Dieses Dokument definiert die Programmier- und Formatierungskonventionen für das Projekt **Intercable Connectris**. Jedes hinzugefügte GDScript-Skript muss diesen Richtlinien entsprechen, um die statische Codeanalyse (Linter) erfolgreich zu durchlaufen.

> [!NOTE]
> Dieses Dokument wird von **Claude Code** (Senior Engineer & Architect) befüllt und gepflegt.

---

## 1. Code-Formatierung & Linter-Vorgaben

Das Projekt verwendet `gdformat` und `gdlint` zur automatischen Code-Überprüfung. 

* **Einrückung**: Es werden **Tabs** verwendet (keine Leerzeichen für die Einrückung, `mixed-tabs-and-spaces` ist verboten).
* **Maximale Zeilenlänge**: **100 Zeichen**. Zeilen, die diese Länge überschreiten, müssen sinnvoll umgebrochen werden.
* **Typisierung**: Alle Variablen, Funktionsparameter und Rückgabewerte müssen **explizit typisiert** werden, um Typsicherheit und bessere IDE-Autovervollständigung zu gewährleisten (z. B. `var score: int = 0` statt `var score = 0`).

---

## 2. Strukturierung von Klassen-Dateien

Innerhalb eines Skripts müssen Definitionen in einer festen Reihenfolge angeordnet sein. Dies wird durch die Linter-Regel `class-definitions-order` erzwungen:

1. **Tool-Direktive**: `@tool` (falls vorhanden)
2. **Klassenname**: `class_name PascalCase`
3. **Vererbung**: `extends BaseClass`
4. **Klassen-Docstring**: Kurze Beschreibung der Klasse
5. **Signale**: `signal signal_name(...)`
6. **Enums**: `enum EnumName { ... }`
7. **Konstanten**: `const CONSTANT_NAME = ...`
8. **Statische Variablen**: `static var static_variable`
9. **Exportierte Variablen**: `@export var export_var: Type`
10. **Öffentliche Variablen**: `var public_var: Type`
11. **Private Variablen**: `var _private_var: Type` (mit führendem Unterstrich)
12. **Onready öffentliche Variablen**: `@onready var onready_pub_var: Type`
13. **Onready private Variablen**: `@onready var _onready_prv_var: Type`
14. **Funktionen**: (Konstruktoren, Engine-Callbacks, eigene Methoden)

---

## 3. Benennungsregeln (Naming Conventions)

| Typ | Stil | Beispiel |
| :--- | :--- | :--- |
| **Dateinamen (Klassen)** | PascalCase | `Playfield.gd`, `TetrisGrid.gd` |
| **Dateinamen (Szenen)** | snake_case | `playfield.tscn`, `main_menu.tscn` |
| **Klassennamen** | PascalCase | `class_name Playfield` |
| **Lokale & Klassen-Variablen** | snake_case | `current_score`, `fall_interval` |
| **Private Variablen** | snake_case (führender `_`) | `_textures`, `_fall_timer` |
| **Funktionsnamen** | snake_case | `spawn_block()`, `move_left()` |
| **Private Funktionen** | snake_case (führender `_`) | `_init_grid()`, `_load_textures()` |
| **Signalnamen** | snake_case | `signal score_changed(value)` |
| **Konstanten** | UPPER_SNAKE_CASE | `const MAX_LEVEL: int = 10` |
| **Enum-Namen** | PascalCase | `enum SegmentType` |
| **Enum-Elemente** | UPPER_SNAKE_CASE | `ISOLATED`, `BARE`, `CRIMP_LUG` |
| **Methodenparameter** | snake_case (Präfix `p_` empfohlen) | `func initialize(p_shape_type: int)` |

---

## 4. Signal- und Kommunikationsmuster

* **Nach unten aufrufen, nach oben signalisieren**: 
  Eltern-Nodes rufen Methoden von Kind-Nodes direkt auf (z. B. `grid.lock_block(...)`). Kind-Nodes kommunizieren mit ihren Eltern ausschließlich über Signale (z. B. signalisiert `PlayfieldScene` an `MainRoot`, wenn ein Game Over eintritt).
* **Signal-Verbindung**: 
  Die Verbindung von Signalen im Code soll bevorzugt über die neue Godot 4 Syntax erfolgen:
  ```gdscript
  # Richtig:
  button.pressed.connect(_on_Button_pressed)
  
  # Falsch (Godot 3 Stil):
  button.connect("pressed", self, "_on_Button_pressed")
  ```
* **Signal-Methodennamen**: 
  Empfänger-Methoden für Signale werden nach dem Muster `_on_SenderName_signal_name` benannt:
  ```gdscript
  func _on_Grid_rows_cleared(count: int) -> void:
      _add_score(count * 100)
  ```

---

## 5. Vorlage für Skripte (Script Template)

Jedes neue GDScript-Skript sollte folgendem Muster folgen:

```gdscript
class_name ExampleClass
extends Node2D
## Kurze Beschreibung der Funktionalität dieses Skripts.
## Eine längere Erklärung kann hier folgen.


signal action_completed(result: Dictionary)


enum State {
	IDLE,
	BUSY,
	ERROR
}


const MAX_ITEMS: int = 100


@export var speed: float = 200.0


var current_item_count: int = 0

var _is_initialized: bool = false


@onready var _sprite: Sprite2D = $Sprite2D


# Godot Engine-Callbacks

func _ready() -> void:
	_initialize_system()


func _process(delta: float) -> void:
	if _is_initialized:
		_update_movement(delta)


# Private Methoden

func _initialize_system() -> void:
	_is_initialized = true
	action_completed.emit({"status": "ready"})


func _update_movement(p_delta: float) -> void:
	position.x += speed * p_delta


# Öffentliche Methoden

func reset_position() -> void:
	position = Vector2.ZERO
```
