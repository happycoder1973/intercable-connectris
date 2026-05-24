# Architekturentscheidungen und Delegationen (DECISIONS.md)

Dieses Dokument erfasst alle nicht-trivialen Entwurfsentscheidungen, Technologiewahlen und CLI-Delegationen gemäß Modul 8.

---

## 2026-05-24 08:45 — Repository-Initialisierung und Phase 0 Start
- **Kontext:** Das Git-Repository wurde inspiziert. Ein Snapshot-Branch `archive/initial-attempt` wurde erstellt und der Entwicklungs-Branch `professional-rebuild` wurde als sauberer Startpunkt aufgesetzt (alle alten Dateien im Arbeitsverzeichnis wurden gelöscht).
- **Optionen:**
  1. Fortführen des alten C#-Stands (verworfen wegen Godot 4 GDScript Vorgabe)
  2. Kompletter Neustart mit GDScript auf `professional-rebuild` (ausgewählt)
- **Entscheidung:** Neustart auf dem Branch `professional-rebuild` mit GDScript als Primärsprache.
- **Delegiert an:** Antigravity (Manuelle Ausführung der Git-Branch-Befehle)
- **Begründung:** Entspricht der Vorgabe im Systemprompt (Modul 6.2).
- **Ergebnis:** Branches `archive/initial-attempt` und `professional-rebuild` angelegt, Arbeitsverzeichnis bereinigt.

## 2026-05-24 09:00 — Konsolidierung Phase 0 (Foundation) und Slice-Reihenfolge-Empfehlung
- **Kontext:** Phase 0 (Legacy-Audit, API-Recherchen und Godot 4 Grundsetup) wurde erfolgreich durch die Subagenten abgeschlossen.
- **Optionen:**
  1. Direkte Übernahme der empfohlenen Slice-Reihenfolge aus Modul 10.
  2. Anpassung der Slice-Reihenfolge, um Abhängigkeiten zu optimieren (z. B. SQLite-Highscore vor dem Spielende-Bildschirm UI).
- **Entscheidung:** Wir halten an der standardmäßigen Slice-Reihenfolge fest (Slices 1 bis 11), da diese eine schrittweise vertikale Integration ermöglicht.
- **Delegiert an:** Claude Code (Audit), Gemini CLI (Recherche), Codex CLI (Setup & CI).
- **Begründung:** Die standardmäßige Reihung baut logisch aufeinander auf: Core-Tetris-Mechanik (1) -> Workflow-Verbindung (2) -> Power-ups (3) -> Game Over Modi (4) -> Level-Progression (5) -> Infotainment (6) -> Eingabemethoden (7) -> SQLite-Highscore (8) -> Kiosk-Modus (9) -> Sound & Branding (10) -> Release (11).
- **Ergebnis:** Alle Phase-0-Ergebnisse (GUT-Framework, Linter, Test-Skript, Build-Skript, Recherchen und Audit) wurden in `professional-rebuild` integriert. Der Baseline-Build läuft erfolgreich headless durch.

