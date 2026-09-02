import 'package:flutter/material.dart';
import 'constants/colors.dart';
import 'screens/catalog_screen.dart';
import 'screens/favorites_screen.dart';
import 'screens/admin_screen.dart';
import 'screens/settings_screen.dart';
import 'services/notification_service.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const LeilaoApp());
}

class LeilaoApp extends StatelessWidget {
  const LeilaoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Leilão de Imóveis',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: AppColors.canvas,
        primaryColor: AppColors.brand,
        colorScheme: const ColorScheme.dark(
          primary: AppColors.brand,
          surface: AppColors.surface,
          background: AppColors.canvas,
        ),
      ),
      home: const MainNavigationScreen(),
    );
  }
}

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int currentIndex = 0;

  final screens = const [
    CatalogScreen(),
    FavoritesScreen(),
    AdminScreen(),
    SettingsScreen(),
  ];

  @override
  void initState() {
    super.initState();
    // Verificar alertas ao iniciar o aplicativo
    NotificationService.checkAlerts();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: screens[currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: currentIndex,
        onTap: (idx) => setState(() => currentIndex = idx),
        backgroundColor: AppColors.surface,
        selectedItemColor: AppColors.brandLight,
        unselectedItemColor: AppColors.textDim,
        type: BottomNavigationBarType.fixed,
        selectedFontSize: 11,
        unselectedFontSize: 11,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home_outlined), activeIcon: Icon(Icons.home), label: 'Catálogo'),
          BottomNavigationBarItem(icon: Icon(Icons.favorite_border), activeIcon: Icon(Icons.favorite), label: 'Favoritos'),
          BottomNavigationBarItem(icon: Icon(Icons.flash_on_outlined), activeIcon: Icon(Icons.flash_on), label: 'Rotinas'),
          BottomNavigationBarItem(icon: Icon(Icons.settings_outlined), activeIcon: Icon(Icons.settings), label: 'Configurações'),
        ],
      ),
    );
  }
}
