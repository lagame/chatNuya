import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:chat_app/models/user.dart';
import 'package:chat_app/models/message.dart';
import 'package:chat_app/services/api_service.dart';
import 'package:chat_app/services/socket_service.dart';
import 'package:chat_app/services/storage_service.dart';
import 'package:chat_app/l10n/app_localizations.dart';

class ChatScreen extends StatefulWidget {
  final User otherUser;
  final SocketService socketService;

  const ChatScreen({
    Key? key,
    required this.otherUser,
    required this.socketService,
  }) : super(key: key);

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();
  List<Message> _messages = [];
  User? _currentUser;
  bool _isLoading = true;
  Set<int> _typingUsers = {};

  @override
  void initState() {
    super.initState();
    _loadCurrentUser();
    _loadMessages();
    _setupSocketListeners();
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadCurrentUser() async {
    final user = await StorageService.getUser();
    setState(() {
      _currentUser = user;
    });
  }

  Future<void> _loadMessages() async {
    if (_currentUser == null) return;

    try {
      widget.socketService.getMessages(
        userId1: _currentUser!.id,
        userId2: widget.otherUser.id,
        callback: (messages) {
          setState(() {
            _messages = messages;
            _isLoading = false;
          });
          _scrollToBottom();
        },
      );
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _setupSocketListeners() {
    widget.socketService.onMessageReceived = (message) {
      if ((message.senderId == widget.otherUser.id &&
              message.receiverId == _currentUser?.id) ||
          (message.senderId == _currentUser?.id &&
              message.receiverId == widget.otherUser.id)) {
        setState(() {
          _messages.add(message);
        });
        _scrollToBottom();
      }
    };

    widget.socketService.onUserTyping = (userId) {
      if (userId == widget.otherUser.id) {
        setState(() {
          _typingUsers.add(userId);
        });
      }
    };

    widget.socketService.onUserStopTyping = (userId) {
      if (userId == widget.otherUser.id) {
        setState(() {
          _typingUsers.remove(userId);
        });
      }
    };
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

  void _sendMessage() {
    if (_messageController.text.isEmpty || _currentUser == null) return;

    final content = _messageController.text;
    _messageController.clear();

    widget.socketService.sendMessage(
      senderId: _currentUser!.id,
      receiverId: widget.otherUser.id,
      content: content,
    );

    widget.socketService.notifyStopTyping(
      senderId: _currentUser!.id,
      receiverId: widget.otherUser.id,
    );
  }

  void _onMessageChanged(String value) {
    if (value.isNotEmpty && _currentUser != null) {
      widget.socketService.notifyTyping(
        senderId: _currentUser!.id,
        receiverId: widget.otherUser.id,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            CircleAvatar(
              radius: 16,
              backgroundColor: Theme.of(context).primaryColor,
              child: widget.otherUser.avatarUrl != null &&
                      widget.otherUser.avatarUrl!.isNotEmpty
                  ? ClipOval(
                      child: CachedNetworkImage(
                        imageUrl:
                            ApiService.getAvatarUrl(widget.otherUser.avatarUrl),
                        fit: BoxFit.cover,
                        width: 32,
                        height: 32,
                        placeholder: (context, url) =>
                            const CircularProgressIndicator(),
                        errorWidget: (context, url, error) => Icon(
                          Icons.person,
                          size: 16,
                          color: Theme.of(context).scaffoldBackgroundColor,
                        ),
                      ),
                    )
                  : Icon(
                      Icons.person,
                      size: 16,
                      color: Theme.of(context).scaffoldBackgroundColor,
                    ),
            ),
            const SizedBox(width: 12),
            Text(widget.otherUser.username),
          ],
        ),
        elevation: 0,
      ),
      body: Column(
        children: [
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _messages.isEmpty
                    ? Center(
                        child: Text(
                          '${loc.noMessages} ${loc.startConversation}',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      )
                    : ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.all(16),
                        itemCount: _messages.length,
                        itemBuilder: (context, index) {
                          final message = _messages[index];
                          final isCurrentUser =
                              message.senderId == _currentUser?.id;

                          return Align(
                            alignment: isCurrentUser
                                ? Alignment.centerRight
                                : Alignment.centerLeft,
                            child: Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 10,
                              ),
                              decoration: BoxDecoration(
                                color: isCurrentUser
                                    ? Theme.of(context).primaryColor
                                    : Theme.of(context).cardColor,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    message.content,
                                    style: TextStyle(
                                      color: isCurrentUser
                                          ? Colors.white
                                          : Theme.of(context)
                                              .textTheme
                                              .bodyMedium
                                              ?.color,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${message.timestamp.hour}:${message.timestamp.minute.toString().padLeft(2, '0')}',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: isCurrentUser
                                          ? Colors.white70
                                          : Colors.grey,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
          ),
          if (_typingUsers.isNotEmpty)
            Padding(
              padding: const EdgeInsets.all(8),
              child: Text(
                loc.t('typing', params: {'name': widget.otherUser.username}),
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              border: Border(
                top: BorderSide(
                  color: Theme.of(context).dividerColor,
                ),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: InputDecoration(
                      hintText: loc.typeMessage,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                    onChanged: _onMessageChanged,
                    maxLines: null,
                  ),
                ),
                const SizedBox(width: 8),
                FloatingActionButton(
                  mini: true,
                  onPressed: _sendMessage,
                  child: const Icon(Icons.send),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
