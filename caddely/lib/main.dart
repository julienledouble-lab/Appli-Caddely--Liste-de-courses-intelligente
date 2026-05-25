import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';
import 'providers/app_preferences_provider.dart';
import 'providers/grocery_provider.dart';
import 'providers/history_provider.dart';
import 'providers/recipes_provider.dart';
import 'providers/store_preferences_provider.dart';
import 'screens/app_root.dart';
import 'services/storage_service.dart';
import 'theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('fr_FR', null);

  final storage = StorageService();
  final groceryProvider = GroceryProvider(storage);
  final historyProvider = HistoryProvider(storage);
  final recipesProvider = RecipesProvider(storage);
  final storePreferencesProvider = StorePreferencesProvider(storage);
  final appPreferencesProvider = AppPreferencesProvider(storage);

  await Future.wait([
    groceryProvider.load(),
    historyProvider.load(),
    recipesProvider.load(),
    storePreferencesProvider.load(),
    appPreferencesProvider.load(),
  ]);

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: groceryProvider),
        ChangeNotifierProvider.value(value: historyProvider),
        ChangeNotifierProvider.value(value: recipesProvider),
        ChangeNotifierProvider.value(value: storePreferencesProvider),
        ChangeNotifierProvider.value(value: appPreferencesProvider),
      ],
      child: const CaddelyApp(),
    ),
  );
}

class CaddelyApp extends StatelessWidget {
  const CaddelyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Caddely',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      home: const AppRoot(),
    );
  }
}
