import 'dart:io';

import 'package:bevelchat/text_composer.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';

class ChatScreen extends StatefulWidget {
  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  final GlobalKey<ScaffoldMessengerState> _scaffoldKey =
      GlobalKey<ScaffoldMessengerState>();

  User? _currentUser;

  @override
  void initState() {
    super.initState();

    FirebaseAuth.instance.authStateChanges().listen((user) {
      _currentUser = user;
    });
  }

  Future<User?> _getUser() async {
    if (_currentUser != null) return _currentUser;

    try {
      final GoogleSignInAccount? googleSignInAccount =
          await _googleSignIn.signIn();
      if (googleSignInAccount != null) {
        final GoogleSignInAuthentication googleSignInAuthentication =
            await googleSignInAccount.authentication;

        final AuthCredential credential = GoogleAuthProvider.credential(
          accessToken: googleSignInAuthentication.idToken,
          idToken: googleSignInAuthentication.accessToken,
        );

        final UserCredential userCredential =
            await FirebaseAuth.instance.signInWithCredential(credential);
        try {
          final User? user = userCredential.user;
          return user;
        } on FirebaseAuthException catch (e) {
          if (e.code == 'account-exists-with-different-credential') {
            print("Error: " + e.code);
            return null;
          } else if (e.code == 'invalid-credential') {
            print("Error: " + e.code);
            return null;
          }
        }
      }
    } on FirebaseAuthException catch (e) {
      print("Error: " + e.code);
      return null;
    }
  }

  void _sendMessage({String? text, File? img}) async {
    final User? user = await _getUser();

    if (user == null) {
      _scaffoldKey.currentState?.showSnackBar(SnackBar(
        content:
            Text("Não foi possível fazer o login. Por favor tente novamente."),
        backgroundColor: Colors.red,
      ));
    }

    Map<String, dynamic> data = {
      "uid": user?.uid,
      "senderMessage": user?.displayName,
      "senderPhotoUrl": user?.photoURL,
    };

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
      key: _scaffoldKey,
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
