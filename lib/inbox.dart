import 'package:flutter/material.dart';

//class InboxPage extends StatelessWidget {
//  const InboxPage({super.key});

class InboxPage extends StatefulWidget {
  @override
  _InboxPageState createState() => _InboxPageState();
}

class _InboxPageState extends State<InboxPage> {
  String _sortedBy = "All Books";
  // default value for accept/decline
  // When Choice = 1, user accepts offer
  // When Choice = 2, user declines offer
  int Choice = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Inbox")),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Sorting Books
              DropdownButtonFormField<String>(
                value: _sortedBy,
                items: ['All Books', 'Books Sold', 'Books Bought']
                    .map((sortedBy) => DropdownMenuItem(
                        value: sortedBy,
                        child: Text(sortedBy),
                      ))
                    .toList(),
                onChanged: (value) {
                  setState(() {
                    _sortedBy = value!;
                  });
                },
                decoration: InputDecoration(labelText: 'Sort By:'),
              ),

              // UI for individual messages, this would be the format
              ListTile(
                leading: FlutterLogo(size: 72.0),
                title: Text('Test'),
                subtitle: Text('Person wants book for this amount of money'),
                trailing: PopupMenuButton<int>(
                  itemBuilder:
                      (BuildContext context) => <PopupMenuEntry<int>>[
                    const PopupMenuItem<int>(
                      value: 1,
                      child: Text('Accept'),
                    ),
                    const PopupMenuItem<int>(
                      value: 2,
                      child: Text('Decline'),
                    ),
                  ],
                ),
              ),
              const Divider(),

            ],
          ),
        ),
      ),



      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: Colors.black,
        selectedItemColor: Colors.white,
        unselectedItemColor: Colors.grey,
        currentIndex: 2, // Highlight the "Inbox" tab
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
            Navigator.pushNamed(context, '/inbox'); // Stay on the same page
          }
        },
      ),
    );
  }
}
