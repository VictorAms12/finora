# Finora Mobile v0.3.5

Versão voltada para uso financeiro diário, planejamento mensal e segurança local. A v0.3.5 amplia a lógica de projeções, cartões, recorrências, lançamentos previstos e gerenciamento das entidades, além de adicionar biometria e notificações.

## Principais mudanças

- Dashboard contextual para mês atual, passado e futuro.
- Saldo projetado encadeado entre os meses.
- Fechamento mensal com saldo inicial, entradas, saídas e saldo final.
- Seletor de mês com calendário mensal/ano e animação.
- Nova central `+` priorizando Despesa e Receita e agrupando ações de planejamento e organização.
- Lançamentos com conta/cartão, data, categoria, observação, recorrência e parcelamento.
- Lançamentos previstos com estados: previsto, atrasado, realizado e ignorado.
- Ações para realizar, adiar ou ignorar um lançamento previsto.
- Recorrências semanais, mensais e anuais com duração infinita, por quantidade ou até uma data.
- Parcelamentos com acompanhamento de progresso e cancelamento das parcelas futuras.
- Cartões com fechamento, vencimento, conta padrão para pagamento e faturas por competência.
- Compras no cartão são direcionadas automaticamente para a fatura correta conforme o fechamento.
- Tela de fatura com mês selecionável, próxima fatura, limite disponível e parcelas futuras.
- CRUD de contas, cartões, metas, reservas, investimentos, categorias e orçamentos.
- Metas com estimativa mensal necessária para atingir o prazo.
- Reservas com estimativa de meses de cobertura.
- Relatórios contextuais com histórico, comparação e projeções.
- Central interna de notificações para atrasos, compromissos próximos e faturas.
- Lembretes locais no aparelho.
- Bloqueio opcional por biometria.
- Tema OLED, tema claro e ocultação de valores mantidos.
- Compatibilidade com os dados da versão 0.3 preservada.

## Android

O GitHub Actions valida o código e gera os artifacts Android em pushes e pull requests da `main`.

Artifacts:

- `Finora-APK-v0.3.5`
- `Finora-AAB-v0.3.5`
