class Board {
  final String name;
  final String id;
  final String url;
  final String? idOrganization;
  final String workspaceName;

  Board({required this.name, required this.id, required this.url, this.idOrganization, required this.workspaceName});

  factory Board.fromJson(Map<String, dynamic> json, Map<String, String> workspaceNames) {
    return Board(
      name: json['name'],
      id: json['id'],
      url: json['url'],
      idOrganization: json['idOrganization'],
      workspaceName: json['idOrganization'] != null ? workspaceNames[json['idOrganization']] ?? "Autre" : "Autre",
    );
  }
}
