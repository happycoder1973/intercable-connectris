# GDScript Stil- und Codekonventionen (CONVENTIONS.md)

Dieses Dokument definiert die Programmier- und Formatierungskonventionen für das Projekt **Intercable Connectris**.

> [!NOTE]
> Dieses Dokument wird von **Claude Code** (Senior Engineer & Architect) befüllt und gepflegt.

## 1. Code-Formatierung
- **Linter & Formatter:** Verwendung von `gdlint` und `gdformat` (Modul 9.2).
- Pre-Commit-Hook blockiert Commits mit Linter-Fehlern.

## 2. Benennungsregeln (Naming Conventions)
- **Klassen / Nodes:** PascalCase (z.B. `PlayfieldGrid`)
- **Variablen & Funktionen:** snake_case (z.B. `spawn_block()`, `current_score`)
- **Konstanten:** UPPER_SNAKE_CASE (z.B. `MAX_LEVEL`)
- **Dateinamen:** PascalCase für Klassen-Dateien (`Playfield.gd`), snake_case für Szenen (`playfield.tscn`).

## 3. Scene-Struktur
- ... (folgt durch Claude Code)

## 4. Signal- und Kommunikationsmuster
- ... (folgt durch Claude Code)
