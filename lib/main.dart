import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:url_launcher/url_launcher.dart';
import 'login.dart';
import 'signup.dart';
import 'profile.dart';
import 'post.dart';
import 'inbox.dart';
import 'package:firebase_app_check/firebase_app_check.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  await FirebaseAppCheck.instance.activate(
    androidProvider: AndroidProvider.playIntegrity,
  );

  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  bool _isDarkMode = false; // Default to Light Mode

  void _toggleTheme() {
    setState(() {
      _isDarkMode = !_isDarkMode; // Toggle between Light & Dark Mode
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PAPERCHASE',
      theme: ThemeData(
        brightness: Brightness.light,
        scaffoldBackgroundColor: Colors.black,
        appBarTheme: const AppBarTheme(backgroundColor: Colors.black),
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          backgroundColor: Colors.black,
          selectedItemColor: Colors.white,
          unselectedItemColor: Colors.grey,
        ),
      ),
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: Colors.cyan,
        appBarTheme: const AppBarTheme(backgroundColor: Colors.white),
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          backgroundColor: Colors.white,
          selectedItemColor: Colors.black,
          unselectedItemColor: Colors.grey,
        ),
      ),
      themeMode: _isDarkMode ? ThemeMode.dark : ThemeMode.light,
      initialRoute: '/',
      routes: {
        '/': (context) => HomePage(toggleTheme: _toggleTheme, isDarkMode: _isDarkMode),
        '/login': (context) => const LoginPage(),
        '/signup': (context) => const SignupPage(),
        '/profile': (context) => const ProfilePage(),
        '/post': (context) => const PostPage(),
        '/inbox': (context) => const InboxPage(),
      },
    );
  }
}

class HomePage extends StatefulWidget {
  final VoidCallback toggleTheme;
  final bool isDarkMode;

  const HomePage({super.key, required this.toggleTheme, required this.isDarkMode});

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final TextEditingController _searchController = TextEditingController();
  List<dynamic> _books = [];
  bool _isLoggedIn = false;
  User? _user;

  @override
  void initState() {
    super.initState();
    _checkUserLoginStatus();
  }

  void _checkUserLoginStatus() {
    FirebaseAuth.instance.authStateChanges().listen((User? user) {
      setState(() {
        _isLoggedIn = user != null;
        _user = user;
      });
    });
  }

  Future<void> _logout() async {
    await FirebaseAuth.instance.signOut();
    setState(() {
      _isLoggedIn = false;
    });
    Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
  }

  Future<void> _searchBooks() async {
    final query = _searchController.text;
    if (query.isEmpty) return;

    final url = Uri.parse('https://www.googleapis.com/books/v1/volumes?q=${Uri.encodeComponent(query)}');

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
        title: Image.asset('assets/logo.png', height: 40),
        leading: _isLoggedIn
            ? PopupMenuButton<String>(
          onSelected: (value) {
            if (value == 'logout') {
              _logout();
            } else if (value == 'profile') {
              Navigator.pushNamed(context, '/profile');
            }
          },
          itemBuilder: (BuildContext context) => [
            const PopupMenuItem(value: 'profile', child: Text('Profile')),
            const PopupMenuItem(value: 'logout', child: Text('Logout')),
          ],
        )
            : null,
        actions: [
          IconButton(
            icon: Icon(widget.isDarkMode ? Icons.wb_sunny : Icons.nightlight_round),
            onPressed: widget.toggleTheme,
          ),
          if (!_isLoggedIn) ...[
            TextButton(
              onPressed: () => Navigator.pushNamed(context, '/login'),
              child: Text('Login', style: TextStyle(color: widget.isDarkMode ? Colors.black : Colors.white)),
            ),
            TextButton(
              onPressed: () => Navigator.pushNamed(context, '/signup'),
              child: Text('Sign Up', style: TextStyle(color: widget.isDarkMode ? Colors.black : Colors.white)),
            ),
          ],
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
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: widget.isDarkMode ? Colors.white : Colors.black,
        selectedItemColor: widget.isDarkMode ? Colors.black : Colors.white,
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: "Home"),
          BottomNavigationBarItem(icon: Icon(Icons.add), label: "Post"),
          BottomNavigationBarItem(icon: Icon(Icons.mail), label: "Inbox"),
        ],
        onTap: (index) {
          if (index == 0) {
            Navigator.pushNamed(context, '/');
          } else if (index == 1) {
            Navigator.pushNamed(context, '/post');
          } else if (index == 2) {
            Navigator.pushNamed(context, '/inbox');
          }
        },
      ),
    );
  }
}
