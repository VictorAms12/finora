# Changelog

As mudanças relevantes do Finora são registradas aqui por versão.

## [0.3.9] - 2026-08-18

### Corrigido
- transferências com data futura passam a ser previsões e não alteram saldos antes da realização;
- exclusão de pagamento de fatura recompõe corretamente o saldo da conta e o valor usado do cartão;
- compras da próxima competência deixam de ser tratadas como fatura atual;
- previsões com vencimento no dia atual não são mais classificadas como atrasadas por diferença de horário;
- liquidação de previstos valida conta, cartão e destino antes de marcar o compromisso como realizado;
- receitas previstas não aceitam cartão como destino;
- recorrências indefinidas mantêm um horizonte futuro rolante, inclusive quando a regra já existe há vários anos;
- ocorrências recorrentes adiadas ou ignoradas deixam de reaparecer silenciosamente;
- renomeações de contas e categorias propagam para referências financeiras relacionadas;
- validações impedem nomes de conta ambíguos e valores financeiros inválidos.

### Desempenho
- `MaterialApp` deixa de observar toda alteração do `FinanceStore` e passa a reconstruir apenas quando tema/onboarding mudam;
- agregações mensais de transações, receitas, despesas e categorias passam a usar cache invalidado por commit;
- gravações em `SharedPreferences` são serializadas para preservar a ordem de commits rápidos;
- notificações nativas são inicializadas depois da primeira renderização;
- navegação entre meses passa a selecionar o destino em uma única atualização de estado;
- componentes financeiros observam apenas os campos de estado de que precisam;
- histórico mensal renderiza movimentações progressivamente em blocos de 50 itens;
- operações compostas de recorrência, parcelamento e liquidação foram reduzidas para um único commit lógico.

### Integridade e recuperação
- o último estado íntegro da persistência local é mantido como cópia de recuperação;
- se o JSON principal estiver corrompido, o Finora tenta recuperar a cópia íntegra anterior;
- restauração de backup valida o conteúdo antes de substituir o estado e aguarda a persistência terminar;
- IDs gerados localmente são monotônicos para evitar colisões em operações executadas no mesmo microssegundo;
- novos campos de identidade de recorrência e destino de transferência são opcionais e mantêm compatibilidade com backups da v0.3.8.

### Qualidade
- adicionados testes de regressão para recorrências antigas, adiamento, ignorar ocorrência, transferências futuras, competência de faturas, reversão de pagamento, persistência concorrente, recuperação após corrupção e integridade de nomes/referências.

## [0.3.8] - 2026-08-17

### Adicionado
- backup completo copiável e restauração dos dados do Finora;
- suporte explícito ao Auto Backup do Android;
- teste automatizado de backup e restauração;
- identidade de ícone em preto e branco no Android e Windows.

### Corrigido
- estabilização da assinatura Android para builds futuras;
- ajustes no fluxo de recuperação e preservação de dados.

## [0.3.7] - 2026-08-16

### Adicionado
- programação de salário no 5º dia útil;
- reparo automático de efeitos de lançamentos futuros legados;
- testes para saldo futuro, recorrências e salário.

### Corrigido
- receitas e despesas futuras deixam de alterar o saldo atual antes da realização;
- remoção de previsões órfãs após exclusão de recorrências.

## [0.3.6] - 2026-08-14

### Adicionado
- porte do Finora para Windows;
- navegação lateral responsiva para desktop;
- atalhos de teclado;
- Windows Hello quando disponível;
- pacote portátil em ZIP via GitHub Actions.

## [0.2.3]

### Corrigido
- APIs depreciadas que faziam `flutter analyze` interromper a pipeline;
- uso de `withValues(alpha: ...)` e `initialValue` onde aplicável;
- separação de artifacts APK e AAB.

## [0.2.2]

### Corrigido
- erros de sintaxe em formulários e detalhes de movimentação;
- remoção do teste padrão gerado pelo `flutter create`;
- análise estática passou a bloquear erros reais de compilação.

## [0.2.1]

### Corrigido
- primeiros problemas de build no GitHub Actions;
- remoção automática do `test/widget_test.dart` incompatível com a aplicação.

---

Versões anteriores a 0.2.1 pertencem à fase inicial de prototipação do projeto e não possuem changelog estruturado.
