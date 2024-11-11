import 'package:card_scan_flutter/listar.page.dart';
import 'package:card_scan_flutter/camera.page.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class DeckPage extends StatefulWidget {
  @override
  _DeckPageState createState() => _DeckPageState();
}

class _DeckPageState extends State<DeckPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  void signOut(context) {
    Navigator.pushReplacementNamed(context, '/login');
  }

  void _showAddDeckDialog(BuildContext context) {
  String newDeckName = '';
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: Text('Criar Novo Deck'),
        content: TextField(
          onChanged: (value) {
            newDeckName = value;
          },
          decoration: InputDecoration(hintText: "Nome do Deck"),
        ),
        actions: <Widget>[
          TextButton(
            child: Text('Cancelar'),
            onPressed: () {
              Navigator.of(context).pop();
            },
          ),
          TextButton(
            child: Text('Criar'),
            onPressed: () async {
              if (newDeckName.isNotEmpty) {
                await _createNewDeck(newDeckName);
                Navigator.of(context).pop();
                Navigator.push(
                  context, 
                  MaterialPageRoute(
                    builder: (context) => CameraPage(deckId: newDeckName)
                  )
                );
              }
            },
          ),
        ],
      );
    },
  );
}

  Future<void> _createNewDeck(String deckName) async {
    try {
      // Criar um documento na coleção 'decks' com o ID sendo o nome do deck
      await _firestore.collection('decks').doc(deckName).set({
        'name': deckName,
        'createdAt': FieldValue.serverTimestamp(),
      });

      // Criar uma subcoleção dentro do documento do deck
      // Não precisamos adicionar nada aqui, pois as cartas serão adicionadas posteriormente
      // Mas podemos criar um documento vazio para garantir que a subcoleção exista
      await _firestore
          .collection('decks')
          .doc(deckName)
          .collection(deckName)
          .add({
        'placeholder': true,
        'createdAt': FieldValue.serverTimestamp(),
      });

      print('Deck "$deckName" criado com sucesso!');
    } catch (e) {
      print('Erro ao criar o deck: $e');
    }
  }

  // Função para excluir um deck
  Future<void> _deleteDeck(String deckName) async {
    try {
      // Primeiro, exclui todos os documentos na subcoleção de cartas do deck
      final cardsSnapshot = await _firestore
          .collection('decks')
          .doc(deckName)
          .collection(deckName)
          .get();
      
      // Exclui cada carta individualmente
      for (var doc in cardsSnapshot.docs) {
        await doc.reference.delete();
      }

      // Em seguida, exclui o documento do deck
      await _firestore.collection('decks').doc(deckName).delete();

      print('Deck "$deckName" excluído com sucesso!');
      
      // Opcional: Mostrar um SnackBar de sucesso
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Deck excluído com sucesso!')),
      );
    } catch (e) {
      print('Erro ao excluir o deck: $e');
      
      // Opcional: Mostrar um SnackBar de erro
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao excluir o deck')),
      );
    }
  }

   // Função para mostrar o diálogo de confirmação de exclusão
  void _showDeleteDeckDialog(String deckName) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Excluir Deck'),
          content: Text('Tem certeza que deseja excluir este deck?'),
          actions: <Widget>[
            TextButton(
              child: Text('Cancelar'),
              onPressed: () {
                Navigator.of(context).pop(); // Fecha o diálogo
              },
            ),
            TextButton(
              child: Text('Confirmar'),
              onPressed: () {
                Navigator.of(context).pop(); // Fecha o diálogo
                _deleteDeck(deckName); // Chama a função de exclusão
              },
            ),
          ],
        );
      },
    );
  }

  //Função de update do nome do deck:
 Future<void> _renameDeck(String oldDeckId, String newDeckName) async {
  try {
    // Cria o novo documento com o novo nome de deck
    DocumentSnapshot oldDeckSnapshot = await _firestore.collection('decks').doc(oldDeckId).get();

    // Verifica se o documento antigo existe
    if (oldDeckSnapshot.exists) {
      await _firestore.collection('decks').doc(newDeckName).set({
        'name': newDeckName,
        'createdAt': oldDeckSnapshot['createdAt'], // Copia a data de criação
      });

      // Pega as cartas do deck antigo
      QuerySnapshot cardsSnapshot = await _firestore
          .collection('decks')
          .doc(oldDeckId)
          .collection(oldDeckId)
          .get();

      // Copia cada carta para a nova sub-coleção
      for (var cardDoc in cardsSnapshot.docs) {
        await _firestore
            .collection('decks')
            .doc(newDeckName)
            .collection(newDeckName)
            .doc(cardDoc.id)
            .set(cardDoc.data() as Map<String, dynamic>); 
      }

      // Remove o deck antigo
      await _deleteDeck(oldDeckId);
      print('Deck "$oldDeckId" renomeado para "$newDeckName" com sucesso!');

      // Opcional: mostrar um SnackBar de sucesso
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Deck renomeado com sucesso!')),
      );
    } else {
      print('Deck "$oldDeckId" não encontrado.');
    }
  } catch (e) {
    print('Erro ao renomear o deck: $e');
    
    // Opcional: mostrar um SnackBar de erro
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Erro ao renomear o deck')),
    );
  }
}


void _showEditDeckDialog(BuildContext context, String deckId, String currentName) {
  String newDeckName = currentName;

  showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: Text('Editar Nome do Deck'),
        content: TextField(
          onChanged: (value) {
            newDeckName = value;
          },
          controller: TextEditingController(text: currentName),
          decoration: InputDecoration(hintText: "Novo Nome do Deck"),
        ),
        actions: <Widget>[
          TextButton(
            child: Text('Cancelar'),
            onPressed: () {
              Navigator.of(context).pop();
            },
          ),
          TextButton(
            child: Text('Confirmar'),
            onPressed: () {
              if (newDeckName.isNotEmpty && newDeckName != currentName) {
                _renameDeck(deckId, newDeckName);
              }
              Navigator.of(context).pop();
            },
          ),
        ],
      );
    },
  );
}


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 181, 190, 195),
      appBar: AppBar(
        title: Text('CardSaver'),
        actions: [
          IconButton(
            onPressed: () => signOut(context),
            icon: Icon(Icons.logout),
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _firestore.collection('decks').snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return Center(child: CircularProgressIndicator());
          }

          var decks = snapshot.data!.docs;
          return ListView.builder(
            itemCount: decks.length,
            itemBuilder: (context, index) {
              var deck = decks[index];
              return ListTile(
                title: Text(deck['name']),
                subtitle: Text('Criado em: ${deck['createdAt']?.toDate().toString() ?? 'Data desconhecida'}'),
                leading: IconButton(
                  icon: Icon(Icons.edit),
                  onPressed: () => _showEditDeckDialog(context, deck.id, deck['name']),
                ),
                trailing: IconButton(
                  icon: Icon(Icons.delete, color: Colors.red),
                  onPressed: () => _showDeleteDeckDialog(deck.id), // Botão de exclusão
                ),
                onTap: () {
                  Navigator.push(
                    context, 
                    MaterialPageRoute(
                      builder: (context) => ListarPage(deckName: deck.id,)
                    )
                  );
                },
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddDeckDialog(context),
        child: Icon(Icons.add),
      ),
    );
  }
}