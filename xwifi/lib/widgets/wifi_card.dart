import 'package:flutter/material.dart';
import '../models/wifi_network.dart' as app_model;

class WiFiCard extends StatelessWidget {
  final app_model.WifiNetwork network;
  final VoidCallback onTap;

  const WiFiCard({
    super.key,
    required this.network,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    // Calculate signal quality (1-4)
    final int signalQuality = _calculateSignalQuality(network.level);
    
    // Determine security type
    final bool isSecured = network.isSecured();
    final String securityType = network.getSecurityTypeDisplay();
    
    // Calculate signal percentage (0-100)
    final int signalPercentage = _calculateSignalPercentage(network.level);
    
    // Determine frequency band
    final String frequencyBand = network.getFrequencyBand();
    
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _buildSignalIcon(signalQuality, colorScheme),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          network.ssid.isEmpty ? 'Hidden Network' : network.ssid,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '$frequencyBand • $securityType',
                          style: TextStyle(
                            color: colorScheme.onSurface.withOpacity(0.6),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (network.isConnected)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: colorScheme.primary.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'Connected',
                        style: TextStyle(
                          color: colorScheme.primary,
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              LinearProgressIndicator(
                value: signalPercentage / 100,
                backgroundColor: colorScheme.onSurface.withOpacity(0.1),
                borderRadius: BorderRadius.circular(4),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Signal Strength: $signalPercentage%',
                    style: TextStyle(
                      fontSize: 12,
                      color: colorScheme.onSurface.withOpacity(0.6),
                    ),
                  ),
                  Text(
                    isSecured ? securityType : 'No Password',
                    style: TextStyle(
                      fontSize: 12,
                      color: isSecured ? colorScheme.primary : Colors.orange,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSignalIcon(int signalQuality, ColorScheme colorScheme) {
    IconData iconData;
    Color iconColor;
    
    switch (signalQuality) {
      case 4:
        iconData = Icons.signal_wifi_4_bar;
        iconColor = Colors.green;
        break;
      case 3:
        iconData = Icons.network_wifi;
        iconColor = Colors.green.shade700;
        break;
      case 2:
        iconData = Icons.network_wifi;
        iconColor = Colors.orange;
        break;
      case 1:
      default:
        iconData = Icons.signal_wifi_0_bar;
        iconColor = Colors.red;
        break;
    }
    
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: iconColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(
        iconData,
        color: iconColor,
        size: 24,
      ),
    );
  }
  
  // Helper methods moved from the model to the UI component
  
  // Convert RSSI to percentage
  int _calculateSignalPercentage(int rssi) {
    // Signal level is usually between -100 dBm (weak) and -30 dBm (strong)
    if (rssi >= -50) return 100;
    if (rssi <= -100) return 0;
    
    // Convert to percentage (0-100)
    return ((rssi + 100) * 2).clamp(0, 100);
  }
  
  // Convert RSSI to quality category
  int _calculateSignalQuality(int rssi) {
    if (rssi >= -50) return 4; // Excellent
    if (rssi >= -70) return 3; // Good
    if (rssi >= -80) return 2; // Fair
    return 1; // Poor
  }
} 