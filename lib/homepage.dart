import 'package:flutter/material.dart';
import 'absence.dart';
import 'storage.dart';
import 'devpage.dart';
import 'timetable.dart';
import 'marks.dart';
import 'settings.dart';
import 'events.dart';
import 'menu.dart';
import 'calendar.dart';
import 'qr.dart';
import 'password.dart';
// import 'package:permission_handler/permission_handler.dart';
// import 'package:hive_flutter/hive_flutter.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String cookie = '';

  @override
  void initState () {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      if ((user.get("autoreload") ?? "").isNotEmpty) {
        completeReload(context);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Main menu'),
        actions: [
          // IconButton(
          //   onPressed: () {
          //     loginUser(context);
          //     if (user.get('kleousername') == null || user.get('kleopassword') == null ) return;
          //     loadingDialog(context, () async {await pb.collection('users').authWithPassword(user.get('kleousername') ?? '', user.get('kleopassword') ?? '');});
          //   },
          //   icon: const Icon(Icons.supervised_user_circle)
          // ),
          // IconButton(
          //   onPressed: () async {
          //     Map googleAuth = (await pb.collection('users').listAuthMethods()).toJson()['authProviders'][0];
          //     pb.collection('users').authWithOAuth2('google', googleAuth['codeChallenge'], googleAuth['codeVerifier'], googleAuth['authUrl']);
          //   },
          //   icon: const Icon(Icons.brunch_dining_rounded)
          // ),
          IconButton(
            onPressed: () {completeReload(context);},
            icon: const Icon(Icons.refresh_rounded)
          ),
          // IconButton(
          //   onPressed: () async {
          //     cookie = await loginWebCookie(user.get('url') ?? '', user.get('username') ?? '', user.get('password') ?? '');
          //   },
          //   icon: const Icon(Icons.brunch_dining_sharp)
          // ),
          // IconButton(
          //   onPressed: () async {
          //     String html2 = await queryWeb(user.get('url') ?? '', 'Timetable/Public', cookie);
          //     final options = RegExp(r'<\s*option\s*value="(.+)"\s*>\s*(.+)\s*<\s*\/option\s*>');
          //     final matches = options.allMatches(html2);
          //     final unescape = HtmlUnescape();
          //     // print({for (final match in matches) match.group(1): unescape.convert(match.group(2) ?? '?')});
          //   },
          //   icon: const Icon(Icons.install_desktop_rounded)
          // ),
          // ValueListenableBuilder(
          //   valueListenable: user.listenable(),
          //   builder: (BuildContext context, Box<String> value, _) => Switch(
          //     value: value.get('data_saving') == 'true',
          //     onChanged: (bool newvalue) {value.put('data_saving', newvalue ? 'true' : 'false');}
          //   )
          // ),
        ],
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: <Row>[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: <IconButton>[
              IconButton(
                onPressed: () {Navigator.push(context, MaterialPageRoute(builder: (context) => const DevPage()));},
                icon: const Icon(Icons.terminal_rounded,),
                iconSize: 70,
              ),
              IconButton(
                onPressed: () {Navigator.push(context, MaterialPageRoute(builder: (context) => const TimetablePage()));},
                icon: const Icon(Icons.grid_on_outlined,),
                iconSize: 70,
              ),
              IconButton(
                onPressed: () {Navigator.push(context, MaterialPageRoute(builder: (context) => const AbsencePage()));},
                icon: const Icon(Icons.account_box_rounded,),
                iconSize: 70,
              ),
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: <IconButton>[
              IconButton(
                onPressed: () {Navigator.push(context, MaterialPageRoute(builder: (context) => const MarksPage()));},
                icon: const Icon(Icons.onetwothree_rounded,),
                iconSize: 70,
              ),
              IconButton(
                onPressed: () {Navigator.push(context, MaterialPageRoute(builder: (context) => const SettingsPage()));},
                icon: const Icon(Icons.settings,),
                iconSize: 70,
              ),
              IconButton(
                onPressed: () {Navigator.push(context, MaterialPageRoute(builder: (context) => const EventsPage()));},
                icon: const Icon(Icons.event,),
                iconSize: 70,
              ),
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: <IconButton>[
              IconButton(
                onPressed: () {Navigator.push(context, MaterialPageRoute(builder: (context) => const MenuPage()));},
                icon: const Icon(Icons.soup_kitchen_outlined,),
                iconSize: 70,
              ),
              IconButton(
                onPressed: () {newTaskDialog(context);},
                icon: const Icon(Icons.add_box_outlined,),
                iconSize: 70,
              ),
              IconButton(
                onPressed: () {Navigator.push(context, MaterialPageRoute(builder: (context) => const CalendarPage()));},
                icon: const Icon(Icons.calendar_month_rounded,),
                iconSize: 70,
              ),
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: <IconButton>[
              IconButton(
                onPressed: () {Navigator.push(context, MaterialPageRoute(builder: (context) => const QrPage()));},
                icon: const Icon(Icons.qr_code_2_rounded,),
                iconSize: 70,
              ),
              IconButton(
                onPressed: () {Navigator.push(context, MaterialPageRoute(builder: (context) => const PasswordPage()));},
                icon: const Icon(Icons.key_rounded,),
                iconSize: 70,
              ),
              // IconButton(
              //   onPressed: () {Navigator.push(context, MaterialPageRoute(builder: (context) => const CalendarPage()));},
              //   icon: const Icon(Icons.calendar_month_rounded,),
              //   iconSize: 70,
              // ),
            ],
          ),
        ],
      ),
    );
  }
}
