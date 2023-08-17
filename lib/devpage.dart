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

  @override
  Widget build (BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Query"),
      ),
      body: loadScrollSnacksWrapper(context,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: OutlinedButton(
                onPressed: () {
                  showDialog(context: context, builder: (context) => AlertDialog(
                    title: const Text('Load Raw Endpoint'),
                    actions: [
                      OutlinedButton(onPressed: () {loadingSnack(() async {await loginUser();}, 'logging in');}, child: const Text('Login')),
                      OutlinedButton(onPressed: () {Navigator.pop(context);}, child: const Text('Close')),
                    ],
                    content: LoadRawEndpointWidget(),
                  ),);
                },
                child: const Text('Raw Endpoint Dialog')
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: OutlinedButton(
                onPressed: () {
                  showDialog(context: context, builder: (context) => AlertDialog(
                    title: const Text('Inspect Storage'),
                    actions: [
                      OutlinedButton(onPressed: () {Navigator.pop(context);}, child: const Text('Close')),
                    ],
                    content: InspectStorageWidget(),
                  ),);
                },
                child: const Text('Storage Inspector Dialog')
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: OutlinedButton(
                onPressed: () {
                  showDialog(context: context, builder: (context) => AlertDialog(
                    title: const Text('Read Log'),
                    actions: [
                      OutlinedButton(onPressed: () {log.clear();}, child: const Text('Clear Log')),
                      OutlinedButton(onPressed: () {Navigator.pop(context);}, child: const Text('Close')),
                    ],
                    content: const LogViewWidget(),
                  ),);
                },
                child: const Text('Log View Dialog')
              ),
            ),
            // SingleChildScrollView(scrollDirection: Axis.horizontal, child: Text(const JsonEncoder.withIndent('   ').convert(log.toMap().values.toList()))),
          ]
        ),
      ),
    );
  }
}

class LogViewWidget extends StatelessWidget {
  const LogViewWidget({super.key,});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Text(log.values.map((e) => '${DateTime.fromMillisecondsSinceEpoch(e['time'])} ${e['level']}\n  ${e['data'].join('\n  ')}').join('\n')),
    );
  }
}

final Map<String, Box> boxesByNames = {
  'storage': storage,
  'user': user,
  'refresh': refresh,
  'passwords': passwords,
  'log': log,
  'snacks': snacks,
  'ids': ids,
};

class InspectStorageWidget extends StatelessWidget {
  InspectStorageWidget({super.key,});

  final storageController = TextEditingController();
  final outputController = TextEditingController();

  void loadStorage () {
    loadingSnack(() async {
      bool mapping = false;
      String input = storageController.text;
      if (input.startsWith(':')) {
        mapping = true;
        input = input.substring(1);
      }
      List<String> path = input.split('/');
      dynamic output = boxesByNames[path.first]?.toMap() ?? {'msg': 'box ${path.first} not found'};
      path.removeAt(0);
      for (final dir in path) {
        output = output[int.tryParse(dir) ?? dir];
      }
      if (mapping) {
        output = output.map((key, value) => MapEntry(key, value.runtimeType.toString()));
      }
      outputController.text = const JsonEncoder.withIndent('    ').convert(output);
    });
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: [
          TextField(
            controller: storageController,
            decoration: const InputDecoration(
              labelText: 'Storage Path'
            ),
            onSubmitted: (_) {loadStorage();},
          ),
          OutlinedButton(
            onPressed: loadStorage,
            child: const Text('Load'),
          ),
          TextField(
            controller: outputController,
            maxLines: null,
            decoration: const InputDecoration(
              labelText: 'Storage Data'
            ),
          ),
        ],
      ),
    );
  }
}

class LoadRawEndpointWidget extends StatelessWidget {
  LoadRawEndpointWidget({super.key});

  final endpointController = TextEditingController();
  final payloadController = TextEditingController();
  final outputController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return StatefulBuilder(
      builder: (context, setState2) {
        return SingleChildScrollView(
          child: Column(
            children: [
              TextField(
                controller: endpointController,
                decoration: const InputDecoration(
                  labelText: 'Endpoint'
                ),
              ),
              TextField(
                controller: payloadController,
                decoration: const InputDecoration(
                  labelText: 'Query params'
                ),
              ),
              OutlinedButton(
                onPressed: () {
                  loadingSnack(() async {
                    Box<String> user = Hive.box<String>('user');
                    String url = getPassword("bakalari", "url");
                    String token = user.get('token') ?? '';
                    Map raw = {};
                    if (payloadController.text.isNotEmpty) {
                      Result res = await query(url, token, endpointController.text, jsonDecode(payloadController.text));
                      assert(res.isSuccess);
                      raw = res.success;
                    } else {
                      Result res = await query(url, token, endpointController.text);
                      assert(res.isSuccess);
                      raw = res.success;
                    }
                    outputController.text = const JsonEncoder.withIndent('  ').convert(raw);
                  });
                },
                child: const Text('Send')
              ),
              TextField(
                controller: outputController,
                maxLines: null,
                decoration: const InputDecoration(
                  labelText: 'Output'
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}