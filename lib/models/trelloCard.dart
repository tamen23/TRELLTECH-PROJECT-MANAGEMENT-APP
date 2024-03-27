import 'member.dart';
import 'checklist.dart';

class TrelloCard {
  final String id;
  final String name;
  final String desc;
  final String due;
  final bool closed;
  final List<Member> members;
  final List<Checklist> checklists;
  String? idList; // Added attribute
  String? listName; // Added attribute

  TrelloCard({
    required this.id,
    required this.name,
    required this.desc,
    required this.due,
    required this.closed,
    required this.members,
    required this.checklists,
    this.idList, // Optional, as it may not always be available
    this.listName, // Optional, for the same reason
  });

  factory TrelloCard.fromJson(Map<String, dynamic> json, List<Member> members) {
    var checklistsFromJson = (json['checklists'] as List?)
            ?.map((item) => Checklist.fromJson(item)) ??
        [];
    
    return TrelloCard(
      id: json['id'],
      name: json['name'],
      desc: json['desc'] ?? 'Pas de description',
      due: json['due'] ?? 'Aucune date d’échéance',
      closed: json['closed'] ?? false,
      members: members,
      checklists: checklistsFromJson.toList(),
      idList: json['idList'], // Assigning the new attribute
      listName: '', // Default or empty, will be assigned later
    );
  }
}
