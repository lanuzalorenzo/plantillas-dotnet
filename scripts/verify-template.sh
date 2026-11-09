#!/usr/bin/env bash
# Recorre todas las plantillas, instala cada una, genera un proyecto y comprueba
# que restaura, compila, pasa las pruebas y respeta el formato. Es el mismo
# recorrido que ejecuta el CI.
set -euo pipefail

command -v unzip >/dev/null || { echo "Falta unzip para comprobar el paquete" >&2; exit 1; }
command -v curl >/dev/null || { echo "Falta curl para comprobar la cabecera Server" >&2; exit 1; }

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

  # La API generada arranca con Kestrel y no debe anunciarse en la cabecera Server;
  # la prueba no lo ve porque TestServer no escribe la cabecera.
  if [ "$nombre" = "ll-api" ]; then
    puerto=8099
    ASPNETCORE_URLS="http://127.0.0.1:${puerto}" ASPNETCORE_ENVIRONMENT=Production \
      dotnet run --project "$destino/src/Sample.Api" -c Release --no-build --no-launch-profile \
      >/dev/null 2>&1 &
    api_pid=$!

    cabeceras=""
    respondio=0
    for _ in $(seq 1 30); do
      if ! kill -0 "$api_pid" 2>/dev/null; then
        break
      fi
      if cabeceras="$(curl -fsS -D - -o /dev/null --connect-timeout 1 --max-time 2 "http://127.0.0.1:${puerto}/health" 2>/dev/null)"; then
        respondio=1
        break
      fi
      sleep 1
    done

    kill "$api_pid" >/dev/null 2>&1 || true
    wait "$api_pid" 2>/dev/null || true

    if [ "$respondio" -ne 1 ]; then
      echo "  La API generada no respondió en /health" >&2
      exit 1
    fi
    if printf '%s\n' "$cabeceras" | grep -qiE '^server:'; then
      echo "  La API generada publica la cabecera Server" >&2
      exit 1
    fi
    echo "  /health sin cabecera Server"
  fi

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
