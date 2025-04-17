import 'package:flutter/material.dart';
import 'colors.dart';
import 'post.dart';
import 'inbox.dart';

class HomeScreen extends StatefulWidget {
  final VoidCallback toggleTheme;
  final bool isDarkMode;

  const HomeScreen({
    super.key,
    required this.toggleTheme,
    required this.isDarkMode,
  });

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  final List<Widget> _screens = [
    const HomePage(),
    PostBookPage(),
    const InboxPage(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

 @override
Widget build(BuildContext context) {
  return Scaffold(
    body: _screens[_selectedIndex],
    bottomNavigationBar: BottomNavigationBar(
      backgroundColor: widget.isDarkMode ? kLightBackground : kDarkBackground,
      selectedItemColor: kPrimaryColor,
      unselectedItemColor: widget.isDarkMode ? kDarkBackground : kLightBackground,
      currentIndex: _selectedIndex,
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.home), label: "Home"),
        BottomNavigationBarItem(icon: Icon(Icons.add), label: "Post"),
        BottomNavigationBarItem(icon: Icon(Icons.mail), label: "Inbox"),
      ],
      onTap: (index) {
          if (index == 0) {
            Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
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

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text("Home Screen"),
    );
  }
}
