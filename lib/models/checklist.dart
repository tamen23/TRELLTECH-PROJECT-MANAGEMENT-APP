import 'check_item.dart';

class Checklist {
  final String id;
  final String name;
  final List<CheckItem> items;

  Checklist({
    required this.id,
    required this.name,
    required this.items,
  });

  factory Checklist.fromJson(Map<String, dynamic> json) {
    var itemsFromJson = (json['checkItems'] as List?)
            ?.map((item) => CheckItem.fromJson(item)) ??
        [];
    return Checklist(
      id: json['id'],
      name: json['name'],
      items: itemsFromJson.toList(),
    );
  }
}
