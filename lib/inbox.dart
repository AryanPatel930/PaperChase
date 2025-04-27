import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:paperchase_app/NavBar.dart';
import 'package:paperchase_app/chat_page.dart';
import 'package:paperchase_app/colors.dart';


class InboxPage extends StatefulWidget {
  const InboxPage({super.key});

  @override
  State<InboxPage> createState() => _InboxPageState();
}

class _InboxPageState extends State<InboxPage> {
  Query<Map<String, dynamic>> _getFilteredQuery(String userId) {
    return FirebaseFirestore.instance
        .collection('chats')
        .where('users', arrayContains: userId);
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
          iconTheme: IconThemeData(color: textColor),
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
          backgroundColor: scaffoldColor,
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
        bottomNavigationBar: _buildBottomNavigationBar(isDarkMode, textColor2),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Inbox',
          style: TextStyle(
            fontFamily: 'Impact',
            fontSize: 24,
            fontStyle: FontStyle.italic,
            fontWeight: FontWeight.bold,
            color: kPrimaryColor,
          ),
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
            if (snapshot.hasError) {
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
      bottomNavigationBar: _buildBottomNavigationBar(isDarkMode, textColor2),
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
            const Text('No conversations yet'),
            const SizedBox(height: 8),
            const Text('Browse books and contact sellers to start chatting'),
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
        final chatId = chat.id;
        // We'll determine real seller in FutureBuilder
        final bookId = data['bookId'] as String? ?? '';
        final lastMessage = data['lastMessage'] as String?;
        final lastMessageTime = (data['lastMessageTime'] as Timestamp?)?.toDate();
        final bookTitle = data['bookTitle'] as String?;
        final usersList = (data['users'] as List?)?.cast<String>() ?? [];

        String otherUserId = usersList.firstWhere((id) => id != currentUser.uid, orElse: () => 'unknown');

        return FutureBuilder<DocumentSnapshot>(
          future: FirebaseFirestore.instance.collection('users').doc(otherUserId).get(),
          builder: (context, userSnapshot) {
            String userName = 'Unknown User';
            if (userSnapshot.hasData && userSnapshot.data!.exists) {
              final userData = userSnapshot.data!.data() as Map<String, dynamic>? ?? {};
              userName = '${userData['first_name'] ?? ''} ${userData['last_name'] ?? ''}'.trim();
              if (userName.isEmpty) userName = 'Unknown User';
            }

            return FutureBuilder<QuerySnapshot>(
              future: FirebaseFirestore.instance
                  .collection('chats')
                  .doc(chatId)
                  .collection('messages')
                  .orderBy('timestamp', descending: false)
                  .limit(1)
                  .get(),
              builder: (context, messagesSnapshot) {
                String sellerId = '';
                String buyerId = '';
                
                // Check who sent first message to determine buyer
                if (messagesSnapshot.hasData && messagesSnapshot.data!.docs.isNotEmpty) {
                  final firstMessage = messagesSnapshot.data!.docs.first;
                  final firstMessageData = firstMessage.data() as Map<String, dynamic>;
                  buyerId = firstMessageData['senderId'] as String? ?? '';
                  
                  // If buyer is first message sender, seller is the other user
                  sellerId = usersList.firstWhere((id) => id != buyerId, orElse: () => '');
                } else {
                  // If no messages yet, use any seller ID from data if available
                  sellerId = data['sellerId'] as String? ?? '';
                  
                  // If seller ID still not available, default to book owner from books collection
                  if (sellerId.isEmpty && bookId.isNotEmpty) {
                    // This will be handled later in the next FutureBuilder
                  }
                }

                // Return placeholder while loading book data if necessary
                if (sellerId.isEmpty && bookId.isNotEmpty) {
                  return FutureBuilder<DocumentSnapshot>(
                    future: FirebaseFirestore.instance.collection('books').doc(bookId).get(),
                    builder: (context, bookSnapshot) {
                      if (bookSnapshot.hasData && bookSnapshot.data!.exists) {
                        final bookData = bookSnapshot.data!.data() as Map<String, dynamic>? ?? {};
                        sellerId = bookData['userId'] as String? ?? '';
                      }
                      
                      // Now build the actual chat list item
                      return _buildChatListItem(
                        context,
                        chatId,
                        userName,
                        currentUser.uid,
                        sellerId,
                        bookTitle,
                        lastMessage,
                        lastMessageTime,
                        isDarkMode,
                        textColor,
                      );
                    },
                  );
                }

                return _buildChatListItem(
                  context,
                  chatId,
                  userName,
                  currentUser.uid,
                  sellerId,
                  bookTitle,
                  lastMessage,
                  lastMessageTime,
                  isDarkMode,
                  textColor,
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildChatListItem(
    BuildContext context,
    String chatId,
    String userName,
    String currentUserId,
    String sellerId,
    String? bookTitle,
    String? lastMessage,
    DateTime? lastMessageTime,
    bool isDarkMode,
    Color textColor,
  ) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      color: isDarkMode ? Colors.grey[900] : Colors.white,
      child: ListTile(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => StrictChatPage(
                chatId: chatId,
                otherUserName: userName,
                currentUserId: currentUserId,
                sellerId: sellerId,
              ),
            ),
          );
        },
        leading: CircleAvatar(
          backgroundColor: isDarkMode ? Colors.grey[800] : Colors.grey[200],
          child: Text(
            userName.isNotEmpty ? userName[0].toUpperCase() : '?',
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
  }

  BottomNavigationBar _buildBottomNavigationBar(bool isDarkMode, Color textColor2) {
    return BottomNavigationBar(
      backgroundColor: isDarkMode ? kLightBackground : kDarkBackground,
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