import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_de.dart';
import 'app_localizations_en.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'generated/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('de'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'Sensor Widgets'**
  String get appTitle;

  /// No description provided for @commonCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get commonCancel;

  /// No description provided for @commonEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get commonEdit;

  /// No description provided for @commonDuplicate.
  ///
  /// In en, this message translates to:
  /// **'Duplicate'**
  String get commonDuplicate;

  /// No description provided for @commonDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get commonDelete;

  /// No description provided for @commonSave.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get commonSave;

  /// No description provided for @commonReset.
  ///
  /// In en, this message translates to:
  /// **'Reset'**
  String get commonReset;

  /// No description provided for @commonErrorDetails.
  ///
  /// In en, this message translates to:
  /// **'Error: {error}'**
  String commonErrorDetails(String error);

  /// No description provided for @dashboardSyncTooltip.
  ///
  /// In en, this message translates to:
  /// **'Sync native widgets'**
  String get dashboardSyncTooltip;

  /// No description provided for @dashboardSyncDone.
  ///
  /// In en, this message translates to:
  /// **'Native widgets updated.'**
  String get dashboardSyncDone;

  /// No description provided for @dashboardHelpTooltip.
  ///
  /// In en, this message translates to:
  /// **'Formula help'**
  String get dashboardHelpTooltip;

  /// No description provided for @dashboardConnectionsTooltip.
  ///
  /// In en, this message translates to:
  /// **'InfluxDB connections'**
  String get dashboardConnectionsTooltip;

  /// No description provided for @dashboardEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No widgets configured yet'**
  String get dashboardEmptyTitle;

  /// No description provided for @dashboardEmptyBody.
  ///
  /// In en, this message translates to:
  /// **'Create your first home-screen widget!'**
  String get dashboardEmptyBody;

  /// No description provided for @dashboardCreateWidget.
  ///
  /// In en, this message translates to:
  /// **'Create widget'**
  String get dashboardCreateWidget;

  /// No description provided for @dashboardCardSubtitle.
  ///
  /// In en, this message translates to:
  /// **'{measurement} • every {minutes} min'**
  String dashboardCardSubtitle(String measurement, int minutes);

  /// No description provided for @dashboardActionsTooltip.
  ///
  /// In en, this message translates to:
  /// **'Actions'**
  String get dashboardActionsTooltip;

  /// No description provided for @connectionsTitle.
  ///
  /// In en, this message translates to:
  /// **'InfluxDB Connections'**
  String get connectionsTitle;

  /// No description provided for @connectionsEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No connections configured'**
  String get connectionsEmptyTitle;

  /// No description provided for @connectionsEmptyHint.
  ///
  /// In en, this message translates to:
  /// **'Tap + to add an InfluxDB server'**
  String get connectionsEmptyHint;

  /// No description provided for @connectionsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'{url} • DB: {database}'**
  String connectionsSubtitle(String url, String database);

  /// No description provided for @connectionsDeleteTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete Connection'**
  String get connectionsDeleteTitle;

  /// No description provided for @connectionsDeleteConfirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete \"{name}\"?'**
  String connectionsDeleteConfirm(String name);

  /// No description provided for @connectionsLoadError.
  ///
  /// In en, this message translates to:
  /// **'Error loading connections: {error}'**
  String connectionsLoadError(String error);

  /// No description provided for @connectionTestSuccess.
  ///
  /// In en, this message translates to:
  /// **'Connection successful!'**
  String get connectionTestSuccess;

  /// No description provided for @connectionTestNoResponse.
  ///
  /// In en, this message translates to:
  /// **'Connection failed: no response'**
  String get connectionTestNoResponse;

  /// No description provided for @connectionTestFailed.
  ///
  /// In en, this message translates to:
  /// **'Connection failed: {error}'**
  String connectionTestFailed(String error);

  /// No description provided for @connectionSaveFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to save connection: {error}'**
  String connectionSaveFailed(String error);

  /// No description provided for @connectionEditTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit Connection'**
  String get connectionEditTitle;

  /// No description provided for @connectionNewTitle.
  ///
  /// In en, this message translates to:
  /// **'New Connection'**
  String get connectionNewTitle;

  /// No description provided for @connectionNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Connection Name'**
  String get connectionNameLabel;

  /// No description provided for @connectionNameHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Home Server'**
  String get connectionNameHint;

  /// No description provided for @connectionNameRequired.
  ///
  /// In en, this message translates to:
  /// **'Please enter a connection name'**
  String get connectionNameRequired;

  /// No description provided for @connectionUrlLabel.
  ///
  /// In en, this message translates to:
  /// **'Host URL'**
  String get connectionUrlLabel;

  /// No description provided for @connectionUrlRequired.
  ///
  /// In en, this message translates to:
  /// **'Please enter host URL'**
  String get connectionUrlRequired;

  /// No description provided for @connectionUrlScheme.
  ///
  /// In en, this message translates to:
  /// **'URL must start with http:// or https://'**
  String get connectionUrlScheme;

  /// No description provided for @connectionDatabaseLabel.
  ///
  /// In en, this message translates to:
  /// **'Database / Bucket'**
  String get connectionDatabaseLabel;

  /// No description provided for @connectionDatabaseHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. sensors'**
  String get connectionDatabaseHint;

  /// No description provided for @connectionDatabaseRequired.
  ///
  /// In en, this message translates to:
  /// **'Please enter database name'**
  String get connectionDatabaseRequired;

  /// No description provided for @connectionOrgLabel.
  ///
  /// In en, this message translates to:
  /// **'Organization (optional)'**
  String get connectionOrgLabel;

  /// No description provided for @connectionOrgHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. home-org'**
  String get connectionOrgHint;

  /// No description provided for @connectionTokenLabel.
  ///
  /// In en, this message translates to:
  /// **'API Token'**
  String get connectionTokenLabel;

  /// No description provided for @connectionTokenKeepHint.
  ///
  /// In en, this message translates to:
  /// **'(Keep current token)'**
  String get connectionTokenKeepHint;

  /// No description provided for @connectionTokenRequiredHint.
  ///
  /// In en, this message translates to:
  /// **'Required for auth'**
  String get connectionTokenRequiredHint;

  /// No description provided for @connectionTokenRequired.
  ///
  /// In en, this message translates to:
  /// **'Please enter API token'**
  String get connectionTokenRequired;

  /// No description provided for @connectionTestButton.
  ///
  /// In en, this message translates to:
  /// **'Test Connection'**
  String get connectionTestButton;

  /// No description provided for @appearanceTitle.
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get appearanceTitle;

  /// No description provided for @appearanceBackgroundColor.
  ///
  /// In en, this message translates to:
  /// **'Background color'**
  String get appearanceBackgroundColor;

  /// No description provided for @appearanceBackgroundOpacity.
  ///
  /// In en, this message translates to:
  /// **'Background opacity'**
  String get appearanceBackgroundOpacity;

  /// No description provided for @appearanceTextColor.
  ///
  /// In en, this message translates to:
  /// **'Text color'**
  String get appearanceTextColor;

  /// No description provided for @appearanceAccentColor.
  ///
  /// In en, this message translates to:
  /// **'Accent color'**
  String get appearanceAccentColor;

  /// No description provided for @appearanceFontScale.
  ///
  /// In en, this message translates to:
  /// **'Font size'**
  String get appearanceFontScale;

  /// No description provided for @appearanceCornerRadius.
  ///
  /// In en, this message translates to:
  /// **'Corner radius'**
  String get appearanceCornerRadius;

  /// No description provided for @appearanceIosCornerHint.
  ///
  /// In en, this message translates to:
  /// **'Note: on iOS the system decides the corner radius of widgets.'**
  String get appearanceIosCornerHint;

  /// No description provided for @appearanceColorHint.
  ///
  /// In en, this message translates to:
  /// **'#RRGGBB (empty = default)'**
  String get appearanceColorHint;

  /// No description provided for @colorInvalid.
  ///
  /// In en, this message translates to:
  /// **'Invalid color (#RRGGBB)'**
  String get colorInvalid;

  /// No description provided for @chartStyleTitle.
  ///
  /// In en, this message translates to:
  /// **'Color gradient & chart style'**
  String get chartStyleTitle;

  /// No description provided for @chartStyleDescription.
  ///
  /// In en, this message translates to:
  /// **'The line is colored by value. Without color stops it keeps the default color.'**
  String get chartStyleDescription;

  /// No description provided for @chartStylePresetGreenToRed.
  ///
  /// In en, this message translates to:
  /// **'Green → Red'**
  String get chartStylePresetGreenToRed;

  /// No description provided for @chartStylePresetRedToGreen.
  ///
  /// In en, this message translates to:
  /// **'Red → Green'**
  String get chartStylePresetRedToGreen;

  /// No description provided for @chartStyleAddStop.
  ///
  /// In en, this message translates to:
  /// **'Add color stop'**
  String get chartStyleAddStop;

  /// No description provided for @chartStyleFillArea.
  ///
  /// In en, this message translates to:
  /// **'Fill area'**
  String get chartStyleFillArea;

  /// No description provided for @chartStyleGrid.
  ///
  /// In en, this message translates to:
  /// **'Grid'**
  String get chartStyleGrid;

  /// No description provided for @chartStyleAxes.
  ///
  /// In en, this message translates to:
  /// **'Axis labels'**
  String get chartStyleAxes;

  /// No description provided for @chartStyleMarkMinMax.
  ///
  /// In en, this message translates to:
  /// **'Mark min/max'**
  String get chartStyleMarkMinMax;

  /// No description provided for @chartStyleLineWidth.
  ///
  /// In en, this message translates to:
  /// **'Line width'**
  String get chartStyleLineWidth;

  /// No description provided for @chartStyleStopValue.
  ///
  /// In en, this message translates to:
  /// **'Value'**
  String get chartStyleStopValue;

  /// No description provided for @chartStyleStopColor.
  ///
  /// In en, this message translates to:
  /// **'Color'**
  String get chartStyleStopColor;

  /// No description provided for @chartStyleDeleteStop.
  ///
  /// In en, this message translates to:
  /// **'Delete color stop'**
  String get chartStyleDeleteStop;

  /// No description provided for @alertsTitle.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get alertsTitle;

  /// No description provided for @alertsDescription.
  ///
  /// In en, this message translates to:
  /// **'Push notification as soon as a value crosses the threshold. Again only after it has gone back.'**
  String get alertsDescription;

  /// No description provided for @alertsAdd.
  ///
  /// In en, this message translates to:
  /// **'Add notification'**
  String get alertsAdd;

  /// No description provided for @alertsAbove.
  ///
  /// In en, this message translates to:
  /// **'above'**
  String get alertsAbove;

  /// No description provided for @alertsBelow.
  ///
  /// In en, this message translates to:
  /// **'below'**
  String get alertsBelow;

  /// No description provided for @alertsThreshold.
  ///
  /// In en, this message translates to:
  /// **'Threshold'**
  String get alertsThreshold;

  /// No description provided for @alertsRemove.
  ///
  /// In en, this message translates to:
  /// **'Remove notification'**
  String get alertsRemove;

  /// No description provided for @widgetCodeApplied.
  ///
  /// In en, this message translates to:
  /// **'Code applied.'**
  String get widgetCodeApplied;

  /// No description provided for @widgetCodePromptCopied.
  ///
  /// In en, this message translates to:
  /// **'Prompt copied. Paste it into an AI, then describe the task.'**
  String get widgetCodePromptCopied;

  /// No description provided for @widgetCodeTitle.
  ///
  /// In en, this message translates to:
  /// **'Widget as code'**
  String get widgetCodeTitle;

  /// No description provided for @widgetCodeDescription.
  ///
  /// In en, this message translates to:
  /// **'The whole widget (type, formula, intermediate steps, variables, display) as JSON. Let an AI write it, copy the answer and tap \"Paste\".'**
  String get widgetCodeDescription;

  /// No description provided for @widgetCodeCopyPrompt.
  ///
  /// In en, this message translates to:
  /// **'Copy prompt for AI'**
  String get widgetCodeCopyPrompt;

  /// No description provided for @commonShare.
  ///
  /// In en, this message translates to:
  /// **'Share'**
  String get commonShare;

  /// No description provided for @widgetCodeFieldLabel.
  ///
  /// In en, this message translates to:
  /// **'Widget code (JSON)'**
  String get widgetCodeFieldLabel;

  /// No description provided for @widgetCodeDirty.
  ///
  /// In en, this message translates to:
  /// **'Changes not applied'**
  String get widgetCodeDirty;

  /// No description provided for @widgetCodeMirrorsForm.
  ///
  /// In en, this message translates to:
  /// **'Mirrors the form'**
  String get widgetCodeMirrorsForm;

  /// No description provided for @widgetCodeRegenerate.
  ///
  /// In en, this message translates to:
  /// **'Regenerate from form'**
  String get widgetCodeRegenerate;

  /// No description provided for @widgetCodeApply.
  ///
  /// In en, this message translates to:
  /// **'Apply code'**
  String get widgetCodeApply;

  /// No description provided for @widgetCodePromptShort.
  ///
  /// In en, this message translates to:
  /// **'AI prompt'**
  String get widgetCodePromptShort;

  /// No description provided for @widgetCodeCopyCode.
  ///
  /// In en, this message translates to:
  /// **'Copy'**
  String get widgetCodeCopyCode;

  /// No description provided for @widgetCodePasteCode.
  ///
  /// In en, this message translates to:
  /// **'Paste'**
  String get widgetCodePasteCode;

  /// No description provided for @widgetCodeCopyCodeTooltip.
  ///
  /// In en, this message translates to:
  /// **'Copy the current widget code'**
  String get widgetCodeCopyCodeTooltip;

  /// No description provided for @widgetCodePasteCodeTooltip.
  ///
  /// In en, this message translates to:
  /// **'Paste code from the clipboard and apply it'**
  String get widgetCodePasteCodeTooltip;

  /// No description provided for @widgetCodeCopied.
  ///
  /// In en, this message translates to:
  /// **'Code copied.'**
  String get widgetCodeCopied;

  /// No description provided for @widgetCodeClipboardEmpty.
  ///
  /// In en, this message translates to:
  /// **'The clipboard is empty.'**
  String get widgetCodeClipboardEmpty;

  /// No description provided for @editorSectionTypeSettings.
  ///
  /// In en, this message translates to:
  /// **'Type settings'**
  String get editorSectionTypeSettings;

  /// No description provided for @widgetTypeSingleValueDescription.
  ///
  /// In en, this message translates to:
  /// **'A current reading'**
  String get widgetTypeSingleValueDescription;

  /// No description provided for @widgetTypeHistoryChartDescription.
  ///
  /// In en, this message translates to:
  /// **'History over time'**
  String get widgetTypeHistoryChartDescription;

  /// No description provided for @widgetTypeIndicatorLampDescription.
  ///
  /// In en, this message translates to:
  /// **'Lamp with threshold'**
  String get widgetTypeIndicatorLampDescription;

  /// No description provided for @widgetTypeMultiValueDescription.
  ///
  /// In en, this message translates to:
  /// **'Several values at a glance'**
  String get widgetTypeMultiValueDescription;

  /// No description provided for @widgetTypeAggregateDescription.
  ///
  /// In en, this message translates to:
  /// **'Min, max and average'**
  String get widgetTypeAggregateDescription;

  /// No description provided for @widgetTypeGaugeBarDescription.
  ///
  /// In en, this message translates to:
  /// **'Level with color zones'**
  String get widgetTypeGaugeBarDescription;

  /// No description provided for @helpTitle.
  ///
  /// In en, this message translates to:
  /// **'Formula help'**
  String get helpTitle;

  /// No description provided for @helpFunctionsTitle.
  ///
  /// In en, this message translates to:
  /// **'Functions and constants'**
  String get helpFunctionsTitle;

  /// No description provided for @helpExample.
  ///
  /// In en, this message translates to:
  /// **'Example: {example}'**
  String helpExample(String example);

  /// No description provided for @helpTemplatesTitle.
  ///
  /// In en, this message translates to:
  /// **'Templates'**
  String get helpTemplatesTitle;

  /// No description provided for @helpTemplateResult.
  ///
  /// In en, this message translates to:
  /// **'Result = {formula}'**
  String helpTemplateResult(String formula);

  /// No description provided for @helpApplyTemplate.
  ///
  /// In en, this message translates to:
  /// **'Apply template'**
  String get helpApplyTemplate;

  /// No description provided for @helpVariablesTitle.
  ///
  /// In en, this message translates to:
  /// **'Variables'**
  String get helpVariablesTitle;

  /// No description provided for @helpVariablesBody.
  ///
  /// In en, this message translates to:
  /// **'Each variable (e.g. A, B or co2) stands for a field from the database. Readings are picked from the schema, optionally with their own measurement and tag filters. In the formula you only use the name of the variable.'**
  String get helpVariablesBody;

  /// No description provided for @helpOperatorsTitle.
  ///
  /// In en, this message translates to:
  /// **'Operators'**
  String get helpOperatorsTitle;

  /// No description provided for @helpOperatorsBody.
  ///
  /// In en, this message translates to:
  /// **'+ - * / and parentheses. Comparisons (< > <= >= == !=) return 1 (true) or 0 (false). Example: (A + B) / 2 or A > 25.'**
  String get helpOperatorsBody;

  /// No description provided for @helpStepsTitle.
  ///
  /// In en, this message translates to:
  /// **'Intermediate steps'**
  String get helpStepsTitle;

  /// No description provided for @helpStepsBody.
  ///
  /// In en, this message translates to:
  /// **'Intermediate steps are named partial formulas. They are calculated from top to bottom and may use variables and earlier steps. The formula at the top is the result and may use all steps.'**
  String get helpStepsBody;

  /// No description provided for @helpHistoryTitle.
  ///
  /// In en, this message translates to:
  /// **'History and aggregate'**
  String get helpHistoryTitle;

  /// No description provided for @helpHistoryBody.
  ///
  /// In en, this message translates to:
  /// **'For the history chart and the aggregate the formula is calculated per time bucket (average per interval). If a value is missing in a bucket, the bucket is skipped or the last value is carried over (gap policy). Aggregate computes min/max/mean over the calculated values.'**
  String get helpHistoryBody;

  /// No description provided for @helpErrorsTitle.
  ///
  /// In en, this message translates to:
  /// **'Errors'**
  String get helpErrorsTitle;

  /// No description provided for @helpErrorsBody.
  ///
  /// In en, this message translates to:
  /// **'Syntax errors show the position in the text. \"Division by zero\", \"Unknown function\", a wrong number of arguments, \"Missing variable\" and domain errors (e.g. sqrt of a negative number, ln(0)) are never silently shown as 0, but as a readable error message.'**
  String get helpErrorsBody;

  /// No description provided for @helpFnMin.
  ///
  /// In en, this message translates to:
  /// **'Smallest value (any number of arguments, at least one).'**
  String get helpFnMin;

  /// No description provided for @helpFnMax.
  ///
  /// In en, this message translates to:
  /// **'Largest value (any number of arguments, at least one).'**
  String get helpFnMax;

  /// No description provided for @helpFnClampSignature.
  ///
  /// In en, this message translates to:
  /// **'clamp(x, low, high)'**
  String get helpFnClampSignature;

  /// No description provided for @helpFnClamp.
  ///
  /// In en, this message translates to:
  /// **'Limits x to the range low to high.'**
  String get helpFnClamp;

  /// No description provided for @helpFnAbs.
  ///
  /// In en, this message translates to:
  /// **'Absolute value (without sign).'**
  String get helpFnAbs;

  /// No description provided for @helpFnPowSignature.
  ///
  /// In en, this message translates to:
  /// **'pow(base, exponent)'**
  String get helpFnPowSignature;

  /// No description provided for @helpFnPow.
  ///
  /// In en, this message translates to:
  /// **'Power.'**
  String get helpFnPow;

  /// No description provided for @helpFnSqrt.
  ///
  /// In en, this message translates to:
  /// **'Square root (x must not be negative).'**
  String get helpFnSqrt;

  /// No description provided for @helpFnLn.
  ///
  /// In en, this message translates to:
  /// **'Natural logarithm (x must be greater than 0).'**
  String get helpFnLn;

  /// No description provided for @helpFnLog10.
  ///
  /// In en, this message translates to:
  /// **'Base-10 logarithm (x must be greater than 0).'**
  String get helpFnLog10;

  /// No description provided for @helpFnExp.
  ///
  /// In en, this message translates to:
  /// **'e to the power of x.'**
  String get helpFnExp;

  /// No description provided for @helpFnRound.
  ///
  /// In en, this message translates to:
  /// **'Rounds to the nearest whole number (.5 away from 0).'**
  String get helpFnRound;

  /// No description provided for @helpFnFloor.
  ///
  /// In en, this message translates to:
  /// **'Rounds down.'**
  String get helpFnFloor;

  /// No description provided for @helpFnCeil.
  ///
  /// In en, this message translates to:
  /// **'Rounds up.'**
  String get helpFnCeil;

  /// No description provided for @helpFnIfSignature.
  ///
  /// In en, this message translates to:
  /// **'if(condition, then, else)'**
  String get helpFnIfSignature;

  /// No description provided for @helpFnIf.
  ///
  /// In en, this message translates to:
  /// **'Picks one of two values depending on the condition (not 0 = true). Only the chosen branch is calculated, e.g. if(B == 0, 0, A / B).'**
  String get helpFnIf;

  /// No description provided for @helpConstPi.
  ///
  /// In en, this message translates to:
  /// **'Pi 3.14159…'**
  String get helpConstPi;

  /// No description provided for @helpConstE.
  ///
  /// In en, this message translates to:
  /// **'Euler\'s number 2.71828…'**
  String get helpConstE;

  /// No description provided for @templateIaqDescription.
  ///
  /// In en, this message translates to:
  /// **'Air quality index 0 to 100. Each partial score is a linear ramp (CO₂ 600 ppm = 100, 2000 ppm = 0; VOC index 100 = 100, 250 = 0; PM2.5 5 µg/m³ = 100, 35 = 0; humidity 50 % = 100, 20 % or 80 % = 0). The worst partial score determines the result. Thresholds can be adjusted in the intermediate steps.'**
  String get templateIaqDescription;

  /// No description provided for @templateIaqVocLabel.
  ///
  /// In en, this message translates to:
  /// **'VOC index'**
  String get templateIaqVocLabel;

  /// No description provided for @templateIaqRhLabel.
  ///
  /// In en, this message translates to:
  /// **'Rel. humidity (%)'**
  String get templateIaqRhLabel;

  /// No description provided for @templateFahrenheitTitle.
  ///
  /// In en, this message translates to:
  /// **'Celsius to Fahrenheit'**
  String get templateFahrenheitTitle;

  /// No description provided for @templateFahrenheitDescription.
  ///
  /// In en, this message translates to:
  /// **'Converts a temperature from °C to °F.'**
  String get templateFahrenheitDescription;

  /// No description provided for @templateFahrenheitTempLabel.
  ///
  /// In en, this message translates to:
  /// **'Temperature'**
  String get templateFahrenheitTempLabel;

  /// No description provided for @templateAverageTitle.
  ///
  /// In en, this message translates to:
  /// **'Average of two sensors'**
  String get templateAverageTitle;

  /// No description provided for @templateAverageDescription.
  ///
  /// In en, this message translates to:
  /// **'Average of two readings.'**
  String get templateAverageDescription;

  /// No description provided for @templateAverageSensorLabel.
  ///
  /// In en, this message translates to:
  /// **'Sensor {number}'**
  String templateAverageSensorLabel(int number);

  /// No description provided for @schemaLoadingFromDb.
  ///
  /// In en, this message translates to:
  /// **'Loading from database...'**
  String get schemaLoadingFromDb;

  /// No description provided for @commonReload.
  ///
  /// In en, this message translates to:
  /// **'Reload'**
  String get commonReload;

  /// No description provided for @schemaPickFromList.
  ///
  /// In en, this message translates to:
  /// **'Pick from list'**
  String get schemaPickFromList;

  /// No description provided for @schemaPickTitle.
  ///
  /// In en, this message translates to:
  /// **'Select {title}'**
  String schemaPickTitle(String title);

  /// No description provided for @commonSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search...'**
  String get commonSearchHint;

  /// No description provided for @schemaNumericOnly.
  ///
  /// In en, this message translates to:
  /// **'Numeric fields only'**
  String get schemaNumericOnly;

  /// No description provided for @schemaNoMatches.
  ///
  /// In en, this message translates to:
  /// **'No matches found'**
  String get schemaNoMatches;

  /// No description provided for @tagFilterTitle.
  ///
  /// In en, this message translates to:
  /// **'Tag filters (optional)'**
  String get tagFilterTitle;

  /// No description provided for @tagFilterReloadTags.
  ///
  /// In en, this message translates to:
  /// **'Reload tags'**
  String get tagFilterReloadTags;

  /// No description provided for @tagFilterNone.
  ///
  /// In en, this message translates to:
  /// **'No tag filters active (fetch data for all tags)'**
  String get tagFilterNone;

  /// No description provided for @tagFilterAdd.
  ///
  /// In en, this message translates to:
  /// **'Add filter'**
  String get tagFilterAdd;

  /// No description provided for @tagFilterPickKey.
  ///
  /// In en, this message translates to:
  /// **'Select tag key'**
  String get tagFilterPickKey;

  /// No description provided for @tagFilterPickValue.
  ///
  /// In en, this message translates to:
  /// **'Select tag value for \"{key}\"'**
  String tagFilterPickValue(String key);

  /// No description provided for @schemaPickFromDb.
  ///
  /// In en, this message translates to:
  /// **'Pick from database:'**
  String get schemaPickFromDb;

  /// No description provided for @schemaOrEnterManually.
  ///
  /// In en, this message translates to:
  /// **'Or enter manually:'**
  String get schemaOrEnterManually;

  /// No description provided for @tagFilterKeyHint.
  ///
  /// In en, this message translates to:
  /// **'Tag key (e.g. room)'**
  String get tagFilterKeyHint;

  /// No description provided for @commonNext.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get commonNext;

  /// No description provided for @tagFilterLoadingValues.
  ///
  /// In en, this message translates to:
  /// **'Loading values from database...'**
  String get tagFilterLoadingValues;

  /// No description provided for @tagFilterValueHint.
  ///
  /// In en, this message translates to:
  /// **'Tag value (e.g. living_room)'**
  String get tagFilterValueHint;

  /// No description provided for @commonAdd.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get commonAdd;

  /// No description provided for @multiFieldTitle.
  ///
  /// In en, this message translates to:
  /// **'Fields (multi value) ({count} selected)'**
  String multiFieldTitle(int count);

  /// No description provided for @multiFieldReload.
  ///
  /// In en, this message translates to:
  /// **'Reload fields'**
  String get multiFieldReload;

  /// No description provided for @multiFieldNone.
  ///
  /// In en, this message translates to:
  /// **'No fields selected (at least 1 field required)'**
  String get multiFieldNone;

  /// No description provided for @multiFieldRemove.
  ///
  /// In en, this message translates to:
  /// **'Remove field'**
  String get multiFieldRemove;

  /// No description provided for @multiFieldSelect.
  ///
  /// In en, this message translates to:
  /// **'Select fields'**
  String get multiFieldSelect;

  /// No description provided for @multiFieldAddManual.
  ///
  /// In en, this message translates to:
  /// **'Add field manually'**
  String get multiFieldAddManual;

  /// No description provided for @multiFieldPickTitle.
  ///
  /// In en, this message translates to:
  /// **'Select fields from database'**
  String get multiFieldPickTitle;

  /// No description provided for @multiFieldSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search fields...'**
  String get multiFieldSearchHint;

  /// No description provided for @multiFieldNoneFound.
  ///
  /// In en, this message translates to:
  /// **'No fields found'**
  String get multiFieldNoneFound;

  /// No description provided for @multiFieldConfirm.
  ///
  /// In en, this message translates to:
  /// **'Apply ({count})'**
  String multiFieldConfirm(int count);

  /// No description provided for @multiFieldNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Field name (e.g. temperature)'**
  String get multiFieldNameLabel;

  /// No description provided for @multiFieldLabelLabel.
  ///
  /// In en, this message translates to:
  /// **'Display name / label (optional)'**
  String get multiFieldLabelLabel;

  /// No description provided for @multiFieldUnitLabel.
  ///
  /// In en, this message translates to:
  /// **'Unit (optional, e.g. °C)'**
  String get multiFieldUnitLabel;

  /// No description provided for @formulaErrorEmpty.
  ///
  /// In en, this message translates to:
  /// **'Formula must not be empty'**
  String get formulaErrorEmpty;

  /// No description provided for @formulaErrorUnexpectedCharacter.
  ///
  /// In en, this message translates to:
  /// **'Unexpected character: \"{char}\"'**
  String formulaErrorUnexpectedCharacter(String char);

  /// No description provided for @formulaErrorUnexpectedAssign.
  ///
  /// In en, this message translates to:
  /// **'Unexpected character: \"=\" (comparison: \"==\")'**
  String get formulaErrorUnexpectedAssign;

  /// No description provided for @formulaErrorInvalidNumber.
  ///
  /// In en, this message translates to:
  /// **'Invalid number: {text}'**
  String formulaErrorInvalidNumber(String text);

  /// No description provided for @formulaErrorUnknownOperator.
  ///
  /// In en, this message translates to:
  /// **'Unknown operator: {op}'**
  String formulaErrorUnknownOperator(String op);

  /// No description provided for @formulaErrorMissingOpeningParen.
  ///
  /// In en, this message translates to:
  /// **'Missing opening parenthesis'**
  String get formulaErrorMissingOpeningParen;

  /// No description provided for @formulaErrorMissingOperator.
  ///
  /// In en, this message translates to:
  /// **'Missing operator between operands'**
  String get formulaErrorMissingOperator;

  /// No description provided for @formulaErrorIncomplete.
  ///
  /// In en, this message translates to:
  /// **'Incomplete expression'**
  String get formulaErrorIncomplete;

  /// No description provided for @formulaErrorUnclosedParen.
  ///
  /// In en, this message translates to:
  /// **'Unclosed parenthesis'**
  String get formulaErrorUnclosedParen;

  /// No description provided for @formulaErrorInvalidStepName.
  ///
  /// In en, this message translates to:
  /// **'Invalid step name: \"{name}\"'**
  String formulaErrorInvalidStepName(String name);

  /// No description provided for @formulaErrorStepNameIsFunction.
  ///
  /// In en, this message translates to:
  /// **'Step name \"{name}\" is a function name'**
  String formulaErrorStepNameIsFunction(String name);

  /// No description provided for @formulaErrorDuplicateName.
  ///
  /// In en, this message translates to:
  /// **'Duplicate name: \"{name}\"'**
  String formulaErrorDuplicateName(String name);

  /// No description provided for @formulaErrorStepSelfReference.
  ///
  /// In en, this message translates to:
  /// **'Step \"{name}\" refers to itself'**
  String formulaErrorStepSelfReference(String name);

  /// No description provided for @formulaErrorStepForwardReference.
  ///
  /// In en, this message translates to:
  /// **'Step refers to a later step \"{name}\"'**
  String formulaErrorStepForwardReference(String name);

  /// No description provided for @formulaErrorDivisionByZero.
  ///
  /// In en, this message translates to:
  /// **'Division by zero'**
  String get formulaErrorDivisionByZero;

  /// No description provided for @formulaErrorMissingVariable.
  ///
  /// In en, this message translates to:
  /// **'Missing variable: {name}'**
  String formulaErrorMissingVariable(String name);

  /// No description provided for @formulaErrorUnknownFunction.
  ///
  /// In en, this message translates to:
  /// **'Unknown function: {name}'**
  String formulaErrorUnknownFunction(String name);

  /// No description provided for @formulaErrorWrongArgumentCount.
  ///
  /// In en, this message translates to:
  /// **'Function {name} expects {expected} argument(s), got: {actual}'**
  String formulaErrorWrongArgumentCount(
    String name,
    String expected,
    String actual,
  );

  /// No description provided for @formulaArityAtLeast.
  ///
  /// In en, this message translates to:
  /// **'at least {min}'**
  String formulaArityAtLeast(String min);

  /// No description provided for @formulaArityRange.
  ///
  /// In en, this message translates to:
  /// **'{min} to {max}'**
  String formulaArityRange(String min, String max);

  /// No description provided for @formulaErrorClampBounds.
  ///
  /// In en, this message translates to:
  /// **'clamp: lower bound greater than upper bound'**
  String get formulaErrorClampBounds;

  /// No description provided for @formulaErrorSqrtNegative.
  ///
  /// In en, this message translates to:
  /// **'sqrt: argument must not be negative'**
  String get formulaErrorSqrtNegative;

  /// No description provided for @formulaErrorLnNonPositive.
  ///
  /// In en, this message translates to:
  /// **'ln: argument must be greater than 0'**
  String get formulaErrorLnNonPositive;

  /// No description provided for @formulaErrorLog10NonPositive.
  ///
  /// In en, this message translates to:
  /// **'log10: argument must be greater than 0'**
  String get formulaErrorLog10NonPositive;

  /// No description provided for @formulaErrorNotFinite.
  ///
  /// In en, this message translates to:
  /// **'{function}: result is not finite'**
  String formulaErrorNotFinite(String function);

  /// No description provided for @formulaErrorResultNotFinite.
  ///
  /// In en, this message translates to:
  /// **'Result is not finite'**
  String get formulaErrorResultNotFinite;

  /// No description provided for @formulaErrorNoFormula.
  ///
  /// In en, this message translates to:
  /// **'Widget has no formula'**
  String get formulaErrorNoFormula;

  /// No description provided for @formulaErrorNoVariables.
  ///
  /// In en, this message translates to:
  /// **'No variables defined for the formula'**
  String get formulaErrorNoVariables;

  /// No description provided for @formulaErrorAtPosition.
  ///
  /// In en, this message translates to:
  /// **'{message} (position {position})'**
  String formulaErrorAtPosition(String message, int position);

  /// No description provided for @influxErrorAuth.
  ///
  /// In en, this message translates to:
  /// **'Authentication error (401): please check the API token and the read permissions for the database or bucket.'**
  String get influxErrorAuth;

  /// No description provided for @influxErrorDatabaseNotFound.
  ///
  /// In en, this message translates to:
  /// **'Database or bucket not found: in InfluxDB v2 the bucket needs a v1 DBRP mapping, or the bucket name must match the database name exactly.'**
  String get influxErrorDatabaseNotFound;

  /// No description provided for @influxErrorQuery.
  ///
  /// In en, this message translates to:
  /// **'Query error: {detail}'**
  String influxErrorQuery(String detail);

  /// No description provided for @influxErrorEndpointNotFound.
  ///
  /// In en, this message translates to:
  /// **'Endpoint not found (404): please check the base URL and port of the InfluxDB instance.'**
  String get influxErrorEndpointNotFound;

  /// No description provided for @influxErrorNetwork.
  ///
  /// In en, this message translates to:
  /// **'Network connection failed ({detail}): the InfluxDB instance could not be reached. Please check the network connection, host and port.'**
  String influxErrorNetwork(String detail);

  /// No description provided for @influxErrorParse.
  ///
  /// In en, this message translates to:
  /// **'Unexpected response format ({detail}): the InfluxDB response could not be processed.'**
  String influxErrorParse(String detail);

  /// No description provided for @influxErrorUnexpected.
  ///
  /// In en, this message translates to:
  /// **'Unexpected error: {detail}'**
  String influxErrorUnexpected(String detail);

  /// No description provided for @schemaConnectionNotFound.
  ///
  /// In en, this message translates to:
  /// **'Connection not found.'**
  String get schemaConnectionNotFound;

  /// No description provided for @schemaTokenNotFound.
  ///
  /// In en, this message translates to:
  /// **'API token for this connection not found.'**
  String get schemaTokenNotFound;

  /// No description provided for @schemaNoConnectionSelected.
  ///
  /// In en, this message translates to:
  /// **'No connection selected.'**
  String get schemaNoConnectionSelected;

  /// No description provided for @schemaConnectionOrTokenNotFound.
  ///
  /// In en, this message translates to:
  /// **'Connection or token not found.'**
  String get schemaConnectionOrTokenNotFound;

  /// No description provided for @widgetCopySuffix.
  ///
  /// In en, this message translates to:
  /// **'{title} (copy)'**
  String widgetCopySuffix(String title);

  /// No description provided for @previewBucketErrors.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 time bucket could not be calculated: {error}} other{{count} time buckets could not be calculated: {error}}}'**
  String previewBucketErrors(int count, String error);

  /// No description provided for @previewNoToken.
  ///
  /// In en, this message translates to:
  /// **'No authentication token available.'**
  String get previewNoToken;

  /// No description provided for @previewNoField.
  ///
  /// In en, this message translates to:
  /// **'No field given.'**
  String get previewNoField;

  /// No description provided for @previewNoFields.
  ///
  /// In en, this message translates to:
  /// **'No sensor fields configured.'**
  String get previewNoFields;

  /// No description provided for @formulaSyntaxError.
  ///
  /// In en, this message translates to:
  /// **'Syntax error: {error}'**
  String formulaSyntaxError(String error);

  /// No description provided for @formulaUndefinedVariables.
  ///
  /// In en, this message translates to:
  /// **'Undefined variable: {names}'**
  String formulaUndefinedVariables(String names);

  /// No description provided for @formulaStepError.
  ///
  /// In en, this message translates to:
  /// **'Step error: {error}'**
  String formulaStepError(String error);

  /// No description provided for @formulaTemplateApplied.
  ///
  /// In en, this message translates to:
  /// **'Template \"{title}\" applied. Please map the variables.'**
  String formulaTemplateApplied(String title);

  /// No description provided for @formulaShareSubject.
  ///
  /// In en, this message translates to:
  /// **'Formula prompt for AI'**
  String get formulaShareSubject;

  /// Prefix of new step names (a number is appended). Must be a valid formula identifier: letters, digits and _, no spaces.
  ///
  /// In en, this message translates to:
  /// **'step'**
  String get formulaDefaultStepName;

  /// No description provided for @formulaEnableTitle.
  ///
  /// In en, this message translates to:
  /// **'Use calculation formula'**
  String get formulaEnableTitle;

  /// No description provided for @formulaEnableSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Calculate values from InfluxDB locally before display'**
  String get formulaEnableSubtitle;

  /// No description provided for @formulaTitle.
  ///
  /// In en, this message translates to:
  /// **'Mathematical formula'**
  String get formulaTitle;

  /// No description provided for @formulaHelpTooltip.
  ///
  /// In en, this message translates to:
  /// **'Help and templates'**
  String get formulaHelpTooltip;

  /// No description provided for @formulaInputLabel.
  ///
  /// In en, this message translates to:
  /// **'Formula (e.g. (A + B) / 2 or min(A, B))'**
  String get formulaInputLabel;

  /// No description provided for @formulaInputHelper.
  ///
  /// In en, this message translates to:
  /// **'Supports + - * /, parentheses, comparisons, functions and if(...)'**
  String get formulaInputHelper;

  /// No description provided for @formulaVariablesTitle.
  ///
  /// In en, this message translates to:
  /// **'Variable mapping'**
  String get formulaVariablesTitle;

  /// No description provided for @formulaAddVariable.
  ///
  /// In en, this message translates to:
  /// **'Add variable'**
  String get formulaAddVariable;

  /// No description provided for @formulaNoVariables.
  ///
  /// In en, this message translates to:
  /// **'No variables yet. Add at least one variable.'**
  String get formulaNoVariables;

  /// No description provided for @formulaStepsTitle.
  ///
  /// In en, this message translates to:
  /// **'Intermediate steps'**
  String get formulaStepsTitle;

  /// No description provided for @formulaAddStep.
  ///
  /// In en, this message translates to:
  /// **'Add step'**
  String get formulaAddStep;

  /// No description provided for @formulaStepsHint.
  ///
  /// In en, this message translates to:
  /// **'Optional: named partial formulas that are used in the formula above. The formula above is the result.'**
  String get formulaStepsHint;

  /// No description provided for @formulaStepName.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get formulaStepName;

  /// No description provided for @formulaStepExpression.
  ///
  /// In en, this message translates to:
  /// **'Expression'**
  String get formulaStepExpression;

  /// No description provided for @formulaDeleteStep.
  ///
  /// In en, this message translates to:
  /// **'Delete step'**
  String get formulaDeleteStep;

  /// No description provided for @formulaVariableTitle.
  ///
  /// In en, this message translates to:
  /// **'Variable {name}'**
  String formulaVariableTitle(String name);

  /// No description provided for @formulaNoFieldAssigned.
  ///
  /// In en, this message translates to:
  /// **'No field assigned'**
  String get formulaNoFieldAssigned;

  /// No description provided for @formulaEditField.
  ///
  /// In en, this message translates to:
  /// **'Edit field'**
  String get formulaEditField;

  /// No description provided for @formulaDeleteVariable.
  ///
  /// In en, this message translates to:
  /// **'Delete variable'**
  String get formulaDeleteVariable;

  /// No description provided for @formulaVariableDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit variable {name}'**
  String formulaVariableDialogTitle(String name);

  /// No description provided for @formulaVariableMeasurement.
  ///
  /// In en, this message translates to:
  /// **'Different measurement (optional)'**
  String get formulaVariableMeasurement;

  /// No description provided for @formulaVariableTagFilters.
  ///
  /// In en, this message translates to:
  /// **'Tag filters'**
  String get formulaVariableTagFilters;

  /// No description provided for @formulaVariableTag.
  ///
  /// In en, this message translates to:
  /// **'Tag'**
  String get formulaVariableTag;

  /// No description provided for @formulaVariableTagValue.
  ///
  /// In en, this message translates to:
  /// **'Value'**
  String get formulaVariableTagValue;

  /// No description provided for @formulaVariableAddTag.
  ///
  /// In en, this message translates to:
  /// **'Add tag filter'**
  String get formulaVariableAddTag;

  /// No description provided for @formulaVariableLabel.
  ///
  /// In en, this message translates to:
  /// **'Label (optional)'**
  String get formulaVariableLabel;

  /// No description provided for @commonApply.
  ///
  /// In en, this message translates to:
  /// **'Apply'**
  String get commonApply;

  /// No description provided for @previewDefaultTitle.
  ///
  /// In en, this message translates to:
  /// **'Widget preview'**
  String get previewDefaultTitle;

  /// No description provided for @previewNotLoaded.
  ///
  /// In en, this message translates to:
  /// **'No preview loaded yet.\nTap \"Load preview\".'**
  String get previewNotLoaded;

  /// No description provided for @previewNoPoints.
  ///
  /// In en, this message translates to:
  /// **'No data points found in the selected time range.'**
  String get previewNoPoints;

  /// No description provided for @previewHistorySummary.
  ///
  /// In en, this message translates to:
  /// **'Current: {latest} {unit}  (min: {min}, max: {max})'**
  String previewHistorySummary(
    String latest,
    String unit,
    String min,
    String max,
  );

  /// No description provided for @previewLampCondition.
  ///
  /// In en, this message translates to:
  /// **'Condition: {op} {value} ({state})'**
  String previewLampCondition(String op, String value, String state);

  /// No description provided for @previewLampActive.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get previewLampActive;

  /// No description provided for @previewLampInactive.
  ///
  /// In en, this message translates to:
  /// **'Inactive'**
  String get previewLampInactive;

  /// No description provided for @previewNoThreshold.
  ///
  /// In en, this message translates to:
  /// **'No threshold configured'**
  String get previewNoThreshold;

  /// No description provided for @previewNoMultiPoints.
  ///
  /// In en, this message translates to:
  /// **'No multi-value data points loaded.'**
  String get previewNoMultiPoints;

  /// No description provided for @codeErrorInvalidJson.
  ///
  /// In en, this message translates to:
  /// **'Invalid JSON: {detail}'**
  String codeErrorInvalidJson(String detail);

  /// No description provided for @codeErrorNotObject.
  ///
  /// In en, this message translates to:
  /// **'The code must be a JSON object.'**
  String get codeErrorNotObject;

  /// No description provided for @codeErrorUnknownType.
  ///
  /// In en, this message translates to:
  /// **'Unknown widget type \"{type}\" ({detail}).'**
  String codeErrorUnknownType(String type, String detail);

  /// No description provided for @codeErrorWrongType.
  ///
  /// In en, this message translates to:
  /// **'A value has the wrong type: {detail}'**
  String codeErrorWrongType(String detail);

  /// No description provided for @codeErrorMeasurementMissing.
  ///
  /// In en, this message translates to:
  /// **'Measurement is missing.'**
  String get codeErrorMeasurementMissing;

  /// No description provided for @codeErrorGapPolicy.
  ///
  /// In en, this message translates to:
  /// **'gapPolicy must be \"skip\" or \"previous\".'**
  String get codeErrorGapPolicy;

  /// No description provided for @codeErrorChartStyle.
  ///
  /// In en, this message translates to:
  /// **'chartStyle is invalid (colors as #RRGGBB, lineWidth > 0).'**
  String get codeErrorChartStyle;

  /// No description provided for @codeErrorAppearance.
  ///
  /// In en, this message translates to:
  /// **'appearance is invalid (colors as #RRGGBB, values within range).'**
  String get codeErrorAppearance;

  /// No description provided for @codeFormulaMain.
  ///
  /// In en, this message translates to:
  /// **'Formula'**
  String get codeFormulaMain;

  /// No description provided for @codeFormulaRow.
  ///
  /// In en, this message translates to:
  /// **'Formula of row \"{row}\"'**
  String codeFormulaRow(String row);

  /// No description provided for @codeErrorIncomplete.
  ///
  /// In en, this message translates to:
  /// **'The widget is incomplete: without a formula a \"field\" (or \"items\" for multi_value) is required.'**
  String get codeErrorIncomplete;

  /// No description provided for @codeErrorFormulaSyntax.
  ///
  /// In en, this message translates to:
  /// **'{what}: syntax error: {error}'**
  String codeErrorFormulaSyntax(String what, String error);

  /// No description provided for @codeErrorNoVariable.
  ///
  /// In en, this message translates to:
  /// **'{what}: no variable is defined.'**
  String codeErrorNoVariable(String what);

  /// No description provided for @codeErrorVariableNoField.
  ///
  /// In en, this message translates to:
  /// **'{what}: variable {name} has no field.'**
  String codeErrorVariableNoField(String what, String name);

  /// No description provided for @codeErrorFormula.
  ///
  /// In en, this message translates to:
  /// **'{what}: {error}'**
  String codeErrorFormula(String what, String error);

  /// No description provided for @alertTargetMean.
  ///
  /// In en, this message translates to:
  /// **'Average'**
  String get alertTargetMean;

  /// No description provided for @alertTargetMin.
  ///
  /// In en, this message translates to:
  /// **'Minimum'**
  String get alertTargetMin;

  /// No description provided for @alertTargetMax.
  ///
  /// In en, this message translates to:
  /// **'Maximum'**
  String get alertTargetMax;

  /// No description provided for @alertTargetLatest.
  ///
  /// In en, this message translates to:
  /// **'Latest value'**
  String get alertTargetLatest;

  /// No description provided for @alertTargetCalculated.
  ///
  /// In en, this message translates to:
  /// **'Calculated value'**
  String get alertTargetCalculated;

  /// No description provided for @alertTargetValue.
  ///
  /// In en, this message translates to:
  /// **'Value'**
  String get alertTargetValue;

  /// No description provided for @gapPolicyTitle.
  ///
  /// In en, this message translates to:
  /// **'Gaps in the history'**
  String get gapPolicyTitle;

  /// No description provided for @gapPolicyQuestion.
  ///
  /// In en, this message translates to:
  /// **'What happens when a formula value is missing in a time bucket?'**
  String get gapPolicyQuestion;

  /// No description provided for @gapPolicySkip.
  ///
  /// In en, this message translates to:
  /// **'Skip bucket'**
  String get gapPolicySkip;

  /// No description provided for @gapPolicyPrevious.
  ///
  /// In en, this message translates to:
  /// **'Carry over last value'**
  String get gapPolicyPrevious;

  /// No description provided for @formulaRowDefaultLabel.
  ///
  /// In en, this message translates to:
  /// **'Calculation {number}'**
  String formulaRowDefaultLabel(int number);

  /// No description provided for @formulaRowsTitle.
  ///
  /// In en, this message translates to:
  /// **'Calculated rows (formula)'**
  String get formulaRowsTitle;

  /// No description provided for @formulaRowsAdd.
  ///
  /// In en, this message translates to:
  /// **'Formula row'**
  String get formulaRowsAdd;

  /// No description provided for @formulaRowsHint.
  ///
  /// In en, this message translates to:
  /// **'Optional: rows whose value is calculated from their own formula.'**
  String get formulaRowsHint;

  /// No description provided for @formulaRowLabel.
  ///
  /// In en, this message translates to:
  /// **'Row label'**
  String get formulaRowLabel;

  /// No description provided for @formulaRowDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete row'**
  String get formulaRowDelete;

  /// No description provided for @editorEnterFormula.
  ///
  /// In en, this message translates to:
  /// **'Please enter a calculation formula.'**
  String get editorEnterFormula;

  /// No description provided for @editorInvalidFormula.
  ///
  /// In en, this message translates to:
  /// **'Invalid formula: {error}'**
  String editorInvalidFormula(String error);

  /// No description provided for @editorAddVariable.
  ///
  /// In en, this message translates to:
  /// **'Please add at least one variable.'**
  String get editorAddVariable;

  /// No description provided for @editorAssignFields.
  ///
  /// In en, this message translates to:
  /// **'Please assign a field to every variable.'**
  String get editorAssignFields;

  /// No description provided for @editorInvalidSteps.
  ///
  /// In en, this message translates to:
  /// **'Invalid intermediate steps: {error}'**
  String editorInvalidSteps(String error);

  /// No description provided for @editorNoVariable.
  ///
  /// In en, this message translates to:
  /// **'No variable defined'**
  String get editorNoVariable;

  /// No description provided for @editorFormulaRowError.
  ///
  /// In en, this message translates to:
  /// **'Formula row \"{row}\": {error}'**
  String editorFormulaRowError(String row, String error);

  /// No description provided for @editorTitleNew.
  ///
  /// In en, this message translates to:
  /// **'Configure widget'**
  String get editorTitleNew;

  /// No description provided for @editorTitleEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit widget'**
  String get editorTitleEdit;

  /// No description provided for @editorNoConnection.
  ///
  /// In en, this message translates to:
  /// **'No InfluxDB connection yet.\nPlease create a connection first.'**
  String get editorNoConnection;

  /// No description provided for @commonBack.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get commonBack;

  /// No description provided for @editorLoadPreview.
  ///
  /// In en, this message translates to:
  /// **'Load preview'**
  String get editorLoadPreview;

  /// No description provided for @editorBasicSettings.
  ///
  /// In en, this message translates to:
  /// **'Basic settings'**
  String get editorBasicSettings;

  /// No description provided for @editorWidgetTitle.
  ///
  /// In en, this message translates to:
  /// **'Widget title'**
  String get editorWidgetTitle;

  /// No description provided for @editorTitleRequired.
  ///
  /// In en, this message translates to:
  /// **'Please enter a title'**
  String get editorTitleRequired;

  /// No description provided for @editorConnection.
  ///
  /// In en, this message translates to:
  /// **'InfluxDB connection'**
  String get editorConnection;

  /// No description provided for @editorConnectionItem.
  ///
  /// In en, this message translates to:
  /// **'{name} ({database})'**
  String editorConnectionItem(String name, String database);

  /// No description provided for @editorWidgetType.
  ///
  /// In en, this message translates to:
  /// **'Widget type'**
  String get editorWidgetType;

  /// No description provided for @editorDataSource.
  ///
  /// In en, this message translates to:
  /// **'Data source (InfluxQL)'**
  String get editorDataSource;

  /// No description provided for @editorMeasurementHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. climate, home_sensors'**
  String get editorMeasurementHint;

  /// No description provided for @editorMeasurementRequired.
  ///
  /// In en, this message translates to:
  /// **'Please enter a measurement'**
  String get editorMeasurementRequired;

  /// No description provided for @editorFieldsRequired.
  ///
  /// In en, this message translates to:
  /// **'Select at least 1 field'**
  String get editorFieldsRequired;

  /// No description provided for @editorField.
  ///
  /// In en, this message translates to:
  /// **'Field'**
  String get editorField;

  /// No description provided for @editorFieldHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. temperature, power'**
  String get editorFieldHint;

  /// No description provided for @editorFieldRequired.
  ///
  /// In en, this message translates to:
  /// **'Please enter a field'**
  String get editorFieldRequired;

  /// No description provided for @editorUnit.
  ///
  /// In en, this message translates to:
  /// **'Unit (optional)'**
  String get editorUnit;

  /// No description provided for @editorDecimals.
  ///
  /// In en, this message translates to:
  /// **'Decimal places'**
  String get editorDecimals;

  /// No description provided for @editorDecimalsHint.
  ///
  /// In en, this message translates to:
  /// **'Max. 2 (e.g. 1 or 2)'**
  String get editorDecimalsHint;

  /// No description provided for @editorSaveWidget.
  ///
  /// In en, this message translates to:
  /// **'Save widget'**
  String get editorSaveWidget;

  /// No description provided for @editorHistorySettings.
  ///
  /// In en, this message translates to:
  /// **'History settings'**
  String get editorHistorySettings;

  /// No description provided for @editorTimeRange.
  ///
  /// In en, this message translates to:
  /// **'Time range'**
  String get editorTimeRange;

  /// No description provided for @editorInterval.
  ///
  /// In en, this message translates to:
  /// **'Aggregation interval'**
  String get editorInterval;

  /// No description provided for @editorThresholdCondition.
  ///
  /// In en, this message translates to:
  /// **'Threshold condition'**
  String get editorThresholdCondition;

  /// No description provided for @editorOperator.
  ///
  /// In en, this message translates to:
  /// **'Op'**
  String get editorOperator;

  /// No description provided for @editorScale.
  ///
  /// In en, this message translates to:
  /// **'Scale & limits'**
  String get editorScale;

  /// No description provided for @editorAggregateRange.
  ///
  /// In en, this message translates to:
  /// **'Aggregate time range'**
  String get editorAggregateRange;

  /// No description provided for @durationMinutes.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 minute} other{{count} minutes}}'**
  String durationMinutes(int count);

  /// No description provided for @durationHours.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 hour} other{{count} hours}}'**
  String durationHours(int count);

  /// No description provided for @durationDays.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 day} other{{count} days}}'**
  String durationDays(int count);
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['de', 'en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'de':
      return AppLocalizationsDe();
    case 'en':
      return AppLocalizationsEn();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
