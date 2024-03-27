import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:trello_wish/api/trello_api.dart' as trelloApi;
import 'package:trello_wish/models/member.dart';
import 'package:trello_wish/models/trelloCard.dart';
import 'package:trello_wish/screens/EditCardPage.dart';

class CardDetailPage extends StatefulWidget {
  final String cardId;

  CardDetailPage({Key? key, required this.cardId}) : super(key: key);

  @override
  _CardDetailPageState createState() => _CardDetailPageState();
}

class _CardDetailPageState extends State<CardDetailPage> {
  late Future<TrelloCard> _cardFuture;
  TrelloCard? _currentCard;

  @override
  void initState() {
    super.initState();
    _cardFuture = fetchCardDetails(widget.cardId);
  }

  Future<TrelloCard> fetchCardDetails(String cardId) async {
    final response = await http.get(
      Uri.parse(
          'https://api.trello.com/1/cards/$cardId?fields=id,name,desc,due,closed,idMembers&members=true&member_fields=fullName&key=${trelloApi.TrelloAPI.apiKey}&token=${trelloApi.TrelloAPI.apiToken}'),
    );

    if (response.statusCode == 200) {
      final jsonResponse = json.decode(response.body);
      List<Member> members = [];
      if (jsonResponse.containsKey('members')) {
        members = (jsonResponse['members'] as List)
            .map((memberJson) => Member.fromJson(memberJson))
            .toList();
      }
      return TrelloCard.fromJson(jsonResponse, members);
    } else {
      throw Exception('Failed to load card details');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Détails de la Carte'),
        backgroundColor: Colors.deepPurple,
      ),
      body: FutureBuilder<TrelloCard>(
        future: _cardFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            if (snapshot.hasError) {
              return Text("Erreur: ${snapshot.error}");
            }
            _currentCard = snapshot.data;
            final card = snapshot.data!;
            return SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Card(
                      elevation: 4,
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Nom de la Carte: ${card.name}',
                                style: TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.deepPurple)),
                            SizedBox(height: 10),
                            Text('Description: ${card.desc}',
                                style: TextStyle(fontSize: 16)),
                            if (card.due.isNotEmpty)
                              Text('Date d’échéance: ${card.due}',
                                  style: TextStyle(
                                      fontSize: 16, fontStyle: FontStyle.italic)),
                            if (card.closed)
                              Text('Carte archivée',
                                  style: TextStyle(color: Colors.red, fontSize: 16)),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(height: 20),
                    Text('Membres:',
                        style: TextStyle(
                            fontSize: 20, fontWeight: FontWeight.bold)),
                    ...card.members
                        .map((member) => ListTile(
                      leading: Icon(Icons.person),
                      title: Text(member.fullName),
                    ))
                        .toList(),
                    SizedBox(height: 20),
                    Text('Checklists:',
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                    ...card.checklists.expand((checklist) => [
                      ListTile(
                        title: Text(checklist.name,
                            style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                      ...checklist.items.map((item) => CheckboxListTile(
                        title: Text(item.name),
                        value: item.completed,
                        onChanged: (bool? value) {},
                      ))
                    ]),
                  ],
                ),
              ),
            );
          } else {
            return Center(child: CircularProgressIndicator());
          }
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          if (_currentCard != null) {
            Navigator.of(context)
                .push(MaterialPageRoute(
              builder: (context) => EditCardPage(card: _currentCard!),
            ))
                .then((value) {
              if (value == true) {
                setState(() {
                  _cardFuture = fetchCardDetails(widget.cardId);
                });
              }
            });
          }
        },
        backgroundColor: Colors.deepPurple,
        child: Icon(Icons.edit),
      ),
    );
  }
}
