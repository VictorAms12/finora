import 'dart:convert';

import 'package:finora/models.dart';
import 'package:finora/store.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  FinanceStore baseStore() {
    final store = FinanceStore();
    store.data.accounts.add(
      AccountItem(
        id: 'account-1',
        name: 'Principal',
        type: 'Conta',
        balance: 2500,
      ),
    );
    return store;
  }

  test('sessão do Copilot sobrevive a encode/decode completo', () {
    final store = baseStore();
    store.saveCopilotSession(
      messages: [
        CopilotChatMessageItem(
          id: 'm1',
          user: true,
          text: 'Quanto posso gastar?',
          createdAt: DateTime(2026, 9, 1, 12),
        ),
        CopilotChatMessageItem(
          id: 'm2',
          user: false,
          text: 'Você tem um valor disponível.',
          followUps: const ['Ver planejamento'],
          action: 'showPlanning',
          createdAt: DateTime(2026, 9, 1, 12, 1),
        ),
      ],
      draft: 'e no mês passado?',
      mode: 'transaction',
      pendingTransaction: 'gastei 30 de gasolina',
    );

    final restored = FinanceData.fromJson(
      Map<String, dynamic>.from(jsonDecode(store.data.encode()) as Map),
    );

    expect(restored.copilotChat, hasLength(2));
    expect(restored.copilotChat.last.action, 'showPlanning');
    expect(restored.copilotDraft, 'e no mês passado?');
    expect(restored.copilotMode, 'transaction');
    expect(restored.copilotPendingTransaction, 'gastei 30 de gasolina');
  });

  test('dados antigos sem campos de chat continuam compatíveis', () {
    final old = <String, dynamic>{
      'darkMode': true,
      'accounts': <dynamic>[],
      'cards': <dynamic>[],
      'transactions': <dynamic>[],
      'planned': <dynamic>[],
      'budgets': <dynamic>[],
      'goals': <dynamic>[],
      'reserves': <dynamic>[],
      'investments': <dynamic>[],
      'recurringRules': <dynamic>[],
      'installmentPlans': <dynamic>[],
      'categories': <dynamic>[],
      'snapshots': <dynamic>[],
    };

    final restored = FinanceData.fromJson(old);
    expect(restored.copilotChat, isEmpty);
    expect(restored.copilotDraft, isEmpty);
    expect(restored.copilotMode, 'chat');
  });

  test('histórico do Copilot é limitado às 120 mensagens mais recentes', () {
    final store = baseStore();
    final messages = List.generate(
      150,
      (index) => CopilotChatMessageItem(
        id: '$index',
        user: index.isEven,
        text: 'mensagem $index',
        createdAt: DateTime(2026, 9, 1).add(Duration(minutes: index)),
      ),
    );

    store.saveCopilotSession(messages: messages, draft: '', mode: 'chat');

    expect(store.data.copilotChat, hasLength(120));
    expect(store.data.copilotChat.first.text, 'mensagem 30');
    expect(store.data.copilotChat.last.text, 'mensagem 149');
  });

  test('limpar conversa não altera dados financeiros', () {
    final store = baseStore();
    store.saveCopilotSession(
      messages: [
        CopilotChatMessageItem(
          id: 'm1',
          user: true,
          text: 'teste',
          createdAt: DateTime.now(),
        ),
      ],
      draft: 'rascunho',
      mode: 'chat',
    );

    store.clearCopilotSession();

    expect(store.data.copilotChat, isEmpty);
    expect(store.data.accounts.single.balance, 2500);
  });

  test('diagnóstico detecta referência órfã sem modificar o estado', () {
    final store = baseStore();
    store.data.transactions.add(
      TransactionItem(
        id: 'bad',
        type: TransactionType.expense,
        title: 'Órfã',
        category: 'Outros',
        amount: 10,
        date: DateTime.now(),
        account: 'Conta inexistente',
      ),
    );

    final before = store.data.encode();
    final issues = store.dataHealthIssues;

    expect(issues.any((issue) => issue.contains('conta inexistente')), isTrue);
    expect(store.data.encode(), before);
  });

  test('insights são determinísticos e não alteram finanças', () {
    final store = baseStore();
    final now = DateTime.now();
    store.data.budgets.add(
      BudgetItem(id: 'b1', category: 'Alimentação', limit: 100),
    );
    store.data.transactions.add(
      TransactionItem(
        id: 'food',
        type: TransactionType.expense,
        title: 'Mercado',
        category: 'Alimentação',
        amount: 90,
        date: now,
        account: 'Principal',
      ),
    );
    final before = store.data.encode();

    final insights = store.smartInsights;

    expect(insights, isNotEmpty);
    expect(store.data.encode(), before);
  });
}
