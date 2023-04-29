import 'dart:convert';
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

  Box<Map> storage = Hive.box<Map>('storage');
  Box<int> refresh = Hive.box<int>('refresh');
  Box<String> user = Hive.box<String>('user');
  String cookie = '';

  @override
  Widget build (BuildContext context) {
    return Scaffold(
      appBar: AppBar(
      title: const Text('Menu'),
      actions: [
        IconButton(
          onPressed: () {
            loadingDialog(context, () async {
              String zarizeni = user.get('zarizeni') ?? '';
              String username = user.get('stravausername') ?? '';
              String password = user.get('stravapassword') ?? '';
              if (zarizeni.isEmpty || username.isEmpty || password.isEmpty) return;
              cookie = await stravaLoginCookie(zarizeni, username, password);
              Map menu = await loadStravaMenu(cookie);
              await storage.put('menu', menu);
              setState(() {});
            });
          },
          icon: const Icon(Icons.send_rounded)
        ),
      ],
    ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            ValueListenableBuilder(
              valueListenable: refresh.listenable(),
              builder: (BuildContext context, Box<int> value, child) {
                return Text(czDate(DateTime.fromMillisecondsSinceEpoch(value.get('menu') ?? 0).toString()));
              }
            ),
            ValueListenableBuilder(
              valueListenable: storage.listenable(),
              builder: (BuildContext context, Box<Map> value, child) {
                Map menu = value.get('menu') ?? {};
                // print(menu);
                return Column(
                  children: menu.keys.toList().sublist(0, menu.keys.length-1).map((key) {
                    List day = menu[key];
                    print(day);
                    // String dayRev = day['_datum'].split('-').reversed.join('-');
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
                              Text(day[0][2]),
                              const Divider(),
                              Row(
                                children: [
                                  if (day[3]) Padding(
                                    padding: const EdgeInsets.only(right: 8.0),
                                    child: Checkbox(
                                      value: day[1][0],
                                      onChanged: (bool? newvalue) {
                                        if (newvalue == null) return;
                                        setState(() {
                                          if (day[1][0]) {
                                            loadingDialog(context, () async {
                                              await setLunch(cookie, day[1][1], 0);
                                              await submitLunches(cookie);
                                              setState(() {
                                                day[1][0] = false;
                                              });
                                            });
                                          } else {
                                            loadingDialog(context, () async {
                                              await setLunch(cookie, day[1][1], 1);
                                              await submitLunches(cookie);
                                              setState(() {
                                                day[1][0] = true;
                                                day[2][0] = false;
                                              });
                                            });
                                          }
                                        });
                                      },
                                      activeColor: Colors.blue,
                                    ),
                                  ),
                                  SizedBox(width: width - 88, child: Text(day[1][2])),
                                ],
                              ),
                              const Divider(),
                              if (day[2][2].isNotEmpty) Row(
                                children: [
                                  if (day[3]) Padding(
                                    padding: const EdgeInsets.only(right: 8.0),
                                    child: Checkbox(
                                      value: day[2][0],
                                      onChanged: (bool? newvalue) {
                                        if (newvalue == null) return;
                                        setState(() {
                                          if (day[2][0]) {
                                            loadingDialog(context, () async {
                                              await setLunch(cookie, day[2][1], 0);
                                              await submitLunches(cookie);
                                              setState(() {
                                                day[2][0] = false;
                                              });
                                            });
                                          } else {
                                            loadingDialog(context, () async {
                                              await setLunch(cookie, day[2][2], 1);
                                              await submitLunches(cookie);
                                              setState(() {
                                                day[2][0] = true;
                                                day[1][0] = false;
                                              });
                                            });
                                          }
                                        });
                                      },
                                      activeColor: Colors.blue,
                                    ),
                                  ),
                                  SizedBox(width: width - 88, child: Text(day[2][2])),
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