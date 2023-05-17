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
  final TextEditingController username = TextEditingController();
  final TextEditingController password = TextEditingController();
  final TextEditingController url = TextEditingController();
  final TextEditingController zarizeni = TextEditingController();
  final TextEditingController kleousername = TextEditingController();
  final TextEditingController kleopassword = TextEditingController();
  final TextEditingController stravausername = TextEditingController();
  final TextEditingController stravapassword = TextEditingController();
  final TextEditingController qrpayload = TextEditingController();
  bool passwordVisible = false;
  EventType eventType = EventType.my;
  String qrpath = "";


  @override
  void initState () {
    super.initState();
    username.text = user.get('username') ?? '';
    password.text = user.get('password') ?? '';
    url.text = user.get('url') ?? '';
    zarizeni.text = user.get('zarizeni') ?? '';
    kleousername.text = user.get('kleousername') ?? '';
    kleopassword.text = user.get('kleopassword') ?? '';
    stravausername.text = user.get('stravausername') ?? '';
    stravapassword.text = user.get('stravapassword') ?? '';
    qrpayload.text = user.get('qrpayload') ?? '';
    qrpath = user.get('qrpath') ?? '';
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
              child: Text('Bakaláři'),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: TextField(
                maxLines: 1,
                controller: url,
                decoration: const InputDecoration(
                  hintText: "url",
                  border: OutlineInputBorder(
                    borderSide: BorderSide(
                      width: 1
                    ),
                    borderRadius: BorderRadius.all(Radius.circular(10))
                  )
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: TextField(
                maxLines: 1,
                controller: username,
                decoration: const InputDecoration(
                  hintText: "username",
                  border: OutlineInputBorder(
                    borderSide: BorderSide(
                      width: 1
                    ),
                    borderRadius: BorderRadius.all(Radius.circular(10))
                  )
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: TextField(
                maxLines: 1,
                controller: password,
                obscureText: !passwordVisible,
                decoration: InputDecoration(
                  hintText: "password",
                  border: const OutlineInputBorder(
                    borderSide: BorderSide(
                      width: 1
                    ),
                    borderRadius: BorderRadius.all(Radius.circular(10))
                  ),
                  suffixIcon: IconButton(
                    icon: Icon(
                      passwordVisible
                      ? Icons.visibility
                      : Icons.visibility_off),
                    onPressed: () {
                      setState(() {
                          passwordVisible = !passwordVisible;
                      });
                    },
                  ),
                ),
              ),
            ),
            const Padding(
              padding: EdgeInsets.all(8.0),
              child: Text('strava.cz'),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: TextField(
                maxLines: 1,
                controller: zarizeni,
                decoration: const InputDecoration(
                  hintText: "zařízení",
                  border: OutlineInputBorder(
                    borderSide: BorderSide(
                      width: 1
                    ),
                    borderRadius: BorderRadius.all(Radius.circular(10))
                  )
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: TextField(
                maxLines: 1,
                controller: stravausername,
                decoration: const InputDecoration(
                  hintText: "username",
                  border: OutlineInputBorder(
                    borderSide: BorderSide(
                      width: 1
                    ),
                    borderRadius: BorderRadius.all(Radius.circular(10))
                  )
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: TextField(
                maxLines: 1,
                controller: stravapassword,
                obscureText: !passwordVisible,
                decoration: InputDecoration(
                  hintText: "password",
                  border: const OutlineInputBorder(
                    borderSide: BorderSide(
                      width: 1
                    ),
                    borderRadius: BorderRadius.all(Radius.circular(10))
                  ),
                  suffixIcon: IconButton(
                    icon: Icon(
                      passwordVisible
                      ? Icons.visibility
                      : Icons.visibility_off),
                    onPressed: () {
                      setState(() {
                          passwordVisible = !passwordVisible;
                      });
                    },
                  ),
                ),
              ),
            ),
            const Padding(
              padding: EdgeInsets.all(8.0),
              child: Text('Kleofáš'),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: TextField(
                maxLines: 1,
                controller: kleousername,
                decoration: const InputDecoration(
                  hintText: "username",
                  border: OutlineInputBorder(
                    borderSide: BorderSide(
                      width: 1
                    ),
                    borderRadius: BorderRadius.all(Radius.circular(10))
                  )
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: TextField(
                maxLines: 1,
                controller: kleopassword,
                obscureText: !passwordVisible,
                decoration: InputDecoration(
                  hintText: "password",
                  border: const OutlineInputBorder(
                    borderSide: BorderSide(
                      width: 1
                    ),
                    borderRadius: BorderRadius.all(Radius.circular(10))
                  ),
                  suffixIcon: IconButton(
                    icon: Icon(
                      passwordVisible
                      ? Icons.visibility
                      : Icons.visibility_off),
                    onPressed: () {
                      setState(() {
                          passwordVisible = !passwordVisible;
                      });
                    },
                  ),
                ),
              ),
            ),
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
              child: OutlinedButton(
                onPressed: () {loadingDialog(context, () async {
                  final NavigatorState navigator = Navigator.of(context);
                  await user.put('username', username.text);
                  await user.put('password', password.text);
                  await user.put('kleousername', kleousername.text);
                  await user.put('kleopassword', kleopassword.text);
                  await user.put('stravausername', stravausername.text);
                  await user.put('stravapassword', stravapassword.text);
                  await user.put('url', url.text);
                  await user.put('zarizeni', zarizeni.text);
                  await user.put('event_type', eventType.toString());
                  await user.put('qrpayload', qrpayload.text);
                  await user.put('qrpath', qrpath);
                  // username.text = user.get('username') ?? '';
                  // password.text = user.get('password') ?? '';
                  // kleousername.text = user.get('kleousername') ?? '';
                  // kleopassword.text = user.get('kleopassword') ?? '';
                  // username.text = user.get('username') ?? '';
                  // password.text = user.get('password') ?? '';
                  // url.text = user.get('url') ?? '';
                  // zarizeni.text = user.get('zarizeni') ?? '';
                  // if (user.get('event_type') == 'my') {
                  //   eventType = EventType.my;
                  // } else if (user.get('event_type') == 'all') {
                  //   eventType = EventType.all;
                  // } else {
                  //   eventType = EventType.public;
                  // }
                  navigator.pop();
                });},
                child: const Text('Save')
              ),
            ),
            // Padding(
            //   padding: const EdgeInsets.all(8.0),
            //   child: QrImageView(
            //     data: user.get("qrpayload") ?? "",
            //     version: 1,
            //     errorCorrectionLevel: QrErrorCorrectLevel.Q,
            //     size: MediaQuery.of(context).size.width*3,
            //     backgroundColor: Colors.white,
            //   )
            // ),
          ],
        ),
      ),
    );
  }

}