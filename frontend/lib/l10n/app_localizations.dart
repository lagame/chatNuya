import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class AppLocalizations {
  final Locale locale;
  AppLocalizations(this.locale);

  static const supportedLocales = [
    Locale('pt', 'BR'),
    Locale('en'),
    Locale('es'),
    Locale('fr'),
  ];

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static String localeToTag(Locale locale) {
    if (locale.countryCode == null || locale.countryCode!.isEmpty) {
      return locale.languageCode;
    }
    return '${locale.languageCode}-${locale.countryCode}';
  }

  String _resolveLocaleTag() {
    final tag = localeToTag(locale);
    if (_localizedValues.containsKey(tag)) {
      return tag;
    }
    if (_localizedValues.containsKey(locale.languageCode)) {
      return locale.languageCode;
    }
    return 'en';
  }

  String t(String key, {Map<String, String>? params}) {
    final tag = _resolveLocaleTag();
    final value =
        _localizedValues[tag]?[key] ?? _localizedValues['en']?[key] ?? key;
    if (params == null || params.isEmpty) {
      return value;
    }
    var result = value;
    params.forEach((paramKey, paramValue) {
      result = result.replaceAll('{$paramKey}', paramValue);
    });
    return result;
  }

  String get appTitle => t('app_title');
  String get welcomeBack => t('welcome_back');
  String get signInToAccount => t('sign_in_to_account');
  String get loginIdentifier => t('login_identifier');
  String get email => t('email');
  String get password => t('password');
  String get signIn => t('sign_in');
  String get signUp => t('sign_up');
  String get dontHaveAccount => t('dont_have_account');
  String get alreadyHaveAccount => t('already_have_account');
  String get createAccount => t('create_account');
  String get tapToAddAvatar => t('tap_to_add_avatar');
  String get username => t('username');
  String get birthDateOptional => t('birth_date_optional');
  String get genderOptional => t('gender_optional');
  String get genderMale => t('gender_male');
  String get genderFemale => t('gender_female');
  String get genderOther => t('gender_other');
  String get createAccountButton => t('create_account_button');
  String get logout => t('logout');
  String get addContact => t('add_contact');
  String get settings => t('settings');
  String get noContacts => t('no_contacts');
  String get online => t('online');
  String get offline => t('offline');
  String get noMessages => t('no_messages');
  String get startConversation => t('start_conversation');
  String get typing => t('typing');
  String get typeMessage => t('type_message');
  String get addContactTitle => t('add_contact_title');
  String get contactQueryHint => t('contact_query_hint');
  String get addContactButton => t('add_contact_button');
  String get contactAdded => t('contact_added');
  String get contactNotFound => t('contact_not_found');
  String get contactExists => t('contact_exists');
  String get invalidContact => t('invalid_contact');
  String get language => t('language');
  String get save => t('save');
  String get cancel => t('cancel');
  String get selectLanguage => t('select_language');
  String get fillRequiredFields => t('fill_required_fields');
  String get emailPasswordRequired => t('email_password_required');
  String get errorLoadingUsers => t('error_loading_users');
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) {
    return AppLocalizations.supportedLocales.any(
      (supported) =>
          supported.languageCode == locale.languageCode &&
          (supported.countryCode == null ||
              supported.countryCode == locale.countryCode),
    );
  }

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(AppLocalizations(locale));
  }

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

const Map<String, Map<String, String>> _localizedValues = {
  'en': {
    'app_title': 'NUYA',
    'welcome_back': 'Welcome Back',
    'sign_in_to_account': 'Sign in to your account',
    'login_identifier': 'Email or username',
    'email': 'Email',
    'password': 'Password',
    'sign_in': 'Sign In',
    'sign_up': 'Sign Up',
    'dont_have_account': "Don't have an account?",
    'already_have_account': 'Already have an account?',
    'create_account': 'Create Account',
    'tap_to_add_avatar': 'Tap to add avatar',
    'username': 'Username',
    'birth_date_optional': 'Birth Date (optional)',
    'gender_optional': 'Gender (optional)',
    'gender_male': 'Male',
    'gender_female': 'Female',
    'gender_other': 'Other',
    'create_account_button': 'Create Account',
    'logout': 'Logout',
    'add_contact': 'Add Contact',
    'settings': 'Settings',
    'no_contacts': 'No contacts available',
    'online': 'Online',
    'offline': 'Offline',
    'no_messages': 'No messages yet.',
    'start_conversation': 'Start the conversation!',
    'typing': '{name} is typing...',
    'type_message': 'Type a message...',
    'add_contact_title': 'Add Contact',
    'contact_query_hint': 'Nickname or email',
    'add_contact_button': 'Add',
    'contact_added': 'Contact added',
    'contact_not_found': 'User not found',
    'contact_exists': 'Contact already exists',
    'invalid_contact': 'Invalid contact',
    'language': 'Language',
    'save': 'Save',
    'cancel': 'Cancel',
    'select_language': 'Select language',
    'fill_required_fields': 'Please fill in all required fields',
    'email_password_required': 'Email and password are required',
    'error_loading_users': 'Error loading users',
  },
  'pt-BR': {
    'app_title': 'NUYA',
    'welcome_back': 'Bem-vindo de volta',
    'sign_in_to_account': 'Entre na sua conta',
    'login_identifier': 'Email ou usuário',
    'email': 'Email',
    'password': 'Senha',
    'sign_in': 'Entrar',
    'sign_up': 'Cadastrar',
    'dont_have_account': 'Não tem conta?',
    'already_have_account': 'Já tem uma conta?',
    'create_account': 'Criar conta',
    'tap_to_add_avatar': 'Toque para adicionar avatar',
    'username': 'Usuário',
    'birth_date_optional': 'Data de nascimento (opcional)',
    'gender_optional': 'Gênero (opcional)',
    'gender_male': 'Masculino',
    'gender_female': 'Feminino',
    'gender_other': 'Outro',
    'create_account_button': 'Criar conta',
    'logout': 'Sair',
    'add_contact': 'Adicionar contato',
    'settings': 'Preferências',
    'no_contacts': 'Nenhum contato disponível',
    'online': 'Online',
    'offline': 'Offline',
    'no_messages': 'Sem mensagens ainda.',
    'start_conversation': 'Inicie a conversa!',
    'typing': '{name} está digitando...',
    'type_message': 'Digite uma mensagem...',
    'add_contact_title': 'Adicionar contato',
    'contact_query_hint': 'Nickname ou email',
    'add_contact_button': 'Adicionar',
    'contact_added': 'Contato adicionado',
    'contact_not_found': 'Usuário não encontrado',
    'contact_exists': 'Contato ja existe',
    'invalid_contact': 'Contato inválido',
    'language': 'Idioma',
    'save': 'Salvar',
    'cancel': 'Cancelar',
    'select_language': 'Selecionar idioma',
    'fill_required_fields': 'Preencha os campos obrigatórios',
    'email_password_required': 'Email e senha são obrigatórios',
    'error_loading_users': 'Erro ao carregar usuários',
  },
  'es': {
    'app_title': 'NUYA',
    'welcome_back': 'Bienvenido de nuevo',
    'sign_in_to_account': 'Inicia sesion en tu cuenta',
    'email': 'Correo',
    'password': 'Contrasena',
    'sign_in': 'Iniciar sesion',
    'sign_up': 'Registrarse',
    'dont_have_account': 'No tienes cuenta?',
    'already_have_account': 'Ya tienes una cuenta?',
    'create_account': 'Crear cuenta',
    'tap_to_add_avatar': 'Toca para agregar avatar',
    'username': 'Usuario',
    'birth_date_optional': 'Fecha de nacimiento (opcional)',
    'gender_optional': 'Genero (opcional)',
    'gender_male': 'Masculino',
    'gender_female': 'Femenino',
    'gender_other': 'Otro',
    'create_account_button': 'Crear cuenta',
    'logout': 'Salir',
    'add_contact': 'Agregar contacto',
    'settings': 'Preferencias',
    'no_contacts': 'No hay contactos disponibles',
    'online': 'En linea',
    'offline': 'Desconectado',
    'no_messages': 'Sin mensajes aun.',
    'start_conversation': 'Inicia la conversacion!',
    'typing': '{name} esta escribiendo...',
    'type_message': 'Escribe un mensaje...',
    'add_contact_title': 'Agregar contacto',
    'contact_query_hint': 'Nickname o correo',
    'add_contact_button': 'Agregar',
    'contact_added': 'Contacto agregado',
    'contact_not_found': 'Usuario no encontrado',
    'contact_exists': 'El contacto ya existe',
    'invalid_contact': 'Contacto invalido',
    'language': 'Idioma',
    'save': 'Guardar',
    'cancel': 'Cancelar',
    'select_language': 'Seleccionar idioma',
    'fill_required_fields': 'Completa los campos obligatorios',
    'email_password_required': 'Correo y contrasena son obligatorios',
    'error_loading_users': 'Error al cargar usuarios',
  },
  'fr': {
    'app_title': 'NUYA',
    'welcome_back': 'Bon retour',
    'sign_in_to_account': 'Connectez-vous a votre compte',
    'email': 'Email',
    'password': 'Mot de passe',
    'sign_in': 'Se connecter',
    'sign_up': 'S\'inscrire',
    'dont_have_account': 'Vous n\'avez pas de compte?',
    'already_have_account': 'Vous avez deja un compte?',
    'create_account': 'Creer un compte',
    'tap_to_add_avatar': 'Touchez pour ajouter un avatar',
    'username': 'Nom d\'utilisateur',
    'birth_date_optional': 'Date de naissance (optionnel)',
    'gender_optional': 'Genre (optionnel)',
    'gender_male': 'Homme',
    'gender_female': 'Femme',
    'gender_other': 'Autre',
    'create_account_button': 'Creer un compte',
    'logout': 'Se deconnecter',
    'add_contact': 'Ajouter un contact',
    'settings': 'Preferences',
    'no_contacts': 'Aucun contact disponible',
    'online': 'En ligne',
    'offline': 'Hors ligne',
    'no_messages': 'Aucun message pour le moment.',
    'start_conversation': 'Commencez la conversation!',
    'typing': '{name} est en train d\'ecrire...',
    'type_message': 'Ecrire un message...',
    'add_contact_title': 'Ajouter un contact',
    'contact_query_hint': 'Pseudo ou email',
    'add_contact_button': 'Ajouter',
    'contact_added': 'Contact ajoute',
    'contact_not_found': 'Utilisateur introuvable',
    'contact_exists': 'Le contact existe deja',
    'invalid_contact': 'Contact invalide',
    'language': 'Langue',
    'save': 'Enregistrer',
    'cancel': 'Annuler',
    'select_language': 'Selectionner la langue',
    'fill_required_fields': 'Veuillez remplir les champs requis',
    'email_password_required': 'Email et mot de passe sont requis',
    'error_loading_users': 'Erreur lors du chargement des utilisateurs',
  }
};
