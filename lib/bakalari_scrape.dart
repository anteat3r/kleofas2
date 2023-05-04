import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'bakalari.dart';
import 'day.dart';
import 'package:intl/intl.dart';
import 'storage.dart';
import 'dart:math';
import 'package:universal_html/parsing.dart';
import 'package:universal_html/html.dart' as html;
import 'dart:convert';

class EventsPage extends StatefulWidget{
  const EventsPage({Key? key}) : super(key: key);
  @override
  State<EventsPage> createState() => _EventsPageState();
}

class _EventsPageState extends State<EventsPage> {
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
    events = events.where((element) => element['Times'].map((element1) => element1['StartTime'].split('T')[0]).contains(day['Date'].split('T')[0])).toList();
    return SizedBox(
      height: maxHeight * 6 / 35,
      child: ElevatedButton(
        onPressed: () {Navigator.push(context, MaterialPageRoute(builder: (context) => DayPage(DateTime.parse(day['Date']))));},
        onLongPress: () {
          showDialog(context: context, builder: (BuildContext context) {
            return AlertDialog(
              title: const Text('Den'),
              content: Text('Datum: ${czDate(day["Date"])}\nPopis: ${day["DayDescription"]}\nTyp: ${day["DayType"]}'),
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
              children: [for (var event in events) Container(
                margin: const EdgeInsets.all(2),
                width: 20,
                height: 20,
                child: Transform.translate(offset: const Offset(-3, 0), child: event['Id'].startsWith('K:') ? const Icon(Icons.tornado_rounded) : const Icon(Icons.event)),
              )
              ],
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
              content: Text('Skupiny: ${hour["GroupIds"]?.map((item) => groups[item]["Abbrev"]).join(" ")}\nPředmět: ${subjects[hour["SubjectId"]]?["Name"]}\nUčitel: ${teachers[hour["TeacherId"]]?["Name"]}\nUčebna: ${rooms[hour["RoomId"]]?["Abbrev"]}\nTéma: ${hour["Theme"]}\nZměna: ${hour["Change"] == null ? '' : '\n  Změna předmětu: ${hour["Change"]["ChangeSubject"]}\n  Den: ${czDate(hour["Change"]["Day"])}\n  Hodiny: ${hour["Change"]["Hours"]}\n  Typ změny: ${hour["Change"]["ChangeType"]}\n  Popis: ${hour["Change"]["Description"]}\n  Čas: ${hour["Change"]["Time"]}\n  Zkratka typu: ${hour["Change"]["TypeAbbrev"]}\n  Název typu: ${hour["Change"]["TypeName"]}'}'),
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
            ? Colors.lightBlue
            : hour == null || hour['TeacherId'] == null
              ? const Color.fromARGB(255, 48, 48, 48)
              : Colors.blue.shade800
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              (hour == null || hour['TeacherId'] == null) ? '' : subjects[hour['SubjectId']]?['Abbrev'] ?? 'null',
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
          onPressed: () {
            setState(() async {
              String cookie = await loginWebCookie(user.get('url') ?? '', user.get('username') ?? '', user.get('password') ?? '');
              String rawHtml = await queryWeb(user.get('url') ?? '', 'Timetable/Public/Actual/Class/ZX', cookie);
              var htmlDocument = parseHtmlDocument(rawHtml);
              List output = [];
              for (html.Element row in htmlDocument.querySelectorAll('.bk-timetable-row')) {
                String dateStr = row.querySelector(".bk-day-day")?.text ?? 'idk';
                String dateNum = row.querySelector(".bk-day-date")?.text ?? 'idk';
                output.add({"weekday": dateStr, "date": dateNum, "atoms": []});
                for (html.Element hour in row.querySelector(".bk-cell-wrapper")?.querySelectorAll('.bk-timetable-cell') ?? []) {
                  for (html.Element dtDetail in hour.querySelectorAll(".day-item-hover")) {
                    Map dtDetailStr = jsonDecode(dtDetail.getAttribute("data-detail") ?? '[]');
                    String subject = dtDetail.querySelector(".middle")?.text ?? "idk";
                    int hourNum = int.parse(RegExp(r"\| (\d+) \(\d+:\d+ - \d+:\d+\)").allMatches(dtDetailStr["subjecttext"]).first.group(1) ?? '-1');
                    String room = dtDetailStr['room'] ?? "idk"; //dtDetail.querySelector('.right')?.firstChild?.text ?? 'idk';
                    String group = dtDetailStr['group'] ?? "idk"; //dtDetail.querySelector('.left')?.firstChild?.text ?? 'idk';
                    String teacher = dtDetailStr['teacher'] ?? "idk"; //dtDetail.querySelector('.bottom')?.firstChild?.text ?? 'idk';
                    String changeinfo = dtDetailStr['changeinfo'] ?? "idk";
                    String theme = dtDetailStr['theme'] ?? "idk";
                    output.last["atoms"].add({"subject": subject, "hourNumber": hourNum, "room": room, "group": group, "teacher": teacher, "changeinfo": changeinfo, "theme": theme});
                  }
                }
              }
              await storage.put('timetable_web', {'days': output});
            });
          },
          icon: const Icon(Icons.south_america_rounded)
        ),
        IconButton(
          onPressed: () {
            setState(() {
            });
          },
          icon: const Icon(Icons.refresh_rounded)
        ),
        IconButton(
          onPressed: () {
            setState(() {
            });
          },
          icon: const Icon(Icons.arrow_right_rounded)
        ),
      ],
    );
    double maxHeight = MediaQuery.of(context).size.height - appBar.preferredSize.height - MediaQuery.of(context).padding.top - 19;
    return Scaffold(
      appBar: appBar,
      body: Column(
        children: [
          ValueListenableBuilder(
            valueListenable: storage.listenable(),
            builder: (BuildContext context, Box<Map> value, child) {
              List getElem (String name) => value.get('timetable')?[name] ?? [];
              List hours = getElem('Hours');
              List days = getElem('days');
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
                                  return hourCell(mapListToMap(days[index]['Atoms'], id: 'hourNumber')[hours[index2]['Id']], maxHeight, subjects, rooms, teachers, groups);
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
    );
  }
}