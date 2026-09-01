# Finora v0.4.4 — Reserva de emergência

- Reduzir o valor-alvo não reduz mais silenciosamente o valor já guardado.
- A reserva pode ficar acima da meta sem perder o excedente.
- Aportes deixam de ser truncados quando atingem o valor-alvo.
- Reservas agora aceitam retirada controlada, sem permitir saldo negativo.
- Edição valida alvo, valor guardado e meses de proteção com mensagens claras.
- Meses de proteção passam a aceitar somente inteiros entre 1 e 60.
- A tela diferencia meta, valor guardado, cobertura, valor restante e excedente.
- O app deixa explícito que reserva é um acompanhamento: editar/aportar/retirar não altera automaticamente o saldo das contas.
- Nenhuma migração destrutiva ou alteração de schema do SQLite é necessária.
