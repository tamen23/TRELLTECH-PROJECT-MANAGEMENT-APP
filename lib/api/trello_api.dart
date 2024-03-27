import 'package:http/http.dart' as http;
import 'dart:convert';

class TrelloAPI {
  static const String apiKey = '';
  static const String apiToken = '';

  static Future<void> createTrelloBoard(String boardName) async {
    final Uri url = Uri.parse(
        'https://api.trello.com/1/boards/?name=$boardName&key=$apiKey&token=$apiToken');

    try {
      final response = await http.post(url);
      if (response.statusCode == 200) {
        var data = json.decode(response.body);
        print(
            "Board créé avec succès : ${data['name']} avec l'ID ${data['id']}");
      } else {
        print("Erreur lors de la création du board : ${response.body}");
      }
    } catch (e) {
      print("Exception lors de la création du board : $e");
    }
  }
}
