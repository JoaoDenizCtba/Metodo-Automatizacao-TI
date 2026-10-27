#!/bin/sh
set -eu

SCRIPT_DIR=$(CDPATH= cd "$(dirname "$0")" && pwd)
. "$SCRIPT_DIR/PowerShell-Bootstrap.Common.sh"

OPERATING_SYSTEM=$(uname -s)
if [ "$OPERATING_SYSTEM" != 'Darwin' ]; then
    printf '%s\n' "Erro: este instalador suporta macOS, não $OPERATING_SYSTEM." >&2
    exit 1
fi

machine_architecture=$(uname -m)
case "$machine_architecture" in
    arm64) package_architecture=arm64 ;;
    x86_64) package_architecture=x64 ;;
    *)
        printf '%s\n' "Erro: arquitetura macOS não suportada para instalação automática: $machine_architecture" >&2
        exit 1
        ;;
esac

if command -v brew >/dev/null 2>&1; then
    printf '%s\n' 'PowerShell 7 ausente. Tentando instalar pelo Homebrew já disponível.'
    if brew install --cask powershell && command -v pwsh >/dev/null 2>&1; then
        exit 0
    fi
    printf '%s\n' 'Homebrew não concluiu a instalação; tentando o pacote oficial assinado.' >&2
fi

release_json=$(get_latest_release)
get_release_identity

asset_name=$(printf '%s\n' "$release_json" |
    grep -oE '"name": "[^"]+osx-[^"]+\.pkg"' |
    sed 's/^"name": "//; s/"$//' |
    grep -E "osx-$package_architecture\\.pkg$" |
    head -n 1)
if [ -z "$asset_name" ]; then
    printf '%s\n' "Erro: a release oficial não contém pacote macOS para $package_architecture." >&2
    exit 1
fi

asset_data=$(get_release_asset "$asset_name" "$release_json")
asset_url=$(get_release_value browser_download_url "$asset_data")
digest=$(get_release_value digest "$asset_data")
case "$digest" in
    sha256:*) expected_hash=${digest#sha256:} ;;
    *)
        printf '%s\n' "Erro: a release oficial não publicou digest SHA-256 para $asset_name." >&2
        exit 1
        ;;
esac

if [ -z "$asset_url" ] || [ "${#expected_hash}" -ne 64 ]; then
    printf '%s\n' "Erro: a release oficial não contém URL e digest válidos para $asset_name." >&2
    exit 1
fi

temporary_directory=$(mktemp -d "${TMPDIR:-/tmp}/metodo-inventario.XXXXXX")
trap 'rm -rf "$temporary_directory"' EXIT HUP INT TERM
package_path="$temporary_directory/$asset_name"
download_file "$asset_url" "$package_path"
verify_sha256 "$package_path" "$expected_hash"

if ! pkgutil --check-signature "$package_path" 2>&1 | grep -q 'Developer ID Installer: Microsoft Corporation'; then
    printf '%s\n' 'Erro: o pacote não possui assinatura de instalador da Microsoft.' >&2
    exit 1
fi

printf '%s\n' "Instalando PowerShell 7 $release_tag pelo pacote oficial; o macOS solicitará autorização administrativa."
run_with_privileges installer -pkg "$package_path" -target /
