import 'dart:convert';
import 'package:flutter/material.dart';
import 'storage.dart';

class PasswordPage extends StatefulWidget {
  const PasswordPage({Key? key}) : super(key: key);
  @override
  State<PasswordPage> createState() => _PasswordPageState();
}

class _PasswordPageState extends State<PasswordPage> {
  Map<String, bool> visible = {};
  Map<String, TextEditingController> controllers = {};
  Map<dynamic, Map> localPasses = passwords.toMap();

  @override
  void initState () {
    super.initState();
    if (passwords.toMap().isEmpty) {
      passwords.putAll({
        "bakalari": {
          "title": {
            "value": "Bakaláři",
            "text": true,
          },
          "url": {
            "hint": "url",
            "value": user.get("url") ?? ""
          },
          "username": {
            "hint": "username",
            "value": user.get("username") ?? ""
          },
          "password": {
            "hint": "password",
            "secret": true,
            "value": user.get("password") ?? ""
          },
        },
        "kleofas": {
          "title": {
            "value": "Kleofáš",
            "text": true,
          },
          "username": {
            "hint": "username",
            "value": user.get("kleousername") ?? ""
          },
          "password": {
            "hint": "password",
            "secret": true,
            "value": user.get("kleopassword") ?? ""
          },
        },
        "strava": {
          "title": {
            "value": "strava.cz",
            "text": true,
          },
          "zarizeni": {
            "hint": "zařízení",
            "value": user.get("zarizeni") ?? ""
          },
          "username": {
            "hint": "username",
            "value": user.get("stravausername") ?? ""
          },
          "password": {
            "hint": "password",
            "secret": true,
            "value": user.get("stravapassword") ?? ""
          },
        },
      });
      localPasses = passwords.toMap();
    }
  }

  @override
  Widget build (BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Hesla"),
        actions: [
          IconButton(
            onPressed: () {
              final removePassController = TextEditingController();
              showDialog(context: context, builder: (BuildContext context) => AlertDialog(
                content: TextField(
                  controller: removePassController,
                  maxLines: null,
                  minLines: 5,
                ),
                actions: [
                  TextButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    child: const Text("Cancel")
                  ),
                  TextButton(
                    onPressed: () {
                      localPasses.remove(removePassController.text);
                      passwords.delete(removePassController.text);
                      Navigator.pop(context);
                      setState(() {});
                    },
                    child: const Text("Remove")
                  ),
                ]
              ));
            },
            icon: const Icon(Icons.delete_forever_rounded)
          ),
          IconButton(
            onPressed: () {
              final newPassController = TextEditingController();
              showDialog(context: context, builder: (BuildContext context) => AlertDialog(
                content: TextField(
                  controller: newPassController,
                  maxLines: null,
                  minLines: 5,
                ),
                actions: [
                  TextButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    child: const Text("Cancel")
                  ),
                  TextButton(
                    onPressed: () {
                      String input = "{\n${newPassController.text}${newPassController.text.contains("--") ? "" : "\n}"}}"
                        .replaceAll("--", "}")
                        .replaceAllMapped(RegExp(r'''\n\s*-\s*(.+?)\s*\n'''), (match) => '''\n"${match[1]}":{\n''')
                        .replaceAllMapped(RegExp(r'''\n\s*#\s*(.+?)\s*:\s*(.+?)\s*\n'''), (match) => '''\n\t"${match[1]}":{"text":true,"value":"${match[2]}"},\n''')
                        .replaceAllMapped(RegExp(r'''\n\s*@\s*(.+?)\s*:\s*(.+?)\s*\n'''), (match) => '''\n\t"${match[1]}":{"hint":"${match[2]}"},\n''')
                        .replaceAllMapped(RegExp(r'''\n\s*\$\s*(.+?)\s*:\s*(.+?)\s*\n'''), (match) => '''\n\t"${match[1]}":{"hint":"${match[2]}","secret":true},\n''')
                        .replaceAllMapped(RegExp(r''',\s*?\n\s*\}'''), (match) => '''\n}''');
                      try {
                        localPasses.addAll(Map.from(jsonDecode(input)).map((key, value) => MapEntry(key, Map.from(value))));
                      } catch (e) {
                        return;
                      }
                      Navigator.pop(context);
                      setState(() {});
                    },
                    child: const Text("Done")
                  ),
                ],
              ));
            },
            icon: const Icon(Icons.add)
          ),
        ],
      ),
      body: loadScrollSnacksWrapper(context,
        child: Column(
          children: [
            ...localPasses.map((key, value) {
              return MapEntry(key, value.map((key2, value2) {
                if (value2["text"] ?? false) {
                  return MapEntry("$key:$key2", Padding(
                    padding: const EdgeInsets.all(4.0),
                    child: Text(value2["value"]),
                  ));
                }
                if (!(value2["secret"] ?? false)) {
                  controllers["$key:$key2"] = TextEditingController(text: value2["value"] ?? "");
                  return MapEntry("$key:$key2", Padding(
                    padding: const EdgeInsets.all(4.0),
                    child: TextField(
                      controller: controllers["$key:$key2"],
                      maxLines: 1,
                      decoration: InputDecoration(
                        hintText: value2["hint"] ?? "",
                        border: const OutlineInputBorder(
                          borderSide: BorderSide(
                            width: 1
                          ),
                          borderRadius: BorderRadius.all(Radius.circular(10))
                        ),
                      ),
                      onChanged: (value) {
                        localPasses[key]?[key2]["value"] = value;
                      },
                    ),
                  ));
                }
                controllers["$key:$key2"] = TextEditingController(text: value2["value"] ?? "");
                visible["$key:$key2"] ??= false;
                return MapEntry("$key:$key2", Padding(
                  padding: const EdgeInsets.all(4.0),
                  child: TextField(
                    controller: controllers["$key:$key2"],
                    obscureText: !(visible["$key:$key2"] ?? true),
                    maxLines: 1,
                    decoration: InputDecoration(
                      hintText: value2["hint"] ?? "",
                      border: const OutlineInputBorder(
                        borderSide: BorderSide(
                          width: 1
                        ),
                        borderRadius: BorderRadius.all(Radius.circular(10))
                      ),
                      suffixIcon: IconButton(
                        icon: Icon(
                          (visible["$key:$key2"] ?? true)
                          ? Icons.visibility
                          : Icons.visibility_off),
                        onPressed: () {
                          setState(() {
                            visible["$key:$key2"] = !(visible["$key:$key2"] ?? true);
                          });
                        },
                      ),
                    ),
                    onChanged: (value) {
                      localPasses[key]?[key2]["value"] = value;
                    },
                  ),
                ));
              }).values);
            }).values.expand((i) => i).toList(),
            OutlinedButton(
              onPressed: () {
                passwords.putAll(localPasses);
                Navigator.of(context).pop();
              },
              child: const Text("Save")
            )
          ],
        )
      )
    );
  }
}