#!/usr/bin/env bash
# Recorre todas las plantillas, instala cada una, genera un proyecto y comprueba
# que restaura, compila, pasa las pruebas y respeta el formato. Es el mismo
# recorrido que ejecuta el CI.
set -euo pipefail

raiz="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
trabajo="$(mktemp -d)"

limpiar() {
  for plantilla in "$raiz"/templates/*; do
    dotnet new uninstall "$plantilla" >/dev/null 2>&1 || true
  done
  rm -rf "$trabajo"
}
trap limpiar EXIT

verificadas=0

for plantilla in "$raiz"/templates/*; do
  [ -d "$plantilla" ] || continue

  nombre="$(basename "$plantilla")"
  destino="$trabajo/$nombre/Sample"

  echo "Verificando plantilla: $nombre"
  dotnet new uninstall "$plantilla" >/dev/null 2>&1 || true
  dotnet new install "$plantilla" >/dev/null
  dotnet new "$nombre" -n Sample -o "$destino"

  dotnet restore "$destino/Sample.slnx"
  dotnet build "$destino/Sample.slnx" -c Release --no-restore

  pruebas=()
  while IFS= read -r proyecto; do
    pruebas+=("$proyecto")
  done < <(find "$destino" -name '*Tests.csproj' -print)

  if [ "${#pruebas[@]}" -gt 0 ]; then
    for proyecto in "${pruebas[@]}"; do
      dotnet test "$proyecto" -c Release --no-build --no-restore
    done
  else
    echo "  Sin proyecto de pruebas"
  fi

  dotnet format "$destino/Sample.slnx" --verify-no-changes --no-restore
  verificadas=$((verificadas + 1))
  echo "Plantilla verificada: $nombre"
done

if [ "$verificadas" -eq 0 ]; then
  echo "No hay plantillas que verificar" >&2
  exit 1
fi
