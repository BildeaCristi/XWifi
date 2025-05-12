import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/wifi_provider.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final wifiProvider = Provider.of<WifiProvider>(context);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 8),
                Text(
                  'App Settings',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 24),
                _buildSettingsCard(
                  context,
                  title: 'Permissions',
                  icon: Icons.security,
                  children: [
                    _buildPermissionItem(
                      context,
                      icon: Icons.location_on,
                      title: 'Location',
                      subtitle: 'Required for WiFi scanning',
                      onTap: () async {
                        await wifiProvider.requestPermissions();
                      },
                    ),
                    const Divider(),
                    _buildPermissionItem(
                      context,
                      icon: Icons.wifi,
                      title: 'Nearby WiFi Devices',
                      subtitle: 'Required for finding networks',
                      onTap: () async {
                        await wifiProvider.requestPermissions();
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _buildSettingsCard(
                  context,
                  title: 'About',
                  icon: Icons.info_outline,
                  children: [
                    ListTile(
                      title: const Text('App Version'),
                      subtitle: const Text('1.0.0'),
                      leading: const Icon(Icons.android),
                    ),
                    const Divider(),
                    ListTile(
                      title: const Text('Developer'),
                      subtitle: const Text('XWifi Team'),
                      leading: const Icon(Icons.code),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _buildSettingsCard(
                  context,
                  title: 'Legal',
                  icon: Icons.gavel,
                  children: [
                    ListTile(
                      title: const Text('Privacy Policy'),
                      leading: const Icon(Icons.privacy_tip),
                      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                      onTap: () {
                        // Show privacy policy
                      },
                    ),
                    const Divider(),
                    ListTile(
                      title: const Text('Terms of Service'),
                      leading: const Icon(Icons.description),
                      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                      onTap: () {
                        // Show terms of service
                      },
                    ),
                    const Divider(),
                    ListTile(
                      title: const Text('Open Source Licenses'),
                      leading: const Icon(Icons.source),
                      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                      onTap: () {
                        // Show licenses
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 32),
                Center(
                  child: Text(
                    '© 2023 XWifi',
                    style: TextStyle(
                      color: colorScheme.onSurface.withOpacity(0.5),
                      fontSize: 12,
                    ),
                  ),
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSettingsCard(
    BuildContext context, {
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    final theme = Theme.of(context);
    
    return Card(
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
              children: [
                Icon(icon, color: theme.colorScheme.primary),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildPermissionItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: Row(
          children: [
            Icon(icon, color: Theme.of(context).colorScheme.primary),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
            ),
          ],
        ),
      ),
    );
  }
} 