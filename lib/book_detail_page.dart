import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'colors.dart';
import 'NavBar.dart';

class BookDetailsPage extends StatelessWidget {
  final Map<String, dynamic> book;
  final String bookId;


  const BookDetailsPage({super.key, required this.book, required this.bookId});

  @override
  Widget build(BuildContext context) {
    
    final bool isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final currentUser = FirebaseAuth.instance.currentUser;
    final isMyBook = currentUser?.uid == book['userId'];


    final title = book['title'] ?? 'No title available';
    final author = book['author'] ?? 'No author available';
    final isbn = book['isbn'] ?? 'No ISBN available';
    final price = book['price'] is String
        ? double.tryParse(book['price']) ?? 0.0
        : book['price'] ?? 0.0;
    final condition = book['condition'] ?? 'Condition not available';
    final description = book['description'] ?? 'No description available';
    final imageUrl = book['imageUrl'] ?? 'https://via.placeholder.com/200';

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: true,
        iconTheme: IconThemeData(
          color: isDarkMode ? kDarkBackground : kLightBackground,
        ),
        title: Text(
          title,
          style: TextStyle(
            fontFamily: 'Impact',
            fontSize: 24,
            fontStyle: FontStyle.italic,
            fontWeight: FontWeight.bold,
            color: kPrimaryColor,
          ),
        ),
      ),
      
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: imageUrl.isNotEmpty
                    ? Image.network(imageUrl, height: 200, fit: BoxFit.cover)
                    : Icon(Icons.book, size: 100),
              ),
              const SizedBox(height: 20),
              Text("Title: $title",
                  style:
                      const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
              Text("Author: $author", style: const TextStyle(fontSize: 18)),
              Text("ISBN: $isbn", style: const TextStyle(fontSize: 16)),
              Text("Price: \$${price.toStringAsFixed(2)}",
                  style: const TextStyle(fontSize: 16, color: Colors.green)),
              Text("Condition: $condition", style: const TextStyle(fontSize: 16)),
              const SizedBox(height: 10),
              const Text("Description:",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              Text(description, style: const TextStyle(fontSize: 16)),
              const SizedBox(height: 24),
              if (isMyBook && currentUser != null)
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => _confirmAndDeleteBook(context, bookId),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Delete Book',
                      style: TextStyle(fontSize: 18, color: Colors.white),
                    ),
                  ),
                )

              else if (!isMyBook && currentUser != null)
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () =>
                        _contactSeller(context, book['userId'], title),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: kPrimaryColor,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Contact Seller',
                      style: TextStyle(fontSize: 18, color: Colors.white),
                    ),
                  ),
                  
                )
                
              else if (currentUser == null)
                Center(
                  child: TextButton(
                    onPressed: () =>
                        Navigator.pushNamed(context, '/login'),
                    child: const Text(
                      'Log in to contact the seller',
                      style: TextStyle(fontSize: 16),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: isDarkMode ? kLightBackground : kDarkBackground,
        selectedItemColor:
            isDarkMode ? kDarkBackground : kLightBackground,
        unselectedItemColor:
            isDarkMode ? kDarkBackground : kLightBackground,
        currentIndex: 2,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: "Home"),
          BottomNavigationBarItem(icon: Icon(Icons.add), label: "Post"),
          BottomNavigationBarItem(icon: Icon(Icons.mail), label: "Inbox"),
        ],
        onTap: (index) {
          if (index == 0) {
            Navigator.pushNamedAndRemoveUntil(context, '/', (_) => false);
          } else if (index == 1) {
            Navigator.pushNamed(context, '/post');
          } else if (index == 2) {
            Navigator.pushNamed(context, '/inbox');
          }
        },
      ),
    );
  }

  

  Future<void> _contactSeller(
    
      BuildContext context, String sellerId, String bookTitle) async {
    final currentUser = FirebaseAuth.instance.currentUser;

    
    if (currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please log in to contact the seller')),
      );
      return;
    }

    try {
      final users = [currentUser.uid, sellerId]..sort();
      final chatRoomId = users.join('_');

      final existingChat = await FirebaseFirestore.instance
          .collection('chats')
          .doc(chatRoomId)
          .get();

      final chatData = {
        'users': users,
        'lastMessage': 'Hi! Is this book still available?',
        'lastMessageTime': FieldValue.serverTimestamp(),
        'bookTitle': bookTitle,
        'createdAt': FieldValue.serverTimestamp(),
        'participants': {
          currentUser.uid: true,
          sellerId: true,
        },
      };

      if (existingChat.exists) {
        await FirebaseFirestore.instance
            .collection('chats')
            .doc(chatRoomId)
            .update({
          'lastMessage': chatData['lastMessage'],
          'lastMessageTime': chatData['lastMessageTime'],
        });
      } else {
        await FirebaseFirestore.instance
            .collection('chats')
            .doc(chatRoomId)
            .set(chatData);
      }

      await FirebaseFirestore.instance
          .collection('chats')
          .doc(chatRoomId)
          .collection('messages')
          .add({
        'senderId': currentUser.uid,
        'message': 'Hi! Is this book still available?',
        'timestamp': FieldValue.serverTimestamp(),
      });

      if (context.mounted) {
        Navigator.pushReplacementNamed(context, '/inbox');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Chat started with the seller')),
        );
      }
    } catch (e) {
      debugPrint("Error contacting seller: $e");
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Failed to contact seller. Please try again.')),
        );
      }
    }
  }

  void _confirmAndDeleteBook(BuildContext context, String bookId) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Deletion'),
        content: const Text('Are you sure you want to delete this book?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete')),
        ],
      ),
    );

    if (shouldDelete == true) {
      await FirebaseFirestore.instance.collection('books').doc(bookId).delete();
      if (context.mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Book removed successfully')),
        );
      }
    }
  }


  String _formatPrice(dynamic price) {
    if (price == null) return '0.00';
    if (price is num) return price.toStringAsFixed(2);
    if (price is String) {
      try {
        return double.parse(price).toStringAsFixed(2);
      } catch (_) {
        return price;
      }
    }
    return '0.00';
  }
}
