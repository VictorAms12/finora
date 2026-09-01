import 'dart:convert';

import 'package:finora/ai/copilot.dart';
import 'package:finora/models.dart';
import 'package:finora/store.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  FinanceStore storeWithAccount({double balance = 3000}) {
    final store = FinanceStore();
    store.data.accounts.add(
      AccountItem(
        id: 'acc-1',
        name: 'Conta Principal',
        type: 'Conta digital',
        balance: balance,
      ),
    );
    return store;
  }

  test('memória do Copilot faz parte do estado persistente e do backup', () {
    final store = storeWithAccount();
    expect(
      store.rememberCopilot(
        'Conta do salário',
        'Meu salário normalmente cai na Conta Principal.',
      ),
      isTrue,
    );

    final restored = FinanceData.fromJson(
      Map<String, dynamic>.from(jsonDecode(store.data.encode()) as Map),
    );

    expect(restored.copilotMemoryEnabled, isTrue);
    expect(restored.copilotMemories, hasLength(1));
    expect(restored.copilotMemories.single.label, 'Conta do salário');
    expect(
      restored.copilotMemories.single.value,
      'Meu salário normalmente cai na Conta Principal.',
    );
  });

  test('desativar memória não apaga lembranças existentes', () {
    final store = storeWithAccount();
    store.rememberCopilot('Preferência', 'Prefiro respostas diretas.');
    store.setCopilotMemoryEnabled(false);

    expect(store.data.copilotMemoryEnabled, isFalse);
    expect(store.data.copilotMemories, hasLength(1));
  });

  test('simulador parcelado usa projeções sem alterar dados financeiros', () {
    final store = storeWithAccount(balance: 2500);
    final before = store.cashBalance;

    final result = const FinancialQueryEngine().answer(
      store,
      'Posso comprar um celular de R\$ 1200 em 6x?',
    );

    expect(result, isNotNull);
    expect(result!.message, contains('6x'));
    expect(result.message, contains('R\$ 200,00'));
    expect(store.cashBalance, before);
    expect(store.data.transactions, isEmpty);
  });

  test('consulta local identifica maior categoria do mês', () {
    final store = storeWithAccount();
    final now = DateTime.now();
    store.addTransaction(
      TransactionItem(
        id: 'food',
        type: TransactionType.expense,
        title: 'Mercado',
        category: 'Alimentação',
        amount: 350,
        date: now,
        account: 'Conta Principal',
      ),
    );
    store.addTransaction(
      TransactionItem(
        id: 'transport',
        type: TransactionType.expense,
        title: 'Combustível',
        category: 'Transporte',
        amount: 100,
        date: now,
        account: 'Conta Principal',
      ),
    );

    final result = const FinancialQueryEngine().answer(
      store,
      'Onde estou gastando mais?',
    );

    expect(result, isNotNull);
    expect(result!.message, contains('Alimentação'));
    expect(result.message, contains('R\$ 350,00'));
  });

  test('ação do Copilot só muda orçamento quando aplicada', () {
    final store = storeWithAccount();
    const proposal = CopilotActionProposal(
      type: CopilotActionType.createBudget,
      title: 'Orçamento de Alimentação',
      summary: 'Limite mensal de R\$ 500,00 para Alimentação',
      amount: 500,
      category: 'Alimentação',
    );

    expect(store.data.budgets, isEmpty);
    expect(proposal.apply(store), isTrue);
    expect(store.data.budgets.single.category, 'Alimentação');
    expect(store.data.budgets.single.limit, 500);
  });

  test('ação prevista valida conta antes de escrever no planejamento', () {
    final store = storeWithAccount();
    final tomorrow = DateTime.now().add(const Duration(days: 1));
    final proposal = CopilotActionProposal(
      type: CopilotActionType.createPlanned,
      title: 'Internet',
      summary: 'Pagar R\$ 100,00 amanhã',
      amount: 100,
      category: 'Serviços',
      date: tomorrow,
      sourceName: 'Conta Principal',
    );

    expect(proposal.apply(store), isTrue);
    expect(store.data.planned, hasLength(1));
    expect(store.data.planned.single.title, 'Internet');
    expect(store.data.planned.single.sourceName, 'Conta Principal');
  });
}
