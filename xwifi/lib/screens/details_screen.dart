import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/wifi_provider.dart';
import '../models/wifi_network.dart' as app_model;
import '../widgets/network_status_bar.dart';
import 'package:network_info_plus/network_info_plus.dart';

class DetailsScreen extends StatefulWidget {
  const DetailsScreen({super.key});

  @override
  State<DetailsScreen> createState() => _DetailsScreenState();
}

class _DetailsScreenState extends State<DetailsScreen> {
  Map<String, dynamic> _networkDetails = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadNetworkDetails();
  }

  Future<void> _loadNetworkDetails() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final provider = Provider.of<WifiProvider>(context, listen: false);
      final details = await provider.getNetworkDetails();
      
      setState(() {
        _networkDetails = details;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _networkDetails = {'Error': 'Failed to load network details'};
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final wifiProvider = Provider.of<WifiProvider>(context);
    final connectedNetwork = wifiProvider.connectedNetwork;

    return RefreshIndicator(
      onRefresh: _loadNetworkDetails,
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(
            child: NetworkStatusBar(
              connectedNetwork: connectedNetwork,
              isScanning: wifiProvider.isScanning,
            ),
          ),
          if (_isLoading)
            const SliverFillRemaining(
              child: Center(
                child: CircularProgressIndicator(),
              ),
            )
          else if (connectedNetwork == null)
            const SliverFillRemaining(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.wifi_off, size: 64, color: Colors.grey),
                    SizedBox(height: 16),
                    Text(
                      'Not connected to any WiFi network',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 16),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Connect to a network to see details',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
              ),
            )
          else
            SliverList(
              delegate: SliverChildListDelegate([
                _buildNetworkDetailsSection(context, connectedNetwork),
                _buildIPDetailsSection(context),
                _buildAdvancedDetailsSection(context),
                const SizedBox(height: 40),
              ]),
            ),
        ],
      ),
    );
  }

  Widget _buildNetworkDetailsSection(BuildContext context, app_model.WifiNetwork network) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Network Details',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: colorScheme.primary.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      'Connected',
                      style: TextStyle(
                        color: colorScheme.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const Divider(),
              _buildDetailItem(
                icon: Icons.wifi,
                title: 'SSID',
                value: network.ssid,
              ),
              _buildDetailItem(
                icon: Icons.perm_device_information,
                title: 'BSSID',
                value: network.bssid,
              ),
              _buildDetailItem(
                icon: Icons.security,
                title: 'Security',
                value: network.getSecurityTypeDisplay(),
              ),
              _buildDetailItem(
                icon: Icons.network_cell,
                title: 'Frequency',
                value: network.getFrequencyBand(),
              ),
              if (network.frequency > 0) _buildDetailItem(
                icon: Icons.router,
                title: 'Channel',
                value: network.getChannel().toString(),
              ),
              _buildDetailItem(
                icon: Icons.signal_cellular_alt,
                title: 'Signal Level',
                value: '${network.level} dBm',
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildIPDetailsSection(BuildContext context) {
    final theme = Theme.of(context);
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'IP Configuration',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Divider(),
              _buildDetailItem(
                icon: Icons.language,
                title: 'IP Address',
                value: _networkDetails['IP Address'] ?? 'Unknown',
              ),
              _buildDetailItem(
                icon: Icons.language_outlined,
                title: 'IPv6 Address',
                value: _networkDetails['IPv6 Address'] ?? 'Unknown',
              ),
              _buildDetailItem(
                icon: Icons.router,
                title: 'Gateway',
                value: _networkDetails['Gateway IP'] ?? 'Unknown',
              ),
              _buildDetailItem(
                icon: Icons.network_check,
                title: 'Subnet Mask',
                value: _networkDetails['Subnet Mask'] ?? 'Unknown',
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAdvancedDetailsSection(BuildContext context) {
    final theme = Theme.of(context);
    
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Advanced Details',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Divider(),
              _buildDetailItem(
                icon: Icons.podcasts,
                title: 'Broadcast',
                value: _networkDetails['Broadcast'] ?? 'Unknown',
              ),
              TextButton.icon(
                onPressed: _loadNetworkDetails,
                icon: const Icon(Icons.refresh),
                label: const Text('Refresh Details'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailItem({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Icon(icon, size: 24, color: Colors.blue),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.grey,
                    fontSize: 12,
                  ),
                ),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
} 