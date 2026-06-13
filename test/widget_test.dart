import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:splitico/features/auth/bloc/auth_bloc.dart';
import 'package:splitico/features/auth/repository/auth_repository.dart';
import 'package:splitico/main.dart';

void main() {
  testWidgets('App renders login screen initially', (WidgetTester tester) async {
    // Build our app and trigger a frame with the necessary BlocProvider.
    await tester.pumpWidget(
      BlocProvider(
        create: (_) => AuthBloc(AuthRepository()),
        child: const MyApp(),
      ),
    );

    // Verify that the login screen is displayed by checking for the welcome header.
    expect(find.text('Welcome back'), findsOneWidget);
    expect(find.byType(TextFormField), findsNWidgets(2)); // Email & Password
    expect(find.text('Sign In'), findsOneWidget);
  });

  testWidgets('App can toggle to Create Account screen and back to Sign In', (WidgetTester tester) async {
    await tester.pumpWidget(
      BlocProvider(
        create: (_) => AuthBloc(AuthRepository()),
        child: const MyApp(),
      ),
    );

    // Verify initially we are on Sign In
    expect(find.text('Welcome back'), findsOneWidget);
    expect(find.text('Sign Up'), findsOneWidget);

    // Tap "Sign Up" to switch to Create Account
    await tester.ensureVisible(find.text('Sign Up'));
    await tester.tap(find.text('Sign Up'));
    await tester.pumpAndSettle();

    // Verify Create Account screen elements
    expect(find.text('Create account'), findsOneWidget);
    expect(find.text('Join thousands splitting smarter'), findsOneWidget);
    expect(find.text('FULL NAME'), findsOneWidget);
    expect(find.text('EMAIL'), findsOneWidget);
    expect(find.text('PASSWORD'), findsOneWidget);
    expect(find.text('Strong password'), findsOneWidget);
    expect(find.text('Create Account'), findsOneWidget);
    expect(find.text('Already have an account? '), findsOneWidget);

    // Verify that inputs are empty
    final nameField = tester.widget<TextFormField>(
      find.ancestor(
        of: find.text('Enter your full name'),
        matching: find.byType(TextFormField),
      ),
    );
    expect(nameField.controller?.text, isEmpty);

    // Tap the back arrow to return to Sign In
    await tester.ensureVisible(find.byIcon(Icons.arrow_back_rounded));
    await tester.tap(find.byIcon(Icons.arrow_back_rounded));
    await tester.pumpAndSettle();

    // Verify we are back on Sign In
    expect(find.text('Welcome back'), findsOneWidget);
  });
}
