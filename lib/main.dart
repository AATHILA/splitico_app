import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
// import 'package:firebase_core/firebase_core.dart';
// import 'package:splitico/firebase_options.dart';
import 'package:splitico/features/auth/bloc/auth_bloc.dart';
import 'package:splitico/features/auth/repository/auth_repository.dart';
import 'package:splitico/features/auth/presentation/login_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // TODO: Re-enable Firebase initialization for backend integration.
  // Disabled Firebase initialization for local UI-only testing on physical devices.
  // await Firebase.initializeApp(
  //   options: DefaultFirebaseOptions.currentPlatform,
  // );
  runApp(
    BlocProvider(
      create: (_) => AuthBloc(AuthRepository()),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Splitico',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const LoginScreen(),
    );
  }
}
