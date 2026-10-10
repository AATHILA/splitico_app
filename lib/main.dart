import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:splitico/core/services/preferences_service.dart';
import 'package:splitico/core/theme/app_theme.dart';
import 'package:splitico/core/theme/theme_cubit.dart';
import 'package:splitico/features/group/bloc/group_bloc.dart';
import 'package:splitico/features/group/bloc/group_event.dart';
import 'package:splitico/features/group/repository/group_repository.dart';
import 'package:splitico/features/auth/bloc/auth_bloc.dart';
import 'package:splitico/features/auth/repository/auth_repository.dart';
import 'package:splitico/features/auth/presentation/login_screen.dart';
import 'package:splitico/features/home/pages/home_page.dart';
import 'package:splitico/core/services/payment_reminder_service.dart';
import 'package:splitico/core/services/settlement_storage_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:splitico/features/auth/bloc/auth_event.dart';


void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await PreferencesService().init();
  await dotenv.load(fileName: ".env");

  await Supabase.initialize(
    url: dotenv.env['SUPABASE_URL']!,
    anonKey: dotenv.env['SUPABASE_KEY']!,
  );

  await SettlementStorageService.init();
  await PaymentReminderService.initialize();

  // Check if user is already logged in (persisted session)
  final currentUser = Supabase.instance.client.auth.currentUser;
  final isLoggedIn = currentUser != null || PreferencesService().getBool(PreferencesService.keyIsLoggedIn);

  runApp(
    MultiBlocProvider(
      providers: [
        BlocProvider<ThemeCubit>(create: (_) => ThemeCubit()),
       // BlocProvider<AuthBloc>(create: (_) => AuthBloc(AuthRepository())),
        BlocProvider<AuthBloc>(
  create: (_) => AuthBloc(AuthRepository())..add(AuthCheckRequested()),
),
        BlocProvider<GroupBloc>(
          create: (_) => GroupBloc(GroupRepository())..add(LoadGroups()),
        ),
      ],
      child: MyApp(isLoggedIn: isLoggedIn),
    ),
  );
}

class MyApp extends StatelessWidget {
  final bool isLoggedIn;
  const MyApp({super.key, required this.isLoggedIn});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ThemeCubit, ThemeMode>(
      builder: (context, themeMode) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'Splitico',
          themeMode: themeMode,
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          home: isLoggedIn ? const HomePage() : const LoginScreen(),
        );
      },
    );
  }
}