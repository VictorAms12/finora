## v0.5.2 — Stateful Copilot + Stability Pack

### v0.5.1 incorporada
- conversa da Finora passa a persistir localmente no FinanceData/SQLite e no backup;
- troca de aba e rotação deixam de destruir o estado da IA graças ao shell com IndexedStack;
- rascunho, modo Conversar/Registrar e clarificação pendente são restaurados;
- virada de mês ganha aviso explícito e atalho para o mês anterior;
- Movimentações passa a oferecer pesquisa em todos os meses;
- novo Diagnóstico dos dados verifica SQLite, referências órfãs, IDs, snapshots e valores inválidos;
- orçamento mostra percentual usado, valor restante e projeção pelo ritmo atual.

### v0.5.2
- histórico recente persistido passa a alimentar a continuidade real das conversas;
- Copilot local ganha resposta determinística de insights sem exigir Gemini;
- novo motor de insights destaca atrasos, próximos 7 dias, aceleração de despesas, concentração por categoria, risco de orçamento e uso alto do cartão;
- tela inicial exibe até três insights relevantes do período;
- chat fica mais resistente a teclado/orientação e reduz elementos secundários em altura compacta;
- sessão do chat é limitada e normalizada para evitar crescimento indefinido do estado.

## v0.5.0 — Finora Copilot

- Memória contextual persistente, opcional e totalmente editável pelo usuário.
- Financial Query Engine local para análises rápidas sem depender do Gemini.
- Simulador conversacional de compras à vista e parceladas usando projeções reais.
- Ações do Copilot com confirmação para orçamentos, metas, reservas e previstos.
- Memórias passam a integrar o estado SQLite/backup do Finora.
- Mantém todas as correções de integridade e performance da v0.4.5.

# Changelog

## [0.4.5] - 2026-09-01

### Integridade e comportamento
- auditoria geral das regras de conta, cartão, fatura, planejamento, recorrências, parcelas, metas, SQLite e IA;
- editar fechamento/vencimento de cartão deixa de reclassificar compras históricas em outras faturas;
- cartões não aceitam valor usado abaixo da dívida já rastreada;
- contas/cartões/categorias com compromissos ativos deixam de ser excluídos de forma a criar referências órfãs;
- nomes de contas removidas permanecem reservados enquanto existirem lançamentos históricos, evitando que operações antigas alterem uma nova conta homônima;
- apagar ocorrência recorrente realizada mantém uma marca de ignorada e impede reaparecimento;
- apagar parcela realizada devolve a obrigação ao planejamento quando o parcelamento ainda existe;
- metas passam a preservar valores acumulados acima do alvo, inclusive após redução da meta;
- transferências e pagamentos de fatura podem ser excluídos pela interface e têm os efeitos revertidos;
- realizar previsto inválido deixa de fechar a tela silenciosamente.

### Cálculos e consistência
- “Disponível para gastar” passa a considerar apenas saldo, entradas e compromissos reais; sugestão de aporte em metas deixa de ser descontada como se fosse dívida;
- déficit de caixa previsto passa a ser exposto separadamente;
- IA, tela de cartão e pagamento de fatura compartilham o mesmo cálculo de fatura atual;
- meses históricos sem snapshot são identificados como resultado do mês, não como saldo final conhecido.

### Persistência e desempenho
- commits serializam o estado uma vez e reutilizam o mesmo snapshot para SQLite e espelho legado;
- SQLite marca gravações incompletas e, após falha, prefere o espelho mais novo no próximo início antes de ressincronizar o banco;
- índice SQLite de movimentações só é reconstruído quando transações/planejamento mudam, evitando trabalho pesado em alterações de tema, reserva ou configurações.

### UX e manutenção
- entradas numéricas passam a aceitar melhor formatos brasileiros como `1.234,56`;
- atalhos de reserva usam o editor corrigido;
- formulários críticos mostram falha em vez de fechar como se tivessem salvo;
- versão exibida foi centralizada para evitar rodapés desatualizados;
- adicionada suíte de regressão específica para os problemas encontrados na auditoria.

As mudanças relevantes do Finora são registradas aqui por versão.

## [0.4.4] - 2026-09-01

### Reserva de emergência
- reduzir o valor-alvo não reduz mais silenciosamente o valor já guardado;
- o valor guardado passa a ser independente da meta e pode permanecer acima dela;
- aportes deixam de ser truncados ao atingir o alvo;
- novo fluxo `Movimentar` permite aportar e retirar valores do acompanhamento da reserva;
- retiradas maiores que o valor guardado são bloqueadas para impedir saldo negativo;
- edição passa a validar nome, valor-alvo, valor guardado e meses de proteção com mensagens claras;
- meses de proteção são limitados a inteiros entre 1 e 60;
- a tela passa a diferenciar meta, guardado, restante/excedente, cobertura e referência mensal;
- incluídos testes de regressão cobrindo redução da meta, aporte acima da meta, retirada e persistência.