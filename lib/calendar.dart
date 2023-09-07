import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:kleofas2/storage.dart';
import 'day.dart';

int weekNumber(DateTime date) {
  int dayOfYear = int.parse(DateFormat("D").format(date));
  return ((dayOfYear - date.weekday + 10) / 7).floor();
}

DateTime roundDateTime (DateTime date) {
  if (date.hour > 12) {
    return DateTime(date.year, date.month, date.day + 1);
  }
  return date;
}

class CalendarPage extends StatefulWidget {
  const CalendarPage({Key? key}): super(key: key);
  @override
  State<CalendarPage> createState() => _CalendarPageSate();
}

class _CalendarPageSate extends State<CalendarPage> {
  double cellWidth = 0;
  double cellHeight = 40;
  DateTime schoolYearStart = DateTime(DateTime.now().year - (DateTime.now().month < 9 ? 1 : 0), 9, 1);
  ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    super.dispose();
    _scrollController.dispose();
  }

  @override
  Widget build (BuildContext context) {
    List<Map> events = List.from((storage.get('events')?['Events'] ?? []));
    List tasks = storage.get('tasks')?['Tasks'] ?? [];
    events.addAll(tasks.map((e) => Map.from(e)).toList());
    final mappedEvents = eventListToDateMap(events);
    cellWidth = MediaQuery.of(context).size.width / 8;
    _scrollController = ScrollController(initialScrollOffset: DateTime.now().difference(schoolYearStart).inDays.abs() ~/ 7 * cellHeight + cellHeight);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Kalendář'),
      ),
      body: loadScrollSnacksWrapper(context,
        controller: _scrollController,
        child: Column(
          children: [
            Row(
              children: [
                SizedBox(width: cellWidth, height: cellHeight, child: const Text('')),
                ...List.generate(7, (dayIndex) {
                  return SizedBox(
                    width: cellWidth,
                    height: cellHeight,
                    child: ElevatedButton(
                      onPressed: () {},
                      style: ButtonStyle(
                        backgroundColor: MaterialStatePropertyAll(dayIndex > 4 ? Colors.indigo.shade800: Colors.blue.shade900),
                        padding: const MaterialStatePropertyAll(EdgeInsets.all(0)),
                      ),
                      child: Text(const ['Po', 'Út', 'St', 'Čt', 'Pá', 'So', 'Ne'][dayIndex]),
                    ),
                  );
                }),
              ]
            ),
            ...List.generate(DateTime(schoolYearStart.year + 1, 6, 30).difference(schoolYearStart).inDays.abs() ~/ 7 + 1, (rowIndex) {
              return Row(
                children: [
                  SizedBox(
                    width: cellWidth,
                    height: cellHeight,
                    child: ElevatedButton(
                      onPressed: () {},
                      style: ButtonStyle(
                        backgroundColor: MaterialStatePropertyAll(Colors.blue.shade900),
                        padding: const MaterialStatePropertyAll(EdgeInsets.all(0)),
                      ),
                      child: Text(weekNumber(schoolYearStart.add(Duration(days: 7*rowIndex-1))).toString()), 
                    )
                  ),
                  ...List.generate(7, (colIndex) {
                    int dayOffset = 7*rowIndex+colIndex-(schoolYearStart.weekday-1)%7;
                    DateTime date = roundDateTime(schoolYearStart.add(Duration(days: dayOffset)));
                    // List localEvents = events.where((element) => isEventInvolved(element, date),).toList();
                    List<Map> localEvents = mappedEvents[date.toIso8601String().split('T').first] ?? [];
                    return SizedBox(
                      width: cellWidth,
                      height: cellHeight,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.push(context, MaterialPageRoute(builder: (context) => DayPage(date)));
                        },
                        onLongPress: () async {
                          await showDialog(context: context, builder: (context) => TaskDialog(newTime: date,));
                          setState(() {});
                        },
                        style: ButtonStyle(
                          backgroundColor: MaterialStatePropertyAll(
                            (date.day == DateTime.now().day && date.month == DateTime.now().month && date.year == DateTime.now().year)
                            ? Colors.lightBlue
                            : date.weekday > 5 
                            ? (
                              date.month % 2 == 0
                              ? Colors.indigo.shade800
                              : Colors.indigo.shade700
                            )
                            : (
                              date.month % 2 == 0
                              ? Colors.blue.shade800
                              : Colors.blue.shade700
                            )
                          ),
                          padding: const MaterialStatePropertyAll(EdgeInsets.all(0)),
                        ),  
                        child: Column(
                          children: [
                            Text(date.day == 1 ? '[ ${date.month} ]' : date.day.toString()),
                            Wrap(
                              alignment: WrapAlignment.center,
                              direction: Axis.horizontal,
                              children: localEvents.length < 3
                              ? ([for (var event in localEvents) Icon(event.containsKey('time') ? Icons.tornado_rounded : Icons.event, size: 15,)])
                              : [Icon(localEvents[0].containsKey('time') ? Icons.tornado_rounded : Icons.event, size: 15,), const Text('...')]
                            )
                          ],
                        ),
                      ),
                    );
                  })
                ]
              );
            }),
          ],
        ),
      ),
    );
  }
}