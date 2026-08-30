import 'package:finora/ai/finance_ai.dart';
import 'package:finora/ai/gemini_service.dart';
import 'package:finora/models.dart';
import 'package:finora/store.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  FinanceStore storeWithData() {
    final store = FinanceStore();
    store.data.accounts.addAll([
      AccountItem(
        id: 'nubank-account',
        name: 'Nubank',
        type: 'Conta digital',
        balance: 842.15,
      ),
      AccountItem(
        id: 'wallet',
        name: 'Carteira',
        type: 'Dinheiro',
        balance: 120,
      ),
    ]);
    store.data.cards.add(
      CardItem(
        id: 'nubank-card',
        name: 'Nubank Card',
        limit: 3000,
        used: 780,
        closeDay: 28,
        dueDay: 5,
      ),
    );
    return store;
  }

  test('saldo de conta conhecida é respondido localmente sem Gemini', () {
    final service = const FinoraAiService();
    final reply = service.tryLocalAnswer(
      storeWithData(),
      'Quanto tenho no Nubank?',
    );

    expect(reply, isNotNull);
    expect(reply!.local, isTrue);
    expect(reply.message, contains('R\$ 842,15'));
    expect(reply.action, AiAssistantAction.showTransactions);
  });

  test('pedido de lançamento em linguagem natural é detectado', () {
    final service = const FinoraAiService();

    expect(
      service.looksLikeTransactionRequest('gastei 32,90 de gasolina no Nubank'),
      isTrue,
    );
    expect(
      service.looksLikeTransactionRequest('quanto gastei com gasolina este mês?'),
      isFalse,
    );
  });

  test('roteador identifica perguntas sobre cartão e planejamento', () {
    final service = const FinoraAiService();

    expect(
      service.detectIntent('Como está a fatura do meu cartão?'),
      AiAssistantIntent.cards,
    );
    expect(
      service.detectIntent('O que vence nos próximos dias?'),
      AiAssistantIntent.planning,
    );
  });

  test('limpeza remove tags, cabeçalhos e rótulos robóticos', () {
    const raw = '''<analysis>interno</analysis>
### Resposta
FINORA IA: Você tem R\$ 500 disponíveis.
''';

    final clean = GeminiService.cleanAssistantText(raw);

    expect(clean, isNot(contains('<analysis>')));
    expect(clean, isNot(contains('###')));
    expect(clean, isNot(contains('FINORA IA:')));
    expect(clean, contains('Você tem R\$ 500 disponíveis.'));
  });
}
