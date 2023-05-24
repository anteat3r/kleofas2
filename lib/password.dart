import 'dart:io';
import 'package:flutter/material.dart';
// import 'package:hive_flutter/hive_flutter.dart';
import 'package:local_auth/local_auth.dart';
import 'storage.dart';

class PasswordPage extends StatefulWidget {
  const PasswordPage({Key? key}) : super(key: key);
  @override
  State<PasswordPage> createState() => _PasswordPageState();
}

class _PasswordPageState extends State<PasswordPage> {
  bool authenticated = false;
  Map<String, bool> visible = {};
  Map<String, TextEditingController> controllers = {};
  Map<dynamic, Map> localPasses = passwords.toMap();

  void authenticate () async {
    authenticated = await LocalAuthentication().authenticate(localizedReason: "Autentikuj se pls");
    setState(() {});
  }

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
          },
          "username": {
            "hint": "username",
          },
          "password": {
            "hint": "password",
            "secret": true,
          },
        },
        "kleofas": {
          "title": {
            "value": "Kleofáš",
            "text": true,
          },
          "username": {
            "hint": "username",
          },
          "password": {
            "hint": "password",
            "secret": true,
          },
        },
        "strava": {
          "title": {
            "value": "strava.cz",
            "text": true,
          },
          "zarizeni": {
            "hint": "zařízení",
          },
          "username": {
            "hint": "username",
          },
          "password": {
            "hint": "password",
            "secret": true,
          },
        },
      });
      localPasses = passwords.toMap();
    }
    if (Platform.isWindows) {
      authenticated = true;
      return;
    }
    authenticate();
  }

  @override
  Widget build (BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Hesla"),
        actions: [
          IconButton(
            onPressed: () {
              print(passwords.toMap());
              print(localPasses);
            },
            icon: const Icon(Icons.terrain_rounded)
          )
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            children: [
              if (!authenticated) const Text("nejsi autentikován"),
              if (authenticated) ...localPasses.map((key, value) {
                return MapEntry(key, value.map((key2, value2) {
                  if (value2["text"] ?? false) {
                    return MapEntry("$key:$key2", Text(value2["value"]));
                  }
                  if (!(value2["secret"] ?? false)) {
                    controllers["$key:$key2"] = TextEditingController(text: value2["value"] ?? "");
                    return MapEntry("$key:$key2", TextField(
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
                    ));
                  }
                  controllers["$key:$key2"] = TextEditingController(text: value2["value"] ?? "");
                  visible["$key:$key2"] = false;
                  return MapEntry("$key:$key2", TextField(
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
                          (visible["$key:$key2"] ?? false)
                          ? Icons.visibility
                          : Icons.visibility_off),
                        onPressed: () {
                          // print(visible["$key:$key2"]);
                          // print("$key:$key2");
                          print(visible["strava:password"]);
                          visible["strava:password"] = true;
                          print(visible["strava:password"]);
                          visible["$key:$key2"] = !(visible["$key:$key2"] ?? true);
                          setState(() {});
                        },
                      ),
                    ),
                    onChanged: (value) {
                      localPasses[key]?[key2]["value"] = value;
                    },
                  ));
                }).values);
              }).values.expand((i) => i).toList(),
              if (authenticated) OutlinedButton(
                onPressed: () {
                  passwords.putAll(localPasses);
                },
                child: const Text("Save")
              )
            ],
          ),
        )
      )
    );
  }
}