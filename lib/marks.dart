import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'storage.dart';
import 'day.dart';

class MarksPage extends StatefulWidget{
  const MarksPage({Key? key}) : super(key: key);
  @override
  State<MarksPage> createState() => _MarksPageState();
}

class _MarksPageState extends State<MarksPage> {
  String currentSubject = '';
  bool showSubjects = false;
  //Map mapListToMap (List list, {String id = 'Id'}) => {for (Map item in list) item[id]: item};

  @override
  Widget build (BuildContext context) {
    AppBar appBar = AppBar(
      title: const Text('Marks'),
      actions: [
        IconButton(
          onPressed: () {
            setState(() { loadEndpointSnack('marks'); });
          },
          icon: const Icon(Icons.refresh_rounded)
        ),
      ],
    );
    return Scaffold(
      appBar: appBar,
      body: loadScrollSnacksWrapper(context,
        child: Column(
          children: [
            ValueListenableBuilder(
              valueListenable: refresh.listenable(),
              builder: (BuildContext context, Box<int> value, child) {
                return Text(czDate(DateTime.fromMillisecondsSinceEpoch(value.get('marks') ?? 0).toString()));
              }
            ),
            ValueListenableBuilder(
              valueListenable: storage.listenable(),
              builder: (BuildContext context, Box<Map> value, child) {
                List marksRaw = value.get('marks')?['Subjects'] ?? [];
                List marks = [for (Map subject in marksRaw.where((element) => currentSubject == '' ? true : currentSubject == element['Subject']['Id'])) ...subject['Marks']];
                marks.sort((a, b) => b['EditDate'].compareTo(a['EditDate']));
                Map subjects = mapListToMap(marksRaw.map((e) => e['Subject']).toList());
                return Column(
                  children: [
                    OutlinedButton(onPressed: () {setState(() {showSubjects = !showSubjects;});}, child: Text(showSubjects ? 'Hide' : 'Show')),
                    if (showSubjects) ...List.generate(marksRaw.length, (index) {
                      Map subjectMarks = marksRaw[index];
                      return Padding(
                        padding: const EdgeInsets.only(left: 8.0, right: 8.0, top: 5.0),
                        child: OutlinedButton(
                          style: ButtonStyle(
                            textStyle: MaterialStatePropertyAll(TextStyle(foreground: Paint()..color = Colors.white)),
                            backgroundColor: MaterialStatePropertyAll(currentSubject == subjectMarks['Subject']['Id'] ? Colors.lightBlue.shade600 : Colors.transparent),
                          ),
                          onPressed: () {
                            setState(() {
                              if (currentSubject == subjectMarks['Subject']['Id']) {
                                currentSubject = '';
                              } else {
                                currentSubject = subjectMarks['Subject']['Id'];
                              }
                            });
                          },
                          onLongPress: () {
                            showDialog(context: context, builder: (BuildContext context) {
                              return AlertDialog(
                                title: const Text('Subject'),
                                content: Text('Average Text: ${subjectMarks["AverageText"]}\nTemporary Mark: ${subjectMarks["TemporaryMark"]}\nSubject Note: ${subjectMarks["SubjectNote"]}\nTemporary Mark Note: ${subjectMarks["TemporaryMarkNote"]}\nPoints Only: ${subjectMarks["PointsOnly"]}\nMark Prediction Enabled: ${subjectMarks["MarkPredictionEnabled"]}'),//Text('Mark Date: ${czDate(subjectMarks["MarkDate"])}\nEdit Date: ${czDate(subjectMarks["EditDate"])}\nCaption: ${subjectMarks["Caption"]}\nMark Text: ${subjectMarks["Marktext"]}\nType: ${subjectMarks["Type"]}\nSubject: ${subjectMarks["SubjectId"]}\nTeacher: ${subjectMarks["TeacherId"]}\nTheme: ${subjectMarks["Theme"]}\nIs Invalid Date: ${subjectMarks["IsInvalidDate"]}\nType Note: ${subjectMarks["TypeNote"]}\nWeight: ${subjectMarks["Weight"]}\nIs New: ${subjectMarks["IsNew"]}\nIs Points: ${subjectMarks["IsPoints"]}\nCalculated Mark Text: ${subjectMarks["CalculatedMarkText"]}\nClass RankText: ${subjectMarks["ClassRankText"]}\nId: ${subjectMarks["Id"]}\nPoints Text: ${subjectMarks["PointsText"]}\nMax Points: ${subjectMarks["MaxPoints"]}'),
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
                                  child: SizedBox(width: 60, child: Text(subjectMarks['AverageText'], style: const TextStyle(fontSize: 20),)),
                                ),
                                Padding(
                                  padding: const EdgeInsets.only(right: 8.0),
                                  child: SizedBox(width: 150, child: Text(subjectMarks['Subject']['Name'])),
                                ),
                                Padding(
                                  padding: const EdgeInsets.only(right: 8.0),
                                  child: Text('${subjectMarks['Marks'].length.toString()} známek'),
                                ),
                              ],
                            ),
                          )
                        ),
                      );
                    }),
                    if (showSubjects) const Divider(),
                    ...List.generate(marks.length, (index) {
                      Map mark = marks[index];
                      return Padding(
                        padding: const EdgeInsets.only(left: 8.0, right: 8.0, top: 5.0),
                        child: OutlinedButton(
                          style: ButtonStyle(
                            textStyle: MaterialStatePropertyAll(TextStyle(foreground: Paint()..color = Colors.white))
                          ),
                          onPressed: () {
                            showDialog(context: context, builder: (BuildContext context) {
                              return AlertDialog(
                                title: const Text('Mark'),
                                content: Text('Mark Date: ${czDate(mark["MarkDate"])}\nEdit Date: ${czDate(mark["EditDate"])}\nCaption: ${mark["Caption"]}\nMark Text: ${mark["MarkText"]}\nType: ${mark["Type"]}\nSubject: ${subjects[mark['SubjectId']]?['Name']}\nTeacher: ${ids[mark["TeacherId"]]}\nTheme: ${mark["Theme"]}\nIs Invalid Date: ${mark["IsInvalidDate"]}\nType Note: ${mark["TypeNote"]}\nWeight: ${mark["Weight"]}\nIs New: ${mark["IsNew"]}\nIs Points: ${mark["IsPoints"]}\nCalculated Mark Text: ${mark["CalculatedMarkText"]}\nClass RankText: ${mark["ClassRankText"]}\nId: ${mark["Id"]}\nPoints Text: ${mark["PointsText"]}\nMax Points: ${mark["MaxPoints"]}'),
                                actions: [TextButton(onPressed: () {Navigator.of(context).pop();}, child: const Text('Ok'))],
                              );
                            });
                          },
                          child: Padding(
                            padding: const EdgeInsets.all(6.0),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.start,
                              children: <Widget>[
                                Padding(
                                  padding: const EdgeInsets.only(right: 16),
                                  child: Text(mark['MarkText'], style: const TextStyle(fontSize: 30),),
                                ),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: <Widget>[
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        mainAxisSize: MainAxisSize.max,
                                        children: <Widget>[
                                          Text(subjects[mark['SubjectId']]?['Abbrev'] ?? 'Id not loaded'),
                                          Text(mark['Weight'] == null ? mark['TypeNote'] : 'váha ${mark['Weight']}'),
                                          DayWidget(DateTime.parse(mark['EditDate'])),
                                        ],
                                      ),
                                      Text(mark['Caption'], textAlign: TextAlign.start,),
                                    ],
                                  ),
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