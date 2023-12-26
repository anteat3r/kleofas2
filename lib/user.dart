// import 'package:flutter/material.dart';
// import 'storage.dart';
// import 'package:pocketbase/pocketbase.dart';
// import 'dart:convert';
// import 'dart:io';
// import 'package:image_picker/image_picker.dart';

// class EditStreamWidget extends StatefulWidget {
//   const EditStreamWidget(this.context, this.stream, {super.key});

//   final RecordModel stream;
//   final BuildContext context;

//   @override
//   State<EditStreamWidget> createState() => _EditStreamWidgetState();
// }

// class _EditStreamWidgetState extends State<EditStreamWidget> {

//   final titleController = TextEditingController();
//   final addAdminController = TextEditingController();
//   List<RecordModel> admins = [];

//   @override
//   void initState() {
//     super.initState();
//     titleController.text = widget.stream.data['title'];
//     admins = widget.stream.expand['admins'] ?? [];
//   }

//   @override
//   Widget build(BuildContext context) {
//     return AlertDialog(
//       title: Text('Edit stream ${widget.stream.data['title']}'),
//       actions: [
//         OutlinedButton(onPressed: () {Navigator.pop(context);}, child: const Text('Close')),
//         OutlinedButton(onPressed: () {
//           loadingSnack(() async {
//             await pb.collection('streams').update(widget.stream.id, body: {
//               'title': titleController.text,
//               'admins': admins.map((e) => e.id).toList(),
//             });
//           });
//           Navigator.pop(context);
//         }, child: const Text('Done')),
//       ],
//       content: Column(
//         children: [
//           TextField(
//             controller: titleController,
//             decoration: const InputDecoration(labelText: 'Title'),
//           ),
//           const Text('Admins:'),
//           Row(
//             children: [
//               Expanded(
//                 child: TextField(
//                   controller: addAdminController,
//                   decoration: const InputDecoration(labelText: 'Add admin'),
//                 ),
//               ),
//               IconButton(onPressed: () {
//                 loadingSnack(() async {
//                   final reqUsers = await pb.collection('users').getFullList(filter: 'username = "${addAdminController.text}"');
//                   if (reqUsers.isEmpty) {
//                     globalShowWarning('User not found', 'User ${addAdminController.text} was not found.');
//                     return; 
//                   }
//                   setState(() {
//                     admins.add(reqUsers.first);
//                   });
//                 });
//               }, icon: const Icon(Icons.add)),
//             ],
//           ),
//           ...admins.map((admin) => Row(
//             children: [
//               Text(admin.data['username']),
//               IconButton(onPressed: () {}, icon: const Icon(Icons.remove_circle_outline)),
//             ],
//           )),
//         ],
//       ),
//     );
//   }
// }

// class UserPage extends StatefulWidget {
//   const UserPage({Key? key}): super(key: key);
//   @override
//   State<UserPage> createState() => _UserPageSate();
// }

// class _UserPageSate extends State<UserPage> {
//   Map<String, String> adminStreams = {};
//   final addAdminStreamController = TextEditingController();
//   String? newProfilePicturePath;
//   String? newName;
//   String? newEmail;

//   void loadStreamTitles () {
//     loadingSnack(() async {
//       await loginPb();
//       for (var key in adminStreams.keys) {
//         try {
//           final record = await pb.collection('streams').getOne(key);
//           if (!record.data['admins'].contains(pb.authStore.model.id)) {
//             adminStreams[key] = 'NEJSI ADMIN';
//           } else {
//             adminStreams[key] = record.data['title'];
//           }
//         } on ClientException catch (_) {
//           adminStreams[key] = 'NEEXISTUJE';
//         }
//       }
//       setState(() {});
//     });
//   }

//   @override
//   void initState() {
//     super.initState();
//     adminStreams = {for (final stream in user.get('adminstreams')?.split(' ') ?? []) stream: '...'};
//     if (user.get('adminstreams')?.isEmpty ?? true) {
//       adminStreams = {};
//     }
//     loadStreamTitles();
//   }

//   @override
//   Widget build (BuildContext context) {
//     if (!hasPassword('kleofas', 'password')) {
//       return Scaffold(
//       appBar: AppBar(title: const Text('User'),),
//       body: const Center(
//         child: Text('Nejsi přihlášen do Kleofáš účtu'),
//       ),
//     );
//     }
//     return Scaffold(
//       appBar: AppBar(title: const Text('User'),),
//       body: loadScrollSnacksWrapper(
//         context,
//         child: Column(
//           children: [
//             if (pb.authStore.model != null) Row(
//               children: [
//                 Column(
//                   children: [
//                     newProfilePicturePath == null
//                       ? Image.network('${pb.baseUrl}/api/files/users/${pb.authStore.model.id}/${pb.authStore.model.data['avatar']}')
//                       : Image.file(File(newProfilePicturePath!)),
//                     OutlinedButton(onPressed: () async {
//                       final res = await ImagePicker().pickImage(source: ImageSource.gallery);
//                       if (res == null) return;
//                       setState(() {
//                         newProfilePicturePath = res.path;
//                       });
//                     }, child: const Text('Pick new profile image')),
//                   ],
//                 ),

//               ],
//             ),
//             OutlinedButton(
//               onPressed: () {
//                 loadingSnack(() async {
//                   pb.collection('users').update(pb.authStore.model.id, body: {
//                     // if (newProfilePicturePath != null) 'avatar': newProfilePicturePath,
//                     'librarian': false
//                   });
//                 });
//               },
//               child: const Text('Done')
//             ),
//             const Padding(
//               padding: EdgeInsets.all(8.0),
//               child: Text('Admin streamy'),
//             ),
//             Padding(
//               padding: const EdgeInsets.all(8.0),
//               child: StatefulBuilder(builder: (context, setState2) {
//                 return Column(
//                   children: [
//                     ...adminStreams.keys.map((stream) => Row(
//                       children: [
//                         RichText(text: TextSpan(children: [
//                           TextSpan(text: adminStreams[stream] ?? '?'),
//                           TextSpan(text: '   $stream', style: const TextStyle(
//                             fontSize: 10,
//                             color: Colors.grey,
//                           )),
//                         ])),
//                         IconButton(
//                           onPressed: () {
//                             setState2(() {
//                               adminStreams.remove(stream);
//                             });
//                           }, icon: const Icon(Icons.delete)
//                         ),
//                         IconButton(
//                           onPressed: () async {
//                             final reqStream = await pb.collection('streams').getOne(stream, expand: 'admins');
//                             if (!mounted) return;
//                             showDialog(context: context, builder: (context) => EditStreamWidget(context, reqStream));
//                           }, icon: const Icon(Icons.edit)
//                         ),
//                       ],
//                     )).toList(),
//                     Row(
//                       children: [
//                         Expanded(
//                           child: TextField(
//                             controller: addAdminStreamController,
//                           ),
//                         ),
//                         IconButton(
//                           onPressed: () {
//                             setState2(() {
//                               adminStreams[addAdminStreamController.text] = '';
//                             });
//                             loadStreamTitles();
//                           }, icon: const Icon(Icons.add)
//                         ),
//                       ],
//                     ),
//                   ],
//                 );
//               },),
//             ),
//             OutlinedButton(onPressed: () async {
//               await user.put('adminstreamsnames', jsonEncode(adminStreams));
//               await user.put('adminstreams', adminStreams.keys.join(' '));
//             }, child: const Text('Save')),
            
//           ],
//         ),
//       ),
//     );
//   }
// }
  