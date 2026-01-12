import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async';

class MessagesScreen extends StatefulWidget {
  const MessagesScreen({super.key});

  @override
  State<MessagesScreen> createState() => _MessagesScreenState();
}

class _MessagesScreenState extends State<MessagesScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final user = FirebaseAuth.instance.currentUser;
  Map<String, Timestamp> lastReadChats = {};
  String? userRole;
  StreamSubscription? _userSubscription;
  List<DocumentSnapshot> _filteredUsers = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _userSubscription = _firestore.collection('users').doc(user!.uid).snapshots().listen((doc) {
      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        final lastRead = data['lastReadChats'] as Map<String, dynamic>? ?? {};
        setState(() {
          lastReadChats = lastRead.map((k, v) => MapEntry(k, v as Timestamp));
          userRole = data['role'] ?? 'rider';
        });
        _loadFilteredUsers();
      }
    });
  }

  Future<void> _loadFilteredUsers() async {
    if (userRole == null) return;
    
    setState(() {
      _isLoading = true;
    });

    try {
      List<String> userIds = [];
      
      if (userRole == 'driver') {
        // Get rides where current user is the driver
        final ridesQuery = await _firestore
            .collection('rides')
            .where('driverId', isEqualTo: user!.uid)
            .get();
        
        // Extract all booked rider IDs from these rides
        for (final rideDoc in ridesQuery.docs) {
          final rideData = rideDoc.data() as Map<String, dynamic>;
          final bookedRiders = List<String>.from(rideData['bookedRiders'] ?? []);
          userIds.addAll(bookedRiders);
        }
      } else {
        // Get rides where current user is a booked rider
        final ridesQuery = await _firestore
            .collection('rides')
            .where('bookedRiders', arrayContains: user!.uid)
            .get();
        
        // Extract driver IDs from these rides
        for (final rideDoc in ridesQuery.docs) {
          final rideData = rideDoc.data() as Map<String, dynamic>;
          final driverId = rideData['driverId'] as String?;
          if (driverId != null && driverId.isNotEmpty) {
            userIds.add(driverId);
          }
        }
      }

      // Remove duplicates and current user ID
      userIds = userIds.toSet().where((id) => id != user!.uid).toList();
      
      // Fetch user documents for the extracted IDs
      List<DocumentSnapshot> userDocs = [];
      for (final userId in userIds) {
        try {
          final userDoc = await _firestore.collection('users').doc(userId).get();
          if (userDoc.exists) {
            userDocs.add(userDoc);
          }
        } catch (e) {
          print('Error fetching user $userId: $e');
        }
      }
      
      setState(() {
        _filteredUsers = userDocs;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading filtered users: $e');
      setState(() {
        _filteredUsers = [];
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _userSubscription?.cancel();
    super.dispose();
  }

  Future<int> _getUnreadCount(String chatId, Timestamp? lastRead) async {
    if (lastRead == null) {
      // If never read, count all messages from others
      final query = _firestore.collection('messages').doc(chatId).collection('chats').where('senderId', isNotEqualTo: user!.uid);
      final snapshot = await query.get();
      return snapshot.docs.length;
    } else {
      final query = _firestore.collection('messages').doc(chatId).collection('chats').where('senderId', isNotEqualTo: user!.uid).where('timestamp', isGreaterThan: lastRead);
      final snapshot = await query.get();
      return snapshot.docs.length;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (user == null) {
      return const Scaffold(
        body: Center(child: Text('Please login to view messages')),
      );
    }

    if (userRole == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Messages'),
      ),
      body: Container(
        color: Theme.of(context).colorScheme.surface,
        child: _isLoading 
          ? const Center(child: CircularProgressIndicator())
          : _filteredUsers.isEmpty
            ? Center(
                child: Text(
                  userRole == 'driver' 
                    ? 'No riders have booked your rides yet'
                    : 'No drivers found for your booked rides',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontSize: 16),
                ),
              )
            : ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _filteredUsers.length,
                itemBuilder: (context, index) {
                  final userDoc = _filteredUsers[index];
                  final userData = userDoc.data() as Map<String, dynamic>;
                  final userName = userData['name'] ?? 'Unknown User';
                  final userRole = userData['role'] ?? 'user';
                  final ids = [user!.uid, userDoc.id]..sort();
                  final chatId = ids.join('_');

                  return FutureBuilder<int>(
                    key: ValueKey('${chatId}_${lastReadChats[chatId]?.millisecondsSinceEpoch}'),
                    future: _getUnreadCount(chatId, lastReadChats[chatId]),
                    builder: (context, snapshot) {
                      final unreadCount = snapshot.data ?? 0;
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        color: Theme.of(context).colorScheme.surface.withOpacity(0.9),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: Theme.of(context).colorScheme.secondaryContainer,
                            child: Icon(
                              userRole == 'driver' ? Icons.directions_car : Icons.person,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ),
                          title: Text(
                            userName,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                          ),
                          subtitle: Text(
                            userRole == 'driver' ? 'Driver' : 'Rider',
                            style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (unreadCount > 0)
                                Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: const BoxDecoration(
                                    color: Colors.red,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Text(
                                    unreadCount.toString(),
                                    style: const TextStyle(color: Colors.white, fontSize: 12),
                                  ),
                                ),
                              Icon(
                                Icons.chat,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                            ],
                          ),
                          onTap: () {
                            Navigator.pushNamed(
                              context,
                              '/chat',
                              arguments: {
                                'otherUserId': userDoc.id,
                                'otherUserName': userName,
                              },
                            );
                          },
                        ),
                      );
                    },
                  );
                },
              ),
      ),
    );
  }
}