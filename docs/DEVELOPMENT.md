# Desenvolvimento do Finora

Este documento reúne os comandos de desenvolvimento que antes estavam espalhados em arquivos `.txt` na raiz do repositório.

## Pré-requisitos

- Flutter Stable compatível com o `pubspec.yaml`;
- Dart incluído no Flutter;
- Android SDK + Java 17 para Android;
- Visual Studio com **Desktop development with C++** para Windows.

## Preparação

```bash
git clone https://github.com/VictorAms12/finora.git
cd finora
flutter pub get
```

## Executar localmente

Android:

```bash
flutter run
```

Windows:

```bash
flutter run -d windows
```

> Os diretórios nativos de Android e Windows são gerados pelas pipelines com `flutter create` e recebem os ajustes do Finora através dos scripts em `tool/`.

## Validação antes de enviar mudanças

```bash
flutter analyze --no-fatal-infos
flutter test
```

## Fluxo Git sugerido

```bash
git switch main
git pull
git switch -c feature/minha-alteracao

# altere os arquivos

flutter analyze --no-fatal-infos
flutter test

git add <arquivos>
git commit -m "feat: descreve a alteração"
git push -u origin feature/minha-alteracao
```

Abra um Pull Request para `main` e aguarde as pipelines Android e Windows.

## Versionamento

A fonte única da versão do aplicativo é:

```yaml
# pubspec.yaml
version: X.Y.Z+BUILD
```

Os workflows leem essa versão automaticamente para nomear artifacts e pacotes. Não é necessário alterar manualmente nomes como `Finora-APK-vX.Y.Z` nos YAMLs.

## Scripts auxiliares

| Arquivo | Função |
|---|---|
| `tool/configure_android.py` | aplica permissões, Activity, Gradle, SDK e configuração de assinatura ao projeto Android gerado |
| `tool/configure_windows.ps1` | aplica nome e ajustes de compatibilidade ao projeto Windows gerado |
| `tool/generate_branding.py` | gera a identidade visual nativa do Android e Windows |

## Builds

As pipelines ficam em `.github/workflows/`:

- `build-android.yml` — análise, testes, APK e AAB;
- `build-windows.yml` — análise, testes e pacote portátil Windows.

O Android só publica APK/AAB quando uma assinatura estável foi carregada por GitHub Secrets. Consulte [`SIGNING.md`](SIGNING.md).
