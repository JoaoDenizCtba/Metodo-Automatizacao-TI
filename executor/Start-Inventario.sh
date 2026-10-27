#!/bin/sh
set -eu

SCRIPT_DIR=$(CDPATH= cd "$(dirname "$0")" && pwd)
OPERATING_SYSTEM=$(uname -s)

validate_pwsh() {
    candidate=$1
    "$candidate" -NoLogo -NoProfile -Command 'if ($PSVersionTable.PSVersion.Major -ge 7) { exit 0 } else { exit 1 }' >/dev/null 2>&1
}

find_installed_pwsh() {
    for candidate in \
        "$(command -v pwsh 2>/dev/null || true)" \
        "$HOME/.local/bin/pwsh" \
        /usr/local/bin/pwsh \
        /opt/homebrew/bin/pwsh \
        /usr/bin/pwsh; do
        if [ -n "$candidate" ] && [ -x "$candidate" ] && validate_pwsh "$candidate"; then
            printf '%s\n' "$candidate"
            return 0
        fi
    done

    return 1
}

PWSH_PATH=$(find_installed_pwsh || true)
if [ -z "$PWSH_PATH" ]; then
    case "$OPERATING_SYSTEM" in
        Linux)
            sh "$SCRIPT_DIR/bootstrap/Install-PowerShell-Linux.sh"
            ;;
        Darwin)
            sh "$SCRIPT_DIR/bootstrap/Install-PowerShell-macOS.sh"
            ;;
        *)
            printf '%s\n' "Erro: sistema operacional não suportado por este inicializador: $OPERATING_SYSTEM" >&2
            exit 1
            ;;
    esac

    PWSH_PATH=$(find_installed_pwsh || true)
fi

if [ -z "$PWSH_PATH" ]; then
    printf '%s\n' 'Erro: PowerShell 7 não foi localizado após a preparação do ambiente.' >&2
    exit 1
fi

exec "$PWSH_PATH" -NoLogo -NoProfile -File "$SCRIPT_DIR/Invoke-Inventario.ps1" "$@"
