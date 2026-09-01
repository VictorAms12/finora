part of 'store.dart';

extension FinanceStoreDiagnostics on FinanceStore {
  List<String> get dataHealthIssues {
    final issues = <String>[];

    void duplicateIds(String label, Iterable<String> ids) {
      final seen = <String>{};
      for (final id in ids) {
        if (!seen.add(id)) {
          issues.add('$label possui identificador duplicado.');
          return;
        }
      }
    }

    duplicateIds('Contas', data.accounts.map((e) => e.id));
    duplicateIds('Cartões', data.cards.map((e) => e.id));
    duplicateIds('Movimentações', data.transactions.map((e) => e.id));
    duplicateIds('Planejamentos', data.planned.map((e) => e.id));
    duplicateIds('Metas', data.goals.map((e) => e.id));
    duplicateIds('Reservas', data.reserves.map((e) => e.id));
    duplicateIds('Recorrências', data.recurringRules.map((e) => e.id));
    duplicateIds('Parcelamentos', data.installmentPlans.map((e) => e.id));

    for (final account in data.accounts) {
      if (!account.balance.isFinite) {
        issues.add('A conta ${account.name} possui saldo inválido.');
      }
    }
    for (final card in data.cards) {
      if (!card.limit.isFinite ||
          !card.used.isFinite ||
          card.limit < 0 ||
          card.used < 0) {
        issues.add('O cartão ${card.name} possui limite ou fatura inválidos.');
      }
    }
    for (final tx in data.transactions) {
      if (!tx.amount.isFinite || tx.amount <= 0) {
        issues.add('A movimentação ${tx.title} possui valor inválido.');
        continue;
      }
      if (tx.type == TransactionType.transfer) {
        final pair = transferAccounts(tx);
        if (pair == null ||
            findAccount(pair[0]) == null ||
            findAccount(pair[1]) == null) {
          issues.add(
            'A transferência ${tx.title} referencia uma conta inexistente.',
          );
        }
      } else if (tx.paymentKind == PaymentKind.card &&
          tx.type == TransactionType.expense) {
        if (findCard(tx.cardId) == null) {
          issues.add('A compra ${tx.title} referencia um cartão inexistente.');
        }
      } else if (findAccount(tx.account) == null) {
        issues.add(
          'A movimentação ${tx.title} referencia uma conta inexistente.',
        );
      }
    }

    for (final planned in data.planned.where(
      (e) => e.status == PlannedStatus.planned,
    )) {
      if (!planned.amount.isFinite || planned.amount <= 0) {
        issues.add('O previsto ${planned.title} possui valor inválido.');
      }
      if (planned.paymentKind == PaymentKind.card &&
          planned.type == TransactionType.expense) {
        if (findCard(planned.cardId) == null) {
          issues.add(
            'O previsto ${planned.title} referencia um cartão inexistente.',
          );
        }
      } else if (planned.sourceName.isNotEmpty &&
          findAccount(planned.sourceName) == null) {
        issues.add(
          'O previsto ${planned.title} referencia uma conta inexistente.',
        );
      }
    }

    final snapshotMonths = <String>{};
    for (final snapshot in data.snapshots) {
      final key = '${snapshot.month.year}-${snapshot.month.month}';
      if (!snapshotMonths.add(key)) {
        issues.add(
          'Há mais de um fechamento salvo para ${snapshot.month.month}/${snapshot.month.year}.',
        );
      }
      if (!snapshot.openingBalance.isFinite ||
          !snapshot.closingBalance.isFinite ||
          !snapshot.income.isFinite ||
          !snapshot.expense.isFinite) {
        issues.add('Um fechamento mensal possui valores inválidos.');
      }
    }

    if (data.copilotChat.length > 120) {
      issues.add('O histórico do Copilot ultrapassou o limite local esperado.');
    }

    return issues.take(30).toList(growable: false);
  }
}
