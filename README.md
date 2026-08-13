# Finora Mobile v0.1

Aplicativo mobile de gestão financeira pessoal desenvolvido em **Flutter**.

## Visual
- Tema escuro OLED com preto absoluto (`#000000`)
- Cinzas escuros nas superfícies
- Detalhes dourados
- Tema claro branco
- Verde para entradas
- Vermelho para saídas
- Dourado para saldos
- Roxo para metas
- Âmbar para reservas
- Azul para investimentos

## Módulos
- Dashboard
- Disponível para gastar
- Entradas e saídas
- Transferências
- Planejamento
- Orçamento por categoria
- Calendário financeiro
- Metas e aportes
- Reservas
- Investimentos
- Relatórios
- Saúde financeira
- Contas
- Cartões
- Conselhos / insights
- Tema claro / OLED
- Privacidade
- Persistência local

## Compilar no GitHub
O projeto já inclui:

`.github/workflows/build-android.yml`

Ao fazer push para `main`, o GitHub Actions:
1. instala Java 17;
2. instala Flutter Stable;
3. gera a estrutura Android;
4. baixa dependências;
5. compila APK release;
6. compila AAB;
7. disponibiliza ambos em **Artifacts**.

Também é possível iniciar manualmente em:

**Actions → Compilar Finora Android → Run workflow**

## Arquivo para instalar
Após o build, baixe o artifact `Finora-Android-v0.1`.

O APK fica dentro dele como:

`app-release.apk`
