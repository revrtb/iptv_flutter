import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'fvp_register_stub.dart' if (dart.library.io) 'fvp_register_impl.dart';
import 'providers/auth_provider.dart';
import 'providers/categories_provider.dart';
import 'providers/streams_provider.dart';
import 'providers/vod_provider.dart';
import 'providers/series_provider.dart';
import 'providers/tmdb_provider.dart';
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  debugPrint = (String? message, {int? wrapWidth}) {};
  registerFvpIfNeeded();
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);
  runApp(const IptvApp());
}

class IptvApp extends StatelessWidget {
  const IptvApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()..loadSavedCredentials()),
        ChangeNotifierProvider(create: (_) => CategoriesProvider()),
        ChangeNotifierProvider(create: (_) => StreamsProvider()),
        ChangeNotifierProvider(create: (_) => VodProvider()),
        ChangeNotifierProvider(create: (_) => SeriesProvider()),
        ChangeNotifierProvider(create: (_) => TmdbProvider()),
      ],
      child: MaterialApp(
        title: 'IPTV Player',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
          useMaterial3: true,
        ),
        home: Consumer<AuthProvider>(
          builder: (context, auth, _) {
            if (auth.isLoading) {
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }
            if (auth.isLoggedIn) {
              return const HomeScreen();
            }
            return const LoginScreen();
          },
        ),
      ),
    );
  }
}
