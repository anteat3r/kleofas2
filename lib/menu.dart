import 'bakalari.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'storage.dart';
import 'day.dart';

class MenuPage extends StatefulWidget{
  const MenuPage({Key? key}) : super(key: key);
  @override
  State<MenuPage> createState() => _MenuPageState();
}

class _MenuPageState extends State<MenuPage> {
  String cookie = '';

  @override
  void initState () {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      loadingDialog(context, () async {
        if (!hasPassword("strava", "zarizeni") || !hasPassword("strava", "username") || !hasPassword("strava", "password")) return;
        String zarizeni = getPassword("strava", "zarizeni");
        String username = getPassword("strava", "username");
        String password = getPassword("strava", "password");
        cookie = await stravaLoginCookie(zarizeni, username, password);
        Map menu = await loadStravaMenu(cookie);
        await storage.put('menu', menu);
        await refresh.put('strava_cookie', DateTime.now().millisecondsSinceEpoch);
        setState(() {});
      });
    });
  }

  @override
  Widget build (BuildContext context) {
    return Scaffold(
      appBar: AppBar(
      title: const Text('Menu'),
      // actions: [
      //   IconButton(
      //     onPressed: () {
      //       // loadingDialog(context, () async {
      //       //   String zarizeni = user.get('zarizeni') ?? '';
      //       //   String username = user.get('stravausername') ?? '';
      //       //   String password = user.get('stravapassword') ?? '';
      //       //   if (zarizeni.isEmpty || username.isEmpty || password.isEmpty) return;
      //       //   cookie = await stravaLoginCookie(zarizeni, username, password);
      //       //   Map menu = await loadStravaMenu(cookie);
      //       //   await storage.put('menu', menu);
      //       //   setState(() {});
      //       // });
      //       print(storage.get('menu'));
      //     },
      //     icon: const Icon(Icons.send_rounded)
      //   ),
      // ],
    ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // ValueListenableBuilder(
            //   valueListenable: refresh.listenable(),
            //   builder: (BuildContext context, Box<int> value, child) {
            //     return Text(czDate(DateTime.fromMillisecondsSinceEpoch(value.get('menu') ?? 0).toString()));
            //   }
            // ),
            ValueListenableBuilder(
              valueListenable: storage.listenable(),
              builder: (BuildContext context, Box<Map> value, child) {
                Map menu = value.get('menu') ?? {};
                // print(menu);
                if (menu.keys.isEmpty) {
                  return const Text("empty");
                }
                return Column(
                  children: menu.keys.toList().sublist(0, menu.keys.length-1).map((key) {
                    Map day = menu[key];
                    double width = MediaQuery.of(context).size.width;
                    return Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: OutlinedButton(
                        style: ButtonStyle(
                          textStyle: MaterialStatePropertyAll(TextStyle(foreground: Paint()..color = Colors.white)),
                        ),
                        onPressed: () {},
                        child: Padding(
                          padding: const EdgeInsets.only(top: 15.0, bottom: 15.0),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.start,
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: <Widget>[
                              Padding(
                                padding: const EdgeInsets.only(bottom: 5.0),
                                child: DayWidget(DateTime.parse(key)),
                              ),
                              Text(day['soup']),
                              const Divider(),
                              Row(
                                children: [
                                  // Padding(
                                  if (day['soup'] != day['first']['title']) Padding(
                                    padding: const EdgeInsets.only(right: 8.0),
                                    child: Checkbox(
                                      // fillColor: day['enabled'] ? null : const MaterialStatePropertyAll(Colors.grey),
                                      value: day['first']['ordered'],
                                      onChanged: (bool? newvalue) {
                                        if (!day['enabled']) return;
                                        if (newvalue == null) return;
                                        setState(() {
                                          if (day['first']['ordered']) {
                                            loadingDialog(context, () async {
                                              await setLunch(cookie, day['first']['veta'], 0);
                                              await submitLunches(cookie);
                                              setState(() {
                                                day['first']['ordered'] = false;
                                              });
                                            });
                                          } else {
                                            loadingDialog(context, () async {
                                              await setLunch(cookie, day['first']['veta'], 1);
                                              await submitLunches(cookie);
                                              setState(() {
                                                day['first']['ordered'] = true;
                                                day['second']['ordered'] = false;
                                              });
                                            });
                                          }
                                        });
                                      },
                                      activeColor: day['enabled'] ? Colors.blue : Colors.grey,
                                    ),
                                  ),
                                  SizedBox(width: width - 88, child: Text(day['first']['title'])),
                                ],
                              ),
                              const Divider(),
                              if (day['second']['title'].isNotEmpty) Row(
                                children: [
                                  if (day['soup'] != day['second']['title']) Padding(
                                  // Padding(
                                    padding: const EdgeInsets.only(right: 8.0),
                                    child: Checkbox(
                                      value: day['second']['ordered'],
                                      // fillColor: day['enabled'] ? null : const MaterialStatePropertyAll(Colors.grey),
                                      onChanged: (bool? newvalue) {
                                        if (!day['enabled']) return;
                                        if (newvalue == null) return;
                                        setState(() {
                                          if (day['second']['ordered']) {
                                            loadingDialog(context, () async {
                                              await setLunch(cookie, day['second']['veta'], 0);
                                              await submitLunches(cookie);
                                              setState(() {
                                                day['second']['ordered'] = false;
                                              });
                                            });
                                          } else {
                                            loadingDialog(context, () async {
                                              await setLunch(cookie, day['second']['veta'], 1);
                                              await submitLunches(cookie);
                                              setState(() {
                                                day['second']['ordered'] = true;
                                                day['first']['ordered'] = false;
                                              });
                                            });
                                          }
                                        });
                                      },
                                      activeColor: day['enabled'] ? Colors.blue : Colors.grey,
                                    ),
                                  ),
                                  SizedBox(width: width - 88, child: Text(day['second']['title'])),
                                ],
                              ),
                            ],
                          ),
                        )
                      ),
                    );
                  }).toList()
                );
              }
            )
          ],
        ),
      ),
    );
  }

}