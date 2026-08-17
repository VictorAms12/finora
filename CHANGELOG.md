# Changelog

As mudanças relevantes do Finora são registradas aqui por versão.

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
