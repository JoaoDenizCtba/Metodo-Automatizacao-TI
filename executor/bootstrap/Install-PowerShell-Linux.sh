#!/bin/sh
set -eu

SCRIPT_DIR=$(CDPATH= cd "$(dirname "$0")" && pwd)
. "$SCRIPT_DIR/PowerShell-Bootstrap.Common.sh"

try_linux_package_manager() {
    case "$1" in
        apt-get)
            if command -v apt-cache >/dev/null 2>&1 &&
                apt-cache policy powershell 2>/dev/null | grep -q 'Candidate: [^()[:space:]]'; then
                if run_with_privileges apt-get install -y powershell; then
                    return 0
                fi
                printf '%s\n' 'Erro: a instalação do PowerShell pelo APT falhou.' >&2
                return 2
            fi
            ;;
        dnf)
            if dnf -q info powershell 2>/dev/null | grep -q 'Available Packages'; then
                if run_with_privileges dnf install -y powershell; then
                    return 0
                fi
                printf '%s\n' 'Erro: a instalação do PowerShell pelo DNF falhou.' >&2
                return 2
            fi
            ;;
        yum)
            if yum -q info powershell 2>/dev/null | grep -q 'Available Packages'; then
                if run_with_privileges yum install -y powershell; then
                    return 0
                fi
                printf '%s\n' 'Erro: a instalação do PowerShell pelo YUM falhou.' >&2
                return 2
            fi
            ;;
        zypper)
            if zypper --non-interactive search --match-exact powershell 2>/dev/null |
                grep -Eq '^[[:space:]]*\|[[:space:]]*powershell[[:space:]]*\|'; then
                if run_with_privileges zypper --non-interactive install -y powershell; then
                    return 0
                fi
                printf '%s\n' 'Erro: a instalação do PowerShell pelo Zypper falhou.' >&2
                return 2
            fi
            ;;
        apk)
            if apk search -x powershell 2>/dev/null | grep -q '^powershell-'; then
                if run_with_privileges apk add powershell; then
                    return 0
                fi
                printf '%s\n' 'Erro: a instalação do PowerShell pelo APK falhou.' >&2
                return 2
            fi
            ;;
    esac

    return 1
}

install_user_archive() {
    machine_architecture=$(uname -m)
    case "$machine_architecture" in
        x86_64|amd64) package_architecture=x64 ;;
        aarch64|arm64) package_architecture=arm64 ;;
        armv7l|armv7*) package_architecture=arm ;;
        *)
            printf '%s\n' "Erro: arquitetura Linux não suportada para instalação automática: $machine_architecture" >&2
            return 1
            ;;
    esac

    linux_asset_os=linux
    if [ -r /etc/os-release ] && grep -qi '^ID=alpine' /etc/os-release; then
        linux_asset_os=linux-musl
    fi

    asset_name="powershell-$release_version-$linux_asset_os-$package_architecture.tar.gz"
    asset_data=$(get_release_asset "$asset_name" "$release_json")
    asset_url=$(get_release_value browser_download_url "$asset_data")
    digest=$(get_release_value digest "$asset_data")
    case "$digest" in
        sha256:*) expected_hash=${digest#sha256:} ;;
        *)
            printf '%s\n' "Erro: a release oficial não publicou digest SHA-256 para $asset_name." >&2
            return 1
            ;;
    esac

    if [ -z "$asset_url" ] || [ "${#expected_hash}" -ne 64 ]; then
        printf '%s\n' "Erro: a release oficial não contém o pacote esperado para $machine_architecture." >&2
        return 1
    fi

    temporary_directory=$(mktemp -d "${TMPDIR:-/tmp}/metodo-inventario.XXXXXX")
    trap 'rm -rf "$temporary_directory"' EXIT HUP INT TERM
    archive_path="$temporary_directory/$asset_name"
    download_file "$asset_url" "$archive_path"
    verify_sha256 "$archive_path" "$expected_hash"

    install_directory="$HOME/.local/opt/powershell/$release_version"
    mkdir -p "$install_directory" "$HOME/.local/bin"
    tar -xzf "$archive_path" -C "$install_directory"
    chmod +x "$install_directory/pwsh"
    ln -sf "$install_directory/pwsh" "$HOME/.local/bin/pwsh"

    if command -v ldd >/dev/null 2>&1 && ldd "$install_directory/pwsh" 2>/dev/null | grep -q 'not found'; then
        printf '%s\n' 'Erro: o runtime instalado tem bibliotecas de sistema ausentes. Instale PowerShell pelos pacotes da distribuição e repita a validação.' >&2
        return 1
    fi
}

OPERATING_SYSTEM=$(uname -s)
if [ "$OPERATING_SYSTEM" != 'Linux' ]; then
    printf '%s\n' "Erro: este instalador suporta Linux, não $OPERATING_SYSTEM." >&2
    exit 1
fi

release_json=$(get_latest_release)
get_release_identity

package_manager_installed=false
for package_manager in apt-get dnf yum zypper apk; do
    if command -v "$package_manager" >/dev/null 2>&1; then
        if try_linux_package_manager "$package_manager"; then
            package_manager_installed=true
            break
        else
            package_manager_status=$?
            if [ "$package_manager_status" -ne 1 ]; then
                exit "$package_manager_status"
            fi
        fi
    fi
done

if [ "$package_manager_installed" != true ]; then
    printf '%s\n' 'Nenhum gerenciador já configurado oferece PowerShell; instalando o arquivo oficial verificado por SHA-256 no perfil do usuário.'
    install_user_archive
fi
