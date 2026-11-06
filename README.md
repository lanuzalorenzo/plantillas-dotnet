<img src="assets/iconos/plantillas-dotnet.svg" width="64" alt="Icono de plantillas-dotnet">

# Plantillas .NET del portfolio

Plantillas de `dotnet new` que crean un repositorio con la línea base ya puesta: API por capas o aplicación Blazor, compilación centralizada, CI sobre las acciones de [`core`](https://github.com/lanuzalorenzo/core) y Dockerfile sin privilegios. La plantilla de API añade los controles compartidos de [`shared-dotnet`](https://github.com/lanuzalorenzo/shared-dotnet).

Una plantilla no es un control que la aplicación instala: es el esqueleto que la crea. Los controles viven en `shared-dotnet` y se actualizan por versión. Esa separación está en el ADR 0003 de `shared-dotnet`.

## Plantillas

| Nombre corto | Qué crea | Estado |
|---|---|---|
| `ll-api` | API ASP.NET Core por capas, con pruebas, CI, Docker y los paquetes `LL.Security` y `LL.Hosting` | Validada en local y CI |
| `ll-blazor` | Aplicación Blazor WebAssembly con pruebas, CI y contenedor nginx sin privilegios | Validada en local y CI |

La plantilla de paquete NuGet entra cuando la de Blazor esté probada de extremo a extremo.

## Uso

```bash
dotnet new install ./templates/ll-api
dotnet new ll-api -n MiApi -o ../mi-api

dotnet new install ./templates/ll-blazor
dotnet new ll-blazor -n MiWeb -o ../mi-web
```

La plantilla `ll-api` restaura los paquetes `LL.*` desde GitHub Packages; `ll-blazor` solo usa nuget.org. GitHub exige autenticación incluso para leer los paquetes públicos del feed: para `ll-api`, define `GITHUB_TOKEN` con permiso `read:packages` antes de restaurar.

```bash
export GITHUB_TOKEN="$(gh auth token)"
cd ../mi-api
dotnet restore MiApi.slnx
dotnet build MiApi.slnx -c Release --no-restore
dotnet test MiApi.slnx -c Release --no-build --no-restore
```

## Qué incluye la API generada

- `src/MiApi.Domain`, `src/MiApi.Application`, `src/MiApi.Infrastructure` y `src/MiApi.Api`, con la regla de dependencias `Domain ← Application ← Infrastructure ← Api`.
- `Directory.Build.props` y `Directory.Packages.props`: una sola versión por paquete, fijada y auditada como error.
- `LL.Security` y `LL.Hosting`: CORS con denegación por defecto, cabeceras de seguridad, límite por IP, ProblemDetails y salud anónima.
- `.github/workflows/ci.yml` con la acción `dotnet` y Gitleaks de `core@v1.3`.
- Dependabot para NuGet y GitHub Actions, con auto-merge de parche y minor.
- `Dockerfile` multi-stage, usuario no privilegiado y credencial del feed por secreto de BuildKit.

## Qué incluye la web generada

- `src/MiWeb`, una aplicación Blazor WebAssembly que consume la API por HTTP; la dirección vive en `wwwroot/appsettings.json`.
- `tests/MiWeb.Tests`, con pruebas del cliente HTTP y un manejador falso.
- `Directory.Build.props` y `Directory.Packages.props` con la compilación centralizada y una sola versión por paquete.
- `.github/workflows/ci.yml` con la acción `dotnet` y Gitleaks de `core@v1.3`.
- Dependabot para NuGet y GitHub Actions, con auto-merge de parche y minor.
- `Dockerfile` con nginx sin privilegios y cabeceras de seguridad en `nginx.conf`.

## Verificación del repositorio

```bash
./scripts/verify-template.sh
gitleaks detect --source . --redact --verbose --exit-code 2
```

El script recorre todas las plantillas: instala cada una en un directorio temporal, genera un proyecto, restaura, compila, prueba y comprueba el formato. Una plantilla está lista cuando ese recorrido termina sin fallos y el CI está en verde.

Licencia: MIT.
