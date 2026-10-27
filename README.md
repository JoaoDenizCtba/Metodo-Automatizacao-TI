# Método Pessoal de Automação de Tarefas de TI

Este repositório documenta e disponibiliza um método modular e estruturado para automação de tarefas de TI em ambientes Windows, Linux e macOS, utilizando PowerShell 7+, arquivos JSON e scripts especializados.

## Estrutura do Método

- **Separação por especialização**: cada script possui uma responsabilidade clara (ex: inventário, verificação de softwares, autenticação).
- **Matriz JSON**: centraliza informações de dispositivos, softwares obrigatórios e parâmetros.
- **Executor orquestrador**: um script principal que carrega a matriz e dispara os scripts especializados conforme necessidade.

## Estrutura atual

- `executor/Invoke-Inventario.ps1`: orquestra a coleta e grava o relatório JSON localmente.
- `executor/Start-Inventario.cmd` e `executor/Start-Inventario.sh`: inicializadores nativos; verificam ou instalam PowerShell 7 antes de chamar o executor.
- `executor/Bootstrap-Windows.ps1`: inicializador Windows PowerShell 5.1, usa WinGet quando disponível e valida assinatura/hash do MSI oficial no fallback.
- `executor/bootstrap/Install-PowerShell-Linux.sh`: instalação por gerenciador Linux suportado ou arquivo oficial local.
- `executor/bootstrap/Install-PowerShell-macOS.sh`: instalação por Homebrew ou pacote oficial macOS.
- `executor/bootstrap/PowerShell-Bootstrap.Common.sh`: download, metadados de release, SHA-256 e privilégios.
- `matriz/inventario.json`: define a versão da matriz e os parâmetros de saída.
- `scripts/Inventario.Common.ps1`: funções compartilhadas pelos coletores.
- `scripts/Environment.Validation.ps1`: verifica a plataforma, a versão do PowerShell, comandos e arquivos obrigatórios antes da coleta; instala `coreutils` no Linux se `df` ou `who` estiver ausente.
- `scripts/Inventario.Windows.ps1`: coleta específica para Windows.
- `scripts/Inventario.Linux.ps1`: coleta específica para Linux.
- `scripts/Inventario.macOS.ps1`: coleta específica para macOS.
- `docs/inventario.md`: escopo, formato e limitações do inventário inicial.
- `tests/Test-InventorySmoke.ps1`: valida a estrutura do relatório no sistema atual.
- `.github/workflows/test-inventory.yml`: executa o teste de fumaça em Windows, Linux e macOS.

## Objetivo

- Reduzir redundância e facilitar manutenção
- Permitir expansão modular e reutilização de código
- Otimizar o tempo do analista de infraestrutura

## Exemplos de Uso

- Coletar informações locais de hardware, sistema operacional, usuários e sessões.
- Gerar um relatório JSON local com data de coleta e avisos sobre dados indisponíveis.

## Primeira execução

O caminho recomendado inicia a validação e prepara PowerShell 7 quando necessário. No Windows, execute:

```powershell
.\executor\Start-Inventario.cmd
```

No Linux e macOS:

```sh
sh ./executor/Start-Inventario.sh
```

O inicializador prefere o gerenciador já existente quando ele oferece PowerShell. Se não houver um gerenciador adequado, usa o instalador oficial do PowerShell, verificando SHA-256 e assinatura onde o formato permite. A instalação de pacotes de sistema pode solicitar senha de administrador; no Linux, o fallback do arquivo oficial é instalado no perfil do usuário. O validador pode instalar `coreutils` no Linux se `df` ou `who` estiver ausente; outras dependências nativas obrigatórias ausentes bloqueiam a coleta com diagnóstico, sem instalar ou configurar um gerenciador novo.

Para executar diretamente, PowerShell 7+ deve estar previamente instalado. O relatório é salvo no diretório local de dados do usuário; para escolher outro caminho:

```powershell
pwsh -File ./executor/Invoke-Inventario.ps1 -OutputPath ./inventario.json
```

O coletor não envia dados para serviços externos. Consulte [docs/inventario.md](docs/inventario.md) antes de distribuir ou armazenar relatórios, pois eles podem conter identificadores de dispositivos, contas e endereços de rede.

O suporte a Active Directory, instalações e correções remotas não faz parte deste primeiro escopo.

Para validar a coleta no equipamento atual:

```powershell
pwsh -File ./tests/Test-InventorySmoke.ps1
```

## Autor

João Alberto R. Deniz Junior – Analista de Infraestrutura Sênior
