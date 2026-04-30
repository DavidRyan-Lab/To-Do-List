import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
    final alarmCtrl = TextEditingController();
    DateTime? picked;
    String alarmUnit = '분';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModal) => AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('새 할 일',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 할 일 입력
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

                // 날짜·시간 설정
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
                      picked = DateTime(date.year, date.month, date.day,
                          time.hour, time.minute);
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.calendar_today,
                            size: 18, color: Colors.grey),
                        const SizedBox(width: 8),
                        Text(
                          picked == null
                              ? '날짜·시간 설정 (선택)'
                              : DateFormat('MM월 dd일 HH:mm').format(picked!),
                          style: TextStyle(
                              color: picked == null
                                  ? Colors.grey
                                  : Colors.black87),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // 알람 설정
                const Text('알람 설정 (선택)',
                    style: TextStyle(fontSize: 13, color: Colors.grey)),
                const SizedBox(height: 6),
                Row(
                  children: [
                    // 숫자 입력
                    Expanded(
                      flex: 2,
                      child: TextField(
                        controller: alarmCtrl,
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly
                        ],
                        decoration: InputDecoration(
                          hintText: '숫자',
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    // 단위 선택
                    Expanded(
                      flex: 3,
                      child: Container(
                        padding:
                            const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade300),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: alarmUnit,
                            items: ['분', '시', '일', '주']
                                .map((u) => DropdownMenuItem(
                                    value: u, child: Text(u)))
                                .toList(),
                            onChanged: (v) =>
                                setModal(() => alarmUnit = v!),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('취소', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
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

                // 날짜·시간 알람
                if (picked != null) {
                  NotificationService.scheduleNotification(
                    id: todo.id.hashCode,
                    title: todo.title,
                    dateTime: picked!,
                  );
                }

                // 알람 설정
                if (alarmCtrl.text.isNotEmpty) {
                  final num = int.parse(alarmCtrl.text);
                  Duration duration;
                  switch (alarmUnit) {
                    case '분':
                      duration = Duration(minutes: num);
                      break;
                    case '시':
                      duration = Duration(hours: num);
                      break;
                    case '일':
                      duration = Duration(days: num);
                      break;
                    case '주':
                      duration = Duration(days: num * 7);
                      break;
                    default:
                      duration = Duration(minutes: num);
                  }
                  final alarmTime = DateTime.now().add(duration);
                  NotificationService.scheduleNotification(
                    id: todo.id.hashCode + 1,
                    title: '⏰ ${todo.title}',
                    dateTime: alarmTime,
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black87,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('추가', style: TextStyle(color: Colors.white)),
            ),
          ],
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
    NotificationService.cancel(todo.id.hashCode + 1);
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
            padding: const EdgeInsets.only(right: 16),
            child: Text(
              DateFormat('M월 d일').format(DateTime.now()),
              style: const TextStyle(color: Colors.grey),
            ),
          ),
        ],
      ),
      body: _todos.isEmpty
          ? const Center(
              child: Text('할 일을 추가해 보세요!',
                  style: TextStyle(color: Colors.grey, fontSize: 16)))
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                if (todayTodos.isNotEmpty) ...[
                  const Text('오늘',
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: Colors.grey)),
                  const SizedBox(height: 8),
                  ...todayTodos.map((t) => _buildTile(t)),
                  const SizedBox(height: 16),
                ],
                if (otherTodos.isNotEmpty) ...[
                  const Text('기타',
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: Colors.grey)),
                  const SizedBox(height: 8),
                  ...otherTodos.map((t) => _buildTile(t)),
                ],
              ],
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addTodo,
        backgroundColor: Colors.black87,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildTile(Todo todo) {
    return Dismissible(
      key: Key(todo.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: Colors.red.shade400,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      onDismissed: (_) => _deleteTodo(todo),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
        child: ListTile(
          leading: GestureDetector(
            onTap: () => _toggleTodo(todo),
            child: Icon(
              todo.isDone
                  ? Icons.check_circle
                  : Icons.radio_button_unchecked,
              color: todo.isDone ? Colors.green : Colors.grey,
            ),
          ),
          title: Text(
            todo.title,
            style: TextStyle(
              decoration: todo.isDone ? TextDecoration.lineThrough : null,
              color: todo.isDone ? Colors.grey : Colors.black87,
            ),
          ),
          subtitle: todo.dueDate != null
              ? Text(
                  DateFormat('MM월 dd일 HH:mm').format(todo.dueDate!),
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                )
              : null,
        ),
      ),
    );
  }
}