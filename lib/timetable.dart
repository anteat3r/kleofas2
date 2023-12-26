import 'dart:convert';
import 'dart:math';
import 'package:kleofas2/day.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'storage.dart';
import 'package:intl/intl.dart';
import 'dart:io';
import 'custom_icons.dart';

DateTime roundDateTime (DateTime date) {
  if (date.hour > 12) {
    return DateTime(date.year, date.month, date.day + 1);
  }
  return date;
}

class TimetablePage extends StatefulWidget{
  const TimetablePage({Key? key}) : super(key: key);
  @override
  State<TimetablePage> createState() => _TimetablePageState();
}

class _TimetablePageState extends State<TimetablePage> {
  DateTime curDate = DateTime.now();
  final List<String> czWeekDayNames = ['Ne', 'Po', 'Út', 'St', 'Čt', 'Pá', 'So', 'Ne'];

  Widget hourTitleCell (Map hour, double maxHeight) {
    return SizedBox(
      height: maxHeight / 7,
      child: ElevatedButton(
        onPressed: () {},
        style: ButtonStyle(
          shape: MaterialStatePropertyAll(RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
          backgroundColor: MaterialStatePropertyAll(Colors.blue.shade900),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              hour['Caption'],
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 20,
              ),
            ),
            Text(
              hour['BeginTime'],
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: 12,
              ),
            ),
            Text(
              hour['EndTime'],
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: 12,
              ),
            ),
          ],
        )
      ),
    );
  }

  Widget dayCell (Map day, double maxHeight) {
    List events = List.from(storage.get('events')?['Events'] ?? []);
    events.addAll(storage.get('tasks')?['Tasks'] ?? []);
    day['Date'] = roundDateTime(DateTime.parse(day['Date'])).toIso8601String();
    events = events.where((element) => isEventInvolved(element, day['Date']),).toList();
    if (events.length > 4) {
      events = events.sublist(0, 3) + [{}];
    }
    return SizedBox(
      height: maxHeight * 6 / 35,
      child: ElevatedButton(
        onPressed: () {Navigator.push(context, MaterialPageRoute(builder: (context) => DayPage(DateTime.parse(day['Date']))));},
        onLongPress: () {
          showDialog(context: context, builder: (BuildContext context) {
            return AlertDialog(
              title: const Text('Den'),
              // content: Text('Datum: ${czDate(day["Date"])}\nPopis: ${day["DayDescription"]}\nTyp: ${day["DayType"]}'),
              content: SingleChildScrollView(scrollDirection: Axis.horizontal, child: Text(const JsonEncoder.withIndent('    ').convert({...day}..remove('Atoms')))),
              actions: [
                TextButton(onPressed: () {Navigator.pop(context);}, child: const Text('Ok'))
              ],
            );
          });
        },
        style: ButtonStyle(
          shape: MaterialStatePropertyAll(RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
          backgroundColor: MaterialStatePropertyAll(Colors.blue.shade900),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              czWeekDayNames[day['DayOfWeek']],
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 30,
              ),
            ),
            Text(
              DateFormat('d. M.').format(DateTime.parse(day['Date'])..add(const Duration(days: 1))),
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: 12,
              ),
            ),
            Wrap(
              alignment: WrapAlignment.center,
              direction: Axis.horizontal,
              children: [for (final event in events) Container(
                margin: const EdgeInsets.all(2),
                width: Platform.isWindows ? 17 : 20,
                height: Platform.isWindows ? 17 : 20,
                child: Transform.translate(offset: const Offset(-3, 0), child:
                  event != {}
                  ? ( event.containsKey('time')
                    ? Icon(allIconsMap[user.get('streamicon:${event['stream']}')] ?? Icons.tornado_rounded, size: Platform.isWindows ? 20 : 24,)
                    : Icon(Icons.event, size: Platform.isWindows ? 20 : 24,) )
                  : const Text('...')
                ),
              )],
            )
          ],
        )
      ),
    );
  }

  Widget hourCell (Map? hour, double maxHeight, Map subjects, Map rooms, Map teachers, Map groups) {
    return SizedBox(
      height: maxHeight * 6 / 35,
      child: ElevatedButton(
        onPressed: (hour == null) ? () {} : () {
          showDialog(context: context, builder: (BuildContext context) {
            return AlertDialog(
              title: const Text('Hodina'),
              // content: Text('Skupiny: ${hour["GroupIds"]?.map((item) => groups[item]["Abbrev"]).join(" ")}\nPředmět: ${subjects[hour["SubjectId"]]?["Name"]}\nUčitel: ${teachers[hour["TeacherId"]]?["Name"]}\nUčebna: ${rooms[hour["RoomId"]]?["Abbrev"]}\nTéma: ${hour["Theme"]}\nZměna: ${hour["Change"] == null ? '' : '\n  Změna předmětu: ${hour["Change"]["ChangeSubject"]}\n  Den: ${czDate(hour["Change"]["Day"])}\n  Hodiny: ${hour["Change"]["Hours"]}\n  Typ změny: ${hour["Change"]["ChangeType"]}\n  Popis: ${hour["Change"]["Description"]}\n  Čas: ${hour["Change"]["Time"]}\n  Zkratka typu: ${hour["Change"]["TypeAbbrev"]}\n  Název typu: ${hour["Change"]["TypeName"]}'}'),
              content: SingleChildScrollView(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Text(const JsonEncoder.withIndent('    ').convert(hour)
                    .replaceAppendAll('"${hour['TeacherId'] ?? '?'}"', ' - "${getId(hour['TeacherId']).name}"')
                    .replaceAppendAll('"${hour['RoomId'] ?? '?'}"', ' - "${getId(hour['RoomId']).abbrev}"')
                    .replaceAppendAll('"${hour['SubjectId'] ?? '?'}"', ' - "${getId(hour['SubjectId']).name}"')
                    .replaceAppendMap({for (String groupId in hour['GroupIds'] ?? []) '"$groupId"': ' - "${getId(groupId).abbrev}"'})
                  ),
                ),
              ),
              actions: [
                TextButton(onPressed: () {Navigator.pop(context);}, child: const Text('Ok'))
              ],
            );
          });
        },
        style: ButtonStyle(
          shape: MaterialStatePropertyAll(RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
          backgroundColor: MaterialStatePropertyAll(
            hour?['Change'] != null
            ? ( hour?['Change']?['TypeAbbrev'] == null
              ? Colors.lightBlue
              : Colors.lightBlue.shade600 )
            : ( hour == null || hour['TeacherId'] == null
                ? const Color.fromARGB(255, 48, 48, 48)
                : Colors.blue.shade800
              )
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              (hour == null || hour['TeacherId'] == null) ? (hour?["Change"]?["TypeAbbrev"] ?? '') : subjects[hour['SubjectId']]?['Abbrev'] ?? 'null',
              style: const TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 20,
              ),
            ),
            Text(
              (hour == null || hour['TeacherId'] == null) ? '' : (teachers[hour['TeacherId']]['Abbrev'] ?? 'null') + '\n' + (rooms[hour['RoomId']]['Abbrev'] ?? 'null') + '\n' + (groups[hour['GroupIds'][0]]['Abbrev'] ?? 'null'),
              textAlign: TextAlign.left,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: 12,
              ),
            ),
          ],
        )
      ),
    );
  }

  @override
  Widget build (BuildContext context) {
    AppBar appBar = AppBar(
      title: const Text('Timetable'),
      actions: [
        IconButton(
          onPressed: () async {
            final pickedDate = await showDatePicker(context: context, initialDate: curDate, firstDate: DateTime(1969), lastDate: DateTime(2069));
            if (pickedDate == null) return;
            curDate = pickedDate;
            setState(() { loadingSnack(() => loadTimeTable(curDate)); });
          },
          icon: const Icon(Icons.date_range)
        ),
        IconButton(
          onPressed: () {
            curDate = curDate.subtract(const Duration(days: 7));
            setState(() { loadEndpointSnack('timetable', url: 'timetable/actual', payload: {'date': DateFormat('yyyy-MM-dd').format(curDate)}); });
          },
          icon: const Icon(Icons.arrow_left_rounded)
        ),
        IconButton(
          onPressed: () {
              curDate = DateTime.now();
            setState(() { loadEndpointSnack('timetable', url: 'timetable/actual'); });
          },
          icon: const Icon(Icons.refresh_rounded)
        ),
        IconButton(
          onPressed: () {
            curDate = curDate.add(const Duration(days: 7));
            setState(() { loadEndpointSnack('timetable', url: 'timetable/actual', payload: {'date': DateFormat('yyyy-MM-dd').format(curDate)}); });
          },
          icon: const Icon(Icons.arrow_right_rounded)
        ),
      ],
    );
    double maxHeight = MediaQuery.of(context).size.height - appBar.preferredSize.height - MediaQuery.of(context).padding.top - 19;
    return Scaffold(
      appBar: appBar,
      body: loadScrollSnacksWrapper(context,
        child: Column(
          children: [
            ValueListenableBuilder(
              valueListenable: refresh.listenable(),
              builder: (BuildContext context, Box<int> value, child) {
                return Text(czDate(DateTime.fromMillisecondsSinceEpoch(value.get('timetable') ?? 0).toString()));
              }
            ),
            ValueListenableBuilder(
              valueListenable: storage.listenable(),
              builder: (BuildContext context, Box<Map> value, child) {
                List getElem (String name) => value.get('timetable')?[name] ?? [];
                List hours = getElem('Hours');
                List days = getElem('Days');
                hours = hours.sublist(max(0, hours.indexWhere((element) => days.any((day) => day['Atoms'].any((atom) => atom['HourId'] == element['Id'])))), hours.lastIndexWhere((element) => days.any((day) => day['Atoms'].any((atom) => atom['HourId'] == element['Id']))) + 1);
                Map groups = mapListToMap(getElem('Groups'));
                Map subjects = mapListToMap(getElem('Subjects'));
                Map teachers = mapListToMap(getElem('Teachers'));
                Map rooms = mapListToMap(getElem('Rooms'));
                return SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: SizedBox(
                    width: hours.length * 100,
                    child: Table(
                      children: [
                        TableRow(
                          children: 
                            [
                              const TableCell(child: Text("")),
                              ...List.generate(
                                hours.length, (index) {
                                  return hourTitleCell(hours[index], maxHeight);
                                }
                              )
                            ],
                        ),
                        ...List.generate(
                          days.length, (index) {
                            return TableRow(
                              children: [
                                dayCell(days[index], maxHeight),
                                ...List.generate(
                                  hours.length, (index2) {
                                    return hourCell(mapListToMap(days[index]['Atoms'], id: 'HourId')[hours[index2]['Id']], maxHeight, subjects, rooms, teachers, groups);
                                  }
                                )
                              ],
                            );
                          }
                        )
                      ],
                    ),
                  ),
                );
              }
            )
          ],
        ),
      ),
    );
  }

}