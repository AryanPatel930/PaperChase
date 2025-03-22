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
import 'package:animated_splash_screen/animated_splash_screen.dart';
import 'NavBar.dart';

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
      
     home: widget.isFirstLaunch
    ? AnimatedSplashScreen(
        splash: Image.asset('assets/splash_screen-4.gif', gaplessPlayback: true),
        splashIconSize: 2000.0,
        centered: true,
        nextScreen: HomePage(toggleTheme: _toggleTheme, isDarkMode: _isDarkMode),
        nextRoute: '/home',
        backgroundColor: Colors.white,
        duration: 2800, // Ensure the duration is long enough for the GIF to play
        animationDuration: const Duration(milliseconds: 1000), // Control transition speed
      )
    : HomePage(toggleTheme: _toggleTheme, isDarkMode: _isDarkMode),

      routes: {
        '/home': (context) => HomePage(toggleTheme: _toggleTheme, isDarkMode: _isDarkMode),  // Passing the flag and toggle method
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
    bool darkMode = isDarkMode(context); // Call the utility function
    return Scaffold(
      drawer: _isLoggedIn ? NavBar() : null,
      appBar: AppBar(
      iconTheme: IconThemeData(
        color: widget.isDarkMode ? kDarkBackground : kLightBackground,
      ),
       title: Text(
        'PaperChase',
        style: TextStyle(
          fontFamily: 'Impact', // Ensure "Impact" is available in your fonts
          fontSize: 24, // Adjust size as needed
          fontStyle: FontStyle.italic,
          fontWeight: FontWeight.bold,
          color: kPrimaryColor,
        ),
      ),
        
        actions: [
          IconButton(
            icon: Icon(widget.isDarkMode ? Icons.wb_sunny : Icons.nightlight_round),
            color: widget.isDarkMode ? kDarkBackground : kLightBackground,
            onPressed: widget.toggleTheme,
          ),
          if (!_isLoggedIn) ...[
            TextButton(
              onPressed: () => Navigator.pushNamed(context, '/login'),
              child: Text('Login', style: TextStyle(color: widget.isDarkMode ? kDarkBackground : Colors.white)),
            ),
            TextButton(
              onPressed: () => Navigator.pushNamed(context, '/signup'),
              child: Text('Sign Up', style: TextStyle(color: widget.isDarkMode ? kDarkBackground : Colors.white)),
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
            Navigator.pushNamed(context, '/post');
          } else if (index == 2) {
            Navigator.pushNamed(context, '/inbox');
          }
        },
      ),
    );
  }
}
