class Member {
  final String id;
  final String fullName;
  bool isSelected;

  Member({required this.id, required this.fullName, this.isSelected = false});

  factory Member.fromJson(Map<String, dynamic> json) {
    return Member(
      id: json['id'],
      fullName: json['fullName'],
      isSelected: false, // Par défaut, les membres ne sont pas sélectionnés
    );
  }
}

