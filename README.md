# Método Pessoal de Automação de Tarefas de TI

[Português](#portugues) | [Español](#espanol) | [English](#english)

<a id="portugues"></a>

## Português

Este repositório apresenta um método modular para automação de tarefas de TI em Windows, Linux e macOS, usando PowerShell 7+, scripts especializados e arquivos JSON.

> **Escopo atual:** a implementação disponível é o módulo inicial de inventário local. Verificação de softwares, autenticação, Active Directory e automação remota são possibilidades futuras, não funcionalidades atualmente fornecidas.

### Princípios de organização

- **Separação por responsabilidade:** inicialização, validação do ambiente, orquestração e coleta por sistema operacional ficam em componentes distintos.
- **Orquestrador central:** carrega e valida a configuração, seleciona o coletor apropriado e grava o relatório.
- **Configuração versionada:** `matriz/inventario.json` mantém os parâmetros usados pelo inventário; não representa um catálogo de dispositivos ou softwares.
- **Validação e documentação:** testes locais e integração contínua verificam aspectos da implementação em mais de um sistema operacional.

### Componentes atuais

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

### Primeira execução

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

### Dados e privacidade

O relatório pode incluir identificadores do dispositivo, contas locais e endereços de rede. Revise [docs/inventario.md](docs/inventario.md) e as regras de privacidade da organização antes de armazenar ou compartilhar os arquivos.

A coleta do inventário não envia o relatório para serviços externos. Entretanto, os inicializadores podem acessar a internet para obter PowerShell quando ele não estiver disponível. A instalação de dependências também pode alterar o equipamento, conforme o gerenciador de pacotes utilizado.

### Testes

Para validar a coleta no equipamento atual, com PowerShell 7 instalado:

```powershell
pwsh -File ./tests/Test-InventorySmoke.ps1
```

O workflow do GitHub Actions também verifica a sintaxe dos inicializadores e executa testes em Windows, Linux e macOS.

### Limitações e documentação

O escopo atual é um inventário local, sem integração com Active Directory, envio centralizado de relatórios, agendamento ou instalação e correção remotas. A disponibilidade de alguns dados depende do sistema operacional, dos comandos presentes e das permissões do usuário.

- [Inventário local — português, espanhol e inglês](docs/inventario.md).
- [Conceito de automação — português, espanhol e inglês](docs/conceito.md).

Cada documento de `docs/` reúne as três versões no mesmo arquivo, reduzindo a duplicação e facilitando a manutenção.

### Autor

João Alberto R. Deniz Junior – Analista de Infraestrutura Sênior

---

<a id="espanol"></a>

## Español

# Método personal de automatización de tareas de TI

Este repositorio presenta un método modular para automatizar tareas de TI en Windows, Linux y macOS mediante PowerShell 7+, scripts especializados y archivos JSON.

> **Alcance actual:** la implementación disponible es el módulo inicial de inventario local. La verificación de software, la autenticación, Active Directory y la automatización remota son posibilidades futuras, no funcionalidades que se ofrezcan actualmente.

### Principios de organización

- **Separación de responsabilidades:** el inicio, la validación del entorno, la orquestación y la recopilación específica de cada sistema operativo se mantienen en componentes distintos.
- **Orquestador central:** carga y valida la configuración, selecciona el recolector adecuado y guarda el informe.
- **Configuración versionada:** `matriz/inventario.json` contiene los parámetros utilizados por el inventario; no es un catálogo de dispositivos ni de software.
- **Validación y documentación:** las pruebas locales y la integración continua verifican aspectos de la implementación en más de un sistema operativo.

### Componentes actuales

- `executor/Invoke-Inventario.ps1`: orquesta la validación, la recopilación y la escritura del informe JSON.
- `executor/Start-Inventario.cmd` y `executor/Start-Inventario.sh`: inicializadores que comprueban o preparan PowerShell 7 antes de ejecutar el orquestador.
- `executor/Bootstrap-Windows.ps1`: inicializador para Windows PowerShell 5.1; intenta usar WinGet y valida el instalador oficial como alternativa.
- `executor/bootstrap/Install-PowerShell-Linux.sh` y `executor/bootstrap/Install-PowerShell-macOS.sh`: preparan PowerShell mediante gestores compatibles ya disponibles o paquetes oficiales verificados.
- `executor/bootstrap/PowerShell-Bootstrap.Common.sh`: reúne funciones para consultar versiones, descargar, verificar SHA-256 y gestionar privilegios.
- `matriz/inventario.json`: contiene la versión de la configuración y los parámetros de salida del inventario.
- `scripts/Inventario.Common.ps1`: funciones compartidas por los recolectores.
- `scripts/Environment.Validation.ps1`: comprueba la plataforma, la versión de PowerShell y los requisitos de recopilación. En Linux, intenta instalar `coreutils` si no encuentra `df` o `who`.
- `scripts/Inventario.Windows.ps1`, `scripts/Inventario.Linux.ps1` y `scripts/Inventario.macOS.ps1`: recolectores específicos para cada sistema operativo.
- `tests/Test-InventorySmoke.ps1`: prueba de humo de la estructura del informe.
- `tests/Test-BootstrapMetadata.sh`: prueba de metadatos del inicializador POSIX.
- `.github/workflows/test-inventory.yml`: validación automatizada en Windows, Linux y macOS.

### Primera ejecución

Los inicializadores nativos comprueban o preparan PowerShell 7 cuando es necesario.

**Windows**

```powershell
.\executor\Start-Inventario.cmd
```

**Linux y macOS**

```sh
sh ./executor/Start-Inventario.sh
```

Cuando es posible, el inicializador utiliza un gestor de paquetes compatible que ya esté disponible. De lo contrario, puede descargar la versión oficial de PowerShell y verificar los metadatos de integridad y la firma en los formatos compatibles. Una instalación a nivel del sistema puede solicitar privilegios de administrador; la alternativa de instalación desde un archivo en Linux se realiza en el perfil del usuario.

En Linux, la validación puede intentar instalar `coreutils` mediante el gestor compatible existente si faltan `df` o `who`. Este paso puede solicitar `sudo`; el proyecto no instala ni configura un gestor de paquetes nuevo. Si faltan otros requisitos obligatorios, la recopilación se detiene y muestra un diagnóstico.

Si PowerShell 7 ya está instalado, se puede ejecutar directamente el orquestador:

```powershell
pwsh -File ./executor/Invoke-Inventario.ps1
```

De forma predeterminada, el informe se guarda en una carpeta local de datos del usuario. Para elegir otra ruta:

```powershell
pwsh -File ./executor/Invoke-Inventario.ps1 -OutputPath ./inventario.json
```

El parámetro `-WhatIf` simula la escritura sin crear el archivo. `-ConfigPath` permite indicar otra matriz compatible con la versión 1.

### Datos y privacidad

El informe puede incluir identificadores del dispositivo, cuentas locales y direcciones de red. Revise [docs/inventario.md](docs/inventario.md) y las reglas de privacidad de su organización antes de almacenar o compartir los archivos.

La recopilación del inventario no envía el informe a servicios externos. Sin embargo, los inicializadores pueden acceder a Internet para obtener PowerShell si no está disponible. La instalación de dependencias también puede modificar el equipo, según el gestor de paquetes utilizado.

### Pruebas

Para validar la recopilación en el equipo actual, con PowerShell 7 instalado:

```powershell
pwsh -File ./tests/Test-InventorySmoke.ps1
```

El workflow de GitHub Actions también comprueba la sintaxis de los inicializadores y ejecuta pruebas en Windows, Linux y macOS.

### Limitaciones y documentación

El alcance actual es un inventario local, sin integración con Active Directory, envío centralizado de informes, programación ni instalación o corrección remotas. La disponibilidad de algunos datos depende del sistema operativo, de los comandos instalados y de los permisos del usuario.

- [Inventario local — portugués, español e inglés](docs/inventario.md).
- [Concepto de automatización — portugués, español e inglés](docs/conceito.md).

Cada documento de `docs/` reúne las tres versiones en el mismo archivo, lo que reduce la duplicación y facilita el mantenimiento.

### Autor

João Alberto R. Deniz Junior – Analista de Infraestructura Sénior

---

<a id="english"></a>

## English

# Personal IT Task Automation Method

This repository presents a modular method for automating IT tasks on Windows, Linux, and macOS using PowerShell 7+, specialized scripts, and JSON files.

> **Current scope:** the available implementation is the initial local inventory module. Software verification, authentication, Active Directory, and remote automation are potential future additions, not currently provided features.

### Organizational principles

- **Separation of responsibilities:** setup, environment validation, orchestration, and operating-system-specific collection are handled by distinct components.
- **Central orchestrator:** loads and validates the configuration, selects the appropriate collector, and writes the report.
- **Versioned configuration:** `matriz/inventario.json` stores parameters used by the inventory; it is not a device or software catalog.
- **Validation and documentation:** local tests and continuous integration verify aspects of the implementation across multiple operating systems.

### Current components

- `executor/Invoke-Inventario.ps1`: orchestrates validation, data collection, and JSON report output.
- `executor/Start-Inventario.cmd` and `executor/Start-Inventario.sh`: launchers that check for or prepare PowerShell 7 before running the orchestrator.
- `executor/Bootstrap-Windows.ps1`: Windows PowerShell 5.1 launcher; tries WinGet and validates the official installer as a fallback.
- `executor/bootstrap/Install-PowerShell-Linux.sh` and `executor/bootstrap/Install-PowerShell-macOS.sh`: prepare PowerShell using compatible package managers already available or verified official packages.
- `executor/bootstrap/PowerShell-Bootstrap.Common.sh`: shared release lookup, download, SHA-256 verification, and privilege-handling functions.
- `matriz/inventario.json`: contains the configuration version and inventory output parameters.
- `scripts/Inventario.Common.ps1`: functions shared by the collectors.
- `scripts/Environment.Validation.ps1`: checks the platform, PowerShell version, and collection prerequisites. On Linux, it attempts to install `coreutils` if `df` or `who` is missing.
- `scripts/Inventario.Windows.ps1`, `scripts/Inventario.Linux.ps1`, and `scripts/Inventario.macOS.ps1`: collectors for their respective operating systems.
- `tests/Test-InventorySmoke.ps1`: smoke test for the report structure.
- `tests/Test-BootstrapMetadata.sh`: POSIX launcher metadata test.
- `.github/workflows/test-inventory.yml`: automated validation on Windows, Linux, and macOS.

### First run

The native launchers check for or prepare PowerShell 7 when needed.

**Windows**

```powershell
.\executor\Start-Inventario.cmd
```

**Linux and macOS**

```sh
sh ./executor/Start-Inventario.sh
```

When possible, the launcher uses a compatible package manager that is already available. Otherwise, it may download the official PowerShell release and verify integrity metadata and the installer signature for supported package formats. A system-wide installation may require administrator privileges; the Linux file-based fallback installs to the user's profile.

On Linux, validation may try to install `coreutils` through an existing supported package manager if `df` or `who` is missing. This may require `sudo`; the project does not install or configure a new package manager. If other required prerequisites are missing, collection stops with a diagnostic.

If PowerShell 7 is already installed, you can run the orchestrator directly:

```powershell
pwsh -File ./executor/Invoke-Inventario.ps1
```

By default, the report is written to a local user data directory. To choose another path:

```powershell
pwsh -File ./executor/Invoke-Inventario.ps1 -OutputPath ./inventario.json
```

The `-WhatIf` parameter previews the write without creating the file. `-ConfigPath` lets you specify another matrix compatible with version 1.

### Data and privacy

The report may contain device identifiers, local account information, and network addresses. Review [docs/inventario.md](docs/inventario.md) and your organization's privacy requirements before storing or sharing reports.

The inventory collection does not send the report to external services. However, launchers may access the internet to obtain PowerShell when it is unavailable. Installing dependencies may also modify the machine, depending on the package manager used.

### Tests

To validate collection on the current machine, with PowerShell 7 installed:

```powershell
pwsh -File ./tests/Test-InventorySmoke.ps1
```

The GitHub Actions workflow also checks launcher syntax and runs tests on Windows, Linux, and macOS.

### Limitations and documentation

The current scope is local inventory, with no Active Directory integration, centralized report submission, scheduling, or remote installation and remediation. The availability of some data depends on the operating system, installed commands, and the user's permissions.

- [Local inventory — Portuguese, Spanish, and English](docs/inventario.md).
- [Automation concept — Portuguese, Spanish, and English](docs/conceito.md).

Each document in `docs/` contains all three language versions in one file, reducing duplication and simplifying maintenance.

### Author

João Alberto R. Deniz Junior – Senior Infrastructure Analyst
