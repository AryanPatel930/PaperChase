import 'package:cloud_firestore/cloud_firestore.dart';
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
import 'colors.dart';
import 'utils.dart';
import 'home.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'NavBar.dart';
import 'book_detail_page.dart';
import 'settings.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  await FirebaseAppCheck.instance.activate(
    androidProvider: AndroidProvider.playIntegrity,
  );

  final prefs = await SharedPreferences.getInstance();
  final bool isFirstLaunch = prefs.getBool('first_launch') ?? true;

  if (isFirstLaunch) {
    await prefs.setBool('first_launch', false);
  }
  // Add a delay to ensure the GIF plays after the native splash screen
  await Future.delayed(const Duration(milliseconds: 500));
  runApp(MyApp(isFirstLaunch: isFirstLaunch));
}

class MyApp extends StatefulWidget {
  final bool isFirstLaunch;
  const MyApp({super.key, required this.isFirstLaunch});

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
      title: 'PaperChase',
      
      theme: ThemeData(
        primaryColor: kPrimaryColor,
        brightness: Brightness.light,
        scaffoldBackgroundColor: kLightBackground,
        textTheme: const TextTheme(
          bodyLarge: TextStyle(color: kLightText),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: kDarkBackground,
          titleTextStyle: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
        ),
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          backgroundColor: kDarkBackground,
          selectedItemColor: kPrimaryColor,
          unselectedItemColor: kLightBackground,
        ),
      ),
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: kDarkBackground,
        appBarTheme: const AppBarTheme(backgroundColor: kLightBackground),
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          backgroundColor: kLightBackground,
          selectedItemColor: kPrimaryColor,
          unselectedItemColor: kDarkBackground,
        ),
      ),
      themeMode: _isDarkMode ? ThemeMode.dark : ThemeMode.light,
      
     home: HomePage(toggleTheme: _toggleTheme, isDarkMode: _isDarkMode),

      routes: {
        '/home': (context) => HomePage(toggleTheme: _toggleTheme, isDarkMode: _isDarkMode),  // Passing the flag and toggle method
        '/login': (context) => const LoginPage(),
        '/signup': (context) => const SignupPage(),
        '/profile': (context) => const ProfilePage(),
        '/post': (context) => PostBookPage(),
        '/inbox': (context) => InboxPage(),
        '/settings': (context) => SettingsPage(
            isDarkMode: _isDarkMode,
            toggleTheme: _toggleTheme,
        ),
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
    _loadRecentBooks();
  }

  void _checkUserLoginStatus() {
    FirebaseAuth.instance.authStateChanges().listen((User? user) {
      setState(() {
        _isLoggedIn = user != null;
        _user = user;
      });
    });
  }

  // Navigation with authentication check
  void _navigateIfAuthenticated(BuildContext context, String route) {
    if (_user != null) {
      Navigator.pushNamed(context, route);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please log in to access this feature.')),
      );
      Navigator.pushNamed(context, '/login');
    }
  }

  Future<void> _logout() async {
    await FirebaseAuth.instance.signOut();
    setState(() {
      _isLoggedIn = false;
    });
    Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
  }

  Future<void> _searchBooks() async {
  final query = _searchController.text.trim().toLowerCase();
  if (query.isEmpty) {
    _loadRecentBooks(); // If search is empty, reload recent books
    return;
  }

  try {
    final QuerySnapshot snapshot = await FirebaseFirestore.instance
        .collection('books')
        .orderBy('timestamp', descending: true)
        .get();

    final filteredBooks = snapshot.docs.where((doc) {
      final data = doc.data() as Map<String, dynamic>;
      final title = (data['title'] ?? '').toString().toLowerCase();
      final author = (data['author'] ?? '').toString().toLowerCase();
      final isbn = (data['isbn'] ?? '').toString(); 

      return title.contains(query) || author.contains(query) || isbn.contains(query);
    }).toList();

    setState(() {
      _books = filteredBooks.map((doc) => doc.data()).toList();
    });
  } catch (e) {
    print("Error searching books: $e");
  }
}


  Future<void> _loadRecentBooks() async {
  try {
    final QuerySnapshot snapshot = await FirebaseFirestore.instance
        .collection('books')
        .orderBy('timestamp', descending: true) // Sort by the most recent posts
        .limit(10) // Optionally limit to the latest 10 books
        .get();

    setState(() {
      _books = snapshot.docs.map((doc) => doc.data()).toList();
    });
  } catch (e) {
    print("Error fetching recent books: $e");
  }
}

void _filterBooks() {
  setState(() {
    if (_filterBy == 'Latest Posted') {
      _books.sort((a, b) => (b['timestamp'] as Timestamp).compareTo(a['timestamp'] as Timestamp));
    } else if (_filterBy == 'Price: Low to High') {
      _books.sort((a, b) => (a['price'] ?? 0).compareTo(b['price'] ?? 0));
    } else if (_filterBy == 'Price: High to Low') {
      _books.sort((a, b) => (b['price'] ?? 0).compareTo(a['price'] ?? 0));
    } else if (_filterBy == 'Condition: Best to Worst') {
      _books.sort((a, b) => _conditionRanking(a['condition']).compareTo(_conditionRanking(b['condition'])));
    } else if (_filterBy == 'Condition: Worst to Best') {
      _books.sort((a, b) => _conditionRanking(b['condition']).compareTo(_conditionRanking(a['condition'])));
    }
  });
}

int _conditionRanking(String? condition) {
  const conditionOrder = {
    'Like New': 1,
    'Good': 2,
    'Fair': 3,
    'Poor': 4
  };
  return conditionOrder[condition] ?? 0;
}

String _filterBy = 'Latest Posted'; // Default filter option
  @override
  Widget build(BuildContext context) {
    bool darkMode = isDarkMode(context); // Call the utility function
    final query = _searchController.text.trim().toLowerCase();
    return Scaffold(
      drawer: _isLoggedIn ? NavBar() : null,
      appBar: AppBar(
      iconTheme: IconThemeData(
        color: widget.isDarkMode ? kDarkBackground : kLightBackground,
      ),
       title: Image.asset('assets/title-text.png'),
        actions: [
          IconButton(
            icon: Icon(widget.isDarkMode ? Icons.wb_sunny : Icons.nightlight_round),
            color: widget.isDarkMode ? kDarkBackground : kLightBackground,
            onPressed: widget.toggleTheme,
          ),
          if (!_isLoggedIn) ...[
            TextButton(
              onPressed: () => Navigator.pushNamed(context, '/login'),
              child: Text('Login', style: TextStyle(color: widget.isDarkMode ? kDarkBackground : kLightBackground)),
            ),
            TextButton(
              onPressed: () => Navigator.pushNamed(context, '/signup'),
              child: Text('Sign Up', style: TextStyle(color: widget.isDarkMode ? kDarkBackground : kLightBackground)),
            ),
          ],
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
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
            const SizedBox(height: 15),

          if (_books.isNotEmpty && (query ?? '').isNotEmpty)
          Align(
            alignment: Alignment.centerLeft,    // ✅ Align to the left
            child: GestureDetector(
              onTap: () => showModalBottomSheet(
                context: context,
                builder: (context) => Container(
                  decoration: BoxDecoration(
                    color: widget.isDarkMode ? kDarkBackground : kLightBackground,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(16),   // ✅ Rounded corners at the top
                      topRight: Radius.circular(16),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 8,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      for (var filterOption in [
                        'Latest Posted',
                        'Price: Low to High',
                        'Price: High to Low',
                        'Condition: Best to Worst',
                        'Condition: Worst to Best'
                      ])
                        ListTile(
                          title: Text(
                            filterOption,
                            style: TextStyle(color: widget.isDarkMode ? kDarkText : kLightText),
                          ),
                          onTap: () {
                            setState(() {
                              _filterBy = filterOption;
                              _filterBooks();
                            });
                            Navigator.pop(context);
                          },
                        ),
                    ],
                  ),
                ),
              ),

              // 🔥 Compact Container with Border around Icon on the Left
              child: Container(
                padding: const EdgeInsets.all(8),  // Compact padding
                decoration: BoxDecoration(
                  color: widget.isDarkMode ? kDarkBackground : kLightBackground,
                  borderRadius: BorderRadius.circular(12),    // ✅ Rounded border
                  border: Border.all(
                    color: widget.isDarkMode ? Colors.grey : Colors.black12,  // Light border
                    width: 1,
                  ),
                ),
                child: 
                Icon(Icons.sort_rounded, color: widget.isDarkMode ? kDarkText : kLightText),  // ✅ Only the icon inside
              ),
            ),
          ),

          const SizedBox(height: 10),

            Expanded(
              
              child: ListView.builder(
                itemCount: _books.length,
                itemBuilder: (context, index) {
                  final book = _books[index];
                    
                  final title = book['title'] ?? "Unknown Title";
                  final author = book['author'] ?? "No author available";
                  final thumbnail = book['imageUrl'] ?? "https://via.placeholder.com/50";
                  
                  return ListTile(
                    leading: Image.network(thumbnail, width: 50, height: 50, fit: BoxFit.cover),
                    title: Text(title),
                    subtitle: Text(author),
                    onTap: () {
                      if (_isLoggedIn) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => BookDetailsPage(book: book), // Pass book data
                          ),
                        );
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text("You need to log in to view book details."),
                            duration: Duration(seconds: 2),
                          ),
                        );
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
        backgroundColor: widget.isDarkMode ? kLightBackground : kDarkBackground,
        selectedItemColor: kPrimaryColor,
        unselectedItemColor: widget.isDarkMode ? kDarkBackground : kLightBackground,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: "Home"),
          BottomNavigationBarItem(icon: Icon(Icons.add), label: "Post"),
          BottomNavigationBarItem(icon: Icon(Icons.mail), label: "Inbox"),
        ],
        onTap: (index) {
          if (index == 0) {
            Navigator.pushNamed(context, '/');
          } else if (index == 1) {
            _navigateIfAuthenticated(context, '/post');
          } else if (index == 2) {
            _navigateIfAuthenticated(context, '/inbox');
          }
        },
      ),
    );
  }
}
