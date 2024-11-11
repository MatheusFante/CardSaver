import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:card_scan_flutter/camera.page.dart'; 

class ListarPage extends StatefulWidget {
  final String deckName;

  const ListarPage({Key? key, required this.deckName}) : super(key: key);

  @override
  _ListarPageState createState() => _ListarPageState();
}

class _ListarPageState extends State<ListarPage> {
  void signOut(context) {
    Navigator.pushReplacementNamed(context, '/login');
  }

  // Função para excluir uma carta do deck
  Future<void> _deleteCard(String cardId) async {
    try {
      await FirebaseFirestore.instance
          .collection('decks')
          .doc(widget.deckName)
          .collection(widget.deckName)  
          .doc(cardId)
          .delete();

      print('Carta excluída com sucesso!');
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Carta excluída com sucesso!')),
      );
    } catch (e) {
      print('Erro ao excluir a carta: $e');
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao excluir a carta')),
      );
    }
  }

  // Função para mostrar o diálogo de confirmação de exclusão
  void _showDeleteCardDialog(String cardId, String cardName) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Excluir Carta'),
          content: Text('Tem certeza que deseja excluir a carta "$cardName"?'),
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
                Navigator.of(context).pop();
                _deleteCard(cardId);
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
        title: Text('Cartas de ${widget.deckName}'),
        actions: [
          IconButton(
            onPressed: () => signOut(context),
            icon: Icon(Icons.logout),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('decks')
                  .doc(widget.deckName)
                  .collection(widget.deckName)  
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(child: Text('Erro ao carregar cartas.'));
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }

                final cards = snapshot.data!.docs;
                
                if (cards.isEmpty) {
                  return Center(child: Text('Nenhuma carta neste deck.'));
                }

                return ListView.builder(
                  itemCount: cards.length,
                  itemBuilder: (context, index) {
                    final cardData = cards[index].data() as Map<String, dynamic>;
                    final cardId = cards[index].id;
                    return Card(
                      margin: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                      child: ListTile(
                        leading: cardData['imageUrl'] != null
                            ? Image.network(
                                cardData['imageUrl'],
                                height: 60,
                                width: 40,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) =>
                                    Icon(Icons.image_not_supported),
                              )
                            : Icon(Icons.image_not_supported),
                        title: Text(cardData['name'] ?? 'Nome desconhecido'),
                        subtitle: Text(cardData['type'] ?? 'Tipo desconhecido'),
                        trailing: IconButton(
                          icon: Icon(Icons.delete, color: Colors.red),
                          onPressed: () => _showDeleteCardDialog(
                            cardId, 
                            cardData['name'] ?? 'Carta'
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: OutlinedButton(
              style: OutlinedButton.styleFrom(
                minimumSize: Size(200, 60),
                side: BorderSide(color: Color.fromARGB(255, 242, 245, 242)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.all(Radius.circular(20)),
                ),
              ),
              onPressed: () {
                // Implementar a funcionalidade de exportação aqui
              },
              child: Text('Exportar',
                  style: TextStyle(color: Color.fromARGB(255, 10, 10, 10))),
            ),
          ),
        ],
      ),
      // Adicione o FloatingActionButton aqui
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Navega para a CameraPage passando o nome do deck atual
          Navigator.push(
            context, 
            MaterialPageRoute(
              builder: (context) => CameraPage(deckId: widget.deckName)
            )
          );
        },
        child: Icon(Icons.add_a_photo),
        backgroundColor: Colors.blue,
      ),
    );
  }
}