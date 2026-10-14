import 'package:flutter/material.dart';

import '../domain/auth_exceptions.dart';
import '../domain/login_use_case.dart';
import 'login_texts.dart';
import 'user_model.dart';
import 'widgets/login_form.dart';
import 'widgets/login_success_view.dart';

/// Pantalla de inicio de sesión simulado.
///
/// Las reglas de validación viven en [LoginUseCase]; la pantalla solo muestra
/// el resultado: errores por campo, carga, éxito o error del inicio de sesión.
class LoginScreen extends StatefulWidget {
  const LoginScreen({required this.loginUseCase, super.key});

  final LoginUseCase loginUseCase;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

enum _LoginStatus { idle, loading, success, failure }

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  _LoginStatus _status = _LoginStatus.idle;
  String? _emailError;
  String? _passwordError;
  String? _failureMessage;
  UserModel? _user;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_status == _LoginStatus.loading) {
      return;
    }

    setState(() {
      _status = _LoginStatus.loading;
      _emailError = null;
      _passwordError = null;
      _failureMessage = null;
    });

    try {
      final user = await widget.loginUseCase(
        email: _emailController.text,
        password: _passwordController.text,
      );
      if (!mounted) {
        return;
      }

      setState(() {
        _status = _LoginStatus.success;
        _user = UserModel.fromEntity(user);
      });
    } on LoginValidationException catch (exception) {
      if (!mounted) {
        return;
      }

      final emailError = exception.emailError;
      final passwordError = exception.passwordError;
      setState(() {
        _status = _LoginStatus.idle;
        _emailError = emailError == null
            ? null
            : LoginTexts.emailError(emailError);
        _passwordError = passwordError == null
            ? null
            : LoginTexts.passwordError(passwordError);
      });
    } on InvalidCredentialsException {
      _showFailure(LoginTexts.invalidCredentials);
    } on Object {
      // ServiceUnavailableException y cualquier fallo inesperado se muestran
      // como error técnico: la pantalla nunca queda en carga.
      _showFailure(LoginTexts.serviceUnavailable);
    }
  }

  void _showFailure(String message) {
    if (!mounted) {
      return;
    }

    setState(() {
      _status = _LoginStatus.failure;
      _failureMessage = message;
    });
  }

  void _backToForm() {
    _emailController.clear();
    _passwordController.clear();

    setState(() {
      _status = _LoginStatus.idle;
      _emailError = null;
      _passwordError = null;
      _failureMessage = null;
      _user = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final user = _user;

    return Scaffold(
      appBar: AppBar(title: const Text(LoginTexts.screenTitle)),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: _status == _LoginStatus.success && user != null
                  ? LoginSuccessView(user: user, onBack: _backToForm)
                  : LoginForm(
                      emailController: _emailController,
                      passwordController: _passwordController,
                      isLoading: _status == _LoginStatus.loading,
                      onSubmit: _submit,
                      emailErrorText: _emailError,
                      passwordErrorText: _passwordError,
                      failureMessage: _failureMessage,
                    ),
            ),
          ),
        ),
      ),
    );
  }
}
