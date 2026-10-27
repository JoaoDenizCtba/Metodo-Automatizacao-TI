#!/bin/sh
set -eu

SCRIPT_DIR=$(CDPATH= cd "$(dirname "$0")" && pwd)
. "$SCRIPT_DIR/../executor/bootstrap/PowerShell-Bootstrap.Common.sh"

release_json='{
  "tag_name": "v7.6.9",
  "assets": [
    {
      "name": "powershell-7.6.9-linux-x64.tar.gz",
      "browser_download_url": "https://github.com/PowerShell/PowerShell/releases/download/v7.6.9/powershell-7.6.9-linux-x64.tar.gz",
      "digest": "sha256:0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef",
      "uploader": {
        "login": "release-bot"
      }
    },
    {
      "name": "powershell-7.6.9-osx-arm64.pkg",
      "browser_download_url": "https://github.com/PowerShell/PowerShell/releases/download/v7.6.9/powershell-7.6.9-osx-arm64.pkg",
      "digest": "sha256:abcdef0123456789abcdef0123456789abcdef0123456789abcdef0123456789"
    }
  ]
}'

get_release_identity
if [ "$release_tag" != 'v7.6.9' ] || [ "$release_version" != '7.6.9' ]; then
    printf '%s\n' 'Falha ao extrair versão da release.' >&2
    exit 1
fi

linux_asset=$(get_release_asset 'powershell-7.6.9-linux-x64.tar.gz' "$release_json")
linux_url=$(get_release_value browser_download_url "$linux_asset")
linux_digest=$(get_release_value digest "$linux_asset")
if [ "$linux_url" != 'https://github.com/PowerShell/PowerShell/releases/download/v7.6.9/powershell-7.6.9-linux-x64.tar.gz' ] ||
    [ "$linux_digest" != 'sha256:0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef' ]; then
    printf '%s\n' 'Falha ao extrair URL ou digest da release Linux.' >&2
    exit 1
fi

mac_asset=$(get_release_asset 'powershell-7.6.9-osx-arm64.pkg' "$release_json")
mac_digest=$(get_release_value digest "$mac_asset")
if [ "$mac_digest" != 'sha256:abcdef0123456789abcdef0123456789abcdef0123456789abcdef0123456789' ]; then
    printf '%s\n' 'Falha ao extrair digest da release macOS.' >&2
    exit 1
fi

printf '%s\n' 'Bootstrap release metadata test passed.'
