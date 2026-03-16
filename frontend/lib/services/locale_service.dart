import 'package:flutter/material.dart';

class LocaleService {
  static final ValueNotifier<Locale?> localeNotifier =
      ValueNotifier<Locale?>(null);

  static void setLocaleFromTag(String? tag) {
    if (tag == null || tag.isEmpty) {
      localeNotifier.value = null;
      return;
    }
    final normalized = tag.replaceAll('_', '-');
    final parts = normalized.split('-');
    if (parts.length == 1) {
      localeNotifier.value = Locale(parts[0].toLowerCase());
      return;
    }
    localeNotifier.value = Locale(
      parts[0].toLowerCase(),
      parts[1].toUpperCase(),
    );
  }

  static String? tagFromLocale(Locale? locale) {
    if (locale == null) return null;
    if (locale.countryCode == null || locale.countryCode!.isEmpty) {
      return locale.languageCode.toLowerCase();
    }
    return '${locale.languageCode.toLowerCase()}-${locale.countryCode!.toUpperCase()}';
  }
}
