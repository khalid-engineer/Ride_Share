import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';
import 'package:record/record.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';

class Message {
  final String id;
  final String text;
  final String senderId;
  final DateTime timestamp;
  final bool? deletedForAll;
  final List<String>? deletedBy;
  final String? replyTo;
  final String type; // 'text' or 'voice'
  final String? audioUrl;

  Message({
    required this.id,
    required this.text,
    required this.senderId,
    required this.timestamp,
    this.deletedForAll,
    this.deletedBy,
    this.replyTo,
    this.type = 'text',
    this.audioUrl,
  });
}

class ChatScreen extends StatefulWidget {
  final String otherUserId;
  final String otherUserName;

  const ChatScreen({
    super.key,
    required this.otherUserId,
    required this.otherUserName,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final AudioRecorder _audioRecorder = AudioRecorder();
  final AudioPlayer _audioPlayer = AudioPlayer();
  Message? replyingTo;
  List<Message> allMessages = [];
  bool _isRecording = false;
  String? _recordingPath;
  bool _showEmojiPicker = false;

  String get chatId {
    final user = FirebaseAuth.instance.currentUser!;
    final ids = [user.uid, widget.otherUserId]..sort();
    return ids.join('_');
  }

  @override
  void initState() {
    super.initState();
    _markAsRead();
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _markAsRead() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    try {
      await _firestore.collection('users').doc(user.uid).update({
        'lastReadChats.${chatId}': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      // Handle error if needed
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.otherUserName),
      ),
      body: Column(
        children: [
          Expanded(
            child: Container(
              color: Theme.of(context).colorScheme.surface,
              child: Column(
                children: [
                  // Messages area
                  Expanded(
                    child: Container(
                      margin: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surface.withOpacity(0.9),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        children: [
                          // Messages list
                          Expanded(
                            child: StreamBuilder<QuerySnapshot>(
                              stream: _firestore
                                  .collection('messages')
                                  .doc(chatId)
                                  .collection('chats')
                                  .orderBy('timestamp', descending: false)
                                  .snapshots(),
                              builder: (context, snapshot) {
                                if (snapshot.connectionState == ConnectionState.waiting) {
                                  return const Center(child: CircularProgressIndicator());
                                }

                                final docs = snapshot.data?.docs ?? [];
                                allMessages = docs.map((doc) {
                                  final data = doc.data() as Map<String, dynamic>;
                                  return Message(
                                    id: doc.id,
                                    text: data['text'] ?? '',
                                    senderId: data['senderId'] ?? '',
                                    timestamp: data['timestamp'] != null ? (data['timestamp'] as Timestamp).toDate() : DateTime.now(),
                                    deletedForAll: data['deletedForAll'],
                                    deletedBy: (data['deletedBy'] as List<dynamic>?)?.cast<String>(),
                                    replyTo: data['replyTo'],
                                    type: data['type'] ?? 'text',
                                    audioUrl: data['audioUrl'],
                                  );
                                }).toList();

                                final displayedMessages = allMessages.where((m) {
                                  final user = FirebaseAuth.instance.currentUser!;
                                  return !(m.deletedForAll == true || (m.deletedBy?.contains(user.uid) ?? false));
                                }).toList();

                                if (displayedMessages.isEmpty) {
                                  return const Center(
                                    child: Text(
                                      'No messages yet. Start the conversation!',
                                      style: TextStyle(color: Colors.grey),
                                    ),
                                  );
                                }

                                return ListView.builder(
                                  controller: _scrollController,
                                  padding: const EdgeInsets.all(16),
                                  itemCount: displayedMessages.length,
                                  itemBuilder: (context, index) {
                                    final message = displayedMessages[index];
                                    final isMe = message.senderId == user!.uid;

                                    return _buildMessage(message, isMe: isMe);
                                  },
                                );
                              },
                            ),
                          ),

                          // Message input
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              border: Border(
                                top: BorderSide(
                                  color: Colors.grey.shade300,
                                ),
                              ),
                            ),
                            child: Column(
                              children: [
                                if (replyingTo != null)
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    margin: const EdgeInsets.only(bottom: 8),
                                    decoration: BoxDecoration(
                                      color: Colors.grey.shade200,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            'Replying to: ${replyingTo!.text}',
                                            style: const TextStyle(fontSize: 12),
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        IconButton(
                                          icon: const Icon(Icons.close, size: 16),
                                          onPressed: () {
                                            setState(() {
                                              replyingTo = null;
                                            });
                                          },
                                        ),
                                      ],
                                    ),
                                  ),
                                Row(
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.emoji_emotions),
                                      onPressed: () {
                                        setState(() {
                                          _showEmojiPicker = !_showEmojiPicker;
                                        });
                                      },
                                    ),
                                    Expanded(
                                      child: TextField(
                                        controller: _messageController,
                                        decoration: InputDecoration(
                                          hintText: 'Type a message...',
                                          border: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(24),
                                          ),
                                          contentPadding: const EdgeInsets.symmetric(
                                            horizontal: 16,
                                            vertical: 12,
                                          ),
                                        ),
                                      ),
                                    ),
                                    IconButton(
                                      icon: Icon(_isRecording ? Icons.stop : Icons.mic),
                                      onPressed: _toggleRecording,
                                    ),
                                    FloatingActionButton(
                                      onPressed: _sendMessage,
                                      mini: true,
                                      child: const Icon(Icons.send),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (_showEmojiPicker)
            SizedBox(
              height: 250,
              child: EmojiPicker(
                onEmojiSelected: (category, emoji) {
                  _onEmojiSelected(emoji);
                },
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildMessage(Message message, {required bool isMe}) {
    final sender = isMe ? 'You' : widget.otherUserName;
    Message? repliedMessage;
    if (message.replyTo != null) {
      repliedMessage = allMessages.firstWhere(
        (m) => m.id == message.replyTo,
        orElse: () => Message(id: '', text: 'Message not found', senderId: '', timestamp: DateTime.now()),
      );
    }

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: GestureDetector(
        onLongPress: () => _showMessageOptions(message),
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 4),
          padding: const EdgeInsets.all(12),
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.7,
          ),
          decoration: BoxDecoration(
            color: isMe ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(16),
            border: isMe ? null : Border.all(color: Theme.of(context).colorScheme.outline),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (!isMe)
                Text(
                  sender,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              if (repliedMessage != null && repliedMessage.id.isNotEmpty)
                Container(
                  padding: const EdgeInsets.all(8),
                  margin: const EdgeInsets.only(bottom: 8),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    repliedMessage.text,
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              if (message.type == 'voice')
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.play_arrow, color: Colors.blue),
                      onPressed: () => _playAudio(message.audioUrl!),
                    ),
                    const Text('Voice message', style: TextStyle(fontSize: 12)),
                  ],
                )
              else
                Text(
                  message.text,
                  style: TextStyle(
                    color: isMe ? Theme.of(context).colorScheme.onPrimary : Theme.of(context).colorScheme.onSurface,
                  ),
                ),
              const SizedBox(height: 4),
              Text(
                '${message.timestamp.hour}:${message.timestamp.minute.toString().padLeft(2, '0')}',
                style: TextStyle(
                  fontSize: 10,
                  color: isMe ? Theme.of(context).colorScheme.onPrimary.withOpacity(0.7) : Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _sendMessage() async {
    final message = _messageController.text.trim();
    if (message.isEmpty) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final data = {
        'text': message,
        'senderId': user.uid,
        'timestamp': FieldValue.serverTimestamp(),
      };
      if (replyingTo != null) {
        data['replyTo'] = replyingTo!.id;
      }
      await _firestore
          .collection('messages')
          .doc(chatId)
          .collection('chats')
          .add(data);

      _messageController.clear();
      setState(() {
        replyingTo = null;
      });

      // Scroll to bottom
      Future.delayed(const Duration(milliseconds: 100), () {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to send message: $e')),
      );
    }
  }

  void _showMessageOptions(Message message) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.reply),
              title: const Text('Reply'),
              onTap: () {
                Navigator.pop(context);
                setState(() {
                  replyingTo = message;
                });
              },
            ),
            ListTile(
              leading: const Icon(Icons.forward),
              title: const Text('Forward'),
              onTap: () {
                Navigator.pop(context);
                // TODO: implement forward
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete),
              title: const Text('Delete'),
              onTap: () {
                Navigator.pop(context);
                _showDeleteOptions(message);
              },
            ),
          ],
        );
      },
    );
  }

  void _showDeleteOptions(Message message) {
    final user = FirebaseAuth.instance.currentUser!;
    final isSender = message.senderId == user.uid;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete Message'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: const Text('Delete for me'),
                onTap: () {
                  Navigator.pop(context);
                  _deleteForMe(message);
                },
              ),
              if (isSender)
                ListTile(
                  title: const Text('Delete for everyone'),
                  onTap: () {
                    Navigator.pop(context);
                    _deleteForEveryone(message);
                  },
                ),
            ],
          ),
        );
      },
    );
  }

  void _deleteForMe(Message message) async {
    final user = FirebaseAuth.instance.currentUser!;
    try {
      final docRef = _firestore.collection('messages').doc(chatId).collection('chats').doc(message.id);
      final doc = await docRef.get();
      final data = doc.data()!;
      final deletedBy = List<String>.from(data['deletedBy'] ?? []);
      if (!deletedBy.contains(user.uid)) {
        deletedBy.add(user.uid);
        await docRef.update({'deletedBy': deletedBy});
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to delete: $e')),
      );
    }
  }

  void _deleteForEveryone(Message message) async {
    try {
      await _firestore.collection('messages').doc(chatId).collection('chats').doc(message.id).update({'deletedForAll': true});
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to delete: $e')),
      );
    }
  }

  void _onEmojiSelected(Emoji emoji) {
    _messageController.text += emoji.emoji;
  }

  void _playAudio(String url) async {
    try {
      await _audioPlayer.play(UrlSource(url));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to play audio: $e')),
      );
    }
  }

  void _toggleRecording() async {
    if (_isRecording) {
      final path = await _audioRecorder.stop();
      setState(() {
        _isRecording = false;
        _recordingPath = path;
      });
      _sendVoiceMessage();
    } else {
      final directory = await getApplicationDocumentsDirectory();
      final path = '${directory.path}/audio_${DateTime.now().millisecondsSinceEpoch}.m4a';
      await _audioRecorder.start(const RecordConfig(), path: path);
      setState(() {
        _isRecording = true;
        _recordingPath = path;
      });
    }
  }

  void _sendVoiceMessage() async {
    if (_recordingPath == null) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final file = File(_recordingPath!);
      final ref = FirebaseStorage.instance.ref().child('audio/${DateTime.now().millisecondsSinceEpoch}.m4a');
      await ref.putFile(file);
      final url = await ref.getDownloadURL();

      final data = {
        'text': '',
        'senderId': user.uid,
        'timestamp': FieldValue.serverTimestamp(),
        'type': 'voice',
        'audioUrl': url,
      };
      if (replyingTo != null) {
        data['replyTo'] = replyingTo!.id;
      }
      await _firestore.collection('messages').doc(chatId).collection('chats').add(data);

      setState(() {
        _recordingPath = null;
        replyingTo = null;
      });

      // Scroll to bottom
      Future.delayed(const Duration(milliseconds: 100), () {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to send voice message: $e')),
      );
    }
  }
}