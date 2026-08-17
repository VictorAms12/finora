# Assinatura Android do Finora

A chave de assinatura Android **não deve ser armazenada no repositório**, mesmo em projetos pessoais. A assinatura identifica a origem dos APKs e precisa permanecer estável para que versões futuras possam atualizar uma instalação existente.

## Estado de segurança

Uma chave usada anteriormente pelo Finora chegou a ser versionada no repositório junto com sua senha. Como o repositório está público, essa chave deve ser considerada **comprometida** e não deve ser utilizada como identidade definitiva de distribuição.

Remover o arquivo da branch atual não apaga cópias presentes no histórico Git. A correção correta é:

1. gerar uma nova chave privada;
2. armazená-la fora do repositório;
3. configurar a chave no GitHub Actions através de Secrets;
4. manter essa nova chave como identidade estável das próximas versões.

> A troca de chave também troca a identidade de assinatura. Um APK assinado com a nova chave não atualiza diretamente uma instalação assinada pela chave antiga fora de mecanismos oficiais de rotação de chave. Defina a nova chave antes de estabelecer uma nova instalação-base do Finora.

## Secrets necessários

Em **Settings → Secrets and variables → Actions → New repository secret**, configure:

| Secret | Conteúdo |
|---|---|
| `FINORA_KEYSTORE_BASE64` | conteúdo Base64 completo do arquivo `.jks` |
| `FINORA_KEYSTORE_PASSWORD` | senha do keystore |
| `FINORA_KEY_ALIAS` | alias da chave |
| `FINORA_KEY_PASSWORD` | senha da chave |

Nenhum desses valores deve aparecer em arquivos versionados, logs, issues ou pull requests.

## Converter um JKS para Base64

Linux/macOS:

```bash
base64 -w 0 finora-release.jks > finora-release.base64.txt
```

PowerShell:

```powershell
[Convert]::ToBase64String([IO.File]::ReadAllBytes('finora-release.jks')) |
  Set-Content -NoNewline finora-release.base64.txt
```

Copie todo o conteúdo do `.txt` para `FINORA_KEYSTORE_BASE64`.

## Comportamento da pipeline

O workflow Android possui dois modos:

### Assinatura estável

Quando os quatro Secrets estão configurados:

- o keystore é reconstruído apenas dentro do runner do GitHub Actions;
- APK e AAB são assinados com a chave estável;
- artifacts de release são publicados em pushes da `main` ou execução manual.

### Assinatura efêmera de CI

Quando os Secrets ainda não estão configurados:

- o workflow gera uma chave temporária;
- `flutter analyze`, testes, APK e AAB continuam sendo compilados para validar o código;
- APK/AAB **não são publicados**, evitando que uma assinatura descartável seja usada como baseline.

## Arquivos protegidos pelo `.gitignore`

O projeto ignora, entre outros:

```text
android/keystore/
android/key.properties
*.jks
*.keystore
*.p12
*.pem
```

Antes de qualquer commit de release, confirme:

```bash
git status
```

Uma chave de assinatura nunca deve aparecer na lista de arquivos staged.
