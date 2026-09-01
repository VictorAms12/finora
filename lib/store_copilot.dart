part of 'store.dart';

extension FinanceStoreCopilotSession on FinanceStore {
  void saveCopilotSession({
    required List<CopilotChatMessageItem> messages,
    required String draft,
    required String mode,
    String? pendingTransaction,
  }) {
    final normalizedMessages = messages
        .where((message) => message.text.trim().isNotEmpty)
        .map(
          (message) => CopilotChatMessageItem(
            id: message.id,
            user: message.user,
            text: message.text.trim(),
            followUps: message.followUps
                .where((value) => value.trim().isNotEmpty)
                .take(4)
                .toList(growable: false),
            action: message.action,
            actionLabel: message.actionLabel,
            createdAt: message.createdAt,
          ),
        )
        .toList(growable: true);
    if (normalizedMessages.length > 120) {
      normalizedMessages.removeRange(0, normalizedMessages.length - 120);
    }

    final normalizedDraft = draft.length > 2000
        ? draft.substring(0, 2000)
        : draft;
    final normalizedMode = mode == 'transaction' ? 'transaction' : 'chat';
    final normalizedPending = pendingTransaction?.trim();
    final cleanPending = normalizedPending == null || normalizedPending.isEmpty
        ? null
        : (normalizedPending.length > 4000
              ? normalizedPending.substring(0, 4000)
              : normalizedPending);

    var changed =
        data.copilotChat.length != normalizedMessages.length ||
        data.copilotDraft != normalizedDraft ||
        data.copilotMode != normalizedMode ||
        data.copilotPendingTransaction != cleanPending;

    if (!changed) {
      for (var i = 0; i < normalizedMessages.length; i++) {
        final before = data.copilotChat[i];
        final after = normalizedMessages[i];
        if (before.id != after.id ||
            before.user != after.user ||
            before.text != after.text ||
            before.action != after.action ||
            before.actionLabel != after.actionLabel ||
            before.followUps.join('\u0000') != after.followUps.join('\u0000')) {
          changed = true;
          break;
        }
      }
    }
    if (!changed) return;

    data.copilotChat
      ..clear()
      ..addAll(normalizedMessages);
    data.copilotDraft = normalizedDraft;
    data.copilotMode = normalizedMode;
    data.copilotPendingTransaction = cleanPending;
    data.copilotChatUpdatedAt = DateTime.now();
    commit();
  }

  void clearCopilotSession() {
    if (data.copilotChat.isEmpty &&
        data.copilotDraft.isEmpty &&
        data.copilotPendingTransaction == null &&
        data.copilotMode == 'chat') {
      return;
    }
    data.copilotChat.clear();
    data.copilotDraft = '';
    data.copilotMode = 'chat';
    data.copilotPendingTransaction = null;
    data.copilotChatUpdatedAt = DateTime.now();
    commit();
  }
}
