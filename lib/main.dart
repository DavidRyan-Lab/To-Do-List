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
import 'package:flutter/material.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'services/notification_service.dart';
import 'screens/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  tz.initializeTimeZones();
  await NotificationService.init();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'To-Do',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.black87),
        useMaterial3: true,
      ),
      home: const HomeScreen(),
    );
  }
}