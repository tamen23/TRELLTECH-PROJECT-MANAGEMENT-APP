import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:trello_wish/api/trello_api.dart' as trelloApi;

class CreateCardPage extends StatefulWidget {
  final String boardId;

  CreateCardPage({Key? key, required this.boardId}) : super(key: key);

  @override
  _CreateCardPageState createState() => _CreateCardPageState();
}

class _CreateCardPageState extends State<CreateCardPage> {
  final _formKey = GlobalKey<FormState>();
  String _cardName = '';
  String _cardDesc = '';
  String _selectedListId = '';
  late Future<List<dynamic>> _listsFuture;

  @override
  void initState() {
    super.initState();
    _listsFuture = fetchLists(widget.boardId);
  }

  Future<List<dynamic>> fetchLists(String boardId) async {
    final response = await http.get(
      Uri.parse('https://api.trello.com/1/boards/$boardId/lists?key=${trelloApi.TrelloAPI.apiKey}&token=${trelloApi.TrelloAPI.apiToken}'),
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to load lists');
    }
  }

  Future<void> createCard() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      final url = Uri.parse('https://api.trello.com/1/cards?name=$_cardName&desc=$_cardDesc&idList=$_selectedListId&key=${trelloApi.TrelloAPI.apiKey}&token=${trelloApi.TrelloAPI.apiToken}');
      final response = await http.post(url);
      
      if (response.statusCode == 200) {
        Navigator.of(context).pop(true); // Return true if the card was successfully created
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to create card')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Create New Card')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: <Widget>[
              TextFormField(
                decoration: InputDecoration(labelText: 'Card Name'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a card name';
                  }
                  return null;
                },
                onSaved: (value) {
                  _cardName = value!;
                },
              ),
              TextFormField(
                decoration: InputDecoration(labelText: 'Card Description'),
                onSaved: (value) {
                  _cardDesc = value ?? '';
                },
              ),
              FutureBuilder<List<dynamic>>(
                future: _listsFuture,
                builder: (context, snapshot) {
                  if (!snapshot.hasData) return CircularProgressIndicator();
                  List<DropdownMenuItem<String>> items = snapshot.data!
                      .map<DropdownMenuItem<String>>((list) => DropdownMenuItem<String>(
                            value: list['id'],
                            child: Text(list['name']),
                          ))
                      .toList();
                  return DropdownButtonFormField<String>(
                    value: _selectedListId.isEmpty ? null : _selectedListId,
                    onChanged: (value) {
                      setState(() {
                        _selectedListId = value!;
                      });
                    },
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please select a list';
                      }
                      return null;
                    },
                    items: items,
                    decoration: InputDecoration(labelText: 'List'),
                  );
                },
              ),
              ElevatedButton(
                onPressed: createCard,
                child: Text('Create Card'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
