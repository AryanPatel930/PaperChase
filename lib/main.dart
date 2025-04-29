import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'login.dart';
import 'signup.dart';
import 'profile.dart';
import 'post.dart';
import 'inbox.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'colors.dart';
import 'utils.dart';
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
  bool _isDarkMode = false;

  void _toggleTheme() {
    setState(() {
      _isDarkMode = !_isDarkMode;
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
          titleTextStyle: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
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
        appBarTheme: const AppBarTheme(
          backgroundColor: kLightBackground,
          titleTextStyle: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
        ),
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          backgroundColor: kLightBackground,
          selectedItemColor: kPrimaryColor,
          unselectedItemColor: kDarkBackground,
        ),
      ),
      themeMode: _isDarkMode ? ThemeMode.dark : ThemeMode.light,
      home: HomePage(toggleTheme: _toggleTheme, isDarkMode: _isDarkMode),
      routes: {
        '/home': (context) => HomePage(toggleTheme: _toggleTheme, isDarkMode: _isDarkMode),
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
  List<DocumentSnapshot> _books = [];
  List<DocumentSnapshot> _filteredBooks = [];
  bool _isLoggedIn = false;
  User? _user;
  final String _filterBy = 'Latest Posted';
  int _selectedIndex = 0;
  
  // Filter state
  List<String> _allConditions = ['Like New', 'Good', 'Fair', 'Poor'];
  List<String> _selectedConditions = [];
  bool _filtersActive = false;

  get kDarkCard => const Color(0xFF2C2C2C);
  get kLightCard => Colors.white;

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

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });

    if (index == 1) {
      _navigateIfAuthenticated(context, '/post');
    } else if (index == 2) {
      _navigateIfAuthenticated(context, '/inbox');
    }
  }

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

  Future<void> _searchBooks() async {
    final query = _searchController.text.trim().toLowerCase();
    if (query.isEmpty) {
      setState(() {
        _filteredBooks = _books;
      });
      return;
    }

    try {
      final filteredBooks = _books.where((doc) {
        final data = doc.data() as Map<String, dynamic>;
        final title = (data['title'] ?? '').toString().toLowerCase();
        final author = (data['author'] ?? '').toString().toLowerCase();
        final isbn = (data['isbn'] ?? '').toString();
        return title.contains(query) || author.contains(query) || isbn.contains(query);
      }).toList();

      setState(() {
        _filteredBooks = filteredBooks;
      });
    } catch (e) {
      print("Error searching books: $e");
    }
  }

  Future<void> _loadRecentBooks() async {
    try {
      final QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('books')
          .orderBy('timestamp', descending: true)
          .limit(20)  // Increased limit to show more books
          .get();

      setState(() {
        _books = snapshot.docs;
        _filteredBooks = snapshot.docs;
      });
    } catch (e) {
      print("Error fetching recent books: $e");
    }
  }
  
  // Apply filters to the current book collection
  void _applyFilters() {
    setState(() {
      _filteredBooks = _books.where((doc) {
        final data = doc.data() as Map<String, dynamic>;
        
        // Condition filter only
        final condition = (data['condition'] ?? '').toString();
        final isConditionSelected = _selectedConditions.isEmpty || 
                                   _selectedConditions.contains(condition);
        
        return isConditionSelected;
      }).toList();
      
      _filtersActive = true;
    });
  }
  
  // Reset filters and show all books
  void _resetFilters() {
    setState(() {
      _selectedConditions = [];
      _filteredBooks = _books;
      _filtersActive = false;
    });
  }
  
  // Improved filter button
  Widget _buildFilterButton() {
    final bool isActive = _filtersActive;
    
    return InkWell(
      onTap: _showFilterDialog,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isActive ? kPrimaryColor : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isActive ? kPrimaryColor : widget.isDarkMode ? Colors.grey[600]! : Colors.grey[400]!,
            width: 1.5,
          ),
        ),
        child: Stack(
          children: [
            Icon(
              Icons.filter_list,
              color: isActive ? Colors.white : (widget.isDarkMode ? Colors.grey[400] : Colors.grey[700]),
              size: 22,
            ),
            if (isActive)
              Positioned(
                right: 0,
                top: 0,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
  
  // Show the filter dialog with only condition filters
  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            final bool isDarkMode = widget.isDarkMode;
            final Color backgroundColor = isDarkMode ? kDarkBackground : kLightBackground;
            final Color textColor = isDarkMode ? kLightText : kDarkText;
            
            return AlertDialog(
              backgroundColor: backgroundColor,
              title: Text(
                'Filter Books',
                style: TextStyle(
                  color: textColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Condition filter
                    Text(
                      'Condition:',
                      style: TextStyle(
                        color: textColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: _allConditions.map((condition) {
                        final isSelected = _selectedConditions.contains(condition);
                        return FilterChip(
                          label: Text(condition),
                          selected: isSelected,
                          selectedColor: kPrimaryColor.withOpacity(0.2),
                          checkmarkColor: kPrimaryColor,
                          backgroundColor: backgroundColor,
                          shape: StadiumBorder(
                            side: BorderSide(
                              color: isSelected ? kPrimaryColor : Colors.grey,
                            ),
                          ),
                          onSelected: (bool selected) {
                            setState(() {
                              if (selected) {
                                _selectedConditions.add(condition);
                              } else {
                                _selectedConditions.remove(condition);
                              }
                            });
                          },
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  child: Text(
                    'Reset',
                    style: TextStyle(color: kPrimaryColor),
                  ),
                  onPressed: () {
                    setState(() {
                      _selectedConditions = [];
                    });
                  },
                ),
                TextButton(
                  child: Text(
                    'Cancel',
                    style: TextStyle(color: Colors.grey),
                  ),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
                FilledButton(
                  style: ButtonStyle(
                    backgroundColor: MaterialStateProperty.all(kPrimaryColor),
                  ),
                  child: const Text(
                    'Apply',
                    style: TextStyle(color: Colors.white),
                  ),
                  onPressed: () {
                    // Update the main state with current filter values
                    this._selectedConditions = List.from(_selectedConditions);
                    
                    // Close the dialog
                    Navigator.of(context).pop();
                    
                    // Apply the filters
                    _applyFilters();
                  },
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: const NavBar(),
      appBar: AppBar(
        title: Image.asset('assets/title-text.png', height: 70), // Increased height from 60 to 70
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(widget.isDarkMode ? Icons.wb_sunny : Icons.nightlight_round),
            onPressed: widget.toggleTheme,
          ),
          if (!_isLoggedIn) ...[
            TextButton(
              onPressed: () => Navigator.pushNamed(context, '/login'),
              child: const Text('Login', style: TextStyle(color: Colors.white)),
            ),
            TextButton(
              onPressed: () => Navigator.pushNamed(context, '/signup'),
              child: const Text('Sign Up', style: TextStyle(color: Colors.white)),
            ),
          ],
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Search and Filter Row
            Row(
              children: [
                // Search Field
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: "Search for books",
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.search),
                        onPressed: _searchBooks,
                      ),
                    ),
                  ),
                ),
                
                // Filter Button (updated)
                const SizedBox(width: 8),
                _buildFilterButton(),
              ],
            ),
            
            // Active Filters Chips
            if (_filtersActive) ...[
              const SizedBox(height: 12),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    // Condition Chips
                    ..._selectedConditions.map((condition) {
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: Chip(
                          label: Text(condition),
                          deleteIcon: const Icon(Icons.close, size: 18),
                          onDeleted: () {
                            setState(() {
                              _selectedConditions.remove(condition);
                              _applyFilters();
                            });
                          },
                        ),
                      );
                    }).toList(),
                    
                    // Clear All Filters
                    if (_filtersActive) 
                      TextButton.icon(
                        icon: const Icon(Icons.clear_all, size: 18),
                        label: const Text('Clear All'),
                        onPressed: _resetFilters,
                      ),
                  ],
                ),
              ),
            ],
            
            const SizedBox(height: 15),
            
            // Results count
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                '${_filteredBooks.length} books found',
                style: TextStyle(
                  color: widget.isDarkMode ? kLightText : kDarkText,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            
            const SizedBox(height: 8),
            
            // Books Grid
            Expanded(
              child: _filteredBooks.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.search_off, 
                              size: 64, 
                              color: widget.isDarkMode ? Colors.grey[400] : Colors.grey[600]),
                          const SizedBox(height: 16),
                          Text(
                            'No books match your filters',
                            style: TextStyle(
                              fontSize: 18,
                              color: widget.isDarkMode ? Colors.grey[400] : Colors.grey[600],
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextButton(
                            onPressed: _resetFilters,
                            child: const Text('Reset Filters'),
                          ),
                        ],
                      ),
                    )
                  : GridView.builder(
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        mainAxisSpacing: 15,
                        crossAxisSpacing: 15,
                        childAspectRatio: 0.6,
                      ),
                      itemCount: _filteredBooks.length,
                      itemBuilder: (context, index) {
                        final doc = _filteredBooks[index];
                        final data = doc.data() as Map<String, dynamic>;

                        final bookId = doc.id;
                        final title = data['title'] ?? 'Unknown Title';
                        final condition = data['condition'] ?? 'Unknown';
                        // Extract price and format it with currency
                        final price = data['price'] != null 
                            ? '\$${data['price'].toString()}' 
                            : 'Price not listed';
                            
                        // Handle image URLs more robustly
                        String? imageUrl;
                        // First try the imageUrls field (array of images)
                        if (data.containsKey('imageUrls') && data['imageUrls'] != null) {
                          final images = data['imageUrls'];
                          if (images is List && images.isNotEmpty) {
                            imageUrl = images[0].toString();
                          }
                        }
                        // If that doesn't work, try imageUrl field (single image)
                        if ((imageUrl == null || imageUrl.isEmpty) && data.containsKey('imageUrl')) {
                          imageUrl = data['imageUrl']?.toString();
                        }
                        // If that doesn't work, try coverImageUrl field
                        if ((imageUrl == null || imageUrl.isEmpty) && data.containsKey('coverImageUrl')) {
                          imageUrl = data['coverImageUrl']?.toString();
                        }

                        return GestureDetector(
                          onTap: () {
                            if (_isLoggedIn) {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => BookDetailsPage(
                                    book: data,
                                    bookId: bookId,
                                  ),
                                ),
                              );
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text("You need to log in to view book details."),
                                  duration: Duration(seconds: 2),
                                ),
                              );
                            }
                          },
                          child: Container(
                            decoration: BoxDecoration(
                              color: widget.isDarkMode ? kDarkCard : kLightCard,
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.1),
                                  blurRadius: 8,
                                  spreadRadius: 2,
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Image section - takes up most of the space
                                Expanded(
                                  flex: 5,
                                  child: ClipRRect(
                                    borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                                    child: imageUrl != null && imageUrl.isNotEmpty
                                      ? FadeInImage.assetNetwork(
                                          placeholder: 'assets/placeholder.png',
                                          image: imageUrl,
                                          fit: BoxFit.cover,
                                          width: double.infinity,
                                          height: double.infinity,
                                          imageErrorBuilder: (context, error, stackTrace) {
                                            return Container(
                                              color: Colors.grey[300],
                                              child: const Center(child: Icon(Icons.broken_image, size: 40)),
                                            );
                                          },
                                        )
                                      : Container(
                                          color: Colors.grey[300],
                                          child: const Center(child: Icon(Icons.book, size: 40)),
                                        ),
                                  ),
                                ),
                                // Info section below the image
                                Expanded(
                                  flex: 3,
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      mainAxisAlignment: MainAxisAlignment.start,
                                      children: [
                                        // Price in bold
                                        Text(
                                          price,
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                            color: kPrimaryColor,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 2),
                                        // Title in bold
                                        Text(
                                          title,
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 13,
                                            color: widget.isDarkMode ? kDarkText : kLightText,
                                          ),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 2),
                                        // Condition not in bold
                                        Text(
                                          condition,
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: widget.isDarkMode ? Colors.grey[300] : Colors.grey[700],
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.post_add), label: 'Post'),
          BottomNavigationBarItem(icon: Icon(Icons.inbox), label: 'Inbox'),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: kPrimaryColor,
        onTap: _onItemTapped,
      ),
    );
  }
}