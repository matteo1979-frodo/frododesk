// lib/main.dart
import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'logic/core_store.dart';
import 'logic/ips_store.dart';
import 'screens/home_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('it_IT', null);

  final coreStore = CoreStore();
  await coreStore.init();

  runApp(FrodoDeskApp(coreStore: coreStore));
}

class FrodoDeskApp extends StatefulWidget {
  final CoreStore coreStore;

  const FrodoDeskApp({super.key, required this.coreStore});

  @override
  State<FrodoDeskApp> createState() => _FrodoDeskAppState();
}

class _FrodoDeskAppState extends State<FrodoDeskApp> {
  late final CoreStore coreStore;
  late final IpsStore ipsStore;

  @override
  void initState() {
    super.initState();
    coreStore = widget.coreStore;
    ipsStore = coreStore.ipsStore;
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'FrodoDesk',
      theme: ThemeData(useMaterial3: true),

      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('it', 'IT'), Locale('en', 'US')],
      locale: const Locale('it', 'IT'),

      home: HomeScreen(ipsStore: ipsStore, coreStore: coreStore),
    );
  }
}
