import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart' show kDebugMode;
import 'colors.dart';
import 'NavBar.dart';
import 'chat_page.dart';

enum BookFilter {
  all,
  sold,
  bought,
}

class InboxPage extends StatefulWidget {
  const InboxPage({super.key});

  @override
  State<InboxPage> createState() => _InboxPageState();
}

class _InboxPageState extends State<InboxPage> {
  BookFilter _currentFilter = BookFilter.all;

  String _getFilterName(BookFilter filter) {
    switch (filter) {
      case BookFilter.all:
        return 'All Books';
      case BookFilter.sold:
        return 'Sold Books';
      case BookFilter.bought:
        return 'Bought Books';
    }
  }

  Query<Map<String, dynamic>> _getFilteredQuery(String userId) {
    final baseQuery = FirebaseFirestore.instance.collection('chats');
    switch (_currentFilter) {
      case BookFilter.all:
        return baseQuery.where('users', arrayContains: userId);
      case BookFilter.sold:
        return baseQuery
            .where('users', arrayContains: userId)
            .where('sellerId', isEqualTo: userId);
      case BookFilter.bought:
        return baseQuery
            .where('users', arrayContains: userId)
            .where('buyerId', isEqualTo: userId);
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;
    final bool isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDarkMode ? kDarkBackground : kLightBackground;
    final scaffoldColor = isDarkMode ? kLightBackground : kDarkBackground;
    final textColor = isDarkMode ? kDarkText : kLightText;
    final textColor2 = isDarkMode ? kLightText : kDarkText;

    if (currentUser == null) {
      return Scaffold(
        appBar: AppBar(
          iconTheme: IconThemeData(
            color: isDarkMode ? kDarkBackground : kLightBackground,
          ),
          title: const Text(
            "Inbox",
            style: TextStyle(
              fontFamily: 'Impact',
              fontSize: 24,
              fontStyle: FontStyle.italic,
              fontWeight: FontWeight.bold,
              color: kPrimaryColor,
            ),
          ),
          foregroundColor: isDarkMode ? kLightBackground : kDarkBackground,
        ),
        drawer: const NavBar(),
        body: Container(
          color: backgroundColor,
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.lock_outline, size: 64, color: textColor.withOpacity(0.5)),
                const SizedBox(height: 16),
                Text(
                  'Please log in to view your messages',
                  style: TextStyle(fontSize: 18, color: textColor.withOpacity(0.7)),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () => Navigator.pushNamed(context, '/login'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kPrimaryColor,
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                  ),
                  child: const Text('Log In', style: TextStyle(fontSize: 16)),
                ),
              ],
            ),
          ),
        ),
        bottomNavigationBar: BottomNavigationBar(
          backgroundColor: isDarkMode ? kLightBackground : kDarkBackground,
          selectedItemColor: kPrimaryColor,
          unselectedItemColor: isDarkMode ? kDarkBackground : kLightBackground,
          currentIndex: 1,
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

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const Text(
              'Inbox',
              style: TextStyle(
                fontFamily: 'Impact',
                fontSize: 24,
                fontStyle: FontStyle.italic,
                fontWeight: FontWeight.bold,
                color: kPrimaryColor,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: isDarkMode ? Colors.grey[800] : Colors.grey[200],
                  borderRadius: BorderRadius.circular(20),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<BookFilter>(
                    value: _currentFilter,
                    icon: Icon(Icons.arrow_drop_down, color: textColor),
                    style: TextStyle(color: textColor, fontSize: 14),
                    dropdownColor: isDarkMode ? Colors.grey[800] : Colors.grey[200],
                    items: BookFilter.values.map((filter) {
                      return DropdownMenuItem<BookFilter>(
                        value: filter,
                        child: Text(_getFilterName(filter)),
                      );
                    }).toList(),
                    onChanged: (BookFilter? newValue) {
                      if (newValue != null) {
                        setState(() {
                          _currentFilter = newValue;
                        });
                      }
                    },
                  ),
                ),
              ),
            ),
          ],
        ),
        backgroundColor: scaffoldColor,
        iconTheme: IconThemeData(color: textColor2),
      ),
      drawer: const NavBar(),
      body: Container(
        color: backgroundColor,
        child: StreamBuilder<QuerySnapshot>(
          stream: _getFilteredQuery(currentUser.uid)
              .orderBy('lastMessageTime', descending: true)
              .snapshots(),
          builder: (context, snapshot) {
            if (kDebugMode) {
              print('Current user ID in Inbox: ${currentUser.uid}');
              print('Current filter: ${_getFilterName(_currentFilter)}');
              print('Stream connection state: ${snapshot.connectionState}');
              if (snapshot.hasError) {
                print('Stream error: ${snapshot.error}');
                print('Error stack trace: ${snapshot.stackTrace}');
              }
            }
            
            if (snapshot.hasError) {
              final error = snapshot.error.toString();
              if (error.contains('failed-precondition') || error.contains('requires an index')) {
                return StreamBuilder<QuerySnapshot>(
                  stream: _getFilteredQuery(currentUser.uid).snapshots(),
                  builder: (context, simpleSnapshot) {
                    return _buildChatList(simpleSnapshot, currentUser, isDarkMode, textColor);
                  },
                );
              }
              return Center(
                child: Text(
                  'Error loading conversations: ${snapshot.error}',
                  style: TextStyle(color: textColor),
                ),
              );
            }
            
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            
            return _buildChatList(snapshot, currentUser, isDarkMode, textColor);
          },
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: scaffoldColor,
        selectedItemColor: kPrimaryColor,
        unselectedItemColor: textColor2,
        currentIndex: 2,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.add), label: 'Post'),
          BottomNavigationBarItem(icon: Icon(Icons.mail), label: 'Inbox'),
        ],
        onTap: (index) {
          if (index == 0) {
            Navigator.pushReplacementNamed(context, '/');
          } else if (index == 1) {
            Navigator.pushReplacementNamed(context, '/post');
          }
        },
      ),
    );
  }

  Widget _buildChatList(AsyncSnapshot<QuerySnapshot> snapshot, User currentUser, bool isDarkMode, Color textColor) {
    final chats = snapshot.data?.docs ?? [];
    
    if (chats.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.chat_bubble_outline, size: 64, color: textColor.withOpacity(0.5)),
            const SizedBox(height: 16),
            Text(
              _currentFilter == BookFilter.all
                  ? 'No conversations yet'
                  : _currentFilter == BookFilter.sold
                      ? 'No sold books conversations'
                      : 'No bought books conversations',
              style: TextStyle(fontSize: 18, color: textColor.withOpacity(0.7)),
            ),
            const SizedBox(height: 8),
            Text(
              _currentFilter == BookFilter.all
                  ? 'Browse books and contact sellers to start chatting'
                  : 'No messages found for this filter',
              style: TextStyle(fontSize: 14, color: textColor.withOpacity(0.5)),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    final sortedChats = List.from(chats);
    sortedChats.sort((a, b) {
      final aTime = (a.data() as Map<String, dynamic>)['lastMessageTime'] as Timestamp?;
      final bTime = (b.data() as Map<String, dynamic>)['lastMessageTime'] as Timestamp?;
      if (aTime == null && bTime == null) return 0;
      if (aTime == null) return 1;
      if (bTime == null) return -1;
      return bTime.compareTo(aTime);
    });

    return ListView.builder(
      itemCount: sortedChats.length,
      itemBuilder: (context, index) {
        final chat = sortedChats[index];
        final data = chat.data() as Map<String, dynamic>;
        
        if (kDebugMode) {
          print('Chat data: $data');
        }
        
        final lastMessage = data['lastMessage'] as String?;
        final lastMessageTime = (data['lastMessageTime'] as Timestamp?)?.toDate();
        final bookTitle = data['bookTitle'] as String?;
        final usersList = (data['users'] as List?)?.cast<String>() ?? [];
        
        String otherUserId;
        try {
          otherUserId = usersList.firstWhere(
            (id) => id != currentUser.uid,
            orElse: () => 'unknown',
          );
        } catch (e) {
          if (kDebugMode) {
            print('Error finding other user: $e');
          }
          otherUserId = 'unknown';
        }
        
        return FutureBuilder<DocumentSnapshot>(
          future: FirebaseFirestore.instance.collection('users').doc(otherUserId).get(),
          builder: (context, userSnapshot) {
            String userName = 'Unknown User';
            if (userSnapshot.hasData && userSnapshot.data!.exists) {
              final userData = userSnapshot.data!.data() as Map<String, dynamic>? ?? {};
              userName = '${userData['first_name'] ?? ''} ${userData['last_name'] ?? ''}'.trim();
              if (userName.isEmpty) userName = 'Unknown User';
            }
            
            return Card(
              margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              color: isDarkMode ? Colors.grey[900] : Colors.white,
              child: ListTile(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => StrictChatPage(
                        chatId: chat.id,
                        otherUserName: userName,
                        predefinedMessages: const [
                          "Is this still available?",
                          "When can we meet?",
                          "I'll take it",
                          "Thanks!",
                          "Hello",
                          "Can you hold it for me?",
                          "What's your lowest price?",
                        ],
                      ),
                    ),
                  );
                },
                leading: CircleAvatar(
                  backgroundColor: isDarkMode ? Colors.grey[800] : Colors.grey[200],
                  child: Text(
                    userName[0].toUpperCase(),
                    style: TextStyle(
                      color: textColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                title: Text(
                  userName,
                  style: TextStyle(
                    color: textColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (bookTitle != null)
                      Text(
                        'Re: $bookTitle',
                        style: TextStyle(
                          color: textColor.withOpacity(0.7),
                          fontSize: 12,
                        ),
                      ),
                    Text(
                      lastMessage ?? 'No messages yet',
                      style: TextStyle(
                        color: textColor.withOpacity(0.7),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
                trailing: lastMessageTime != null
                    ? Text(
                        _formatTimestamp(lastMessageTime),
                        style: TextStyle(
                          color: textColor.withOpacity(0.5),
                          fontSize: 12,
                        ),
                      )
                    : null,
              ),
            );
          },
        );
      },
    );
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);
    if (difference.inDays > 7) {
      return '${timestamp.month}/${timestamp.day}/${timestamp.year}';
    } else if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }
}