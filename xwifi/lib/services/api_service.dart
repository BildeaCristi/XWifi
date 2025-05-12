import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/saved_network.dart';

class ApiService {
  // Base URL for the API
  final String baseUrl;
  
  // Client for making HTTP requests
  final http.Client _client = http.Client();

  // Constructor with flexible URL configuration
  ApiService({String? customBaseUrl}) 
      : baseUrl = customBaseUrl ?? 'http://192.168.100.13:5116/api/networks';
  
  // Get all saved networks
  Future<List<SavedNetwork>> getSavedNetworks() async {
    try {
      debugPrint('Fetching networks from: $baseUrl');
      final response = await _client.get(Uri.parse(baseUrl));
      
      if (response.statusCode == 200) {
        final List<dynamic> jsonList = jsonDecode(response.body);
        debugPrint('Received ${jsonList.length} networks');
        return jsonList.map((json) => SavedNetwork.fromJson(json)).toList();
      } else {
        debugPrint('Error status code: ${response.statusCode}');
        throw Exception('Failed to load networks: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Network error in getSavedNetworks: $e');
      throw Exception('Network error: $e');
    }
  }

  // Save a network (works with or without password)
  Future<SavedNetwork> saveNetwork(SavedNetwork network) async {
    try {
      // Make sure the network is properly configured with either a valid password or null
      final networkToSave = network.toJson();
      
      // For debugging
      debugPrint('Posting network to: $baseUrl');
      debugPrint('Network data: ${jsonEncode(networkToSave)}');
      
      final response = await _client.post(
        Uri.parse(baseUrl),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode(networkToSave),
      );
      
      if (response.statusCode == 201) {
        final responseJson = jsonDecode(response.body);
        debugPrint('Save response: ${response.body}');
        return SavedNetwork.fromJson(responseJson);
      } else {
        debugPrint('Failed with status: ${response.statusCode}, body: ${response.body}');
        throw Exception('Failed to save network: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Network error in saveNetwork: $e');
      throw Exception('Network error: $e');
    }
  }

  // Delete a network
  Future<bool> deleteNetwork(String id) async {
    try {
      debugPrint('Deleting network at: $baseUrl/$id');
      
      final response = await _client.delete(
        Uri.parse('$baseUrl/$id'),
      );
      
      if (response.statusCode == 204) {
        debugPrint('Network deleted successfully');
        return true;
      } else {
        debugPrint('Failed to delete with status: ${response.statusCode}');
        throw Exception('Failed to delete network: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Network error in deleteNetwork: $e');
      throw Exception('Network error: $e');
    }
  }

  // Dispose of the HTTP client
  void dispose() {
    _client.close();
  }
} 