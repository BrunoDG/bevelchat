import 'dart:io';

import 'package:bevelchat/text_composer.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';

class ChatScreen extends StatefulWidget {
  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  void _sendMessage({String? text, File? img}) async {
    Map<String, dynamic> data = {};

    if (img != null) {
      UploadTask task = FirebaseStorage.instance
          .ref()
          .child(DateTime.now().millisecondsSinceEpoch.toString())
          .putFile(img);
      try {
        TaskSnapshot snap = await task;
        String url = await snap.ref.getDownloadURL();
        print('Uploaded ${snap.bytesTransferred} bytes.');
        data['imgUrl'] = url;
      } on FirebaseException catch (e) {
        print(task.snapshot);

        if (e.code == 'permission-denied') {
          print('Usuário não tem permissão para fazer upload nessa referência');
        }
      }
    }

    if (text != null) {
      data['texto'] = text;
    }

    FirebaseFirestore.instance.collection('messages').add(data);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Olá'),
        elevation: 0,
      ),
      body: Column(
        children: <Widget>[
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream:
                  FirebaseFirestore.instance.collection('messages').snapshots(),
              builder: (context, snapshot) {
                switch (snapshot.connectionState) {
                  case ConnectionState.waiting:
                    return Center(
                      child: CircularProgressIndicator(),
                    );
                  default:
                    List<DocumentSnapshot<Map<String, dynamic>>> documents =
                        snapshot.data!.docs.reversed
                            .toList()
                            .cast<DocumentSnapshot<Map<String, dynamic>>>();
                    return ListView.builder(
                      itemCount: documents.length,
                      reverse: true,
                      itemBuilder: (context, index) {
                        return ListTile(
                          title: Text(documents[index].data()!['texto']),
                        );
                      },
                    );
                }
              },
            ),
          ),
          TextComposer(_sendMessage),
        ],
      ),
    );
  }
}
