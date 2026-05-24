# SETUP & GUIDELINES: Windows 11 Kiosk-Modus für Intercable Connectris

Dieses Verzeichnis enthält die Werkzeuge und Skripte zur Einrichtung eines sicheren, offline-fähigen Kiosk-Betriebs für **Intercable Connectris** unter Windows 11.

---

## 1. Systemanforderungen & Voraussetzungen

* **Betriebssystem**: Windows 11 Enterprise, Education oder IoT Enterprise (erforderlich für *Shell Launcher v2* und *Keyboard Filter*).
* **Rechte**: Alle Skripte müssen in einer PowerShell mit **Administratorrechten** ausgeführt werden.
* **Spiel-Executable**: Die exportierte Spieldatei `IntercableConnectris.exe` muss sich im selben Ordner wie die Skripte befinden.

---

## 2. Kiosk-Modus einrichten (`kiosk-setup.ps1`)

Das Skript `kiosk-setup.ps1` automatisiert die gesamte Systemabsicherung:

1. **Feature-Aktivierung**: Aktiviert die Windows-Features *Shell Launcher* und *Keyboard Filter*.
2. **Konto-Erstellung**: Erstellt einen lokalen Standard-Benutzer `KioskUser` mit dem Kennwort `ConnectrisPassword123!`.
3. **Shell Launcher v2**: Setzt die Spieldatei (`IntercableConnectris.exe --kiosk`) als primäre Benutzeroberfläche (Shell) für den `KioskUser`. Der reguläre Windows Explorer (`explorer.exe`) wird nicht geladen. Schließt sich das Spiel, startet Windows es automatisch neu.
4. **Tastatursperren**: Deaktiviert kritische Tastenkombinationen wie **Alt+Tab**, **Alt+F4** und die **Windows-Taste**.
5. **Strg+Alt+Entf Absicherung**: Setzt Registry-Gruppenrichtlinien für den `KioskUser`, um Task-Manager, PC sperren, Kennwort ändern und Benutzer wechseln auszublenden.

### Ausführung:
1. Öffnen Sie die PowerShell als Administrator.
2. Navigieren Sie in das Verzeichnis.
3. Führen Sie das Setup-Skript aus:
   ```powershell
   Set-ExecutionPolicy Bypass -Scope Process -Force
   .\kiosk-setup.ps1
   ```
4. Starten Sie den PC neu und melden Sie sich als **KioskUser** an.

---

## 3. Kiosk-Modus zurücksetzen (`kiosk-revert.ps1`)

Um den PC wieder in den Normalzustand zu versetzen, verwenden Sie das Skript `kiosk-revert.ps1`:

1. Deaktiviert den WMI Shell Launcher und setzt den Windows Explorer wieder als Standard-Shell für alle Benutzer.
2. Gibt alle gesperrten Tastenkombinationen im Keyboard Filter wieder frei.
3. Entfernt die Registry-Sperren auf dem Strg+Alt+Entf-Bildschirm für den `KioskUser`.

### Ausführung:
1. Melden Sie sich als Administrator an (Administratoren erhalten weiterhin den normalen Desktop).
2. Öffnen Sie die PowerShell als Administrator.
3. Führen Sie das Revert-Skript aus:
   ```powershell
   Set-ExecutionPolicy Bypass -Scope Process -Force
   .\kiosk-revert.ps1
   ```
4. Starten Sie den PC neu.

---

## 4. Spielinterne Sicherheitsmechanismen (Godot 4)

Zusätzlich zur Windows-Absicherung verfügt das Spiel über interne Sicherheitsnetze:

* **Fokus-Garantie**: Sollte eine unerwartete OS-Meldung den Fokus stehlen, holt sich die App diesen sofort über `get_window().grab_focus()` zurück.
* **Always-On-Top**: Im `--kiosk` Modus läuft die App im rahmenlosen Vollbildmodus mit dem Flag `Always on top`, um Overlays zu blockieren.
* **Offline-Datenbank**: Verwendet ein sicheres lokales Highscore-System (SQLite mit einem transaktionssicheren Backup-Fallback über ConfigFiles), um Schreibfehler durch plötzliches Ausschalten zu verhindern.
