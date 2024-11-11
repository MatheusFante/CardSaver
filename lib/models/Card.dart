class Card 
{
  //Atributos:
  String id;
  String name;
  String imageUrl;
  String type;
  String description;

  //Construtor Padrão:
  Card({
    required this.id,
    required this.name,
    required this.imageUrl,
    required this.type,
    required this.description
  });

  //Construtor nomeado fromMap(quando pegamos informação do banco de dados):
  Card.fromMap(Map<String, dynamic> map): 
  id = map["id"], 
  name = map["name"], 
  imageUrl = map["imageUrl"], 
  type = map["type"],
  description = map["description"];

  //ToMap (quando queremos enviar informação para o banco de dados):
  Map<String, dynamic> toMap() {
    return{
      "id": id,
      "name": name,
      "imageUrl": imageUrl,
      "type": type,
      "description": description,
    };
  }
  
}

