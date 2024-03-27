import 'package:flutter/foundation.dart';

class UserData extends ChangeNotifier {
  String _userName = '';
  String _userId = '';
  List<String> _boards = [];
  List<String> _workspaces = [];

  String get userName => _userName;
  String get userId => _userId;
  List<String> get boards => _boards;
  List<String> get workspaces => _workspaces;

  void setUserData({
    required String userName,
    required List<String> workspaces,
  }) {
    _userName = userName;
    _userId = userId;
    _workspaces = workspaces;
    _boards = boards;

    notifyListeners(); // Notifie les widgets qui écoutent ce modèle
  }

}
