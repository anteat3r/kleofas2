import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'storage.dart';
import 'package:intl/intl.dart';
import 'day.dart';

AlertDialog eventDialog (Map event, BuildContext context) {
  return AlertDialog(
    title: const Text('Event'),
    content: SingleChildScrollView(child: Text('Title: ${event["Title"]}\nDescription: ${event["Description"]}\nEvent Type:\n\tAbbrev: ${event["EventType"]["Abbrev"]}\n\tName: ${event["EventType"]["Name"]}\nNote: ${event["Note"]}\nDate Changed: ${czDate(event["DateChanged"])}\nTimes:${event["Times"].map((e) => "\n\tTime:\n\t\tWhole Day: ${e['WholeDay']}\n\t\tStart Time: ${czDate(e['StartTime'])}\n\t\tEnd Time: ${czDate(e['EndTime'])}\n\t\tInterval Start Time: ${czDate(e['IntervalStartTime'])}\n\t\tInterval End Time: ${czDate(e['IntervalEndTime'])}").join("\n\t")}\nClasses:${event["Classes"].map((e) => "\n\tClass:\n\t\tAbbrev: ${e['Abbrev']}\n\t\tName: ${e['Name']}").join("\n\t")}\nClass Sets: TODO\nTeachers:${event["Teachers"].map((e) => "\n\tTeacher:\n\t\tAbbrev: ${e['Abbrev']}\n\t\tName: ${e['Name']}").join("\n\t")}\nTeacher Sets: TODO\nRooms:${event["Rooms"].map((e) => "\n\tRoom:\n\t\tAbbrev: ${e['Abbrev']}\n\t\tName: ${e['Name']}").join("\n\t")}\nRoom Sets: TODO\nStudents:${event["Students"].map((e) => "\n\tName: ${e['Name']}").join("\n\t")}')),
    actions: [
      if (event['Id'].contains('K:')) TextButton(onPressed: () {
        loadingDialog(context, () async {
          final NavigatorState navigator = Navigator.of(context);
          if (!hasPassword("kleofas", "username") || !hasPassword("klefoas", "password")) return;
          await pb.collection('users').authWithPassword(getPassword("bakalari", "username"), getPassword("bakalari", "password"));
          await pb.collection('tasks').delete(event['KleoId']);
          navigator.pop(navigator);
        });
      }, child: const Text('Delete')),
      TextButton(onPressed: () {Navigator.of(context).pop();}, child: const Text('Ok')),
    ],
  );
}

class EventsPage extends StatefulWidget{
  const EventsPage({Key? key}) : super(key: key);
  @override
  State<EventsPage> createState() => _EventsPageState();
}

class _EventsPageState extends State<EventsPage> {
  bool showTasks = true;

  @override
  Widget build (BuildContext context) {
    AppBar appBar = AppBar(
      title: const Text('Events'),
      actions: [
        Switch(
          value: showTasks,
          onChanged: (bool newvalue) {
            setState(() {
              showTasks = newvalue;
            });
          }
        ),
        IconButton(
          onPressed: () {
            setState(() {
              loadTasks(context);
            });
          },
          icon: const Icon(Icons.task_rounded)
        ),
        IconButton(
          onPressed: () {
            setState(() {
              loadEndpoint(context, 'events', 'events/${user.get('event_type')?.split(".")[1] ?? "my"}');
            });
          },
          icon: const Icon(Icons.refresh_rounded)
        ),
      ],
    );
    return Scaffold(
      appBar: appBar,
      body: SingleChildScrollView(
        child: Column(
          children: [
            ValueListenableBuilder(
              valueListenable: refresh.listenable(),
              builder: (BuildContext context, Box<int> value, child) {
                return Text(czDate(DateTime.fromMillisecondsSinceEpoch(value.get('events') ?? 0).toString()));
              }
            ),
            ValueListenableBuilder(
              valueListenable: storage.listenable(),
              builder: (BuildContext context, Box<Map> value, child) {
                List events = List.from(value.get('events')?['Events'] ?? []);
                if (showTasks) {
                  events.addAll(value.get('tasks')?['Tasks'] ?? []);
                }
                return Column(
                  children: [
                    ...List.generate(events.length, (index) {
                      Map event = events[index];
                      return Padding(
                        padding: const EdgeInsets.only(left: 8.0, right: 8.0, top: 5.0),
                        child: OutlinedButton(
                          style: ButtonStyle(
                            textStyle: MaterialStatePropertyAll(TextStyle(foreground: Paint()..color = Colors.white)),
                          ),
                          onPressed: () {
                            showDialog(context: context, builder: (BuildContext context) {
                              return eventDialog(event, context);
                            });
                          },
                          child: Padding(
                            padding: const EdgeInsets.only(top: 6.0, right: 6.0, bottom: 6.0,),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.start,
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: <Widget>[
                                Padding(
                                  padding: const EdgeInsets.only(right: 8.0),
                                  child: Text(event['Title'].toString(), style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w500,),),
                                ),
                                Padding(
                                  padding: const EdgeInsets.only(right: 8.0),
                                  child: Text(event['Description'].toString(),),// style: TextStyle(fontSize: 30, fontWeight: FontWeight.w500, foreground: Paint()..color = Colors.red),),
                                ),
                                ...List.generate(event['Times'].length, (index) {
                                  Map time = event['Times'][index];
                                  if (time['WholeDay']) {
                                    return Padding(
                                      padding: const EdgeInsets.all(8.0),
                                      // child: DayWidget(DateTime.parse(time['StartTime']))
                                      child: Text(time['StartTime'])
                                    );
                                  } else {
                                    return Padding(
                                      padding: const EdgeInsets.all(8.0),
                                      child: Row(
                                        children: [
                                          DayWidget(DateTime.parse(time['StartTime'])),
                                          Text('   ${DateFormat('HH:MM:ss').format(DateTime.parse(time['StartTime']))} - ${DateFormat('HH:MM:ss').format(DateTime.parse(time['EndTime']))}'),
                                        ],
                                      )
                                    );
                                  }
                                })
                              ],
                            ),
                          )
                        ),
                      );
                    }),
                  ]
                );
              }
            )
          ],
        ),
      ),
    );
  }

}