download_file() {
    url=$1
    destination=$2

    if command -v curl >/dev/null 2>&1; then
        curl --fail --location --silent --show-error --retry 3 "$url" --output "$destination"
    elif command -v wget >/dev/null 2>&1; then
        wget --https-only --tries=3 --output-document="$destination" "$url"
    else
        printf '%s\n' 'Erro: curl ou wget é necessário para baixar o PowerShell 7 oficial.' >&2
        return 1
    fi
}

get_latest_release() {
    if command -v curl >/dev/null 2>&1; then
        curl --fail --location --silent --show-error \
            --header 'Accept: application/vnd.github+json' \
            --header 'X-GitHub-Api-Version: 2022-11-28' \
            https://api.github.com/repos/PowerShell/PowerShell/releases/latest
    elif command -v wget >/dev/null 2>&1; then
        wget --https-only --quiet --output-document=- \
            --header='Accept: application/vnd.github+json' \
            https://api.github.com/repos/PowerShell/PowerShell/releases/latest
    else
        printf '%s\n' 'Erro: curl ou wget é necessário para consultar a release oficial.' >&2
        return 1
    fi
}

get_release_asset() {
    asset_name=$1
    release_json=$2

    printf '%s\n' "$release_json" |
        awk -v asset="$asset_name" '
            index($0, "\"name\": \"" asset "\"") { found = 1 }
            found { print }
            found && /^  },[[:space:]]*$/ { exit }
        '
}

get_release_value() {
    key=$1
    asset_data=$2
    printf '%s\n' "$asset_data" |
        sed -n "s/.*\"$key\": \"\\([^\"]*\\)\".*/\\1/p" |
        head -n 1
}

verify_sha256() {
    file_path=$1
    expected_hash=$2

    if command -v sha256sum >/dev/null 2>&1; then
        actual_hash=$(sha256sum "$file_path" | awk '{ print $1 }')
    elif command -v shasum >/dev/null 2>&1; then
        actual_hash=$(shasum -a 256 "$file_path" | awk '{ print $1 }')
    else
        printf '%s\n' 'Erro: sha256sum ou shasum é necessário para verificar o instalador.' >&2
        return 1
    fi

    if [ "$actual_hash" != "$expected_hash" ]; then
        printf '%s\n' 'Erro: SHA-256 do instalador não corresponde ao digest da release oficial.' >&2
        return 1
    fi
}

run_with_privileges() {
    if [ "$(id -u)" -eq 0 ]; then
        "$@"
    elif command -v sudo >/dev/null 2>&1; then
        sudo "$@"
    else
        printf '%s\n' 'Erro: esta instalação exige root ou sudo.' >&2
        return 1
    fi
}

get_release_identity() {
    release_tag=$(printf '%s\n' "$release_json" |
        sed -n 's/.*"tag_name": "\([^"]*\)".*/\1/p' |
        head -n 1)
    release_version=${release_tag#v}

    if [ -z "$release_version" ]; then
        printf '%s\n' 'Erro: não foi possível determinar a versão estável do PowerShell na API oficial.' >&2
        return 1
    fi
}
