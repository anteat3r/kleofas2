import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'bakalari.dart';
import 'dart:convert';
import 'package:result_type/result_type.dart';
import 'storage.dart';

class DevPage extends StatefulWidget{
  const DevPage({Key? key}) : super(key: key);
  @override
  State<DevPage> createState() => _DevPageState();
}

class _DevPageState extends State<DevPage> {

  String output = "";
  TextEditingController endpoint = TextEditingController();
  TextEditingController payload = TextEditingController();

  @override
  Widget build (BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Query")
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SingleChildScrollView(scrollDirection: Axis.horizontal, child: Text(const JsonEncoder.withIndent('    ').convert(log.toMap()))),
            TextField(
              maxLines: 1,
              controller: endpoint,
              decoration: const InputDecoration(
                hintText: "endpoint",
                border: OutlineInputBorder(
                  borderSide: BorderSide(
                    width: 1
                  ),
                  borderRadius: BorderRadius.all(Radius.circular(10))
                )
              ),
            ),
            TextField(
              maxLines: 1,
              controller: payload,
              decoration: const InputDecoration(
                hintText: "query",
                border: OutlineInputBorder(
                  borderSide: BorderSide(
                    width: 1
                  ),
                  borderRadius: BorderRadius.all(Radius.circular(10))
                )
              ),
            ),
            TextButton(
              onPressed: () async {
                Box<String> user = Hive.box<String>('user');
                String url = getPassword("bakalari", "url");
                String token = user.get('token') ?? '';
                Map raw = {};
                if (payload.text.contains(":")) {
                  Result res = await query(url, token, endpoint.text, {payload.text.split(":")[0]: payload.text.split(":")[1]});
                  assert(res.isSuccess);
                  raw = res.success;
                } else {
                  Result res = await query(url, token, endpoint.text);
                  assert(res.isSuccess);
                  raw = res.success;
                }
                JsonEncoder encoder = const JsonEncoder.withIndent('  ');
                setState(() {
                  output = encoder.convert(raw);
                });
              },
              child: const Text("send")
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                  output,
                  textAlign: TextAlign.left,
                )
            )
          ]
        ),
      ),
    );
  }
}