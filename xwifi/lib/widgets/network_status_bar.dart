import 'package:flutter/material.dart';
import '../models/wifi_network.dart' as app_model;

class NetworkStatusBar extends StatelessWidget {
  final app_model.WifiNetwork? connectedNetwork;
  final bool isScanning;

  const NetworkStatusBar({
    super.key,
    required this.connectedNetwork,
    required this.isScanning,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return Container(
      margin: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: colorScheme.primaryContainer,
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  connectedNetwork != null
                      ? Icons.wifi
                      : Icons.wifi_off,
                  color: colorScheme.onPrimaryContainer,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Text(
                  'Network Status',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onPrimaryContainer,
                  ),
                ),
                if (isScanning) ...[
                  const SizedBox(width: 8),
                  SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: colorScheme.onPrimaryContainer,
                    ),
                  ),
                ],
                const Spacer(),
                if (connectedNetwork != null)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: colorScheme.onPrimaryContainer.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'Connected',
                      style: TextStyle(
                        color: colorScheme.onPrimaryContainer,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            if (connectedNetwork != null) ...[
              Text(
                connectedNetwork!.ssid,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onPrimaryContainer,
                ),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  _buildInfoChip(
                    context,
                    icon: Icons.security,
                    label: connectedNetwork!.getSecurityTypeDisplay(),
                  ),
                  const SizedBox(width: 8),
                  _buildInfoChip(
                    context,
                    icon: Icons.network_cell,
                    label: connectedNetwork!.getFrequencyBand(),
                  ),
                  if (connectedNetwork!.ipAddress != null) ...[
                    const SizedBox(width: 8),
                    _buildInfoChip(
                      context,
                      icon: Icons.language,
                      label: connectedNetwork!.ipAddress!,
                    ),
                  ],
                ],
              ),
            ] else ...[
              Text(
                'Not connected to any WiFi network',
                style: TextStyle(
                  color: colorScheme.onPrimaryContainer,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Tap on a network from the list below to connect',
                style: TextStyle(
                  color: colorScheme.onPrimaryContainer.withOpacity(0.7),
                  fontSize: 12,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInfoChip(
    BuildContext context, {
    required IconData icon,
    required String label,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 8,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: colorScheme.onPrimaryContainer.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 14,
            color: colorScheme.onPrimaryContainer.withOpacity(0.8),
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: colorScheme.onPrimaryContainer,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
} 