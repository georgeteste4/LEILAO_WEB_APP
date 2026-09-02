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
          error: AppColors.discount,
        ),
        dividerTheme: const DividerThemeData(
          color: AppColors.border,
          thickness: 0.8,
        ),
        cardTheme: const CardTheme(
          color: AppColors.surface,
          elevation: 0,
          margin: EdgeInsets.zero,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: AppColors.canvas,
          elevation: 0,
          centerTitle: false,
          iconTheme: IconThemeData(color: AppColors.textMain),
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
          color: AppColors.canvas,
          border: Border(top: BorderSide(color: AppColors.border, width: 0.9)),
        ),
        child: NavigationBarTheme(
          data: NavigationBarThemeData(
            height: 62,
            backgroundColor: AppColors.canvas,
            indicatorColor: AppColors.surfaceElevated,
            labelTextStyle: MaterialStateProperty.resolveWith((states) {
              if (states.contains(MaterialState.selected)) {
                return const TextStyle(color: AppColors.brandLight, fontSize: 11, fontWeight: FontWeight.bold);
              }
              return const TextStyle(color: AppColors.textDim, fontSize: 11);
            }),
            iconTheme: MaterialStateProperty.resolveWith((states) {
              if (states.contains(MaterialState.selected)) {
                return const IconThemeData(color: AppColors.brandLight, size: 22);
              }
              return const IconThemeData(color: AppColors.textDim, size: 20);
            }),
          ),
          child: NavigationBar(
            selectedIndex: currentIndex,
            onDestinationSelected: (idx) => setState(() => currentIndex = idx),
            destinations: const [
              NavigationDestination(
                icon: Icon(Icons.home_work_outlined),
                selectedIcon: Icon(Icons.home_work),
                label: 'Catálogo',
              ),
              NavigationDestination(
                icon: Icon(Icons.favorite_border),
                selectedIcon: Icon(Icons.favorite),
                label: 'Favoritos',
              ),
              NavigationDestination(
                icon: Icon(Icons.sync_alt_outlined),
                selectedIcon: Icon(Icons.sync_alt),
                label: 'Rotinas',
              ),
              NavigationDestination(
                icon: Icon(Icons.tune_outlined),
                selectedIcon: Icon(Icons.tune),
                label: 'Ajustes',
              ),
            ],
          ),
        ),
      ),
    );
  }
}
