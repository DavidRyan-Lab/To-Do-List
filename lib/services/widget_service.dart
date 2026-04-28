import 'package:home_widget/home_widget.dart';
import 'package:intl/intl.dart';
import '../models/todo.dart';

class WidgetService {
  static Future<void> updateWidget(List<Todo> todos) async {
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final todayTodos = todos.where((t) =>
        !t.isDone &&
        t.dueDate != null &&
        DateFormat('yyyy-MM-dd').format(t.dueDate!) == today).toList();

    final text = todayTodos.isEmpty
        ? '오늘 완료된 할 일이 없습니다 🎉'
        : todayTodos.map((t) => '• ${t.title}').join('\n');

    await HomeWidget.saveWidgetData<String>('widget_todos', text);
    await HomeWidget.updateWidget(
      androidName: 'TodoWidget',
    );
  }
}