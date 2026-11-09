<img src="assets/iconos/plantillas-dotnet.svg" width="64" alt="Icono de plantillas-dotnet">

# Plantillas .NET del portfolio

Plantillas de `dotnet new` que crean un repositorio con la línea base ya puesta: API por capas, aplicación Blazor o biblioteca NuGet, con compilación centralizada, CI sobre las acciones de [`core`](https://github.com/lanuzalorenzo/core) y, cuando aplica, Dockerfile sin privilegios. La plantilla de API añade los controles compartidos de [`shared-dotnet`](https://github.com/lanuzalorenzo/shared-dotnet); la de biblioteca no depende de ellos y prepara la publicación en GitHub Packages.

Una plantilla no es un control que la aplicación instala: es el esqueleto que la crea. Los controles viven en `shared-dotnet` y se actualizan por versión. Esa separación está en el [ADR 0003](https://github.com/lanuzalorenzo/shared-dotnet/blob/main/docs/adr/0003-plantillas-fuera-del-repositorio.md) de `shared-dotnet`.

## Plantillas

| Nombre corto | Qué crea | Estado |
|---|---|---|
| `ll-api` | API ASP.NET Core por capas, con pruebas, CI, Docker y los paquetes `LL.Security` y `LL.Hosting` | Validado |
| `ll-blazor` | Aplicación Blazor WebAssembly con pruebas, CI y contenedor nginx sin privilegios | Validado |
| `ll-nuget` | Biblioteca .NET empaquetable, con pruebas, CI, publicación por etiqueta y el README dentro del paquete | Validado |

Las tres plantillas se generan, compilan, prueban y formatean en `scripts/verify-template.sh` y en el CI; la de biblioteca se empaqueta además en ese recorrido. La publicación de `ll-nuget` se probó el 7 de noviembre de 2026 en un repositorio temporal: el workflow publicó el paquete `0.1.0` en GitHub Packages y el CI del repositorio generado quedó en verde.

## Uso

```bash
dotnet new install ./templates/ll-api
dotnet new ll-api -n MiApi -o ../mi-api

dotnet new install ./templates/ll-blazor
dotnet new ll-blazor -n MiWeb -o ../mi-web

dotnet new install ./templates/ll-nuget
dotnet new ll-nuget -n MiPaquete -o ../mi-paquete
```

La plantilla `ll-api` restaura los paquetes `LL.*` desde GitHub Packages; `ll-blazor` y `ll-nuget` solo usan nuget.org. GitHub exige autenticación incluso para leer los paquetes públicos del feed: para `ll-api`, define `GH_PACKAGES_TOKEN` con permiso `read:packages` antes de restaurar. No uses `GITHUB_TOKEN`: `gh` y Git la leen como credencial de la sesión y un token sin `repo` deja los `push` en `403`.

```bash
export GH_PACKAGES_TOKEN="<pat-de-solo-lectura>"
cd ../mi-api
dotnet restore MiApi.slnx
dotnet build MiApi.slnx -c Release --no-restore
dotnet test MiApi.slnx -c Release --no-build --no-restore
```

## Qué incluye la API generada

- `src/MiApi.Domain`, `src/MiApi.Application`, `src/MiApi.Infrastructure` y `src/MiApi.Api`, con la regla de dependencias `Domain ← Application ← Infrastructure ← Api`.
- `Directory.Build.props` y `Directory.Packages.props`: una sola versión por paquete, fijada y auditada como error.
- `LL.Security` y `LL.Hosting`: CORS con denegación por defecto, cabeceras de seguridad, límite por IP, ProblemDetails y salud anónima.
- `.github/workflows/ci.yml` con la acción `dotnet` y Gitleaks de `core@v1.4`.
- Dependabot para NuGet y GitHub Actions, con auto-merge de parche y minor.
- `Dockerfile` multi-stage, usuario no privilegiado y credencial del feed por secreto de BuildKit.

## Qué incluye la web generada

- `src/MiWeb`, una aplicación Blazor WebAssembly que consume la API por HTTP; la dirección vive en `wwwroot/appsettings.json`.
- `tests/MiWeb.Tests`, con pruebas del cliente HTTP y un manejador falso.
- `Directory.Build.props` y `Directory.Packages.props` con la compilación centralizada y una sola versión por paquete.
- `.github/workflows/ci.yml` con la acción `dotnet` y Gitleaks de `core@v1.4`.
- Dependabot para NuGet y GitHub Actions, con auto-merge de parche y minor.
- `Dockerfile` con nginx sin privilegios y cabeceras de seguridad en `nginx.conf`.

## Qué incluye la biblioteca generada

- `src/MiPaquete`, una biblioteca empaquetable con `Slug` como ejemplo y el README dentro del `.nupkg`.
- `tests/MiPaquete.Tests`, con pruebas de la biblioteca.
- `Directory.Build.props` y `Directory.Packages.props` con la compilación centralizada, la versión y una sola versión por paquete.
- `.github/workflows/ci.yml` con la acción `dotnet`, Gitleaks de `core@v1.4` y una comprobación de que el paquete contiene la biblioteca.
- `.github/workflows/publish.yml`: una etiqueta `vX.Y.Z` compila, prueba, empaqueta y publica en GitHub Packages con `GITHUB_TOKEN`.
- Dependabot para NuGet y GitHub Actions, con auto-merge de parche y minor.

## Verificación del repositorio

```bash
./scripts/verify-template.sh
gitleaks detect --source . --redact --verbose --exit-code 2
```

El script recorre todas las plantillas: instala cada una en un directorio temporal, genera un proyecto, restaura, compila, prueba, comprueba el formato y empaqueta los proyectos que se declaren publicables. Una plantilla está lista cuando ese recorrido termina sin fallos y el CI está en verde.

Licencia: MIT.
