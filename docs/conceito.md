# Conceito Estruturado de Automação

Este método foi desenvolvido com base nas necessidades reais de automação em ambientes corporativos, com foco em modularidade, clareza e controle.

## Princípios do Método

- **Scripts especializados por tarefa**
- **Executor centralizado que gerencia execuções**
- **Matriz JSON como fonte de verdade**
- **Documentação e versionamento**

## Componentes

- `executor/Start-Inventario.cmd`, `executor/Start-Inventario.sh` e `executor/Bootstrap-Windows.ps1`: inicializam PowerShell 7 por caminhos específicos de plataforma.
- `executor/bootstrap/Install-PowerShell-Linux.sh` e `executor/bootstrap/Install-PowerShell-macOS.sh`: preparam PowerShell com gerenciadores já configurados ou pacotes oficiais verificados.
- `executor/bootstrap/PowerShell-Bootstrap.Common.sh`: compartilhamento da consulta de release, download, verificação de integridade e privilégios.
- `executor/Invoke-Inventario.ps1`: orquestrador que valida a matriz e o ambiente, seleciona o coletor do sistema operacional e grava o resultado.
- `matriz/inventario.json`: parâmetros versionados da coleta e do relatório.
- `scripts/Inventario.Common.ps1`: funções compartilhadas para erros, comandos nativos, datas e rede.
- `scripts/Environment.Validation.ps1`: valida pré-requisitos obrigatórios e identifica limitações antes da coleta.
- `scripts/Inventario.Windows.ps1`, `scripts/Inventario.Linux.ps1` e `scripts/Inventario.macOS.ps1`: coletores especializados por sistema operacional.
- `docs/inventario.md`: definição do escopo, formato do relatório e limitações conhecidas.
- `tests/Test-InventorySmoke.ps1`: teste de fumaça da estrutura JSON.
- `.github/workflows/test-inventory.yml`: validação multiplataforma automatizada.

## Escopo inicial

A primeira entrega é um inventário somente leitura para equipamentos Windows, Linux e macOS fora de domínio. O relatório permanece local por padrão. O módulo de domínio/Active Directory fica fora deste escopo e poderá ser adicionado futuramente como uma especialização separada.

Este conceito está em constante evolução e poderá ser adaptado conforme novas necessidades.
