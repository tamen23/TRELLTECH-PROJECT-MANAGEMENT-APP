import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:trello_wish/api/trello_api.dart' as trelloApi;
import 'package:trello_wish/models/member.dart';
import 'package:trello_wish/models/trelloCard.dart';
import 'package:trello_wish/screens/card_detail_page.dart';
import 'package:intl/intl.dart';

class EditCardPage extends StatefulWidget {
  final TrelloCard card;

  EditCardPage({Key? key, required this.card}) : super(key: key);

  @override
  _EditCardPageState createState() => _EditCardPageState();
}

class _EditCardPageState extends State<EditCardPage> {
  final _formKey = GlobalKey<FormState>();
  late String _name;
  late String _desc;
  late String _due;
  late TextEditingController _dueController;
  List<String> _selectedMemberIds = [];
  List<Member> _boardMembers = [];
  @override
  void initState() {
    super.initState();
    _name = widget.card.name;
    _desc = widget.card.desc;
    _due = widget.card.due;
    _dueController = TextEditingController(text: _due);

    fetchBoardIdFromCardId(widget.card.id).then((boardId) {
      fetchAndMarkBoardMembers(boardId, widget.card.id);
    });
  }

  Future<void> updateCard() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      final url = Uri.parse(
          'https://api.trello.com/1/cards/${widget.card.id}?key=${trelloApi.TrelloAPI.apiKey}&token=${trelloApi.TrelloAPI.apiToken}');
      Map<String, dynamic> updates = {
        'name': _name,
        'desc': _desc,
        'due': _due
      };
      final response = await http.put(url, body: updates);

      if (response.statusCode != 200) {
        throw Exception('Failed to update card info');
      }
    }
  }

  Future<void> updateCardAndMembers() async {
    await updateCard(); 
    await updateMembersOfCard(); 

    ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Card and members updated successfully')));
    Navigator.of(context).pop(true); // Retourner en arrière avec succès
  }

  Future<List<Member>> fetchBoardMembers(String boardId) async {
    var url = Uri.parse(
        'https://api.trello.com/1/boards/$boardId/members?key=${trelloApi.TrelloAPI.apiKey}&token=${trelloApi.TrelloAPI.apiToken}');
    var response = await http.get(url);
    if (response.statusCode == 200) {
      List<dynamic> membersJson = json.decode(response.body);
      List<Member> members =
          membersJson.map((json) => Member.fromJson(json)).toList();
      return members;
    } else {
      throw Exception('Failed to load board members');
    }
  }

  Future<void> addMemberToCard(String cardId, String memberId) async {
    var url = Uri.parse(
        'https://api.trello.com/1/cards/$cardId/idMembers?key=${trelloApi.TrelloAPI.apiKey}&token=${trelloApi.TrelloAPI.apiToken}&value=$memberId');
    var response = await http.post(url);
    if (response.statusCode == 200) {
      print("Member added successfully");
    }
  }

  Future<void> removeMemberFromCard(String cardId, String memberId) async {
    var url = Uri.parse(
        'https://api.trello.com/1/cards/$cardId/idMembers/$memberId?key=${trelloApi.TrelloAPI.apiKey}&token=${trelloApi.TrelloAPI.apiToken}');
    var response = await http.delete(url);
    if (response.statusCode == 200) {
      print("Member removed successfully");
    }
  }

  Future<void> updateMembersOfCard() async {
    final currentMembers = await fetchCardMembers(widget.card.id);

    for (var member in _boardMembers) {
      final isCurrentlyAssigned = currentMembers.any((m) => m.id == member.id);

      if (member.isSelected && !isCurrentlyAssigned) {
        await addMemberToCard(widget.card.id, member.id);
      } else if (!member.isSelected && isCurrentlyAssigned) {
        await removeMemberFromCard(widget.card.id, member.id);
      }
    }
  }

  Future<List<Member>> fetchCardMembers(String cardId) async {
    var url = Uri.parse(
        'https://api.trello.com/1/cards/$cardId/members?key=${trelloApi.TrelloAPI.apiKey}&token=${trelloApi.TrelloAPI.apiToken}');
    var response = await http.get(url);
    if (response.statusCode == 200) {
      List<dynamic> membersJson = json.decode(response.body);
      return membersJson.map((json) => Member.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load card members');
    }
  }

  Future<String> fetchBoardIdFromCardId(String cardId) async {
    var url = Uri.parse(
        'https://api.trello.com/1/cards/$cardId?key=${trelloApi.TrelloAPI.apiKey}&token=${trelloApi.TrelloAPI.apiToken}');
    var response = await http.get(url);
    if (response.statusCode == 200) {
      var data = json.decode(response.body);
      return data[
          'idBoard']; 
    } else {
      throw Exception('Failed to load card details');
    }
  }

  Future<void> fetchAndMarkBoardMembers(String boardId, String cardId) async {
    final boardMembers = await fetchBoardMembers(boardId);
    final cardMembers =
        await fetchCardMembers(cardId); 

    for (var boardMember in boardMembers) {
      boardMember.isSelected = cardMembers.any((m) => m.id == boardMember.id);
    }

    setState(() {
      _boardMembers = boardMembers;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Edit Card'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              children: [
                TextFormField(
                  initialValue: _name,
                  decoration: InputDecoration(labelText: 'Card Name'),
                  onSaved: (value) => _name = value!,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a name';
                    }
                    return null;
                  },
                ),
                TextFormField(
                  initialValue: _desc,
                  decoration: InputDecoration(labelText: 'Description'),
                  onSaved: (value) => _desc = value!,
                ),
                TextFormField(
                  controller: _dueController,
                  decoration: InputDecoration(labelText: 'Due Date'),
                  readOnly: true,
                  onTap: () async {
                    DateTime? pickedDate = await showDatePicker(
                      context: context,
                      initialDate: DateTime.now(),
                      firstDate: DateTime(2000),
                      lastDate: DateTime(2025),
                    );
                    if (pickedDate != null) {
                      setState(() {
                        _due = pickedDate
                            .toIso8601String(); // Mettez à jour la variable _due avec la nouvelle date
                        _dueController.text = DateFormat('yyyy-MM-dd').format(
                            pickedDate); // Mettez à jour le texte du contrôleur avec le format de date souhaité
                      });
                    }
                  },
                ),
                Container(
                  height: 300, 
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: _boardMembers.length,
                    itemBuilder: (context, index) {
                      return CheckboxListTile(
                        title: Text(_boardMembers[index].fullName),
                        value: _boardMembers[index].isSelected,
                        onChanged: (bool? value) {
                          setState(() {
                            _boardMembers[index].isSelected = value!;
                          });
                        },
                      );
                    },
                  ),
                ),

                ElevatedButton(
                  onPressed: () {
                    updateCardAndMembers();
                  },
                  child: Text('Update Card'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
