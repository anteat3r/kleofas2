import 'dart:io';

import 'package:flutter/material.dart';
import 'package:pocketbase/pocketbase.dart';
import 'package:url_launcher/url_launcher.dart';
import 'storage.dart';
import 'package:http/http.dart' as http;
import 'package:file_picker/file_picker.dart';

class LibraryPage extends StatefulWidget {
  const LibraryPage({Key? key}) : super(key: key);
  @override
  State<LibraryPage> createState() => _LibraryPageState();
}

class _LibraryPageState extends State<LibraryPage> {
  List<RecordModel> libraryData = [];

  void loadLibrary () async {
    loadingDialog(context, () async {
      await loginPbFuture();
      libraryData = await pb.collection('library').getFullList();
      setState(() {});
    });
  }

  @override
  void initState () {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      loadLibrary();
    });
  }

  void showArticle (RecordModel article, bool edit) {
    showDialog(context: context, builder: (context) {
      TextEditingController articlecontroller = TextEditingController(text: article.data['body']);
      return AlertDialog(
        title: Text(article.data['title']),
        content: SingleChildScrollView(
          child: TextField(
            controller: articlecontroller,
          ),
        ),
      );
    });
  }

  @override
  Widget build (BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Library'),
        actions: [
          IconButton(
            onPressed: () {
              showDialog(context: context, builder: (context) {
                final titlecontroller = TextEditingController();
                final bodycontroller = TextEditingController();
                return AlertDialog(
                  title: const Text('Vytvořit'),
                  content: SingleChildScrollView(
                    child: Column(
                      children: [
                        TextField(
                          controller: titlecontroller,
                          decoration: const InputDecoration(
                            labelText: 'Název'
                          ),
                        ),
                        TextField(
                          controller: bodycontroller,
                          maxLines: null,
                          decoration: const InputDecoration(
                            labelText: 'Text'
                          ),
                        ),
                      ],
                    ),
                  ),
                  actions: [
                    OutlinedButton(
                      onPressed: () {Navigator.pop(context);},
                      child: const Text('Zavřít')
                    ),
                    OutlinedButton(
                      onPressed: () {
                        loadingDialog(context, () async {
                          final navigator_ = Navigator.of(context);
                          await pb.collection('library').create(body: {
                            'title': titlecontroller.text,
                            'body': bodycontroller.text,
                          });
                          libraryData = await pb.collection('library').getFullList();
                          navigator_.pop();
                          setState(() {});
                        });
                      },
                      child: const Text('Vytvořit')
                    ),
                  ],
                );
              });
            },
            icon: const Icon(Icons.create)
          )
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: libraryData.map((article) => Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Text(article.data['title']),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  OutlinedButton(
                    onPressed: () {
                      showDialog(context: context, builder: (context) {
                        return AlertDialog(
                          title: Text(article.data['title']),
                          content: SingleChildScrollView(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(article.data['body']),
                                const Divider(),
                                ...[for (final file in article.data['files']) RichText(text: TextSpan(
                                  style: const TextStyle(color: Colors.lightBlue),
                                  text: file,
                                  recognizer: TapAndPanGestureRecognizer()..onTapDown = (details) {
                                    launchUrl(Uri.parse('${pb.baseUrl}/api/files/library/${article.id}/$file'));
                                  }
                                ))],
                              ],
                            ),
                          ),
                          actions: [
                            OutlinedButton(
                              onPressed: () {Navigator.pop(context);},
                              child: const Text('Zavřít')
                            )
                          ],
                        );
                      });
                    },
                    child: const Text('Zobrazit')
                  ),
                  OutlinedButton(
                    onPressed: () {
                      showDialog(context: context, builder: (context) {
                        TextEditingController articlecontroller = TextEditingController(text: article.data['body']);
                        return AlertDialog(
                          title: Text(article.data['title']),
                          content: SingleChildScrollView(
                            child: Column(
                              children: [
                                TextField(
                                  maxLines: null,
                                  controller: articlecontroller,
                                ),
                                ...[for (final file in article.data['files']) Row(
                                  children: [
                                    RichText(text: TextSpan(
                                      style: const TextStyle(color: Colors.lightBlue),
                                      text: file,
                                      recognizer: TapAndPanGestureRecognizer()..onTapDown = (details) {
                                        launchUrl(Uri.parse('${pb.baseUrl}/api/files/library/${article.id}/$file'));
                                      }
                                    )),
                                    IconButton(
                                      onPressed: () {
                                        loadingDialog(context, () async {
                                          await pb.collection('library').update(article.id, body: {
                                            'files-': [file]
                                          });
                                          setState(() {});
                                        });
                                      },
                                      icon: const Icon(Icons.delete_forever)
                                    )
                                  ],
                                )],
                                IconButton(
                                  onPressed: () {
                                    loadingDialog(context, () async {
                                      final res = await FilePicker.platform.pickFiles();
                                      if (res == null) return;
                                      final path = res.files.single.path;
                                      if (path == null) return;
                                      print(await pb.collection('library').update(article.id, files: [
                                        http.MultipartFile.fromBytes('file', await File(path).readAsBytes(), filename: path.split('/').last)
                                      ]));
                                      setState(() {});
                                    });
                                  },
                                  icon: const Icon(Icons.add)
                                )
                              ],
                            ),
                          ),
                          actions: [
                            OutlinedButton(
                              onPressed: () {
                                loadingDialog(context, () async {
                                  final navigator_ = Navigator.of(context);
                                  await pb.collection('library').delete(article.id);
                                  navigator_.pop();
                                  libraryData = await pb.collection('library').getFullList();
                                  setState(() {});
                                });
                              },
                              child: const Text('Smazat')
                            ),
                            OutlinedButton(
                              onPressed: () {
                                loadingDialog(context, () async {
                                  await pb.collection('library').update(article.id, body: {
                                    'body': articlecontroller.text
                                  });
                                  libraryData = await pb.collection('library').getFullList();
                                  setState(() {});
                                });
                              },
                              child: const Text('Upravit')
                            ),
                            OutlinedButton(
                              onPressed: () {Navigator.pop(context);},
                              child: const Text('Zavřít')
                            ),
                          ],
                        );
                      });
                    },
                    child: const Text('Editovat')
                  ),
                ],
              ),
            ],
          ),
        )).toList(),
      ),
    );
  }
}