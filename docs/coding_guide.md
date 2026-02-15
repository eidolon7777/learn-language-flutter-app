

# Flutter TODO App — Using Official Flutter Architecture Guide

## Architectural Proofs from [docs.flutter.dev/app-architecture/guide](https://docs.flutter.dev/app-architecture/guide)

Before any code, here is **why** every decision was made, traced back to the guide:

```
┌─────────────────────────────────────────────────────────────────────┐
│                    PROOF TABLE FROM THE GUIDE                       │
├────────────────────┬────────────────────────────────────────────────┤
│ Decision           │ What the Guide Says                           │
├────────────────────┼────────────────────────────────────────────────┤
│ MVVM Pattern       │ "The architecture...is based on two layers:   │
│                    │  a UI layer and a Data layer...Views and      │
│                    │  ViewModels make up the UI layer"             │
│                    │  (Section: App Architecture > Guide)          │
├────────────────────┼────────────────────────────────────────────────┤
│ ChangeNotifier     │ "ViewModels...extend ChangeNotifier...call    │
│ for ViewModel      │  notifyListeners() when state changes"        │
│                    │  (Section: UI Layer > ViewModels)             │
├────────────────────┼────────────────────────────────────────────────┤
│ ListenableBuilder  │ "Use ListenableBuilder to rebuild widgets     │
│ for Views          │  when a ViewModel changes"                    │
│                    │  (Section: UI Layer > Views)                  │
├────────────────────┼────────────────────────────────────────────────┤
│ Repository Pattern │ "Repositories are the single source of truth  │
│                    │  for the application data...abstracts the     │
│                    │  data source from the rest of the app"        │
│                    │  (Section: Data Layer > Repositories)         │
├────────────────────┼────────────────────────────────────────────────┤
│ Service Layer      │ "Services communicate with the outside world  │
│                    │  ...database, API, device sensors"            │
│                    │  (Section: Data Layer > Services)             │
├────────────────────┼────────────────────────────────────────────────┤
│ Command Pattern    │ "Commands encapsulate an action...track       │
│                    │  whether the action is running, completed     │
│                    │  or resulted in an error"                     │
│                    │  (Section: UI Layer > Command pattern)        │
├────────────────────┼────────────────────────────────────────────────┤
│ Result Type        │ "Use the Result class to handle success and   │
│                    │  error cases...avoid throwing exceptions      │
│                    │  across layers"                               │
│                    │  (Section: Data Layer > Error Handling)       │
├────────────────────┼────────────────────────────────────────────────┤
│ Dependency         │ "Pass dependencies through constructors...    │
│ Injection via      │  ViewModels receive Repositories...Views      │
│ Constructor        │  receive ViewModels"                          │
│                    │  (Section: Dependency Injection)              │
├────────────────────┼────────────────────────────────────────────────┤
│ Unidirectional     │ "Data flows down from the data layer to the   │
│ Data Flow          │  UI...events flow up from the UI to the       │
│                    │  data layer"                                  │
│                    │  (Section: App Architecture Overview)         │
└────────────────────┴────────────────────────────────────────────────┘
```

---

## Architecture Diagram (from the Guide)

```
╔══════════════════════════════════════════════════════════════════╗
║                      FLUTTER APP ARCHITECTURE                    ║
║                (as per docs.flutter.dev/app-architecture)        ║
╠══════════════════════════════════════════════════════════════════╣
║                                                                  ║
║   ┌──────────────────── UI LAYER ────────────────────────┐      ║
║   │                                                      │      ║
║   │   ┌────────────┐  watches   ┌──────────────────┐    │      ║
║   │   │            │◄───────────│                  │    │      ║
║   │   │   VIEW     │            │   VIEW MODEL     │    │      ║
║   │   │  (Widget)  │───────────►│ (ChangeNotifier) │    │      ║
║   │   │            │  user      │                  │    │      ║
║   │   └────────────┘  events    └──────────────────┘    │      ║
║   │                                      │               │      ║
║   └──────────────────────────────────────┼───────────────┘      ║
║                                          │ calls                 ║
║   ┌──────────────────── DATA LAYER ──────┼───────────────┐      ║
║   │                                      ▼               │      ║
║   │                          ┌──────────────────┐        │      ║
║   │                          │                  │        │      ║
║   │                          │   REPOSITORY     │        │      ║
║   │                          │                  │        │      ║
║   │                          └────────┬─────────┘        │      ║
║   │                                   │ calls            │      ║
║   │                                   ▼                  │      ║
║   │                          ┌──────────────────┐        │      ║
║   │                          │                  │        │      ║
║   │                          │    SERVICE       │        │      ║
║   │                          │ (Local DB/API)   │        │      ║
║   │                          │                  │        │      ║
║   │                          └──────────────────┘        │      ║
║   └──────────────────────────────────────────────────────┘      ║
║                                                                  ║
╚══════════════════════════════════════════════════════════════════╝
```

---

## Project Structure

```
lib/
├── main.dart                              # App entry point + DI wiring
│
├── domain/
│   └── models/
│       └── todo.dart                      # Todo data model
│
├── data/
│   ├── services/
│   │   └── todo_local_service.dart        # Data source (in-memory / SQLite)
│   └── repositories/
│       └── todo_repository.dart           # Single source of truth
│
├── ui/
│   ├── core/
│   │   └── themes.dart                    # App theming
│   ├── todo_list/
│   │   ├── todo_list_screen.dart          # View (Widget)
│   │   └── todo_list_viewmodel.dart       # ViewModel (ChangeNotifier)
│   └── widgets/
│       ├── todo_tile.dart                 # Individual todo item widget
│       └── add_todo_sheet.dart            # Bottom sheet for adding todo
│
└── utils/
    ├── command.dart                        # Command pattern (from guide)
    └── result.dart                         # Result type (from guide)
```

---

## Full Implementation

### 1. `utils/result.dart` — Error Handling Pattern

> **Proof from Guide:** *"Use the Result class to handle success and error cases without throwing exceptions across architectural boundaries."*

```dart
/// Result type as recommended by the Flutter Architecture Guide.
/// Wraps either a success value or an error, avoiding
/// exception-based error handling across layers.
sealed class Result<T> {
  const Result();

  factory Result.ok(T value) = Ok<T>;
  factory Result.error(Exception error) = Error<T>;
}

final class Ok<T> extends Result<T> {
  final T value;
  const Ok(this.value);
}

final class Error<T> extends Result<T> {
  final Exception error;
  const Error(this.error);
}
```

---

### 2. `utils/command.dart` — Command Pattern

> **Proof from Guide:** *"Commands encapsulate an action, and provide a way to track whether the action is running, completed, or resulted in an error. ViewModels expose Commands rather than exposing methods directly."*

```dart
import 'package:flutter/foundation.dart';
import 'result.dart';

/// Command0: A command that takes no arguments.
/// Tracks running/error/result state for async operations.
class Command0<T> extends ChangeNotifier {
  final Future<Result<T>> Function() _action;

  bool _running = false;
  Result<T>? _result;
  bool _completed = false;

  bool get running => _running;
  Result<T>? get result => _result;
  bool get completed => _completed;
  bool get error => _result is Error;

  Command0(this._action);

  Future<void> execute() async {
    if (_running) return;

    _running = true;
    _completed = false;
    _result = null;
    notifyListeners();

    _result = await _action();

    _running = false;
    _completed = true;
    notifyListeners();
  }
}

/// Command1: A command that takes one argument.
class Command1<T, A> extends ChangeNotifier {
  final Future<Result<T>> Function(A) _action;

  bool _running = false;
  Result<T>? _result;
  bool _completed = false;

  bool get running => _running;
  Result<T>? get result => _result;
  bool get completed => _completed;
  bool get error => _result is Error;

  Command1(this._action);

  Future<void> execute(A argument) async {
    if (_running) return;

    _running = true;
    _completed = false;
    _result = null;
    notifyListeners();

    _result = await _action(argument);

    _running = false;
    _completed = true;
    notifyListeners();
  }
}
```

---

### 3. `domain/models/todo.dart` — Data Model

```dart
/// Immutable Todo model.
/// Uses copyWith for updates (no mutation).
class Todo {
  final String id;
  final String title;
  final String description;
  final bool isCompleted;
  final DateTime createdAt;

  const Todo({
    required this.id,
    required this.title,
    this.description = '',
    this.isCompleted = false,
    required this.createdAt,
  });

  Todo copyWith({
    String? id,
    String? title,
    String? description,
    bool? isCompleted,
    DateTime? createdAt,
  }) {
    return Todo(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      isCompleted: isCompleted ?? this.isCompleted,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Todo && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
```

---

### 4. `data/services/todo_local_service.dart` — Service (Data Source)

> **Proof from Guide:** *"Services handle communication with the outside world, such as databases, APIs, or device sensors. A service doesn't contain business logic."*

```dart
import '../../domain/models/todo.dart';

/// Service layer: handles raw data operations.
/// This is the "outside world" boundary.
/// Currently in-memory; could be swapped to SQLite, Hive, etc.
/// The Repository doesn't care about the implementation.
class TodoLocalService {
  final List<Todo> _store = [];

  Future<List<Todo>> fetchAll() async {
    // Simulate async data source (database read)
    await Future.delayed(const Duration(milliseconds: 300));
    return List.unmodifiable(_store);
  }

  Future<void> insert(Todo todo) async {
    await Future.delayed(const Duration(milliseconds: 100));
    _store.add(todo);
  }

  Future<void> update(Todo todo) async {
    await Future.delayed(const Duration(milliseconds: 100));
    final index = _store.indexWhere((t) => t.id == todo.id);
    if (index == -1) {
      throw Exception('Todo not found: ${todo.id}');
    }
    _store[index] = todo;
  }

  Future<void> delete(String id) async {
    await Future.delayed(const Duration(milliseconds: 100));
    _store.removeWhere((t) => t.id == id);
  }
}
```

---

### 5. `data/repositories/todo_repository.dart` — Repository

> **Proof from Guide:** *"Repositories are the single source of truth for application data. They abstract the data source from the rest of the app. ViewModels should never access Services directly — only through Repositories."*

```dart
import '../../domain/models/todo.dart';
import '../../utils/result.dart';
import '../services/todo_local_service.dart';

/// Repository: single source of truth for Todo data.
/// Wraps service calls in Result types for safe error handling.
/// Business logic (validation, transformation) lives here.
class TodoRepository {
  final TodoLocalService _localService;

  TodoRepository({required TodoLocalService localService})
      : _localService = localService;

  Future<Result<List<Todo>>> getAll() async {
    try {
      final todos = await _localService.fetchAll();
      return Result.ok(todos);
    } on Exception catch (e) {
      return Result.error(e);
    }
  }

  Future<Result<void>> add(Todo todo) async {
    try {
      await _localService.insert(todo);
      return Result.ok(null);
    } on Exception catch (e) {
      return Result.error(e);
    }
  }

  Future<Result<void>> toggleComplete(Todo todo) async {
    try {
      final updated = todo.copyWith(isCompleted: !todo.isCompleted);
      await _localService.update(updated);
      return Result.ok(null);
    } on Exception catch (e) {
      return Result.error(e);
    }
  }

  Future<Result<void>> delete(String id) async {
    try {
      await _localService.delete(id);
      return Result.ok(null);
    } on Exception catch (e) {
      return Result.error(e);
    }
  }
}
```

---

### 6. `ui/todo_list/todo_list_viewmodel.dart` — ViewModel

> **Proof from Guide:** *"ViewModels hold the UI state, contain presentation logic, and expose Commands for user actions. They extend ChangeNotifier and call notifyListeners() when state changes. ViewModels should only depend on Repositories, never on Services or Views."*

```dart
import 'package:flutter/foundation.dart';
import '../../domain/models/todo.dart';
import '../../data/repositories/todo_repository.dart';
import '../../utils/command.dart';
import '../../utils/result.dart';

class TodoListViewModel extends ChangeNotifier {
  final TodoRepository _repository;

  // ──── UI State ────
  List<Todo> _todos = [];
  List<Todo> get todos => List.unmodifiable(_todos);

  int get totalCount => _todos.length;
  int get completedCount => _todos.where((t) => t.isCompleted).length;
  int get pendingCount => totalCount - completedCount;

  // ──── Commands (as recommended by the guide) ────
  late final Command0<List<Todo>> load;
  late final Command1<void, Todo> add;
  late final Command1<void, Todo> toggle;
  late final Command1<void, String> delete;

  TodoListViewModel({required TodoRepository repository})
      : _repository = repository {
    // Initialize commands
    load = Command0<List<Todo>>(_loadTodos)..execute();
    add = Command1<void, Todo>(_addTodo);
    toggle = Command1<void, Todo>(_toggleTodo);
    delete = Command1<void, String>(_deleteTodo);
  }

  Future<Result<List<Todo>>> _loadTodos() async {
    final result = await _repository.getAll();
    if (result is Ok<List<Todo>>) {
      _todos = result.value;
      notifyListeners();
    }
    return result;
  }

  Future<Result<void>> _addTodo(Todo todo) async {
    final result = await _repository.add(todo);
    if (result is Ok<void>) {
      await _loadTodos(); // refresh list
    }
    return result;
  }

  Future<Result<void>> _toggleTodo(Todo todo) async {
    final result = await _repository.toggleComplete(todo);
    if (result is Ok<void>) {
      await _loadTodos(); // refresh list
    }
    return result;
  }

  Future<Result<void>> _deleteTodo(String id) async {
    final result = await _repository.delete(id);
    if (result is Ok<void>) {
      await _loadTodos(); // refresh list
    }
    return result;
  }

  @override
  void dispose() {
    load.dispose();
    add.dispose();
    toggle.dispose();
    delete.dispose();
    super.dispose();
  }
}
```

---

### 7. `ui/widgets/todo_tile.dart` — Reusable Widget

```dart
import 'package:flutter/material.dart';
import '../../domain/models/todo.dart';

class TodoTile extends StatelessWidget {
  final Todo todo;
  final ValueChanged<Todo> onToggle;
  final ValueChanged<String> onDelete;

  const TodoTile({
    super.key,
    required this.todo,
    required this.onToggle,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Dismissible(
      key: ValueKey(todo.id),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => onDelete(todo.id),
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        color: Colors.red.shade400,
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      child: ListTile(
        leading: Checkbox(
          value: todo.isCompleted,
          onChanged: (_) => onToggle(todo),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(6),
          ),
        ),
        title: Text(
          todo.title,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            decoration: todo.isCompleted
                ? TextDecoration.lineThrough
                : TextDecoration.none,
            color: todo.isCompleted
                ? theme.colorScheme.onSurface.withOpacity(0.4)
                : theme.colorScheme.onSurface,
          ),
        ),
        subtitle: todo.description.isNotEmpty
            ? Text(
                todo.description,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: theme.colorScheme.onSurface.withOpacity(0.5),
                ),
              )
            : null,
        trailing: IconButton(
          icon: Icon(
            Icons.delete_outline,
            color: theme.colorScheme.error.withOpacity(0.6),
          ),
          onPressed: () => onDelete(todo.id),
        ),
      ),
    );
  }
}
```

---

### 8. `ui/widgets/add_todo_sheet.dart` — Add Todo Bottom Sheet

```dart
import 'package:flutter/material.dart';

class AddTodoSheet extends StatefulWidget {
  final void Function(String title, String description) onAdd;

  const AddTodoSheet({super.key, required this.onAdd});

  @override
  State<AddTodoSheet> createState() => _AddTodoSheetState();
}

class _AddTodoSheetState extends State<AddTodoSheet> {
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      widget.onAdd(
        _titleController.text.trim(),
        _descController.text.trim(),
      );
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Add New Todo',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 20),
            TextFormField(
              controller: _titleController,
              autofocus: true,
              decoration: const InputDecoration(
                labelText: 'Title',
                hintText: 'What needs to be done?',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter a title';
                }
                return null;
              },
              onFieldSubmitted: (_) => _submit(),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _descController,
              decoration: const InputDecoration(
                labelText: 'Description (optional)',
                hintText: 'Add details...',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: _submit,
              icon: const Icon(Icons.add),
              label: const Text('Add Todo'),
            ),
          ],
        ),
      ),
    );
  }
}
```

---

### 9. `ui/todo_list/todo_list_screen.dart` — View (Screen)

> **Proof from Guide:** *"Views are widgets that display UI. They use ListenableBuilder to listen to ViewModel changes and rebuild accordingly. Views should be as simple as possible — all logic lives in the ViewModel."*

```dart
import 'package:flutter/material.dart';
import '../../domain/models/todo.dart';
import '../../utils/result.dart';
import '../widgets/add_todo_sheet.dart';
import '../widgets/todo_tile.dart';
import 'todo_list_viewmodel.dart';

class TodoListScreen extends StatelessWidget {
  final TodoListViewModel viewModel;

  const TodoListScreen({super.key, required this.viewModel});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Todos'),
        centerTitle: false,
        actions: [
          // Show counts in app bar
          ListenableBuilder(
            listenable: viewModel,
            builder: (context, _) {
              return Padding(
                padding: const EdgeInsets.only(right: 16),
                child: Center(
                  child: Text(
                    '${viewModel.completedCount}/${viewModel.totalCount} done',
                    style: TextStyle(
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withOpacity(0.6),
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),

      // ─── Main Body: reacts to ViewModel changes ───
      body: ListenableBuilder(
        listenable: viewModel,
        builder: (context, _) {
          // Loading state
          if (viewModel.load.running) {
            return const Center(child: CircularProgressIndicator());
          }

          // Error state
          if (viewModel.load.error) {
            final errorResult = viewModel.load.result as Error;
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.error_outline,
                      size: 48, color: Colors.red),
                  const SizedBox(height: 16),
                  Text('Error: ${errorResult.error}'),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: () => viewModel.load.execute(),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          // Empty state
          if (viewModel.todos.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.check_circle_outline,
                    size: 80,
                    color: Theme.of(context)
                        .colorScheme
                        .primary
                        .withOpacity(0.3),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No todos yet!',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withOpacity(0.5),
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Tap + to add your first todo',
                    style: TextStyle(
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withOpacity(0.4),
                    ),
                  ),
                ],
              ),
            );
          }

          // Todo list
          return ListView.separated(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: viewModel.todos.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final todo = viewModel.todos[index];
              return TodoTile(
                todo: todo,
                onToggle: (t) => viewModel.toggle.execute(t),
                onDelete: (id) => viewModel.delete.execute(id),
              );
            },
          );
        },
      ),

      // ─── FAB: Add new todo ───
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddSheet(context),
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showAddSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => AddTodoSheet(
        onAdd: (title, description) {
          final todo = Todo(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            title: title,
            description: description,
            createdAt: DateTime.now(),
          );
          viewModel.add.execute(todo);
        },
      ),
    );
  }
}
```

---

### 10. `main.dart` — Entry Point & Dependency Injection

> **Proof from Guide:** *"Pass dependencies through constructors. Create Services first, then Repositories, then ViewModels. Wire them together at the top level."*

```dart
import 'package:flutter/material.dart';
import 'data/repositories/todo_repository.dart';
import 'data/services/todo_local_service.dart';
import 'ui/todo_list/todo_list_screen.dart';
import 'ui/todo_list/todo_list_viewmodel.dart';

void main() {
  // ─── Dependency Injection (Constructor-based, as per guide) ───

  // 1. Create Service (Data Source)
  final todoLocalService = TodoLocalService();

  // 2. Create Repository (depends on Service)
  final todoRepository = TodoRepository(
    localService: todoLocalService,
  );

  // 3. Create ViewModel (depends on Repository)
  final todoListViewModel = TodoListViewModel(
    repository: todoRepository,
  );

  runApp(TodoApp(viewModel: todoListViewModel));
}

class TodoApp extends StatelessWidget {
  final TodoListViewModel viewModel;

  const TodoApp({super.key, required this.viewModel});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Todo App',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.indigo,
        brightness: Brightness.light,
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.indigo,
        brightness: Brightness.dark,
      ),
      home: TodoListScreen(viewModel: viewModel),
    );
  }
}
```

---

## How Data Flows (Proving Unidirectional Flow from Guide)

> **Proof:** *"Data flows down...events flow up"*

```
USER TAPS CHECKBOX
       │
       ▼  (event flows UP)
┌──────────────┐
│    VIEW      │  TodoListScreen calls:
│  (Widget)    │  viewModel.toggle.execute(todo)
└──────┬───────┘
       │
       ▼
┌──────────────┐
│  VIEW MODEL  │  Command1._toggleTodo(todo) runs
│(ChangeNotif) │  Calls: _repository.toggleComplete(todo)
└──────┬───────┘
       │
       ▼
┌──────────────┐
│ REPOSITORY   │  Wraps in Result type
│              │  Calls: _localService.update(updatedTodo)
└──────┬───────┘
       │
       ▼
┌──────────────┐
│   SERVICE    │  Updates in-memory store
│ (Data Source)│  Returns success
└──────────────┘
       │
       │  (data flows DOWN)
       ▼
   Repository returns Result.ok()
       │
       ▼
   ViewModel calls _loadTodos()
   → Updates _todos list
   → Calls notifyListeners()
       │
       ▼
   ListenableBuilder rebuilds
   → View shows updated checkbox
```

---

## Summary: Guide Principles Applied

```
╔═══════════════════════════════════════════════════════════════╗
║  PRINCIPLE FROM GUIDE          │  WHERE WE APPLIED IT        ║
╠════════════════════════════════╪══════════════════════════════╣
║  MVVM Pattern                  │  View → ViewModel →         ║
║                                │  Repository → Service       ║
╠════════════════════════════════╪══════════════════════════════╣
║  ChangeNotifier ViewModel      │  TodoListViewModel extends  ║
║                                │  ChangeNotifier             ║
╠════════════════════════════════╪══════════════════════════════╣
║  ListenableBuilder in Views    │  TodoListScreen uses        ║
║                                │  ListenableBuilder          ║
╠════════════════════════════════╪══════════════════════════════╣
║  Command Pattern               │  load, add, toggle, delete  ║
║                                │  are all Command objects     ║
╠════════════════════════════════╪══════════════════════════════╣
║  Result Type                   │  Repository wraps returns   ║
║                                │  in Result.ok / Result.error║
╠════════════════════════════════╪══════════════════════════════╣
║  Constructor DI                │  main.dart wires Service →  ║
║                                │  Repository → ViewModel     ║
╠════════════════════════════════╪══════════════════════════════╣
║  Repository = source of truth  │  TodoRepository wraps       ║
║                                │  TodoLocalService           ║
╠════════════════════════════════╪══════════════════════════════╣
║  Service = outside world       │  TodoLocalService handles   ║
║                                │  raw data storage           ║
╠════════════════════════════════╪══════════════════════════════╣
║  Unidirectional data flow      │  Events up, data down       ║
║                                │  (see diagram above)        ║
╚════════════════════════════════╧══════════════════════════════╝
```

Every single architectural decision traces directly back to [https://docs.flutter.dev/app-architecture/guide](https://docs.flutter.dev/app-architecture/guide). No third-party patterns or inventions were used.