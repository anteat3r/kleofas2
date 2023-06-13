import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'bakalari.dart';
import 'package:result_type/result_type.dart';
import 'package:intl/intl.dart';
import 'package:pocketbase/pocketbase.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

const List<String> czWeekDayNames = ['Ne', 'Po', 'Út', 'St', 'Čt', 'Pá', 'So', 'Ne'];

class SimpleNotif {
  final String title;
  final String body;
  const SimpleNotif(this.title, [this.body = ""]);
}

dynamic getListDefault (List inputList, int idx, [dynamic default_]) {
  if (inputList.length <= idx) return default_;
  return inputList[idx];
}

Map<String, String> ids = {"08": "0.C", "0B": "0.J", "0C": "0.M", "05": "U21", "07": "1.J", "06": "1.M", "04": "2.C", "02": "2.J", "03": "2.M", "ZZ": "3.C", "00": "3.J", "01": "3.M", "ZW": "4.C", "ZX": "4.J", "ZY": "4.M", "ZT": "5.J", "ZS": "5.M", "ZR": "6.J", "ZQ": "6.M", "ZO": "7.J", "ZM": "7.M", "ZL": "8.J", "ZK": "8.M", "UUZFR": "Balák Ondřej", "UPZEK": "Beuzon Benoit", "UTZFE": "Frimlová Klára", "UZZAQ": "Haschková Pavla", "UOZEB": "Holíková Jolana", "UZZC3": "Holubová Ivana", "UTVCG": "Hradová Pecinová Zuzana", "UWZGC": "Chvosta Petr", "UKZD6": "Jahn Vítězslav", "UZZAS": "Jirošová Štěpánka", "UVZG4": "Kirschner Věra", "UZZC5": "Kocourková Blanka", "UWZGI": "Kocúrová Zuzana", "UTZFG": "Kolářová Magdaléna", "UWZG6": "Kubelková Natálie", "UOZE5": "Loula Karel", "UWZGB": "Lukáčová Denisa", "UWZGG": "Mádlová Zdenka", "UXZGL": "Matějka Jakub", "URZEY": "Matušík Michal", "UUZFW": "Mazná Michaela", "UWZG7": "Miškovský Jakub", "UQZEQ": "Nosková Alena", "UAPP8": "Nováková Renata", "UK8S1": "Ortinská Ludmila", "UZZ9N": "Pauchová Renata", "UZZC9": "Pavel Josef", "USZFA": "Pavlousek Pavel", "U9F2I": "Pěchová Světlana", "USZF8": "Petrová Eva", "UKZD5": "Petržílka František", "ULZDF": "Plese Conor", "UWZG8": "Procházka Marek", "UKZD3": "Prokopec Michal", "UUZFV": "Radvanová Sabina", "UTZFK": "Roček Daniel", "UZZBZ": "Růžičková Lucie", "UUZFY": "Růžičková Monika", "UZZCC": "Růžičková Václava", "UZZ9X": "Semeráková Vladimíra", "UTZFM": "Skálová Zuzana", "UKZD4": "Skoupilová Petra", "UZZCL": "Stárová Martina", "UXZGK": "Stockmann Alissia", "UKZD7": "Stříbrná Leona", "UWZGA": "Suldovská Klára", "UQZEU": "Šperl Jiří", "UQZET": "Štěchová Linda", "UDZUD": "Švarcová Dagmar", "USZF6": "Tůmová Jaroslava", "UTZFD": "Valášková Andrea", "UWZGE": "Vilímová Sheila", "UWZGD": "Vincena Petr", "UVZG3": "Wangerin Torben", "UWZG9": "Wilhelm Lukáš", "UUZFP": "Yaghobová Anna", "UUZFT": "Zajíc František", "USZFC": "Zítka Martin", "Y6": "AUL", "4E": "F", "F2": "Fit", "YL": "Fl", "0D": "Chl", "C7": "I1", "RI": "I2", "NW": "TMS", "YJ": "TSO", "30": "Tv", "YM": "U1", "0W": "U10", "GZ": "U11", "1K": "U12", "N7": "U13", "YG": "U14", "YI": "U15", "YN": "U2", "N6": "U22", "PU": "U23", "LG": "U24", "Y2": "U25", "YC": "U26", "YD": "U27", "D5": "U31", "OG": "U32", "YB": "U33", "YE": "U34", "Y7": "U35", "63": "U36", "Y9": "U37", "Y8": "U38", "2D": "U41", "PZ": "U42", "68": "U43", "YF": "U44", "YO": "Zas"};

final pb = PocketBase('http://kleofas.eu:4200'); 
Box<Map> storage = Hive.box<Map>('storage');
Box<String> user = Hive.box<String>('user');
Box<int> refresh = Hive.box<int>('refresh');
Box<Map> passwords = Hive.box<Map>('passwords');
Box<Map> log = Hive.box<Map>('log');

Future<void> logInfo (List data) async {
  await log.add({
    'level': 'info',
    'time': DateTime.now().millisecondsSinceEpoch,
    'data': data.map((e) => e.toString()).toList()
  });
}

Future<void> logError (List data) async {
  await log.add({
    'level': 'error',
    'time': DateTime.now().millisecondsSinceEpoch,
    'data': data.map((e) => e.toString()).toList()
  });
}

String getPassword (String key, String field, [dynamic def]) {
  String? res = passwords.get(key)?[field]?["value"]?.toString();
  if (res == null && def == null) {
    throw AssertionError("credential $field in $key not found");
  }
  return res ?? def;
}

bool hasPassword (String key, String field) {
  return passwords.get(key)?[field]?["value"] != null;
}

Future<void> bgLoad () async {
  logInfo(['notifkace bgload start']);
  final hour = DateTime.now().hour;
  if (hour < (int.tryParse(user.get("notifstart") ?? "6") ?? 6) || hour > (int.tryParse(user.get("notifend") ?? "22") ?? 22)) return;
  final oldStorage = storage.toMap();
  await completeReloadFuture();
  final newStorage = storage.toMap();
  List<SimpleNotif> notifsToShow = [];

  // nová známka
  final newMarksRaw = newStorage['marks']?['Subjects'] ?? [];
  if (oldStorage["marks"] != null && newStorage["marks"] != null) {
  final subjects = mapListToMap(newMarksRaw.map((e) => e['Subject']).toList());
  final allOldMarks = [for (Map subject in newMarksRaw) ...subject['Marks']];
  final allNewMarks = [for (Map subject in newStorage["Marks"]?["Subjects"] ?? []) ...subject['Marks']];
  if (allOldMarks != allNewMarks) {
    final changedMarks = allNewMarks.where((element) => !allOldMarks.contains(element)).toList();
    for (final mark in changedMarks) {
      logInfo(['notifikace nová známka detekována', allOldMarks, allNewMarks, mark]);
      notifsToShow.add(SimpleNotif(
        "Nová známka: ${subjects[mark['SubjectId']]?['Abbrev'] ?? '?'}",
        "${mark['Caption']}: ${mark['MarkText']} (${mark['Weight'] == null ? mark['TypeNote'] : 'váha ${mark['Weight']}'})"
      ));
    }
  }
  }

  // změna rozvrhu
  final List oldDays = oldStorage["timetable"]?["Days"] ?? [];
  final List newDays = newStorage["timetable"]?["Days"] ?? [];
  if (oldDays.length == newDays.length) {
  for (int i = 0; i < max(oldDays.length, newDays.length); i++) {
    final oldDay = oldDays[i];
    final newDay = newDays[i];
    if (oldDay != newDay) {
      logInfo(['notifikace změna rozvrhu detekována', oldDay, newDay, oldDays, newDays]);
      notifsToShow.add(SimpleNotif(
        "změna rozvrhu ${czWeekDayNames[i]}"
      ));
      // List<Map> dayChanges = [];
      // final List oldAtoms = oldDay["Atoms"];
      // final List newAtoms = newDay["Atoms"];
      // for (int j = 0; j < max(oldAtoms.length, newAtoms.length); j++) {
      //   final oldAtom = getListDefault(oldAtoms, j);
      //   final newAtom = getListDefault(newAtoms, j);
      //   if (oldAtom != newAtom) {
      //     dayChanges.add({
      //       "hour": newAtom
      //     });
      //   }
      // }
    }
  }
  }

  // absence
  final List absences = newStorage["absence"]?["Absences"] ?? [];
  for (final Map absence in absences) {
    if (absence["Unsolved"] > 0 || absence["Missed"] > 0 || absence["Late"] > 0 || absence["Soon"] > 0) {
      logInfo(['notifikace neomluvená absence detekována', absence, absences]);
      notifsToShow.add(SimpleNotif(
        "neomluvená absence ${DateFormat('EEE d. M.').format(DateTime.tryParse(absence["Date"] ?? "") ?? DateTime(1969))}"
      ));
    }
  }

  if (notifsToShow.isEmpty) return;
  final localNotifs = FlutterLocalNotificationsPlugin();
  await localNotifs.initialize(const InitializationSettings(
    android: AndroidInitializationSettings("icon")
  ));
  for (final notif in notifsToShow) {
    await localNotifs.show(0, notif.title, notif.body, const NotificationDetails(
      android: AndroidNotificationDetails("kleofas", "Kleofáš notifikace")
    ));
  }
  logInfo(['notifkace bgload start']);
}

void loadingDialog (BuildContext context, Function func) async {
  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('loading'), duration: Duration(days: 1),),);
  try {
    await func();
  } catch (e) {
    showDialog(context: context, builder: (BuildContext context) {
      return AlertDialog(
        title: const Text('Error'),
        content: Text(e.toString()),
      );
    });
  } finally {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
  }
}

void loginUser (BuildContext context) async {
  loadingDialog(context, () async {
    Result token = await login(getPassword("bakalari", "url"), getPassword("bakalari", "username"), getPassword("bakalari", "password"));
    if (token.isFailure) {
      throw ErrorDescription(jsonDecode(token.failure)['error_description']);
    }
    await user.put('token', token.success);
  });
}

Future<void> loginUserFuture () async {
  Result token = await login(getPassword("bakalari", "url"), getPassword("bakalari", "username"), getPassword("bakalari", "password"));
  if (token.isFailure) {
    throw ErrorDescription(jsonDecode(token.failure)['error_description']);
  }
  await user.put('token', token.success);
}

void loadEndpoint (BuildContext context, String endpoint, [String? url, Map<String, dynamic>? payload]) async {
  loadingDialog(context, () async {
    Result res = await query(getPassword("bakalari", "url"), user.get('token') ?? '', url ?? endpoint, payload);
    if (res.isFailure) {
      Result token = await login(getPassword("bakalari", "url"), getPassword("bakalari", "username"), getPassword("bakalari", "password"));
      if (token.isFailure) {
        throw AssertionError(res.failure);
      }
      await user.put('token', token.success);
      return;
    }
    if (res.isSuccess) {
      await Future.wait([
        storage.put(endpoint, res.success),
        refresh.put(endpoint, DateTime.now().millisecondsSinceEpoch)
      ]);
    } else {
      throw AssertionError('bruh');
    }
  });
}

String czDate (String? isoTime) {
  if (isoTime == null) {
    return 'idk';
  }
  return DateFormat('d. M. y HH:mm:ss').format(DateTime.tryParse(isoTime) ?? DateTime(69, 4, 20));
}

Map mapListToMap (Iterable list, {String id = 'Id'}) => {for (Map item in list) item[id]: item};

void loadTasks (BuildContext context) async {
  loadingDialog(context, () async {
    final tasks = await pb.collection('tasks').getFullList();
    await Future.wait([
      storage.put('tasks', {'Tasks': tasks.map((e) => e.data['json']..['KleoId'] = e.id).toList()}),
      refresh.put('tasks', DateTime.now().millisecondsSinceEpoch)
    ]);
  });
}

Future<void> loadTasksFuture (Box<Map> storage, Box<int> refresh) async {
  final tasks = await pb.collection('tasks').getFullList();
  await Future.wait([
    storage.put('tasks', {'Tasks': tasks.map((e) => e.data['json']..['KleoId'] = e.id).toList()}),
    refresh.put('tasks', DateTime.now().millisecondsSinceEpoch)
  ]);
}

Future<void> addTask (String subject, String date, String title, String description, BuildContext context) async {
  date = date.replaceAll(' ', '');
  if (date == 'zítra') {
    date = DateFormat('d.M.y').format(DateTime.now().add(const Duration(days: 1)));
  }
  else if (date == 'pozítří') {
    date = DateFormat('d.M.y').format(DateTime.now().add(const Duration(days: 1)));
  }
  else if (date == 'popozítří') {
    date = DateFormat('d.M.y').format(DateTime.now().add(const Duration(days: 1)));
  }
  else if (date.startsWith('za')) {
    date = DateFormat('d.M.y').format(DateTime.now().add(Duration(days: int.parse(date.substring(2)))));
  }
  String dateString = '';
  try {
    dateString = DateFormat('d.M.y').parse(date).toIso8601String();
  } on FormatException {
    try {
      dateString = DateFormat('d.M').parse(date).toIso8601String();
    } on FormatException {
      showDialog(context: context, builder: (BuildContext context) {
        return const AlertDialog(
          title: Text('Error'),
          content: Text('Date not valid'),
        );
      });
    }
  }
  final Map payload = {
    'Id': 'K:${DateTime.now().millisecondsSinceEpoch}',
    'Title': title,
    'Description': description,
    'EventType': {
      'Id': 'K:$subject',
      'Abbrev': subject,
      'Name': subject,
    },
    'Times': [
      {
        'WholeDay': true,
        'StartTime': dateString,
      }
    ],
    'Classes': [
      {
        'Id': 'ZY',
        'Abbrev': '4.M (celá)',
        'Name': 'osmileté matematické (celá třída)',
      },
    ],
    'ClassSets': [],
    'Teachers': [],
    'TeacherSets': [],
    'Rooms': [],
    'RoomSets': [],
    'Students': [],
    'Note': 'From Kleofáš v0.0.0',
    'DateChnged': DateTime.now().toIso8601String()
  };
  if (!await loginPbFuture()) return;
  await Future.wait([
    pb.collection('tasks').create(body: {'json': jsonEncode(payload)}),
    storage.put('tasks', (storage.get('tasks') ?? {'Tasks': []})..['Tasks'].add(payload))
  ]);
}

void newTaskDialog (BuildContext context, [DateTime? date]) async {
  final navigator = Navigator.of(context);
  final newTaskSubjectController = TextEditingController();
  final newTaskDateController = TextEditingController(text: date == null ? '' : DateFormat('d. M. y').format(date));
  final newTaskTitleController = TextEditingController();
  final newTaskDescController = TextEditingController();
  showDialog(context: context, builder: (BuildContext context) {
    double halfWidth = MediaQuery.of(context).size.width / 2;
    return AlertDialog(
      title: const Text('Přidat task'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.all(4),
            child: SizedBox(
              width: halfWidth,
              child: TextField(
                controller: newTaskSubjectController,
                decoration: const InputDecoration(
                  hintText: 'předmět',
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(4),
            child: Row(
              children: [
                SizedBox(
                  width: halfWidth - 30,
                  child: TextField(
                    controller: newTaskDateController,
                    decoration: const InputDecoration(
                      hintText: 'datum',
                    ),
                  ),
                ),
                SizedBox(
                  width: 30,
                  child: IconButton(
                    onPressed: () async {
                      DateTime? selectedDate = await showDatePicker(context: context, initialDate: DateTime.now(), firstDate: DateTime(1969, 4, 20), lastDate: DateTime(2069, 4, 20));
                      if (selectedDate == null) return;
                      newTaskDateController.text = DateFormat('d. M. y').format(selectedDate);
                    },
                    icon: const Icon(Icons.date_range_rounded)
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(4),
            child: SizedBox(
              width: halfWidth,
              child: TextField(
                controller: newTaskTitleController,
                decoration: const InputDecoration(
                  hintText: 'nadpis',
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(4),
            child: SizedBox(
              width: halfWidth,
              child: TextField(
                controller: newTaskDescController,
                maxLines: 5,
                decoration: const InputDecoration(
                  hintText: 'popis',
                ),
              ),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(onPressed: () {navigator.pop();}, child: const Text('Zrušit')),
        TextButton(onPressed: () {
          loadingDialog(context, () async {
            await addTask(newTaskSubjectController.text, newTaskDateController.text, newTaskTitleController.text, newTaskDescController.text, context);
            navigator.pop();
          });
        }, child: const Text('Přidat')),
      ],
    );
  });
}

Future<void> loadEndpointFuture (String userUrl, String token, Box<Map> storage, Box<int> refresh, String endpoint, [String? url, Map<String, dynamic>? payload]) async {
  Result res = await query(userUrl, token, url ?? endpoint, payload);
  if (res.isFailure) {
    Result token = await login(getPassword("bakalari", "url"), getPassword("bakalari", "username"), getPassword("bakalari", "password"));
    if (token.isFailure) {
      throw AssertionError(res.failure);
    }
    await user.put('token', token.success);
    return;
  }
  if (res.isSuccess) {
    await Future.wait([
      storage.put(endpoint, res.success),
      refresh.put(endpoint, DateTime.now().millisecondsSinceEpoch)
    ]);
  } else {
    throw AssertionError('bruh');
  }
}

Future<bool> loginPbFuture () async {
  if (!hasPassword("kleofas", "username") || !hasPassword("kleofas", "password")) return false;
  final record = await pb.collection('users').authWithPassword(getPassword("kleofas", "username"), getPassword("kleofas", "password"));
  await user.put('kleolibrary', (record.record?.data['librarian'] ?? false) ? 'true' : '');
  await user.put('kleouserid', record.record?.id ?? '');
  return true;
}

Future<void> completeReloadFuture () async {
  String url = getPassword("bakalari", "url");
  String token = user.get('token') ?? '';
  print('sasa');
  // String zarizeni = user.get('zarizeni') ?? '3753';
  await Future.wait([
    loginUserFuture(),
    loginPbFuture(),
  ]);
  await Future.wait([
    loadEndpointFuture(url, token, storage, refresh, 'timetable', 'timetable/actual'),
    loadEndpointFuture(url, token, storage, refresh, 'absence', 'absence/student'),
    loadEndpointFuture(url, token, storage, refresh, 'marks'),
    loadEndpointFuture(url, token, storage, refresh, 'events', 'events/${user.get('event_type')?.split(".")[1] ?? "my"}'),
    loadTasksFuture(storage, refresh),
    // loadMenuFuture(zarizeni, storage, refresh),
  ]);
}

void completeReload (BuildContext context) {
  loadingDialog(context, () async {
    await completeReloadFuture();
  });
}