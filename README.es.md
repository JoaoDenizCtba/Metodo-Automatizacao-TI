# Método personal de automatización de tareas de TI

[Português](README.md) | [Español](README.es.md) | [English](README.en.md)

Este repositorio presenta un método modular para automatizar tareas de TI en Windows, Linux y macOS mediante PowerShell 7+, scripts especializados y archivos JSON.

> **Alcance actual:** la implementación disponible es el módulo inicial de inventario local. La verificación de software, la autenticación, Active Directory y la automatización remota son posibilidades futuras, no funcionalidades que se ofrezcan actualmente.

## Principios de organización

- **Separación de responsabilidades:** el inicio, la validación del entorno, la orquestación y la recopilación específica de cada sistema operativo se mantienen en componentes distintos.
- **Orquestador central:** carga y valida la configuración, selecciona el recolector adecuado y guarda el informe.
- **Configuración versionada:** `matriz/inventario.json` contiene los parámetros utilizados por el inventario; no es un catálogo de dispositivos ni de software.
- **Validación y documentación:** las pruebas locales y la integración continua verifican aspectos de la implementación en más de un sistema operativo.

## Componentes actuales

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

## Primera ejecución

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

## Datos y privacidad

El informe puede incluir identificadores del dispositivo, cuentas locales y direcciones de red. Revise [docs/inventario.md](docs/inventario.md) y las reglas de privacidad de su organización antes de almacenar o compartir los archivos.

La recopilación del inventario no envía el informe a servicios externos. Sin embargo, los inicializadores pueden acceder a Internet para obtener PowerShell si no está disponible. La instalación de dependencias también puede modificar el equipo, según el gestor de paquetes utilizado.

## Pruebas

Para validar la recopilación en el equipo actual, con PowerShell 7 instalado:

```powershell
pwsh -File ./tests/Test-InventorySmoke.ps1
```

El workflow de GitHub Actions también comprueba la sintaxis de los inicializadores y ejecuta pruebas en Windows, Linux y macOS.

## Limitaciones y documentación

El alcance actual es un inventario local, sin integración con Active Directory, envío centralizado de informes, programación ni instalación o corrección remotas. La disponibilidad de algunos datos depende del sistema operativo, de los comandos instalados y de los permisos del usuario.

- [Alcance, formato y limitaciones del inventario](docs/inventario.md) — disponible en portugués.
- [Concepto estructurado de automatización](docs/conceito.md) — disponible en portugués.

Las traducciones al español y al inglés de este README están separadas; los documentos detallados de `docs/` todavía no se han traducido.

## Autor

João Alberto R. Deniz Junior – Analista de Infraestructura Sénior
