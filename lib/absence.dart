import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'storage.dart';
import 'day.dart';

class AbsencePage extends StatefulWidget{
  const AbsencePage({Key? key}) : super(key: key);
  @override
  State<AbsencePage> createState() => _AbsencePageState();
}

DateTime roundDateTime (DateTime date) {
  if (date.hour > 12) {
    return DateTime(date.year, date.month, date.day + 1);
  }
  return date;
}

class _AbsencePageState extends State<AbsencePage> {
  final List<String> czWeekDayNames = ['Ne', 'Po', 'Út', 'St', 'Čt', 'Pá', 'So', 'Ne'];

  @override
  Widget build (BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Absence'),
        actions: [
          IconButton(
            onPressed: () {
              setState(() {
                loadEndpoint(context, 'absence', 'absence/student');
              });
            },
            icon: const Icon(Icons.refresh_rounded)
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            ValueListenableBuilder(
              valueListenable: refresh.listenable(),
              builder: (BuildContext context, Box<int> value, child) {
                return Text(czDate(DateTime.fromMillisecondsSinceEpoch(value.get('absence') ?? 0).toString()));
              }
            ),
            ValueListenableBuilder(
              valueListenable: storage.listenable(),
              builder: (BuildContext context, Box<Map> value, child) {
                List absences = value.get('absence')?['Absences'] ?? [];
                absences.sort((b, a) {
                  int aBad = a['Unsolved'] + a['Late'] + a['Missed'] + a['Soon'];
                  int bBad = b['Unsolved'] + b['Late'] + b['Missed'] + b['Soon'];
                  int aGood = a['Ok'] + a['School'];
                  int bGood = b['Ok'] + b['School'];
                  if (aBad == bBad) {
                    return aGood.compareTo(bGood);
                  } else {
                    return aBad.compareTo(bBad);
                  }
                });
                List absencesSubject = value.get('absence')?['AbsencesPerSubject'] ?? [];
                return Column(
                  children: [
                    ...List.generate(absences.length, (index) {
                      Map absence = absences[index];
                      return Padding(
                        padding: const EdgeInsets.only(left: 8.0, right: 8.0, top: 5.0),
                        child: OutlinedButton(
                          style: ButtonStyle(
                            textStyle: MaterialStatePropertyAll(TextStyle(foreground: Paint()..color = Colors.white)),
                          ),
                          onPressed: () {
                            showDialog(context: context, builder: (BuildContext context) {
                              return AlertDialog(
                                title: const Text('Absence'),
                                content: Text('Date: ${czDate(absence["Date"])}\nUnsolved: ${absence["Unsolved"]}\nOk: ${absence["Ok"]}\nMissed: ${absence["Missed"]}\nLate: ${absence["Late"]}\nSoon: ${absence["Soon"]}\nSchool: ${absence["School"]}\nDistance Teaching: ${absence["DistanceTeaching"]}'),
                                actions: [TextButton(onPressed: () {Navigator.of(context).pop();}, child: const Text('Ok'))],
                              );
                            });
                          },
                          child: Padding(
                            padding: const EdgeInsets.only(top: 6.0, right: 6.0, bottom: 6.0,),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.start,
                              children: <Widget>[
                                Padding(
                                  padding: const EdgeInsets.only(right: 8.0),
                                  child: Text((absence['Unsolved'] + absence['Late'] + absence['Missed'] + absence['Soon']).toString(), style: TextStyle(fontSize: 30, fontWeight: FontWeight.w500, foreground: Paint()..color = Colors.red),),
                                ),
                                Padding(
                                  padding: const EdgeInsets.only(right: 16.0),
                                  child: Text((absence['Ok'] + absence['School']).toString(), style: TextStyle(fontSize: 25, fontWeight: FontWeight.w500, foreground: Paint()..color = Colors.green),),
                                ),
                                Padding(
                                  padding: const EdgeInsets.only(right: 8.0),
                                  child: DayWidget(roundDateTime(DateTime.parse(absence['Date']))),
                                ),
                              ],
                            ),
                          )
                        ),
                      );
                    }),
                    const Divider(),
                    ...List.generate(absencesSubject.length, (index) {
                      Map absenceSubject = absencesSubject[index];
                      return Padding(
                        padding: const EdgeInsets.only(left: 8.0, right: 8.0, top: 5.0),
                        child: OutlinedButton(
                          style: ButtonStyle(
                            textStyle: MaterialStatePropertyAll(TextStyle(foreground: Paint()..color = Colors.white)),
                          ),
                          onPressed: () {
                            showDialog(context: context, builder: (BuildContext context) {
                              return AlertDialog(
                                title: const Text('Subject'),
                                content: Text('Subject Name: ${absenceSubject["SubjectName"]}\nLessons Count: ${absenceSubject["LessonsCount"]}\nBase: ${absenceSubject["Base"]}\nLate: ${absenceSubject["Late"]}\nSoon: ${absenceSubject["Soon"]}\nSchool: ${absenceSubject["School"]}\nDistance Teaching: ${absenceSubject["DistanceTeaching"]}'),
                                actions: [TextButton(onPressed: () {Navigator.of(context).pop();}, child: const Text('Ok'))],
                              );
                            });
                          },
                          child: Padding(
                            padding: const EdgeInsets.only(top: 6.0, right: 6.0, bottom: 6.0,),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: <Widget>[
                                Padding(
                                  padding: const EdgeInsets.only(right: 8.0),
                                  child: SizedBox(width: 150, child: Text(absenceSubject['SubjectName'])),
                                ),
                                Padding(
                                  padding: const EdgeInsets.only(right: 8.0),
                                  child: Text('${absenceSubject["Base"]} / ${absenceSubject["LessonsCount"]}'),
                                ),
                                Padding(
                                  padding: const EdgeInsets.only(right: 8.0),
                                  child: SizedBox(width: 50, child: Text((absenceSubject["Base"] / absenceSubject["LessonsCount"] * 100).toStringAsFixed(2), textAlign: TextAlign.end,)),
                                ),
                              ],
                            ),
                          )
                        ),
                      );
                    }),
                  ]
                );
              }
            )
          ],
        ),
      ),
    );
  }

}