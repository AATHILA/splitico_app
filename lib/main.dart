import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:splitico/core/theme/app_theme.dart';
import 'package:splitico/core/theme/theme_cubit.dart';
import 'package:splitico/features/group/bloc/group_bloc.dart';
import 'package:splitico/features/group/bloc/group_event.dart';
import 'package:splitico/features/group/repository/group_repository.dart';
import 'package:splitico/features/auth/bloc/auth_bloc.dart';
import 'package:splitico/features/auth/repository/auth_repository.dart';
import 'package:splitico/features/auth/presentation/login_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(
    url: "https://ywuoycwwtvynagrukdow.supabase.co",
    anonKey: "sb_publishable_XM2f_-CC6lDsGnD2eTiZXA_TDpImgKJ",
  );
  runApp(
    MultiBlocProvider(
      providers: [
        BlocProvider<ThemeCubit>(create: (_) => ThemeCubit()),
        BlocProvider<AuthBloc>(create: (_) => AuthBloc(AuthRepository())),
        BlocProvider<GroupBloc>(
          create: (_) => GroupBloc(GroupRepository())..add(LoadGroups()),
        ),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

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
      home: const LoginScreen(),
      
    );
      
  }
     );
}
}