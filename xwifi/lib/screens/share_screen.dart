import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/saved_networks_provider.dart';
import '../providers/wifi_provider.dart';
import '../models/saved_network.dart';
import '../models/wifi_network.dart' as app_model;
import '../widgets/saved_network_card.dart';

class ShareScreen extends StatefulWidget {
  const ShareScreen({super.key});

  @override
  State<ShareScreen> createState() => _ShareScreenState();
}

class _ShareScreenState extends State<ShareScreen> {
  final _passwordController = TextEditingController();
  final _notesController = TextEditingController();
  bool _showPassword = false;

  @override
  void initState() {
    super.initState();
    // Load networks when screen initializes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<SavedNetworksProvider>(context, listen: false).loadNetworks();
    });
  }

  @override
  void dispose() {
    _passwordController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<WifiProvider, SavedNetworksProvider>(
      builder: (context, wifiProvider, savedNetworksProvider, child) {
        final connectedNetwork = wifiProvider.connectedNetwork;
        
        return Scaffold(
          appBar: AppBar(
            title: const Text('Share WiFi'),
          ),
          body: RefreshIndicator(
            onRefresh: () => savedNetworksProvider.loadNetworks(),
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                // Section 1: Currently Connected Network
                SliverToBoxAdapter(
                  child: Card(
                    margin: const EdgeInsets.all(16),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Currently Connected Network',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),
                          const SizedBox(height: 16),
                          if (connectedNetwork == null)
                            const Text('Not connected to any WiFi network')
                          else
                            _buildConnectedNetworkInfo(context, connectedNetwork, savedNetworksProvider),
                        ],
                      ),
                    ),
                  ),
                ),
                
                // Section 2: Saved Networks
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Saved Networks',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.refresh),
                          onPressed: () => savedNetworksProvider.loadNetworks(),
                          tooltip: 'Refresh',
                        ),
                      ],
                    ),
                  ),
                ),
                
                if (savedNetworksProvider.isLoading)
                  const SliverToBoxAdapter(
                    child: Center(
                      child: Padding(
                        padding: EdgeInsets.all(16.0),
                        child: CircularProgressIndicator(),
                      ),
                    ),
                  )
                else if (savedNetworksProvider.networks.isEmpty)
                  const SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Center(
                        child: Text('No saved networks'),
                      ),
                    ),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.all(8.0),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final network = savedNetworksProvider.networks[index];
                          return Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8.0,
                              vertical: 4.0,
                            ),
                            child: SavedNetworkCard(
                              network: network,
                              onConnect: () => _connectToNetwork(context, network),
                              onDelete: () => _deleteNetwork(context, network),
                            ),
                          );
                        },
                        childCount: savedNetworksProvider.networks.length,
                      ),
                    ),
                  ),
                
                if (savedNetworksProvider.errorMessage.isNotEmpty)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Text(
                        savedNetworksProvider.errorMessage,
                        style: const TextStyle(color: Colors.red),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildConnectedNetworkInfo(
    BuildContext context, 
    app_model.WifiNetwork network, 
    SavedNetworksProvider savedNetworksProvider
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.wifi, size: 24),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    network.ssid,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Security: ${network.getSecurityTypeDisplay()}',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.secondary,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        
        // Password input
        TextField(
          controller: _passwordController,
          decoration: InputDecoration(
            labelText: 'Password (Optional)',
            hintText: 'Enter WiFi password',
            suffixIcon: IconButton(
              icon: Icon(_showPassword ? Icons.visibility_off : Icons.visibility),
              onPressed: () => setState(() => _showPassword = !_showPassword),
            ),
            border: const OutlineInputBorder(),
          ),
          obscureText: !_showPassword,
        ),
        const SizedBox(height: 16),
        
        // Notes input
        TextField(
          controller: _notesController,
          decoration: const InputDecoration(
            labelText: 'Notes (Optional)',
            hintText: 'Add notes about this network',
            border: OutlineInputBorder(),
          ),
          maxLines: 2,
        ),
        const SizedBox(height: 16),
        
        // Single save button
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () => _saveNetworkInfo(context, network, savedNetworksProvider),
            icon: const Icon(Icons.save),
            label: const Text('SAVE NETWORK'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green.shade700,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        ),
      ],
    );
  }

  void _saveNetworkInfo(
    BuildContext context, 
    app_model.WifiNetwork network,
    SavedNetworksProvider savedNetworksProvider
  ) async {
    // Show loading indicator
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Saving network...'),
        duration: Duration(seconds: 1),
      ),
    );

    final password = _passwordController.text.trim();
    final notes = _notesController.text.trim();
    
    try {
      // Use the single saveNetwork method - pass null or empty password to save a basic network
      debugPrint('Saving network: ${network.ssid}');
      debugPrint('Password: ${password.isEmpty ? "None" : "Provided"}');
      debugPrint('Notes: ${notes.isEmpty ? "None" : notes}');
      
      final result = await savedNetworksProvider.saveNetwork(
        network: network,
        password: password.isEmpty ? null : password, // Pass null if password is empty
        notes: notes,
      );
      
      if (result) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 10),
                Text('${network.ssid} saved successfully'),
              ],
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
        _passwordController.clear();
        _notesController.clear();
        
        // Reload networks to update the list
        debugPrint('Reloading networks after successful save');
        await savedNetworksProvider.loadNetworks();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error, color: Colors.white),
                const SizedBox(width: 10),
                Text('Failed to save ${network.ssid}'),
              ],
            ),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      debugPrint('Error in _saveNetworkInfo: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error, color: Colors.white),
              const SizedBox(width: 10),
              const Text('Error saving network'),
            ],
          ),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  void _connectToNetwork(BuildContext context, SavedNetwork network) async {
    // Skip connect if no password
    if (network.password == null || network.password!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Cannot connect to ${network.ssid} - no password saved')),
      );
      return;
    }
    
    final wifiProvider = Provider.of<WifiProvider>(context, listen: false);
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    
    try {
      // Use non-null assertion operator after null check
      final result = await wifiProvider.connectToNetwork(
        network.ssid, 
        network.password! // We already checked for null above
      );
      
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
    } catch (e) {
      debugPrint('Error connecting to network: $e');
      scaffoldMessenger.showSnackBar(
        SnackBar(
          content: Text('Error connecting to ${network.ssid}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _deleteNetwork(BuildContext context, SavedNetwork network) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Network'),
        content: Text('Are you sure you want to delete ${network.ssid}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('CANCEL'),
          ),
          TextButton(
            onPressed: () async {
              final provider = Provider.of<SavedNetworksProvider>(
                context, 
                listen: false
              );
              await provider.deleteNetwork(network.id);
              // Reload networks after deletion
              provider.loadNetworks();
              Navigator.of(context).pop();
            },
            child: const Text('DELETE'),
          ),
        ],
      ),
    );
  }
} 