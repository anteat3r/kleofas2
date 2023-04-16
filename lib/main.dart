import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'homepage.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Workmanager().initialize(callbackDispatcher, isInDebugMode: true);
  // Workmanager().registerPeriodicTask('bgrefresh', 'backgroundRefreshing');
  await Hive.initFlutter();
  await Hive.openBox<String>('user');
  await Hive.openBox<Map>('storage');
  await Hive.openBox<int>('refresh');
  runApp(const MyApp());
}

// void callbackDispatcher () {
//   Workmanager().executeTask((taskName, inputData) async {
//     await completeReloadFuture();
//     return Future.value(true);
//   });
// }

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