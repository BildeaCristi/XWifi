import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:wifi_scan/wifi_scan.dart';
import 'package:wifi_iot/wifi_iot.dart' as wifi_iot;
import 'package:network_info_plus/network_info_plus.dart';
import '../models/wifi_network.dart' as app_model;

/// Provider that manages WiFi scanning and connection
/// Uses WiFiScan library for scanning and NetworkInfo+ for network details
class WifiProvider extends ChangeNotifier {
  final NetworkInfo _networkInfo = NetworkInfo();
  final List<app_model.WifiNetwork> _networks = [];
  app_model.WifiNetwork? _connectedNetwork;
  bool _isScanning = false;
  bool _hasPermissions = false;
  bool _locationEnabled = false;
  String _errorMessage = '';
  StreamSubscription<List<WiFiAccessPoint>>? _scanResultsSubscription;
  Timer? _autoScanTimer;
  final Duration _autoScanInterval = const Duration(seconds: 10);
  
  // Platform channel for native permissions
  static const platform = MethodChannel('com.example.xwifi/permissions');

  // Getters
  List<app_model.WifiNetwork> get networks => _networks;
  app_model.WifiNetwork? get connectedNetwork => _connectedNetwork;
  bool get isScanning => _isScanning;
  bool get hasPermissions => _hasPermissions;
  bool get locationEnabled => _locationEnabled;
  String get errorMessage => _errorMessage;

  WifiProvider() {
    _init();
  }

  Future<void> _init() async {
    await _checkPermissions();
    await _checkLocationService();
    if (_hasPermissions && _locationEnabled) {
      // Subscribe to scan results using the stream API
      _subscribeToScanResults();
      await _getCurrentNetwork();
      await startScan();
    }
  }

  /// Subscribe to WiFiScan's onScannedResultsAvailable stream
  void _subscribeToScanResults() {
    _scanResultsSubscription?.cancel();
    _scanResultsSubscription = WiFiScan.instance.onScannedResultsAvailable.listen((results) {
      if (results.isNotEmpty) {
        _updateNetworksFromScan(results);
        _errorMessage = '';  // Clear error if we have results
      }
      _isScanning = false;
      notifyListeners();
    }, onError: (e) {
      _errorMessage = 'Error in scan results: $e';
      _isScanning = false;
      notifyListeners();
    });
  }

  Future<void> _checkPermissions() async {
    if (Platform.isAndroid) {
      var status = await Permission.location.status;
      _hasPermissions = status.isGranted;
      
      if (!_hasPermissions) {
        _errorMessage = 'Location permission is required for WiFi scanning on Android';
      } else {
        _errorMessage = '';
      }
      
      notifyListeners();
    } else {
      // On iOS or other platforms, assume permissions are granted
      _hasPermissions = true;
      notifyListeners();
    }
  }
  
  Future<void> _checkLocationService() async {
    if (Platform.isAndroid) {
      // Use WiFiScan's canStartScan to check if location services are enabled
      final serviceStatus = await WiFiScan.instance.canStartScan();
      _locationEnabled = (serviceStatus == CanStartScan.yes);
      
      if (!_locationEnabled) {
        _errorMessage = 'Location services are disabled. Please enable them in system settings.';
      }
      
      notifyListeners();
    } else {
      _locationEnabled = true;
      notifyListeners();
    }
  }

  Future<void> requestPermissions() async {
    if (Platform.isAndroid) {
      // Request location permission which is required for WiFi scanning
      var status = await Permission.location.request();
      _hasPermissions = status.isGranted;
      
      // Next, check if location services are enabled
      await _checkLocationService();
      
      if (_hasPermissions && !_locationEnabled) {
        _errorMessage = 'Please enable location services in your device settings to scan for WiFi networks';
        
        // Wait a moment and check again
        await Future.delayed(const Duration(seconds: 2));
        await _checkLocationService();
      }
      
      if (_hasPermissions && _locationEnabled) {
        _errorMessage = '';
        _subscribeToScanResults();
        await startScan();
        _startAutoScan();
      }
      
      notifyListeners();
    } else {
      // On iOS or other platforms
      _hasPermissions = true;
      _locationEnabled = true;
      notifyListeners();
    }
  }

  void _startAutoScan() {
    _autoScanTimer?.cancel();
    _autoScanTimer = Timer.periodic(_autoScanInterval, (_) => startScan());
  }

  @override
  void dispose() {
    _scanResultsSubscription?.cancel();
    _autoScanTimer?.cancel();
    super.dispose();
  }

  Future<void> startScan() async {
    if (_isScanning || !_hasPermissions) return;
    
    try {
      _isScanning = true;
      notifyListeners();

      _errorMessage = '';
      
      // Check location service and WiFi enabled
      await _checkLocationService();
      if (!_locationEnabled) {
        _isScanning = false;
        notifyListeners();
        return;
      }

      // Ensure WiFi is enabled
      bool isWifiEnabled = await wifi_iot.WiFiForIoTPlugin.isEnabled();
      if (!isWifiEnabled) {
        bool? enableResult = await wifi_iot.WiFiForIoTPlugin.setEnabled(true);
        if (enableResult != true) {
          _errorMessage = 'Unable to enable WiFi';
          _isScanning = false;
          notifyListeners();
          return;
        }
      }

      // Start scan using WiFiScan
      final canScan = await WiFiScan.instance.canStartScan();
      if (canScan != CanStartScan.yes) {
        _errorMessage = 'Cannot start WiFi scan: $canScan';
        _isScanning = false;
        notifyListeners();
        return;
      }

      // Start WiFi scan - results will come through the onScannedResultsAvailable stream
      final result = await WiFiScan.instance.startScan();
      if (!result) {
        // If startScan failed, try to get previously scanned results
        final canGetResults = await WiFiScan.instance.canGetScannedResults();
        if (canGetResults == CanGetScannedResults.yes) {
          final accessPoints = await WiFiScan.instance.getScannedResults();
          if (accessPoints.isEmpty) {
            _errorMessage = 'No networks found';
          } else {
            // Update our list with previous scan results
            _updateNetworksFromScan(accessPoints);
          }
        } else {
          _errorMessage = 'Failed to start WiFi scan';
        }
        _isScanning = false;
        notifyListeners();
      }
      
      // Update current network info - don't wait as results will come through stream
      _getCurrentNetwork();
    } catch (e) {
      _errorMessage = 'Error scanning WiFi: $e';
      _isScanning = false;
      notifyListeners();
    }
  }

  void _updateNetworksFromScan(List<WiFiAccessPoint> accessPoints) {
    _networks.clear();
    String? connectedSSID = _connectedNetwork?.ssid;
    
    for (final ap in accessPoints) {
      final network = app_model.WifiNetwork.fromAccessPoint(ap);
      // Mark as connected if matches the currently connected network
      if (connectedSSID != null && connectedSSID == network.ssid) {
        network.isConnected = true;
        // Copy network details if available
        if (_connectedNetwork != null) {
          network.ipAddress = _connectedNetwork!.ipAddress;
          network.ipv6Address = _connectedNetwork!.ipv6Address;
          network.subnet = _connectedNetwork!.subnet;
          network.broadcast = _connectedNetwork!.broadcast;
          network.gateway = _connectedNetwork!.gateway;
        }
      }
      _networks.add(network);
    }
    // Sort by signal strength
    _networks.sort((a, b) => b.level.compareTo(a.level));
    notifyListeners();
  }

  Future<void> _getCurrentNetwork() async {
    try {
      // Get all network info directly from NetworkInfo+
      final wifiName = await _networkInfo.getWifiName();
      final bssid = await _networkInfo.getWifiBSSID();
      final ip = await _networkInfo.getWifiIP();
      final ipv6 = await _networkInfo.getWifiIPv6();
      final subnet = await _networkInfo.getWifiSubmask();
      final broadcast = await _networkInfo.getWifiBroadcast();
      final gateway = await _networkInfo.getWifiGatewayIP();
      
      if (wifiName != null && wifiName.isNotEmpty) {
        // Remove quotes if present in SSID
        final ssid = wifiName.replaceAll('"', '');
        
        // Get signal strength and frequency directly from WiFiForIoTPlugin
        int signalStrength = 0;
        int frequency = 0;
        String capabilities = '';
        
        try {
          // Use direct plugin calls
          final currentStrength = await wifi_iot.WiFiForIoTPlugin.getCurrentSignalStrength();
          if (currentStrength != null) {
            signalStrength = currentStrength;
          }
          
          // Try to get frequency
          final currentFrequency = await wifi_iot.WiFiForIoTPlugin.getFrequency();
          if (currentFrequency != null) {
            frequency = currentFrequency;
          }
          
          // Try to get security info
          final networks = await wifi_iot.WiFiForIoTPlugin.loadWifiList();
          if (networks != null) {
            for (var network in networks) {
              if (network.ssid == ssid && network.capabilities != null) {
                capabilities = network.capabilities!;
                break;
              }
            }
          }
          
          if (capabilities.isEmpty) {
            capabilities = "WPA"; // Default for most networks
          }
        } catch (e) {
          // Default values on error
          print('Error getting network details: $e');
        }
        
        // Create a clean network object with all available info
        _connectedNetwork = app_model.WifiNetwork(
          ssid: ssid,
          bssid: bssid ?? '',
          capabilities: capabilities,
          frequency: frequency,
          level: signalStrength,
          isConnected: true,
          ipAddress: ip,
          ipv6Address: ipv6,
          subnet: subnet,
          broadcast: broadcast,
          gateway: gateway,
        );
        
        // Update connected status in the networks list
        for (var network in _networks) {
          network.isConnected = network.ssid == ssid;
          if (network.isConnected) {
            network.ipAddress = ip;
            network.ipv6Address = ipv6;
            network.subnet = subnet;
            network.broadcast = broadcast;
            network.gateway = gateway;
          }
        }
      } else {
        _connectedNetwork = null;
      }
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Error getting current network: $e';
      notifyListeners();
    }
  }

  Future<bool> connectToNetwork(String ssid, String password) async {
    try {
      // Determine security type
      wifi_iot.NetworkSecurity security = wifi_iot.NetworkSecurity.WPA;
      
      // Find the network in our list to determine security type
      for (var network in _networks) {
        if (network.ssid == ssid) {
          if (network.capabilities.contains('WPA')) {
            security = wifi_iot.NetworkSecurity.WPA;
          } else if (network.capabilities.contains('WEP')) {
            security = wifi_iot.NetworkSecurity.WEP;
          } else {
            security = wifi_iot.NetworkSecurity.NONE;
          }
          break;
        }
      }
      
      // Connect directly using wifi_iot plugin
      final result = await wifi_iot.WiFiForIoTPlugin.connect(
        ssid,
        password: password,
        security: security,
        joinOnce: false,
      );
      
      if (result) {
        // Wait a bit for connection to establish
        await Future.delayed(const Duration(seconds: 2));
        // Update the current network
        await _getCurrentNetwork();
      }
      
      return result;
    } catch (e) {
      _errorMessage = 'Error connecting to network: $e';
      notifyListeners();
      return false;
    }
  }

  Future<bool> disconnectFromNetwork() async {
    try {
      // Disconnect directly using wifi_iot plugin
      final result = await wifi_iot.WiFiForIoTPlugin.disconnect();
      if (result) {
        await _getCurrentNetwork();
      }
      return result;
    } catch (e) {
      _errorMessage = 'Error disconnecting from network: $e';
      notifyListeners();
      return false;
    }
  }

  Future<Map<String, dynamic>> getNetworkDetails() async {
    final details = <String, dynamic>{};
    
    try {
      // Get all details directly from NetworkInfo+ plugin
      details['SSID'] = await _networkInfo.getWifiName();
      if (details['SSID'] != null) {
        details['SSID'] = (details['SSID'] as String).replaceAll('"', '');
      } else {
        details['SSID'] = 'Not connected';
      }
      
      details['BSSID'] = await _networkInfo.getWifiBSSID() ?? 'Unknown';
      details['IP Address'] = await _networkInfo.getWifiIP() ?? 'Unknown';
      details['IPv6 Address'] = await _networkInfo.getWifiIPv6() ?? 'Unknown';
      details['Subnet Mask'] = await _networkInfo.getWifiSubmask() ?? 'Unknown';
      details['Gateway IP'] = await _networkInfo.getWifiGatewayIP() ?? 'Unknown';
      details['Broadcast'] = await _networkInfo.getWifiBroadcast() ?? 'Unknown';
      
      if (details['SSID'] != 'Not connected') {
        try {
          // Add frequency and channel info if connected
          final frequency = await wifi_iot.WiFiForIoTPlugin.getFrequency() ?? 0;
          details['Frequency'] = frequency > 0 ? '${frequency} MHz' : 'Unknown';
          
          if (frequency > 0) {
            // Calculate channel from frequency
            int channel = 0;
            if (frequency >= 2412 && frequency <= 2484) {
              // 2.4 GHz band
              if (frequency == 2484) channel = 14; // Japan
              else channel = ((frequency - 2412) ~/ 5) + 1;
            } else if (frequency >= 5170 && frequency <= 5825) {
              // 5 GHz band
              channel = ((frequency - 5170) ~/ 5) + 34;
            }
            details['Channel'] = channel > 0 ? channel.toString() : 'Unknown';
          } else {
            details['Channel'] = 'Unknown';
          }
        } catch (e) {
          details['Frequency'] = 'Unknown';
          details['Channel'] = 'Unknown';
        }
      }
      
      // Get security type if connected
      if (details['SSID'] != 'Not connected' && _connectedNetwork != null) {
        details['Security'] = _connectedNetwork!.getSecurityTypeDisplay();
      } else {
        details['Security'] = 'Unknown';
      }
      
      return details;
    } catch (e) {
      _errorMessage = 'Error getting network details: $e';
      notifyListeners();
      return {'Error': 'Failed to get network details: $e'};
    }
  }
  
  // Additional utility methods
  
  Future<bool> isWifiEnabled() async {
    try {
      return await wifi_iot.WiFiForIoTPlugin.isEnabled();
    } catch (e) {
      _errorMessage = 'Error checking WiFi status: $e';
      return false;
    }
  }
  
  Future<bool> setWifiEnabled(bool enabled) async {
    try {
      return await wifi_iot.WiFiForIoTPlugin.setEnabled(enabled) ?? false;
    } catch (e) {
      _errorMessage = 'Error setting WiFi status: $e';
      return false;
    }
  }
  
  Future<bool> forgetNetwork(String ssid) async {
    try {
      return await wifi_iot.WiFiForIoTPlugin.removeWifiNetwork(ssid);
    } catch (e) {
      _errorMessage = 'Error removing network: $e';
      return false;
    }
  }
} 