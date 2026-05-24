# godot-sqlite vs. Alternativen für lokale Persistenz in Godot 4

Dieses Dokument vergleicht die GDExtension **godot-sqlite** mit den in Godot 4 standardmäßig integrierten Mechanismen zur lokalen Datenpersistenz. Die Analyse dient als Entscheidungsgrundlage für das Projekt **Intercable Connectris**.

---

## 1. Übersicht der Persistenz-Optionen

Für lokale Speicherungen (Einstellungen, Spielstände, Highscores, Telemetrie) stehen in Godot 4 vier primäre Ansätze zur Verfügung:

1. **godot-sqlite (GDExtension)**: Eine relationale SQL-Datenbank.
2. **ConfigFile (Eingebaut)**: Strukturierte Konfigurationsdateien im INI-Format.
3. **Custom Resources (`.tres` / `.res`)**: Serialisierte Godot-Objekte.
4. **JSON via FileAccess (Eingebaut)**: Reine Textdaten im JSON-Format.

---

## 2. Detaillierte Analyse der einzelnen Optionen

### A. godot-sqlite (GDExtension)
Die GDExtension `2shady4u/godot-sqlite` bindet die offizielle SQLite-C-Bibliothek in Godot ein. Sie wird zur Laufzeit als dynamische Bibliothek (`.dll` auf Windows) geladen.

* **Vorteile:**
  * **Relationales Datenmodell:** Erlaubt komplexe Datenstrukturen (z. B. Spielerprofile verknüpft mit detaillierten Level-Statistiken) via SQL-Queries, Joins und Indizes.
  * **ACID-Konformität:** Bietet hohe Transaktionssicherheit. Stürzt das System während eines Schreibvorgangs abstürze, bleibt die Datenbank konsistent.
  * **Hervorragende Performance:** Bei sehr großen Datenmengen (z. B. Tausenden von Einträgen für Telemetrie oder Logdaten) extrem schnell durch indizierte Suchen.
  * **Sicherheit:** Kann optional verschlüsselt werden (SQLCipher).
* **Nachteile:**
  * **Export-Größe & Komplexität:** Erfordert plattformspezifische Binärdateien im Export-Build.
  * **Zusätzliche Abhängigkeit:** Da es sich um ein Community-Projekt handelt, besteht die Gefahr, dass es bei zukünftigen Godot-Major-Updates verzögert angepasst wird.
  * **Overkill für einfache Daten:** Für das Speichern von bloßen Einstellungen (z. B. Lautstärke) ist der Overhead einer relationalen Datenbank zu groß.

### B. ConfigFile (Eingebaut)
Die Klasse `ConfigFile` ist Godots integrierte Lösung zum Lesen und Schreiben von INI-ähnlichen Textdateien.

* **Vorteile:**
  * **Einfachheit:** Sehr leicht zu implementierende API für Schlüssel-Wert-Paare in Sektionen.
  * **Lesbarkeit:** Die Dateien sind für Entwickler (und Kiosk-Administratoren) im Texteditor direkt lesbar und editierbar.
  * **Verschlüsselung:** Unterstützt native AES-256-Bit-Verschlüsselung über `save_encrypted_pass()`.
  * **Plattformunabhängig:** Läuft ohne Zusatzbibliotheken auf absolut jeder Zielplattform.
* **Nachteile:**
  * **Skalierbarkeit:** Bei riesigen Datenbeständen ineffizient, da die gesamte Datei stets im Speicher gehalten und komplett neu geschrieben werden muss.
  * **Keine Abfragesprache:** Filterungen oder Verknüpfungen müssen manuell in GDScript ausprogrammiert werden.

### C. Custom Resources (`.tres` / `.res`)
Godot ermöglicht es, benutzerdefinierte Klassen, die von `Resource` erben, direkt zu speichern und zu laden (`ResourceSaver.save()` / `ResourceLoader.load()`).

* **Vorteile:**
  * **Tiefste Integration:** Daten verhalten sich wie native Godot-Objekte mit strikter Typisierung.
  * **Komfort:** Verschachtelte Strukturen (z. B. eine Liste von Items, die selbst Ressourcen sind) werden automatisch serialisiert.
* **Nachteile:**
  * **Sicherheitsrisiko (Code-Execution):** Das Laden von `.tres`/`.res`-Dateien aus externen oder manipulierten Quellen ist unsicher, da Ressourcen eingebettete GDScript-Skripte enthalten können. Lädt das Spiel eine modifizierte Savegame-Datei eines Benutzers, kann beliebiger Schadcode auf dem System ausgeführt werden.
  * **Für Kiosks ungeeignet:** Da Kiosk-Systeme maximal abgesichert sein müssen, sollte auf das Laden ungeprüfter Ressourcen verzichtet werden.

### D. JSON via FileAccess
Textbasiertes Speichern unter Verwendung der Klasse `JSON` und der Klasse `FileAccess` zur Datei-Interaktion.

* **Vorteile:**
  * **Sicherheit:** JSON speichert nur rohe Daten (Dictionaries, Arrays, Strings, Zahlen) und führt niemals Code aus.
  * **Interoperabilität:** Einfacher Austausch mit Web-Schnittstellen oder externen Tools.
* **Nachteile:**
  * **Typenverlust:** Godot-spezifische Typen (wie `Vector2`, `Color`, `Rect2`) müssen vor dem Speichern manuell in Strings oder Arrays konvertiert und beim Laden wieder rekonstruiert werden.
  * **Kein Schutz vor Datenverlust:** Ein Absturz während des Schreibvorgangs zerstört die JSON-Datei in der Regel vollständig.

---

## 3. Direkter Vergleich (Matrix)

| Kriterium | godot-sqlite | ConfigFile | Custom Resource | JSON |
| :--- | :--- | :--- | :--- | :--- |
| **Schnittstelle** | SQL (Queries) | Sektionen / Keys | GDScript-Objekt | Dictionary / Array |
| **Transaktionssicherheit** | Sehr hoch (ACID) | Gering | Gering | Gering |
| **Sicherheit (RCE-Schutz)**| Hoch | Hoch | **Kritisch (RCE-Risiko)**| Sehr hoch |
| **Setup-Aufwand** | Mittel (GDExtension) | Sehr gering (Nativ) | Sehr gering (Nativ) | Gering (Nativ) |
| **Große Datenmengen** | Exzellent | Schlecht | Mittel | Schlecht |
| **Verschlüsselung** | Ja (via SQLCipher) | Ja (Nativ) | Ja (Nativ) | Nein (nur manuell) |
| **Plattform-Portabilität**| Eingeschränkt (Binaries)| Uneingeschränkt | Uneingeschränkt | Uneingeschränkt |

---

## 4. Empfehlung für Intercable Connectris

Für das Projekt **Intercable Connectris** wird eine **hybride Persistenz-Strategie** empfohlen:

### 1. Systemeinstellungen und Tastaturbelegungen
* **Empfehlung:** `ConfigFile`
* **Begründung:** Ideal für flache Datenstrukturen, leicht für Administratoren wartbar und nativ verschlüsselt, um Manipulationen am Kiosk vorzubeugen.

### 2. Lokale Highscores und detaillierte Spielstatistiken
* **Empfehlung:** `godot-sqlite`
* **Begründung:** Kiosk-Systeme laufen oft über lange Zeiträume und sammeln kontinuierlich Spielstatistiken (z. B. Spielzeit, Punkteverlauf pro Tag). SQLite garantiert hierbei, dass auch bei plötzlichen Stromausfällen am Kiosk (hartes Ausschalten) keine Datenkorruption auftritt. Zudem lassen sich historische Highscore-Listen (z. B. "Top 10 dieses Monats") extrem einfach per SQL-Query auslesen.

### 3. Einfache Spielstände (Save-State für Singleplayer)
* **Empfehlung:** `JSON` (oder sichere Binärdaten via `FileAccess.store_var(data, false)`)
* **Begründung:** Sicher vor Code-Injections und leicht zu debuggen.
