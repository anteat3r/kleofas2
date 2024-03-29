import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'storage.dart';
import 'package:intl/intl.dart';
import 'day.dart';
import 'dart:convert';

AlertDialog eventDialog(Map event, BuildContext context) => AlertDialog(
    title: const Text('Event'),
    content: SingleChildScrollView(child: SingleChildScrollView(scrollDirection: Axis.horizontal, child: SingleChildScrollView(scrollDirection: Axis.horizontal, child: Text(const JsonEncoder.withIndent(' ').convert(event))))),
    actions: [
      TextButton(
        onPressed: () {
          Navigator.of(context).pop();
        },
        child: const Text('Ok')
      ),
    ],
  );

class EventsPage extends StatefulWidget {
  const EventsPage({super.key});
  @override
  State<EventsPage> createState() => _EventsPageState();
}

class _EventsPageState extends State<EventsPage> {
  bool showTasks = false;
  String stringFilter = '';
  DateTime? dateFilter;
  final stringFilterController = TextEditingController();
  DateTime? appliedDateFilter;
  String currentPath = 'events';

  @override
  Widget build(BuildContext context) {
    AppBar appBar = AppBar(
      title: const Text('Events'),
      actions: [
        Switch(
          value: showTasks,
          onChanged: (bool newvalue) {
            setState(() {
              showTasks = newvalue;
            });
          }),
        IconButton(
          onPressed: () {
            setState(() {
              loadEndpointSnack('events', url: 'events/my');
            });
          },
          icon: const Icon(Icons.refresh_rounded)
        ),
      ],
    );
    return Scaffold(
      appBar: appBar,
      body: loadScrollSnacksWrapper(
        context,
        child: Column(
          children: [
            ValueListenableBuilder(
              valueListenable: refresh.listenable(),
              builder: (BuildContext context, Box<int> value, child) {
                return Text(czDate(DateTime.fromMillisecondsSinceEpoch(value.get(currentPath) ?? 0).toString()));
              }
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                OutlinedButton(
                  onPressed: () {
                    loadEndpointSnack('events', url: 'events/my');
                    currentPath = 'events';
                  },
                  child: const Text('Load My'),
                ),
                OutlinedButton(
                  onPressed: () {
                    loadEndpointSnack('events:all', url: 'events');
                    currentPath = 'events:all';
                  },
                  child: const Text('Load All'),
                ),
                OutlinedButton(
                  onPressed: () {
                    loadEndpointSnack('events:public', url: 'events/public');
                    currentPath = 'events:public';
                  },
                  child: const Text('Load Public'),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: TextField(
                controller: stringFilterController,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: 'Filter'
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                children: [
                  Checkbox(
                    value: dateFilter != null,
                    onChanged: (value) {
                      if (value == null) return;
                      setState(() {
                        dateFilter = value ? DateTime.now() : null;
                      });
                    },
                  ),
                  if (dateFilter != null)
                  OutlinedButton(
                    onPressed: () async {
                      dateFilter = await showDatePicker(
                        context: context,
                        initialDate: dateFilter ?? DateTime.now(),
                        firstDate: DateTime(1969),
                        lastDate: DateTime(2069)
                      ) ?? dateFilter;
                      setState(() {});
                    },
                    child: Text(dateFilter == null ? '' : DateFormat('d. M. y').format(dateFilter!))
                  )
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(left: 8.0),
              child: OutlinedButton(
                onPressed: () {
                  setState(() {
                    stringFilter = stringFilterController.text;
                    if (dateFilter != null) {
                      appliedDateFilter = DateTime.fromMillisecondsSinceEpoch(dateFilter!.millisecondsSinceEpoch).copyWith(
                        minute: 0,
                        second: 0,
                        millisecond: 0,
                        microsecond: 0,
                      );
                    } else {
                      appliedDateFilter = null;
                    }
                  });
                },
                child: const Text('Apply')
              ),
            ),
            ValueListenableBuilder(
              valueListenable: storage.listenable(),
              builder: (BuildContext context, Box<Map> storage_, child) {
                List events = List.from(storage_.get(currentPath)?['Events'] ?? []);
                // events.addAll(storage_.get('tasks')?['Tasks'] ?? []);
                return Column(children: <Widget>[
                  ...List.generate(events.length, (index) {
                    Map event = events[index];
                    if (!event.toString().contains(stringFilter)) return <Widget>[];
                    if (appliedDateFilter != null) {
                      if (!event.toString().contains(DateFormat('yyyy-MM-dd').format(appliedDateFilter!))) return <Widget>[];
                    }
                    return [
                      Padding(
                        padding: const EdgeInsets.only(left: 8.0, right: 8.0, top: 5.0),
                        child: eventWidget(context, event),
                      )
                    ];
                  }).expand((e) => e),
                ]);
              }
            )
          ],
        ),
      ),
    );
  }
}

OutlinedButton eventWidget(BuildContext context, Map<dynamic, dynamic> event) {
  return OutlinedButton(
  style: ButtonStyle(
    textStyle: MaterialStatePropertyAll(TextStyle(
      foreground: Paint()..color = Colors.white
    )),
  ),
  onPressed: () {
    showDialog(context: context, builder: (BuildContext context) => eventDialog(event, context));
  },
  child: Padding(
    padding: const EdgeInsets.only(
      top: 6.0,
      right: 6.0,
      bottom: 6.0,
    ),
    child: Column(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.only(right: 8.0),
          child: Text(
            event['Title'].toString(),
            style: const TextStyle(
              fontSize: 30,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(right: 8.0),
          child: Text(
            event['Description'].toString(),
          ), // style: TextStyle(fontSize: 30, fontWeight: FontWeight.w500, foreground: Paint()..color = Colors.red),),
        ),
        ...List.generate(event['Times'].length,
            (index) {
          Map time = event['Times'][index];
          if (time['WholeDay']) {
            return Padding(
              padding: const EdgeInsets.only(top: 8.0, bottom: 8.0, right: 8.0),
              child: DayWidget(DateTime.parse(time['StartTime']).toLocal())
              // child: Text(time['StartTime'])); 
            );
          } else {
            return Padding(
              padding: const EdgeInsets.only(top: 8.0, bottom: 8.0),
              child: Wrap(
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  DayWidget(DateTime.parse(time['StartTime']).toLocal()),
                  Text('     ${DateFormat('HH : mm').format(DateTime.parse(time['StartTime']).toLocal())} - ${DateFormat('HH :mm').format(DateTime.parse(time['EndTime']).toLocal())}'),
                ],
              )
            );
          }
        }),
        if (event['Teachers'].isNotEmpty) RichText(
          text: TextSpan(
            children: [
              const TextSpan(
                text: 'Učitelé: ',
                style: TextStyle(
                  fontWeight: FontWeight.bold
                ),
              ),
              TextSpan(
                text: event['Teachers'].map((e) => e['Name']).join(', '),
              )
            ]
          )
        ),
        if (event['Classes'].isNotEmpty) RichText(
          text: TextSpan(
            children: [
              const TextSpan(
                text: 'Třídy: ',
                style: TextStyle(
                  fontWeight: FontWeight.bold
                ),
              ),
              TextSpan(
                text: event['Classes'].map((e) => e['Abbrev']).join(', '),
              )
            ]
          )
        ),
        if (event['Students'].isNotEmpty) RichText(
          text: TextSpan(
            children: [
              const TextSpan(
                text: 'Studenti: ',
                style: TextStyle(
                  fontWeight: FontWeight.bold
                ),
              ),
              TextSpan(
                text: event['Students'].map((e) => e['Name']).join(', '),
              )
            ]
          )
        ),
        if (event['Rooms'].isNotEmpty) RichText(
          text: TextSpan(
            children: [
              const TextSpan(
                text: 'Místnosti: ',
                style: TextStyle(
                  fontWeight: FontWeight.bold
                ),
              ),
              TextSpan(
                text: event['Rooms'].map((e) => e['Abbrev']).join(', '),
              )
            ]
          )
        ),
      ],
    ),
  ));
}
