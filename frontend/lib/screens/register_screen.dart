import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:chat_app/services/api_service.dart';
import 'package:chat_app/services/storage_service.dart';
import 'package:chat_app/services/socket_service.dart';
import 'package:chat_app/services/locale_service.dart';
import 'package:chat_app/l10n/app_localizations.dart';
import 'package:intl/intl.dart';

class RegisterScreen extends StatefulWidget {
  final SocketService socketService;
  const RegisterScreen({Key? key, required this.socketService})
      : super(key: key);

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _birthDateController = TextEditingController();
  String? _birthDateValue;
  String? _selectedGender;
  File? _selectedImage;
  bool _isLoading = false;
  String? _errorMessage;

  final ImagePicker _imagePicker = ImagePicker();

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _birthDateController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      final pickedFile = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
      );

      if (pickedFile != null) {
        setState(() {
          _selectedImage = File(pickedFile.path);
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error picking image: $e')),
      );
    }
  }

  Future<void> _pickDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime(2000),
      firstDate: DateTime(1950),
      lastDate: DateTime.now(),
    );

    if (picked != null) {
      final locale = Localizations.localeOf(context).toString();
      final displayFormat = DateFormat.yMd(locale);
      final storageFormat = DateFormat('yyyy-MM-dd');
      setState(() {
        _birthDateValue = storageFormat.format(picked);
        _birthDateController.text = displayFormat.format(picked);
      });
    }
  }

  Future<void> _handleRegister() async {
    final loc = AppLocalizations.of(context);
    if (_usernameController.text.isEmpty ||
        _emailController.text.isEmpty ||
        _passwordController.text.isEmpty) {
      setState(() {
        _errorMessage = loc.fillRequiredFields;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final user = await ApiService.registerUser(
        username: _usernameController.text,
        email: _emailController.text,
        password: _passwordController.text,
        birthDate: _birthDateValue,
        gender: _selectedGender,
        avatarPath: _selectedImage?.path,
        language: LocaleService.tagFromLocale(Localizations.localeOf(context)),
      );

      await StorageService.saveUser(user);
      LocaleService.setLocaleFromTag(user.language);
      widget.socketService.connect();
      widget.socketService.joinUser(user.id);

      if (mounted) {
        Navigator.of(context).pushReplacementNamed('/home');
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceAll('Exception: ', '');
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
        title: Text(loc.createAccount),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 20),
            Center(
              child: GestureDetector(
                onTap: _isLoading ? null : _pickImage,
                child: Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Theme.of(context).primaryColor.withOpacity(0.2),
                    border: Border.all(
                      color: Theme.of(context).primaryColor,
                      width: 2,
                    ),
                  ),
                  child: _selectedImage != null
                      ? ClipOval(
                          child: Image.file(
                            _selectedImage!,
                            fit: BoxFit.cover,
                          ),
                        )
                      : Icon(
                          Icons.camera_alt,
                          size: 50,
                          color: Theme.of(context).primaryColor,
                        ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              loc.tapToAddAvatar,
              style: Theme.of(context).textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            TextField(
              controller: _usernameController,
              decoration: InputDecoration(
                labelText: loc.username,
                prefixIcon: const Icon(Icons.person),
              ),
              enabled: !_isLoading,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _emailController,
              decoration: InputDecoration(
                labelText: loc.email,
                prefixIcon: const Icon(Icons.email),
              ),
              keyboardType: TextInputType.emailAddress,
              enabled: !_isLoading,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _passwordController,
              decoration: InputDecoration(
                labelText: loc.password,
                prefixIcon: const Icon(Icons.lock),
              ),
              obscureText: true,
              enabled: !_isLoading,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _birthDateController,
              decoration: InputDecoration(
                labelText: loc.birthDateOptional,
                prefixIcon: const Icon(Icons.calendar_today),
              ),
              readOnly: true,
              onTap: _isLoading ? null : _pickDate,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _selectedGender,
              decoration: InputDecoration(
                labelText: loc.genderOptional,
                prefixIcon: const Icon(Icons.wc),
              ),
              items: [
                DropdownMenuItem(value: 'Male', child: Text(loc.genderMale)),
                DropdownMenuItem(
                    value: 'Female', child: Text(loc.genderFemale)),
                DropdownMenuItem(value: 'Other', child: Text(loc.genderOther)),
              ],
              onChanged: _isLoading
                  ? null
                  : (value) {
                      setState(() {
                        _selectedGender = value;
                      });
                    },
            ),
            const SizedBox(height: 24),
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
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _isLoading ? null : _handleRegister,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                        ),
                      )
                    : Text(loc.createAccountButton),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('${loc.alreadyHaveAccount} '),
                TextButton(
                  onPressed: _isLoading
                      ? null
                      : () {
                          Navigator.of(context).pop();
                        },
                  child: Text(loc.signIn),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
