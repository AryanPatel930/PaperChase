import 'package:flutter/material.dart';
import 'colors.dart';

class SettingsPage extends StatefulWidget {
  final bool isDarkMode;
  final VoidCallback toggleTheme;

  const SettingsPage({
    Key? key,
    required this.isDarkMode,
    required this.toggleTheme,
  }) : super(key: key);

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool _notificationsEnabled = true; // Replace with your actual state logic

  @override
  Widget build(BuildContext context) {
    final bool isDarkMode = widget.isDarkMode;

    return Scaffold(
      appBar: AppBar(
        iconTheme: IconThemeData(
          color: isDarkMode ? kDarkBackground : kLightBackground,
        ),
        title: const Text(
          "Settings",
          style: TextStyle(
            fontFamily: 'Impact',
            fontSize: 24,
            fontStyle: FontStyle.italic,
            fontWeight: FontWeight.bold,
            color: kPrimaryColor,
          ),
        ),
        foregroundColor: isDarkMode ? kDarkBackground : kLightBackground,
      ),
      body: ListView(
        children: [
          // Notifications Toggle
          ListTile(
            title: Text(
              "Notifications",
              style: TextStyle(
                color: isDarkMode ? kLightBackground : kDarkBackground,
              ),
            ),
            leading: Icon(Icons.notifications,
            color: widget.isDarkMode ? kLightBackground : kDarkBackground,),
            trailing: Switch(
              focusColor: isDarkMode ? kLightBackground : kDarkBackground,
              activeColor: kAccentColor,
              value: _notificationsEnabled,
              onChanged: (bool value) {
                setState(() {
                  _notificationsEnabled = value;
                });
                // TODO: Implement your actual notification toggle logic here
                // For example, save to SharedPreferences, Firestore, etc.
                print("Notifications toggled: $_notificationsEnabled");
              },
            ),
          ),

          // Change Theme tile
          ListTile(
            leading: Icon(
              isDarkMode ? Icons.wb_sunny : Icons.nightlight_round,
              color: isDarkMode ? kLightBackground : kDarkBackground,
            ),
            title: Text(
              "Change Theme",
              style: TextStyle(
                color: isDarkMode ? kLightBackground : kDarkBackground,
              ),
            ),
            onTap: widget.toggleTheme, 
          ),

          // Contact Support tile
          ListTile(
            title: Text(
              "Contact Support",
              style: TextStyle(
                color: isDarkMode ? kLightBackground : kDarkBackground,
              ),
            ),
            leading: Icon(Icons.contact_support,
            color: widget.isDarkMode ? kLightBackground : kDarkBackground,),
            onTap: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Contact Support'),
                  content: const Text('Email us at apatel50@pride.hofstra.edu'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('OK'),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: isDarkMode ? kLightBackground : kDarkBackground,
        selectedItemColor: isDarkMode ? kDarkBackground : kLightBackground,
        unselectedItemColor: isDarkMode ? kDarkBackground : kLightBackground,
        currentIndex: 1, // Adjust if needed
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
