import 'dart:io';
import 'dart:typed_data';
import 'package:camera/camera.dart';
import 'package:card_scan_flutter/listar.page.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart'; 
import 'package:dash_chat_2/dash_chat_2.dart';
import 'package:flutter_gemini/flutter_gemini.dart';

class CameraPage extends StatefulWidget 
{
  final String deckId; 
  const CameraPage({Key? key, required this.deckId}) : super(key: key);

  @override
  _CameraPageState createState() => _CameraPageState();
}

class _CameraPageState extends State<CameraPage> {
  final Gemini gemini = Gemini.instance;
  CameraController? _controller;

  // Lista para armazenar as cartas reconhecidas
  List<Map<String, dynamic>> recognizedCards = [];

  //Lista das imagens enviadas em formato de mensagem para o GeminiAI
  List<ChatMessage> messages = [];

  ChatUser currentUser = ChatUser(id: "0", firstName: "User");
  ChatUser geminiUser = ChatUser(id: "1", firstName: "Gemini");

  @override
  void initState() 
  {
    super.initState();
  }

  @override
  void dispose() {
    _controller?.dispose(); // Libera o controlador da câmera ao sair
    super.dispose();
  }

 void _sendMessage(ChatMessage chatMessage) {
  setState(() {
    messages = [chatMessage, ...messages];
  });
  try {
    String question = chatMessage.text;
    List<Uint8List>? images;
    if (chatMessage.medias?.isNotEmpty ?? false) {
      images = [
        File(chatMessage.medias!.first.url).readAsBytesSync(),
      ];
    }

    String fullResponse = ""; // Variável para armazenar a resposta completa

    gemini
        .streamGenerateContent(
      question,
      images: images,
    )
        .listen((event) {
      String partialResponse = event.content?.parts?.fold(
              "", (previous, current) => "$previous${current.text}") ??
          "";
      
      fullResponse += partialResponse; // Concatena a resposta parcial

      ChatMessage? lastMessage = messages.firstOrNull;
      if (lastMessage != null && lastMessage.user == geminiUser) {
        lastMessage = messages.removeAt(0);
        lastMessage.text = fullResponse;
        setState(() {
          messages = [lastMessage!, ...messages];
        });
      } else {
        ChatMessage message = ChatMessage(
          user: geminiUser,
          createdAt: DateTime.now(),
          text: fullResponse,
        );
        setState(() {
          messages = [message, ...messages];
        });
      }
    }, onDone: () async {
      // Quando o stream terminar, processa a resposta completa
      String cleanedResponse = fullResponse.trim().replaceAll('\n', ' ');
      print("Resposta do GeminiAI: $cleanedResponse");
      
      // Chama a função para buscar a carta no Firestore e aguarda o resultado
      final cardData = await fetchCardFromFirestore(cleanedResponse);
      if (cardData != null) {
      print('Carta processada com sucesso');
      // Aqui podemos adicionar lógica adicional se necessário
      // Por exemplo, atualizar a UI ou mostrar uma mensagem de sucesso
     } else {
    print('Não foi possível processar a carta');
    // Aqui podemos adicionar lógica para tratar o caso de falha
    // Por exemplo, mostrar uma mensagem de erro para o usuário
  }
    });
  } catch (e) {
    print("Erro ao enviar mensagem: $e");
  }
}

  //enviar a imagem para o geminiAI
  void _sendMedia() async 
  {
    ImagePicker picker = ImagePicker();
    XFile? file = await picker.pickImage(
      source: ImageSource.camera,
      );
    if (file != null) 
    {
      ChatMessage chatMessage = ChatMessage(
        user: currentUser, 
        createdAt: DateTime.now(), 
        text:"Faça o reconhecimento desta carta de Magic e me retorne SOMENTE o nome desta carta, e nada mais.", 
        medias: [
          ChatMedia(
            url: file.path, 
            fileName: "", 
            type: MediaType.image,
          )
       ],
      );
      _sendMessage(chatMessage);
    }
  }

  // Função para buscar a carta no Firestore com base no nome reconhecido
Future<Map<String, dynamic>?> fetchCardFromFirestore(String cleanedResponse) async {
  try {
    // Normaliza o nome da carta (remove espaços extras e converte para lowercase)
    final normalizedCardName = cleanedResponse.trim().toLowerCase();
    print("Iniciando busca no Firestore para carta: '$normalizedCardName'");

    // Busca a carta na coleção principal 'cards' no firestore
    final snapshot = await FirebaseFirestore.instance
        .collection('cards')
        .where('name', isEqualTo: normalizedCardName)
        .get();

    if (snapshot.docs.isNotEmpty) {
      final cardData = snapshot.docs.first.data();
      
      // Adiciona a carta ao deck específico
        await FirebaseFirestore.instance
            .collection('decks')
            .doc(widget.deckId)
            .collection(widget.deckId)
            .add({
          ...cardData,
          'addedAt': FieldValue.serverTimestamp(),
        });

        print('Carta encontrada e adicionada ao deck ${widget.deckId}');
        print('Nome: ${cardData['name']}');
        print('Dados completos da carta: $cardData');

      setState(() {
        // Verifica se a carta já existe na lista antes de adicionar
        if (!recognizedCards.any((card) => card['name'] == cardData['name'])) {
          recognizedCards.add(cardData);
          print('Carta adicionada à lista de cartas reconhecidas');
        } else {
          print('Carta já existe na lista de cartas reconhecidas');
        }
      });

      return cardData;
    } else {
      print('⚠️ Carta não encontrada no Firestore.');
      print('Verifique se o nome "$cleanedResponse" está correto na base de dados.');
      return null;
    }
  } catch (e) {
    print('❌ Erro ao buscar carta no Firestore: $e');
    // Você pode querer implementar alguma lógica de retry aqui
    return null;
  }
}

    void signOut(context) {
    Navigator.pushReplacementNamed(context, '/login');
  }

  void SendDeck(context) {
    Navigator.pushReplacementNamed(context, '/deck');
  }

 // Método para navegar para a página ListarPage do deck atual
  void SendListar(context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ListarPage(deckName: widget.deckId),
      ),
    );
  }

  void SendAjuda(context) {
    Navigator.pushReplacementNamed(context, '/ajuda');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 181, 190, 195),
      appBar: AppBar(title: Text(''), actions: []),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: <Widget>[
            DrawerHeader(
              decoration: BoxDecoration(
                color: const Color.fromARGB(255, 195, 201, 206),
              ),
              child: Text(
                'Menu',
                style: TextStyle(
                  color: (Colors.black),
                  fontSize: 24,
                ),
              ),
            ),
            ListTile(
                leading: Icon(Icons.home),
                title: Text('Deck'),
                onTap: () {
                  Navigator.pushNamed(context, '/deck');
                }),
            ListTile(
                leading: Icon(Icons.person),
                title: Text('Listar cartas'),
                onTap: () {
                  SendListar(context); 
                }),
            ListTile(
                leading: Icon(Icons.settings),
                title: Text('Ajuda'),
                onTap: () {
                  Navigator.pushNamed(context, '/ajuda');
                }),
            const Divider(),
            IconButton(
              onPressed: () {},
              icon: const Icon(Icons.sunny),
            ),
            const IconButton(
              onPressed: null,
              icon: Icon(Icons.dark_mode),
            ),
            ListTile(
              leading: Icon(Icons.logout),
              title: Text('Sair'),
              onTap: () => signOut(context),
            ),
          ],
        ),
      ),
      body: Stack(
        children: <Widget>[
          // Prévia das cartas reconhecidas (imagens do Firestore)
          Padding(
          padding: const EdgeInsets.all(3.0),
          child: SingleChildScrollView(
          child: Wrap(
          spacing: 8.0, // Espaço horizontal entre as cartas
          runSpacing: 8.0, // Espaço vertical entre as linhas
          alignment: WrapAlignment.start,
          children: recognizedCards.map((card) {
            return Image.network(
              card['imageUrl'],
              width: 95, // Largura da carta
              height: 128, // Altura da carta
              fit: BoxFit.cover,
            );
          }).toList(),
        ),
      ),
    ),

    // Botão de captura da câmera
    Align(
      alignment: Alignment.bottomCenter,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 20.0),
        child: IconButton(
          icon: Icon(Icons.camera_alt),
          iconSize: 50.0,
          color: const Color.fromARGB(255, 31, 32, 32),
          onPressed: () {
            _sendMedia();
          },
        ),
      ),
    ),
  ],
)
);
  }
}

