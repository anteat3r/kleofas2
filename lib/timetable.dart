import 'dart:math';
import 'package:kleofas2/day.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'storage.dart';
import 'package:intl/intl.dart';

class TimetablePage extends StatefulWidget{
  const TimetablePage({Key? key}) : super(key: key);
  @override
  State<TimetablePage> createState() => _TimetablePageState();
}

class _TimetablePageState extends State<TimetablePage> {
  int weeksOffset = 0;
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
              hour?['Caption'],
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 20,
              ),
            ),
            Text(
              hour?['BeginTime'],
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: 12,
              ),
            ),
            Text(
              hour?['EndTime'],
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
              content: Text('Skupiny: ${hour?["GroupIds"]?.map((item) => groups[item]["Abbrev"]).join(" ")}\nPředmět: ${subjects[hour?["SubjectId"]]?["Name"]}\nUčitel: ${teachers[hour?["TeacherId"]]?["Name"]}\nUčebna: ${rooms[hour?["RoomId"]]?["Abbrev"]}\nTéma: ${hour?["Theme"]}\nZměna: ${hour?["Change"] == null ? '' : '\n  Změna předmětu: ${hour?["Change"]["ChangeSubject"]}\n  Den: ${czDate(hour?["Change"]["Day"])}\n  Hodiny: ${hour?["Change"]["Hours"]}\n  Typ změny: ${hour?["Change"]["ChangeType"]}\n  Popis: ${hour?["Change"]["Description"]}\n  Čas: ${hour?["Change"]["Time"]}\n  Zkratka typu: ${hour?["Change"]["TypeAbbrev"]}\n  Název typu: ${hour?["Change"]["TypeName"]}'}'),
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
              : Colors.lightBlue.shade700 )
            : hour == null || hour?['TeacherId'] == null
              ? const Color.fromARGB(255, 48, 48, 48)
              : Colors.blue.shade800
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              (hour == null || hour?['TeacherId'] == null) ? (hour?["Change"]?["TypeAbbrev"] ?? '') : subjects[hour?['SubjectId']]?['Abbrev'] ?? 'null',
              style: const TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 20,
              ),
            ),
            Text(
              (hour == null || hour?['TeacherId'] == null) ? '' : (teachers[hour?['TeacherId']]['Abbrev'] ?? 'null') + '\n' + (rooms[hour?['RoomId']]['Abbrev'] ?? 'null') + '\n' + (groups[hour?['GroupIds'][0]]['Abbrev'] ?? 'null'),
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
        /*IconButton(
          onPressed: () {
            weeksOffset -= 1;
            setState(() {
              loadEndpoint(context, 'timetable', 'timetable/actual', {'date': DateFormat('yyyy-MM-dd').format(DateTime.now().add(Duration(days: 7 * weeksOffset)))});
            });
          },
          icon: const Icon(Icons.curtains_rounded)
        ),*/
        IconButton(
          onPressed: () {
            weeksOffset -= 1;
            setState(() {
              loadEndpoint(context, 'timetable', 'timetable/actual', {'date': DateFormat('yyyy-MM-dd').format(DateTime.now().add(Duration(days: 7 * weeksOffset)))});
            });
          },
          icon: const Icon(Icons.arrow_left_rounded)
        ),
        IconButton(
          onPressed: () {
            setState(() {
              weeksOffset = 0;
              loadEndpoint(context, 'timetable', 'timetable/actual');
            });
          },
          icon: const Icon(Icons.refresh_rounded)
        ),
        IconButton(
          onPressed: () {
            weeksOffset += 1;
            setState(() {
              loadEndpoint(context, 'timetable', 'timetable/actual', {'date': DateFormat('yyyy-MM-dd').format(DateTime.now().add(Duration(days: 7 * weeksOffset)))});
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
    );
  }

}