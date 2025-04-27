import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:paperchase_app/book_detail_page.dart';
import 'colors.dart';

class StrictChatPage extends StatefulWidget {
  final String chatId;
  //final String bookId;
  final String otherUserName;
  final String currentUserId;
  final String sellerId;


  const StrictChatPage({
    Key? key,
    required this.chatId,
    required this.otherUserName,
    required this.currentUserId,
    required this.sellerId,
    }) : super(key: key);

  @override
  _StrictChatPageState createState() => _StrictChatPageState();
}

class _StrictChatPageState extends State<StrictChatPage> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _messageController = TextEditingController();
  String? _bookTitle;
  String? _bookId;

List<String> get predefinedMessages {
    final currentUser = FirebaseAuth.instance.currentUser;
    final email = currentUser?.email ?? "your email";
    if (widget.currentUserId == widget.sellerId) {
      return [
        "Yes, it's still available.",
        "Thanks!",
        "How about we meet this weekend?",
        "That a deal!",
        "Yes, I will hold it",
        "Contact me at $email"

      ];
    } else {
      return [
        "Is this still available?",
        "When can we meet?",
        "I'll take it",
        "Thanks!",
        "Can you hold it for me?",
        "Contact me at $email",
      ];
    }
  }

  @override
  void initState() {
    super.initState();
    _fetchBookTitle();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _fetchBookTitle() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('chats')
          .doc(widget.chatId)
          .get();

      if (doc.exists) {
        setState(() {
          _bookTitle = doc.data()?['bookTitle'] as String?;
          _bookId = doc.data()?['bookId'] as String?;
        });
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error fetching book title: $e');
      }
    }
  }

  Future<void> _sendMessage(String text) async {
    if (text.trim().isEmpty) return;
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    await FirebaseFirestore.instance
        .collection('chats')
        .doc(widget.chatId)
        .collection('messages')
        .add({
      'message': text,
      'senderId': currentUser.uid,
      'timestamp': FieldValue.serverTimestamp(),
    });

    await FirebaseFirestore.instance
        .collection('chats')
        .doc(widget.chatId)
        .update({
      'lastMessage': text,
      'lastMessageTime': FieldValue.serverTimestamp(),
    });

    _messageController.clear();
    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final bool isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDarkMode ? kDarkBackground : kLightBackground;
    final backgroundColor2 = isDarkMode ? kLightBackground : kDarkBackground;
    final textColor = isDarkMode ? kDarkText : kLightText;
    final textColor2 = isDarkMode ? kLightText : kDarkText;
    final messageBackgroundOther = isDarkMode ? Colors.grey[800] : Colors
        .grey[200];

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.otherUserName,
              style: TextStyle(
                fontFamily: 'Impact',
                fontSize: 20,
                fontStyle: FontStyle.italic,
                fontWeight: FontWeight.bold,
                color: kPrimaryColor,
              ),
            ),
            if (_bookTitle != null)
              Text(
                '$_bookTitle',
                style: TextStyle(
                  fontSize: 14,
                  color: textColor2.withOpacity(0.7),
                ),
              ),
          ],
        ),
        backgroundColor: backgroundColor2,
        elevation: 1,
        iconTheme: IconThemeData(color: textColor2),
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('chats')
                  .doc(widget.chatId)
                  .collection('messages')
                  .orderBy('timestamp', descending: false)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final messages = snapshot.data!.docs;
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  _scrollToBottom();
                });

                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(8),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final message = messages[index];
                    final data = message.data() as Map<String, dynamic>;
                    final text = data['message'] as String? ?? '';
                    final senderId = data['senderId'] as String? ?? '';
                    final currentUser = FirebaseAuth.instance.currentUser;
                    final isMe = currentUser != null &&
                        senderId == currentUser.uid;

                    return Container(
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        mainAxisAlignment: isMe
                            ? MainAxisAlignment.end
                            : MainAxisAlignment.start,
                        children: [
                          Container(
                            constraints: BoxConstraints(
                              maxWidth: MediaQuery
                                  .of(context)
                                  .size
                                  .width * 0.75,
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 10,
                            ),
                            decoration: BoxDecoration(
                              color: isMe
                                  ? Colors.blue[500]
                                  : messageBackgroundOther,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Text(
                              text,
                              style: TextStyle(
                                color: isMe ? Colors.white : textColor,
                                fontSize: 16,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
          Container(
  padding: const EdgeInsets.all(16),
  margin: const EdgeInsets.only(top: 2),
  width: double.infinity,
  decoration: BoxDecoration(
    color: backgroundColor2,
    border: Border(
      top: BorderSide(
        color: backgroundColor.withOpacity(0.2),
      ),
    ),
  ),
  child: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        'Quick replies:',
        style: TextStyle(
          color: textColor2.withOpacity(0.7),
          fontSize: 14,
        ),
      ),

      // Only show the Confirmed button if the current user is the seller
      if (widget.currentUserId == widget.sellerId)
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () => _confirmAndCompletePurchase(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.lightGreenAccent,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              'Confirmed!',
              style: TextStyle(fontSize: 18, color: kLightText),
            ),
          ),
        ),
      if (widget.currentUserId == widget.sellerId)
        const SizedBox(height: 12),

      Wrap(
        spacing: 12,
        runSpacing: 12,
        children: predefinedMessages.map((msg) {
          return ActionChip(
            label: Text(msg),
            onPressed: () => _sendMessage(msg),
            backgroundColor: backgroundColor,
            labelStyle: TextStyle(color: textColor,),
          );
        }).toList(),
      ),
      const SizedBox(height: 12),
    ],
  ),
),
        ],
      ),
    );
  }

  void _confirmAndCompletePurchase(BuildContext context) async {
    await FirebaseFirestore.instance.collection('books').doc(_bookId).delete();
    //await FirebaseFirestore.instance.collection('chats').doc(widget.chatId).collection('messages').doc().delete();
    await FirebaseFirestore.instance.collection('chats').doc(widget.chatId).delete();
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Transaction completed!')),
    );
  }
}