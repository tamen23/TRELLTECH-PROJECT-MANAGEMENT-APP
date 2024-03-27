import 'dart:convert';
import 'package:http/http.dart' as http;

class TrelloService {
  final String _apiKey = '68e9b7f0a24622a0ecb4a3177b825720';

  Future<bool> createBoard(String boardName, String userToken) async {
    final url = Uri.parse('https://api.trello.com/1/boards/?name=$boardName&key=$_apiKey&token=$userToken');
    final response = await http.post(url);

    if (response.statusCode == 200) {
      return true; // Board créé avec succès
    } else {
      print('Erreur lors de la création du board : ${response.body}');
      return false; // Échec de la création du board
    }
  }
}
