# Inventário local — primeira versão

## Objetivo

Coletar informações locais de equipamentos Windows, Linux e macOS fora de domínio, com PowerShell 7 ou superior. O executor escolhe um coletor específico para o sistema operacional e grava um arquivo JSON; nenhum envio de rede ou alteração de configuração é feito pelo projeto.

## Pré-requisitos

- PowerShell 7+ (`pwsh`).
- O inicializador pode baixar a release estável do repositório oficial PowerShell; MSI/PKG requer autorização administrativa e o fallback Linux usa instalação por usuário.
- No Windows, acesso aos cmdlets CIM e LocalAccounts, normalmente incluídos no sistema.
- No Linux, acesso de leitura a `/etc/passwd`, `/etc/group` e `/proc`; os comandos `df`, `who` e `lastlog` são usados quando disponíveis.
- No macOS, disponibilidade de `sw_vers`, `system_profiler`, `dscl`, `last`, `who`, `sysctl` e `df`.
- No Linux, `df` e `who` são dependências obrigatórias; se estiverem ausentes, o validador tenta instalar `coreutils` pelo gerenciador suportado existente.
- Algumas informações podem depender de permissões e dos comandos instalados.

## Execução

Use os inicializadores nativos, que verificam/instalam PowerShell 7 antes de chamar o orquestrador:

Windows:

```powershell
.\executor\Start-Inventario.cmd
```

Linux e macOS:

```sh
sh ./executor/Start-Inventario.sh
```

O inicializador usa o gerenciador suportado que já estiver disponível e oferecer PowerShell. Quando não houver, baixa a release estável oficial do projeto PowerShell, compara o SHA-256 publicado pela API de releases e verifica a assinatura do instalador nos formatos MSI/PKG. No Windows, WinGet é tentado antes do MSI. No macOS, Homebrew é tentado antes do PKG. No Linux, APT, DNF, YUM, Zypper ou APK só são usados quando o repositório configurado oferece o pacote; caso contrário, o arquivo oficial verificado é instalado no perfil do usuário. Instalações de sistema podem solicitar autorização administrativa.

O teste e a execução direta continuam disponíveis quando PowerShell 7 já está instalado:

```powershell
pwsh -File ./executor/Invoke-Inventario.ps1
```

Por padrão, o arquivo é gravado em uma pasta de dados local do usuário. O diretório pode ser sobrescrito:

```powershell
pwsh -File ./executor/Invoke-Inventario.ps1 -OutputPath ./inventario.json
```

Os diretórios padrão são `%LOCALAPPDATA%\Metodo-Automatizacao-TI\inventarios` no Windows, `~/Library/Application Support/Metodo-Automatizacao-TI/inventarios` no macOS e `~/.local/share/Metodo-Automatizacao-TI/inventarios` no Linux.

`-WhatIf` mostra a ação de gravação sem criar o arquivo. `-ConfigPath` permite apontar para outra matriz compatível com a versão 1.

O teste de fumaça para o sistema atual pode ser executado com:

```powershell
pwsh -File ./tests/Test-InventorySmoke.ps1
```

Antes de coletar, `scripts/Environment.Validation.ps1` confirma versão do PowerShell, plataforma suportada, comandos nativos obrigatórios e, no Linux, acesso de leitura aos arquivos usados pelo coletor. Se `df` ou `who` estiver ausente no Linux, o validador tenta instalar `coreutils` pelo gerenciador suportado já disponível; pode solicitar `sudo`. Não instala/configura gerenciadores de pacotes. Dependências opcionais indisponíveis (por exemplo, `lastlog` em algumas distribuições Linux) aparecem como avisos; outras dependências nativas obrigatórias ausentes bloqueiam a coleta com diagnóstico. No escopo atual, os coletores usam recursos do sistema operacional e não requerem módulos PowerShell de terceiros.

## Dados no relatório

- `schemaVersion`, `collectedAtUtc` e `collectorVersion`.
- `environmentValidation`: plataforma, versão PowerShell e verificações obrigatórias/avisos concluídas antes da coleta.
- `device`: hostname, sistema operacional, arquitetura, fabricante/modelo/serial quando disponíveis, CPU, memória, armazenamento e interfaces de rede.
- `users.currentUser`: usuário da sessão que executa o coletor, nome de exibição local quando disponível e identificador local (SID/UID).
- `users.localAccounts`: contas locais, identificador, indicação de privilégio administrativo e último logon quando a plataforma o fornece. `lastLogonStatus` distingue `recorded`, `noRecord` e `unavailable`; `noRecord` significa que a fonte consultada não apresentou um registro, não uma garantia de que a conta nunca foi usada.
- `users.activeSessions`: sessões que o sistema consegue enumerar, com início e duração quando interpretáveis.
- `activity`: uptime e início/duração da sessão atual quando disponíveis.
- `issues`: lista de campos que não puderam ser obtidos ou interpretados. Valores ausentes não devem ser tratados como zero ou como prova de inexistência.

Listas de contas incluem contas de serviço e sistema quando a plataforma as apresenta como contas locais. A classificação de administrador reflete os grupos locais reconhecidos pelo coletor e pode variar conforme a configuração da distribuição ou do equipamento.

## Limitações e privacidade

As APIs e comandos dos sistemas operacionais diferem; por isso, nome completo, último logon, contas administrativas e horários de sessão podem não estar disponíveis ou ter formatos distintos. A primeira versão reporta limitações em `issues` em vez de afirmar que um dado inexistente foi coletado.

O relatório pode conter nomes de usuário, SID/UID, número de série, endereço MAC e endereços IP. Armazene e compartilhe esses arquivos conforme as regras de privacidade da organização. O executor não coleta senhas, tokens ou credenciais e não envia os dados para fora do equipamento.

## Fora do escopo

- Integração com Active Directory ou outros diretórios.
- Inventário centralizado, envio automático, agendamento e instalação/correção remota.
- Garantia de coleta de dados que o sistema operacional não disponibiliza ao usuário atual.
