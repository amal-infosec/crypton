
import 'dart:convert';
import 'dart:io';
import 'package:csv/csv.dart';
import '../models/data_models.dart';
import 'encryption_service.dart';

class ImportService {
  final EncryptionService _encryptionService;

  ImportService(this._encryptionService);

  /// Parses a Chrome/Brave CSV export and returns a list of PasswordEntry
  Future<List<PasswordEntry>> parseChromeCsv(String filePath) async {
    final file = File(filePath);
    final input = await file.readAsString();
    
    // Chrome CSV format: name,url,username,password
    // We use CsvToListConverter with shouldParseNumbers: false to keep passwords as strings
    List<List<dynamic>> rows = const CsvToListConverter(shouldParseNumbers: false).convert(input);
    
    if (rows.isEmpty) return [];

    // Identify indices from header
    List<dynamic> header = rows.first;
    int nameIdx = header.indexOf('name');
    int urlIdx = header.indexOf('url');
    int userIdx = header.indexOf('username');
    int passIdx = header.indexOf('password');

    // Fallback if headers are slightly different (e.g. Brave)
    if (nameIdx == -1) nameIdx = header.indexOf('title');
    if (userIdx == -1) userIdx = header.indexOf('login');

    if (nameIdx == -1 || userIdx == -1 || passIdx == -1) {
      // If we can't find headers, try assuming a standard order
      nameIdx = 0;
      urlIdx = 1;
      userIdx = 2;
      passIdx = 3;
    }

    final List<PasswordEntry> entries = [];
    
    // Start from 1 to skip header
    for (int i = 1; i < rows.length; i++) {
      final row = rows[i];
      if (row.length <= passIdx) continue;

      final title = row[nameIdx].toString();
      final website = row[urlIdx].toString();
      final username = row[userIdx].toString();
      final plainPassword = row[passIdx].toString();

      if (title.isEmpty && username.isEmpty) continue;

      final encryptedPassword = _encryptionService.encryptString(plainPassword);

      entries.add(PasswordEntry(
        title: title.isEmpty ? website : title,
        username: username,
        encryptedPassword: encryptedPassword,
        website: website,
        category: 'Imported',
      ));
    }

    return entries;
  }

  /// Parses Firefox CSV export
  Future<List<PasswordEntry>> parseFirefoxCsv(String filePath) async {
    // Firefox CSV format: "url","username","password","httpRealm","formActionOrigin","guid","timeCreated","timeLastUsed","timePasswordChanged"
    final file = File(filePath);
    final input = await file.readAsString();
    
    List<List<dynamic>> rows = const CsvToListConverter(shouldParseNumbers: false).convert(input);
    
    if (rows.isEmpty) return [];

    List<dynamic> header = rows.first;
    int urlIdx = header.indexOf('url');
    int userIdx = header.indexOf('username');
    int passIdx = header.indexOf('password');

    if (urlIdx == -1 || userIdx == -1 || passIdx == -1) {
       // Manual indices for Firefox standard export
       urlIdx = 0;
       userIdx = 1;
       passIdx = 2;
    }

    final List<PasswordEntry> entries = [];
    for (int i = 1; i < rows.length; i++) {
      final row = rows[i];
      if (row.length <= passIdx) continue;

      final website = row[urlIdx].toString();
      final username = row[userIdx].toString();
      final plainPassword = row[passIdx].toString();

      if (username.isEmpty && plainPassword.isEmpty) continue;

      final encryptedPassword = _encryptionService.encryptString(plainPassword);

      entries.add(PasswordEntry(
        title: _extractHostFromUrl(website),
        username: username,
        encryptedPassword: encryptedPassword,
        website: website,
        category: 'Imported',
      ));
    }
    return entries;
  }

  /// Parses Bitwarden JSON export
  Future<List<PasswordEntry>> parseBitwardenJson(String filePath) async {
    final file = File(filePath);
    final content = await file.readAsString();
    final data = jsonDecode(content);
    
    if (data == null || data['items'] == null) return [];
    
    final List items = data['items'];
    final List<PasswordEntry> entries = [];
    
    for (var item in items) {
      if (item['type'] != 1) continue; // 1 is Login type in Bitwarden
      
      final login = item['login'];
      if (login == null) continue;
      
      final title = item['name'] ?? 'Untitled';
      final username = login['username'] ?? '';
      final plainPassword = login['password'] ?? '';
      final List? uris = login['uris'];
      final website = (uris != null && uris.isNotEmpty) ? uris.first['uri'] ?? '' : '';

      if (username.isEmpty && plainPassword.isEmpty) continue;

      final encryptedPassword = _encryptionService.encryptString(plainPassword);

      entries.add(PasswordEntry(
        title: title,
        username: username,
        encryptedPassword: encryptedPassword,
        website: website,
        category: 'Imported',
      ));
    }
    
    return entries;
  }

  String _extractHostFromUrl(String url) {
    try {
      final uri = Uri.parse(url);
      return uri.host.isNotEmpty ? uri.host : url;
    } catch (_) {
      return url;
    }
  }
}
