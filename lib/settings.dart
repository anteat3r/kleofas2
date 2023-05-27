import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'storage.dart';

class SettingsPage extends StatefulWidget{
  const SettingsPage({Key? key}) : super(key: key);
  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

enum Gender {civilAttackHelicopter}
enum EventType {my, all, public}

class _SettingsPageState extends State<SettingsPage> {
  bool passwordVisible = false;
  bool autoreload = false;
  EventType eventType = EventType.my;
  String qrpath = "";


  @override
  void initState () {
    super.initState();
    qrpath = user.get('qrpath') ?? '';
    autoreload = (user.get('autoreload') ?? '').isNotEmpty;
    if (user.get('event_type') == null) return;
    if (user.get('event_type') == 'EventType.my') {
      eventType = EventType.my;
    } else if (user.get('event_type') == 'EventType.all') {
      eventType = EventType.all;
    } else {
      eventType = EventType.public;
    }
  }

  @override
  Widget build (BuildContext context) {
    AppBar appBar = AppBar(
      title: const Text('Settings'),
    );
    return Scaffold(
      appBar: appBar,
      body: SingleChildScrollView(
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
                    if (value == null ) return;
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
                    if (value == null ) return;
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
                    if (value == null ) return;
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
                child: const Text("Vybrat soubor")
              ),
              // child: TextField(
              //   maxLines: 1,
              //   controller: qrpayload,
              //   decoration: const InputDecoration(
              //     hintText: "payload qr kódu",
              //     border: OutlineInputBorder(
              //       borderSide: BorderSide(
              //         width: 1
              //       ),
              //       borderRadius: BorderRadius.all(Radius.circular(10))
              //     )
              //   ),
              // ),
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
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: OutlinedButton(
                onPressed: () {loadingDialog(context, () async {
                  final NavigatorState navigator = Navigator.of(context);
                  await user.put('event_type', eventType.toString());
                  await user.put('qrpath', qrpath);
                  await user.put('autoreload', autoreload ? 'true' : '');
                  navigator.pop();
                });},
                child: const Text('Save')
              ),
            ),
          ],
        ),
      ),
    );
  }

}