import 'package:flutter/material.dart';

import 'features/auth/data/mock_auth_repository.dart';
import 'features/auth/domain/login_use_case.dart';
import 'features/auth/presentation/login_screen.dart';
import 'features/auth/presentation/login_texts.dart';

/// Retardo del inicio de sesión simulado en la aplicación.
const Duration simulatedLoginLatency = Duration(milliseconds: 800);

/// Raíz de la aplicación y de composición: es el único lugar que conoce la
/// implementación simulada del repositorio de autenticación.
class FitNotesApp extends StatelessWidget {
  const FitNotesApp({super.key});

  static const LoginUseCase _loginUseCase = LoginUseCase(
    MockAuthRepository(latency: simulatedLoginLatency),
  );

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: LoginTexts.appTitle,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
      ),
      home: const LoginScreen(loginUseCase: _loginUseCase),
    );
  }
}
