// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Russian (`ru`).
class AppLocalizationsRu extends AppLocalizations {
  AppLocalizationsRu([String locale = 'ru']) : super(locale);

  @override
  String get appName => 'Мой фитнес-дневник';

  @override
  String get menu => 'Меню';

  @override
  String get back => 'Назад';

  @override
  String get cancel => 'Отмена';

  @override
  String get save => 'Сохранить';

  @override
  String get delete => 'Удалить';

  @override
  String get remove => 'Убрать';

  @override
  String get gotIt => 'Понятно';

  @override
  String get navRoutines => 'Тренировки';

  @override
  String get navExercises => 'Упражнения';

  @override
  String get navStats => 'Статистика';

  @override
  String get navProfile => 'Профиль';

  @override
  String get thisWeek => 'Эта неделя';

  @override
  String get trainingDays => 'Дни тренировок';

  @override
  String get startRoutine => 'Начать тренировку';

  @override
  String get startRoutineEmpty =>
      'Здесь пока пусто — откройте «Тренировки» в меню и запишите одну.';

  @override
  String get nothingLoggedWeek => 'пока ничего не записано — страница пуста';

  @override
  String workoutsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count тренировки',
      many: '$count тренировок',
      few: '$count тренировки',
      one: '$count тренировка',
    );
    return '$_temp0';
  }

  @override
  String workoutNoun(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'тренировки',
      many: 'тренировок',
      few: 'тренировки',
      one: 'тренировка',
    );
    return '$_temp0';
  }

  @override
  String streakLine(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'серия $count дня — пусть чернила текут',
      many: 'серия $count дней — пусть чернила текут',
      few: 'серия $count дня — пусть чернила текут',
      one: 'серия $count день — пусть чернила текут',
    );
    return '$_temp0';
  }

  @override
  String get trainingTime => 'Время тренировок';

  @override
  String get bodyTrends => 'Динамика тела';

  @override
  String get statThisMonth => 'этот месяц';

  @override
  String get statVsLastMonth => 'к прошлому месяцу';

  @override
  String get statAvgSession => 'средняя тренировка';

  @override
  String get statAllTime => 'за всё время';

  @override
  String get finishWorkoutEmpty => 'заверши тренировку — и она появится здесь';

  @override
  String get minutesPerWeek => 'минуты в неделю · последние 10';

  @override
  String get noTimedWorkouts =>
      'длительность появится после тренировок с таймером';

  @override
  String get noMeasurements =>
      'замеров пока нет — добавь их на странице профиля';

  @override
  String get logWeightAgain => 'запиши вес ещё раз, чтобы построить график';

  @override
  String statsGoal(String value) {
    return 'цель $value';
  }

  @override
  String get barThisWeek => 'эта неделя';

  @override
  String get newRoutine => '+ новая тренировка…';

  @override
  String get routineNameHint => 'название…';

  @override
  String get createRoutineSemantic => 'Создать тренировку';

  @override
  String manageNamed(String name) {
    return 'Настроить $name';
  }

  @override
  String deleteRoutineTitle(String name) {
    return 'Удалить «$name»?';
  }

  @override
  String get deleteRoutineMessage =>
      'Тренировка, её упражнения и журнал сессий будут удалены.';

  @override
  String get manageRoutineSemantic => 'Настроить тренировку';

  @override
  String get workoutComplete => 'Тренировка завершена';

  @override
  String get exercisesCompletedLabel => 'Упражнений выполнено';

  @override
  String get setsCompletedLabel => 'Подходов выполнено';

  @override
  String get repsLoggedLabel => 'Повторений записано';

  @override
  String get totalDurationLabel => 'Общая длительность';

  @override
  String get timePausedLabel => 'В паузе';

  @override
  String get removeSessionTitle => 'Убрать сессию?';

  @override
  String get removeSessionMessage => 'Убрать эту сессию из журнала?';

  @override
  String setActual(int index, String unit) {
    return 'Подход $index · факт. $unit';
  }

  @override
  String get startWorkout => 'Начать тренировку';

  @override
  String get noExercisesWorkout =>
      'Упражнений пока нет — добавь через ✐ вверху.';

  @override
  String get loggedSessions => 'Журнал сессий';

  @override
  String get noSessions => 'Сессий пока нет.';

  @override
  String get paused => 'пауза';

  @override
  String get pause => 'Пауза';

  @override
  String get resume => 'Продолжить';

  @override
  String get finish => 'Завершить';

  @override
  String get aboutMe => 'О себе';

  @override
  String get fieldName => 'Имя';

  @override
  String get fieldBorn => 'Дата рождения';

  @override
  String get fieldHeight => 'Рост';

  @override
  String get pickDateHint => 'нажми, чтобы выбрать дату…';

  @override
  String ageYears(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '($count года)',
      many: '($count лет)',
      few: '($count года)',
      one: '($count год)',
    );
    return '$_temp0';
  }

  @override
  String get unitsLabel => 'единицы:';

  @override
  String get languageLabel => 'язык:';

  @override
  String get measurements => 'Замеры';

  @override
  String get measurementsHint =>
      'нажми на строку для истории и цели, + чтобы записать';

  @override
  String get saveDetails => 'Сохранить';

  @override
  String logMetric(String metric) {
    return 'Записать: $metric';
  }

  @override
  String get goalLabel => 'цель:';

  @override
  String get saveGoalSemantic => 'Сохранить цель';

  @override
  String get deleteEntrySemantic => 'Удалить запись';

  @override
  String get noEntries =>
      'записей пока нет — добавь через + на странице профиля';

  @override
  String get metricWeight => 'вес';

  @override
  String get metricChest => 'грудь';

  @override
  String get metricWaist => 'талия';

  @override
  String get metricHips => 'бёдра';

  @override
  String get metricBiceps => 'бицепс';

  @override
  String get metricThigh => 'бедро';

  @override
  String get newExerciseTitle => 'Новое упражнение';

  @override
  String get editExerciseTitle => 'Изменить упражнение';

  @override
  String exerciseExists(String name) {
    return '«$name» уже существует.';
  }

  @override
  String exerciseNameTaken(String name) {
    return 'Упражнение «$name» уже есть.';
  }

  @override
  String get deleteExerciseTitle => 'Удалить упражнение?';

  @override
  String removeFromLibrary(String name) {
    return 'Убрать «$name» из библиотеки?';
  }

  @override
  String routinesUsingSuffix(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: ' Оно останется в $count тренировках, где уже используется.',
      many: ' Оно останется в $count тренировках, где уже используется.',
      few: ' Оно останется в $count тренировках, где уже используется.',
      one: ' Оно останется в $count тренировке, где уже используется.',
    );
    return '$_temp0';
  }

  @override
  String get noExercisesLibrary => 'Упражнений пока нет — добавь ниже.';

  @override
  String get newExerciseLine => '+ новое упражнение…';

  @override
  String get exercisesEditHint =>
      'смахни влево, чтобы удалить · нажми, чтобы изменить';

  @override
  String get fieldDescription => 'Описание';

  @override
  String get descHint => 'техника, заметки…';

  @override
  String get defaultSetsReps => 'Подходы × повторы (по умолчанию)';

  @override
  String get unitLabel => 'тип:';

  @override
  String get manageRoutineTitle => 'Настройка тренировки';

  @override
  String get routineDetails => 'О тренировке';

  @override
  String get routineDescHint => 'Для чего эта тренировка?';

  @override
  String addNamedTitle(String name) {
    return 'Добавить «$name»';
  }

  @override
  String get deleteRoutineConfirmTitle => 'Удалить эту тренировку?';

  @override
  String removeExerciseTitle(String name) {
    return 'Убрать «$name»?';
  }

  @override
  String get removeExerciseMessage => 'Убрать это упражнение из тренировки?';

  @override
  String get addExerciseHint => '+ добавить упражнение…';

  @override
  String get addExerciseSemantic => 'Добавить упражнение';

  @override
  String editPrescriptionSemantic(String name) {
    return 'Изменить подходы/повторы: $name';
  }

  @override
  String get deleteRoutineButton => 'Удалить тренировку';

  @override
  String get noExercisesManage => 'Упражнений пока нет — добавь выше.';

  @override
  String get previousMonth => 'Предыдущий месяц';

  @override
  String get nextMonth => 'Следующий месяц';
}
