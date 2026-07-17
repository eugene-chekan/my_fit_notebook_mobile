// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appName => 'My fit notebook';

  @override
  String get menu => 'Menu';

  @override
  String get back => 'Back';

  @override
  String get cancel => 'Cancel';

  @override
  String get save => 'Save';

  @override
  String get delete => 'Delete';

  @override
  String get remove => 'Remove';

  @override
  String get gotIt => 'Got it';

  @override
  String get navRoutines => 'Routines';

  @override
  String get navSchedule => 'Schedule';

  @override
  String get navExercises => 'Exercises';

  @override
  String get navStats => 'Stats';

  @override
  String get navProfile => 'Profile';

  @override
  String get thisWeek => 'This week';

  @override
  String get trainingDays => 'Training days';

  @override
  String get startRoutine => 'Start routine';

  @override
  String get startRoutineEmpty =>
      'Nothing here yet — open Routines from the menu and write one down.';

  @override
  String resumeNamed(String name) {
    return '▸ Resume $name';
  }

  @override
  String get scheduleWorkout => 'Schedule a workout';

  @override
  String get upcomingHeading => 'Upcoming';

  @override
  String get missedHeading => 'Missed';

  @override
  String get noUpcoming => 'Nothing planned yet.';

  @override
  String get pickRoutine => 'Pick a routine';

  @override
  String get todayLabel => 'Today';

  @override
  String get tomorrowLabel => 'Tomorrow';

  @override
  String get rescheduleSemantic => 'Reschedule';

  @override
  String get allRoutinesPlanned =>
      'All routines are already planned for this day.';

  @override
  String scheduledTodayLine(String name) {
    return '▸ Today: $name';
  }

  @override
  String scheduledOnLine(String date, String name) {
    return '▸ $date: $name';
  }

  @override
  String get nothingLoggedWeek => 'nothing logged yet — the page is blank';

  @override
  String workoutsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count workouts',
      one: '$count workout',
    );
    return '$_temp0';
  }

  @override
  String workoutNoun(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'workouts',
      one: 'workout',
    );
    return '$_temp0';
  }

  @override
  String streakLine(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count-day streak — keep the ink flowing',
      one: '$count-day streak — keep the ink flowing',
    );
    return '$_temp0';
  }

  @override
  String get trainingTime => 'Training time';

  @override
  String get bodyTrends => 'Body trends';

  @override
  String get statThisMonth => 'this month';

  @override
  String get statVsLastMonth => 'vs last month';

  @override
  String get statAvgSession => 'avg session';

  @override
  String get statAllTime => 'all time';

  @override
  String get finishWorkoutEmpty => 'finish a workout and it lands here';

  @override
  String get minutesPerWeek => 'minutes per week · last 10';

  @override
  String get noTimedWorkouts =>
      'durations appear here once you finish timed sessions';

  @override
  String get noMeasurements =>
      'no measurements yet — add them on the Profile page';

  @override
  String get logWeightAgain => 'log weight again to draw the trend';

  @override
  String statsGoal(String value) {
    return 'goal $value';
  }

  @override
  String get barThisWeek => 'this week';

  @override
  String get newRoutine => '+ new routine…';

  @override
  String get routineNameHint => 'name…';

  @override
  String get createRoutineSemantic => 'Create routine';

  @override
  String manageNamed(String name) {
    return 'Manage $name';
  }

  @override
  String deleteRoutineTitle(String name) {
    return 'Delete “$name”?';
  }

  @override
  String get deleteRoutineMessage =>
      'This removes the routine, its exercises, and its session log.';

  @override
  String get manageRoutineSemantic => 'Manage routine';

  @override
  String get workoutComplete => 'Workout complete';

  @override
  String get exercisesCompletedLabel => 'Exercises completed';

  @override
  String get setsCompletedLabel => 'Sets completed';

  @override
  String get repsLoggedLabel => 'Reps logged';

  @override
  String get totalDurationLabel => 'Total duration';

  @override
  String get timePausedLabel => 'Time paused';

  @override
  String get removeSessionTitle => 'Remove session?';

  @override
  String get removeSessionMessage => 'Remove this session from the log?';

  @override
  String setActual(int index, String unit) {
    return 'Set $index · actual $unit';
  }

  @override
  String get startWorkout => 'Start workout';

  @override
  String get workoutRunning => 'Workout in progress';

  @override
  String get workoutReminderChannel => 'Workout reminders';

  @override
  String get reminderTitle => 'Time to train';

  @override
  String get addExercises => 'Add exercises';

  @override
  String get noExercisesWorkout => 'No exercises yet — add one via ✐ above.';

  @override
  String get loggedSessions => 'Logged sessions';

  @override
  String get noSessions => 'No sessions logged yet.';

  @override
  String sessionExercises(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count exercises',
      one: '$count exercise',
    );
    return '$_temp0';
  }

  @override
  String sessionSets(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count sets',
      one: '$count set',
    );
    return '$_temp0';
  }

  @override
  String sessionReps(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count reps',
      one: '$count rep',
    );
    return '$_temp0';
  }

  @override
  String get paused => 'paused';

  @override
  String get pause => 'Pause';

  @override
  String get resume => 'Resume';

  @override
  String get finish => 'Finish';

  @override
  String get aboutMe => 'About me';

  @override
  String get fieldName => 'Name';

  @override
  String get fieldBorn => 'Born';

  @override
  String get fieldHeight => 'Height';

  @override
  String get pickDateHint => 'tap to pick a date…';

  @override
  String ageYears(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '($count years)',
      one: '($count year)',
    );
    return '$_temp0';
  }

  @override
  String get unitsLabel => 'units:';

  @override
  String get languageLabel => 'language:';

  @override
  String get measurements => 'Measurements';

  @override
  String get measurementsHint => 'tap a line for history & goal, + to log';

  @override
  String get saveDetails => 'Save details';

  @override
  String logMetric(String metric) {
    return 'Log $metric';
  }

  @override
  String get goalLabel => 'goal:';

  @override
  String get saveGoalSemantic => 'Save goal';

  @override
  String get deleteEntrySemantic => 'Delete entry';

  @override
  String get noEntries => 'no entries yet — log one with + on the profile page';

  @override
  String get metricWeight => 'weight';

  @override
  String get metricChest => 'chest';

  @override
  String get metricWaist => 'waist';

  @override
  String get metricHips => 'hips';

  @override
  String get metricBiceps => 'biceps';

  @override
  String get metricThigh => 'thigh';

  @override
  String get newExerciseTitle => 'New exercise';

  @override
  String get editExerciseTitle => 'Edit exercise';

  @override
  String exerciseExists(String name) {
    return '“$name” already exists.';
  }

  @override
  String exerciseNameTaken(String name) {
    return 'Another exercise is already called “$name”.';
  }

  @override
  String get deleteExerciseTitle => 'Delete exercise?';

  @override
  String removeFromLibrary(String name) {
    return 'Remove “$name” from the library?';
  }

  @override
  String routinesUsingSuffix(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: ' It stays in the $count routines already using it.',
      one: ' It stays in the $count routine already using it.',
    );
    return '$_temp0';
  }

  @override
  String get noExercisesLibrary => 'No exercises yet — add one below.';

  @override
  String get newExerciseLine => '+ new exercise…';

  @override
  String get exercisesEditHint => 'swipe left to delete · tap to edit';

  @override
  String get fieldDescription => 'Description';

  @override
  String get descHint => 'form cues, notes…';

  @override
  String get defaultSetsReps => 'Default sets × reps';

  @override
  String get unitLabel => 'unit:';

  @override
  String get manageRoutineTitle => 'Manage routine';

  @override
  String get routineDetails => 'Routine details';

  @override
  String get routineDescHint => 'What is this routine for?';

  @override
  String addNamedTitle(String name) {
    return 'Add “$name”';
  }

  @override
  String get deleteRoutineConfirmTitle => 'Delete this routine?';

  @override
  String removeExerciseTitle(String name) {
    return 'Remove “$name”?';
  }

  @override
  String get removeExerciseMessage => 'Remove this exercise from the routine?';

  @override
  String get addExerciseHint => '+ add an exercise…';

  @override
  String get addExerciseSemantic => 'Add exercise';

  @override
  String editPrescriptionSemantic(String name) {
    return 'Edit sets/reps for $name';
  }

  @override
  String get deleteRoutineButton => 'Delete routine';

  @override
  String get noExercisesManage => 'No exercises yet — add one above.';

  @override
  String get previousMonth => 'Previous month';

  @override
  String get nextMonth => 'Next month';
}
