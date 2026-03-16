import 'package:flutter/material.dart';
import 'package:chat_app/services/api_service.dart';
import 'package:chat_app/l10n/app_localizations.dart';

class AddContactScreen extends StatefulWidget {
  final int userId;
  const AddContactScreen({Key? key, required this.userId}) : super(key: key);

  @override
  State<AddContactScreen> createState() => _AddContactScreenState();
}

class _AddContactScreenState extends State<AddContactScreen> {
  final _queryController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _queryController.dispose();
    super.dispose();
  }

  Future<void> _handleAddContact() async {
    final loc = AppLocalizations.of(context);
    final query = _queryController.text.trim();
    if (query.isEmpty) {
      setState(() {
        _errorMessage = loc.invalidContact;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await ApiService.addContact(userId: widget.userId, query: query);
      if (mounted) {
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      final message = e.toString().replaceAll('Exception: ', '');
      final loc = AppLocalizations.of(context);
      String mapped;
      if (message.contains('User not found')) {
        mapped = loc.contactNotFound;
      } else if (message.contains('Contact already exists')) {
        mapped = loc.contactExists;
      } else if (message.contains('Invalid contact')) {
        mapped = loc.invalidContact;
      } else {
        mapped = message;
      }
      setState(() {
        _errorMessage = mapped;
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(loc.addContactTitle),
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _queryController,
              decoration: InputDecoration(
                labelText: loc.contactQueryHint,
                prefixIcon: const Icon(Icons.person_add),
              ),
              enabled: !_isLoading,
            ),
            const SizedBox(height: 16),
            if (_errorMessage != null)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _errorMessage!,
                  style: const TextStyle(color: Colors.red),
                ),
              ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _isLoading ? null : _handleAddContact,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(loc.addContactButton),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
