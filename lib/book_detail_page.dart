import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:paperchase_app/seller_profile_page.dart';
import 'package:paperchase_app/chat_page.dart'; // Import chat page

class BookDetailsPage extends StatefulWidget {
  final Map<String, dynamic> book;
  final String bookId;

  const BookDetailsPage({super.key, required this.book, required this.bookId});

  @override
  State<BookDetailsPage> createState() => _BookDetailsPageState();
}

class _BookDetailsPageState extends State<BookDetailsPage> {
  late Future<DocumentSnapshot> _sellerFuture;
  bool _hasReviewed = false;
  int _userRating = 0;
  final _reviewController = TextEditingController();
  bool _isSubmitting = false;
  bool _isContactingSellerLoading = false;
  bool _isDeleting = false; // Track deletion status

  @override
  void initState() {
    super.initState();
    _sellerFuture = FirebaseFirestore.instance
        .collection('users')
        .doc(widget.book['userId'])
        .get();
    _checkExistingReview();
  }

  Future<void> _checkExistingReview() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    try {
      final reviewDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.book['userId'])
          .collection('reviews')
          .doc(currentUser.uid)
          .get();

      if (reviewDoc.exists) {
        if (mounted) {
          setState(() {
            _hasReviewed = true;
            _userRating = reviewDoc.data()?['rating'] ?? 0;
            _reviewController.text = reviewDoc.data()?['comment'] ?? '';
          });
        }
      }
    } catch (e) {
      print('Error checking existing review: $e');
    }
  }

  Future<void> _contactSeller(BuildContext context, String sellerName) async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please log in to contact the seller')),
      );
      return;
    }

    setState(() {
      _isContactingSellerLoading = true;
    });

    try {
      // Get current user info
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser.uid)
          .get();
      
      final buyerName = userDoc.exists 
          ? "${userDoc.data()?['first_name'] ?? ''} ${userDoc.data()?['last_name'] ?? ''}".trim()
          : "Anonymous User";

      // Check if a chat already exists between these users for this book
      final existingChatQuery = await FirebaseFirestore.instance
          .collection('chats')
          .where('bookId', isEqualTo: widget.bookId)
          .where('users', arrayContains: currentUser.uid)
          .get();

      String chatId;
      
      if (existingChatQuery.docs.isNotEmpty) {
        // Chat already exists, use existing chat
        chatId = existingChatQuery.docs.first.id;
      } else {
        // Create a new chat document
        final chatRef = FirebaseFirestore.instance.collection('chats').doc();
        chatId = chatRef.id;
        
        await chatRef.set({
          'users': [currentUser.uid, widget.book['userId']],
          'buyerId': currentUser.uid,
          'sellerId': widget.book['userId'],
          'bookId': widget.bookId,
          'bookTitle': widget.book['title'] ?? 'Unknown Book',
          'createdAt': FieldValue.serverTimestamp(),
          'lastMessage': 'No messages yet',
          'lastMessageTime': FieldValue.serverTimestamp(),
          'lastMessageSenderId': '',
        });
      }

      if (mounted) {
        setState(() {
          _isContactingSellerLoading = false;
        });
        
        // Navigate to the chat page
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => StrictChatPage(
              chatId: chatId,
              otherUserName: sellerName,
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
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isContactingSellerLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error contacting seller: $e')),
        );
      }
    }
  }

  @override
  void dispose() {
    _reviewController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final currentUser = FirebaseAuth.instance.currentUser;
    final isMyBook = currentUser?.uid == widget.book['userId'];

    final title = widget.book['title'] ?? 'No title available';
    final author = widget.book['author'] ?? 'No author available';
    final isbn = widget.book['isbn'] ?? 'No ISBN available';
    final price = widget.book['price'] is String
        ? double.tryParse(widget.book['price']) ?? 0.0
        : widget.book['price'] ?? 0.0;
    final condition = widget.book['condition'] ?? 'Condition not available';
    final description = widget.book['description'] ?? 'No description available';
    final imageUrl = widget.book['imageUrl'] ?? 'https://via.placeholder.com/200';
    final postedDate = widget.book['createdAt'] != null
        ? _formatDate(widget.book['createdAt'])
        : 'Date not available';

    return Scaffold(
      backgroundColor: isDarkMode ? Colors.black : Colors.grey[100],
      appBar: AppBar(
        backgroundColor: isDarkMode ? Colors.black : Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: isDarkMode ? Colors.white : Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          if (isMyBook)
            IconButton(
              icon: Icon(Icons.more_vert, color: isDarkMode ? Colors.white : Colors.black),
              onPressed: () => _showOptionsMenu(context),
            ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AspectRatio(
              aspectRatio: 1.0,
              child: Container(
                width: double.infinity,
                color: Colors.grey[300],
                child: imageUrl.isNotEmpty
                    ? Image.network(
                        imageUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Center(child: Icon(Icons.book, size: 100, color: Colors.grey[500]));
                        },
                      )
                    : Center(child: Icon(Icons.book, size: 100, color: Colors.grey[500])),
              ),
            ),
            
            Container(
              color: isDarkMode ? Colors.black : Colors.white,
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '\$${price.toStringAsFixed(2)}',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: isDarkMode ? Colors.white : Colors.black,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                      color: isDarkMode ? Colors.white : Colors.black,
                    ),
                  ),
                  const SizedBox(height: 4),
                ],
              ),
            ),

            const SizedBox(height: 8),

            // Seller Section with Rating
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => SellerProfilePage(
                      sellerId: widget.book['userId'],
                    ),
                  ),
                );
              },
              child: Container(
                color: isDarkMode ? Colors.black : Colors.white,
                padding: const EdgeInsets.all(16.0),
                child: FutureBuilder<DocumentSnapshot>(
                  future: _sellerFuture,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    String sellerName = 'Unknown Seller';
                    String sellerAvatar = '';
                    double averageRating = 0;
                    int reviewCount = 0;

                    if (snapshot.hasData && snapshot.data!.exists) {
                      final userData = snapshot.data!.data() as Map<String, dynamic>?;
                      if (userData != null) {
                        sellerName = "${userData['first_name'] ?? ''} ${userData['last_name'] ?? ''}".trim();
                        sellerAvatar = userData['avatar_url'] ?? '';
                        averageRating = userData['average_rating']?.toDouble() ?? 0.0;
                        reviewCount = userData['review_count']?.toInt() ?? 0;
                      }
                    }

                    return Row(
                      children: [
                        CircleAvatar(
                          radius: 20,
                          backgroundColor: Colors.grey[300],
                          backgroundImage: sellerAvatar.isNotEmpty ? NetworkImage(sellerAvatar) : null,
                          child: sellerAvatar.isEmpty ? const Icon(Icons.person, color: Colors.white) : null,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                sellerName,
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                  color: isDarkMode ? Colors.white : Colors.black,
                                ),
                              ),
                              Text(
                                isMyBook ? 'You' : 'Seller',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[600],
                                ),
                              ),
                              Row(
                                children: [
                                  _buildRatingStars(averageRating, size: 16),
                                  Text(
                                    ' (${reviewCount.toString()})',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
                      ],
                    );
                  },
                ),
              ),
            ),

            const SizedBox(height: 8),

            // Description section
            Container(
              color: isDarkMode ? Colors.black : Colors.white,
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Description',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: isDarkMode ? Colors.white : Colors.black,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: 16,
                      color: isDarkMode ? Colors.white70 : Colors.black87,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 8),

            // Review section - only visible to buyers (not the seller's own book)
            if (!isMyBook)
              Container(
                color: isDarkMode ? Colors.black : Colors.white,
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _hasReviewed ? 'Your Review' : 'Rate this Seller',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: isDarkMode ? Colors.white : Colors.black,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(5, (index) {
                        return IconButton(
                          icon: Icon(
                            index < _userRating ? Icons.star : Icons.star_border,
                            color: index < _userRating ? Colors.amber : Colors.grey,
                            size: 36,
                          ),
                          onPressed: _hasReviewed && !currentUser!.isAnonymous
                              ? null
                              : () {
                                  setState(() {
                                    _userRating = index + 1;
                                  });
                                },
                        );
                      }),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _reviewController,
                      maxLines: 3,
                      readOnly: _hasReviewed && !currentUser!.isAnonymous,
                      decoration: InputDecoration(
                        hintText: 'Write your review (optional)',
                        border: OutlineInputBorder(),
                        filled: true,
                        fillColor: isDarkMode ? Colors.grey[900] : Colors.grey[100],
                      ),
                    ),
                    const SizedBox(height: 16),
                    if (!_hasReviewed)
                      Center(
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                          ),
                          onPressed: _isSubmitting || _userRating == 0 || currentUser == null
                              ? null
                              : () => _submitReview(context),
                          child: _isSubmitting
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(color: Colors.white),
                                )
                              : const Text(
                                  'Submit Review',
                                  style: TextStyle(fontSize: 16, color: Colors.white),
                                ),
                        ),
                      ),
                    if (_hasReviewed)
                      Center(
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                          ),
                          onPressed: currentUser == null ? null : () => _editReview(context),
                          child: const Text(
                            'Edit Review',
                            style: TextStyle(fontSize: 16, color: Colors.white),
                          ),
                        ),
                      ),
                    if (currentUser == null)
                      Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Center(
                          child: Text(
                            'Sign in to leave a review',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              
            const SizedBox(height: 80),
          ],
        ),
      ),
      bottomNavigationBar: !isMyBook
          ? Container(
              decoration: BoxDecoration(
                color: isDarkMode ? Colors.black : Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 5,
                    offset: const Offset(0, -3),
                  ),
                ],
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: FutureBuilder<DocumentSnapshot>(
                future: _sellerFuture,
                builder: (context, snapshot) {
                  String sellerName = 'Unknown Seller';
                  
                  if (snapshot.hasData && snapshot.data!.exists) {
                    final userData = snapshot.data!.data() as Map<String, dynamic>?;
                    if (userData != null) {
                      sellerName = "${userData['first_name'] ?? ''} ${userData['last_name'] ?? ''}".trim();
                    }
                  }
                  
                  return ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    onPressed: _isContactingSellerLoading
                        ? null
                        : () => _contactSeller(context, sellerName),
                    child: _isContactingSellerLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(color: Colors.white),
                          )
                        : const Text(
                            'Contact Seller',
                            style: TextStyle(fontSize: 18, color: Colors.white),
                          ),
                  );
                },
              ),
            )
          : null,
    );
  }

  Widget _buildRatingStars(double rating, {double size = 24}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (index) {
        if (index < rating.floor()) {
          // Full star
          return Icon(Icons.star, color: Colors.amber, size: size);
        } else if (index == rating.floor() && rating % 1 > 0) {
          // Half star
          return Icon(Icons.star_half, color: Colors.amber, size: size);
        } else {
          // Empty star
          return Icon(Icons.star_border, color: Colors.amber, size: size);
        }
      }),
    );
  }

  Future<void> _submitReview(BuildContext context) async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    setState(() {
      _isSubmitting = true;
    });

    try {
      // Get current user info
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser.uid)
          .get();
      
      final userName = userDoc.exists 
          ? "${userDoc.data()?['first_name'] ?? ''} ${userDoc.data()?['last_name'] ?? ''}".trim()
          : "Anonymous User";
      
      final userAvatar = userDoc.data()?['avatar_url'] ?? '';

      // Save the review to seller's reviews subcollection
      await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.book['userId'])
          .collection('reviews')
          .doc(currentUser.uid)
          .set({
            'userId': currentUser.uid,
            'rating': _userRating,
            'comment': _reviewController.text.trim(),
            'userName': userName,
            'userAvatar': userAvatar,
            'bookId': widget.bookId,
            'bookTitle': widget.book['title'] ?? 'Unknown Book',
            'createdAt': FieldValue.serverTimestamp(),
          });

      // Update seller's average rating
      final sellerReviewsRef = FirebaseFirestore.instance
          .collection('users')
          .doc(widget.book['userId'])
          .collection('reviews');
      
      final reviewsSnapshot = await sellerReviewsRef.get();
      final reviews = reviewsSnapshot.docs;
      
      double totalRating = 0;
      for (var doc in reviews) {
        totalRating += doc.data()['rating'] ?? 0;
      }
      
      final newAverageRating = reviews.isEmpty ? 0 : totalRating / reviews.length;
      
      // Update the seller's user document with new average rating
      await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.book['userId'])
          .update({
            'average_rating': newAverageRating,
            'review_count': reviews.length,
          });

      if (mounted) {
        setState(() {
          _hasReviewed = true;
          _isSubmitting = false;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Thank you for your review!')),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error submitting review: $e')),
        );
      }
    }
  }

  Future<void> _editReview(BuildContext context) async {
    setState(() {
      _hasReviewed = false;
    });
  }

  void _showOptionsMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: const Text('Delete Book'),
              onTap: () {
                Navigator.pop(context); // Close the bottom sheet
                _confirmAndDeleteBook(context);
              },
            ),
          ],
        ),
      ),
    );
  }
  
  // Fixed method that prevents using context after async gap
  void _confirmAndDeleteBook(BuildContext context) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Deletion'),
        content: const Text('Are you sure you want to delete this book?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false), 
            child: const Text('Cancel')
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true), 
            child: const Text('Delete')
          ),
        ],
      ),
    );

    // Store context references before any async operations
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    if (shouldDelete == true) {
      setState(() {
        _isDeleting = true; // Show loading state
      });
      
      try {
        // Delete the book document from Firestore
        await FirebaseFirestore.instance
            .collection('books')
            .doc(widget.bookId)
            .delete();
        
        // Check if widget is still mounted before updating state
        if (mounted) {
          setState(() {
            _isDeleting = false;
          });
        }
        
        // Show success message using stored scaffoldMessenger reference
        scaffoldMessenger.showSnackBar(
          const SnackBar(content: Text('Book deleted successfully')),
        );
        
        // Navigate back using stored navigator reference
        navigator.pop();
      } catch (e) {
        // Only update state if still mounted
        if (mounted) {
          setState(() {
            _isDeleting = false;
          });
          
          // Show error using stored scaffoldMessenger
          scaffoldMessenger.showSnackBar(
            SnackBar(content: Text('Error deleting book: $e')),
          );
        }
      }
    }
  }
}

String _formatDate(Timestamp timestamp) {
  if (timestamp == null) return 'Date not available';
  
  final date = timestamp.toDate();
  final now = DateTime.now();
  final difference = now.difference(date);
  
  if (difference.inDays == 0) {
    return 'Today';
  } else if (difference.inDays == 1) {
    return 'Yesterday';
  } else if (difference.inDays < 7) {
    return '${difference.inDays} days ago';
  } else {
    return '${date.day}/${date.month}/${date.year}';
  }
}