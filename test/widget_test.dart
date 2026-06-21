import 'package:flutter_test/flutter_test.dart';
import 'package:gerelat_frontend/main.dart';

void main() {
  testWidgets('exibe tela de login quando nao ha sessao', (tester) async {
    await tester.pumpWidget(const AplicativoGeRelat());
    await tester.pumpAndSettle();

    expect(find.text('Bem-vindo de volta'), findsOneWidget);
  });
}
