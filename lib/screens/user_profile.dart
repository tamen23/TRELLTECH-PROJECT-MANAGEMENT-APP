import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:trello_wish/api/trello_api.dart' as trelloApi;

class UserProfile extends StatefulWidget {
  @override
  _UserProfileState createState() => _UserProfileState();
}

class _UserProfileState extends State<UserProfile> {
  late Future<List<TrelloCard>> _cardsFuture;

  @override
  void initState() {
    super.initState();
    _cardsFuture = fetchUserCards();
  }

  Future<List<TrelloCard>> fetchUserCards() async {
    final response = await http.get(
      Uri.parse('https://api.trello.com/1/members/me/cards?key=${trelloApi.TrelloAPI.apiKey}&token=${trelloApi.TrelloAPI.apiToken}'),
    );

    if (response.statusCode == 200) {
      List<dynamic> cardsJson = json.decode(response.body);
      return cardsJson.map((json) => TrelloCard.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load user cards');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Profil Utilisateur'),
        backgroundColor: Colors.deepPurple,
      ),
      body: FutureBuilder<List<TrelloCard>>(
        future: _cardsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            if (snapshot.hasError) {
              return Text("Erreur: ${snapshot.error}");
            }
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    "Toutes vos cartes",
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.deepPurple,
                    ),
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    itemCount: snapshot.data!.length,
                    itemBuilder: (context, index) {
                      TrelloCard card = snapshot.data![index];
                      return Card(
                        child: ListTile(
                          title: Text(card.name),
                          subtitle: Text(card.desc),
                        ),
                      );
                    },
                  ),
                ),
              ],
            );
          } else {
            return Center(child: CircularProgressIndicator());
          }
        },
      ),
    );
  }
}

class TrelloCard {
  final String id;
  final String name;
  final String desc;

  TrelloCard({required this.id, required this.name, required this.desc});

  factory TrelloCard.fromJson(Map<String, dynamic> json) {
    return TrelloCard(
      id: json['id'],
      name: json['name'],
      desc: json['desc'] ?? 'Pas de description disponible',
    );
  }
}
