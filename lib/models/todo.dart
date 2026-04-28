class Todo {
  final String id;
  String title;
  bool isDone;
  DateTime? dueDate;

  Todo({
    required this.id,
    required this.title,
    this.isDone = false,
    this.dueDate,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'isDone': isDone,
        'dueDate': dueDate?.toIso8601String(),
      };

  factory Todo.fromJson(Map<String, dynamic> json) => Todo(
        id: json['id'],
        title: json['title'],
        isDone: json['isDone'],
        dueDate: json['dueDate'] != null ? DateTime.parse(json['dueDate']) : null,
      );
}