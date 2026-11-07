#!/usr/bin/env bash
# Recorre todas las plantillas, instala cada una, genera un proyecto y comprueba
# que restaura, compila, pasa las pruebas y respeta el formato. Es el mismo
# recorrido que ejecuta el CI.
set -euo pipefail

command -v unzip >/dev/null || { echo "Falta unzip para comprobar el paquete" >&2; exit 1; }

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

  # Empaquetar la solución si algún proyecto se declara publicable, con el mismo
  # comando que documenta la plantilla, y comprobar el contenido de cada .nupkg.
  publicables=0
  while IFS= read -r proyecto; do
    if ! valor="$(dotnet msbuild "$proyecto" -getProperty:IsPackable -nologo)"; then
      echo "  No se pudo leer IsPackable en $proyecto" >&2
      exit 1
    fi
    if [ "$valor" = "true" ]; then
      publicables=$((publicables + 1))
    fi
  done < <(find "$destino" -name '*.csproj' -print)

  if [ "$publicables" -gt 0 ]; then
    dotnet pack "$destino/Sample.slnx" -c Release --no-build --no-restore -o "$trabajo/$nombre/paquetes"

    paquetes=()
    while IFS= read -r paquete; do
      paquetes+=("$paquete")
    done < <(find "$trabajo/$nombre/paquetes" -name '*.nupkg' -print)

    if [ "${#paquetes[@]}" -eq 0 ]; then
      echo "  Hay proyectos publicables y no se generó el paquete" >&2
      exit 1
    fi

    for paquete in "${paquetes[@]}"; do
      listado="$(unzip -l "$paquete")"
      if ! grep -Eq 'lib/[^/]+/[^/]+\.dll' <<< "$listado"; then
        echo "  El paquete no contiene la biblioteca: $(basename "$paquete")" >&2
        exit 1
      fi
      if grep -rq --include='*.csproj' '<PackageReadmeFile>' "$destino" && ! grep -q 'README.md' <<< "$listado"; then
        echo "  El paquete no contiene el README: $(basename "$paquete")" >&2
        exit 1
      fi
      echo "  Paquete generado: $(basename "$paquete")"
    done
  elif grep -rq --include='*.csproj' '<PackageReadmeFile>' "$destino"; then
    echo "  La plantilla declara un paquete y no hay proyectos publicables" >&2
    exit 1
  fi

  verificadas=$((verificadas + 1))
  echo "Plantilla verificada: $nombre"
done

if [ "$verificadas" -eq 0 ]; then
  echo "No hay plantillas que verificar" >&2
  exit 1
fi
