import 'storage.dart';
import 'dart:math';
import 'package:intl/intl.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

typedef Storage = Map<dynamic, Map<dynamic, dynamic>>;
typedef Notif = ({String title, String body});

Future<void> bgLoad () async {
  final hour = DateTime.now().hour;
  final notifstart = int.tryParse(user.get("notifstart") ?? "6") ?? 6;
  final notifend = int.tryParse(user.get("notifend") ?? "22") ?? 22;
  if ((hour < notifstart) || (hour >= notifend)) {
    await logInfo(['bgload exited early']);
    return;
  }
  final oldStorage = storage.toMap();
  logInfo(['notifkace bgload start']);
  await completeReload();
  final newStorage = storage.toMap();
  final List<Notif> allDayNotifs = [
    ...newMarks(oldStorage, newStorage),
    ...timeTableChanges(oldStorage, newStorage),
  ];
  List<Notif> afternoonNotifs = [];
  final today = DateFormat('dd. MM. yyyy').format(DateTime.now());
  if (hour > 18 && (user.get('lastafternoonchunk') ?? '') != today) {
    afternoonNotifs = [
      ...unexcusedAbsences(oldStorage, newStorage),
      ...tasksToDo(oldStorage, newStorage),
    ];
    await user.put('lastafternoonchunk', today);
  }
  if (allDayNotifs.isNotEmpty || afternoonNotifs.isNotEmpty) {
    final localNotifs = FlutterLocalNotificationsPlugin();
    await localNotifs.initialize(const InitializationSettings(
      android: AndroidInitializationSettings("icon")
    ));
    for (final notif in allDayNotifs) {
      await localNotifs.show(0, notif.title, notif.body, const NotificationDetails(
        android: AndroidNotificationDetails("kleofasAllDay", "Kleofáš celodenní notifikace (nové známky, změny rozvrhu)")
      ));
    }
    for (final notif in allDayNotifs) {
      await localNotifs.show(0, notif.title, notif.body, const NotificationDetails(
        android: AndroidNotificationDetails("kleofasAfternoon", "Kleofáš odpolední notifikace (úkoly na zítra, neomluvené absence)")
      ));
    }
  }
  logInfo(['notifkace bgload end']);
}

List<Notif> newMarks (Storage oldStorage, Storage newStorage) {
  final newMarksRaw = newStorage['marks']?['Subjects'] ?? [];
  final oldMarksRaw = oldStorage['marks']?['Subjects'] ?? [];
  final subjects = mapListToMap(newMarksRaw.map((e) => e['Subject']).toList());
  final List<Map> allOldMarks = [for (Map subject in oldMarksRaw) ...subject['Marks']];
  final List<Map> allNewMarks = [for (Map subject in newMarksRaw) ...subject['Marks']];
  final oldMarksSet = allOldMarks.toSet();
  final newMarksSet = allNewMarks.toSet();
  final changedMarks = newMarksSet.difference(oldMarksSet);
  return changedMarks.map((dynamic mark) => (
    title: 'Nová známka z ${subjects[mark['SubjectId']]?['Abbrev'] ?? '?'}',
    body: '${mark['Caption']}: ${mark['MarkText']} (${mark['Weight'] == null ? mark['TypeNote'] : 'váha ${mark['Weight']}'})\nNový průměr z ${subjects[mark['SubjectId']]?['Abbrev'] ?? '?'}: ${subjects[mark['SubjectId']]?['AverageText'] ?? '?'}',
  )).toList();
}

List<Notif> timeTableChanges (Storage oldStorage, Storage newStorage) {
  final List oldDaysRaw = [...oldStorage["timetable"]?["Days"] ?? []];
  final List oldDays = oldDaysRaw.map((e) => e..['Atoms'] = e['Atoms'].map((f) => f..['Theme'] = '').toList()).toList();
  final List newDaysRaw = [...newStorage["timetable"]?["Days"] ?? []];
  final List newDays = newDaysRaw.map((e) => e..['Atoms'] = e['Atoms'].map((f) => f..['Theme'] = '').toList()).toList();
  // final List newDays = newDaysRaw.map((e) => e.map((key, value) {
  //   final List atoms = value['Atoms'] ?? [];
  //   return MapEntry(key, value..['Atoms'] = atoms.map((e) => e..['Theme'] = '').toList());
  // })).toList();
  if (oldDays.length != newDays.length) return [];
  List<Notif> notifsToShow_ = [];
  for (int i = 0; i < max(oldDays.length, newDays.length); i++) {
    final oldDay = oldDays[i];
    final newDay = newDays[i];
    if (oldDay != newDay) {
      notifsToShow_.add((
        title: 'změna rozvrhu ${newDay['DayOfWeek']}',
        body: '',
      ));
    }
  }
  return notifsToShow_;
}

List<Notif> unexcusedAbsences (Storage oldStorage, Storage newStorage) {
  final List absences = newStorage["absence"]?["Absences"] ?? [];
  List<Notif> notifsToShow_ = [];
  for (final Map absence in absences) {
    if (absence["Unsolved"] > 0 || absence["Missed"] > 0 || absence["Late"] > 0 || absence["Soon"] > 0) {
      notifsToShow_.add((
        title: 'neomluvená absence ${DateFormat('EEE d. M.').format(roundDateTime(DateTime.tryParse(absence["Date"] ?? "") ?? DateTime(1969)))}',
        body: '',
      ));
    }
  }
  return notifsToShow_;
}

List<Notif> tasksToDo (Storage oldStorage, Storage newStorage) {
  final List tasks = newStorage['tasks']?['Tasks'] ?? [];
  return tasks.where((task) => isEventInvolved(task, DateTime.now())).map((task) => (
    title: 'Úkol na zítra z ${task['subject']}',
    body: '${task['title']}\n${task['description']}',
  )).toList();
}

List<Notif> upcomingEvents (Storage oldStorage, Storage newStorage) {
  final List tasks = newStorage['events']?['Events'] ?? [];
  return tasks.where((task) => isEventInvolved(task, DateTime.now())).map((task) => (
    title: 'Událost zítra',
    body: '${task['Title']}\n${task['Description']}',
  )).toList();
}