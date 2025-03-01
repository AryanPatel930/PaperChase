import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:url_launcher/url_launcher.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PAPERCHASE',
      theme: ThemeData(primarySwatch: Colors.blue),
      initialRoute: '/',
      routes: {
        '/': (context) => const HomePage(),
        '/login': (context) => const LoginPage(),
        '/signup': (context) => const SignupPage(),
      },
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final TextEditingController _searchController = TextEditingController();
  List<dynamic> _books = [];

  Future<void> _searchBooks() async {
    final query = _searchController.text;
    if (query.isEmpty) return;

    final url = Uri.parse(
        'https://www.googleapis.com/books/v1/volumes?q=${Uri.encodeComponent(query)}&key=AIzaSyDb5q3iuyyhJh0yeD4cprHduShcuRmAco8');

    try {
      final response = await http.get(url);
      final data = json.decode(response.body);

      setState(() {
        _books = data['items'] ?? [];
      });
    } catch (error) {
      print("Error fetching books: $error");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('PAPERCHASE'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pushNamed(context, '/login'),
            child: const Text('Login', style: TextStyle(color: Colors.white)),
          ),
          TextButton(
            onPressed: () => Navigator.pushNamed(context, '/signup'),
            child: const Text('Sign Up', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: "Search for books by title, author, or ISBN",
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.search),
                  onPressed: _searchBooks,
                ),
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: ListView.builder(
                itemCount: _books.length,
                itemBuilder: (context, index) {
                  final book = _books[index]['volumeInfo'];
                  final title = book['title'] ?? "Unknown Title";
                  final authors = book['authors']?.join(", ") ?? "Unknown Author";
                  final thumbnail = book['imageLinks']?['thumbnail'] ?? "https://via.placeholder.com/50";
                  final link = book['infoLink'] ?? "#";

                  return ListTile(
                    leading: Image.network(thumbnail, width: 50, height: 50, fit: BoxFit.cover),
                    title: Text(title),
                    subtitle: Text(authors),
                    onTap: () async {
                      final Uri url = Uri.parse(link);
                      if (await canLaunchUrl(url)) {
                        await launchUrl(url);
                      } else {
                        print("Could not open $url");
                      }
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Login')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(decoration: const InputDecoration(labelText: 'Email')),
              TextField(decoration: const InputDecoration(labelText: 'Password'), obscureText: true),
              const SizedBox(height: 20),
              ElevatedButton(onPressed: () {}, child: const Text('Login')),
              TextButton(
                onPressed: () => Navigator.pushNamed(context, '/signup'),
                child: const Text("Don't have an account? Sign Up"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class SignupPage extends StatelessWidget {
  const SignupPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Sign Up')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(decoration: const InputDecoration(labelText: 'Full Name')),
              TextField(decoration: const InputDecoration(labelText: 'Email')),
              TextField(decoration: const InputDecoration(labelText: 'Password'), obscureText: true),
              const SizedBox(height: 20),
              ElevatedButton(onPressed: () {}, child: const Text('Sign Up')),
              TextButton(
                onPressed: () => Navigator.pushNamed(context, '/login'),
                child: const Text("Already have an account? Login"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
