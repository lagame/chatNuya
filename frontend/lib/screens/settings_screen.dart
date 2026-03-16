import 'package:flutter/material.dart';
import 'package:chat_app/models/user.dart';
import 'package:chat_app/services/api_service.dart';
import 'package:chat_app/services/locale_service.dart';
import 'package:chat_app/services/storage_service.dart';
import 'package:chat_app/l10n/app_localizations.dart';

class SettingsScreen extends StatefulWidget {
  final User currentUser;
  const SettingsScreen({Key? key, required this.currentUser}) : super(key: key);

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  String? _selectedLanguage;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _selectedLanguage = widget.currentUser.language;
  }

  Future<void> _saveLanguage() async {
    final loc = AppLocalizations.of(context);
    if (_selectedLanguage == null || _selectedLanguage!.isEmpty) {
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final updatedUser = await ApiService.updateUserLanguage(
        userId: widget.currentUser.id,
        language: _selectedLanguage!,
      );
      await StorageService.saveUser(updatedUser);
      LocaleService.setLocaleFromTag(updatedUser.language);
      if (mounted) {
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(e.toString())));
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final languageOptions = [
      const _LanguageOption(tag: 'pt-BR', label: 'Português (Brasil)'),
      const _LanguageOption(tag: 'en', label: 'English'),
      const _LanguageOption(tag: 'es', label: 'Español'),
      const _LanguageOption(tag: 'fr', label: 'Français'),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(loc.settings),
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(loc.language, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _selectedLanguage ?? 'pt-BR',
              decoration: InputDecoration(
                labelText: loc.selectLanguage,
                prefixIcon: const Icon(Icons.language),
              ),
              items: languageOptions
                  .map((option) => DropdownMenuItem(
                        value: option.tag,
                        child: Text(option.label),
                      ))
                  .toList(),
              onChanged: _isSaving
                  ? null
                  : (value) {
                      setState(() {
                        _selectedLanguage = value;
                      });
                    },
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _isSaving ? null : _saveLanguage,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: _isSaving
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(loc.save),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LanguageOption {
  final String tag;
  final String label;
  const _LanguageOption({required this.tag, required this.label});
}
