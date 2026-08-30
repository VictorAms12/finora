# Changelog

As mudanças relevantes do Finora são registradas aqui por versão.

## [0.4.3] - 2026-08-30

### Finora Assistant Engine
- respostas passam por um contrato estruturado que separa texto, continuações e ações da interface, evitando que JSON, tags ou marcações internas apareçam no chat;
- personalidade conversacional revisada para respostas naturais, diretas e proporcionais à pergunta, sem linguagem de relatório ou termos de implementação;
- roteador de intenção separa consultas de saldo, gastos, cartões, planejamento, comparação e lançamentos antes de montar o contexto da IA;
- perguntas simples sobre saldo, patrimônio, disponível para gastar e faturas podem ser respondidas localmente, com cálculos do próprio Finora e sem chamada ao Gemini;
- o contexto enviado ao Gemini passa a ser seletivo conforme a pergunta, reduzindo tokens e exposição desnecessária de dados;
- perguntas de continuação usam o histórico recente sem repetir toda a conversa ou informações já compreendidas;
- respostas podem oferecer chips de continuação e ações para abrir Planejamento, Movimentações ou iniciar um lançamento;
- frases de lançamento podem ser reconhecidas no modo Conversar, sem exigir troca manual para o modo Registrar;
- quando falta conta, cartão ou destino de transferência, o assistente pergunta naturalmente e oferece opções reais em vez de mostrar um erro técnico;
- sem chave Gemini, consultas financeiras locais básicas continuam disponíveis;
- configuração inicial da chave dentro do chat ficou mais compacta e menos intrusiva;
- indicador de confiança numérico foi removido da interface de lançamento e substituído por um aviso simples apenas quando a interpretação merece conferência extra.

### Robustez
- pós-processamento remove code fences, tags de raciocínio/apresentação, cabeçalhos Markdown e rótulos artificiais antes de exibir texto do modelo;
- cálculos financeiros continuam no `FinanceStore`; o Gemini interpreta e explica, mas não se torna fonte de verdade para saldos, faturas ou previsões;
- lançamentos continuam exigindo confirmação explícita antes de alterar qualquer dado;
- adicionados testes para respostas locais, roteamento de intenção, detecção de lançamento e sanitização de respostas;
- versão incrementada para `0.4.3+15`, sem alteração destrutiva no SQLite ou na migração existente.

## [0.4.2] - 2026-08-30

### Experiência da Finora IA
- Finora IA passa a ser uma aba principal no mobile e no desktop, deixando de ficar escondida dentro de `Mais`;
- a interface de três formulários independentes foi substituída por um chat contínuo com histórico durante a sessão;
- um único campo de conversa atende perguntas e lançamentos, com modos `Conversar` e `Lançar` claramente separados;
- atalhos contextuais permitem analisar o mês, consultar valor disponível, próximos compromissos, cartões e iniciar um lançamento;
- perguntas de continuação recebem o contexto recente da conversa para tornar o diálogo mais natural;
- a primeira configuração da chave Gemini pode ser feita dentro do próprio chat, sem obrigar o usuário a abrir Configurações;
- respostas, erros e confirmações passam a aparecer na conversa em vez de depender principalmente de mensagens temporárias;
- sugestões de lançamento continuam exigindo confirmação explícita antes de alterar qualquer dado financeiro;
- o botão de novo lançamento deixa o centro da barra inferior para liberar uma quinta aba real e permanece disponível como ação flutuante nas demais telas.

### Compatibilidade
- nenhuma alteração destrutiva foi feita no SQLite, na migração ou nas regras financeiras;
- versão incrementada para `0.4.2+14`, preservando a atualização sobre a v0.4.1 e os dados locais quando assinada com a mesma chave.

## [0.4.1] - 2026-08-30

### Corrigido
- adicionada a permissão `android.permission.INTERNET` ao APK Release, permitindo que o Finora IA acesse a API Gemini no Android;
- mensagens de erro de rede da IA agora diferenciam bloqueio de permissão, falta de conexão e timeout;
- versão Android incrementada para `0.4.1+13`, permitindo instalar o hotfix por cima da v0.4.0 sem perder o banco SQLite ou demais dados locais.

## [0.4.0] - 2026-08-30

### Adicionado
- armazenamento SQLite transacional como camada primária, mantendo o `FinanceStore` validado como núcleo das regras financeiras;
- migração automática e não destrutiva dos dados existentes da v0.3.9 em `SharedPreferences` para SQLite;
- índice local de transações e previstos para consultas rápidas e relatórios;
- Finora IA via Gemini, opt-in e configurável pelo próprio usuário;
- lançamento por linguagem natural com prévia e confirmação obrigatória;
- análise mensal e perguntas sobre os próprios dados financeiros;
- armazenamento seguro da chave Gemini no cofre do sistema operacional.

### Integridade e privacidade
- o JSON legado da v0.3.9 permanece como espelho de compatibilidade durante a migração;
- falha do SQLite não impede acesso aos dados: o Finora retorna ao armazenamento legado;
- SQLite mantém o estado anterior íntegro como recuperação transacional;
- respostas de IA nunca alteram saldos diretamente e reutilizam as validações do `FinanceStore`;
- contexto enviado à IA é reduzido e exclui backup completo e notas privadas.

### Qualidade
- testes cobrem migração v0.3.9 → SQLite, preservação de saldo, indexação pós-migração e recuperação do espelho legado corrompido.

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