import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:splitico/features/group/bloc/group_bloc.dart';
import 'package:splitico/features/auth/bloc/auth_bloc.dart';
import 'package:splitico/features/auth/repository/auth_repository.dart';
import 'package:splitico/features/auth/presentation/login_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  runApp(
    MultiBlocProvider(
      providers: [
        BlocProvider<AuthBloc>(create: (_) => AuthBloc(AuthRepository())),
        BlocProvider<GroupBloc>(create: (_) => GroupBloc()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Splitico',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const LoginScreen(),
    );
  }
}
