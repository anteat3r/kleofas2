import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'storage.dart';
import 'day.dart';
import 'package:http/http.dart';

class MenuPage extends StatefulWidget{
  const MenuPage({Key? key}) : super(key: key);
  @override
  State<MenuPage> createState() => _MenuPageState();
}

class _MenuPageState extends State<MenuPage> {

  Box<Map> storage = Hive.box<Map>('storage');
  Box<int> refresh = Hive.box<int>('refresh');
  Box<String> user = Hive.box<String>('user');
  Map choices = {};
  Map localChoices = {};

  @override
  void initState () {
    super.initState();
    choices = storage.get('menu:choices') ?? {};
  }

  @override
  Widget build (BuildContext context) {
    return Scaffold(
      appBar: AppBar(
      title: const Text('Menu'),
      actions: [
        IconButton(
          onPressed: () {
            String zarizeni = user.get('zarizeni') ?? '';
            String username = user.get('stravausername') ?? '';
            String password = user.get('stravapassword') ?? '';
            if (zarizeni.isEmpty || username.isEmpty || password.isEmpty) return;
            loadingDialog(context, () async {
              Response resp = await post(Uri.parse('http://pb.kleofas.pro:8000'), body: jsonEncode({'jidelna': zarizeni, 'uzivatel': username, 'heslo': password, 'data': localChoices}));
              choices = jsonDecode(resp.body);
              await storage.put('menu:choices', choices);
              setState(() {});
            });
            loadMenu(context);
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
                List menu = value.get('menu')?['jidelnicky']?['den'] ?? [];
                return Column(
                  children: List.generate(menu.length, (index) {
                    Map day = menu[index];
                    String dayRev = day['_datum'].split('-').reversed.join('-');
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
                                child: DayWidget(DateTime.parse(dayRev)),
                              ),
                              Text(day['jidlo'][0]['_nazev'],),
                              const Divider(),
                              Row(
                                children: [
                                  if (!day['jidlo'][1]['_nazev'].contains('nevaří')) Padding(
                                    padding: const EdgeInsets.only(right: 8.0),
                                    child: Checkbox(
                                      value: (choices[dayRev] ?? 0) == 1,
                                      onChanged: (bool? newvalue) {
                                        if (newvalue == null) return;
                                        setState(() {
                                          if (choices[dayRev] == 1) {
                                            choices[dayRev] = 0;
                                            localChoices[dayRev] = 0;
                                          } else {
                                            choices[dayRev] = 1;
                                            localChoices[dayRev] = 1;
                                          }
                                        });
                                      },
                                      activeColor: Colors.blue,
                                    ),
                                  ),
                                  SizedBox(width: width - 88, child: Text(day['jidlo'][1]['_nazev'],)),
                                ],
                              ),
                              const Divider(),
                              if (day['jidlo'][2]['_nazev'].isNotEmpty) Row(
                                children: [
                                  if (!day['jidlo'][2]['_nazev'].contains('nevaří')) Padding(
                                    padding: const EdgeInsets.only(right: 8.0),
                                    child: Checkbox(
                                      value: (choices[dayRev] ?? 0) == 2,
                                      onChanged: (bool? newvalue) {
                                        if (newvalue == null) return;
                                        setState(() {
                                          if (choices[dayRev] == 2) {
                                            choices[dayRev] = 0;
                                            localChoices[dayRev] = 0;
                                          } else {
                                            choices[dayRev] = 2;
                                            localChoices[dayRev] = 2;
                                          }
                                        });
                                      },
                                      activeColor: Colors.blue,
                                    ),
                                  ),
                                  SizedBox(width: width - 88, child: Text(day['jidlo'][2]['_nazev'],)),
                                ],
                              ),
                            ],
                          ),
                        )
                      ),
                    );
                  })
                );
              }
            )
          ],
        ),
      ),
    );
  }

}