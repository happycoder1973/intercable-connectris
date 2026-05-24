# Spielarchitektur und Design (ARCHITECTURE.md)

Dieses Dokument beschreibt die Softwarearchitektur, Szenenstrukturen und Datenflüsse für **Intercable Connectris**.

> [!NOTE]
> Dieses Dokument wird von **Claude Code** (Senior Engineer & Architect) befüllt und gepflegt.

## 1. Szenen-Graph & Komponentenstruktur
- **Main/Root Scene** (`main.tscn`): Verwaltet den globalen Spielzustand, Szenenübergänge und Kiosk-Modus-Einstellungen.
- **Game Scene** (`playfield.tscn`): Der Gameplay-Viewport, der das Grid und die Fall-Logik steuert.
- **UI Scenes** (Menüs, Settings, Highscore, Comics).

## 2. Datenfluss & State Machine
- ... (folgt durch Claude Code)

## 3. SQLite Datenbank-Schema
- ... (folgt durch Claude Code)
