import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:kleofas2/settings.dart';
import 'events.dart';
import 'package:intl/intl.dart';
import 'storage.dart';
import 'dart:math';
import 'dart:convert';
import 'custom_icons.dart';
// import 'package:flutter/foundation.dart';

const List<String> czWeekDayNames = ['Ne', 'Po', 'Út', 'St', 'Čt', 'Pá', 'So', 'Ne'];

DateTime roundDateTime (DateTime date) {
  if (date.hour > 12) {
    return DateTime(date.year, date.month, date.day + 1);
  }
  return date;
}

String formatczDate(DateTime date) {
  Duration dif = date.difference(DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day));
  String durString = '';
  if (dif.isNegative) {
    dif = dif.abs();
    if (dif.inDays < 1) {
      durString = 'dnes';
    } else if (dif.inDays < 2) {
      durString = 'včera';
    } else if (dif.inDays < 8) {
      durString = 'před ${dif.inDays} dny';
    } else if ((dif.inDays / 7).round() < 4) {
      if ((dif.inDays / 7).round() == 1) {
        durString = 'před týdnem';
      } else {
        durString = 'před ${(dif.inDays / 7).round()} týdny';
      }
    } else if (dif.inDays < 365) {
      if ((dif.inDays / 28).round() == 1) {
        durString = 'před měsícem';
      } else {
        durString = 'před ${(dif.inDays / 30).round()} měsíci';
      }
    } else {
      if ((dif.inDays / 365).round() == 1) {
        durString = 'před rokem';
      } else {
        durString = 'před ${(dif.inDays / 365).round()} lety';
      }
    }
  } else {
    if (dif.inDays < 1) {
      durString = 'dnes';
    } else if (dif.inDays < 2) {
      durString = 'zítra';
    } else if (dif.inDays < 5) {
      durString = 'za ${dif.inDays} dny';
    } else if (dif.inDays < 8) {
      durString = 'za ${dif.inDays} dní';
    } else if ((dif.inDays / 7).round() < 4) {
      if ((dif.inDays / 7).round() == 1) {
        durString = 'za týden';
      } else {
        durString = 'za ${(dif.inDays / 7).round()} týdny';
      }
    } else if (dif.inDays < 365) {
      if ((dif.inDays / 28).round() == 1) {
        durString = 'za měsíc';
      } else if ((dif.inDays / 28).round() < 5) {
        durString = 'za ${(dif.inDays / 30).round()} měsíce';
      } else {
        durString = 'za ${(dif.inDays / 30).round()} měsíců';
      }
    } else {
      if ((dif.inDays / 365).round() == 1) {
        durString = 'za rok';
      } else if ((dif.inDays / 365).round() < 5) {
        durString = 'za ${(dif.inDays / 365).round()} roky';
      } else {
        durString = 'za ${(dif.inDays / 365).round()} let';
      }
    }
  }
  return durString;
}

class DayWidget extends StatelessWidget {
  final DateTime date;
  final bool year;
  final EventType? eventType;
  const DayWidget(this.date, {this.year = false, super.key, this.eventType});

  @override
  Widget build (BuildContext context) {
    return OutlinedButton(
      onPressed: () {Navigator.push(context, MaterialPageRoute(builder: (context) => DayPage(date)));},
      child: RichText(
        text: TextSpan(
          children: [
            TextSpan(text: '${czWeekDayNames[date.weekday]} ${DateFormat(year ? 'd. M. y' : 'd. M.').format(date)}', style: const TextStyle(
              color: Colors.blue,
              fontWeight: FontWeight.bold
            )),
            TextSpan(text: '  ( ${formatczDate(date)} )', style: const TextStyle(
              fontSize: 10,
              color: Colors.grey,
            ))
          ]
        ),
      )
    );
  }
}

class DayPage extends StatefulWidget {
  final DateTime date;
  final String? teacherId;
  final EventType eventType;
  const DayPage(this.date, {super.key, this.teacherId, this.eventType = EventType.my});
  @override
  State<DayPage> createState() => _DayPageSate();
}

class _DayPageSate extends State<DayPage> {
  bool timeTableLoaded = false;

  Widget hourCell (Map? hour, Map subjects, Map rooms, Map teachers, Map groups, double height, bool current) {
    return SizedBox(
      height: height,
      width: height,
      child: ElevatedButton(
        onPressed: (hour == null) ? () {} : () {
          showDialog(context: context, builder: (BuildContext context) {
            return AlertDialog(
              title: const Text('Hodina'),
              content: Text('Skupiny: ${hour["GroupIds"]?.map((item) => groups[item]["Abbrev"]).join(" ")}\nPředmět: ${subjects[hour["SubjectId"]]?["Name"]}\nUčitel: ${teachers[hour["TeacherId"]]?["Name"]}\nUčebna: ${rooms[hour["RoomId"]]?["Name"]}\nTéma: ${hour["Theme"]}\nZměna: ${hour["Change"] == null ? '' : '\n  Změna předmětu: ${hour["Change"]["ChangeSubject"]}\n  Den: ${czDate(hour["Change"]["Day"])}\n  Hodiny: ${hour["Change"]["Hours"]}\n  Typ změny: ${hour["Change"]["ChangeType"]}\n  Popis: ${hour["Change"]["Description"]}\n  Čas: ${hour["Change"]["Time"]}\n  Zkratka typu: ${hour["Change"]["TypeAbbrev"]}\n  Název typu: ${hour["Change"]["TypeName"]}'}'),
              actions: [
                TextButton(onPressed: () {Navigator.pop(context);}, child: const Text('Ok'))
              ],
            );
          });
        },
        style: ButtonStyle(
          padding: const MaterialStatePropertyAll(EdgeInsets.all(3)),
          shape: MaterialStatePropertyAll(RoundedRectangleBorder(borderRadius: BorderRadius.circular(5))
          ),
          backgroundColor: MaterialStatePropertyAll(
            hour?['Change'] != null
            ? (current
              ? Colors.lightBlue
              : Colors.grey.shade700
            )
            : hour == null || hour['TeacherId'] == null
              ? const Color.fromARGB(255, 48, 48, 48)
              : (current
                ? Colors.blue.shade800
                : Colors.grey.shade800
              )
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              (hour == null || hour['TeacherId'] == null) ? '' : subjects[hour['SubjectId']]?['Abbrev'] ?? '?',
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700
              ),
            ),
            Text(
              (hour == null || hour['TeacherId'] == null) ? '' : rooms[hour['RoomId']]['Abbrev'] ?? '?',
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w500
              ),
            ),
          ],
        ),
        // child: Column(
        //   mainAxisAlignment: MainAxisAlignment.center,
        //   crossAxisAlignment: CrossAxisAlignment.start,
        //   children: [
        //     Text(
        //       (hour == null || hour['TeacherId'] == null) ? '' : subjects[hour['SubjectId']]?['Abbrev'] ?? 'null',
        //       style: const TextStyle(
        //         fontWeight: FontWeight.w900,
        //         fontSize: 20,
        //       ),
        //     ),
        //     Text(
        //       (hour == null || hour['TeacherId'] == null) ? '' : (teachers[hour['TeacherId']]['Abbrev'] ?? 'null') + '\n' + (rooms[hour['RoomId']]['Abbrev'] ?? 'null') + '\n' + (groups[hour['GroupIds'][0]]['Abbrev'] ?? 'null'),
        //       textAlign: TextAlign.left,
        //       style: const TextStyle(
        //         fontWeight: FontWeight.w500,
        //         fontSize: 12,
        //       ),
        //     ),
        //   ],
        // )
      ),
    );
  }

  @override
  Widget build (BuildContext context) {
    List events = List.from(storage.get(widget.teacherId == null ? (switch (widget.eventType) {
          EventType.my => "events",
          EventType.all => "events:all",
          EventType.public => "events:public",
        }) : 'events:all')?['Events'] ?? []);
    events.addAll(storage.get('tasks')?['Tasks'] ?? []);
    if (widget.teacherId != null) {
      events = events.where((element) => element.toString().contains(widget.teacherId!)).toList();
    }
    events = events.where((element) => isEventInvolved(element, widget.date),).toList();
    return Scaffold(
      appBar: AppBar(
        title: Text('${czWeekDayNames[widget.date.weekday]} ${DateFormat('d. M. y').format(widget.date)}, ${formatczDate(widget.date)}'),
        actions: [
                IconButton(onPressed: () {
                  Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) =>
                    DayPage(
                      widget.date.subtract(const Duration(days: 1)),
                      teacherId: widget.teacherId,
                      eventType: widget.eventType,
                    )
                  ));
                  },
                  icon: const Icon(Icons.swipe_left),
                ),
                IconButton(onPressed: () {
                  Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) =>
                    DayPage(
                      widget.date.add(const Duration(days: 1)),
                      teacherId: widget.teacherId,
                      eventType: widget.eventType,
                    )
                  ));
                }, icon: const Icon(Icons.swipe_right)),
        ],
      ),
      body: loadScrollSnacksWrapper(context,
        child: Column(
          // crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (widget.date.weekday < 6 && !timeTableLoaded) Padding(
              padding: const EdgeInsets.all(8.0),
              child: OutlinedButton(
                onPressed: () {
                  loadEndpointSnack('timetable:temp', url: 'timetable/actual', payload: {'date': DateFormat('yyyy-MM-dd').format(widget.date)});
                  setState(() {
                    timeTableLoaded = true;
                  });
                },
                child: const Text('Načíst rozvrh')
              ),
            ),
            if (timeTableLoaded) ValueListenableBuilder(
            valueListenable: storage.listenable(),
            builder: (BuildContext context, Box<Map> value, child) {
              List getElem (String name) => value.get('timetable:temp')?[name] ?? [];
              List hours = getElem('Hours');
              List days = getElem('Days');
              // hours = hours.sublist(max(0, hours.indexWhere((element) => days[widget.date.weekday-1]['Atoms'].any((atom) => atom['HourId'] == element['Id']))), hours.lastIndexWhere((element) => days[widget.date.weekday-1]['Atoms'].any((atom) => atom['HourId'] == element['Id'])) + 1);
              hours = hours.sublist(max(0, hours.indexWhere((element) => days.any((day) => day['Atoms'].any((atom) => atom['HourId'] == element['Id'])))), hours.lastIndexWhere((element) => days.any((day) => day['Atoms'].any((atom) => atom['HourId'] == element['Id']))) + 1);
              if (hours.isEmpty) {
                return Text('${days[widget.date.weekday-1]['DayType']}: ${days[widget.date.weekday-1]['DayDescription']}');
              }
              // Map groups = mapListToMap(getElem('Groups'));
              Map subjects = mapListToMap(getElem('Subjects'));
              // Map teachers = mapListToMap(getElem('Teachers'));
              Map rooms = mapListToMap(getElem('Rooms'));
              return SizedBox(
                width: min(MediaQuery.of(context).size.width/10, 50.0)*hours.length,
                child: Table(
                  children: List.generate(5, (index) {
                    double height = min(MediaQuery.of(context).size.width/10, 50.0);
                    bool current = widget.date.weekday == index+1;
                    return TableRow(
                      children: [
                        SizedBox(
                          width: height,
                          height: height,
                          child: ElevatedButton(
                            onPressed: () {
                              if (!current) {
                                Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => DayPage(roundDateTime(DateTime.parse(days[index]['Date'])))));
                              }
                            },
                            style: ButtonStyle(
                              padding: const MaterialStatePropertyAll(EdgeInsets.all(3)),
                              shape: MaterialStatePropertyAll(RoundedRectangleBorder(borderRadius: BorderRadius.circular(5))
                              ),
                              backgroundColor: MaterialStatePropertyAll(current
                                ? Colors.blue.shade900
                                : Colors.grey.shade800
                              )
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  czWeekDayNames[index+1],
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700
                                  ),
                                ),
                                Text(
                                  DateFormat('d.M.').format(roundDateTime(DateTime.parse(days[index]['Date']))),
                                  style: const TextStyle(
                                    fontSize: 9,
                                    fontWeight: FontWeight.w500
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        ...List.generate(
                          hours.length, (index2) {
                            Map? hour = mapListToMap(days[index]['Atoms'], id: 'HourId')[hours[index2]['Id']];
                            return SizedBox(
                              height: height,
                              width: height,
                              child: ElevatedButton(
                                onPressed: (hour == null) ? () {} : () {
                                  showDialog(context: context, builder: (BuildContext context) {
                                    return AlertDialog(
                                      title: const Text('Hodina'),
                                      // content: Text('Skupiny: ${hour["GroupIds"]?.map((item) => groups[item]["Abbrev"]).join(" ")}\nPředmět: ${subjects[hour["SubjectId"]]?["Name"]}\nUčitel: ${teachers[hour["TeacherId"]]?["Name"]}\nUčebna: ${rooms[hour["RoomId"]]?["Name"]}\nTéma: ${hour["Theme"]}\nZměna: ${hour["Change"] == null ? '' : '\n  Změna předmětu: ${hour["Change"]["ChangeSubject"]}\n  Den: ${czDate(hour["Change"]["Day"])}\n  Hodiny: ${hour["Change"]["Hours"]}\n  Typ změny: ${hour["Change"]["ChangeType"]}\n  Popis: ${hour["Change"]["Description"]}\n  Čas: ${hour["Change"]["Time"]}\n  Zkratka typu: ${hour["Change"]["TypeAbbrev"]}\n  Název typu: ${hour["Change"]["TypeName"]}'}'),
                                      content: SingleChildScrollView(
                                        scrollDirection: Axis.horizontal,
                                        child: Text(const JsonEncoder.withIndent('    ').convert(hour)
                                          .replaceAppendAll('"${hour['TeacherId'] ?? '?'}"', ' - "${getId(hour['TeacherId']).name}"')
                                          .replaceAppendAll('"${hour['RoomId'] ?? '?'}"', ' - "${getId(hour['RoomId']).abbrev}"')
                                          .replaceAppendAll('"${hour['SubjectId'] ?? '?'}"', ' - "${getId(hour['SubjectId']).name}"')
                                          .replaceAppendMap({for (String groupId in hour['GroupIds'] ?? []) '"$groupId"': ' - "${getId(groupId).abbrev}"'})
                                        ),
                                      ),
                                      actions: [
                                        TextButton(onPressed: () {Navigator.pop(context);}, child: const Text('Ok'))
                                      ],
                                    );
                                  });
                                },
                                style: ButtonStyle(
                                  padding: const MaterialStatePropertyAll(EdgeInsets.all(3)),
                                  shape: MaterialStatePropertyAll(RoundedRectangleBorder(borderRadius: BorderRadius.circular(5))
                                  ),
                                  backgroundColor: MaterialStatePropertyAll(
                                    hour?['Change'] != null
                                    ? (current
                                      ? ( hour?['Change']?['TypeAbbrev'] == null
                                        ? Colors.lightBlue
                                        : Colors.lightBlue.shade600 )
                                      : Colors.grey.shade700
                                    )
                                    : hour == null || hour['TeacherId'] == null
                                      ? const Color.fromARGB(255, 48, 48, 48)
                                      : (current
                                        ? Colors.blue.shade800
                                        : Colors.grey.shade800
                                      )
                                  ),
                                ),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      (hour == null || hour['TeacherId'] == null) ? (hour?["Change"]?["TypeAbbrev"] ?? '') : subjects[hour['SubjectId']]?['Abbrev'] ?? 'null',
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w700
                                      ),
                                    ),
                                    Text(
                                      (hour == null || hour['TeacherId'] == null) ? '' : rooms[hour['RoomId']]['Abbrev'] ?? '?',
                                      style: const TextStyle(
                                        fontSize: 9,
                                        fontWeight: FontWeight.w500
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }
                        )
                      ]
                    );
                  }),
                ),
              );
            }
          ),
          const Divider(),
          ...[ for (Map event in events)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: ElevatedButton(
                style: const ButtonStyle(
                  padding: MaterialStatePropertyAll(EdgeInsets.all(10))
                ),
                onPressed: () async {
                  if (event.containsKey('time')) {
                    await showDialog(context: context, builder: (context) => TaskDialog(task: event,));
                    setState(() {});
                  } else {
                    await showDialog(context: context, builder: (BuildContext context) => AlertDialog(
                      title: Text(event['Title'].toString()),
                      content: eventWidget(context, event),
                      actions: [
                        OutlinedButton(onPressed: () {Navigator.pop(context);}, child: const Text('Close')),
                      ],
                    ));
                  }
                },
                onLongPress: () async {
                  if (event.containsKey('time')) {
                    await showDialog(context: context, builder: (context) => TaskDialog(task: event,));
                    setState(() {});
                  } else {
                    showDialog(context: context, builder: (context) => eventDialog(event, context));
                  }
                },
                child: Row(
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: Icon(event.containsKey('time') ? allIconsMap[getId(event["stream"]).name] ?? Icons.tornado_rounded : Icons.event, size: 30,),
                    ),
                    Expanded(child: Text((event.containsKey('time') ? '${event['subject'] ?? '?'} - ' : '') + (event.containsKey('time') ? event['title'] : event['Title']), style: const TextStyle(fontSize: 14), overflow: TextOverflow.ellipsis, maxLines: 1,))
                  ],
                )
              ),
            )
          ],
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: OutlinedButton(
              onPressed: () async {
                await showDialog(context: context, builder: (context) => TaskDialog(newTime: widget.date,),);
                setState(() {});
              },
              child: const Text("Přidat task"),
            ),
          ),
          ],
        ),
      ),
    );
  }
}
  
