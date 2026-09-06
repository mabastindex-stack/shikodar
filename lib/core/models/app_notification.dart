class AppNotification {
  final String id;
  final String title;
  final String body;
  final DateTime createdAt;
  final bool isNew;

  const AppNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.createdAt,
    required this.isNew,
  });

  factory AppNotification.fromJson(Map<String, dynamic> json) => AppNotification(
        id: json['id'].toString(),
        title: json['title'] ?? '',
        body: json['body'] ?? '',
        createdAt: DateTime.parse(json['created_at']),
        isNew: json['is_new'] == true,
      );
}
