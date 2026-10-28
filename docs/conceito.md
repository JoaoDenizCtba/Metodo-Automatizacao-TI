# Conceito Estruturado de Automação

[Português](#portugues) | [Español](#espanol) | [English](#english)

<a id="portugues"></a>

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

---

<a id="espanol"></a>

# Concepto estructurado de automatización

Este método se desarrolló a partir de necesidades reales de automatización en entornos corporativos, con énfasis en la modularidad, la claridad y el control.

## Principios del método

- **Scripts especializados por tarea**
- **Un ejecutor centralizado que administra las ejecuciones**
- **Una matriz JSON como fuente de verdad**
- **Documentación y control de versiones**

## Componentes

- `executor/Start-Inventario.cmd`, `executor/Start-Inventario.sh` y `executor/Bootstrap-Windows.ps1`: inicializan PowerShell 7 mediante procedimientos específicos de cada plataforma.
- `executor/bootstrap/Install-PowerShell-Linux.sh` y `executor/bootstrap/Install-PowerShell-macOS.sh`: preparan PowerShell mediante gestores de paquetes ya configurados o paquetes oficiales verificados.
- `executor/bootstrap/PowerShell-Bootstrap.Common.sh`: comparte las funciones de consulta de versiones, descarga, verificación de integridad y gestión de privilegios.
- `executor/Invoke-Inventario.ps1`: orquesta la validación de la matriz y del entorno, selecciona el recolector del sistema operativo y guarda el resultado.
- `matriz/inventario.json`: contiene parámetros versionados para la recopilación y el informe.
- `scripts/Inventario.Common.ps1`: funciones compartidas para errores, comandos nativos, fechas y red.
- `scripts/Environment.Validation.ps1`: valida los requisitos obligatorios e identifica limitaciones antes de la recopilación.
- `scripts/Inventario.Windows.ps1`, `scripts/Inventario.Linux.ps1` y `scripts/Inventario.macOS.ps1`: recolectores especializados por sistema operativo.
- `docs/inventario.md`: define el alcance, el formato del informe y las limitaciones conocidas.
- `tests/Test-InventorySmoke.ps1`: prueba de humo de la estructura JSON.
- `.github/workflows/test-inventory.yml`: validación multiplataforma automatizada.

## Alcance inicial

La primera entrega es un inventario de solo lectura para equipos Windows, Linux y macOS que no están unidos a un dominio. De forma predeterminada, el informe permanece en el equipo local. El módulo para dominios/Active Directory queda fuera de este alcance y podría añadirse en el futuro como una especialización independiente.

Este concepto está en evolución continua y podrá adaptarse a nuevas necesidades.

---

<a id="english"></a>

# Structured Automation Concept

This method was developed in response to real automation needs in corporate environments, with an emphasis on modularity, clarity, and control.

## Method principles

- **Task-specific scripts**
- **A centralized executor that manages runs**
- **A JSON matrix as the source of truth**
- **Documentation and version control**

## Components

- `executor/Start-Inventario.cmd`, `executor/Start-Inventario.sh`, and `executor/Bootstrap-Windows.ps1`: initialize PowerShell 7 through platform-specific paths.
- `executor/bootstrap/Install-PowerShell-Linux.sh` and `executor/bootstrap/Install-PowerShell-macOS.sh`: prepare PowerShell using existing package managers or verified official packages.
- `executor/bootstrap/PowerShell-Bootstrap.Common.sh`: shared release lookup, download, integrity verification, and privilege handling.
- `executor/Invoke-Inventario.ps1`: orchestrates matrix and environment validation, selects the operating-system collector, and writes the result.
- `matriz/inventario.json`: contains versioned parameters for collection and reporting.
- `scripts/Inventario.Common.ps1`: shared functions for errors, native commands, dates, and networking.
- `scripts/Environment.Validation.ps1`: validates required prerequisites and identifies limitations before collection.
- `scripts/Inventario.Windows.ps1`, `scripts/Inventario.Linux.ps1`, and `scripts/Inventario.macOS.ps1`: specialized collectors for each operating system.
- `docs/inventario.md`: defines the inventory scope, report format, and known limitations.
- `tests/Test-InventorySmoke.ps1`: smoke test for the JSON structure.
- `.github/workflows/test-inventory.yml`: automated cross-platform validation.

## Initial scope

The first release is a read-only inventory for Windows, Linux, and macOS machines that are not domain-joined. By default, the report remains on the local machine. Domain/Active Directory support is outside the current scope and may be added later as a separate specialization.

This concept is continuously evolving and may be adapted to meet new needs.
