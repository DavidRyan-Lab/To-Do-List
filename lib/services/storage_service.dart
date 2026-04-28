import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/todo.dart';
import 'widget_service.dart';

class StorageService {
  static const _key = 'todos';

  static Future<List<Todo>> loadTodos() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString(_key);
    if (data == null) return [];
    final list = jsonDecode(data) as List;
    return list.map((e) => Todo.fromJson(e)).toList();
  }

  static Future<void> saveTodos(List<Todo> todos) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, jsonEncode(todos.map((e) => e.toJson()).toList()));
    
    // 위젯 자동 업데이트
    await WidgetService.updateWidget(todos);
  }
}