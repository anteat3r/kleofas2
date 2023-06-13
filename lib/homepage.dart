import 'package:flutter/material.dart';
// import 'package:intl/intl.dart';
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
import 'library.dart';
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
          IconButton(
            onPressed: () {completeReload(context);},
            icon: const Icon(Icons.refresh_rounded)
          ),
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
              if ((user.get('kleolibrary') ?? '').isNotEmpty) IconButton(
                onPressed: () {Navigator.push(context, MaterialPageRoute(builder: (context) => const LibraryPage()));},
                icon: const Icon(Icons.trolley,),
                iconSize: 70,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
