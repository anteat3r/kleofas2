import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pocketbase/pocketbase.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'storage.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({Key? key}) : super(key: key);
  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

enum Gender { civilAttackHelicopter }
enum EventType { my, all, public }

class _SettingsPageState extends State<SettingsPage> {
  bool passwordVisible = false;
  bool autoreload = false;
  var eventType = EventType.my;
  // String qrpath = "";
  var notifdurcontroller = TextEditingController();
  var notifstartcontroller = TextEditingController();
  var notifendcontroller = TextEditingController();
  List<String> streams = [];
  List<String> adminStreams = [];
  final addStreamController = TextEditingController();
  final addAdminStreamController = TextEditingController();

  void loadStreamTitles () async {
    await loginPb();
    for (String key in streams) {
      try {
        final loadedStream = await pb.collection('streams').getOne(key);
        await setId(key, loadedStream.data['title'], loadedStream.data['icon']);
        if (!loadedStream.data["admins"]?.contains(pb.authStore.model.id)) continue;
        if (adminStreams.contains(loadedStream.id)) continue;
        adminStreams.add(loadedStream.id);
      } on ClientException {
        await setId(key, "NEEXISTUJE", "NEEXISTUJE");
     }
    }
    setState(() {});
  }

  @override
  void initState() {
    super.initState();
    // qrpath = user.get('qrpath') ?? '';
    autoreload = (user.get('autoreload') ?? '').isNotEmpty;
    notifdurcontroller.text = user.get("notifdur") ?? "15";
    notifstartcontroller.text = user.get("notifstart") ?? "6";
    notifendcontroller.text = user.get("notifend") ?? "22";
    streams = user.get("streams")?.split(",") ?? [];
    if (streams == [""]) {
      streams = [];
    }
    adminStreams = user.get("adminstreams")?.split(",") ?? [];
    //streams = {for (final stream in user.get('streams')?.split(' ') ?? []) stream: '...'};
    //if (user.get('streams')?.isEmpty ?? true) {
      //streams = {};
    //}
    //if (user.get('adminstreams')?.isEmpty ?? true) {
    //  adminStreams = {};
    //}
    if (user.get('event_type') == null) return;
    if (user.get('event_type') == 'EventType.my') {
      eventType = EventType.my;
    } else if (user.get('event_type') == 'EventType.all') {
      eventType = EventType.all;
    } else {
      eventType = EventType.public;
    }
    loadStreamTitles();
  }

  @override
  Widget build(BuildContext context) {
    AppBar appBar = AppBar(
      title: const Text('Settings'),
    );
    return Scaffold(
      appBar: appBar,
      body: loadScrollSnacksWrapper(context,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.all(8.0),
              child: Text('Načítat události:'),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: ListTile(
                title: const Text('my'),
                leading: Radio<EventType>(
                  value: EventType.my,
                  groupValue: eventType,
                  onChanged: (EventType? value) {
                    if (value == null) return;
                    setState(() {
                      eventType = EventType.my;
                    });
                  },
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: ListTile(
                title: const Text('all'),
                leading: Radio<EventType>(
                  value: EventType.all,
                  groupValue: eventType,
                  onChanged: (EventType? value) {
                    if (value == null) return;
                    setState(() {
                      eventType = EventType.all;
                    });
                  },
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: ListTile(
                title: const Text('public'),
                leading: Radio<EventType>(
                  value: EventType.public,
                  groupValue: eventType,
                  onChanged: (EventType? value) {
                    if (value == null) return;
                    setState(() {
                      eventType = EventType.public;
                    });
                  },
                ),
              ),
            ),
            const Padding(
              padding: EdgeInsets.all(8.0),
              child: Text('Pohlaví'),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: ListTile(
                title: const Text('Útočná helikoptéra'),
                leading: Radio<Gender>(
                  value: Gender.civilAttackHelicopter,
                  groupValue: Gender.civilAttackHelicopter,
                  onChanged: (Gender? value) {},
                ),
              ),
            ),
            // const Padding(
            //   padding: EdgeInsets.all(8.0),
            //   child: Text('Qr kód'),
            // ),
            // Padding(
            //   padding: const EdgeInsets.all(8.0),
            //   child: OutlinedButton(
            //       onPressed: () async {
            //         final res = await FilePicker.platform.pickFiles();
            //         if (res == null) return;
            //         qrpath = res.files.single.path ?? "";
            //       },
            //       child: const Text("Vybrat soubor")),
            // ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: ListTile(
                title: const Text('Auto Reload'),
                leading: Checkbox(
                  value: autoreload,
                  onChanged: (bool? value) {
                    if (value == null) return;
                    setState(() {
                      autoreload = value;
                    });
                  },
                ),
              ),
            ),
            const Padding(
              padding: EdgeInsets.all(8.0),
              child: Text('Kleofáš účet'),
            ),
            OutlinedButton(
              onPressed: () {
                showDialog(context: context, builder: (context) => const CreateNewAccountDialog(),);
              },
              child: const Text('Vytvořit účet')
            ),
            const Padding(
              padding: EdgeInsets.all(8.0),
              child: Text('Streamy'),
            ),
            OutlinedButton(
              onPressed: () {
                showDialog(context: context, builder: (context) => const AddStreamDialog(),);
              },
              child: const Text('Vytvořit stream')
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: StatefulBuilder(builder: (context, setState2) {
                return Column(
                  children: [
                    ...streams.map((stream) => stream == "" ? const SizedBox.shrink() : Row(
                      children: [
                        RichText(text: TextSpan(children: [
                          TextSpan(text: getId(stream).abbrev),
                          TextSpan(text: '   $stream', style: const TextStyle(
                            fontSize: 10,
                            color: Colors.grey,
                          )),
                        ])),
                        IconButton(
                          onPressed: () {
                            setState2(() {
                              streams.remove(stream);
                              if (adminStreams.contains(stream)) {
                                adminStreams.remove(stream);
                              }
                            });
                          }, icon: const Icon(Icons.delete_rounded)
                        ),
                        IconButton(
                          onPressed: () {
                            showDialog(context: context, builder: (context) =>  QrImageView(
                              data: stream,
                              backgroundColor: Colors.white,
                            ));
                          }, icon: const Icon(Icons.qr_code_rounded)
                        ),
                        if (adminStreams.contains(stream)) IconButton(
                          onPressed: () async {
                            final reqStream = await pb.collection('streams').getOne(stream, expand: 'admins');
                            if (!mounted) return;
                            showDialog(context: context, builder: (context) => EditStreamWidget(context, reqStream));
                          }, icon: const Icon(Icons.edit_rounded)
                        ),
                      ],
                    )).toList(),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: addStreamController,
                          ),
                        ),
                        IconButton(
                          onPressed: () {
                            streams.add(addStreamController.text);
                            loadStreamTitles();
                          }, icon: const Icon(Icons.add_rounded)
                        ),
                        IconButton(onPressed: () async {
                          final addedStream = await showQrDialog(context, 'Scan QR code of stream');
                          if (addedStream == null) return;
                          setState2(() {
                            streams.add(addedStream);
                          });
                          loadStreamTitles();
                        }, icon: const Icon(Icons.qr_code_2_rounded)),
                      ],
                    ),
                  ],
                );
              },),
            ),
           /*Padding(
              padding: const EdgeInsets.all(8.0),
              child: StatefulBuilder(builder: (context, setState2) {
                return Column(
                  children: [
                    ...adminStreams.keys.map((stream) => Row(
                      children: [
                        RichText(text: TextSpan(children: [
                          TextSpan(text: adminStreams[stream] ?? '?'),
                          TextSpan(text: '   $stream', style: const TextStyle(
                            fontSize: 10,
                            color: Colors.grey,
                          )),
                        ])),
                        IconButton(
                          onPressed: () {
                            setState2(() {
                              adminStreams.remove(stream);
                            });
                          }, icon: const Icon(Icons.delete)
                        ),
                        IconButton(
                          onPressed: () async {
                            final reqStream = await pb.collection('streams').getOne(stream, expand: 'admins');
                            if (!mounted) return;
                            showDialog(context: context, builder: (context) => EditStreamWidget(context, reqStream));
                          }, icon: const Icon(Icons.edit)
                        ),
                      ],
                    )).toList(),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: addAdminStreamController,
                          ),
                        ),
                        IconButton(
                          onPressed: () {
                            setState2(() {
                              adminStreams[addAdminStreamController.text] = '';
                            });
                            loadStreamTitles();
                          }, icon: const Icon(Icons.add)
                        ),
                      ],
                    ),
                  ]
                );
              })
            ),*/
            const Padding(
              padding: EdgeInsets.all(8.0),
              child: Text('Notifikace'),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: TextField(
                controller: notifdurcontroller,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'doba mezi notifikacemi (minuty)',
                ),
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              ),
            ),
            const Padding(
              padding: EdgeInsets.all(8.0),
              child: Text("Čas generování notifikací (hodiny, 0 - 24)"),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: notifstartcontroller,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    ),
                  ),
                  const Padding(
                    padding: EdgeInsets.all(8.0),
                    child: Text("-"),
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: TextField(
                        controller: notifendcontroller,
                        keyboardType: TextInputType.number,
                        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: OutlinedButton(
                onPressed: () {
                  loadingSnack(() async {
                    if (streams.contains('NEEXISTUJE') || adminStreams.contains('NEEXITUJE')) {
                      globalShowDialog((context) => const AlertDialog(
                        title: Text('Stream neexistuje'),
                        content: Text('Pokusil jsi se uložit stream, který neexistuje.'),));
                      return;
                    }
                    if (streams.contains('NEJSI ADMIN')) {
                      globalShowDialog((context) => const AlertDialog(
                        title: Text('Nejsi admin'),
                        content: Text('Pokusil jsi se uložit stream, jehož nejsi admin, jako admin stream.'),));
                      return;
                    }
                    final NavigatorState navigator = Navigator.of(context);
                    await user.put('event_type', eventType.toString());
                    // await user.put('qrpath', qrpath);
                    await user.put('autoreload', autoreload ? 'true' : '');
                    await user.put('notifdur', notifdurcontroller.text);
                    await user.put('notifstart', notifstartcontroller.text);
                    await user.put('notifend', notifendcontroller.text);
                    await user.put('streams', streams.join(','));
                    await user.put('adminstreams', adminStreams.join(','));
                    navigator.pop();
                  });
                },
                child: const Text('Save')
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class CreateNewAccountDialog extends StatefulWidget {
  const CreateNewAccountDialog({super.key,});

  @override
  State<CreateNewAccountDialog> createState() => _CreateNewAccountDialogState();
}

class _CreateNewAccountDialogState extends State<CreateNewAccountDialog> {
  final usernameController = TextEditingController();

  final emailController = TextEditingController();

  final passwordController = TextEditingController();

  final passwordConfirmController = TextEditingController();

  bool emailVisible = true;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Vytvořit účet'),
      content: Column(
        children: [
          TextField(
            controller: usernameController,
            decoration: const InputDecoration(labelText: 'username'),
          ),
          TextField(
            controller: emailController,
            decoration: const InputDecoration(labelText: 'email'),
          ),
          Switch(value: emailVisible, onChanged: (value) => setState(() {
            emailVisible = value;
          }),),
          TextField(
            controller: passwordController,
            obscureText: true,
            decoration: const InputDecoration(labelText: 'password'),
          ),
          TextField(
            controller: passwordConfirmController,
            obscureText: true,
            decoration: const InputDecoration(labelText: 'confirm password'),
          ),
        ],
      ),
      actions: [
        OutlinedButton(onPressed: () {Navigator.pop(context);}, child: const Text('Close')),
        OutlinedButton(onPressed: () {
          loadingSnack(() async {
            await pb.collection('users').create(body: {
              'username': usernameController.text,
              'email': emailController.text,
              'password': passwordController.text,
              'passwordConfirm': passwordConfirmController.text,
              'emailVisibility': emailVisible,
              'librarian': false,
            });
            await passwords.put('kleofas', {
              "title": {
                  "value": "Kleofáš",
                  "text": true
              },
              "username": {
                  "hint": "username",
                  "value": usernameController.text
              },
              "password": {
                  "hint": "password",
                  "secret": true,
                  "value": passwordController.text
              }
            });
            await loginPb();
          });
          Navigator.pop(context);
        }, child: const Text('Done')),
      ],
    );
  }
}

class EditStreamWidget extends StatefulWidget {
  const EditStreamWidget(this.context, this.stream, {super.key});

  final RecordModel stream;
  final BuildContext context;

  @override
  State<EditStreamWidget> createState() => _EditStreamWidgetState();
}

class _EditStreamWidgetState extends State<EditStreamWidget> {

  final titleController = TextEditingController();
  final addAdminController = TextEditingController();
  List<RecordModel> admins = [];

  @override
  void initState() {
    super.initState();
    titleController.text = widget.stream.data['title'];
    admins = widget.stream.expand['admins'] ?? [];
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Edit stream ${widget.stream.data['title']}'),
      actions: [
        OutlinedButton(onPressed: () {Navigator.pop(context);}, child: const Text('Close')),
        OutlinedButton(onPressed: () {
          loadingSnack(() async {
            await pb.collection('streams').update(widget.stream.id, body: {
              'title': titleController.text,
              'admins': admins.map((e) => e.id).toList(),
            });
          });
          Navigator.pop(context);
        }, child: const Text('Done')),
      ],
      content: Column(
        children: [
          TextField(
            controller: titleController,
            decoration: const InputDecoration(labelText: 'Title'),
          ),
          const Text('Admins:'),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: addAdminController,
                  decoration: const InputDecoration(labelText: 'Add admin'),
                ),
              ),
              IconButton(onPressed: () {
                loadingSnack(() async {
                  final reqUsers = await pb.collection('users').getFullList(filter: 'username = "${addAdminController.text}"');
                  if (reqUsers.isEmpty) {
                    globalShowWarning('User not found', 'User ${addAdminController.text} was not found.');
                    return; 
                  }
                  setState(() {
                    admins.add(reqUsers.first);
                  });
                });
              }, icon: const Icon(Icons.add)),
            ],
          ),
          ...admins.map((admin) => Row(
            children: [
              Text(admin.data['username']),
              IconButton(onPressed: () {}, icon: const Icon(Icons.remove_circle_outline)),
            ],
          )),
        ],
      ),
    );
  }
}

class AddStreamDialog extends StatefulWidget {
  const AddStreamDialog({super.key});

  @override
  State<AddStreamDialog> createState() => _AddStreamDialogState();
}

class _AddStreamDialogState extends State<AddStreamDialog> {

  final streamNameController = TextEditingController();
  final streamIconController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Create Stream'),
      actions: [
        OutlinedButton(onPressed: () {Navigator.pop(context);}, child: const Text('Close')),
        OutlinedButton(onPressed: () async {
          final record = await pb.collection('streams').create(
            body: {
              'title': streamNameController.text,
              'icon': streamIconController.text,
              'admins': [pb.authStore.model.id],
            }
          );
          Clipboard.setData(ClipboardData(text: record.id));
        }, child: const Text('Add')),
      ],
      content: Column(
        children: [
          TextField(
            controller: streamNameController,
            decoration: const InputDecoration(labelText: 'Stream Name'),
          ),
          TextField(
            controller: streamIconController,
            decoration: const InputDecoration(labelText: 'Stream Icon'),
          ),
        ],
      ),
    );
  }
}
