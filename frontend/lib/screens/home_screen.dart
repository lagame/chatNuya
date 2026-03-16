import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:chat_app/models/user.dart';
import 'package:chat_app/services/api_service.dart';
import 'package:chat_app/services/storage_service.dart';
import 'package:chat_app/services/socket_service.dart';
import 'package:chat_app/screens/add_contact_screen.dart';
import 'package:chat_app/screens/settings_screen.dart';
import 'package:chat_app/l10n/app_localizations.dart';

class HomeScreen extends StatefulWidget {
  final SocketService socketService;
  const HomeScreen({Key? key, required this.socketService}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  User? _currentUser;
  List<User> _contacts = [];
  List<int> _onlineUsers = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initialize();
    _setupSocketListeners();
  }

  Future<void> _initialize() async {
    await _loadCurrentUser();
    await _loadContacts();
  }

  Future<void> _loadCurrentUser() async {
    final user = await StorageService.getUser();
    setState(() {
      _currentUser = user;
    });
  }

  Future<void> _loadContacts() async {
    if (_currentUser == null) {
      setState(() {
        _isLoading = false;
      });
      return;
    }
    try {
      final contacts = await ApiService.getContacts(_currentUser!.id);
      setState(() {
        _contacts = contacts;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        final loc = AppLocalizations.of(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${loc.errorLoadingUsers}: $e')),
        );
      }
    }
  }

  void _setupSocketListeners() {
    widget.socketService.onOnlineUsersChanged = (onlineUserIds) {
      setState(() {
        _onlineUsers = onlineUserIds;
      });
    };
  }

  bool _isUserOnline(int userId) {
    return _onlineUsers.contains(userId);
  }

  Future<void> _handleLogout() async {
    await StorageService.clearAll();
    widget.socketService.disconnect();
    if (mounted) {
      Navigator.of(context).pushReplacementNamed('/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(loc.appTitle),
        elevation: 0,
        actions: [
          IconButton(
            tooltip: loc.addContact,
            onPressed: _currentUser == null
                ? null
                : () async {
                    final added = await Navigator.of(context).push<bool>(
                      MaterialPageRoute(
                        builder: (context) =>
                            AddContactScreen(userId: _currentUser!.id),
                      ),
                    );
                    if (added == true) {
                      _loadContacts();
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(loc.contactAdded)),
                        );
                      }
                    }
                  },
            icon: const Icon(Icons.person_add_alt_1),
          ),
          IconButton(
            tooltip: loc.settings,
            onPressed: _currentUser == null
                ? null
                : () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) =>
                            SettingsScreen(currentUser: _currentUser!),
                      ),
                    );
                  },
            icon: const Icon(Icons.settings),
          ),
          PopupMenuButton(
            itemBuilder: (context) => [
              PopupMenuItem(
                child: Text(loc.logout),
                onTap: _handleLogout,
              ),
            ],
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Current user profile
                if (_currentUser != null)
                  Container(
                    padding: const EdgeInsets.all(16),
                    color: Theme.of(context).cardColor,
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 30,
                          backgroundColor: Theme.of(context).primaryColor,
                          child: _currentUser!.avatarUrl != null &&
                                  _currentUser!.avatarUrl!.isNotEmpty
                              ? ClipOval(
                                  child: CachedNetworkImage(
                                    imageUrl: ApiService.getAvatarUrl(
                                        _currentUser!.avatarUrl),
                                    fit: BoxFit.cover,
                                    width: 60,
                                    height: 60,
                                    placeholder: (context, url) =>
                                        const CircularProgressIndicator(),
                                    errorWidget: (context, url, error) => Icon(
                                      Icons.person,
                                      size: 30,
                                      color: Theme.of(context)
                                          .scaffoldBackgroundColor,
                                    ),
                                  ),
                                )
                              : Icon(
                                  Icons.person,
                                  size: 30,
                                  color:
                                      Theme.of(context).scaffoldBackgroundColor,
                                ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _currentUser!.username,
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                              Text(
                                _currentUser!.email,
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                const Divider(height: 1),
                // Contacts list
                Expanded(
                  child: _contacts.isEmpty
                      ? Center(
                          child: Text(
                            loc.noContacts,
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        )
                      : RefreshIndicator(
                          onRefresh: _loadContacts,
                          child: ListView.builder(
                            itemCount: _contacts.length,
                            itemBuilder: (context, index) {
                              final user = _contacts[index];
                              final isOnline = _isUserOnline(user.id);

                              return ListTile(
                                leading: Stack(
                                  children: [
                                    CircleAvatar(
                                      radius: 24,
                                      backgroundColor:
                                          Theme.of(context).primaryColor,
                                      child: user.avatarUrl != null &&
                                              user.avatarUrl!.isNotEmpty
                                          ? ClipOval(
                                              child: CachedNetworkImage(
                                                imageUrl:
                                                    ApiService.getAvatarUrl(
                                                        user.avatarUrl),
                                                fit: BoxFit.cover,
                                                width: 48,
                                                height: 48,
                                                placeholder: (context, url) =>
                                                    const CircularProgressIndicator(),
                                                errorWidget:
                                                    (context, url, error) =>
                                                        Icon(
                                                  Icons.person,
                                                  size: 24,
                                                  color: Theme.of(context)
                                                      .scaffoldBackgroundColor,
                                                ),
                                              ),
                                            )
                                          : Icon(
                                              Icons.person,
                                              size: 24,
                                              color: Theme.of(context)
                                                  .scaffoldBackgroundColor,
                                            ),
                                    ),
                                    if (isOnline)
                                      Positioned(
                                        bottom: 0,
                                        right: 0,
                                        child: Container(
                                          width: 16,
                                          height: 16,
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            color: Colors.green,
                                            border: Border.all(
                                              color: Theme.of(context)
                                                  .scaffoldBackgroundColor,
                                              width: 2,
                                            ),
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                                title: Text(user.username),
                                subtitle: Text(
                                  isOnline ? loc.online : loc.offline,
                                  style: TextStyle(
                                    color:
                                        isOnline ? Colors.green : Colors.grey,
                                  ),
                                ),
                                onTap: () {
                                  Navigator.of(context).pushNamed(
                                    '/chat',
                                    arguments: user,
                                  );
                                },
                              );
                            },
                          ),
                        ),
                )
              ],
            ),
    );
  }
}
