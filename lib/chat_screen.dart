import 'dart:io';

import 'package:bevelchat/text_composer.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';

import 'chat_message.dart';

class ChatScreen extends StatefulWidget {
  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  final GlobalKey<ScaffoldState> _scaffoldKey = new GlobalKey<ScaffoldState>();

  User? _currentUser;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();

    FirebaseAuth.instance.authStateChanges().listen((user) {
      setState(() {
        _currentUser = user;
      });
    });
  }

  Future<User?> _getUser() async {
    if (_currentUser != null) return _currentUser;

    try {
      final GoogleSignInAccount? _googleSignInAccount =
          await _googleSignIn.signIn();
      final GoogleSignInAuthentication _googleSignInAuthentication =
          await _googleSignInAccount!.authentication;

      final AuthCredential _credential = GoogleAuthProvider.credential(
        idToken: _googleSignInAuthentication.idToken,
        accessToken: _googleSignInAuthentication.accessToken,
      );

      final UserCredential _authResult =
          await FirebaseAuth.instance.signInWithCredential(_credential);

      final User user = _authResult.user!;
      return user;
    } catch (error) {
      return null;
    }
  }

  void _sendMessage({String? text, File? img}) async {
    final User? user = await _getUser();

    if (user == null) {
      _scaffoldKey.currentState?.showSnackBar(
        SnackBar(
          content: Text(
              "Não foi possível fazer o login. Por favor tente novamente."),
          backgroundColor: Colors.red,
        ),
      );
    }

    Map<String, dynamic> data = {
      "uid": user?.uid,
      "senderName": user?.displayName,
      "senderPhotoUrl": user?.photoURL,
      "time": Timestamp.now(),
    };

    if (img != null) {
      UploadTask task = FirebaseStorage.instance
          .ref()
          .child(user!.uid + DateTime.now().millisecondsSinceEpoch.toString())
          .putFile(img);
      setState(() {
        _isLoading = true;
      });

      try {
        TaskSnapshot snap = await task;
        String url = await snap.ref.getDownloadURL();
        print('Uploaded ${snap.bytesTransferred} bytes.');
        data['imgUrl'] = url;
        setState(() {
          _isLoading = false;
        });
      } on FirebaseException catch (e) {
        print(task.snapshot);

        if (e.code == 'permission-denied') {
          print('Usuário não tem permissão para fazer upload nessa referência');
        }

        setState(() {
          _isLoading = false;
        });
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
        title: Text(_currentUser != null
            ? 'Olá, ${_currentUser!.displayName}'
            : 'Chat App'),
        centerTitle: true,
        elevation: 0,
        actions: <Widget>[
          _currentUser != null
              ? IconButton(
                  icon: Icon(Icons.exit_to_app),
                  onPressed: () {
                    FirebaseAuth.instance.signOut();
                    _googleSignIn.signOut();
                    _scaffoldKey.currentState?.showSnackBar(
                      SnackBar(
                        content: Text("Você saiu com sucesso!"),
                      ),
                    );
                  },
                )
              : Container()
        ],
      ),
      body: Column(
        children: <Widget>[
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('messages')
                  .orderBy("time")
                  .snapshots(),
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
                        return ChatMessage(
                            documents[index].data(),
                            documents[index].data()?["uid"] ==
                                _currentUser?.uid);
                      },
                    );
                }
              },
            ),
          ),
          _isLoading ? LinearProgressIndicator() : Container(),
          TextComposer(_sendMessage),
        ],
      ),
    );
  }
}
