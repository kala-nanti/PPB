import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

// Model Todo
class Todo {
  final int id;
  final String title;
  final bool completed;

  Todo({required this.id, required this.title, required this.completed});

  factory Todo.fromJson(Map<String, dynamic> json) {
    return Todo(
      id: json['id'],
      title: json['title'],
      completed: json['completed'],
    );
  }
}

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Todo List',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const TodoListPage(),
    );
  }
}

class TodoListPage extends StatefulWidget {
  const TodoListPage({super.key});

  @override
  TodoListPageState createState() => TodoListPageState();
}

class TodoListPageState extends State<TodoListPage> {
  late Future<List<Todo>> futureTodos;
  List<Todo> allTodos = [];
  List<Todo> displayedTodos = [];

  String filter = 'All'; // All, Completed, Not Completed
  String searchQuery = '';

  @override
  void initState() {
    super.initState();
    futureTodos = fetchTodos();
  }

  Future<List<Todo>> fetchTodos() async {
    try {
      final response = await http.get(Uri.parse('https://jsonplaceholder.typicode.com/todos/'));

      if (response.statusCode == 200) {
        List<dynamic> jsonData = json.decode(response.body);
        List<Todo> todos = jsonData.map((item) => Todo.fromJson(item)).toList();

        // Simpan ke state
        setState(() {
          allTodos = todos;
          applyFilters();
        });

        return todos;
      } else {
        throw Exception('Gagal memuat data. Kode status: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Terjadi kesalahan: $e');
    }
  }

  void _refreshData() {
    setState(() {
      futureTodos = fetchTodos();
    });
  }

  void applyFilters() {
    List<Todo> filteredTodos = allTodos;

    // Filter Completed / Not Completed
    if (filter == 'Completed') {
      filteredTodos = filteredTodos.where((todo) => todo.completed).toList();
    } else if (filter == 'Not Completed') {
      filteredTodos = filteredTodos.where((todo) => !todo.completed).toList();
    }

    // Filter by search query
    if (searchQuery.isNotEmpty) {
      filteredTodos = filteredTodos.where((todo) =>
          todo.title.toLowerCase().contains(searchQuery.toLowerCase())).toList();
    }

    setState(() {
      displayedTodos = filteredTodos;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Todo List'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshData,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: FutureBuilder<List<Todo>>(
        future: futureTodos,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error, size: 50, color: Colors.red),
                  const SizedBox(height: 10),
                  Text('Error: ${snapshot.error}'),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: _refreshData,
                    child: const Text('Coba Lagi'),
                  ),
                ],
              ),
            );
          } else {
            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: TextField(
                    decoration: const InputDecoration(
                      labelText: 'Search',
                      prefixIcon: Icon(Icons.search),
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (value) {
                      searchQuery = value;
                      applyFilters();
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: DropdownButton<String>(
                    value: filter,
                    isExpanded: true,
                    items: <String>['All', 'Completed', 'Not Completed']
                        .map((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text('Filter: $value'),
                      );
                    }).toList(),
                    onChanged: (value) {
                      if (value != null) {
                        filter = value;
                        applyFilters();
                      }
                    },
                  ),
                ),
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: () async {
                      _refreshData();
                    },
                    child: displayedTodos.isEmpty
                        ? const Center(child: Text('Tidak ada data yang sesuai'))
                        : ListView.builder(
                            padding: const EdgeInsets.all(8),
                            itemCount: displayedTodos.length,
                            itemBuilder: (context, index) {
                              final todo = displayedTodos[index];
                              return Card(
                                margin: const EdgeInsets.symmetric(vertical: 6),
                                child: ListTile(
                                  leading: CircleAvatar(
                                    backgroundColor:
                                        todo.completed ? Colors.green : Colors.red,
                                    child: Text(todo.id.toString()),
                                  ),
                                  title: Text(todo.title),
                                  subtitle: Text(todo.completed
                                      ? 'Completed'
                                      : 'Not Completed'),
                                  trailing: Icon(
                                    todo.completed
                                        ? Icons.check_circle
                                        : Icons.radio_button_unchecked,
                                    color: todo.completed
                                        ? Colors.green
                                        : Colors.grey,
                                  ),
                                ),
                              );
                            },
                          ),
                  ),
                ),
              ],
            );
          }
        },
      ),
    );
  }
}
