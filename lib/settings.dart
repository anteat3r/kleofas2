import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pocketbase/pocketbase.dart';
import 'storage.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({Key? key}) : super(key: key);
  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

enum Gender { civilAttackHelicopter }
enum EventType { my, all, public }

class _SettingsPageState extends State<SettingsPage> {
  bool passwordVisible = false;
  bool autoreload = false;
  EventType eventType = EventType.my;
  String qrpath = "";
  TextEditingController notifdurcontroller = TextEditingController();
  TextEditingController notifstartcontroller = TextEditingController();
  TextEditingController notifendcontroller = TextEditingController();
  Map<String, String> streams = {};
  final addStreamController = TextEditingController();

  void loadStreamTitles () async {
    for (var key in streams.keys) {
      try {
        streams[key] = (await pb.collection('streams').getOne(key)).data['title'];
      } on ClientException catch (_) {
        streams[key] = 'NEEXISTUJE';
      }
    }
    setState(() {});
  }

  @override
  void initState() {
    super.initState();
    qrpath = user.get('qrpath') ?? '';
    autoreload = (user.get('autoreload') ?? '').isNotEmpty;
    notifdurcontroller.text = user.get("notifdur") ?? "15";
    notifstartcontroller.text = user.get("notifstart") ?? "6";
    notifendcontroller.text = user.get("notifend") ?? "22";
    streams = {for (final stream in user.get('streams')?.split(' ') ?? []) stream: ''};
    if (user.get('event_type') == null) return;
    if (user.get('event_type') == 'EventType.my') {
      eventType = EventType.my;
    } else if (user.get('event_type') == 'EventType.all') {
      eventType = EventType.all;
    } else {
      eventType = EventType.public;
    }
    loadStreamTitles();
  }

  @override
  Widget build(BuildContext context) {
    AppBar appBar = AppBar(
      title: const Text('Settings'),
    );
    return Scaffold(
      appBar: appBar,
      body: loadScrollSnacksWrapper(context,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.all(8.0),
              child: Text('Načítat události:'),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: ListTile(
                title: const Text('my'),
                leading: Radio<EventType>(
                  value: EventType.my,
                  groupValue: eventType,
                  onChanged: (EventType? value) {
                    if (value == null) return;
                    setState(() {
                      eventType = EventType.my;
                    });
                  },
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: ListTile(
                title: const Text('all'),
                leading: Radio<EventType>(
                  value: EventType.all,
                  groupValue: eventType,
                  onChanged: (EventType? value) {
                    if (value == null) return;
                    setState(() {
                      eventType = EventType.all;
                    });
                  },
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: ListTile(
                title: const Text('public'),
                leading: Radio<EventType>(
                  value: EventType.public,
                  groupValue: eventType,
                  onChanged: (EventType? value) {
                    if (value == null) return;
                    setState(() {
                      eventType = EventType.public;
                    });
                  },
                ),
              ),
            ),
            const Padding(
              padding: EdgeInsets.all(8.0),
              child: Text('Pohlaví'),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: ListTile(
                title: const Text('Útočná helikoptéra'),
                leading: Radio<Gender>(
                  value: Gender.civilAttackHelicopter,
                  groupValue: Gender.civilAttackHelicopter,
                  onChanged: (Gender? value) {},
                ),
              ),
            ),
            const Padding(
              padding: EdgeInsets.all(8.0),
              child: Text('Qr kód'),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: OutlinedButton(
                  onPressed: () async {
                    final res = await FilePicker.platform.pickFiles();
                    if (res == null) return;
                    qrpath = res.files.single.path ?? "";
                  },
                  child: const Text("Vybrat soubor")),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: ListTile(
                title: const Text('Auto Reload'),
                leading: Checkbox(
                  value: autoreload,
                  onChanged: (bool? value) {
                    if (value == null) return;
                    setState(() {
                      autoreload = value;
                    });
                  },
                ),
              ),
            ),
            const Padding(
              padding: EdgeInsets.all(8.0),
              child: Text('Streamy'),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: StatefulBuilder(builder: (context, setState2) {
                return Column(
                  children: [
                    ...streams.keys.map((stream) => Row(
                      children: [
                        RichText(text: TextSpan(children: [
                          TextSpan(text: streams[stream] ?? '?'),
                          TextSpan(text: '   $stream', style: const TextStyle(
                            fontSize: 10,
                            color: Colors.grey,
                          )),
                        ])),
                        IconButton(
                          onPressed: () {
                            setState2(() {
                              streams.remove(stream);
                            });
                          }, icon: const Icon(Icons.delete)
                        ),
                      ],
                    )).toList(),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: addStreamController,
                          ),
                        ),
                        IconButton(
                          onPressed: () {
                            setState2(() {
                              streams[addStreamController.text] = '';
                            });
                            loadStreamTitles();
                          }, icon: const Icon(Icons.add)
                        ),
                      ],
                    ),
                  ],
                );
              },),
            ),
            const Padding(
              padding: EdgeInsets.all(8.0),
              child: Text('Notifikace'),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: TextField(
                controller: notifdurcontroller,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'doba mezi notifikacemi (minuty)',
                ),
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              ),
            ),
            const Padding(
              padding: EdgeInsets.all(8.0),
              child: Text("Čas generování notifikací (hodiny, 0 - 24)"),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: notifstartcontroller,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    ),
                  ),
                  const Padding(
                    padding: EdgeInsets.all(8.0),
                    child: Text("-"),
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: TextField(
                        controller: notifendcontroller,
                        keyboardType: TextInputType.number,
                        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: OutlinedButton(
                onPressed: () {
                  loadingSnack(() async {
                    final NavigatorState navigator = Navigator.of(context);
                    await user.put('event_type', eventType.toString());
                    await user.put('qrpath', qrpath);
                    await user.put('autoreload', autoreload ? 'true' : '');
                    await user.put('notifdur', notifdurcontroller.text);
                    await user.put('notifstart', notifstartcontroller.text);
                    await user.put('notifend', notifendcontroller.text);
                    await user.put('streams', streams.keys.join(' '));
                    navigator.pop();
                  });
                },
                child: const Text('Save')
              ),
            ),
          ],
        ),
      ),
    );
  }
}
