# Concepto estructurado de automatización

[Português](conceito.md) | [Español](conceito.es.md) | [English](conceito.en.md)

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
