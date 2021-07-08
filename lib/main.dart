import 'package:bevelchat/chat_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(MyApp());

  /**
   * Escrevendo, Lendo, Alterando e Excluindo dados no Firebase:
   * 
   * .set() -> Escreve um dado novo no banco de dados - Create
   * .get() -> Obtém as mensagens do banco (precisa de 'await') - Read
   * .update() -> Atualiza campo de dado no banco - Update
   * .delete() -> Exclui um campo ou dado no banco - Delete
   * 
   */

  /*
  FirebaseFirestore.instance
      .collection("mensagens")
      .doc('kkDiByMOrz7897FSPajV')
      .collection('arquivos')
      .doc()
      .set({'arquivo': 'foto.png'});
  */
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Bevel Chat',
      theme: ThemeData(
          primarySwatch: Colors.blue,
          iconTheme: IconThemeData(
            color: Colors.blue,
          )),
      home: ChatScreen(),
    );
  }
}
