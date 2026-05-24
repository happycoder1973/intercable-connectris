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
