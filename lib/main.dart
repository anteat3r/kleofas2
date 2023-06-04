import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'homepage.dart';
import 'storage.dart';
import 'package:workmanager/workmanager.dart';
import 'dart:io';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  await Hive.openBox<String>('user');
  await Hive.openBox<Map>('storage');
  await Hive.openBox<int>('refresh');
  await Hive.openBox<Map>('passwords');
  if (Platform.isAndroid || Platform.isIOS) {
    Workmanager().initialize(callbackDispatcher);
    Workmanager().registerPeriodicTask('bgrefresh', 'backgroundRefreshing', frequency: const Duration(minutes: 15));
  }
  runApp(const MyApp());
}

@pragma('vm:entry-point')
void callbackDispatcher () {
  Workmanager().executeTask((taskName, inputData) async {
    try {
      await bgLoad();
    } catch (e, s) {
      await Hive.openBox<String>('user');
      await user.put("error", "${user.get("error") ?? ""}${DateTime.now().toIso8601String()}: $e -> $s\n");
    }
    return Future.value(true);
  });
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Kleofáš',
      theme: ThemeData(
        brightness: Brightness.dark,
        primarySwatch: Colors.lightBlue,
      ),
      home: const HomePage(),
      debugShowCheckedModeBanner: false,
    );
  }
}
