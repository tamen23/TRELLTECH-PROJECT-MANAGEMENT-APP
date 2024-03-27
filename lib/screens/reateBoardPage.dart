import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:trello_wish/api/trello_api.dart' as trelloApi;

class CreateBoardPage extends StatefulWidget {
  @override
  _CreateBoardPageState createState() => _CreateBoardPageState();
}

class _CreateBoardPageState extends State<CreateBoardPage> {
  final _formKey = GlobalKey<FormState>();
  String _boardName = '';
  String _selectedWorkspaceId = '';
  String _selectedTemplateId = ''; 

  Future<List<dynamic>> fetchWorkspaces() async {
    final response = await http.get(Uri.parse('https://api.trello.com/1/members/me/organizations?key=${trelloApi.TrelloAPI.apiKey}&token=${trelloApi.TrelloAPI.apiToken}'));
    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to load workspaces');
    }
  }

  Future<List<dynamic>> fetchTemplates() async {
    final response = await http.get(Uri.parse('https://api.trello.com/1/member/me/boards?filter=open&fields=name,idOrganization,url&lists=open&list_fields=name&key=${trelloApi.TrelloAPI.apiKey}&token=${trelloApi.TrelloAPI.apiToken}'));
    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to load templates');
    }
  }

  Future<void> createBoard() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      final url = Uri.parse('https://api.trello.com/1/boards/?name=$_boardName&idOrganization=$_selectedWorkspaceId&idBoardSource=$_selectedTemplateId&keepFromSource=all&key=${trelloApi.TrelloAPI.apiKey}&token=${trelloApi.TrelloAPI.apiToken}');
      final response = await http.post(url);
      if (response.statusCode == 200) {
        Navigator.of(context).pop(true); 
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to create board')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Create New Board'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: <Widget>[
              TextFormField(
                decoration: InputDecoration(labelText: 'Board Name'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a board name';
                  }
                  return null;
                },
                onSaved: (value) {
                  _boardName = value!;
                },
              ),
              FutureBuilder<List<dynamic>>(
                future: fetchWorkspaces(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) return CircularProgressIndicator();
                  List<DropdownMenuItem<String>> items = snapshot.data!
                      .map<DropdownMenuItem<String>>((workspace) => DropdownMenuItem<String>(
                            value: workspace['id'],
                            child: Text(workspace['displayName']),
                          ))
                      .toList();
                  return DropdownButtonFormField<String>(
                    value: _selectedWorkspaceId.isEmpty ? null : _selectedWorkspaceId,
                    onChanged: (value) {
                      setState(() {
                        _selectedWorkspaceId = value!;
                      });
                    },
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please select a workspace';
                      }
                      return null;
                    },
                    items: items,
                    decoration: InputDecoration(labelText: 'Workspace'),
                  );
                },
              ),
              FutureBuilder<List<dynamic>>(
                future: fetchTemplates(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) return CircularProgressIndicator();
                  List<DropdownMenuItem<String>> items = snapshot.data!
                      .map<DropdownMenuItem<String>>((template) => DropdownMenuItem<String>(
                            value: template['id'],
                            child: Text(template['name']),
                          ))
                      .toList();
                  return DropdownButtonFormField<String>(
                    value: _selectedTemplateId.isEmpty ? null : _selectedTemplateId,
                    onChanged: (value) {
                      setState(() {
                        _selectedTemplateId = value!;
                      });
                    },
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please select a template';
                      }
                      return null;
                    },
                    items: items,
                    decoration: InputDecoration(labelText: 'Template'),
                  );
                },
              ),
              ElevatedButton(
                onPressed: createBoard,
                child: Text('Create Board'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
