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

const Map<String, String> eventNames = {
  'EventType.my': '/my',
  'EventType.all': '',
  'EventType.public': '/public',
};

class SimpleNotif {
  final String title;
  final String body;
  const SimpleNotif(this.title, [this.body = ""]);
}

dynamic getListDefault (List inputList, int idx, [dynamic default_]) {
  if (inputList.length <= idx) return default_;
  return inputList[idx];
}

DateTime roundDateTime (DateTime date) {
  if (date.hour > 12) {
    return DateTime(date.year, date.month, date.day + 1);
  }
  return date;
}

GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void globalShowDialog (Widget Function(BuildContext) builder) {
  final currentContext = navigatorKey.currentState?.overlay?.context;
  if (currentContext == null) return;
  showDialog(context: currentContext, builder: builder);
}

const Map<String, String> ids = {"08": "0.C", "0B": "0.J", "0C": "0.M", "05": "U21", "07": "1.J", "06": "1.M", "04": "2.C", "02": "2.J", "03": "2.M", "ZZ": "3.C", "00": "3.J", "01": "3.M", "ZW": "4.C", "ZX": "4.J", "ZY": "4.M", "ZT": "5.J", "ZS": "5.M", "ZR": "6.J", "ZQ": "6.M", "ZO": "7.J", "ZM": "7.M", "ZL": "8.J", "ZK": "8.M", "UUZFR": "Balák Ondřej", "UPZEK": "Beuzon Benoit", "UTZFE": "Frimlová Klára", "UZZAQ": "Haschková Pavla", "UOZEB": "Holíková Jolana", "UZZC3": "Holubová Ivana", "UTVCG": "Hradová Pecinová Zuzana", "UWZGC": "Chvosta Petr", "UKZD6": "Jahn Vítězslav", "UZZAS": "Jirošová Štěpánka", "UVZG4": "Kirschner Věra", "UZZC5": "Kocourková Blanka", "UWZGI": "Kocúrová Zuzana", "UTZFG": "Kolářová Magdaléna", "UWZG6": "Kubelková Natálie", "UOZE5": "Loula Karel", "UWZGB": "Lukáčová Denisa", "UWZGG": "Mádlová Zdenka", "UXZGL": "Matějka Jakub", "URZEY": "Matušík Michal", "UUZFW": "Mazná Michaela", "UWZG7": "Miškovský Jakub", "UQZEQ": "Nosková Alena", "UAPP8": "Nováková Renata", "UK8S1": "Ortinská Ludmila", "UZZ9N": "Pauchová Renata", "UZZC9": "Pavel Josef", "USZFA": "Pavlousek Pavel", "U9F2I": "Pěchová Světlana", "USZF8": "Petrová Eva", "UKZD5": "Petržílka František", "ULZDF": "Plese Conor", "UWZG8": "Procházka Marek", "UKZD3": "Prokopec Michal", "UUZFV": "Radvanová Sabina", "UTZFK": "Roček Daniel", "UZZBZ": "Růžičková Lucie", "UUZFY": "Růžičková Monika", "UZZCC": "Růžičková Václava", "UZZ9X": "Semeráková Vladimíra", "UTZFM": "Skálová Zuzana", "UKZD4": "Skoupilová Petra", "UZZCL": "Stárová Martina", "UXZGK": "Stockmann Alissia", "UKZD7": "Stříbrná Leona", "UWZGA": "Suldovská Klára", "UQZEU": "Šperl Jiří", "UQZET": "Štěchová Linda", "UDZUD": "Švarcová Dagmar", "USZF6": "Tůmová Jaroslava", "UTZFD": "Valášková Andrea", "UWZGE": "Vilímová Sheila", "UWZGD": "Vincena Petr", "UVZG3": "Wangerin Torben", "UWZG9": "Wilhelm Lukáš", "UUZFP": "Yaghobová Anna", "UUZFT": "Zajíc František", "USZFC": "Zítka Martin", "Y6": "AUL", "4E": "F", "F2": "Fit", "YL": "Fl", "0D": "Chl", "C7": "I1", "RI": "I2", "NW": "TMS", "YJ": "TSO", "30": "Tv", "YM": "U1", "0W": "U10", "GZ": "U11", "1K": "U12", "N7": "U13", "YG": "U14", "YI": "U15", "YN": "U2", "N6": "U22", "PU": "U23", "LG": "U24", "Y2": "U25", "YC": "U26", "YD": "U27", "D5": "U31", "OG": "U32", "YB": "U33", "YE": "U34", "Y7": "U35", "63": "U36", "Y9": "U37", "Y8": "U38", "2D": "U41", "PZ": "U42", "68": "U43", "YF": "U44", "YO": "Zas"};

final pb = PocketBase('https://pb.kleofas.eu'); 
Box<Map> storage = Hive.box<Map>('storage');
Box<String> user = Hive.box<String>('user');
Box<int> refresh = Hive.box<int>('refresh');
Box<Map> passwords = Hive.box<Map>('passwords');
Box<Map> log = Hive.box<Map>('log');
Box<Map> snacks = Hive.box<Map>('snacks');

Widget loadScrollSnacksWrapper (BuildContext context, {required Widget child, Axis scrollDirection = Axis.vertical, ScrollController? controller, bool scrollable = true}) => Stack(
  children: [
    if (scrollable) Positioned(child: SizedBox.expand(child: SingleChildScrollView(
      scrollDirection: scrollDirection,
      controller: controller,
      child: child,
    ))),
    if (!scrollable) Positioned(child: SizedBox.expand(child: child)),
    Positioned(bottom: 0, left: 0, width: MediaQuery.of(context).size.width, child: ValueListenableBuilder(
      valueListenable: snacks.listenable(),
      builder: (context, snacks_, _) => Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: snacks_.values.map((e) => Text(e['message'],
            textAlign: TextAlign.center,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.black,
              background: Paint()
                ..color = Color.fromARGB(e['a'], e['r'], e['g'], e['b'])
                ..strokeWidth = 20
                ..strokeJoin = StrokeJoin.round
                ..strokeCap = StrokeCap.round
                ..style = PaintingStyle.stroke
            ),
          )).toList(),
        ),
      )
    ),),
  ],
);

Future<void> pushSnack (String name, String message, [Color color = Colors.lightBlue]) async => snacks.put(name, {'message': message, 'a': color.alpha, 'r': color.red, 'g': color.green, 'b': color.blue});
Future<void> popSnack (String name) async => snacks.delete(name);
Future<void> popAllSnacks () async => snacks.clear();

dynamic jsonify (dynamic object) {
  if (object.toString().contains('{')) {
    return (object as Map).map((key, value) => MapEntry(jsonify(key), jsonify(value)));
  }
  if (object.toString().contains('[')) {
    return (object as List).map((element) => jsonify(element));
  }
  if (object.runtimeType == int || object.runtimeType == double) {
    return object.toString();
  }
  if (object.runtimeType == String) {
    return '"$object"';
  }
  return '<$object>';
}

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
  final hour = DateTime.now().hour;
  if (hour < (int.tryParse(user.get("notifstart") ?? "6") ?? 6) || hour > (int.tryParse(user.get("notifend") ?? "22") ?? 22)) return;
  final oldStorage = storage.toMap();
  logInfo(['notifkace bgload start']);
  await completeReload();
  final newStorage = storage.toMap();
  List<SimpleNotif> notifsToShow = [];

  // nová známka
  final newMarksRaw = newStorage['marks']?['Subjects'] ?? [];
  if (oldStorage["marks"] != null && newStorage["marks"] != null) {
    final subjects = mapListToMap(newMarksRaw.map((e) => e['Subject']).toList());
    final allOldMarks = [for (Map subject in newMarksRaw) ...subject['Marks']];
    final allNewMarks = [for (Map subject in newStorage["Marks"]?["Subjects"] ?? []) ...subject['Marks']];
    final changedMarks = allNewMarks.where((element) => allOldMarks.map((e) => e.toString()).contains(element.toString())).toList();
    // logInfo(['checkování známek', allOldMarks, allNewMarks]);
    logInfo(['změněné známky', changedMarks]);
    for (final mark in changedMarks) {
      logInfo(['notifikace nová známka detekována', mark]);
      notifsToShow.add(SimpleNotif(
        "Nová známka: ${subjects[mark['SubjectId']]?['Abbrev'] ?? '?'}",
        "${mark['Caption']}: ${mark['MarkText']} (${mark['Weight'] == null ? mark['TypeNote'] : 'váha ${mark['Weight']}'})"
      ));
    }
  }

  // změna rozvrhu
  final List oldDays = oldStorage["timetable"]?["Days"] ?? [];
  final List newDays = newStorage["timetable"]?["Days"] ?? [];
  if (oldDays.length == newDays.length) {
  for (int i = 0; i < max(oldDays.length, newDays.length); i++) {
    final oldDay = oldDays[i];
    final newDay = newDays[i];
    if (jsonEncode(oldDay).compareTo(jsonEncode(newDay)) != 0) {
      logInfo(['notifikace změna rozvrhu detekována', jsonEncode(oldDay), jsonEncode(newDay)]);
      notifsToShow.add(SimpleNotif(
        "změna rozvrhu ${newDay['DayOfWeek']}"
      ));
    }
  }
  }

  // absence
  final List absences = newStorage["absence"]?["Absences"] ?? [];
  for (final Map absence in absences) {
    if (absence["Unsolved"] > 0 || absence["Missed"] > 0 || absence["Late"] > 0 || absence["Soon"] > 0) {
      logInfo(['notifikace neomluvená absence detekována', absence, absences]);
      notifsToShow.add(SimpleNotif(
        "neomluvená absence ${DateFormat('EEE d. M.').format(roundDateTime(DateTime.tryParse(absence["Date"] ?? "") ?? DateTime(1969)))}"
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

void loadingSnack (Future<void> Function() func, [String message = 'loading', Color color = Colors.lightBlue]) async {
  // final currentContext = navigatorKey.currentState?.overlay?.context;
  // if (currentContext == null) return;
  // ScaffoldMessenger.of(currentContext).showSnackBar(const SnackBar(content: Text('loading'), duration: Duration(days: 1),),);
  String snackName = DateTime.now().toIso8601String();
  await pushSnack(snackName, message, color);
  try {
    await func();
  } catch (e, s) {
    print('Error $e: $s');
    globalShowDialog((BuildContext context) {
      return AlertDialog(
        title: const Text('Error'),
        content: Text(e.toString()),
      );
    });
    // final currentContext = navigatorKey.currentState?.overlay?.context;
    // if (currentContext == null) return;
    // showDialog(context: currentContext, builder: (BuildContext context) {
    //   return AlertDialog(
    //     title: const Text('Error'),
    //     content: Text(e.toString()),
    //   );
    // });
  } finally {
    await popSnack(snackName);
  }
  // final currentContext_ = navigatorKey.currentState?.overlay?.context;
  // if (currentContext_ == null) return;
  // // ignore: use_build_context_synchronously
  // ScaffoldMessenger.of(currentContext_).hideCurrentSnackBar();
}

Future<void> loginUser () async {
  if (DateTime.now().difference(DateTime.parse(user.get('lastbakalogin') ?? '1970-01-01')).inSeconds < 3600) return;
  Result token = await login(getPassword("bakalari", "url"), getPassword("bakalari", "username"), getPassword("bakalari", "password"));
  if (token.isFailure) {
    throw ErrorDescription(jsonDecode(token.failure)['error_description']);
  }
  await user.put('token', token.success);
  await user.put('lastbakalogin', DateTime.now().toString());
}

Future<void> loadEndpoint (String endpoint, [String? url, Map<String, dynamic>? payload]) async {
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
}

void loadEndpointSnack (String endpoint, [String? url, Map<String, dynamic>? payload]) {
  loadingSnack(() async {await loadEndpoint(endpoint, url, payload);});
}

String czDate (String? isoTime) {
  if (isoTime == null) {
    return 'idk';
  }
  return DateFormat('d. M. y HH:mm:ss').format(DateTime.tryParse(isoTime) ?? DateTime(69, 4, 20));
}

Map mapListToMap (Iterable list, {String id = 'Id'}) => {for (Map item in list) item[id]: item};

Future<void> loadTasks () async {
  final tasks = await pb.collection('tasks').getFullList(filter: user.get('streams')?.split(' ').map((e) => 'stream.id = "$e"').join(' || '));
  await Future.wait([
    storage.put('tasks', {'Tasks': tasks.map((e) => e.data).toList()}),
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
  if (!await loginPb()) return;
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
          loadingSnack(() async {
            await addTask(newTaskSubjectController.text, newTaskDateController.text, newTaskTitleController.text, newTaskDescController.text, context);
            navigator.pop();
          });
        }, child: const Text('Přidat')),
      ],
    );
  });
}

Future<bool> loginPb () async {
  if (DateTime.now().difference(DateTime.parse(user.get('lastpblogin') ?? '1970-01-01')).inSeconds < 1209600) return true;
  if (!hasPassword("kleofas", "username") || !hasPassword("kleofas", "password")) return false;
  final record = await pb.collection('users').authWithPassword(getPassword("kleofas", "username"), getPassword("kleofas", "password"));
  await user.put('kleolibrary', (record.record?.data['librarian'] ?? false) ? 'true' : '');
  await user.put('kleouserid', record.record?.id ?? '');
  await user.put('lastpblogin', DateTime.now().toString());
  return true;
}

Future<void> completeReload () async {
  await Future.wait([
    loginUser(),
    loginPb(),
  ]);
  await Future.wait([
    loadEndpoint('timetable', 'timetable/actual'),
    loadEndpoint('absence', 'absence/student'),
    loadEndpoint('marks'),
    loadEndpoint('events', 'events${eventNames[user.get('event_type') ?? "EventType.my"]}'),
    loadTasks(),
  ]);
}

void completeReloadSnack () {
  loadingSnack(() async {
    await completeReload();
  }, 'complete reload'.toUpperCase(), Colors.red);
}