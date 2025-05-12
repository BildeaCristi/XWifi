import 'package:flutter/material.dart';
import '../models/wifi_network.dart' as app_model;

class ConnectDialog extends StatefulWidget {
  final app_model.WifiNetwork network;
  final Function(String password) onConnect;

  const ConnectDialog({
    super.key,
    required this.network,
    required this.onConnect,
  });

  @override
  State<ConnectDialog> createState() => _ConnectDialogState();
}

class _ConnectDialogState extends State<ConnectDialog> {
  final TextEditingController _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isPasswordRequired = false;

  @override
  void initState() {
    super.initState();
    _isPasswordRequired = widget.network.isSecured();
  }

  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return AlertDialog(
      title: Text('Connect to ${widget.network.ssid}'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildNetworkInfo(context),
            const SizedBox(height: 16),
            if (_isPasswordRequired) ...[
              TextField(
                controller: _passwordController,
                decoration: InputDecoration(
                  labelText: 'Password',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility_off
                          : Icons.visibility,
                    ),
                    onPressed: () {
                      setState(() {
                        _obscurePassword = !_obscurePassword;
                      });
                    },
                  ),
                ),
                obscureText: _obscurePassword,
                autofocus: true,
              ),
            ] else ...[
              Text(
                'This network does not require a password.',
                style: TextStyle(
                  color: colorScheme.onSurface.withOpacity(0.6),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(
                    Icons.warning,
                    color: Colors.orange,
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Open networks are not secure. Your data may be visible to others.',
                      style: TextStyle(
                        color: Colors.orange,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            widget.onConnect(_passwordController.text);
          },
          child: const Text('Connect'),
        ),
      ],
    );
  }

  Widget _buildNetworkInfo(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    // Calculate signal quality (1-4)
    final int signalQuality = _calculateSignalQuality(widget.network.level);
    
    // Calculate signal percentage
    final int signalStrength = _calculateSignalPercentage(widget.network.level);
    
    // Determine security
    final bool isSecured = widget.network.isSecured();
    final String securityType = widget.network.getSecurityTypeDisplay();
    
    // Get frequency band
    final String frequencyBand = widget.network.getFrequencyBand();
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.primaryContainer.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                signalQuality >= 3
                    ? Icons.signal_wifi_4_bar
                    : (signalQuality == 2
                        ? Icons.network_wifi
                        : Icons.signal_wifi_0_bar),
                color: signalQuality >= 3
                    ? Colors.green
                    : (signalQuality == 2 ? Colors.orange : Colors.red),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  widget.network.ssid,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Security: $securityType',
                style: TextStyle(
                  fontSize: 12,
                  color: colorScheme.onSurface.withOpacity(0.6),
                ),
              ),
              Text(
                'Signal: $signalStrength%',
                style: TextStyle(
                  fontSize: 12,
                  color: colorScheme.onSurface.withOpacity(0.6),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Frequency: $frequencyBand',
            style: TextStyle(
              fontSize: 12,
              color: colorScheme.onSurface.withOpacity(0.6),
            ),
          ),
        ],
      ),
    );
  }
  
  // Helper methods for UI display
  
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