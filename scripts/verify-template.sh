#!/usr/bin/env bash
# Instala la plantilla, genera un proyecto y comprueba que restaura, compila,
# pasa las pruebas y respeta el formato. Es el mismo recorrido que ejecuta el CI.
set -euo pipefail

raiz="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
plantilla="$raiz/templates/ll-api"
trabajo="$(mktemp -d)"
nombre="SampleApi"

limpiar() {
  dotnet new uninstall "$plantilla" >/dev/null 2>&1 || true
  rm -rf "$trabajo"
}
trap limpiar EXIT

dotnet new uninstall "$plantilla" >/dev/null 2>&1 || true
dotnet new install "$plantilla"
dotnet new ll-api -n "$nombre" -o "$trabajo/$nombre"

dotnet restore "$trabajo/$nombre/$nombre.slnx"
dotnet build "$trabajo/$nombre/$nombre.slnx" -c Release --no-restore
dotnet test "$trabajo/$nombre/$nombre.slnx" -c Release --no-build --no-restore
dotnet format "$trabajo/$nombre/$nombre.slnx" --verify-no-changes --no-restore

echo "Plantilla verificada: $nombre"
