import 'package:flutter/material.dart';
import 'package:chat_app/services/socket_service.dart';
import 'package:chat_app/services/storage_service.dart';
import 'package:chat_app/utils/theme.dart';
import 'package:chat_app/l10n/app_localizations.dart';
import 'package:chat_app/services/locale_service.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:chat_app/screens/login_screen.dart';
import 'package:chat_app/screens/register_screen.dart';
import 'package:chat_app/screens/home_screen.dart';
import 'package:chat_app/screens/chat_screen.dart';
import 'package:chat_app/models/user.dart';

void main() {
  runApp(const ChatApp());
}

class ChatApp extends StatefulWidget {
  const ChatApp({Key? key}) : super(key: key);

  @override
  State<ChatApp> createState() => _ChatAppState();
}

class _ChatAppState extends State<ChatApp> {
  late SocketService _socketService;
  User? _currentUser;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _socketService = SocketService();
    _checkAuthStatus();
  }

  Future<void> _checkAuthStatus() async {
    final user = await StorageService.getUser();
    setState(() {
      _currentUser = user;
      _isLoading = false;
    });

    LocaleService.setLocaleFromTag(user?.language);

    if (user != null) {
      _socketService.connect();
      _socketService.joinUser(user.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Locale?>(
      valueListenable: LocaleService.localeNotifier,
      builder: (context, locale, _) {
        return MaterialApp(
          title: 'NUYA',
          theme: AppTheme.getDarkTheme(),
          locale: locale,
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          home: _isLoading
              ? const Scaffold(
                  body: Center(
                    child: CircularProgressIndicator(),
                  ),
                )
              : _currentUser != null
                  ? HomeScreen(socketService: _socketService)
                  : LoginScreen(socketService: _socketService),
          routes: {
            '/login': (context) => LoginScreen(socketService: _socketService),
            '/register': (context) =>
                RegisterScreen(socketService: _socketService),
            '/home': (context) => HomeScreen(socketService: _socketService),
            '/chat': (context) {
              final user = ModalRoute.of(context)?.settings.arguments as User;
              return ChatScreen(
                otherUser: user,
                socketService: _socketService,
              );
            },
          },
        );
      },
    );
  }
}
