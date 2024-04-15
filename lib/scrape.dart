import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:html/parser.dart';
import 'package:intl/intl.dart';
import 'package:kleofas2/day.dart';

import 'bakalari.dart';
import 'custom_icons.dart';
import 'storage.dart';

DateTime roundDateTime (DateTime date) {
  if (date.hour > 12) {
    return DateTime(date.year, date.month, date.day + 1);
  }
  return date;
}

class ParsePage extends StatefulWidget{
  const ParsePage({super.key});
  @override
  State<ParsePage> createState() => _ParsePageState();
}

enum SelectedIdType {classes, teachers, rooms}
enum TimeTableType {permanent, actual, next}

class _ParsePageState extends State<ParsePage> {
  DateTime curDate = DateTime.now();
  final List<String> czWeekDayNames = ['Ne', 'Po', 'Út', 'St', 'Čt', 'Pá', 'So', 'Ne'];
  Map<String, String>? classOpts;
  Map<String, String>? teacherOpts;
  Map<String, String>? roomOpts;
  String? selectedId;
  SelectedIdType? selectedType;
  TimeTable? timeTable;
  String? cookie;
  bool collapsed = false;
  TimeTableType timeTableType = TimeTableType.actual;

  Widget hourTitleCell (Map hour, double maxHeight) {
    return SizedBox(
      height: 40,
      child: ElevatedButton(
        onPressed: () {},
        style: ButtonStyle(
          shape: MaterialStatePropertyAll(RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
          backgroundColor: MaterialStatePropertyAll(Colors.blue.shade900),
        ),
        child: OrientationBuilder(
          builder: (context, orientation) => Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                hour['Caption'],
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 20,
                ),
              ),
              // if (orientation == Orientation.portrait) Text(
              //   hour['BeginTime'],
              //   style: const TextStyle(
              //     fontWeight: FontWeight.w500,
              //     fontSize: 12,
              //   ),
              // ),
              // if (orientation == Orientation.portrait) Text(
              //   hour['EndTime'],
              //   style: const TextStyle(
              //     fontWeight: FontWeight.w500,
              //     fontSize: 12,
              //   ),
              // ),
            ],
          ),
        ),
      ),
    );
  }

  Widget dayCell (Map day, double height, [String? teacherId]) {
    List events = List.from(storage.get(teacherId == null ? 'events' : 'events:all')?['Events'] ?? []);
    events.addAll(storage.get('tasks')?['Tasks'] ?? []);
    day['Date'] = DateTime.parse(day['Date']).toIso8601String();
    if (teacherId != null) {
      events = events.where((element) => element.toString().contains(teacherId)).toList();
    }
    events = events.where((element) => isEventInvolved(element, day['Date']),).toList();
    if (events.length > 4) {
      events = events.sublist(0, 3) + [{}];
    }
    return SizedBox(
      height: height,
      child: ElevatedButton(
        onPressed: () {Navigator.push(context, MaterialPageRoute(builder: (context) => DayPage(DateTime.parse(day['Date']),teacherId: teacherId,)));},
        onLongPress: () {
          showDialog(context: context, builder: (BuildContext context) {
            return AlertDialog(
              title: const Text('Den'),
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
        child: OrientationBuilder(
          builder: (context, orientation) => Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                czWeekDayNames[day['DayOfWeek']],
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 30,
                ),
              ),
              if (orientation == Orientation.portrait) Text(
                DateFormat('d. M.').format(DateTime.parse(day['Date'])..add(const Duration(days: 1))),
                style: const TextStyle(
                  fontWeight: FontWeight.w500,
                  fontSize: 12,
                ),
              ),
              if (orientation == Orientation.portrait) Wrap(
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
          ),
        ),
      ),
    );
  }

  Widget hourCell (Cell hour, double height) {
    return SizedBox(
      height: height,
      child: ElevatedButton(
        onPressed: () {
          showDialog(context: context, builder: (context) => AlertDialog(
            title: const Text("Detail hodiny"),
            content: Text("${hour.subject}\n${hour.teacher}\n${hour.room}\n${hour.group}\n${hour.detail}\n"),
            actions: [
              TextButton(onPressed: () {Navigator.pop(context);}, child: const Text('Ok'))
            ],
          ));
        },
        onLongPress: () {
          setState(() {
            collapsed = !collapsed;
          });
        },
        style: ButtonStyle(
          shape: MaterialStatePropertyAll(RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
          backgroundColor: MaterialStatePropertyAll(
            hour.group.isEmpty && hour.teacher.isEmpty && hour.room.isEmpty && hour.subject.isEmpty && hour.color == CellColor.white
            ? const Color.fromARGB(255, 48, 48, 48)
            : switch (hour.color) {
              CellColor.white => Colors.blue.shade800,
              CellColor.pink => Colors.lightBlue,
              CellColor.green => Colors.lightBlue.shade800,
            }
          ),
        ),
        child: OrientationBuilder(
          builder: (context, orientation) => Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                hour.subject,
                style: const TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 20,
                ),
              ),
              if (orientation == Orientation.portrait && !collapsed) Text(
                hour.group.isEmpty &&
                hour.teacher.isEmpty &&
                hour.room.isEmpty &&
                hour.subject.isEmpty
                  ? ''
                  : '${hour.teacher}\n${hour.room}\n${hour.group}',
                textAlign: TextAlign.left,
                style: const TextStyle(
                  fontWeight: FontWeight.w500,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void loadOpts() {
    loadingSnack(() async {
      final url = getPassword("bakalari", "url");
      cookie = await loginWebCookie(
        url,
        getPassword("bakalari", "username"),
        getPassword("bakalari", "password"),
      );
      final html = await queryWeb(url, "Timetable/Public", cookie!);
      final doc = parse(html);
      final opts = parseBakalariIds(doc);
      classOpts = opts.classes;
      teacherOpts = opts.teachers;
      roomOpts = opts.rooms;
      setState(() {});
    });
  }

  String stringifyTimeTableType(TimeTableType val) => switch (val) {
    TimeTableType.permanent => "Permanent",
    TimeTableType.actual => "Actual",
    TimeTableType.next => "Next",
  };

  void loadParsedTimeTable() {
    loadingSnack(() async {
      if (cookie == null) return;
      final url = getPassword("bakalari", "url");
      final timePrefix = stringifyTimeTableType(timeTableType);
      final typePrefix = switch (selectedType!) {
        SelectedIdType.classes => "Class",
        SelectedIdType.teachers => "Teacher",
        SelectedIdType.rooms => "Room",
      };
      final html = await queryWeb(url, "Timetable/Public/$timePrefix/$typePrefix/$selectedId", cookie!);
      final doc = parse(html);
      timeTable = parseTimetable(doc);
      setState(() {});
    });
  }

  @override
  void initState() {
    super.initState();
    loadOpts();
  } 

  @override
  Widget build (BuildContext context) {
    AppBar appBar = AppBar(
      title: const Text('Timetable'),
      actions: [
        DropdownButton(
          items: TimeTableType.values.map((e) => DropdownMenuItem(value: e, child: Text(stringifyTimeTableType(e)))).toList(),
          onChanged: (newval) {
            if (newval == null) return;
            timeTableType = newval;
            if (selectedType == null) return;
            loadParsedTimeTable();
          },
          value: timeTableType,
        ),
      ],
    );
    double maxHeight = MediaQuery.of(context).size.height - appBar.preferredSize.height - MediaQuery.of(context).padding.top - 19;
    return Scaffold(
      appBar: appBar,
      body: loadScrollSnacksWrapper(context,
        child: Column(
          children: [
            if (classOpts != null && teacherOpts != null && roomOpts != null) Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                DropdownButton(
                  items: classOpts?.keys.map((e) => DropdownMenuItem(
                    value: e,
                    child: Text(classOpts?[e] ?? "?"),
                  )).toList(),
                  onChanged: (newval) {
                    setState(() {
                       if (newval == null) return;
                       selectedId = newval;
                       selectedType = SelectedIdType.classes;
                    });
                    loadParsedTimeTable();
                  },
                  value: selectedType == SelectedIdType.classes ? selectedId : null,
                ),
                DropdownButton(
                  items: teacherOpts?.keys.map((e) => DropdownMenuItem(
                    value: e,
                    child: Text(teacherOpts?[e] ?? "?"),
                  )).toList(),
                  onChanged: (newval) {
                    setState(() {
                       if (newval == null) return;
                       selectedId = newval;
                       selectedType = SelectedIdType.teachers;
                    });
                    loadParsedTimeTable();
                  },
                  value: selectedType == SelectedIdType.teachers ? selectedId : null,
                ),
                DropdownButton(
                  items: roomOpts?.keys.map((e) => DropdownMenuItem(
                    value: e,
                    child: Text(roomOpts?[e] ?? "?"),
                  )).toList(),
                  onChanged: (newval) {
                    setState(() {
                       if (newval == null) return;
                       selectedId = newval;
                       selectedType = SelectedIdType.rooms;
                    });
                    loadParsedTimeTable();
                  },
                  value: selectedType == SelectedIdType.rooms ? selectedId : null,
                ),
              ],
            ),
            if (selectedType == SelectedIdType.teachers) OutlinedButton(
              onPressed: () {
                loadEndpointSnack('events:all', url: 'events/all');
                setState(() { });
              },
              child: const Text('Reload all events'),
            ),
            if (timeTable != null) SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: SizedBox(
                width: timeTable!.map((e) => e.length).fold(0, max) * 100,
                child: Table(
                  children: [
                    TableRow(
                      children: 
                        [
                          const TableCell(child: Text("")),
                          ...List.generate(
                            timeTable!.map((e) => e.length).fold(0, max), (index) {
                              return hourTitleCell({"Caption": index.toString(), "BeginTime": "", "EndTime": ""}, maxHeight);
                            }
                          )
                        ],
                    ),
                    ...List.generate(
                      timeTable!.length, (index) {
                        return TableRow(
                          children: [
                            dayCell({
                              "DayOfWeek": index+1,
                              "Date": DateTime
                                .now()
                                .add(Duration(days: (timeTableType == TimeTableType.next ? 1 : 0)*7-DateTime.now().weekday+1+index)).toString()
                            }, (maxHeight - 95)/5,
                            selectedType == SelectedIdType.teachers ? selectedId : null,
                            ),
                            ...List.generate(
                              timeTable!.map((e) => e.length).fold(0, max), (index2) => Column(
                                children: timeTable![index].asMap()[index2]?.map((e) => hourCell(e, (maxHeight - 95)/5/(timeTable![index][index2].length))).toList() ?? [const SizedBox()],
                              )
                            )
                          ],
                        );
                      }
                    )
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

}

