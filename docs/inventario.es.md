# Inventario local — primera versión

[Português](inventario.md) | [Español](inventario.es.md) | [English](inventario.en.md)

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
