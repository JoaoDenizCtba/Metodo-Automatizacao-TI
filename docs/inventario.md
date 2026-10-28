# Inventário local — primeira versão

[Português](#portugues) | [Español](#espanol) | [English](#english)

<a id="portugues"></a>

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

---

<a id="espanol"></a>

# Inventario local — primera versión

## Objetivo

Recopilar información local de equipos Windows, Linux y macOS que no están unidos a un dominio, mediante PowerShell 7 o posterior. El ejecutor selecciona un recolector específico del sistema operativo y guarda un archivo JSON; el proyecto no envía datos por red ni modifica la configuración del equipo durante la recopilación.

## Requisitos previos

- PowerShell 7 o posterior (`pwsh`).
- El inicializador puede descargar la versión estable del repositorio oficial de PowerShell; los paquetes MSI/PKG requieren autorización administrativa y la alternativa de instalación en Linux se realiza por usuario.
- En Windows, acceso a los cmdlets CIM y LocalAccounts, normalmente incluidos en el sistema.
- En Linux, acceso de lectura a `/etc/passwd`, `/etc/group` y `/proc`; se utilizan los comandos `df`, `who` y `lastlog` cuando están disponibles.
- En macOS, disponibilidad de `sw_vers`, `system_profiler`, `dscl`, `last`, `who`, `sysctl` y `df`.
- En Linux, `df` y `who` son requisitos obligatorios; si faltan, el validador intenta instalar `coreutils` mediante un gestor de paquetes compatible ya disponible.
- Algunos datos pueden depender de los permisos y de los comandos instalados.

## Ejecución

Utilice los inicializadores nativos, que comprueban o instalan PowerShell 7 antes de ejecutar el orquestador:

**Windows**

```powershell
.\executor\Start-Inventario.cmd
```

**Linux y macOS**

```sh
sh ./executor/Start-Inventario.sh
```

El inicializador utiliza un gestor de paquetes compatible que ya esté disponible y ofrezca PowerShell. Si no hay ninguno adecuado, descarga la versión estable oficial del proyecto PowerShell, compara el SHA-256 publicado por la API de versiones y verifica la firma del instalador en los formatos MSI/PKG. En Windows, se intenta usar WinGet antes que MSI. En macOS, se intenta Homebrew antes que PKG. En Linux, APT, DNF, YUM, Zypper o APK solo se utilizan si el repositorio configurado ofrece el paquete; de lo contrario, el archivo oficial verificado se instala en el perfil del usuario. Las instalaciones a nivel del sistema pueden solicitar autorización administrativa.

La prueba y la ejecución directa están disponibles si PowerShell 7 ya está instalado:

```powershell
pwsh -File ./executor/Invoke-Inventario.ps1
```

De forma predeterminada, el archivo se guarda en una carpeta local de datos del usuario. La ruta se puede cambiar:

```powershell
pwsh -File ./executor/Invoke-Inventario.ps1 -OutputPath ./inventario.json
```

Las carpetas predeterminadas son `%LOCALAPPDATA%\Metodo-Automatizacao-TI\inventarios` en Windows, `~/Library/Application Support/Metodo-Automatizacao-TI/inventarios` en macOS y `~/.local/share/Metodo-Automatizacao-TI/inventarios` en Linux.

`-WhatIf` muestra la operación de escritura sin crear el archivo. `-ConfigPath` permite indicar otra matriz compatible con la versión 1.

La prueba de humo para el sistema actual se ejecuta así:

```powershell
pwsh -File ./tests/Test-InventorySmoke.ps1
```

Antes de recopilar datos, `scripts/Environment.Validation.ps1` comprueba la versión de PowerShell, la plataforma admitida, los comandos nativos obligatorios y, en Linux, el acceso de lectura a los archivos utilizados por el recolector. Si faltan `df` o `who` en Linux, el validador intenta instalar `coreutils` mediante un gestor de paquetes compatible que ya esté disponible; puede solicitar `sudo`. No instala ni configura gestores de paquetes. Las dependencias opcionales no disponibles (por ejemplo, `lastlog` en algunas distribuciones de Linux) se notifican como advertencias; si faltan otras dependencias nativas obligatorias, la recopilación se bloquea con un diagnóstico. En el alcance actual, los recolectores utilizan recursos del sistema operativo y no requieren módulos de PowerShell de terceros.

## Datos del informe

- `schemaVersion`, `collectedAtUtc` y `collectorVersion`.
- `environmentValidation`: plataforma, versión de PowerShell y verificaciones obligatorias y advertencias completadas antes de la recopilación.
- `device`: nombre de host, sistema operativo, arquitectura, fabricante/modelo/número de serie cuando están disponibles, CPU, memoria, almacenamiento e interfaces de red.
- `users.currentUser`: usuario de la sesión que ejecuta el recolector, nombre para mostrar local cuando está disponible e identificador local (SID/UID).
- `users.localAccounts`: cuentas locales, identificador, indicación de privilegios administrativos y último inicio de sesión cuando la plataforma lo proporciona. `lastLogonStatus` distingue `recorded`, `noRecord` y `unavailable`; `noRecord` significa que la fuente consultada no proporcionó un registro, no que la cuenta nunca se haya utilizado.
- `users.activeSessions`: sesiones que el sistema puede enumerar, con inicio y duración cuando se pueden interpretar.
- `activity`: tiempo de actividad del sistema e inicio/duración de la sesión actual cuando están disponibles.
- `issues`: lista de campos que no se pudieron obtener o interpretar. Los valores ausentes no deben tratarse como cero ni como prueba de inexistencia.

Las listas de cuentas incluyen cuentas de servicio y del sistema cuando la plataforma las presenta como cuentas locales. La clasificación de administrador refleja los grupos locales reconocidos por el recolector y puede variar según la configuración de la distribución o del equipo.

## Limitaciones y privacidad

Las API y los comandos de los sistemas operativos difieren. Por ello, es posible que el nombre completo, el último inicio de sesión, las cuentas administrativas y los horarios de sesión no estén disponibles o tengan formatos distintos. La primera versión informa las limitaciones en `issues` en lugar de afirmar que se recopiló un dato inexistente.

El informe puede contener nombres de usuario, SID/UID, número de serie, dirección MAC y direcciones IP. Almacene y comparta estos archivos de acuerdo con las reglas de privacidad de su organización. El ejecutor no recopila contraseñas, tokens ni credenciales y no envía los datos fuera del equipo.

## Fuera del alcance

- Integración con Active Directory u otros directorios.
- Inventario centralizado, envío automático, programación e instalación o corrección remotas.
- Garantía de recopilación de datos que el sistema operativo no proporciona al usuario actual.

---

<a id="english"></a>

# Local Inventory — First Version

## Objective

Collect local information from Windows, Linux, and macOS machines that are not domain-joined, using PowerShell 7 or later. The executor selects an operating-system-specific collector and writes a JSON file; the project does not send data over the network or change system configuration during collection.

## Prerequisites

- PowerShell 7 or later (`pwsh`).
- The launcher may download the stable release from the official PowerShell repository; MSI/PKG packages require administrative authorization, while the Linux fallback installs per user.
- On Windows, access to the CIM and LocalAccounts cmdlets, which are normally included with the system.
- On Linux, read access to `/etc/passwd`, `/etc/group`, and `/proc`; the `df`, `who`, and `lastlog` commands are used when available.
- On macOS, availability of `sw_vers`, `system_profiler`, `dscl`, `last`, `who`, `sysctl`, and `df`.
- On Linux, `df` and `who` are required prerequisites; if either is missing, the validator attempts to install `coreutils` through an existing supported package manager.
- Some information may depend on permissions and installed commands.

## Running

Use the native launchers, which check for or install PowerShell 7 before invoking the orchestrator:

**Windows**

```powershell
.\executor\Start-Inventario.cmd
```

**Linux and macOS**

```sh
sh ./executor/Start-Inventario.sh
```

The launcher uses a supported package manager that is already available and provides PowerShell. If no suitable manager is available, it downloads the official stable PowerShell release, compares its SHA-256 with the value published by the releases API, and verifies the installer signature for MSI/PKG formats. On Windows, WinGet is tried before MSI. On macOS, Homebrew is tried before PKG. On Linux, APT, DNF, YUM, Zypper, or APK is used only when the configured repository offers the package; otherwise, the verified official archive is installed in the user's profile. System installations may require administrator authorization.

The test and direct execution are also available when PowerShell 7 is already installed:

```powershell
pwsh -File ./executor/Invoke-Inventario.ps1
```

By default, the file is written to a local user data directory. You can override the path:

```powershell
pwsh -File ./executor/Invoke-Inventario.ps1 -OutputPath ./inventario.json
```

The default directories are `%LOCALAPPDATA%\Metodo-Automatizacao-TI\inventarios` on Windows, `~/Library/Application Support/Metodo-Automatizacao-TI/inventarios` on macOS, and `~/.local/share/Metodo-Automatizacao-TI/inventarios` on Linux.

`-WhatIf` previews the write operation without creating the file. `-ConfigPath` lets you specify another matrix compatible with version 1.

Run the smoke test for the current system with:

```powershell
pwsh -File ./tests/Test-InventorySmoke.ps1
```

Before collection, `scripts/Environment.Validation.ps1` checks the PowerShell version, supported platform, required native commands, and, on Linux, read access to files used by the collector. If `df` or `who` is missing on Linux, the validator attempts to install `coreutils` through an existing supported package manager; this may require `sudo`. It does not install or configure package managers. Unavailable optional dependencies (for example, `lastlog` on some Linux distributions) are reported as warnings; missing other required native dependencies block collection with a diagnostic. In the current scope, the collectors use operating-system facilities and do not require third-party PowerShell modules.

## Report data

- `schemaVersion`, `collectedAtUtc`, and `collectorVersion`.
- `environmentValidation`: platform, PowerShell version, and required checks and warnings completed before collection.
- `device`: hostname, operating system, architecture, manufacturer/model/serial number when available, CPU, memory, storage, and network interfaces.
- `users.currentUser`: the user running the collector, local display name when available, and local identifier (SID/UID).
- `users.localAccounts`: local accounts, identifier, administrative-privilege indicator, and last logon when provided by the platform. `lastLogonStatus` distinguishes `recorded`, `noRecord`, and `unavailable`; `noRecord` means the queried source returned no record, not that the account has never been used.
- `users.activeSessions`: sessions the system can enumerate, with start time and duration when interpretable.
- `activity`: system uptime and current session start/duration when available.
- `issues`: fields that could not be obtained or interpreted. Missing values must not be treated as zero or as proof that something does not exist.

Account lists include service and system accounts when the platform exposes them as local accounts. The administrator classification reflects local groups recognized by the collector and may vary with the distribution or machine configuration.

## Limitations and privacy

Operating-system APIs and commands differ. As a result, full name, last logon, administrative accounts, and session times may be unavailable or use different formats. The first version reports limitations in `issues` rather than claiming that unavailable data was collected.

The report may contain usernames, SID/UID values, serial numbers, MAC addresses, and IP addresses. Store and share these files according to your organization's privacy rules. The executor does not collect passwords, tokens, or credentials and does not send data off the machine.

## Out of scope

- Active Directory or other directory integration.
- Centralized inventory, automatic submission, scheduling, and remote installation or remediation.
- Guaranteeing collection of data that the operating system does not expose to the current user.
