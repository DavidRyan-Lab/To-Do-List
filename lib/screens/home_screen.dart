import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../models/todo.dart';
import '../services/storage_service.dart';
import '../services/notification_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Todo> _todos = [];
  final _uuid = const Uuid();

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final todos = await StorageService.loadTodos();
    setState(() => _todos = todos);
  }

  Future<void> _save() async {
    await StorageService.saveTodos(_todos);
    final today = _todos.where((t) =>
        !t.isDone &&
        t.dueDate != null &&
        DateFormat('yyyy-MM-dd').format(t.dueDate!) ==
            DateFormat('yyyy-MM-dd').format(DateTime.now()));
    final summary = today.isEmpty
        ? '오늘 할 일이 없습니다!'
        : today.map((t) => '• ${t.title}').join('\n');
    await NotificationService.scheduleDailySummary(summary);
  }

  void _addTodo() {
    final ctrl = TextEditingController();
    DateTime? picked;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModal) => Padding(
          padding: EdgeInsets.fromLTRB(
              24, 24, 24, MediaQuery.of(ctx).viewInsets.bottom + 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('새 할 일',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              TextField(
                controller: ctrl,
                autofocus: true,
                decoration: InputDecoration(
                  hintText: '할 일을 입력하세요',
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 12),
              GestureDetector(
                onTap: () async {
                  final date = await showDatePicker(
                    context: ctx,
                    initialDate: DateTime.now(),
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(const Duration(days: 365)),
                  );
                  if (date == null) return;
                  final time = await showTimePicker(
                    context: ctx,
                    initialTime: TimeOfDay.now(),
                  );
                  if (time == null) return;
                  setModal(() {
                    picked = DateTime(
                        date.year, date.month, date.day, time.hour, time.minute);
                  });
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.calendar_today, size: 18, color: Colors.grey),
                      const SizedBox(width: 8),
                      Text(
                        picked == null
                            ? '날짜·시간 설정 (선택)'
                            : DateFormat('MM월 dd일 HH:mm').format(picked!),
                        style: TextStyle(
                            color: picked == null ? Colors.grey : Colors.black87),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    if (ctrl.text.trim().isEmpty) return;
                    final todo = Todo(
                      id: _uuid.v4(),
                      title: ctrl.text.trim(),
                      dueDate: picked,
                    );
                    setState(() => _todos.add(todo));
                    if (ctx.mounted) Navigator.pop(ctx);
                    _save();
                    if (picked != null) {
                      NotificationService.scheduleNotification(
                        id: todo.id.hashCode,
                        title: todo.title,
                        dateTime: picked!,
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black87,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('추가', style: TextStyle(color: Colors.white)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _toggleTodo(Todo todo) {
    setState(() => todo.isDone = !todo.isDone);
    _save();
  }

  void _deleteTodo(Todo todo) {
    NotificationService.cancel(todo.id.hashCode);
    setState(() => _todos.remove(todo));
    _save();
  }

  @override
  Widget build(BuildContext context) {
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final todayTodos = _todos
        .where((t) =>
            t.dueDate != null &&
            DateFormat('yyyy-MM-dd').format(t.dueDate!) == today)
        .toList();
    final otherTodos = _todos
        .where((t) =>
            t.dueDate == null ||
            DateFormat('yyyy-MM-dd').format(t.dueDate!) != today)
        .toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text('📋 할 일',
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87)),
        actions: [
          Padding(
            padding: const EdgeInset