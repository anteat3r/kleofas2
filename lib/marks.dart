import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'day.dart';
import 'storage.dart';

class MarksPage extends StatefulWidget{
  const MarksPage({Key? key}) : super(key: key);
  @override
  State<MarksPage> createState() => _MarksPageState();
}

class _MarksPageState extends State<MarksPage> {
  String currentSubject = '';
  bool showSubjects = false;
  List marksPerm = [];
  Map subjectsPerm = {};
  bool whatif = false;
  List<Map> addedMarks = [];
  
  //Map mapListToMap (List list, {String id = 'Id'}) => {for (Map item in list) item[id]: item};

  void updateWhatIf () => loadingSnack(() async {
    print(marksPerm + addedMarks);
    await loadPostJsonEndpoint("marks:whatif", url: 'marks/what-if', body: marksPerm + addedMarks);
    setState(() {
      whatif = true;
    });
  });


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
            ...addedMarks.map((addedMark) => Row(
              children: [
                Text(addedMark['MarkText'].toString()),
                Text(getId(addedMark['SubjectId']).name),
                Text(addedMark['TypeNote'].toString()),
              ],
            )).toList(),
            OutlinedButton(
              onPressed: () {
                // print(subjectsPerm);
                showDialog(context: context, builder: (context) => StatefulBuilder(
                    builder: (context2, setState2) {
                      String selectedSubjectId = subjectsPerm.values.first['Id'];
                      int selectedWeight = 1;
                      String selectedMark = "1";
                      // print(subjectsPerm);
                      return AlertDialog(
                        title: const Text('Add Expected Mark'),
                        actions: [
                          OutlinedButton(onPressed: () {Navigator.pop(context);}, child: const Text('Cancel')),
                          OutlinedButton(onPressed: () {
                            addedMarks.add({
                              'Id': null,
                              'MarkText': selectedMark,
                              'Weight': selectedWeight,
                              'SubjectId': selectedSubjectId,
                              'MaxPoints': 0,
                            });
                            updateWhatIf();
                          }, child: const Text('Ok')),
                        ],
                        content: Column(
                          children: [
                            DropdownButton<String>(
                              items: subjectsPerm.values.map((e) => DropdownMenuItem(value: e['Id'].toString(), child: Text(e['Name'].toString(),))).toList(),
                              onChanged: (newval) {
                                if (newval == null) return;
                                setState2(() {
                                  selectedSubjectId = newval;
                                });
                              },
                              value: selectedSubjectId,
                            ),
                            DropdownButton<int>(
                              items: List.generate(10, (index) => DropdownMenuItem(value: index+1, child: Text((index+1).toString()))),
                              onChanged: (newval) {
                                if (newval == null) return;
                                setState2(() {
                                  selectedWeight = newval;
                                });
                              },
                              value: selectedWeight,
                            ),
                            DropdownButton<String>(
                              items: ["1","1-","2","2-","3","3-","4","4-","5",].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                              onChanged: (newval) {
                                if (newval == null) return;
                                setState2(() {
                                  selectedMark = newval;
                                });
                              },
                              value: selectedMark,
                            ),
                          ],
                        ),
                      );
                    },
                ));
              },
              child: const Text('Add Expected Mark'),
            ),
            ValueListenableBuilder(
              valueListenable: storage.listenable(),
              builder: (BuildContext context, Box<Map> value, child) {
                List marksRaw = value.get(whatif ? 'marks:whatif' : 'marks')?['Subjects'] ?? [];
                List marks = [for (Map subject in marksRaw.where((element) => currentSubject == '' ? true : currentSubject == element['Subject']['Id'])) ...subject['Marks']];
                marks.sort((a, b) => b['EditDate'].compareTo(a['EditDate']));
                Map subjects = mapListToMap(marksRaw.map((e) => e['Subject']).toList());
                // print(subjects);
                if (!whatif) {
                  marksPerm = marks;
                  subjectsPerm = subjects;
                }
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
                            const markMap = <String, double>{
                              "1": 1.0,
                              "1-": 1.5,
                              "2": 2.0,
                              "2-": 2.5,
                              "3": 3.0,
                              "3-": 3.5,
                              "4": 4.0,
                              "4-": 4.5,
                              "5": 5.0,
                            };
                            List<(double?, double)> marksAndWeghts = List.from(subjectMarks["Marks"]).map((e) { 
                              String? weight = e["Weight"]?.toString();
                              weight ??= e["Type"];
                              double intWeight = 0.0;
                              if (weight == "X") {
                                intWeight = 10.0;
                              } else {
                                intWeight = double.parse(weight ?? "0");
                              }
                              double? markDouble;
                              if (e["MarkText"].contains("%")) {
                                markDouble = int.tryParse(e["MarkText"].replaceAll("%", ""))?.toDouble();
                              } else {
                                markDouble = markMap[e["MarkText"]];
                              }
                              return (markDouble, intWeight);
                            }).where((e) => e.$1 != null).toList();
                            double? corr = correlCoef(
                              marksAndWeghts.map((e) => e.$1!).toList(),
                              marksAndWeghts.map((e) => e.$2).toList(),
                            );
                            int? corrInt;
                            try {
                              corrInt = corr?.toInt();
                            } on Error {
                              corrInt = null;
                            }
                            showDialog(context: context, builder: (BuildContext context) {
                              return AlertDialog(
                                title: const Text('Subject'),
                                // content: Text('Average Text: ${subjectMarks["AverageText"]}\nTemporary Mark: ${subjectMarks["TemporaryMark"]}\nSubject Note: ${subjectMarks["SubjectNote"]}\nTemporary Mark Note: ${subjectMarks["TemporaryMarkNote"]}\nPoints Only: ${subjectMarks["PointsOnly"]}\nMark Prediction Enabled: ${subjectMarks["MarkPredictionEnabled"]}'),//Text('Mark Date: ${czDate(subjectMarks["MarkDate"])}\nEdit Date: ${czDate(subjectMarks["EditDate"])}\nCaption: ${subjectMarks["Caption"]}\nMark Text: ${subjectMarks["Marktext"]}\nType: ${subjectMarks["Type"]}\nSubject: ${subjectMarks["SubjectId"]}\nTeacher: ${subjectMarks["TeacherId"]}\nTheme: ${subjectMarks["Theme"]}\nIs Invalid Date: ${subjectMarks["IsInvalidDate"]}\nType Note: ${subjectMarks["TypeNote"]}\nWeight: ${subjectMarks["Weight"]}\nIs New: ${subjectMarks["IsNew"]}\nIs Points: ${subjectMarks["IsPoints"]}\nCalculated Mark Text: ${subjectMarks["CalculatedMarkText"]}\nClass RankText: ${subjectMarks["ClassRankText"]}\nId: ${subjectMarks["Id"]}\nPoints Text: ${subjectMarks["PointsText"]}\nMax Points: ${subjectMarks["MaxPoints"]}'),
                                content: SingleChildScrollView(child: Text(const JsonEncoder.withIndent('    ').convert({...subjectMarks, "lazy": corrInt == null ? null : (corrInt*100).round().toString()}..remove('Marks')))),
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
                                  child: SizedBox(width: 80, child: RichText(
                                    text: TextSpan(
                                      children: [
                                        TextSpan(
                                          text: subjectMarks['AverageText'].trim() == '' ? "? ? ?" : subjectMarks['AverageText'].trim(),
                                          style: const TextStyle(fontSize: 20, color: Colors.white),
                                        ),
                                        TextSpan(
                                          text: '   ${subjectMarks['TemporaryMark']}',
                                          style: const TextStyle(
                                            fontSize: 15,
                                            // color: Colors.grey,
                                          ),
                                        ),
                                      ],
                                    )
                                  )),
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
                                // content: Text('Mark Date: ${czDate(mark["MarkDate"])}\nEdit Date: ${czDate(mark["EditDate"])}\nCaption: ${mark["Caption"]}\nMark Text: ${mark["MarkText"]}\nType: ${mark["Type"]}\nSubject: ${subjects[mark['SubjectId']]?['Name']}\nTeacher: ${ids[mark["TeacherId"]]}\nTheme: ${mark["Theme"]}\nIs Invalid Date: ${mark["IsInvalidDate"]}\nType Note: ${mark["TypeNote"]}\nWeight: ${mark["Weight"]}\nIs New: ${mark["IsNew"]}\nIs Points: ${mark["IsPoints"]}\nCalculated Mark Text: ${mark["CalculatedMarkText"]}\nClass RankText: ${mark["ClassRankText"]}\nId: ${mark["Id"]}\nPoints Text: ${mark["PointsText"]}\nMax Points: ${mark["MaxPoints"]}'),
                                content: SingleChildScrollView(child: Text(const JsonEncoder.withIndent('    ').convert(mark)
                                  .replaceAppendAll('"${mark['TeacherId'] ?? 'BRUH'}"', ' - "${getId(mark['TeacherId']).name}"')
                                  .replaceAppendAll('"${mark['SubjectId'] ?? 'BRUH'}"', ' - "${getId(mark['SubjectId']).name}"')
                                )),
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
