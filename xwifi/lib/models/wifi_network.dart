import 'package:wifi_iot/wifi_iot.dart' as wifi_iot;
import 'package:wifi_scan/wifi_scan.dart';

/// A simple data holder for WiFi networks
/// Uses WiFiAccessPoint's properties directly when available
class WifiNetwork {
  // Core properties from WiFiAccessPoint
  final String ssid;
  final String bssid;
  final String capabilities;
  final int frequency;
  final int level;
  bool isConnected;
  
  // Optional network details
  String? ipAddress;
  String? ipv6Address;
  String? subnet;
  String? broadcast;
  String? gateway;
  
  // Reference to original access point for direct access
  final WiFiAccessPoint? accessPoint;

  WifiNetwork({
    required this.ssid,
    required this.bssid,
    required this.capabilities,
    required this.frequency,
    required this.level,
    this.isConnected = false,
    this.ipAddress,
    this.ipv6Address,
    this.subnet,
    this.broadcast,
    this.gateway,
    this.accessPoint,
  });

  /// Create a WifiNetwork from a WiFiAccessPoint (wifi_scan library)
  factory WifiNetwork.fromAccessPoint(WiFiAccessPoint ap) {
    return WifiNetwork(
      ssid: ap.ssid,
      bssid: ap.bssid,
      capabilities: ap.capabilities,
      frequency: ap.frequency,
      level: ap.level,
      isConnected: false,
      accessPoint: ap,
    );
  }

  /// Create a WifiNetwork from a WifiNetwork (wifi_iot library)
  factory WifiNetwork.fromWiFiForIoT(wifi_iot.WifiNetwork network) {
    return WifiNetwork(
      ssid: network.ssid ?? '',
      bssid: network.bssid ?? '',
      capabilities: network.capabilities ?? '',
      frequency: network.frequency ?? 0,
      level: network.level ?? 0,
      isConnected: false,
    );
  }

  /// Get security type for connecting with WiFiForIoTPlugin
  wifi_iot.NetworkSecurity getConnectionSecurity() {
    if (capabilities.contains('WPA3') || 
        capabilities.contains('WPA2') || 
        capabilities.contains('WPA')) {
      return wifi_iot.NetworkSecurity.WPA;
    }
    if (capabilities.contains('WEP')) {
      return wifi_iot.NetworkSecurity.WEP;
    }
    return wifi_iot.NetworkSecurity.NONE;
  }

  /// Check if this network requires a password
  bool isSecured() {
    if (capabilities.contains('WPA3') || 
        capabilities.contains('WPA2') || 
        capabilities.contains('WPA')) {
      return true;
    }
    if (capabilities.contains('WEP')) {
      return true;
    }
    return false;
  }
  
  /// Get human-readable frequency band
  String getFrequencyBand() {
    // Use the frequency directly from the WiFiAccessPoint
    if (accessPoint != null) {
      return accessPoint!.frequency >= 5000 ? '5 GHz' : '2.4 GHz';
    }
    
    // Fallback to our stored frequency value
    if (frequency > 0) {
      return frequency >= 5000 ? '5 GHz' : '2.4 GHz';
    }
    
    // Handle hotspots by BSSID pattern
    if (bssid.startsWith('02:')) {
      return '2.4 GHz'; // Most mobile hotspots use 2.4 GHz
    }
    
    return 'Unknown';
  }
  
  /// Get channel number based on frequency
  int getChannel() {
    if (accessPoint != null) {
      // WiFiAccessPoint directly provides channel information on some platforms
      // For other platforms, calculate from frequency
      return _frequencyToChannel(accessPoint!.frequency);
    }
    
    if (frequency > 0) {
      return _frequencyToChannel(frequency);
    }
    
    return 0; // Unknown channel
  }
  
  /// Convert frequency to channel number
  int _frequencyToChannel(int freq) {
    if (freq >= 2412 && freq <= 2484) {
      // 2.4 GHz band
      if (freq == 2484) return 14; // Japan
      return ((freq - 2412) ~/ 5) + 1;
    } else if (freq >= 5170 && freq <= 5825) {
      // 5 GHz band
      return ((freq - 5170) ~/ 5) + 34;
    }
    return 0; // Unknown
  }
  
  /// Get a human-readable security description
  String getSecurityTypeDisplay() {
    if (capabilities.contains('WPA3')) return 'WPA3';
    if (capabilities.contains('WPA2')) return 'WPA2';
    if (capabilities.contains('WPA')) return 'WPA';
    if (capabilities.contains('WEP')) return 'WEP';
    return isSecured() ? 'Secured' : 'Open';
  }
} 