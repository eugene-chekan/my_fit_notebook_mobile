import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_ru.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
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
    Locale('ru'),
  ];

  /// No description provided for @appName.
  ///
  /// In en, this message translates to:
  /// **'My fit notebook'**
  String get appName;

  /// No description provided for @menu.
  ///
  /// In en, this message translates to:
  /// **'Menu'**
  String get menu;

  /// No description provided for @back.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get back;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @remove.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get remove;

  /// No description provided for @gotIt.
  ///
  /// In en, this message translates to:
  /// **'Got it'**
  String get gotIt;

  /// No description provided for @navRoutines.
  ///
  /// In en, this message translates to:
  /// **'Routines'**
  String get navRoutines;

  /// No description provided for @navSchedule.
  ///
  /// In en, this message translates to:
  /// **'Schedule'**
  String get navSchedule;

  /// No description provided for @navExercises.
  ///
  /// In en, this message translates to:
  /// **'Exercises'**
  String get navExercises;

  /// No description provided for @navStats.
  ///
  /// In en, this message translates to:
  /// **'Stats'**
  String get navStats;

  /// No description provided for @navProfile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get navProfile;

  /// No description provided for @thisWeek.
  ///
  /// In en, this message translates to:
  /// **'This week'**
  String get thisWeek;

  /// No description provided for @trainingDays.
  ///
  /// In en, this message translates to:
  /// **'Training days'**
  String get trainingDays;

  /// No description provided for @startRoutine.
  ///
  /// In en, this message translates to:
  /// **'Start routine'**
  String get startRoutine;

  /// No description provided for @startRoutineEmpty.
  ///
  /// In en, this message translates to:
  /// **'Nothing here yet — open Routines from the menu and write one down.'**
  String get startRoutineEmpty;

  /// No description provided for @resumeNamed.
  ///
  /// In en, this message translates to:
  /// **'▸ Resume {name}'**
  String resumeNamed(String name);

  /// No description provided for @scheduleWorkout.
  ///
  /// In en, this message translates to:
  /// **'Schedule a workout'**
  String get scheduleWorkout;

  /// No description provided for @upcomingHeading.
  ///
  /// In en, this message translates to:
  /// **'Upcoming'**
  String get upcomingHeading;

  /// No description provided for @missedHeading.
  ///
  /// In en, this message translates to:
  /// **'Missed'**
  String get missedHeading;

  /// No description provided for @noUpcoming.
  ///
  /// In en, this message translates to:
  /// **'Nothing planned yet.'**
  String get noUpcoming;

  /// No description provided for @pickRoutine.
  ///
  /// In en, this message translates to:
  /// **'Pick a routine'**
  String get pickRoutine;

  /// No description provided for @todayLabel.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get todayLabel;

  /// No description provided for @tomorrowLabel.
  ///
  /// In en, this message translates to:
  /// **'Tomorrow'**
  String get tomorrowLabel;

  /// No description provided for @rescheduleSemantic.
  ///
  /// In en, this message translates to:
  /// **'Reschedule'**
  String get rescheduleSemantic;

  /// No description provided for @allRoutinesPlanned.
  ///
  /// In en, this message translates to:
  /// **'All routines are already planned for this day.'**
  String get allRoutinesPlanned;

  /// No description provided for @scheduledTodayLine.
  ///
  /// In en, this message translates to:
  /// **'▸ Today: {name}'**
  String scheduledTodayLine(String name);

  /// No description provided for @scheduledOnLine.
  ///
  /// In en, this message translates to:
  /// **'▸ {date}: {name}'**
  String scheduledOnLine(String date, String name);

  /// No description provided for @nothingLoggedWeek.
  ///
  /// In en, this message translates to:
  /// **'nothing logged yet — the page is blank'**
  String get nothingLoggedWeek;

  /// No description provided for @workoutsCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{{count} workout} other{{count} workouts}}'**
  String workoutsCount(int count);

  /// No description provided for @workoutNoun.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{workout} other{workouts}}'**
  String workoutNoun(int count);

  /// No description provided for @streakLine.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{{count}-day streak — keep the ink flowing} other{{count}-day streak — keep the ink flowing}}'**
  String streakLine(int count);

  /// No description provided for @trainingTime.
  ///
  /// In en, this message translates to:
  /// **'Training time'**
  String get trainingTime;

  /// No description provided for @bodyTrends.
  ///
  /// In en, this message translates to:
  /// **'Body trends'**
  String get bodyTrends;

  /// No description provided for @statThisMonth.
  ///
  /// In en, this message translates to:
  /// **'this month'**
  String get statThisMonth;

  /// No description provided for @statVsLastMonth.
  ///
  /// In en, this message translates to:
  /// **'vs last month'**
  String get statVsLastMonth;

  /// No description provided for @statAvgSession.
  ///
  /// In en, this message translates to:
  /// **'avg session'**
  String get statAvgSession;

  /// No description provided for @statAllTime.
  ///
  /// In en, this message translates to:
  /// **'all time'**
  String get statAllTime;

  /// No description provided for @finishWorkoutEmpty.
  ///
  /// In en, this message translates to:
  /// **'finish a workout and it lands here'**
  String get finishWorkoutEmpty;

  /// No description provided for @minutesPerWeek.
  ///
  /// In en, this message translates to:
  /// **'minutes per week · last 10'**
  String get minutesPerWeek;

  /// No description provided for @noTimedWorkouts.
  ///
  /// In en, this message translates to:
  /// **'durations appear here once you finish timed sessions'**
  String get noTimedWorkouts;

  /// No description provided for @noMeasurements.
  ///
  /// In en, this message translates to:
  /// **'no measurements yet — add them on the Profile page'**
  String get noMeasurements;

  /// No description provided for @logWeightAgain.
  ///
  /// In en, this message translates to:
  /// **'log weight again to draw the trend'**
  String get logWeightAgain;

  /// No description provided for @statsGoal.
  ///
  /// In en, this message translates to:
  /// **'goal {value}'**
  String statsGoal(String value);

  /// No description provided for @barThisWeek.
  ///
  /// In en, this message translates to:
  /// **'this week'**
  String get barThisWeek;

  /// No description provided for @newRoutine.
  ///
  /// In en, this message translates to:
  /// **'+ new routine…'**
  String get newRoutine;

  /// No description provided for @routineNameHint.
  ///
  /// In en, this message translates to:
  /// **'name…'**
  String get routineNameHint;

  /// No description provided for @createRoutineSemantic.
  ///
  /// In en, this message translates to:
  /// **'Create routine'**
  String get createRoutineSemantic;

  /// No description provided for @manageNamed.
  ///
  /// In en, this message translates to:
  /// **'Manage {name}'**
  String manageNamed(String name);

  /// No description provided for @deleteRoutineTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete “{name}”?'**
  String deleteRoutineTitle(String name);

  /// No description provided for @deleteRoutineMessage.
  ///
  /// In en, this message translates to:
  /// **'This removes the routine, its exercises, and its session log.'**
  String get deleteRoutineMessage;

  /// No description provided for @manageRoutineSemantic.
  ///
  /// In en, this message translates to:
  /// **'Manage routine'**
  String get manageRoutineSemantic;

  /// No description provided for @workoutComplete.
  ///
  /// In en, this message translates to:
  /// **'Workout complete'**
  String get workoutComplete;

  /// No description provided for @exercisesCompletedLabel.
  ///
  /// In en, this message translates to:
  /// **'Exercises completed'**
  String get exercisesCompletedLabel;

  /// No description provided for @setsCompletedLabel.
  ///
  /// In en, this message translates to:
  /// **'Sets completed'**
  String get setsCompletedLabel;

  /// No description provided for @repsLoggedLabel.
  ///
  /// In en, this message translates to:
  /// **'Reps logged'**
  String get repsLoggedLabel;

  /// No description provided for @totalDurationLabel.
  ///
  /// In en, this message translates to:
  /// **'Total duration'**
  String get totalDurationLabel;

  /// No description provided for @timePausedLabel.
  ///
  /// In en, this message translates to:
  /// **'Time paused'**
  String get timePausedLabel;

  /// No description provided for @removeSessionTitle.
  ///
  /// In en, this message translates to:
  /// **'Remove session?'**
  String get removeSessionTitle;

  /// No description provided for @removeSessionMessage.
  ///
  /// In en, this message translates to:
  /// **'Remove this session from the log?'**
  String get removeSessionMessage;

  /// No description provided for @setActual.
  ///
  /// In en, this message translates to:
  /// **'Set {index} · actual {unit}'**
  String setActual(int index, String unit);

  /// No description provided for @startWorkout.
  ///
  /// In en, this message translates to:
  /// **'Start workout'**
  String get startWorkout;

  /// No description provided for @workoutRunning.
  ///
  /// In en, this message translates to:
  /// **'Workout in progress'**
  String get workoutRunning;

  /// No description provided for @addExercises.
  ///
  /// In en, this message translates to:
  /// **'Add exercises'**
  String get addExercises;

  /// No description provided for @noExercisesWorkout.
  ///
  /// In en, this message translates to:
  /// **'No exercises yet — add one via ✐ above.'**
  String get noExercisesWorkout;

  /// No description provided for @loggedSessions.
  ///
  /// In en, this message translates to:
  /// **'Logged sessions'**
  String get loggedSessions;

  /// No description provided for @noSessions.
  ///
  /// In en, this message translates to:
  /// **'No sessions logged yet.'**
  String get noSessions;

  /// No description provided for @sessionExercises.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{{count} exercise} other{{count} exercises}}'**
  String sessionExercises(int count);

  /// No description provided for @sessionSets.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{{count} set} other{{count} sets}}'**
  String sessionSets(int count);

  /// No description provided for @sessionReps.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{{count} rep} other{{count} reps}}'**
  String sessionReps(int count);

  /// No description provided for @paused.
  ///
  /// In en, this message translates to:
  /// **'paused'**
  String get paused;

  /// No description provided for @pause.
  ///
  /// In en, this message translates to:
  /// **'Pause'**
  String get pause;

  /// No description provided for @resume.
  ///
  /// In en, this message translates to:
  /// **'Resume'**
  String get resume;

  /// No description provided for @finish.
  ///
  /// In en, this message translates to:
  /// **'Finish'**
  String get finish;

  /// No description provided for @aboutMe.
  ///
  /// In en, this message translates to:
  /// **'About me'**
  String get aboutMe;

  /// No description provided for @fieldName.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get fieldName;

  /// No description provided for @fieldBorn.
  ///
  /// In en, this message translates to:
  /// **'Born'**
  String get fieldBorn;

  /// No description provided for @fieldHeight.
  ///
  /// In en, this message translates to:
  /// **'Height'**
  String get fieldHeight;

  /// No description provided for @pickDateHint.
  ///
  /// In en, this message translates to:
  /// **'tap to pick a date…'**
  String get pickDateHint;

  /// No description provided for @ageYears.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{({count} year)} other{({count} years)}}'**
  String ageYears(int count);

  /// No description provided for @unitsLabel.
  ///
  /// In en, this message translates to:
  /// **'units:'**
  String get unitsLabel;

  /// No description provided for @languageLabel.
  ///
  /// In en, this message translates to:
  /// **'language:'**
  String get languageLabel;

  /// No description provided for @measurements.
  ///
  /// In en, this message translates to:
  /// **'Measurements'**
  String get measurements;

  /// No description provided for @measurementsHint.
  ///
  /// In en, this message translates to:
  /// **'tap a line for history & goal, + to log'**
  String get measurementsHint;

  /// No description provided for @saveDetails.
  ///
  /// In en, this message translates to:
  /// **'Save details'**
  String get saveDetails;

  /// No description provided for @logMetric.
  ///
  /// In en, this message translates to:
  /// **'Log {metric}'**
  String logMetric(String metric);

  /// No description provided for @goalLabel.
  ///
  /// In en, this message translates to:
  /// **'goal:'**
  String get goalLabel;

  /// No description provided for @saveGoalSemantic.
  ///
  /// In en, this message translates to:
  /// **'Save goal'**
  String get saveGoalSemantic;

  /// No description provided for @deleteEntrySemantic.
  ///
  /// In en, this message translates to:
  /// **'Delete entry'**
  String get deleteEntrySemantic;

  /// No description provided for @noEntries.
  ///
  /// In en, this message translates to:
  /// **'no entries yet — log one with + on the profile page'**
  String get noEntries;

  /// No description provided for @metricWeight.
  ///
  /// In en, this message translates to:
  /// **'weight'**
  String get metricWeight;

  /// No description provided for @metricChest.
  ///
  /// In en, this message translates to:
  /// **'chest'**
  String get metricChest;

  /// No description provided for @metricWaist.
  ///
  /// In en, this message translates to:
  /// **'waist'**
  String get metricWaist;

  /// No description provided for @metricHips.
  ///
  /// In en, this message translates to:
  /// **'hips'**
  String get metricHips;

  /// No description provided for @metricBiceps.
  ///
  /// In en, this message translates to:
  /// **'biceps'**
  String get metricBiceps;

  /// No description provided for @metricThigh.
  ///
  /// In en, this message translates to:
  /// **'thigh'**
  String get metricThigh;

  /// No description provided for @newExerciseTitle.
  ///
  /// In en, this message translates to:
  /// **'New exercise'**
  String get newExerciseTitle;

  /// No description provided for @editExerciseTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit exercise'**
  String get editExerciseTitle;

  /// No description provided for @exerciseExists.
  ///
  /// In en, this message translates to:
  /// **'“{name}” already exists.'**
  String exerciseExists(String name);

  /// No description provided for @exerciseNameTaken.
  ///
  /// In en, this message translates to:
  /// **'Another exercise is already called “{name}”.'**
  String exerciseNameTaken(String name);

  /// No description provided for @deleteExerciseTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete exercise?'**
  String get deleteExerciseTitle;

  /// No description provided for @removeFromLibrary.
  ///
  /// In en, this message translates to:
  /// **'Remove “{name}” from the library?'**
  String removeFromLibrary(String name);

  /// No description provided for @routinesUsingSuffix.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{ It stays in the {count} routine already using it.} other{ It stays in the {count} routines already using it.}}'**
  String routinesUsingSuffix(int count);

  /// No description provided for @noExercisesLibrary.
  ///
  /// In en, this message translates to:
  /// **'No exercises yet — add one below.'**
  String get noExercisesLibrary;

  /// No description provided for @newExerciseLine.
  ///
  /// In en, this message translates to:
  /// **'+ new exercise…'**
  String get newExerciseLine;

  /// No description provided for @exercisesEditHint.
  ///
  /// In en, this message translates to:
  /// **'swipe left to delete · tap to edit'**
  String get exercisesEditHint;

  /// No description provided for @fieldDescription.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get fieldDescription;

  /// No description provided for @descHint.
  ///
  /// In en, this message translates to:
  /// **'form cues, notes…'**
  String get descHint;

  /// No description provided for @defaultSetsReps.
  ///
  /// In en, this message translates to:
  /// **'Default sets × reps'**
  String get defaultSetsReps;

  /// No description provided for @unitLabel.
  ///
  /// In en, this message translates to:
  /// **'unit:'**
  String get unitLabel;

  /// No description provided for @manageRoutineTitle.
  ///
  /// In en, this message translates to:
  /// **'Manage routine'**
  String get manageRoutineTitle;

  /// No description provided for @routineDetails.
  ///
  /// In en, this message translates to:
  /// **'Routine details'**
  String get routineDetails;

  /// No description provided for @routineDescHint.
  ///
  /// In en, this message translates to:
  /// **'What is this routine for?'**
  String get routineDescHint;

  /// No description provided for @addNamedTitle.
  ///
  /// In en, this message translates to:
  /// **'Add “{name}”'**
  String addNamedTitle(String name);

  /// No description provided for @deleteRoutineConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete this routine?'**
  String get deleteRoutineConfirmTitle;

  /// No description provided for @removeExerciseTitle.
  ///
  /// In en, this message translates to:
  /// **'Remove “{name}”?'**
  String removeExerciseTitle(String name);

  /// No description provided for @removeExerciseMessage.
  ///
  /// In en, this message translates to:
  /// **'Remove this exercise from the routine?'**
  String get removeExerciseMessage;

  /// No description provided for @addExerciseHint.
  ///
  /// In en, this message translates to:
  /// **'+ add an exercise…'**
  String get addExerciseHint;

  /// No description provided for @addExerciseSemantic.
  ///
  /// In en, this message translates to:
  /// **'Add exercise'**
  String get addExerciseSemantic;

  /// No description provided for @editPrescriptionSemantic.
  ///
  /// In en, this message translates to:
  /// **'Edit sets/reps for {name}'**
  String editPrescriptionSemantic(String name);

  /// No description provided for @deleteRoutineButton.
  ///
  /// In en, this message translates to:
  /// **'Delete routine'**
  String get deleteRoutineButton;

  /// No description provided for @noExercisesManage.
  ///
  /// In en, this message translates to:
  /// **'No exercises yet — add one above.'**
  String get noExercisesManage;

  /// No description provided for @previousMonth.
  ///
  /// In en, this message translates to:
  /// **'Previous month'**
  String get previousMonth;

  /// No description provided for @nextMonth.
  ///
  /// In en, this message translates to:
  /// **'Next month'**
  String get nextMonth;
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
      <String>['en', 'ru'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'ru':
      return AppLocalizationsRu();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
