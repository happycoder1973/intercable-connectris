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