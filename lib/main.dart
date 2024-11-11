// ignore_for_file: prefer_const_constructors, use_key_in_widget_constructors, annotate_overrides, prefer_const_literals_to_create_immutables

import 'package:card_scan_flutter/ajuda.page.dart';
import 'package:card_scan_flutter/camera.page.dart';
import 'package:card_scan_flutter/consts.dart';
import 'package:card_scan_flutter/deck.page.dart';
import 'package:card_scan_flutter/login.page.dart';
import 'package:card_scan_flutter/register.page.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_gemini/flutter_gemini.dart';
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: FirebaseOptions(
      apiKey: "AIzaSyBeXEbPLNTgkGr4oEPOJFILeorubbHueok",
      appId: "1:939531561317:android:430824a7b4a7edb733d98c",
      messagingSenderId: "939531561317",
      projectId: "cardsaver-ec5f1",
    ),
  );
  testFirestoreConnection();  // Verifica a conexão com o Firestore
  Gemini.init(apiKey: GEMINI_API_KEY);
  runApp(MyApp());
}

// Função para testar a conexão com o Firestore
void testFirestoreConnection() async {
  try {
    var snapshot = await FirebaseFirestore.instance.collection('cards').get();

    if (snapshot.docs.isNotEmpty) {
      print('Firestore conectado com sucesso!');
      for (var doc in snapshot.docs) {
        print('Documento encontrado: ${doc.data()}');
      }
    } else {
      print('Conexão feita, mas nenhum documento foi encontrado.');
    }
  } catch (e) {
    print('Erro ao conectar ao Firestore: $e');
  }
}

class MyApp extends StatelessWidget {
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      // home: RegisterPage(),
      routes: {
        "/login": (context) => LoginPage(),
        "/register": (context) => RegisterPage(),
        "/deck": (context) => DeckPage(), 
        "/ajuda": (context) => AjudaPage(),
      },
      initialRoute: '/login',
    );
  }
}
