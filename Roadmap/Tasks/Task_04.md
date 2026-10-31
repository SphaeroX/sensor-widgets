> [!IMPORTANT]
> ### 🚨 PFLICHTANWEISUNG VOR ARBEITSBEGINN
> 1. **Lies als allererstes die Regeldateien:** Konsultiere `../AGENTS.md` im Ordner `Roadmap/` sowie `/AGENTS.md` im Projekt-Root und befolge ausnahmslos alle darin festgelegten Regeln (insbesondere striktes TDD)!
> 2. **Allererste Aktion – Datei umbenennen:** Benenne diese Datei als **allererste Aktion** um und stelle das Kürzel `RUN_` voran (`Task_04.md` ➔ `RUN_Task_04.md`), **NOCH BEVOR** irgendeine Zeile Code geschrieben oder geändert wird!
> 3. **Testing-Suite:** Alle Tests müssen permanent in den dafür vorgesehenen Test-Ordnern (`test/`, `android/app/src/test/`, `ios/`, `fixtures/influx/`) abgelegt werden.
> 4. **Vor der Archivierung:** Bevor dieser Task nach erfolgreichem Testing ins `Archiv/` verschoben wird, müssen Sektion 6 am Ende dieser Datei ausgefüllt sowie die Folge-Tasks, `Roadmap/README.md` und `docs/` geprüft und aktualisiert werden!

---

# Task_04: Persistenz- & Bridge-Layer: Secure Token Storage & Shared Widget Storage

## 1. Ziel & Zweck des Tasks
- **Fokus:** Implementierung der Persistenzschicht für InfluxDB-Verbindungen (Metadaten + sichere Token-Ablage für App und Hintergrund-Widgets) sowie für Widget-Definitionen im Shared Storage (`home_widget`) inklusive Triggerung nativer Widget-Reloads.
- **Erwartetes Ergebnis:** Sauber abstrahierte, mit `mocktail` getestete Repositories (`ConnectionRepository`, `WidgetDefinitionRepository`, `NativeWidgetBridge`) und passende Riverpod-Provider.

---

## 2. Kontext & Abhängigkeiten
- **Vorausgehende Tasks:** `Task_01` bis `Task_03` müssen abgeschlossen und archiviert sein.
- **Betroffene Komponenten / Dateien:**
  - `lib/data/storage/secure_token_store.dart`
  - `lib/data/storage/shared_widget_store.dart`
  - `lib/data/repositories/connection_repository.dart`
  - `lib/data/repositories/widget_definition_repository.dart`
  - `lib/presentation/providers/storage_providers.dart`
  - `test/data/storage/*_test.dart`
  - `test/data/repositories/*_test.dart`
- **Relevante globale Infos:** Siehe `../README.md` und `lib/core/constants/storage_keys.dart` aus `Task_02`.

---

## 3. Detaillierte Implementierungsschritte
1. **Vorbereitung:**
   - [ ] Datei in `RUN_Task_04.md` umbenennen.
   - [ ] Learnings aus `Task_02` und `Task_03` prüfen.
2. **Secure Token Store & Shared Widget Store Abstraktionen (TDD):**
   - [ ] **Red:** Schreibe Unit-Tests in `test/data/storage/secure_token_store_test.dart` und `test/data/storage/shared_widget_store_test.dart`.
   - [ ] **Green:**
     - Implementiere `SecureTokenStore` (nutzt `FlutterSecureStorage` mit konfigurierten `AndroidOptions(encryptedSharedPreferences: true)` und `IOSOptions(groupId: StorageKeys.iosAppGroupId)`), sodass die nativen Hintergrund-Widgets auf Android (`EncryptedSharedPreferences`) und iOS (App Group Keychain) die Tokens unter einem deterministischen Key (`token_<connectionId>`) auslesen können.
     - Implementiere `SharedWidgetStore` (kapselt `HomeWidget.setAppGroupId`, `HomeWidget.saveWidgetData`, `HomeWidget.getWidgetData` und `HomeWidget.updateWidget` für Android- und iOS-Widget-Klassen).
3. **ConnectionRepository per TDD:**
   - [ ] **Red:** Schreibe `test/data/repositories/connection_repository_test.dart` für CRUD-Operationen auf Verbindungen:
     - Verbindungs-Metadaten (ID, Name, BaseUrl, Database/Bucket) werden als JSON im Shared Storage gespeichert (damit Hintergrund-Widgets URL & DB kennen).
     - Das zugehörige Token wird **ausschließlich** im `SecureTokenStore` gespeichert.
     - Beim Löschen einer Verbindung wird geprüft, ob noch Widgets diese Verbindung nutzen (oder entsprechende Warnung/Kaskade ausgelöst) und das Token sicher gelöscht.
   - [ ] **Green:** Implementiere `ConnectionRepository` in `lib/data/repositories/connection_repository.dart`.
4. **WidgetDefinitionRepository per TDD:**
   - [ ] **Red:** Schreibe `test/data/repositories/widget_definition_repository_test.dart` für:
     - Laden aller Widget-Definitionen (leere Liste bei Erststart, Fehler-Resilienz bei korruptem JSON).
     - Speichern, Aktualisieren, Duplizieren, Umsortieren und Löschen von `WidgetDefinition`-Einträgen im `v1`-Envelope-Format.
     - Automatisches Triggern von `SharedWidgetStore.notifyWidgetsUpdated()` nach jeder Änderung.
   - [ ] **Green:** Implementiere `WidgetDefinitionRepository` und die zugehörigen Riverpod-Provider in `lib/presentation/providers/storage_providers.dart`.
   - [ ] **Refactor:** Dokumentiere die genauen Keychain-/EncryptedSharedPreferences-Optionen in `docs/architecture.md` und `Roadmap/README.md` für `Task_07` und `Task_09`.

---

## 4. Akzeptanzkriterien & Testing-Vorgaben
- **Funktionale Kriterien:**
  - [ ] API-Tokens landen niemals im unverschlüsselten JSON-Dokument der Verbindungs- oder Widget-Definitionen.
  - [ ] Jede Änderung an Verbindungen oder Widget-Definitionen aktualisiert den Shared Storage und stößt ein Widget-Update an.
- **Testing-Pflicht (`test/`):**
  - [ ] Vollständige Unit-Tests für `SecureTokenStore`, `SharedWidgetStore`, `ConnectionRepository` und `WidgetDefinitionRepository` mit `mocktail`.
  - [ ] `flutter test`, `dart format --set-exit-if-changed .` und `flutter analyze` laufen fehlerfrei.

---

## 5. Abschluss-Checkliste vor der Archivierung
- [ ] Alle Tests unter `test/` sind grün.
- [ ] Die exakten `FlutterSecureStorage`-Parameter (File-/Key-Namen für Android & iOS) sind in Sektion 6 und `docs/architecture.md` dokumentiert.
- [ ] Folge-Tasks in `Roadmap/Tasks/` und `Roadmap/README.md` geprüft und aktualisiert.
- [ ] Datei umbenennen (`RUN_Task_04.md` ➔ `Task_04.md`) und nach `Roadmap/Archiv/` verschieben.

---

## 6. Erkenntnisse & Learnings für nachfolgende Tasks
<!-- DIESE SEKTION MUSS VOM BEARBEITENDEN AGENTEN VOR DER ARCHIVIERUNG AUSGEFÜLLT WERDEN! -->
*Hier dokumentiert der Agent wichtige Erkenntnisse, Stolpersteine, Architekturanpassungen und Schnittstellen-Details, die für nachfolgende Agenten bei späteren Tasks unverzichtbar sind:*

- **Wichtige Architekturentscheidungen & Details:**
  - *[Wird vom Agenten nach der Implementierung ausgefüllt]*
- **Stolpersteine & gelöste Probleme:**
  - *[Wird vom Agenten nach der Implementierung ausgefüllt]*
- **Wichtige Hinweise für die Folge-Tasks:**
  - *[Wird vom Agenten nach der Implementierung ausgefüllt]*
