import 'dart:convert';

/// A model representing a saved WiFi network that can be shared
class SavedNetwork {
  final String id;
  final String ssid;
  final String password;
  final String capabilities;
  final String notes;
  final DateTime createdAt;

  SavedNetwork({
    required this.id,
    required this.ssid,
    required this.password,
    required this.capabilities,
    this.notes = '',
    required this.createdAt,
  });

  factory SavedNetwork.create({
    required String ssid,
    required String password,
    required String capabilities,
    String notes = '',
  }) {
    return SavedNetwork(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      ssid: ssid,
      password: password,
      capabilities: capabilities,
      notes: notes,
      createdAt: DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'ssid': ssid,
      'password': password,
      'capabilities': capabilities,
      'notes': notes,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory SavedNetwork.fromJson(Map<String, dynamic> json) {
    return SavedNetwork(
      id: json['id'],
      ssid: json['ssid'],
      password: json['password'],
      capabilities: json['capabilities'],
      notes: json['notes'] ?? '',
      createdAt: DateTime.parse(json['createdAt']),
    );
  }

  String getSecurityTypeDisplay() {
    if (capabilities.contains('WPA3')) return 'WPA3';
    if (capabilities.contains('WPA2')) return 'WPA2';
    if (capabilities.contains('WPA')) return 'WPA';
    if (capabilities.contains('WEP')) return 'WEP';
    return capabilities.isNotEmpty ? 'Secured' : 'Open';
  }
}

// Extension for list conversion
extension SavedNetworkListExtension on List<SavedNetwork> {
  String toJsonString() {
    final jsonList = map((network) => network.toJson()).toList();
    return jsonEncode(jsonList);
  }

  static List<SavedNetwork> fromJsonString(String jsonString) {
    final List<dynamic> jsonList = jsonDecode(jsonString);
    return jsonList.map((json) => SavedNetwork.fromJson(json)).toList();
  }
} 