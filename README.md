<div align="center">

# FINORA

### Gestão financeira pessoal, clara e multiplataforma.

Organize receitas, despesas, cartões, planejamento, metas, reservas e investimentos em uma única aplicação, com foco em controle financeiro diário e visão de futuro.

[![Flutter](https://img.shields.io/badge/Flutter-multiplataforma-02569B?logo=flutter&logoColor=white)](https://flutter.dev/)
[![Dart](https://img.shields.io/badge/Dart-3.x-0175C2?logo=dart&logoColor=white)](https://dart.dev/)
[![Android](https://img.shields.io/badge/Android-suportado-3DDC84?logo=android&logoColor=white)](#android)
[![Windows](https://img.shields.io/badge/Windows-suportado-0078D4?logo=windows11&logoColor=white)](#windows)
[![Versão](https://img.shields.io/badge/versão-0.3.6-D4AF37)](#versão-atual)

[![Build Android](https://github.com/VictorAms12/finora/actions/workflows/build-android.yml/badge.svg)](https://github.com/VictorAms12/finora/actions/workflows/build-android.yml)
[![Build Windows](https://github.com/VictorAms12/finora/actions/workflows/build-windows.yml/badge.svg)](https://github.com/VictorAms12/finora/actions/workflows/build-windows.yml)

</div>

---

## Sobre o projeto

**Finora** é uma aplicação de gestão financeira pessoal desenvolvida em **Flutter**, atualmente disponível para **Android e Windows** a partir da mesma base de código.

O projeto foi pensado para ir além de um simples registro de gastos. O objetivo é reunir o ciclo financeiro pessoal completo:

**registrar → planejar → acompanhar → projetar → melhorar**.

A aplicação funciona localmente, sem exigir conta online ou conexão permanente com a internet. Cada instalação mantém seus próprios dados no dispositivo.

> **Importante:** na versão atual, Android e Windows ainda não sincronizam automaticamente entre si.

---

## Principais recursos

### Dashboard financeiro

- visão consolidada do mês selecionado;
- entradas, saídas, saldo e saldo projetado;
- acompanhamento do patrimônio;
- visão de contas, reservas e investimentos;
- compromissos financeiros próximos;
- acompanhamento de metas e orçamentos;
- navegação entre meses passados, atual e futuros;
- projeções encadeadas entre competências.

### Receitas e despesas

- cadastro de receitas e despesas;
- associação com conta ou cartão;
- data, categoria e observação;
- edição e exclusão de lançamentos;
- filtros e pesquisa;
- lançamentos recorrentes;
- parcelamentos;
- lançamentos previstos e realizados.

Os lançamentos planejados podem assumir estados como:

- **previsto**;
- **atrasado**;
- **realizado**;
- **ignorado**.

Também é possível realizar, adiar ou ignorar compromissos previstos.

### Planejamento mensal

- orçamento por categoria;
- previsão de receitas e despesas;
- saldo projetado;
- recorrências semanais, mensais e anuais;
- recorrência infinita, por quantidade ou até uma data;
- parcelamentos com acompanhamento das parcelas futuras;
- fechamento mensal com saldo inicial, movimentações e saldo final.

### Cartões de crédito

- cadastro e gerenciamento de cartões;
- limite do cartão;
- data de fechamento;
- data de vencimento;
- conta padrão para pagamento;
- organização de compras por fatura/competência;
- visualização da fatura selecionada;
- próxima fatura;
- limite disponível;
- acompanhamento de parcelas futuras.

### Metas e reservas

- criação e edição de metas financeiras;
- valor-alvo e prazo;
- acompanhamento do progresso;
- estimativa de contribuição mensal necessária;
- reservas financeiras separadas do saldo cotidiano;
- estimativa de meses de cobertura da reserva.

### Investimentos

- cadastro de investimentos;
- acompanhamento do valor investido;
- composição do patrimônio junto às demais posições financeiras.

### Relatórios

- visão histórica das movimentações;
- comparação entre períodos;
- análise por categorias;
- acompanhamento de receitas e despesas;
- projeções financeiras contextuais.

### Organização

CRUD disponível para as principais entidades do aplicativo:

- contas;
- cartões;
- categorias;
- orçamentos;
- metas;
- reservas;
- investimentos.

---

## Experiência e interface

O Finora utiliza uma identidade visual própria com foco em legibilidade e baixa poluição visual.

- tema claro;
- tema escuro **OLED** com preto absoluto;
- detalhes em dourado;
- cores semânticas para receitas, despesas e indicadores;
- animações e transições suaves;
- onboarding inicial;
- opção para ocultar valores financeiros;
- layout responsivo entre celular e desktop.

No Android, a navegação principal utiliza barra inferior e ação central de novo lançamento. No Windows, a aplicação muda automaticamente para uma interface de desktop com barra lateral e conteúdo limitado para melhor aproveitamento de monitores maiores.

---

## Segurança e privacidade

O Finora possui bloqueio opcional de acesso por autenticação do próprio dispositivo:

- **Android:** biometria compatível com o aparelho;
- **Windows:** Windows Hello.

A aplicação também volta a exigir autenticação quando retorna de determinados estados de segundo plano, caso a proteção esteja ativada.

### Como os dados são armazenados?

Atualmente, os dados financeiros são persistidos **localmente** usando `shared_preferences`.

Isso significa que:

- não existe backend obrigatório;
- os dados não são enviados automaticamente para um servidor;
- Android e Windows possuem bases locais independentes;
- o bloqueio biométrico protege o acesso pela interface, mas **não deve ser interpretado como criptografia completa do banco de dados em repouso**.

Criptografia local e sincronização segura fazem parte da evolução planejada do projeto.

---

## Notificações

O Finora possui uma central interna de avisos e integração com notificações locais para situações como:

- lançamentos atrasados;
- compromissos próximos;
- lembretes financeiros;
- vencimentos e informações relacionadas a faturas.

A implementação respeita as diferenças de suporte entre Android e Windows.

---

## Windows

A partir da **v0.3.6**, o Finora possui suporte nativo para Windows através do Flutter Desktop.

### Recursos específicos do desktop

- navegação lateral;
- layout responsivo para janelas maiores;
- central de lançamentos adaptada para mouse e teclado;
- Windows Hello;
- notificações compatíveis com Windows;
- build `Release` nativo;
- distribuição em pacote portátil `.zip`.

### Atalhos de teclado

| Atalho | Ação |
|---|---|
| `Ctrl + N` | Novo lançamento |
| `Ctrl + 1` | Início |
| `Ctrl + 2` | Planejamento |
| `Ctrl + 3` | Movimentações |
| `Ctrl + 4` | Mais |

### Executando a versão portátil

Baixe o artifact **Finora-Windows-v0.3.6** na execução mais recente do workflow **Compilar Finora Windows**.

Depois:

1. extraia todo o conteúdo do ZIP;
2. mantenha o executável, DLLs e a pasta `data` juntos;
3. execute `Finora.exe`.

Não mova apenas o `.exe`, pois o aplicativo depende dos arquivos que acompanham o build Flutter para Windows.

---

## Android

O workflow **Compilar Finora Android** valida o código e produz builds de distribuição em cada push ou pull request direcionado à `main`.

São gerados:

- **APK Release**, indicado para instalação direta e testes;
- **AAB Release**, destinado a distribuição por lojas compatíveis.

O pipeline também configura automaticamente os requisitos nativos usados por biometria e notificações no Android.

---

## Tecnologias

| Tecnologia | Uso no projeto |
|---|---|
| **Flutter** | Interface e aplicação multiplataforma |
| **Dart** | Linguagem principal |
| **Provider** | Gerenciamento de estado |
| **ChangeNotifier** | Atualização reativa do estado financeiro |
| **SharedPreferences** | Persistência local dos dados |
| **local_auth** | Biometria e Windows Hello |
| **flutter_local_notifications** | Notificações locais |
| **GitHub Actions** | Análise, build e geração de artifacts |

A versão atual declarada no `pubspec.yaml` é **0.3.6+8**.

---

## Arquitetura do projeto

A aplicação mantém a lógica de domínio e a interface separadas em arquivos especializados.

```text
finora/
├── .github/
│   └── workflows/
│       ├── build-android.yml
│       └── build-windows.yml
│
├── lib/
│   ├── main.dart
│   ├── models.dart
│   ├── store.dart
│   ├── store_entities.dart
│   ├── store_planning.dart
│   ├── store_transactions.dart
│   ├── notification_service.dart
│   ├── security.dart
│   ├── onboarding.dart
│   ├── theme.dart
│   └── ui/
│       ├── accounts.dart
│       ├── common.dart
│       ├── dashboard.dart
│       ├── desktop_actions.dart
│       ├── forms.dart
│       ├── goals_reserves.dart
│       ├── home_shell.dart
│       ├── more.dart
│       ├── planning.dart
│       ├── reports.dart
│       └── ...
│
├── analysis_options.yaml
├── pubspec.yaml
└── README.md
```

### Responsabilidades principais

- `main.dart` — inicialização da aplicação, estado global e escolha entre onboarding e área principal;
- `models.dart` — entidades e modelos financeiros;
- `store.dart` — estado central, persistência e regras compartilhadas;
- `store_entities.dart` — operações relacionadas às entidades financeiras;
- `store_planning.dart` — regras de planejamento e projeção;
- `store_transactions.dart` — operações de movimentações;
- `notification_service.dart` — notificações locais;
- `security.dart` — autenticação biométrica/Windows Hello e bloqueio da aplicação;
- `theme.dart` — temas e identidade visual;
- `ui/` — telas, formulários e componentes visuais.

---

## Ambiente de desenvolvimento

### Pré-requisitos

- Flutter Stable;
- Dart compatível com `>=3.10.0 <4.0.0`;
- Git;
- Android Studio/Android SDK para builds Android;
- Windows com Visual Studio e ferramentas de C++ Desktop para builds Windows.

### Clonando o projeto

```bash
git clone https://github.com/VictorAms12/finora.git
cd finora
flutter pub get
```

Como o repositório mantém o foco na base compartilhada e os workflows geram a estrutura nativa das plataformas, você pode recriar os targets localmente quando necessário.

### Gerar suporte Android

```bash
flutter create . --platforms=android --project-name=finora --org=com.finora
flutter pub get
```

### Gerar suporte Windows

Em um ambiente Windows preparado para Flutter Desktop:

```bash
flutter create . --platforms=windows --project-name=finora --org=com.finora
flutter pub get
```

> O workflow do Windows também aplica uma configuração de compatibilidade necessária ao `local_auth_windows` no toolchain utilizado atualmente pelo GitHub Actions. Para uma reprodução idêntica do build de CI, consulte `.github/workflows/build-windows.yml`.

### Executar

```bash
flutter run
```

### Análise estática

```bash
flutter analyze
```

### Build Android

```bash
flutter build apk --release
flutter build appbundle --release
```

### Build Windows

```bash
flutter build windows --release
```

---

## CI/CD

O projeto possui pipelines independentes para Android e Windows.

### Android

O workflow realiza, entre outras etapas:

1. configuração do Java e Flutter;
2. geração do target Android;
3. configuração de biometria e notificações;
4. instalação das dependências;
5. análise estática;
6. build do APK;
7. build do AAB;
8. publicação dos artifacts.

### Windows

O workflow realiza:

1. configuração do Flutter;
2. geração do target Windows;
3. ajustes de identidade e compatibilidade C++;
4. instalação das dependências;
5. análise estática;
6. build Windows Release;
7. empacotamento portátil;
8. publicação do ZIP como artifact.

Os workflows são executados em pushes e pull requests para a branch `main` e também podem ser iniciados manualmente.

---

## Versão atual

### Finora v0.3.6

A v0.3.6 marca a expansão do Finora de um aplicativo exclusivamente mobile para uma aplicação **Android + Windows**.

Principais destaques:

- porte nativo para Windows;
- mesma base de código para mobile e desktop;
- sidebar responsiva no desktop;
- atalhos de teclado;
- central de lançamentos para PC;
- Windows Hello;
- build portátil automatizado;
- manutenção dos recursos financeiros introduzidos na linha v0.3.x.

---

## Roadmap

O projeto continua em desenvolvimento. Entre as evoluções planejadas estão:

- [ ] sincronização segura entre Android e Windows;
- [ ] pareamento de dispositivos por código ou QR Code;
- [ ] sincronização fora da rede local;
- [ ] backup e restauração;
- [ ] exportação e importação de dados;
- [ ] armazenamento local com criptografia dedicada;
- [ ] instalador próprio para Windows, como MSIX/Setup;
- [ ] melhorias nas notificações do desktop;
- [ ] ampliação dos relatórios e indicadores;
- [ ] testes automatizados de regras financeiras;
- [ ] testes de interface e regressão;
- [ ] evolução contínua de desempenho, animações e experiência de uso.

---

## Estado atual do projeto

O Finora já é funcional para uso pessoal e possui builds automatizados para Android e Windows. Entretanto, continua sendo um projeto em evolução e ainda não deve ser tratado como software bancário, contábil ou como substituto de serviços financeiros profissionais.

### Limitações conhecidas

- não há sincronização entre dispositivos na versão atual;
- não há integração com bancos ou Open Finance;
- não há cotações financeiras em tempo real;
- os dados são armazenados localmente e separadamente em cada instalação;
- ainda não existe um backend central do Finora.

---

## Contribuindo

Sugestões, correções e melhorias podem ser desenvolvidas por branches e integradas através de pull requests.

Fluxo recomendado:

```bash
git checkout -b feature/minha-melhoria
# faça as alterações
git add .
git commit -m "feat: descreva a melhoria"
git push -u origin feature/minha-melhoria
```

Antes de enviar alterações, procure manter:

- código analisável pelo `flutter analyze`;
- compatibilidade entre Android e Windows;
- regras financeiras independentes da camada visual;
- componentes reutilizáveis quando possível;
- consistência com a identidade visual do Finora.

---

## Licenciamento

Este repositório ainda não possui uma licença de código aberto definida. Enquanto não houver um arquivo `LICENSE`, não presuma permissão automática para redistribuição ou relicenciamento do código.

---

<div align="center">

**Finora** — controle hoje, clareza para o próximo mês.

Desenvolvido em Flutter para Android e Windows.

</div>
