import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'screens/home_screen.dart';
import 'screens/details_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/share_screen.dart';
import 'providers/wifi_provider.dart';
import 'providers/saved_networks_provider.dart';
import 'services/api_service.dart';

// API Configuration
// For physical devices, use the actual laptop IP address
const String apiBaseUrl = 'http://192.168.100.13:5116/api/networks';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Create API service with configuration
    final apiService = ApiService(customBaseUrl: apiBaseUrl);
    
    return MultiProvider(
      providers: [
        // Make ApiService available for later DI
        Provider<ApiService>.value(value: apiService),
        
        ChangeNotifierProvider(create: (context) => WifiProvider()),
        ChangeNotifierProvider(
          create: (context) => SavedNetworksProvider(
            apiService: apiService,
          ),
        ),
      ],
      child: MaterialApp(
        title: 'WiFi Scanner',
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(
            seedColor: Colors.blue,
            brightness: Brightness.light,
          ),
        ),
        darkTheme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(
            seedColor: Colors.blue,
            brightness: Brightness.dark,
          ),
        ),
        themeMode: ThemeMode.system,
        home: const MainScreen(),
      ),
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({Key? key}) : super(key: key);

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;

  final List<Widget> _screens = [
    const HomeScreen(), 
    const DetailsScreen(),
    const ShareScreen(),
    const SettingsScreen()
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_selectedIndex],
      bottomNavigationBar: NavigationBar(
        onDestinationSelected: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        selectedIndex: _selectedIndex,
        destinations: const [
          NavigationDestination(icon: Icon(Icons.wifi), label: 'Scanner'),
          NavigationDestination(
            icon: Icon(Icons.info_outline),
            label: 'Details',
          ),
          NavigationDestination(
            icon: Icon(Icons.share),
            label: 'Share',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}
