import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'colors.dart';

class NavBar extends StatefulWidget {
  const NavBar({super.key});

  @override
  _NavBarState createState() => _NavBarState();
}

class _NavBarState extends State<NavBar> {
  User? _user;
  String? _firstName;
  String? _lastName;

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  // Fetch current user info
  void _loadUser() async {
    FirebaseAuth.instance.authStateChanges().listen((User? user) {
      if (user != null) {
        setState(() {
          _user = user;
        });
        _fetchUserData(user.uid);
      } else {
        setState(() {
          _user = null;
          _firstName = null;
          _lastName = null;
        });
      }
    });
  }

  // Fetch user data from Firestore separately
  Future<void> _fetchUserData(String uid) async {
    try {
      DocumentSnapshot userDoc =
          await FirebaseFirestore.instance.collection('users').doc(uid).get();

      if (userDoc.exists) {
        setState(() {
          _firstName = userDoc['first_name'];
          _lastName = userDoc['last_name'];
        });
      }
    } catch (e) {
      print("Error fetching user data: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isDarkMode = Theme.of(context).brightness == Brightness.dark;

    // Define text colors based on the theme
    final Color textColor = isDarkMode ? kDarkText : kLightText;
    final Color textColor2 = isDarkMode ? kLightText : kDarkText;

    return Drawer(
      backgroundColor: isDarkMode ? kDarkBackground : kLightBackground,
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          UserAccountsDrawerHeader(
            accountName: Text(
              _firstName != null && _lastName != null
                  ? '$_firstName $_lastName'
                  : 'Guest',
              style: TextStyle(
                fontSize: 18,
                color: textColor2,
              ),
            ),
            accountEmail: Text(
              _user?.email ?? 'Not logged in',
              style: TextStyle(
                fontSize: 14,
                color: textColor2,
              ),
            ),
            currentAccountPicture: CircleAvatar(
              backgroundColor: Colors.grey,
              child: _user?.photoURL != null
                  ? ClipOval(
                      child: Image.network(
                        _user!.photoURL!,
                        width: 90,
                        height: 90,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) =>
                            const Icon(Icons.person, size: 50, color: Colors.white),
                      ),
                    )
                  : const Icon(Icons.person, size: 50, color: Colors.white),
            ),
            decoration: BoxDecoration(
              color: isDarkMode ? kLightBackground : kDarkBackground,
            ),
          ),
          ListTile(
            leading: Icon(Icons.person, color: textColor),
            title: Text(
              'Profile',
              style: TextStyle(color: textColor),
            ),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, '/profile');
            },
          ),
          ListTile(
            leading: Icon(Icons.local_offer, color: textColor),
            title: Text(
              'Quotes',
              style: TextStyle(color: textColor),
            ),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, '/quotes');
            },
          ),

          ListTile(
            leading: Icon(Icons.settings, color: textColor),
            title: Text(
              'Settings',
              style: TextStyle(color: textColor),
            ),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, '/settings');
            },
          ),

          ListTile(
            leading: Icon(Icons.logout, color: textColor),
            title: Text(
              'Log Out',
              style: TextStyle(color: textColor),
            ),
            onTap: () async {
              Navigator.pop(context);
              await FirebaseAuth.instance.signOut();
              Navigator.pushReplacementNamed(context, '/home');
            },
          ),
        ],
      ),
    );
  }
}
