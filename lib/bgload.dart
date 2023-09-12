import 'dart:convert';

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
      android: AndroidInitializationSettings("icon"),
      iOS: DarwinInitializationSettings(notificationCategories: [
        DarwinNotificationCategory('kleofasAllDay'),
        DarwinNotificationCategory('kleofasAfternoon'),
      ]),
    ));
    final rng = Random();
    for (final notif in allDayNotifs) {
      await localNotifs.show(rng.nextInt(1000), notif.title, notif.body, const NotificationDetails(
        android: AndroidNotificationDetails("kleofasAllDay", "Kleofáš celodenní notifikace (nové známky, změny rozvrhu)"),
        iOS: DarwinNotificationDetails(threadIdentifier: 'kleofasAllDay', categoryIdentifier: 'kleofasAllDay', subtitle: 'Kleofáš celodenní notifikace (nové známky, změny rozvrhu)'),
      ));
    }
    for (final notif in allDayNotifs) {
      await localNotifs.show(rng.nextInt(1000), notif.title, notif.body, const NotificationDetails(
        android: AndroidNotificationDetails("kleofasAfternoon", "Kleofáš odpolední notifikace (úkoly na zítra, neomluvené absence)"),
        iOS: DarwinNotificationDetails(threadIdentifier: 'kleofasAfternoon', categoryIdentifier: 'kleofasAfternoon', subtitle: 'Kleofáš odpolední notifikace (úkoly na zítra, neomluvené absence)'),
      ));
    }
  }
  logInfo(['notifkace bgload end']);
}

List<Notif> newMarks (Storage oldStorage, Storage newStorage) {
  final newMarksRaw = newStorage['marks']?['Subjects'] ?? [];
  final oldMarksRaw = oldStorage['marks']?['Subjects'] ?? [];
  final subjects = mapListToMapFunc(newMarksRaw, (e) => e['Subject']['Id']);
  final List<Map> allOldMarks = [for (Map subject in oldMarksRaw) ...subject['Marks']];
  final List<Map> allNewMarks = [for (Map subject in newMarksRaw) ...subject['Marks']];
  final allOldMarksMap = mapListToMap(allOldMarks);
  final allNewMarksMap = mapListToMap(allNewMarks);
  final oldMarksIdsSet = allOldMarksMap.keys.toSet();
  final newMarksIdsSet = allNewMarksMap.keys.toSet();
  final changedMarks = newMarksIdsSet.difference(oldMarksIdsSet);
  return changedMarks.map((dynamic markId) {
    final mark = allNewMarksMap[markId];
    return (
      title: 'Nová známka - ${subjects[mark['SubjectId']]?['Subject']?['Name']?.trim() ?? '?'}',
      body: '${mark['Caption']}: ${mark['MarkText']} (${mark['Weight'] == null ? mark['TypeNote'] : 'váha ${mark['Weight']}'})\n${subjects[mark['SubjectId']]?['Subject']?['Name']?.trim() ?? '?'} - nový průměr: ${subjects[mark['SubjectId']]?['AverageText'] ?? '?'}\nPopis: ${mark['Theme'] ?? ''}',
    );
  }).toList();
}

List<Notif> timeTableChanges (Storage oldStorage, Storage newStorage) {
  final List oldDays = oldStorage['timetable']?['Days'] ?? [];
  final List newDays = newStorage['timetable']?['Days'] ?? [];
  final maxLength = max(oldDays.length, newDays.length);
  final Map oldDaysMap = oldDays.asMap();
  final Map newDaysMap = newDays.asMap();
  List<Notif> notifsToShow_ = [];
  for (int i = 0; i < maxLength; i++) {
    final oldDay = oldDaysMap[i];
    final newDay = newDaysMap[i];
    final oldDayString = jsonEncode(oldDay).replaceAll('"Theme": null,', '').replaceAll(RegExp('"Theme": ".+?",'), '');
    final newDayString = jsonEncode(newDay).replaceAll('"Theme": null,', '').replaceAll(RegExp('"Theme": ".+?",'), '');
    if (oldDayString != newDayString) {
      notifsToShow_.add((
        title: 'změna rozvrhu ${czWeekDayNames[newDay['DayOfWeek']]}',
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