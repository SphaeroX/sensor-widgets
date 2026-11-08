// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for German (`de`).
class AppLocalizationsDe extends AppLocalizations {
  AppLocalizationsDe([String locale = 'de']) : super(locale);

  @override
  String get appTitle => 'Sensor Widgets';

  @override
  String get commonCancel => 'Abbrechen';

  @override
  String get commonEdit => 'Bearbeiten';

  @override
  String get commonDuplicate => 'Duplizieren';

  @override
  String get commonDelete => 'Löschen';

  @override
  String get commonSave => 'Speichern';

  @override
  String get commonReset => 'Zurücksetzen';

  @override
  String commonErrorDetails(String error) {
    return 'Fehler: $error';
  }

  @override
  String get dashboardSyncTooltip => 'Native Widgets synchronisieren';

  @override
  String get dashboardSyncDone => 'Native Widgets aktualisiert.';

  @override
  String get dashboardHelpTooltip => 'Formel-Hilfe';

  @override
  String get dashboardConnectionsTooltip => 'InfluxDB Verbindungen';

  @override
  String get dashboardEmptyTitle => 'Noch keine Widgets konfiguriert';

  @override
  String get dashboardEmptyBody =>
      'Erstelle dein erstes Widget für den Homescreen!';

  @override
  String get dashboardCreateWidget => 'Neues Widget anlegen';

  @override
  String dashboardCardSubtitle(String measurement, int minutes) {
    return '$measurement • alle ${minutes}m';
  }

  @override
  String get dashboardActionsTooltip => 'Aktionen';

  @override
  String get connectionsTitle => 'InfluxDB-Verbindungen';

  @override
  String get connectionsEmptyTitle => 'Keine Verbindungen konfiguriert';

  @override
  String get connectionsEmptyHint =>
      'Tippe auf +, um einen InfluxDB-Server hinzuzufügen';

  @override
  String connectionsSubtitle(String url, String database) {
    return '$url • DB: $database';
  }

  @override
  String get connectionsDeleteTitle => 'Verbindung löschen';

  @override
  String connectionsDeleteConfirm(String name) {
    return 'Soll \"$name\" wirklich gelöscht werden?';
  }

  @override
  String connectionsLoadError(String error) {
    return 'Fehler beim Laden der Verbindungen: $error';
  }

  @override
  String get connectionTestSuccess => 'Verbindung erfolgreich!';

  @override
  String get connectionTestNoResponse =>
      'Verbindung fehlgeschlagen: keine Antwort';

  @override
  String connectionTestFailed(String error) {
    return 'Verbindung fehlgeschlagen: $error';
  }

  @override
  String connectionSaveFailed(String error) {
    return 'Verbindung konnte nicht gespeichert werden: $error';
  }

  @override
  String get connectionEditTitle => 'Verbindung bearbeiten';

  @override
  String get connectionNewTitle => 'Neue Verbindung';

  @override
  String get connectionNameLabel => 'Verbindungsname';

  @override
  String get connectionNameHint => 'z. B. Heimserver';

  @override
  String get connectionNameRequired => 'Bitte einen Verbindungsnamen eingeben';

  @override
  String get connectionUrlLabel => 'Host-URL';

  @override
  String get connectionUrlRequired => 'Bitte die Host-URL eingeben';

  @override
  String get connectionUrlScheme =>
      'Die URL muss mit http:// oder https:// beginnen';

  @override
  String get connectionDatabaseLabel => 'Datenbank / Bucket';

  @override
  String get connectionDatabaseHint => 'z. B. sensors';

  @override
  String get connectionDatabaseRequired => 'Bitte den Datenbanknamen eingeben';

  @override
  String get connectionOrgLabel => 'Organisation (optional)';

  @override
  String get connectionOrgHint => 'z. B. home-org';

  @override
  String get connectionTokenLabel => 'API-Token';

  @override
  String get connectionTokenKeepHint => '(Aktuellen Token behalten)';

  @override
  String get connectionTokenRequiredHint =>
      'Für die Authentifizierung erforderlich';

  @override
  String get connectionTokenRequired => 'Bitte den API-Token eingeben';

  @override
  String get connectionTestButton => 'Verbindung testen';

  @override
  String get appearanceTitle => 'Aussehen';

  @override
  String get appearanceBackgroundColor => 'Hintergrundfarbe';

  @override
  String get appearanceBackgroundOpacity => 'Hintergrund-Transparenz';

  @override
  String get appearanceTextColor => 'Textfarbe';

  @override
  String get appearanceAccentColor => 'Akzentfarbe';

  @override
  String get appearanceFontScale => 'Schriftgröße';

  @override
  String get appearanceCornerRadius => 'Eckenrundung';

  @override
  String get appearanceIosCornerHint =>
      'Hinweis: Auf iOS bestimmt das System die Eckenrundung der Widgets.';

  @override
  String get appearanceColorHint => '#RRGGBB (leer = Standard)';

  @override
  String get colorInvalid => 'Ungültige Farbe (#RRGGBB)';

  @override
  String get chartStyleTitle => 'Farbverlauf & Chart-Stil';

  @override
  String get chartStyleDescription =>
      'Die Linie wird nach Wert eingefärbt. Ohne Farbstopps bleibt die Standardfarbe.';

  @override
  String get chartStylePresetGreenToRed => 'Grün → Rot';

  @override
  String get chartStylePresetRedToGreen => 'Rot → Grün';

  @override
  String get chartStyleAddStop => 'Farbstopp hinzufügen';

  @override
  String get chartStyleFillArea => 'Fläche füllen';

  @override
  String get chartStyleGrid => 'Gitter';

  @override
  String get chartStyleAxes => 'Achsenbeschriftung';

  @override
  String get chartStyleMarkMinMax => 'Min/Max markieren';

  @override
  String get chartStyleLineWidth => 'Linienstärke';

  @override
  String get chartStyleStopValue => 'Wert';

  @override
  String get chartStyleStopColor => 'Farbe';

  @override
  String get chartStyleDeleteStop => 'Farbstopp löschen';

  @override
  String get alertsTitle => 'Benachrichtigungen';

  @override
  String get alertsDescription =>
      'Push-Benachrichtigung, sobald ein Wert die Schwelle überschreitet. Erneut erst, nachdem er wieder zurückgegangen ist.';

  @override
  String get alertsAdd => 'Benachrichtigung hinzufügen';

  @override
  String get alertsAbove => 'über';

  @override
  String get alertsBelow => 'unter';

  @override
  String get alertsThreshold => 'Schwellenwert';

  @override
  String get alertsRemove => 'Benachrichtigung entfernen';

  @override
  String get widgetCodeApplied => 'Code übernommen.';

  @override
  String get widgetCodePromptCopied =>
      'Prompt kopiert. In eine KI einfügen, dann die Aufgabe beschreiben.';

  @override
  String get widgetCodeTitle => 'Widget als Code';

  @override
  String get widgetCodeDescription =>
      'Das ganze Widget (Typ, Formel, Zwischenschritte, Variablen, Darstellung) als JSON. Lass es von einer KI schreiben, kopiere die Antwort und tippe auf \"Einfügen\".';

  @override
  String get widgetCodeCopyPrompt => 'Prompt für KI kopieren';

  @override
  String get commonShare => 'Teilen';

  @override
  String get widgetCodeFieldLabel => 'Widget-Code (JSON)';

  @override
  String get widgetCodeDirty => 'Nicht übernommene Änderungen';

  @override
  String get widgetCodeMirrorsForm => 'Spiegelt das Formular';

  @override
  String get widgetCodeRegenerate => 'Aus Formular neu erzeugen';

  @override
  String get widgetCodeApply => 'Code übernehmen';

  @override
  String get widgetCodePromptShort => 'KI-Prompt';

  @override
  String get widgetCodeCopyCode => 'Kopieren';

  @override
  String get widgetCodePasteCode => 'Einfügen';

  @override
  String get widgetCodeCopyCodeTooltip => 'Aktuellen Widget-Code kopieren';

  @override
  String get widgetCodePasteCodeTooltip =>
      'Code aus der Zwischenablage einfügen und übernehmen';

  @override
  String get widgetCodeCopied => 'Code kopiert.';

  @override
  String get widgetCodeClipboardEmpty => 'Die Zwischenablage ist leer.';

  @override
  String get editorSectionTypeSettings => 'Typ-Einstellungen';

  @override
  String get widgetTypeSingleValueDescription => 'Ein aktueller Messwert';

  @override
  String get widgetTypeHistoryChartDescription => 'Verlauf über die Zeit';

  @override
  String get widgetTypeIndicatorLampDescription => 'Lampe mit Schwellenwert';

  @override
  String get widgetTypeMultiValueDescription => 'Mehrere Werte im Überblick';

  @override
  String get widgetTypeAggregateDescription => 'Min, Max und Mittelwert';

  @override
  String get widgetTypeGaugeBarDescription => 'Pegel mit Farbzonen';

  @override
  String get helpTitle => 'Formel-Hilfe';

  @override
  String get helpFunctionsTitle => 'Funktionen und Konstanten';

  @override
  String helpExample(String example) {
    return 'Beispiel: $example';
  }

  @override
  String get helpTemplatesTitle => 'Vorlagen';

  @override
  String helpTemplateResult(String formula) {
    return 'Ergebnis = $formula';
  }

  @override
  String get helpApplyTemplate => 'Vorlage übernehmen';

  @override
  String get helpVariablesTitle => 'Variablen';

  @override
  String get helpVariablesBody =>
      'Jede Variable (z. B. A, B oder co2) steht für ein Feld aus der Datenbank. Messwerte werden aus dem Schema gewählt; optional mit eigenem Measurement und Tag-Filtern. In der Formel verwendest du nur den Namen der Variable.';

  @override
  String get helpOperatorsTitle => 'Operatoren';

  @override
  String get helpOperatorsBody =>
      '+ - * / und Klammern. Vergleiche (< > <= >= == !=) liefern 1 (wahr) oder 0 (falsch). Beispiel: (A + B) / 2 oder A > 25.';

  @override
  String get helpStepsTitle => 'Zwischenschritte';

  @override
  String get helpStepsBody =>
      'Zwischenschritte sind benannte Teilformeln. Sie werden von oben nach unten berechnet und dürfen Variablen und frühere Schritte verwenden. Die Formel oben ist das Ergebnis und darf alle Schritte verwenden.';

  @override
  String get helpHistoryTitle => 'Verlauf und Aggregat';

  @override
  String get helpHistoryBody =>
      'Beim Verlaufschart und beim Aggregat wird die Formel je Zeit-Bucket berechnet (Mittelwert pro Intervall). Fehlt in einem Bucket ein Wert, wird der Bucket übersprungen oder der letzte Wert übernommen (Lückenregel). Aggregat bildet min/max/mean über die berechneten Werte.';

  @override
  String get helpErrorsTitle => 'Fehler';

  @override
  String get helpErrorsBody =>
      'Syntaxfehler zeigen die Position im Text. \"Division durch Null\", \"Unbekannte Funktion\", falsche Argumentzahl, \"Fehlende Variable\" und Bereichsfehler (z. B. sqrt einer negativen Zahl, ln(0)) werden nie still als 0 angezeigt, sondern als lesbare Fehlermeldung.';

  @override
  String get helpFnMin =>
      'Kleinster Wert (beliebig viele Argumente, mindestens eins).';

  @override
  String get helpFnMax =>
      'Größter Wert (beliebig viele Argumente, mindestens eins).';

  @override
  String get helpFnClampSignature => 'clamp(x, unten, oben)';

  @override
  String get helpFnClamp => 'Begrenzt x auf den Bereich unten bis oben.';

  @override
  String get helpFnAbs => 'Betrag (ohne Vorzeichen).';

  @override
  String get helpFnPowSignature => 'pow(basis, exponent)';

  @override
  String get helpFnPow => 'Potenz.';

  @override
  String get helpFnSqrt => 'Quadratwurzel (x darf nicht negativ sein).';

  @override
  String get helpFnLn => 'Natürlicher Logarithmus (x muss größer als 0 sein).';

  @override
  String get helpFnLog10 =>
      'Logarithmus zur Basis 10 (x muss größer als 0 sein).';

  @override
  String get helpFnExp => 'e hoch x.';

  @override
  String get helpFnRound => 'Rundet auf die nächste ganze Zahl (.5 weg von 0).';

  @override
  String get helpFnFloor => 'Rundet ab.';

  @override
  String get helpFnCeil => 'Rundet auf.';

  @override
  String get helpFnIfSignature => 'if(bedingung, dann, sonst)';

  @override
  String get helpFnIf =>
      'Wählt je nach Bedingung (ungleich 0 = wahr) einen von zwei Werten. Nur der gewählte Zweig wird berechnet, z. B. if(B == 0, 0, A / B).';

  @override
  String get helpConstPi => 'Kreiszahl 3,14159…';

  @override
  String get helpConstE => 'Eulersche Zahl 2,71828…';

  @override
  String get templateIaqDescription =>
      'Luftqualitäts-Index 0 bis 100. Jeder Teil-Score ist eine lineare Rampe (CO₂ 600 ppm = 100, 2000 ppm = 0; VOC-Index 100 = 100, 250 = 0; PM2.5 5 µg/m³ = 100, 35 = 0; Feuchte 50 % = 100, 20 % oder 80 % = 0). Der schlechteste Teil-Score bestimmt das Ergebnis. Schwellen lassen sich in den Zwischenschritten anpassen.';

  @override
  String get templateIaqVocLabel => 'VOC-Index';

  @override
  String get templateIaqRhLabel => 'Rel. Feuchte (%)';

  @override
  String get templateFahrenheitTitle => 'Celsius in Fahrenheit';

  @override
  String get templateFahrenheitDescription =>
      'Rechnet eine Temperatur von °C in °F um.';

  @override
  String get templateFahrenheitTempLabel => 'Temperatur';

  @override
  String get templateAverageTitle => 'Mittelwert zweier Sensoren';

  @override
  String get templateAverageDescription => 'Durchschnitt von zwei Messwerten.';

  @override
  String templateAverageSensorLabel(int number) {
    return 'Sensor $number';
  }

  @override
  String get schemaLoadingFromDb => 'Lade aus Datenbank...';

  @override
  String get commonReload => 'Neu laden';

  @override
  String get schemaPickFromList => 'Aus Liste wählen';

  @override
  String schemaPickTitle(String title) {
    return '$title auswählen';
  }

  @override
  String get commonSearchHint => 'Suchen...';

  @override
  String get schemaNumericOnly => 'Nur Zahlenfelder';

  @override
  String get schemaNoMatches => 'Keine Treffer gefunden';

  @override
  String get tagFilterTitle => 'Tag-Filter (Optional)';

  @override
  String get tagFilterReloadTags => 'Tags neu laden';

  @override
  String get tagFilterNone =>
      'Keine Tag-Filter aktiv (Daten für alle Tags abrufen)';

  @override
  String get tagFilterAdd => 'Filter hinzufügen';

  @override
  String get tagFilterPickKey => 'Tag-Key auswählen';

  @override
  String tagFilterPickValue(String key) {
    return 'Tag-Value für \"$key\" auswählen';
  }

  @override
  String get schemaPickFromDb => 'Aus Datenbank wählen:';

  @override
  String get schemaOrEnterManually => 'Oder manuell eingeben:';

  @override
  String get tagFilterKeyHint => 'Tag-Key (z. B. room)';

  @override
  String get commonNext => 'Weiter';

  @override
  String get tagFilterLoadingValues => 'Lade Werte aus Datenbank...';

  @override
  String get tagFilterValueHint => 'Tag-Value (z. B. living_room)';

  @override
  String get commonAdd => 'Hinzufügen';

  @override
  String multiFieldTitle(int count) {
    return 'Felder (Multi-Value) ($count ausgewählt)';
  }

  @override
  String get multiFieldReload => 'Felder neu laden';

  @override
  String get multiFieldNone =>
      'Keine Felder ausgewählt (mindestens 1 Feld erforderlich)';

  @override
  String get multiFieldRemove => 'Feld entfernen';

  @override
  String get multiFieldSelect => 'Felder auswählen';

  @override
  String get multiFieldAddManual => 'Manuelles Feld hinzufügen';

  @override
  String get multiFieldPickTitle => 'Felder aus Datenbank auswählen';

  @override
  String get multiFieldSearchHint => 'Felder suchen...';

  @override
  String get multiFieldNoneFound => 'Keine Felder gefunden';

  @override
  String multiFieldConfirm(int count) {
    return 'Übernehmen ($count)';
  }

  @override
  String get multiFieldNameLabel => 'Feldname (z. B. temperature)';

  @override
  String get multiFieldLabelLabel => 'Anzeigename / Label (Optional)';

  @override
  String get multiFieldUnitLabel => 'Einheit (Optional, z. B. °C)';

  @override
  String get formulaErrorEmpty => 'Formel darf nicht leer sein';

  @override
  String formulaErrorUnexpectedCharacter(String char) {
    return 'Unerwartetes Zeichen: \"$char\"';
  }

  @override
  String get formulaErrorUnexpectedAssign =>
      'Unerwartetes Zeichen: \"=\" (Vergleich: \"==\")';

  @override
  String formulaErrorInvalidNumber(String text) {
    return 'Ungültige Zahl: $text';
  }

  @override
  String formulaErrorUnknownOperator(String op) {
    return 'Unbekannter Operator: $op';
  }

  @override
  String get formulaErrorMissingOpeningParen => 'Fehlende öffnende Klammer';

  @override
  String get formulaErrorMissingOperator =>
      'Fehlender Operator zwischen Operanden';

  @override
  String get formulaErrorIncomplete => 'Ausdruck unvollständig';

  @override
  String get formulaErrorUnclosedParen => 'Nicht geschlossene Klammer';

  @override
  String formulaErrorInvalidStepName(String name) {
    return 'Ungültiger Schrittname: \"$name\"';
  }

  @override
  String formulaErrorStepNameIsFunction(String name) {
    return 'Schrittname \"$name\" ist ein Funktionsname';
  }

  @override
  String formulaErrorDuplicateName(String name) {
    return 'Doppelter Name: \"$name\"';
  }

  @override
  String formulaErrorStepSelfReference(String name) {
    return 'Schritt \"$name\" verweist auf sich selbst';
  }

  @override
  String formulaErrorStepForwardReference(String name) {
    return 'Schritt verweist auf später definierten Schritt \"$name\"';
  }

  @override
  String get formulaErrorDivisionByZero => 'Division durch Null';

  @override
  String formulaErrorMissingVariable(String name) {
    return 'Fehlende Variable: $name';
  }

  @override
  String formulaErrorUnknownFunction(String name) {
    return 'Unbekannte Funktion: $name';
  }

  @override
  String formulaErrorWrongArgumentCount(
    String name,
    String expected,
    String actual,
  ) {
    return 'Funktion $name erwartet $expected Argument(e), erhalten: $actual';
  }

  @override
  String formulaArityAtLeast(String min) {
    return 'mindestens $min';
  }

  @override
  String formulaArityRange(String min, String max) {
    return '$min bis $max';
  }

  @override
  String get formulaErrorClampBounds =>
      'clamp: untere Grenze größer als obere Grenze';

  @override
  String get formulaErrorSqrtNegative =>
      'sqrt: Argument darf nicht negativ sein';

  @override
  String get formulaErrorLnNonPositive => 'ln: Argument muss größer als 0 sein';

  @override
  String get formulaErrorLog10NonPositive =>
      'log10: Argument muss größer als 0 sein';

  @override
  String formulaErrorNotFinite(String function) {
    return '$function: Ergebnis ist nicht endlich';
  }

  @override
  String get formulaErrorResultNotFinite => 'Ergebnis ist nicht endlich';

  @override
  String get formulaErrorNoFormula => 'Widget besitzt keine Formel';

  @override
  String get formulaErrorNoVariables =>
      'Keine Variablen für die Formel definiert';

  @override
  String formulaErrorAtPosition(String message, int position) {
    return '$message (Position $position)';
  }

  @override
  String get influxErrorAuth =>
      'Authentifizierungsfehler (401): Bitte API-Token und Leseberechtigungen für die Datenbank bzw. das Bucket prüfen.';

  @override
  String get influxErrorDatabaseNotFound =>
      'Datenbank bzw. Bucket nicht gefunden: In InfluxDB v2 muss für das Bucket ein v1-DBRP-Mapping eingerichtet sein oder der Bucket-Name exakt mit dem Datenbanknamen übereinstimmen.';

  @override
  String influxErrorQuery(String detail) {
    return 'Abfragefehler: $detail';
  }

  @override
  String get influxErrorEndpointNotFound =>
      'Endpunkt nicht gefunden (404): Bitte Basis-URL und Port der InfluxDB-Instanz prüfen.';

  @override
  String influxErrorNetwork(String detail) {
    return 'Netzwerkverbindung fehlgeschlagen ($detail): Die InfluxDB-Instanz konnte nicht erreicht werden. Bitte Netzwerkverbindung, Host und Port prüfen.';
  }

  @override
  String influxErrorParse(String detail) {
    return 'Unerwartetes Antwortformat ($detail): Die Antwort der InfluxDB konnte nicht verarbeitet werden.';
  }

  @override
  String influxErrorUnexpected(String detail) {
    return 'Unerwarteter Fehler: $detail';
  }

  @override
  String get schemaConnectionNotFound => 'Verbindung nicht gefunden.';

  @override
  String get schemaTokenNotFound =>
      'API-Token für diese Verbindung nicht gefunden.';

  @override
  String get schemaNoConnectionSelected => 'Keine Verbindung ausgewählt.';

  @override
  String get schemaConnectionOrTokenNotFound =>
      'Verbindung oder Token nicht gefunden.';

  @override
  String widgetCopySuffix(String title) {
    return '$title (Kopie)';
  }

  @override
  String previewBucketErrors(int count, String error) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Zeit-Buckets nicht berechenbar: $error',
      one: '1 Zeit-Bucket nicht berechenbar: $error',
    );
    return '$_temp0';
  }

  @override
  String get previewNoToken => 'Kein Authentifizierungs-Token vorhanden.';

  @override
  String get previewNoField => 'Kein Feld angegeben.';

  @override
  String get previewNoFields => 'Keine Sensor-Felder konfiguriert.';

  @override
  String formulaSyntaxError(String error) {
    return 'Syntaxfehler: $error';
  }

  @override
  String formulaUndefinedVariables(String names) {
    return 'Nicht definierte Variable: $names';
  }

  @override
  String formulaStepError(String error) {
    return 'Schrittfehler: $error';
  }

  @override
  String formulaTemplateApplied(String title) {
    return 'Vorlage \"$title\" übernommen. Bitte die Variablen zuordnen.';
  }

  @override
  String get formulaShareSubject => 'Formel-Prompt für KI';

  @override
  String get formulaDefaultStepName => 'schritt';

  @override
  String get formulaEnableTitle => 'Berechnungsformel verwenden';

  @override
  String get formulaEnableSubtitle =>
      'Werte aus InfluxDB vor der Anzeige lokal verrechnen';

  @override
  String get formulaTitle => 'Mathematische Formel';

  @override
  String get formulaHelpTooltip => 'Hilfe und Vorlagen';

  @override
  String get formulaInputLabel => 'Formel (z. B. (A + B) / 2 oder min(A, B))';

  @override
  String get formulaInputHelper =>
      'Unterstützt + - * /, Klammern, Vergleiche, Funktionen und if(...)';

  @override
  String get formulaVariablesTitle => 'Variablen-Zuweisung';

  @override
  String get formulaAddVariable => 'Variable hinzufügen';

  @override
  String get formulaNoVariables =>
      'Keine Variablen vorhanden. Füge mindestens eine Variable hinzu.';

  @override
  String get formulaStepsTitle => 'Zwischenschritte';

  @override
  String get formulaAddStep => 'Schritt hinzufügen';

  @override
  String get formulaStepsHint =>
      'Optional: benannte Teilformeln, die in der Formel oben verwendet werden. Die Formel oben ist das Ergebnis.';

  @override
  String get formulaStepName => 'Name';

  @override
  String get formulaStepExpression => 'Ausdruck';

  @override
  String get formulaDeleteStep => 'Schritt löschen';

  @override
  String formulaVariableTitle(String name) {
    return 'Variable $name';
  }

  @override
  String get formulaNoFieldAssigned => 'Kein Feld zugewiesen';

  @override
  String get formulaEditField => 'Feld bearbeiten';

  @override
  String get formulaDeleteVariable => 'Variable löschen';

  @override
  String formulaVariableDialogTitle(String name) {
    return 'Variable $name anpassen';
  }

  @override
  String get formulaVariableMeasurement =>
      'Abweichendes Measurement (optional)';

  @override
  String get formulaVariableTagFilters => 'Tag-Filter';

  @override
  String get formulaVariableTag => 'Tag';

  @override
  String get formulaVariableTagValue => 'Wert';

  @override
  String get formulaVariableAddTag => 'Tag-Filter hinzufügen';

  @override
  String get formulaVariableLabel => 'Bezeichnung (optional)';

  @override
  String get commonApply => 'Übernehmen';

  @override
  String get previewDefaultTitle => 'Widget Vorschau';

  @override
  String get previewNotLoaded =>
      'Noch keine Vorschau geladen.\nDrücke auf „Vorschau laden“.';

  @override
  String get previewNoPoints =>
      'Keine Datenpunkte im gewählten Zeitraum gefunden.';

  @override
  String previewHistorySummary(
    String latest,
    String unit,
    String min,
    String max,
  ) {
    return 'Aktuell: $latest $unit  (Min: $min, Max: $max)';
  }

  @override
  String previewLampCondition(String op, String value, String state) {
    return 'Bedingung: $op $value ($state)';
  }

  @override
  String get previewLampActive => 'Aktiv';

  @override
  String get previewLampInactive => 'Inaktiv';

  @override
  String get previewNoThreshold => 'Keine Schwelle konfiguriert';

  @override
  String get previewNoMultiPoints => 'Keine Multi-Value Datenpunkte geladen.';

  @override
  String codeErrorInvalidJson(String detail) {
    return 'Kein gültiges JSON: $detail';
  }

  @override
  String get codeErrorNotObject => 'Der Code muss ein JSON-Objekt sein.';

  @override
  String codeErrorUnknownType(String type, String detail) {
    return 'Unbekannter Widget-Typ \"$type\" ($detail).';
  }

  @override
  String codeErrorWrongType(String detail) {
    return 'Ein Wert hat den falschen Typ: $detail';
  }

  @override
  String get codeErrorMeasurementMissing => 'Measurement fehlt.';

  @override
  String get codeErrorGapPolicy =>
      'gapPolicy muss \"skip\" oder \"previous\" sein.';

  @override
  String get codeErrorChartStyle =>
      'chartStyle ist ungültig (Farben als #RRGGBB, lineWidth > 0).';

  @override
  String get codeErrorAppearance =>
      'appearance ist ungültig (Farben als #RRGGBB, Werte im Bereich).';

  @override
  String get codeFormulaMain => 'Formel';

  @override
  String codeFormulaRow(String row) {
    return 'Formel der Zeile \"$row\"';
  }

  @override
  String get codeErrorIncomplete =>
      'Das Widget ist unvollständig: ohne Formel wird ein \"field\" (bzw. \"items\" bei multi_value) benötigt.';

  @override
  String codeErrorFormulaSyntax(String what, String error) {
    return '$what: Syntaxfehler: $error';
  }

  @override
  String codeErrorNoVariable(String what) {
    return '$what: Es ist keine Variable definiert.';
  }

  @override
  String codeErrorVariableNoField(String what, String name) {
    return '$what: Variable $name hat kein Feld.';
  }

  @override
  String codeErrorFormula(String what, String error) {
    return '$what: $error';
  }

  @override
  String get alertTargetMean => 'Mittelwert';

  @override
  String get alertTargetMin => 'Minimum';

  @override
  String get alertTargetMax => 'Maximum';

  @override
  String get alertTargetLatest => 'Letzter Wert';

  @override
  String get alertTargetCalculated => 'Berechneter Wert';

  @override
  String get alertTargetValue => 'Wert';

  @override
  String get gapPolicyTitle => 'Lücken im Verlauf';

  @override
  String get gapPolicyQuestion =>
      'Was passiert, wenn in einem Zeit-Bucket ein Wert der Formel fehlt?';

  @override
  String get gapPolicySkip => 'Bucket überspringen';

  @override
  String get gapPolicyPrevious => 'Letzten Wert übernehmen';

  @override
  String formulaRowDefaultLabel(int number) {
    return 'Berechnung $number';
  }

  @override
  String get formulaRowsTitle => 'Berechnete Zeilen (Formel)';

  @override
  String get formulaRowsAdd => 'Formel-Zeile';

  @override
  String get formulaRowsHint =>
      'Optional: Zeilen, deren Wert aus einer eigenen Formel berechnet wird.';

  @override
  String get formulaRowLabel => 'Bezeichnung der Zeile';

  @override
  String get formulaRowDelete => 'Zeile löschen';

  @override
  String get editorEnterFormula => 'Bitte gib eine Berechnungsformel ein.';

  @override
  String editorInvalidFormula(String error) {
    return 'Ungültige Formel: $error';
  }

  @override
  String get editorAddVariable => 'Bitte füge mindestens eine Variable hinzu.';

  @override
  String get editorAssignFields => 'Bitte allen Variablen ein Feld zuordnen.';

  @override
  String editorInvalidSteps(String error) {
    return 'Ungültige Zwischenschritte: $error';
  }

  @override
  String get editorNoVariable => 'Keine Variable definiert';

  @override
  String editorFormulaRowError(String row, String error) {
    return 'Formelzeile \"$row\": $error';
  }

  @override
  String get editorTitleNew => 'Widget konfigurieren';

  @override
  String get editorTitleEdit => 'Widget bearbeiten';

  @override
  String get editorNoConnection =>
      'Keine InfluxDB-Verbindung vorhanden.\nBitte zuerst eine Verbindung erstellen.';

  @override
  String get commonBack => 'Zurück';

  @override
  String get editorLoadPreview => 'Vorschau laden';

  @override
  String get editorBasicSettings => 'Basis-Einstellungen';

  @override
  String get editorWidgetTitle => 'Widget Titel';

  @override
  String get editorTitleRequired => 'Bitte Titel eingeben';

  @override
  String get editorConnection => 'InfluxDB Verbindung';

  @override
  String editorConnectionItem(String name, String database) {
    return '$name ($database)';
  }

  @override
  String get editorWidgetType => 'Widget-Typ';

  @override
  String get editorDataSource => 'Datenquelle (InfluxQL)';

  @override
  String get editorMeasurementHint => 'z. B. climate, home_sensors';

  @override
  String get editorMeasurementRequired => 'Bitte Measurement eingeben';

  @override
  String get editorFieldsRequired => 'Mindestens 1 Feld auswählen';

  @override
  String get editorField => 'Feld';

  @override
  String get editorFieldHint => 'z. B. temperature, power';

  @override
  String get editorFieldRequired => 'Bitte Feld angeben';

  @override
  String get editorUnit => 'Einheit (optional)';

  @override
  String get editorDecimals => 'Nachkommastellen';

  @override
  String get editorDecimalsHint => 'Max. 2 (z. B. 1 oder 2)';

  @override
  String get editorSaveWidget => 'Widget Speichern';

  @override
  String get editorHistorySettings => 'Verlauf-Einstellungen';

  @override
  String get editorTimeRange => 'Zeitraum';

  @override
  String get editorInterval => 'Aggregations-Intervall';

  @override
  String get editorThresholdCondition => 'Schwellenwert-Bedingung';

  @override
  String get editorOperator => 'Op';

  @override
  String get editorScale => 'Skala & Grenzen';

  @override
  String get editorAggregateRange => 'Aggregat-Zeitraum';

  @override
  String durationMinutes(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Minuten',
      one: '1 Minute',
    );
    return '$_temp0';
  }

  @override
  String durationHours(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Stunden',
      one: '1 Stunde',
    );
    return '$_temp0';
  }

  @override
  String durationDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Tage',
      one: '1 Tag',
    );
    return '$_temp0';
  }
}
