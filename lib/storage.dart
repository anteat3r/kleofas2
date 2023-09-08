import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
// import 'package:kleofas2/bgload.dart';
import 'bakalari.dart';
import 'package:result_type/result_type.dart';
import 'package:intl/intl.dart';
import 'package:pocketbase/pocketbase.dart';
import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;
import 'dart:io';
import 'package:mobile_scanner/mobile_scanner.dart';
// import 'package:flutter_markdown/flutter_markdown.dart' as md;

// UTILS

const List<String> czWeekDayNames = ['Ne', 'Po', 'Út', 'St', 'Čt', 'Pá', 'So', 'Ne'];

const Map<String, String> eventNames = {
  'EventType.my': '/my',
  'EventType.all': '',
  'EventType.public': '/public',
};

typedef Id = ({String abbrev, String name});

// T? getListDefault <T>(List<T> inputList, int idx, [T? default_]) {
//   if (inputList.length <= idx) return default_;
//   return inputList[idx];
// }

DateTime roundDateTime (DateTime date) {
  if (date.hour > 12) {
    return DateTime(date.year, date.month, date.day + 1);
  }
  return date;
}

GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

/// builder is passed directly into showDialog's builder
void globalShowDialog (Widget Function(BuildContext) builder) {
  final currentContext = navigatorKey.currentState?.overlay?.context;
  if (currentContext == null) return;
  showDialog(context: currentContext, builder: builder);
}

void globalShowWarning (String title, String body) {
  globalShowDialog((context) => AlertDialog(
    title: Text(title),
    content: Text(body),
    actions: [OutlinedButton(onPressed: () {Navigator.pop(context);}, child: const Text('Close'))],
  ));
}

dynamic jsonify (dynamic object) {
  if (object.toString().startsWith('{')) {
    return (object as Map).map((key, value) => MapEntry(jsonify(key), jsonify(value)));
  }
  if (object.toString().startsWith('[')) {
    return (object as List).map((element) => jsonify(element)).toList();
  }
  if (object.toString().startsWith('(')) {
    return (object as Iterable).map((element) => jsonify(element)).toList();
  }
  if (object.runtimeType == int || object.runtimeType == double || object.runtimeType == bool) {
    return object.toString();
  }
  if (object.runtimeType == String) {
    return '"$object"';
  }
  return '<$object>';
}

extension ReplaceMap on String {
  String replaceMap (Map<Pattern, String> replacement) {
    String output = this;
    replacement.forEach((key, value) {
      output = output.replaceAll(key, value);
    });
    return output;
  }
  String replaceAppendAll (Pattern from, String replace) => replaceAll(from, '$from$replace');
  String replaceAppendMap (Map<Pattern, String> replacement) => replaceMap(replacement.map((key, value) => MapEntry(key, '$key$value')));
}

extension EnumerateList on List<Widget> {
  List<(int, Widget)> enumerate () => List.generate(length, (i) => (i, this[i]));
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

String czDate (String? isoTime) {
  if (isoTime == null) {
    return 'idk';
  }
  return DateFormat('d. M. y HH:mm:ss').format(DateTime.tryParse(isoTime) ?? DateTime(69, 4, 20));
}

Map mapListToMap (Iterable list, {String id = 'Id'}) => {for (Map item in list) item[id]: item};
Map mapListToMapFunc (Iterable list, dynamic Function(Map) fn) => {for (Map item in list) fn(item): item};

String removeQuotes (String old) {
  if (old.startsWith('"')) {
    old = old.substring(1);
  }
  if (old.endsWith('"')) {
    old = old.substring(0, old.length-1);
  }
  return old;
}

Future<String?> showQrDialog (BuildContext context, String title) {
  if (Platform.isLinux || Platform.isWindows) return Future.value(null);
  return showDialog<String>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(title),
      actions: [
        OutlinedButton(onPressed: () {Navigator.pop(context);}, child: const Text('Cancel'))
      ],
      content: MobileScanner(
        onDetect: (barcodes) {
          Navigator.pop(context, barcodes.barcodes.first.rawValue);
        },
      ),
    ),
  );
}

Future<void> initHive () async {
  await Hive.initFlutter();
  await Hive.openBox<String>('user');
  await Hive.openBox<Map>('storage');
  await Hive.openBox<int>('refresh');
  await Hive.openBox<Map>('passwords');
  await Hive.openBox<Map>('snacks');
  await Hive.openBox<Map>('ids');
  await Hive.openBox<Map>('log');
}

// STORAGE

// const Map<String, String> ids = {"08": "0.C", "0B": "0.J", "0C": "0.M", "05": "U21", "07": "1.J", "06": "1.M", "04": "2.C", "02": "2.J", "03": "2.M", "ZZ": "3.C", "00": "3.J", "01": "3.M", "ZW": "4.C", "ZX": "4.J", "ZY": "4.M", "ZT": "5.J", "ZS": "5.M", "ZR": "6.J", "ZQ": "6.M", "ZO": "7.J", "ZM": "7.M", "ZL": "8.J", "ZK": "8.M", "UUZFR": "Balák Ondřej", "UPZEK": "Beuzon Benoit", "UTZFE": "Frimlová Klára", "UZZAQ": "Haschková Pavla", "UOZEB": "Holíková Jolana", "UZZC3": "Holubová Ivana", "UTVCG": "Hradová Pecinová Zuzana", "UWZGC": "Chvosta Petr", "UKZD6": "Jahn Vítězslav", "UZZAS": "Jirošová Štěpánka", "UVZG4": "Kirschner Věra", "UZZC5": "Kocourková Blanka", "UWZGI": "Kocúrová Zuzana", "UTZFG": "Kolářová Magdaléna", "UWZG6": "Kubelková Natálie", "UOZE5": "Loula Karel", "UWZGB": "Lukáčová Denisa", "UWZGG": "Mádlová Zdenka", "UXZGL": "Matějka Jakub", "URZEY": "Matušík Michal", "UUZFW": "Mazná Michaela", "UWZG7": "Miškovský Jakub", "UQZEQ": "Nosková Alena", "UAPP8": "Nováková Renata", "UK8S1": "Ortinská Ludmila", "UZZ9N": "Pauchová Renata", "UZZC9": "Pavel Josef", "USZFA": "Pavlousek Pavel", "U9F2I": "Pěchová Světlana", "USZF8": "Petrová Eva", "UKZD5": "Petržílka František", "ULZDF": "Plese Conor", "UWZG8": "Procházka Marek", "UKZD3": "Prokopec Michal", "UUZFV": "Radvanová Sabina", "UTZFK": "Roček Daniel", "UZZBZ": "Růžičková Lucie", "UUZFY": "Růžičková Monika", "UZZCC": "Růžičková Václava", "UZZ9X": "Semeráková Vladimíra", "UTZFM": "Skálová Zuzana", "UKZD4": "Skoupilová Petra", "UZZCL": "Stárová Martina", "UXZGK": "Stockmann Alissia", "UKZD7": "Stříbrná Leona", "UWZGA": "Suldovská Klára", "UQZEU": "Šperl Jiří", "UQZET": "Štěchová Linda", "UDZUD": "Švarcová Dagmar", "USZF6": "Tůmová Jaroslava", "UTZFD": "Valášková Andrea", "UWZGE": "Vilímová Sheila", "UWZGD": "Vincena Petr", "UVZG3": "Wangerin Torben", "UWZG9": "Wilhelm Lukáš", "UUZFP": "Yaghobová Anna", "UUZFT": "Zajíc František", "USZFC": "Zítka Martin", "Y6": "AUL", "4E": "F", "F2": "Fit", "YL": "Fl", "0D": "Chl", "C7": "I1", "RI": "I2", "NW": "TMS", "YJ": "TSO", "30": "Tv", "YM": "U1", "0W": "U10", "GZ": "U11", "1K": "U12", "N7": "U13", "YG": "U14", "YI": "U15", "YN": "U2", "N6": "U22", "PU": "U23", "LG": "U24", "Y2": "U25", "YC": "U26", "YD": "U27", "D5": "U31", "OG": "U32", "YB": "U33", "YE": "U34", "Y7": "U35", "63": "U36", "Y9": "U37", "Y8": "U38", "2D": "U41", "PZ": "U42", "68": "U43", "YF": "U44", "YO": "Zas"};

final pb = PocketBase('https://pb.kleofas.eu'); 
Box<Map> storage = Hive.box<Map>('storage');
Box<String> user = Hive.box<String>('user');
Box<int> refresh = Hive.box<int>('refresh');
Box<Map> passwords = Hive.box<Map>('passwords');
Box<Map> log = Hive.box<Map>('log');
Box<Map> snacks = Hive.box<Map>('snacks');
Box<Map> ids = Hive.box<Map>('ids');

Future<void> pushSnack (String name, String message, [Color color = Colors.lightBlue]) async => snacks.put(name, {'message': message, 'a': color.alpha, 'r': color.red, 'g': color.green, 'b': color.blue});
Future<void> popSnack (String name) async => snacks.delete(name);
Future<void> popAllSnacks () async => snacks.clear();

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
          children: snacks_.values.map((snack) => Padding(
            padding: const EdgeInsets.only(bottom: 16.0),
            child: Text(snack['message'],
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                  background: Paint()
                    ..color = Color.fromARGB(snack['a'], snack['r'], snack['g'], snack['b'])
                    ..strokeWidth = 20
                    ..strokeJoin = StrokeJoin.round
                    ..strokeCap = StrokeCap.round
                    ..style = PaintingStyle.stroke
                ),
            ),
          )).toList(),
        ),
      ))
    ),
  ],
);

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

Id getId (String? id, [Id defaultId = (abbrev: '?', name: '?')]) {
  if (id == null) return defaultId;
  Map? loadedId = ids.get(id);
  if (loadedId == null) return defaultId;
  return (abbrev: loadedId['abbrev'] ?? defaultId.abbrev, name: loadedId['name'] ?? defaultId.name);
}

Future<void> setId (String id, String abbrev, String name) => ids.put(id, {'abbrev': abbrev, 'name': name});

// Future<void> setIds (List<String> id, List<Id> idBody) => ids.putAll({for () id: {'abbrev': idBody.abbrev, 'name': idBody.name}});

void loadingSnack (Future<void> Function() func, [String message = 'loading', Color color = Colors.lightBlue]) async {
  String snackName = DateTime.now().toIso8601String();
  await pushSnack(snackName, message, color);
  try {
    await func();
  } catch (e, s) {
    if (kDebugMode) {
      print('Error $e: $s');
    }
    globalShowDialog((BuildContext context) {
      return AlertDialog(
        title: const Text('Error'),
        content: Text(e.toString()),
      );
    });
  } finally {
    await popSnack(snackName);
  }
}

// DATA FETCHING

Future<void> loginUser () async {
  Result token = await login(getPassword("bakalari", "url"), getPassword("bakalari", "username"), getPassword("bakalari", "password"));
  if (token.isFailure) {
    throw ErrorDescription(jsonDecode(token.failure)['error_description']);
  }
  await user.put('token', token.success);
}

Future<bool> loginPb () async {
  if (pb.authStore.isValid) return true;
  if (!hasPassword("kleofas", "username") || !hasPassword("kleofas", "password")) return false;
  final record = await pb.collection('users').authWithPassword(getPassword("kleofas", "username"), getPassword("kleofas", "password"));
  await user.put('kleouserid', record.record?.id ?? '');
  return true;
}

Future<void> loadEndpoint (String endpoint, [String? url, Map<String, dynamic>? payload, bool secondAttempt = false]) async {
  Result res = await query(getPassword("bakalari", "url"), user.get('token') ?? '', url ?? endpoint, payload);
  if (res.isFailure) {
    if (secondAttempt) throw AssertionError(res.failure);
    await loginUser();
    loadEndpoint(endpoint, url, payload, true);
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

Future<void> loadTasks () async {
  final tasks = await pb.collection('tasks').getFullList(
    expand: 'author,stream',
    headers: {'streams': user.get('streams') ?? ''},
    filter: 
      (user.get('streams')?.isEmpty ?? true)
      ? 'false'
      : (user.get('streams') ?? "").split(' ').map((e) => 'stream = "$e"').join(' || '),
  );
  await Future.wait([
    storage.put('tasks', {'Tasks': tasks.map((e) => e.data..['id'] = e.id..['expand'] = jsonify(e.expand.map((key, value) => MapEntry(key/*.replaceAll('"', '')*/, value.map((e2) => e2.data))))).toList()}),
    refresh.put('tasks', DateTime.now().millisecondsSinceEpoch)
  ]);
  final List loadedTasks = storage.get('tasks')?['Tasks'] ?? [];
  for (Map task in loadedTasks) {
    setId(task['id'], task['title'], task['title']);
    setId(task['author'], task['expand']['"author"'][0]['"username"'].replaceAll('"', ''), task['expand']['"author"'][0]['"username"'].replaceAll('"', ''));
    setId(task['stream'], task['expand']['"stream"'][0]['"title"'].replaceAll('"', ''), task['expand']['"stream"'][0]['"title"'].replaceAll('"', ''));
  }
}

Future<void> loadEvents ([String? url]) async {
  await loadEndpoint('events', url ?? 'events/${user.get('event_type')?.split(".")[1] ?? "my"}');
  final List events = storage.get('events')?['Events'] ?? [];
  for (Map event in events) {
    setId(event['Id'], event['Title'], event['Title']);
    setId(event['EventType']['Id'], event['EventType']['Abbrev'], event['EventType']['Name']);
    for (Map element in event['Classes']) { setId(element['Id'], element['Abbrev'], element['Name']); }
    for (Map element in event['Teachers']) { setId(element['Id'], element['Abbrev'], element['Name']); }
    for (Map element in event['Rooms']) { setId(element['Id'], element['Abbrev'], element['Name']); }
    for (Map element in event['Students']) { setId(element['Id'], element['Abbrev'], element['Name']); }
  }
}

Future<void> loadMarks () async {
  await loadEndpoint('marks');
  final List subjects = storage.get('marks')?['Subjects'] ?? [];
  for (Map subject in subjects) {
    setId(subject['Subject']['Id'], subject['Subject']['Abbrev'], subject['Subject']['Name']);
    for (Map mark in subject['Marks']) {setId(mark['Id'], mark['Caption'], '${mark['Caption']} (${mark['MarkText']})');}
  }
}

Future<void> loadTimeTable ([DateTime? date]) async {
  final now = DateTime.now();
  if (now.weekday == DateTime.saturday || now.weekday == DateTime.sunday) {
    date = now.add(const Duration(days: 2));
  }
  // final oldStorage = storage.toMap();
  await loadEndpoint('timetable', 'timetable/actual', date == null ? null : {'date': DateFormat('yyyy-MM-dd').format(date)});
  for (Map element in storage.get('timetable')?['Classes'] ?? []) { setId(element['Id'], element['Abbrev'], element['Name']); }
  for (Map element in storage.get('timetable')?['Groups'] ?? []) { setId(element['Id'], element['Abbrev'], element['Name']); }
  for (Map element in storage.get('timetable')?['Subjects'] ?? []) { setId(element['Id'], element['Abbrev'], element['Name']); }
  for (Map element in storage.get('timetable')?['Teachers'] ?? []) { setId(element['Id'], element['Abbrev'], element['Name']); }
  for (Map element in storage.get('timetable')?['Rooms'] ?? []) { setId(element['Id'], element['Abbrev'], element['Name']); }
  for (Map element in storage.get('timetable')?['Students'] ?? []) { setId(element['Id'], element['Abbrev'], element['Name']); }
  // print(timeTableChanges(oldStorage, storage.toMap()));
}

Future<void> loadAbsence () => loadEndpoint('absence', 'absence/student');

// LOADING HELPERS

void loadEndpointSnack (String endpoint, {String? url, Map<String, dynamic>? payload, String message = '', Color color = Colors.lightBlue}) {
  loadingSnack(() async {await loadEndpoint(endpoint, url, payload);}, message, color);
}

Future<void> completeReload () async {
  await Future.wait([
    loginUser(),
    loginPb(),
  ]);
  await Future.wait([
    loadTimeTable(),
    loadAbsence(),
    loadMarks(),
    loadEvents(),
    loadTasks(),
  ]);
}

void completeReloadSnack () {
  loadingSnack(() async {
    await completeReload();
  }, 'complete loading');
}

// TASK UTILS

Map<String, List<Map>> eventListToDateMap (List<Map> events) {
  Map<String, List<Map>> output = {};
  for (final event in events) {
    final List times =
      event.containsKey('time')
      ? [DateTime.parse(event['time']).toIso8601String()]
      : event['Times'].map((e) => e['StartTime'].toString()).toList();
    for (final time in times) {
      final String date = time.split('T')[0];
      if (output.containsKey(date)) {
        output[date]?.add({...event});
      } else {
        output[date] = [{...event}];
      }
    }
  }
  return output;
}

bool isEventInvolved (Map event, dynamic date) {
  String stringDate = date.toString();
  if (date.runtimeType == DateTime) {
    stringDate = date.toIso8601String().split('T').first;
  }
  stringDate = stringDate.split('T').first;
  // print('$date -> "$stringDate"');
  if (event.containsKey('time')) {
    return event['time'].toString().contains(stringDate);
  }
  return event['Times'].map((time) => time['StartTime'].split('T')[0]).contains(stringDate);
}

class TaskDialog extends StatefulWidget {
  final Map? task;
  final DateTime? newTime;
  // final void Function(void Function()) setState;

  const TaskDialog({super.key, this.task, /*required this.setState,*/ this.newTime});

  @override
  State<TaskDialog> createState() => _TaskDialogState();
}

class _TaskDialogState extends State<TaskDialog> {
  bool admin = false;
  bool editing = false;
  List<PlatformFile> addedFiles = [];
  List<String> removedFiles = [];
  String? stream;
  String streamName = '';
  Map<String, dynamic> adminStreamsMap = {};
  DateTime time = DateTime(2069);
  final subjectController = TextEditingController();
  final titleController = TextEditingController();
  final descriptionController = TextEditingController();

  @override
  void initState() {
    super.initState();
    editing = !(widget.task?.containsKey('author') ?? false);
    stream = widget.task?['stream'];
    streamName = widget.task?['expand']?['"stream"'][0]['"title"'] ?? '';
    streamName = removeQuotes(streamName);
    if (widget.task != null && (user.get('adminstreams')?.split(' ').contains(stream) ?? false)) {
      admin = true;
    }
    if (editing) {
      adminStreamsMap = jsonDecode(user.get('adminstreamsnames') ?? '{}');
      stream ??= adminStreamsMap.keys.first;
    }
    time = widget.newTime ?? DateTime.tryParse(widget.task?['time']?.toString() ?? '') ?? DateTime.now();
    subjectController.text = widget.task?['subject'] ?? '';
    titleController.text = widget.task?['title'] ?? '';
    descriptionController.text = widget.task?['description'] ?? '';
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: widget.task == null ? const Text('New Task') : Text(widget.task!['title']),
      content: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!editing) RichText(text: TextSpan(
              children: [
                const TextSpan(text: 'Stream: ', style: TextStyle(fontWeight: FontWeight.bold)),
                TextSpan(text: streamName),
                // const TextSpan(text: '       '),
                // TextSpan(text: customIcons['streamicon:${widget.task?['stream']}'].toString()),
              ]
            )),
            if (editing) Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: DropdownButton<String>(
                value: stream,
                onChanged: (value) {
                  if (value == null) return;
                  setState(() {
                    stream = value;
                  });
                },
                items: adminStreamsMap.keys.map((e) => DropdownMenuItem(
                  value: e,
                  child: Text(adminStreamsMap[e] ?? '?'),
                )).toList(),
              ),
            ),
            if (widget.task?['author'] != null) RichText(text: TextSpan(
              children: [
                const TextSpan(text: 'Author: ', style: TextStyle(fontWeight: FontWeight.bold)),
                TextSpan(text: removeQuotes(widget.task!['expand']['"author"'][0]['"username"']))
              ]
            )),
            if (!editing && widget.task?['time'] != null) RichText(text: TextSpan(
              children: [
                const TextSpan(text: 'Time: ', style: TextStyle(fontWeight: FontWeight.bold)),
                TextSpan(text: DateFormat('d. M. y').format(time))
              ]
            )),
            if (editing) OutlinedButton(
              onPressed: () async {
                final newTime = await showDatePicker(
                  context: context,
                  initialDate: time,
                  firstDate: DateTime(1969),
                  lastDate: DateTime(2069)
                );
                if (newTime == null) return;
                setState(() {
                  time = newTime;
                },);
              },
              child: Text(DateFormat('d. M. y').format(time)),
            ),
            if (!editing && widget.task?['subject'] != null) RichText(text: TextSpan(
              children: [
                const TextSpan(text: 'Subject: ', style: TextStyle(fontWeight: FontWeight.bold)),
                TextSpan(text: widget.task!['subject'])
              ]
            )),
            if (editing) TextField(
              controller: subjectController,
              decoration: const InputDecoration(labelText: 'Subject'),
            ),
            if (!editing && widget.task?['title'] != null) RichText(text: TextSpan(
              children: [
                const TextSpan(text: 'Title: ', style: TextStyle(fontWeight: FontWeight.bold)),
                TextSpan(text: widget.task!['title'])
              ]
            )),
            if (editing) TextField(
              controller: titleController,
              decoration: const InputDecoration(labelText: 'Title'),
            ),
            if (editing) const SizedBox(width: 10, height: 10,),
            RichText(text: const TextSpan(text: 'Files: ', style: TextStyle(fontWeight: FontWeight.bold)),),
            ...widget.task?['files'].map((dynamic file) => Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                children: [
                  RichText(text: TextSpan(
                    style: const TextStyle(color: Colors.lightBlue),
                    text: file,
                    recognizer: TapAndPanGestureRecognizer()..onTapDown = (details) {
                      launchUrl(Uri.parse('${pb.baseUrl}/api/files/tasks/${widget.task?['id']}/$file'), mode: LaunchMode.externalApplication);
                    }
                  )),
                  if (editing) IconButton(
                    onPressed: () {
                      removedFiles.add(file);
                      setState(() {
                        widget.task?['files'].remove(file);
                      },);
                    },
                    icon: const Icon(Icons.remove_circle_rounded)
                  ),
                ],
              ),
            )).toList() ?? [],
            if (editing) Row(
              children: [
                RichText(text: const TextSpan(text: 'Added Files: ', style: TextStyle(fontWeight: FontWeight.bold), ),),
                IconButton(
                  onPressed: () async {
                    final files = await FilePicker.platform.pickFiles();
                    if (files == null) return;
                    setState(() {
                      addedFiles.addAll(files.files);
                    },);
                  },
                  icon: const Icon(Icons.add)
                ),
              ],
            ),
            if (editing) ...addedFiles.map((PlatformFile file) => Row(
              children: [
                Flexible(
                  child: RichText(text: TextSpan(
                    style: const TextStyle(color: Colors.green),
                    text: file.name,
                  )),
                ),
                Flexible(
                  child: IconButton(
                    onPressed: () {
                      setState(() {
                        addedFiles.remove(file);
                      },);
                    },
                    icon: const Icon(Icons.remove_circle_rounded)
                  ),
                ),
              ],
            )).toList(),
            if (!editing) Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                RichText(text: const TextSpan(text: 'Description: \n', style: TextStyle(fontWeight: FontWeight.bold))),
                RichText(text: TextSpan(text: widget.task!['description'],)),
              ]
            ),
            // if (!editing) RichText(text: const TextSpan(text: 'Description:', style: TextStyle(fontWeight: FontWeight.bold))),
            // if (!editing) Expanded(child: md.MarkdownBody(data: widget.task!['description'], shrinkWrap: false, fitContent: true,)),
            if (editing) TextField(
              controller: descriptionController,
              maxLines: null,
              decoration: const InputDecoration(labelText: 'Description'),
            ),
          ],
        ),
      ),
      actions: [
        if (admin && !editing) OutlinedButton(
          onPressed: () {
            setState(() {
              editing = true;
            });
          },
          child: const Text('Edit'),
        ),
        if (editing && widget.task?['author'] == null) OutlinedButton(
          onPressed: () {
            loadingSnack(() async {
              final navigatorState = Navigator.of(context);
              await loginPb();
              await pb.collection('tasks').create(body: {
                'stream': stream,
                'author': pb.authStore.model.id,
                'time': time.toIso8601String(),
                'subject': subjectController.text,
                'title': titleController.text,
                'description': descriptionController.text,
              }, files: await Future.wait(addedFiles.map((e) async => http.MultipartFile.fromBytes(
                'files', await File(e.path ?? '').readAsBytes(), filename: e.name
              )).toList()));
              await loadTasks();
              navigatorState.pop();
              // setState(() {},);
            }, 'creating');
          },
          child: const Text('Create'),
        ),
        if (editing && widget.task?['author'] != null) OutlinedButton(
          onPressed: () {
            loadingSnack(() async {
              final navigatorState = Navigator.of(context);
              await loginPb();
              await pb.collection('tasks').update(widget.task!['id'], body: {
                'stream': stream,
                'author': pb.authStore.model.id,
                'time': time.toIso8601String(),
                'subject': subjectController.text,
                'title': titleController.text,
                'description': descriptionController.text,
              }, files: await Future.wait(addedFiles.map((e) async => http.MultipartFile.fromBytes(
                'files', await File(e.path ?? '').readAsBytes(), filename: e.name
              )).toList()));
              if (removedFiles.isNotEmpty) {
                await pb.collection('tasks').update(widget.task?['id'], body: {
                  'files-': removedFiles,
                });
              }
              await loadTasks();
              navigatorState.pop();
              // setState(() {},);
            }, 'submitting');
          },
          child: const Text('Submit'),
        ),
        OutlinedButton(
          onPressed: () {
            Navigator.pop(context);
          },
          child: const Text('Close'),
        ),
      ],
    );
  }
}

// void showTaskDialog (BuildContext context, void Function(void Function()) setState, {Map? task, DateTime? newTime}) {
//   if (task == null && (user.get('adminstreams')?.split(' ').isEmpty ?? true)) {
//     showDialog(context: context, builder: (context) => AlertDialog(
//       title: const Text('žádný admin stream'),
//       content: const Text('nemáš žádný stream uložený jako admin'),
//       actions: [
//         OutlinedButton(onPressed: () {Navigator.pop(context);}, child: const Text('Zavřít')),
//       ],
//     ));
//     return;
//   }
//   showDialog(context: context, builder: (context) {
//     bool admin = false;
//     bool editing = !(task?.containsKey('author') ?? false);
//     List<PlatformFile> addedFiles = [];
//     List<String> removedFiles = [];
//     return StatefulBuilder(
//       builder: (context, dialogSetState) {
//         String? stream = task?['stream'];
//         String streamName = task?['expand']?['"stream"'][0]['"title"'] ?? '';
//         streamName = removeQuotes(streamName);
//         Map<String, dynamic> adminStreamsMap = {};
//         if (task != null && (user.get('adminstreams')?.split(' ').contains(stream) ?? false)) {
//           admin = true;
//         }
//         if (editing) {
//           adminStreamsMap = jsonDecode(user.get('adminstreamsnames') ?? '{}');
//           stream ??= adminStreamsMap.keys.first;
//         }
//         DateTime time = newTime ?? DateTime.tryParse(task?['time']?.toString() ?? '') ?? DateTime.now();
//         final subjectController = TextEditingController(text: task?['subject'] ?? '');
//         final titleController = TextEditingController(text: task?['title'] ?? '');
//         final descriptionController = TextEditingController(text: task?['description'] ?? '');
//         return AlertDialog(
//           title: task == null ? const Text('New Task') : Text(task['title']),
//           content: SingleChildScrollView(
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 if (!editing) RichText(text: TextSpan(
//                   children: [
//                     const TextSpan(text: 'Stream: ', style: TextStyle(fontWeight: FontWeight.bold)),
//                     TextSpan(text: streamName)
//                   ]
//                 )),
//                 if (editing) DropdownButton<String>(
//                   value: stream,
//                   onChanged: (value) {
//                     print(stream);
//                     print(adminStreamsMap);
//                     if (value == null) return;
//                     dialogSetState(() {
//                       stream = value;
//                     });
//                   },
//                   items: adminStreamsMap.keys.map((e) => DropdownMenuItem(
//                     value: e,
//                     child: Text(adminStreamsMap[e] ?? '?'),
//                   )).toList(),
//                 ),
//                 if (task?['author'] != null) RichText(text: TextSpan(
//                   children: [
//                     const TextSpan(text: 'Author: ', style: TextStyle(fontWeight: FontWeight.bold)),
//                     TextSpan(text: removeQuotes(task!['expand']['"author"'][0]['"username"']))
//                   ]
//                 )),
//                 if (!editing && task?['time'] != null) RichText(text: TextSpan(
//                   children: [
//                     const TextSpan(text: 'Time: ', style: TextStyle(fontWeight: FontWeight.bold)),
//                     TextSpan(text: DateFormat('d. M. y').format(time))
//                   ]
//                 )),
//                 if (editing) OutlinedButton(
//                   onPressed: () async {
//                     final newTime = await showDatePicker(
//                       context: context,
//                       initialDate: time,
//                       firstDate: DateTime(1969),
//                       lastDate: DateTime(2069)
//                     );
//                     if (newTime == null) return;
//                     dialogSetState(() {
//                       time = newTime;
//                     },);
//                   },
//                   child: Text(DateFormat('d. M. y').format(time)),
//                 ),
//                 if (!editing && task?['subject'] != null) RichText(text: TextSpan(
//                   children: [
//                     const TextSpan(text: 'Subject: ', style: TextStyle(fontWeight: FontWeight.bold)),
//                     TextSpan(text: task!['subject'])
//                   ]
//                 )),
//                 if (editing) TextField(
//                   controller: subjectController,
//                   decoration: const InputDecoration(labelText: 'Subject'),
//                 ),
//                 if (!editing && task?['title'] != null) RichText(text: TextSpan(
//                   children: [
//                     const TextSpan(text: 'Title: ', style: TextStyle(fontWeight: FontWeight.bold)),
//                     TextSpan(text: task!['title'])
//                   ]
//                 )),
//                 if (editing) TextField(
//                   controller: titleController,
//                   decoration: const InputDecoration(labelText: 'Title'),
//                 ),
//                 RichText(text: const TextSpan(text: 'Files: ', style: TextStyle(fontWeight: FontWeight.bold)),),
//                 ...task?['files'].map((dynamic file) => Padding(
//                   padding: const EdgeInsets.all(8.0),
//                   child: Row(
//                     children: [
//                       RichText(text: TextSpan(
//                         style: const TextStyle(color: Colors.lightBlue),
//                         text: file,
//                         recognizer: TapAndPanGestureRecognizer()..onTapDown = (details) {
//                           launchUrl(Uri.parse('${pb.baseUrl}/api/files/tasks/${task['id']}/$file'), mode: LaunchMode.externalApplication);
//                         }
//                       )),
//                       if (editing) IconButton(
//                         onPressed: () {
//                           removedFiles.add(file);
//                           dialogSetState(() {
//                             task['files'].remove(file);
//                           },);
//                         },
//                         icon: const Icon(Icons.remove_circle_rounded)
//                       ),
//                     ],
//                   ),
//                 )).toList() ?? [],
//                 if (editing) Row(
//                   children: [
//                     RichText(text: const TextSpan(text: 'Added Files: ', style: TextStyle(fontWeight: FontWeight.bold), ),),
//                     IconButton(
//                       onPressed: () async {
//                         final files = await FilePicker.platform.pickFiles();
//                         if (files == null) return;
//                         dialogSetState(() {
//                           addedFiles.addAll(files.files);
//                         },);
//                       },
//                       icon: const Icon(Icons.add)
//                     ),
//                   ],
//                 ),
//                 if (editing) ...addedFiles.map((PlatformFile file) => Row(
//                   children: [
//                     Flexible(
//                       child: RichText(text: TextSpan(
//                         style: const TextStyle(color: Colors.green),
//                         text: file.name,
//                       )),
//                     ),
//                     Flexible(
//                       child: IconButton(
//                         onPressed: () {
//                           dialogSetState(() {
//                             addedFiles.remove(file);
//                           },);
//                         },
//                         icon: const Icon(Icons.remove_circle_rounded)
//                       ),
//                     ),
//                   ],
//                 )).toList(),
//                 if (!editing) Row(
//                   children: [
//                     Flexible(
//                       child: Column(
//                         crossAxisAlignment: CrossAxisAlignment.start,
//                         mainAxisSize: MainAxisSize.min,
//                         children: [RichText(text: TextSpan(
//                           children: [
//                             const TextSpan(text: 'Description: ', style: TextStyle(fontWeight: FontWeight.bold)),
//                             TextSpan(text: task!['description'])
//                           ]
//                         )),]
//                       ),
//                     ),
//                   ],
//                 ),
//                 if (editing) TextField(
//                   controller: descriptionController,
//                   maxLines: null,
//                   decoration: const InputDecoration(labelText: 'Description'),
//                 ),
//               ],
//             ),
//           ),
//           actions: [
//             if (admin && !editing) OutlinedButton(
//               onPressed: () {
//                 dialogSetState(() {
//                   editing = true;
//                 });
//               },
//               child: const Text('Edit'),
//             ),
//             if (editing && task?['author'] == null) OutlinedButton(
//               onPressed: () {
//                 loadingSnack(() async {
//                   final navigatorState = Navigator.of(context);
//                   await loginPb();
//                   await pb.collection('tasks').create(body: {
//                     'stream': stream,
//                     'author': pb.authStore.model.id,
//                     'time': time.toIso8601String(),
//                     'subject': subjectController.text,
//                     'title': titleController.text,
//                     'description': descriptionController.text,
//                   }, files: await Future.wait(addedFiles.map((e) async => http.MultipartFile.fromBytes(
//                     'files', await File(e.path ?? '').readAsBytes(), filename: e.name
//                   )).toList()));
//                   await loadTasks();
//                   navigatorState.pop();
//                   setState(() {},);
//                 }, 'creating');
//               },
//               child: const Text('Create'),
//             ),
//             if (editing && task?['author'] != null) OutlinedButton(
//               onPressed: () {
//                 loadingSnack(() async {
//                   final navigatorState = Navigator.of(context);
//                   await loginPb();
//                   await pb.collection('tasks').update(task!['id'], body: {
//                     'stream': stream,
//                     'author': pb.authStore.model.id,
//                     'time': time.toIso8601String(),
//                     'subject': subjectController.text,
//                     'title': titleController.text,
//                     'description': descriptionController.text,
//                   }, files: await Future.wait(addedFiles.map((e) async => http.MultipartFile.fromBytes(
//                     'files', await File(e.path ?? '').readAsBytes(), filename: e.name
//                   )).toList()));
//                   if (removedFiles.isNotEmpty) {
//                     await pb.collection('tasks').update(task['id'], body: {
//                       'files-': removedFiles,
//                     });
//                   }
//                   await loadTasks();
//                   navigatorState.pop();
//                   setState(() {},);
//                 }, 'submitting');
//               },
//               child: const Text('Submit'),
//             ),
//             OutlinedButton(
//               onPressed: () {
//                 Navigator.pop(context);
//               },
//               child: const Text('Close'),
//             ),
//           ],
//         );
//       },
//     );
//   },);
// }
// Future<void> addTask (String subject, String date, String title, String description, BuildContext context) async {
//   date = date.replaceAll(' ', '');
//   if (date == 'zítra') {
//     date = DateFormat('d.M.y').format(DateTime.now().add(const Duration(days: 1)));
//   }
//   else if (date == 'pozítří') {
//     date = DateFormat('d.M.y').format(DateTime.now().add(const Duration(days: 1)));
//   }
//   else if (date == 'popozítří') {
//     date = DateFormat('d.M.y').format(DateTime.now().add(const Duration(days: 1)));
//   }
//   else if (date.startsWith('za')) {
//     date = DateFormat('d.M.y').format(DateTime.now().add(Duration(days: int.parse(date.substring(2)))));
//   }
//   String dateString = '';
//   try {
//     dateString = DateFormat('d.M.y').parse(date).toIso8601String();
//   } on FormatException {
//     try {
//       dateString = DateFormat('d.M').parse(date).toIso8601String();
//     } on FormatException {
//       showDialog(context: context, builder: (BuildContext context) {
//         return const AlertDialog(
//           title: Text('Error'),
//           content: Text('Date not valid'),
//         );
//       });
//     }
//   }
//   final Map payload = {
//     'Id': 'K:${DateTime.now().millisecondsSinceEpoch}',
//     'Title': title,
//     'Description': description,
//     'EventType': {
//       'Id': 'K:$subject',
//       'Abbrev': subject,
//       'Name': subject,
//     },
//     'Times': [
//       {
//         'WholeDay': true,
//         'StartTime': dateString,
//       }
//     ],
//     'Classes': [
//       {
//         'Id': 'ZY',
//         'Abbrev': '4.M (celá)',
//         'Name': 'osmileté matematické (celá třída)',
//       },
//     ],
//     'ClassSets': [],
//     'Teachers': [],
//     'TeacherSets': [],
//     'Rooms': [],
//     'RoomSets': [],
//     'Students': [],
//     'Note': 'From Kleofáš v0.0.0',
//     'DateChnged': DateTime.now().toIso8601String()
//   };
//   if (!await loginPb()) return;
//   await Future.wait([
//     pb.collection('tasks').create(body: {'json': jsonEncode(payload)}),
//     storage.put('tasks', (storage.get('tasks') ?? {'Tasks': []})..['Tasks'].add(payload))
//   ]);
// }

// void newTaskDialog (BuildContext context, [DateTime? date]) async {
//   final navigator = Navigator.of(context);
//   final newTaskSubjectController = TextEditingController();
//   final newTaskDateController = TextEditingController(text: date == null ? '' : DateFormat('d. M. y').format(date));
//   final newTaskTitleController = TextEditingController();
//   final newTaskDescController = TextEditingController();
//   showDialog(context: context, builder: (BuildContext context) {
//     double halfWidth = MediaQuery.of(context).size.width / 2;
//     return AlertDialog(
//       title: const Text('Přidat task'),
//       content: Column(
//         mainAxisSize: MainAxisSize.min,
//         children: [
//           Padding(
//             padding: const EdgeInsets.all(4),
//             child: SizedBox(
//               width: halfWidth,
//               child: TextField(
//                 controller: newTaskSubjectController,
//                 decoration: const InputDecoration(
//                   hintText: 'předmět',
//                 ),
//               ),
//             ),
//           ),
//           Padding(
//             padding: const EdgeInsets.all(4),
//             child: Row(
//               children: [
//                 SizedBox(
//                   width: halfWidth - 30,
//                   child: TextField(
//                     controller: newTaskDateController,
//                     decoration: const InputDecoration(
//                       hintText: 'datum',
//                     ),
//                   ),
//                 ),
//                 SizedBox(
//                   width: 30,
//                   child: IconButton(
//                     onPressed: () async {
//                       DateTime? selectedDate = await showDatePicker(context: context, initialDate: DateTime.now(), firstDate: DateTime(1969, 4, 20), lastDate: DateTime(2069, 4, 20));
//                       if (selectedDate == null) return;
//                       newTaskDateController.text = DateFormat('d. M. y').format(selectedDate);
//                     },
//                     icon: const Icon(Icons.date_range_rounded)
//                   ),
//                 ),
//               ],
//             ),
//           ),
//           Padding(
//             padding: const EdgeInsets.all(4),
//             child: SizedBox(
//               width: halfWidth,
//               child: TextField(
//                 controller: newTaskTitleController,
//                 decoration: const InputDecoration(
//                   hintText: 'nadpis',
//                 ),
//               ),
//             ),
//           ),
//           Padding(
//             padding: const EdgeInsets.all(4),
//             child: SizedBox(
//               width: halfWidth,
//               child: TextField(
//                 controller: newTaskDescController,
//                 maxLines: 5,
//                 decoration: const InputDecoration(
//                   hintText: 'popis',
//                 ),
//               ),
//             ),
//           ),
//         ],
//       ),
//       actions: [
//         TextButton(onPressed: () {navigator.pop();}, child: const Text('Zrušit')),
//         TextButton(onPressed: () {
//           loadingSnack(() async {
//             await addTask(newTaskSubjectController.text, newTaskDateController.text, newTaskTitleController.text, newTaskDescController.text, context);
//             navigator.pop();
//           });
//         }, child: const Text('Přidat')),
//       ],
//     );
//   });
// }