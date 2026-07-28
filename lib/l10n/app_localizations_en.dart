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
  String get swipeCopy => 'copy';

  @override
  String get swipeDelete => 'delete';

  @override
  String get gotIt => 'Got it';

  @override
  String get navRoutines => 'Workouts';

  @override
  String get navPrograms => 'Programs';

  @override
  String get navSchedule => 'Schedule';

  @override
  String get navExercises => 'Exercises';

  @override
  String get navStats => 'Stats';

  @override
  String get navProfile => 'Profile';

  @override
  String get navSettings => 'Settings';

  @override
  String get thisWeek => 'This week';

  @override
  String get trainingDays => 'Training days';

  @override
  String get startRoutine => 'Start workout';

  @override
  String get startRoutineEmpty =>
      'Nothing here yet — open Workouts from the menu and write one down.';

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
  String get pickRoutine => 'Pick a workout';

  @override
  String get todayLabel => 'Today';

  @override
  String get tomorrowLabel => 'Tomorrow';

  @override
  String get rescheduleSemantic => 'Reschedule';

  @override
  String get allRoutinesPlanned =>
      'All workouts are already planned for this day.';

  @override
  String get repeatQuestion => 'Repeat?';

  @override
  String get repeatJustOnce => 'once';

  @override
  String get repeatWeekly => 'weekly';

  @override
  String get repeatOnceHint => 'this week only';

  @override
  String get repeatWeeklyHint => 'every week from now on';

  @override
  String get pickDaysLabel => 'days:';

  @override
  String get timeLabel => 'time:';

  @override
  String get noTimeSet => 'no reminder';

  @override
  String get clearTimeSemantic => 'Clear the time';

  @override
  String repeatWeeklyOn(String days) {
    return 'Weekly · $days';
  }

  @override
  String get recurringSemantic => 'Repeating workout';

  @override
  String get deleteSeriesTitle => 'Delete repeating workout?';

  @override
  String get deleteThisOccurrence => 'Just this one';

  @override
  String get deleteWholeSeries => 'The whole series';

  @override
  String get weekdayMon => 'Mon';

  @override
  String get weekdayTue => 'Tue';

  @override
  String get weekdayWed => 'Wed';

  @override
  String get weekdayThu => 'Thu';

  @override
  String get weekdayFri => 'Fri';

  @override
  String get weekdaySat => 'Sat';

  @override
  String get weekdaySun => 'Sun';

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
  String get newRoutine => '+ new workout…';

  @override
  String get routineNameHint => 'name…';

  @override
  String get createRoutineSemantic => 'Create workout';

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
      'This removes the workout, its exercises, and its session log.';

  @override
  String get manageRoutineSemantic => 'Manage workout';

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
  String get startTimeLabel => 'start';

  @override
  String get endTimeLabel => 'end';

  @override
  String get breakdownHeading => 'Breakdown';

  @override
  String get noSetDetails => 'No per-set details for this session.';

  @override
  String get aboutMe => 'About me';

  @override
  String get profilePhotoSemantic => 'Profile photo';

  @override
  String get photoActionsTitle => 'Profile photo';

  @override
  String get choosePhoto => 'Choose from gallery';

  @override
  String get removePhoto => 'Remove photo';

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
  String get unitKg => 'kg';

  @override
  String get unitCm => 'cm';

  @override
  String get unitLb => 'lb';

  @override
  String get unitIn => 'in';

  @override
  String get repUnitReps => 'reps';

  @override
  String get repUnitSec => 'sec';

  @override
  String get repUnitMin => 'min';

  @override
  String setLabel(int index) {
    return 'Set $index';
  }

  @override
  String get languageLabel => 'language:';

  @override
  String get themeLabel => 'theme:';

  @override
  String get themePaper => 'Paper';

  @override
  String get themeBlueprint => 'Blueprint';

  @override
  String get themeChalkboard => 'Chalkboard';

  @override
  String get themeLamp => 'Aged lamp';

  @override
  String get themeCarbon => 'Carbon';

  @override
  String get paperLabel => 'paper:';

  @override
  String get paperRuled => 'ruled';

  @override
  String get paperGrid => 'grid';

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
      other: ' It stays in the $count workouts already using it.',
      one: ' It stays in the $count workout already using it.',
    );
    return '$_temp0';
  }

  @override
  String get noExercisesLibrary => 'No exercises yet — add one below.';

  @override
  String get newExerciseLine => '+ new exercise…';

  @override
  String get exercisesEditHint =>
      'tap to edit · swipe to copy or delete · long-press to add to a workout';

  @override
  String get fieldDescription => 'Description';

  @override
  String get descHint => 'form cues, notes…';

  @override
  String get defaultSetsReps => 'Default sets × reps';

  @override
  String get unitLabel => 'unit:';

  @override
  String get manageRoutineTitle => 'Manage workout';

  @override
  String get routineDetails => 'Workout details';

  @override
  String get routineDescHint => 'What is this workout for?';

  @override
  String addNamedTitle(String name) {
    return 'Add “$name”';
  }

  @override
  String get deleteRoutineConfirmTitle => 'Delete this workout?';

  @override
  String removeExerciseTitle(String name) {
    return 'Remove “$name”?';
  }

  @override
  String get removeExerciseMessage => 'Remove this exercise from the workout?';

  @override
  String get addExerciseHint => '+ add an exercise…';

  @override
  String get addExerciseSemantic => 'Add exercise';

  @override
  String editPrescriptionSemantic(String name) {
    return 'Edit sets/reps for $name';
  }

  @override
  String get deleteRoutineButton => 'Delete workout';

  @override
  String get noExercisesManage => 'No exercises yet — add one above.';

  @override
  String get newProgram => '+ new program…';

  @override
  String get programNameHint => 'program name…';

  @override
  String get createProgramSemantic => 'Create program';

  @override
  String get noPrograms => 'No programs yet — group your workouts below.';

  @override
  String get programsHint =>
      'swipe right to copy · left to delete · long-press a workout to file it here';

  @override
  String deleteProgramTitle(String name) {
    return 'Delete “$name”?';
  }

  @override
  String get deleteProgramMessage =>
      'This removes the program only. Its workouts stay in your library.';

  @override
  String programWorkoutsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count workouts',
      one: '$count workout',
      zero: 'no workouts',
    );
    return '$_temp0';
  }

  @override
  String get emptyProgram =>
      'Nothing filed here yet — long-press a workout to add it.';

  @override
  String removeFromProgramTitle(String name) {
    return 'Remove “$name”?';
  }

  @override
  String get removeFromProgramMessage =>
      'Take this workout out of the program? It stays in your library.';

  @override
  String get addToProgramTitle => 'Add to a program';

  @override
  String get addToWorkoutTitle => 'Add to a workout';

  @override
  String addedToProgram(String name) {
    return 'Filed “$name”.';
  }

  @override
  String alreadyInProgram(String name) {
    return 'Already in “$name”.';
  }

  @override
  String addedToWorkout(String name) {
    return 'Added to “$name”.';
  }

  @override
  String get noWorkoutsToAdd => 'No workouts yet — create one first.';

  @override
  String get previousMonth => 'Previous month';

  @override
  String get nextMonth => 'Next month';
}
