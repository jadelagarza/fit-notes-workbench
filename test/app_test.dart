import 'package:fit_notes/app.dart';
import 'package:fit_notes/features/auth/presentation/login_keys.dart';
import 'package:fit_notes/features/auth/presentation/login_texts.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('la aplicación arranca en el inicio de sesión y el resultado '
      'simulado tarda 800 ms (LOGIN-25)', (tester) async {
    await tester.pumpWidget(const FitNotesApp());

    expect(find.byKey(LoginKeys.emailField), findsOneWidget);

    await tester.enterText(
      find.byKey(LoginKeys.emailField),
      'demo@fitnotes.dev',
    );
    await tester.enterText(find.byKey(LoginKeys.passwordField), 'Demo1234');
    await tester.tap(find.byKey(LoginKeys.submitButton));
    await tester.pump();

    expect(find.byKey(LoginKeys.progressIndicator), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 799));
    expect(find.byKey(LoginKeys.progressIndicator), findsOneWidget);
    expect(find.byKey(LoginKeys.successView), findsNothing);

    await tester.pump(const Duration(milliseconds: 1));
    expect(find.byKey(LoginKeys.progressIndicator), findsNothing);
    expect(find.byKey(LoginKeys.successView), findsOneWidget);
    expect(find.text(LoginTexts.welcome('Demo FitNotes')), findsOneWidget);
  });
}
