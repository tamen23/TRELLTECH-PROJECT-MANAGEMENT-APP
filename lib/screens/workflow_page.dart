import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:trello_wish/api/trello_api.dart' as trelloApi;
import 'package:trello_wish/models/board.dart';
import 'package:trello_wish/screens/board_detail_page.dart';
import 'package:trello_wish/screens/reateBoardPage.dart';

class WorkflowsPage extends StatefulWidget {
  @override
  _WorkflowsPageState createState() => _WorkflowsPageState();
}

class _WorkflowsPageState extends State<WorkflowsPage> {
  Future<bool> deleteBoard(String boardId) async {
    final url = 'https://api.trello.com/1/boards/$boardId?key=${trelloApi.TrelloAPI.apiKey}&token=${trelloApi.TrelloAPI.apiToken}';
    final response = await http.delete(Uri.parse(url));

    if (response.statusCode == 200) {
      print("Tableau supprimé avec succès.");
      return true;
    } else {
      print("Erreur lors de la suppression du tableau: ${response.body}");
      return false;
    }
  }

  late Future<Map<String, List<Board>>> _boardsFuture;

  @override
  void initState() {
    super.initState();
    _boardsFuture = fetchBoardsGroupedByWorkspace();
  }

Future<Map<String, List<Board>>> fetchBoardsGroupedByWorkspace() async {
  final workspaceResponse = await http.get(
    Uri.parse('https://api.trello.com/1/members/me/organizations?key=${trelloApi.TrelloAPI.apiKey}&token=${trelloApi.TrelloAPI.apiToken}'),
  );
  
  Map<String, String> workspaceNames = {};
  if (workspaceResponse.statusCode == 200) {
    List<dynamic> workspaceJson = json.decode(workspaceResponse.body);
    workspaceJson.forEach((workspace) {
      workspaceNames[workspace['id']] = workspace['displayName'];
    });
  } else {
    throw Exception('Failed to load workspaces');
  }

  final boardResponse = await http.get(
    Uri.parse('https://api.trello.com/1/members/me/boards?fields=name,id,url,idOrganization&key=${trelloApi.TrelloAPI.apiKey}&token=${trelloApi.TrelloAPI.apiToken}'),
  );

  if (boardResponse.statusCode == 200) {
    List<dynamic> boardJson = json.decode(boardResponse.body);
    List<Board> boards = boardJson.map((json) => Board.fromJson(json, workspaceNames)).toList();

  Map<String, List<Board>> boardsByWorkspace = {for (var id in workspaceNames.keys) workspaceNames[id]!: []};
    for (var board in boards) {
      String workspaceName = board.workspaceName;
      boardsByWorkspace.putIfAbsent("Autre", () => []);
      boardsByWorkspace[workspaceName]!.add(board);
    }

    return boardsByWorkspace;
  } else {
    throw Exception('Failed to load boards');
  }
}

@override
Widget build(BuildContext context) {
  return Scaffold(
    appBar: AppBar(title: Text('Workflows'),
      backgroundColor: Colors.deepPurple[800],
      elevation: 4,
    ),
    body: FutureBuilder<Map<String, List<Board>>>(
      future: _boardsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.done) {
          if (snapshot.hasError) {
            return Text("Error: ${snapshot.error}", style: TextStyle(color: Colors.red));
          }

          var workspaces = snapshot.data!;
          List<String> sortedKeys = workspaces.keys.toList();

          bool hasBoardsInOther = workspaces["Autre"] != null && workspaces["Autre"]!.isNotEmpty;

         sortedKeys.sort((a, b) {
            if (a == "Autre") return hasBoardsInOther ? -1 : 1;
            if (b == "Autre") return hasBoardsInOther ? 1 : -1;

            bool isEmptyA = workspaces[a]!.isEmpty;
            bool isEmptyB = workspaces[b]!.isEmpty;
            if (isEmptyA && !isEmptyB) return 1;
            if (!isEmptyA && isEmptyB) return -1;

            return a.compareTo(b);
          });

          if (hasBoardsInOther) {
            sortedKeys.remove("Autre");
            int indexBeforeFirstEmpty = sortedKeys.lastIndexWhere((k) => workspaces[k]!.isNotEmpty);
            sortedKeys.insert(indexBeforeFirstEmpty + 1, "Autre");
          }

          return ListView(
            children: sortedKeys.map<Widget>((key) {
              var boards = workspaces[key]!;
              return ExpansionTile(

                title: Text('${key} (${boards.length})', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.deepPurple)),
                children: boards.isNotEmpty
                    ? boards.map<Widget>((board) {
                        return ListTile(
                          title: Text(board.name, style: TextStyle(color: Colors.deepPurple[900])),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: <Widget>[
                              IconButton(
                                icon: Icon(Icons.delete, color: Colors.red),
                                onPressed: () async {
                                  final shouldDelete = await showDialog<bool>(
                                    context: context,
                                    builder: (context) => AlertDialog(
                                      title: Text('Supprimer'),
                                      content: Text('Voulez-vous vraiment supprimer ce tableau ?'),
                                      actions: <Widget>[
                                        TextButton(
                                          child: Text('Annuler'),
                                          onPressed: () => Navigator.of(context).pop(false),
                                        ),
                                        TextButton(
                                          child: Text('Supprimer'),
                                          onPressed: () => Navigator.of(context).pop(true),
                                        ),
                                      ],
                                    ),
                                  ) ?? false;

                                  if (shouldDelete) {
                                    final deleted = await deleteBoard(board.id);
                                    if (deleted) {
                                      setState(() {
                                        _boardsFuture = fetchBoardsGroupedByWorkspace(); // Rafraîchir après suppression
                                      });
                                    }
                                  }
                                },
                              ),
                              Icon(Icons.arrow_forward_ios, color: Colors.deepPurple[800]),
                            ],
                          ),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => BoardDetailPage(boardId: board.id)),
                            );
                          },
                        );
                      }).toList()
                    : [ListTile(title: Text("Pas de tableau"))],
              );
            }).toList(),
          );
        } else {
          return Center(child: CircularProgressIndicator());
        }
      },
    ),
floatingActionButton: FloatingActionButton(
  onPressed: () {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => CreateBoardPage()),
    ).then((value) {
      // Si la page de création retourne true, rafraîchir la liste des tableaux
      if (value == true) {
        setState(() {
          _boardsFuture = fetchBoardsGroupedByWorkspace(); // Rafraîchir les tableaux
        });
      }
    });
  },
  backgroundColor: Colors.deepPurple,
  child: Icon(Icons.add),
),
  );
}

}


