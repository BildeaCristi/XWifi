import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/wifi_provider.dart';
import '../models/wifi_network.dart' as app_model;
import '../widgets/wifi_card.dart';
import '../widgets/network_status_bar.dart';
import '../widgets/connect_dialog.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<WifiProvider>(
      builder: (context, wifiProvider, child) {
        if (!wifiProvider.hasPermissions) {
          return _buildPermissionsRequest(context, wifiProvider);
        }

        return _buildNetworksList(context, wifiProvider);
      },
    );
  }

  Widget _buildPermissionsRequest(BuildContext context, WifiProvider provider) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.wifi_off_rounded, size: 80, color: Colors.grey),
            const SizedBox(height: 24),
            Text(
              provider.hasPermissions && !provider.locationEnabled
                  ? 'Location Services Required'
                  : 'WiFi Permissions Required',
              style: Theme.of(context).textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text(
              provider.hasPermissions && !provider.locationEnabled
                  ? 'WiFi scanning requires location services to be enabled on your device. Please enable location services in your system settings.'
                  : 'To scan for WiFi networks, this app needs location and WiFi scanning permissions.',
              style: Theme.of(context).textTheme.bodyLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => provider.requestPermissions(),
              icon: Icon(provider.hasPermissions && !provider.locationEnabled
                  ? Icons.location_on
                  : Icons.check_circle_outline),
              label: Text(provider.hasPermissions && !provider.locationEnabled
                  ? 'Enable Location Services'
                  : 'Grant Permissions'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNetworksList(BuildContext context, WifiProvider provider) {
    return RefreshIndicator(
      onRefresh: provider.startScan,
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(
            child: NetworkStatusBar(
              connectedNetwork: provider.connectedNetwork,
              isScanning: provider.isScanning,
            ),
          ),
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(16, 8, 16, 4),
              child: Text(
                'Available Networks',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
          ),
          if (provider.errorMessage.isNotEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  provider.errorMessage,
                  style: const TextStyle(color: Colors.red),
                ),
              ),
            ),
          if (provider.isScanning && provider.networks.isEmpty)
            const SliverFillRemaining(
              child: Center(
                child: CircularProgressIndicator(),
              ),
            )
          else if (provider.networks.isEmpty)
            const SliverFillRemaining(
              child: Center(
                child: Text('No networks found. Pull to refresh.'),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.all(8.0),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final network = provider.networks[index];
                    return Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8.0,
                        vertical: 4.0,
                      ),
                      child: WiFiCard(
                        network: network,
                        onTap: () => _showConnectDialog(context, network, provider),
                      ),
                    );
                  },
                  childCount: provider.networks.length,
                ),
              ),
            ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Center(
                child: provider.isScanning
                    ? const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                          SizedBox(width: 8),
                          Text('Scanning...'),
                        ],
                      )
                    : TextButton.icon(
                        onPressed: provider.startScan,
                        icon: const Icon(Icons.refresh),
                        label: const Text('Scan Again'),
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showConnectDialog(
    BuildContext context,
    app_model.WifiNetwork network,
    WifiProvider provider,
  ) {
    showDialog(
      context: context,
      builder: (context) => ConnectDialog(
        network: network,
        onConnect: (password) async {
          Navigator.of(context).pop();
          
          final scaffoldMessenger = ScaffoldMessenger.of(context);
          final result = await provider.connectToNetwork(network.ssid, password);
          
          if (result) {
            scaffoldMessenger.showSnackBar(
              SnackBar(content: Text('Connected to ${network.ssid}')),
            );
          } else {
            scaffoldMessenger.showSnackBar(
              SnackBar(
                content: Text('Failed to connect to ${network.ssid}'),
                backgroundColor: Colors.red,
              ),
            );
          }
        },
      ),
    );
  }
} 