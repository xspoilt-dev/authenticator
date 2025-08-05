import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/auth_secret.dart';

class StorageService {
  static const String _secretsKey = 'auth_secrets';

  static Future<List<AuthSecret>> getSecrets() async {
    final prefs = await SharedPreferences.getInstance();
    final secretsJson = prefs.getStringList(_secretsKey) ?? [];

    return secretsJson
        .map((json) => AuthSecret.fromJson(jsonDecode(json)))
        .toList();
  }

  static Future<void> saveSecret(AuthSecret secret) async {
    final secrets = await getSecrets();
    secrets.add(secret);
    await _saveSecrets(secrets);
  }

  static Future<void> deleteSecret(String id) async {
    final secrets = await getSecrets();
    secrets.removeWhere((secret) => secret.id == id);
    await _saveSecrets(secrets);
  }

  static Future<void> _saveSecrets(List<AuthSecret> secrets) async {
    final prefs = await SharedPreferences.getInstance();
    final secretsJson = secrets
        .map((secret) => jsonEncode(secret.toJson()))
        .toList();
    await prefs.setStringList(_secretsKey, secretsJson);
  }
}
