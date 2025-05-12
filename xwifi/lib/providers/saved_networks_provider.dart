import 'package:flutter/material.dart';
import '../models/saved_network.dart';
import '../services/api_service.dart';
import '../models/wifi_network.dart';

class SavedNetworksProvider extends ChangeNotifier {
  final ApiService _apiService;
  List<SavedNetwork> _networks = [];
  bool _isLoading = false;
  String _errorMessage = '';
  int _loadAttempts = 0;

  // Getters
  List<SavedNetwork> get networks => _networks;
  bool get isLoading => _isLoading;
  String get errorMessage => _errorMessage;

  SavedNetworksProvider({ApiService? apiService}) 
      : _apiService = apiService ?? ApiService() {
    // Initial load is handled by initState in ShareScreen
  }

  // Load all saved networks from the API
  Future<void> loadNetworks() async {
    _isLoading = true;
    _errorMessage = '';
    _loadAttempts++;
    notifyListeners();

    debugPrint('Loading networks (attempt #$_loadAttempts)');

    try {
      _networks = await _apiService.getSavedNetworks();
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Failed to load networks. Please check your connection and try again.';
      _isLoading = false;
      
      // Keep existing networks if we had them
      if (_networks.isEmpty && _loadAttempts > 1) {
      }
      
      notifyListeners();
    }
  }

  // Save a network with or without password
  Future<bool> saveNetwork({
    required WifiNetwork network,
    String? password,
    String notes = '',
  }) async {
    _isLoading = true;
    _errorMessage = '';
    notifyListeners();

    try {
      final savedNetwork = SavedNetwork.create(
        ssid: network.ssid,
        password: password ?? "",  // Can be null or empty
        capabilities: network.capabilities,
        notes: notes,
      );

      final result = await _apiService.saveNetwork(savedNetwork);

      // Add to local list if not already in it
      if (!_networks.any((n) => n.id == result.id)) {
        _networks.add(result);
      }
      
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Failed to save network. Please check your connection and try again.';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Create a new network entry manually
  Future<bool> createNetwork({
    required String ssid,
    String? password,
    required String security,
    String notes = '',
  }) async {
    _isLoading = true;
    _errorMessage = '';
    notifyListeners();

    debugPrint('Creating manual network: $ssid');

    try {
      final savedNetwork = SavedNetwork.create(
        ssid: ssid,
        password: password ?? "",  // Can be null now
        capabilities: security,
        notes: notes,
      );

      final result = await _apiService.saveNetwork(savedNetwork);
      debugPrint('Manual network created successfully: ${result.ssid}');
      
      if (!_networks.any((n) => n.id == result.id)) {
        _networks.add(result);
      }
      
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Error creating network: $e');
      _errorMessage = 'Failed to create network. Please check your connection and try again.';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Delete a network
  Future<bool> deleteNetwork(String id) async {
    _isLoading = true;
    _errorMessage = '';
    notifyListeners();

    try {
      final result = await _apiService.deleteNetwork(id);
      if (result) {
        _networks.removeWhere((network) => network.id == id);
      }
      _isLoading = false;
      notifyListeners();
      return result;
    } catch (e) {
      _errorMessage = 'Failed to delete network. Please check your connection and try again.';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  @override
  void dispose() {
    _apiService.dispose();
    super.dispose();
  }
} 