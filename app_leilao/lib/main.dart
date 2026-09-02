import 'package:flutter/material.dart';
import 'constants/colors.dart';
import 'screens/catalog_screen.dart';
import 'screens/favorites_screen.dart';
import 'screens/admin_screen.dart';
import 'screens/settings_screen.dart';
import 'services/notification_service.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const GeoBuscaImoveisApp());
}

class GeoBuscaImoveisApp extends StatelessWidget {
  const GeoBuscaImoveisApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Geo Busca Imóveis',
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
    NotificationService.checkAlerts();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: screens[currentIndex],
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: AppColors.border, width: 0.8)),
        ),
        child: BottomNavigationBar(
          currentIndex: currentIndex,
          onTap: (idx) => setState(() => currentIndex = idx),
          backgroundColor: AppColors.surface,
          selectedItemColor: AppColors.brandLight,
          unselectedItemColor: AppColors.textDim,
          type: BottomNavigationBarType.fixed,
          selectedFontSize: 11,
          unselectedFontSize: 11,
          elevation: 8,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.apartment_outlined),
              activeIcon: Icon(Icons.apartment),
              label: 'Catálogo',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.favorite_border),
              activeIcon: Icon(Icons.favorite),
              label: 'Favoritos',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.bolt_outlined),
              activeIcon: Icon(Icons.bolt),
              label: 'Rotinas',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.tune_outlined),
              activeIcon: Icon(Icons.tune),
              label: 'Ajustes',
            ),
          ],
        ),
      ),
    );
  }
}
