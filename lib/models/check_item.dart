class CheckItem {
  final String id;
  final String name;
  final bool completed;

  CheckItem({
    required this.id,
    required this.name,
    required this.completed,
  });

  factory CheckItem.fromJson(Map<String, dynamic> json) {
    return CheckItem(
      id: json['id'],
      name: json['name'],
      completed: json['state'] == 'complete',
    );
  }
}
