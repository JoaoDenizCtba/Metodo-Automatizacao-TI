# Método Pessoal de Automação de Tarefas de TI

[Português](README.md) | [Español](README.es.md) | [English](README.en.md)

Este repositório apresenta um método modular para automação de tarefas de TI em Windows, Linux e macOS, usando PowerShell 7+, scripts especializados e arquivos JSON.

> **Escopo atual:** a implementação disponível é o módulo inicial de inventário local. Verificação de softwares, autenticação, Active Directory e automação remota são possibilidades futuras, não funcionalidades atualmente fornecidas.

## Princípios de organização

- **Separação por responsabilidade:** inicialização, validação do ambiente, orquestração e coleta por sistema operacional ficam em componentes distintos.
- **Orquestrador central:** carrega e valida a configuração, seleciona o coletor apropriado e grava o relatório.
- **Configuração versionada:** `matriz/inventario.json` mantém os parâmetros usados pelo inventário; não representa um catálogo de dispositivos ou softwares.
- **Validação e documentação:** testes locais e integração contínua verificam aspectos da implementação em mais de um sistema operacional.

## Componentes atuais

- `executor/Invoke-Inventario.ps1`: orquestra a validação, a coleta e a gravação do relatório JSON.
- `executor/Start-Inventario.cmd` e `executor/Start-Inventario.sh`: inicializadores que verificam ou preparam PowerShell 7 antes de executar o orquestrador.
- `executor/Bootstrap-Windows.ps1`: inicializador Windows PowerShell 5.1; tenta WinGet e valida o instalador oficial no caminho alternativo.
- `executor/bootstrap/Install-PowerShell-Linux.sh` e `executor/bootstrap/Install-PowerShell-macOS.sh`: preparam PowerShell usando gerenciadores compatíveis já disponíveis ou pacotes oficiais verificados.
- `executor/bootstrap/PowerShell-Bootstrap.Common.sh`: reúne funções de consulta de release, download, verificação SHA-256 e privilégios.
- `matriz/inventario.json`: contém a versão da configuração e os parâmetros de saída do inventário.
- `scripts/Inventario.Common.ps1`: funções compartilhadas pelos coletores.
- `scripts/Environment.Validation.ps1`: verifica a plataforma, a versão do PowerShell e os pré-requisitos da coleta. No Linux, tenta instalar `coreutils` se `df` ou `who` estiver ausente.
- `scripts/Inventario.Windows.ps1`, `scripts/Inventario.Linux.ps1` e `scripts/Inventario.macOS.ps1`: coletores específicos de cada sistema operacional.
- `tests/Test-InventorySmoke.ps1`: teste de fumaça da estrutura do relatório.
- `tests/Test-BootstrapMetadata.sh`: teste de metadados do inicializador POSIX.
- `.github/workflows/test-inventory.yml`: validação automatizada em Windows, Linux e macOS.

## Primeira execução

Os inicializadores nativos verificam ou preparam PowerShell 7 quando necessário.

**Windows**

```powershell
.\executor\Start-Inventario.cmd
```

**Linux e macOS**

```sh
sh ./executor/Start-Inventario.sh
```

O inicializador usa um gerenciador de pacotes compatível já disponível quando possível. Caso contrário, pode baixar a release oficial do PowerShell e verificar os metadados de integridade e a assinatura nos formatos compatíveis. Uma instalação de sistema pode solicitar privilégios administrativos; no fallback Linux baseado em arquivo, a instalação é feita no perfil do usuário.

No Linux, a validação pode tentar instalar `coreutils` pelo gerenciador suportado existente se `df` ou `who` estiver ausente. Essa etapa pode solicitar `sudo`; o projeto não instala nem configura um novo gerenciador de pacotes. Outras dependências obrigatórias ausentes interrompem a coleta com diagnóstico.

Se PowerShell 7 já estiver instalado, é possível executar o orquestrador diretamente:

```powershell
pwsh -File ./executor/Invoke-Inventario.ps1
```

Por padrão, o relatório é gravado em uma pasta de dados local do usuário. Para escolher outro caminho:

```powershell
pwsh -File ./executor/Invoke-Inventario.ps1 -OutputPath ./inventario.json
```

O parâmetro `-WhatIf` simula a gravação sem criar o arquivo. `-ConfigPath` permite informar outra matriz compatível com a versão 1.

## Dados e privacidade

O relatório pode incluir identificadores do dispositivo, contas locais e endereços de rede. Revise [docs/inventario.md](docs/inventario.md) e as regras de privacidade da organização antes de armazenar ou compartilhar os arquivos.

A coleta do inventário não envia o relatório para serviços externos. Entretanto, os inicializadores podem acessar a internet para obter PowerShell quando ele não estiver disponível. A instalação de dependências também pode alterar o equipamento, conforme o gerenciador de pacotes utilizado.

## Testes

Para validar a coleta no equipamento atual, com PowerShell 7 instalado:

```powershell
pwsh -File ./tests/Test-InventorySmoke.ps1
```

O workflow do GitHub Actions também verifica a sintaxe dos inicializadores e executa testes em Windows, Linux e macOS.

## Limitações e documentação

O escopo atual é um inventário local, sem integração com Active Directory, envio centralizado de relatórios, agendamento ou instalação e correção remotas. A disponibilidade de alguns dados depende do sistema operacional, dos comandos presentes e das permissões do usuário.

- [Escopo, formato e limitações do inventário](docs/inventario.md) — disponível em português.
- [Conceito estruturado de automação](docs/conceito.md) — disponível em português.

As traduções em espanhol e inglês deste README são separadas; os documentos detalhados em `docs/` ainda não foram traduzidos.

## Autor

João Alberto R. Deniz Junior – Analista de Infraestrutura Sênior
