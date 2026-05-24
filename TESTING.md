# Test-Dokumentation (TESTING.md)

Dieses Dokument beschreibt das Test-Setup und die Durchführung von Tests für das Projekt **Intercable Connectris**.

## 1. Test-Framework
Das Projekt verwendet **GUT (Godot Unit Test Framework)** in der Version 9.3.0 für Godot 4.x.
Das Addon befindet sich im Verzeichnis `addons/gut/`.

## 2. Teststruktur
Alle Testdateien werden im Verzeichnis `tests/` abgelegt.
- Test-Klassen müssen von `GutTest` erben.
- Test-Methoden müssen mit dem Präfix `test_` benannt sein.

## 3. Testausführung

### Headless über die Konsole (empfohlen für CI/CD)
Um die Tests headlessly über die Konsole auszuführen, führe folgenden Befehl im Projektverzeichnis aus:

```powershell
.\Godot_Engine\Godot_v4.3-stable_mono_win64_console.exe --headless -s addons/gut/gut_cmdln.gd -gdir=res://tests -gexit
```

*Hinweis: Der Parameter `-gexit` stellt sicher, dass Godot nach Beendigung der Tests wieder geschlossen wird.*

### Über den Godot Editor (GUI)
1. Öffne das Projekt in Godot.
2. Aktiviere das GUT-Plugin unter **Project Settings > Plugins** (falls nicht bereits aktiv).
3. Öffne das GUT-Panel unten im Editor, um Tests visuell auszuführen.

## 4. Vorhandene Test-Suites (Slice 1 Core-Tetris)

### 4.1 Block-Tests (`tests/test_block.gd`)
- `test_block_initialization`: Prüft, dass die Form-Matrizen und die Segment-Daten (SegmentType und Farbe) der verschiedenen Tetrominos korrekt initialisiert werden.
- `test_block_rotation`: Testet die Rotations-Logik nach rechts und links sowie die Beibehaltung der Daten nach Vollkreis-Rotationen.
- `test_get_active_segments`: Verifiziert die korrekte Extraktion von belegten Zellen-Positionen und zugehörigen Segment-Daten.

### 4.2 Gitter-Tests (`tests/test_grid.gd`)
- `test_grid_initialization`: Prüft die korrekte Erstellung und Initialisierung des leeren Gitters (10 Spalten x 20 Zeilen).
- `test_is_valid_position_bounds`: Validiert die Kollisionsprüfung an den Grenzen des Gitters (links, rechts, unten).
- `test_is_valid_position_collision`: Validiert die Kollisionsprüfung mit bereits im Gitter festen Segmenten.
- `test_lock_block`: Testet das dauerhafte Verankern eines Blocks im Gitter.
- `test_row_clearing`: Simuliert volle Zeilen und verifiziert deren Löschung sowie das korrekte Herabfallen darüberliegender Segmente.
- `test_powerups_clear`: Testet die Power-up-Hilfsfunktionen zum zeilen- und spaltenweisen Löschen.
- `test_shake_grid`: Testet das Schütteln des Gitters (Kompaktierung aller Segmente nach unten unter Einfluss von Schwerkraft).
- `test_is_row_crimp_valid`: Validiert die Crimp-Gültigkeit einer Zeile (Crimp-Lugs an den Rändern, blanke Adern dazwischen).
- `test_check_full_rows_status`: Prüft die Identifizierung von vollen Zeilen und deren Klassifizierung in gültige (crimp-valid) und ungültige Zeilen.

### 4.3 Spielfeld-Tests (`tests/test_playfield.gd`)
- `test_playfield_initialization`: Verifiziert die korrekte Initialisierung des Spielfelds, das Vorhandensein eines Gitters und das automatische Spawnen des ersten Blocks.
- `test_score_progression`: Testet die aktualisierte Punktevergabe von 1 Punkt pro gelöschter Crimp-Zeile sowie das Level-Up alle 10 Zeilen und validiert das `score_changed` Signal.
- `test_difficulty_adjustment`: Überprüft die Anpassung des Fall-Intervalls (Schwerkraft) basierend auf dem Level und stellt das korrekte Limitieren (Clamp auf minimal 0.1s) sicher.
- `test_block_movement`: Prüft grundlegende Spielaktionen wie das Bewegen nach unten und horizontales Verschieben des aktiven Blocks.
- `test_invalid_rows_not_cleared_and_no_score`: Stellt sicher, dass volle Zeilen, die den Crimp-Kriterien nicht entsprechen, im Gitter verbleiben (nicht gelöscht werden) und keine Punkte vergeben.
- `test_valid_rows_trigger_press_and_score`: Verifiziert, dass gültige Zeilen die STILO60 Crimp-Presse-Animation auslösen, gelöscht werden und Punkte vergeben.
- `test_input_and_gravity_blocked_during_press`: Testet, dass während der laufenden Crimp-Presse-Animation alle Benutzereingaben, Fall-Timer-Updates und Blockbewegungen blockiert werden.
