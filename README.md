<img src="assets/iconos/plantillas-dotnet.svg" width="64" alt="Icono de plantillas-dotnet">

# Plantillas .NET del portfolio

Plantillas de `dotnet new` que crean un repositorio con la línea base ya puesta: API por capas, aplicación Blazor o biblioteca NuGet, con compilación centralizada, CI sobre las acciones de [`core`](https://github.com/lanuzalorenzo/core) y, cuando aplica, Dockerfile sin privilegios. La plantilla de API añade los controles compartidos de [`shared-dotnet`](https://github.com/lanuzalorenzo/shared-dotnet); la de biblioteca no depende de ellos y prepara la publicación en GitHub Packages.

Una plantilla no es un control que la aplicación instala: es el esqueleto que la crea. Los controles viven en `shared-dotnet` y se actualizan por versión. Esa separación está en el [ADR 0003](https://github.com/lanuzalorenzo/shared-dotnet/blob/main/docs/adr/0003-plantillas-fuera-del-repositorio.md) de `shared-dotnet`.

## Guía

Si vas a crear un proyecto, empieza por la [guía de plantillas](docs/guia-de-plantillas.md): el orden API → web, qué significa «segura de base» y cómo convertir el recorrido en una plantilla nueva para no repetirlo.

## Plantillas

| Nombre corto | Qué crea | Estado | Última ejecución real |
|---|---|---|---|
| `ll-api` | API ASP.NET Core por capas, con pruebas, CI, Docker y los paquetes `LL.Security` y `LL.Hosting` | Parcial: el workflow nuevo (`sast` con `github/codeql-action` y nombre de imagen derivado) no se ha ejecutado; la revisión de dependencias sigue sin ejercitar | 2026-11-23 · `285f180` · `v1.8` (workflow anterior) |
| `ll-blazor` | Aplicación Blazor WebAssembly con pruebas, CI y contenedor nginx sin privilegios | Parcial (SAST, SCA y contenedor sin ejercitar) | 2026-11-23 · `f29dc7a` · `v1.8` (CI anterior) |
| `ll-nuget` | Biblioteca .NET empaquetable, con pruebas, CI, publicación por etiqueta y el README dentro del paquete | Parcial (SAST y SCA sin ejercitar) | 2026-11-23 · `e882543` · `v1.8` (CI anterior) |

### Acciones de CI que usan

Todas fijan la etiqueta en la referencia; ninguna usa `@main`.

| Plantilla | Acciones de `core` |
|---|---|
| `ll-api` | `check-platform`, `dotnet`, `gitleaks`, `scan` y `container-publish` |
| `ll-blazor` | `check-platform`, `dotnet`, `gitleaks`, `sast`, `scan` y `container-publish` |
| `ll-nuget` | `check-platform`, `dotnet`, `gitleaks`, `sast` y `scan` |

Las tres plantillas ejecutan análisis estático con CodeQL y escaneo con Trivy; la web y la API construyen su imagen, comprueban que no ejecuta como root y la escanean. La biblioteca no tiene contenedor: su `scan` cubre las dependencias del paquete.

En `ll-api` el SAST usa `github/codeql-action` directamente porque `core/actions/sast@v1.8` no permite condicionar la publicación del SARIF a la visibilidad del repositorio; vuelve a la acción compartida cuando `core` exponga ese conmutador.

Las tres plantillas se generan, compilan, prueban y formatean en `scripts/verify-template.sh`; en `ll-api` además se arranca la API y se comprueba que `/health` no trae la cabecera `Server`; la de biblioteca se empaqueta además en ese recorrido. La publicación de `ll-nuget` se probó el 7 de noviembre de 2026 en un repositorio temporal: el workflow publicó el paquete `0.1.0` en GitHub Packages y el CI del repositorio generado quedó en verde.

El CI de la web generada —compilación, formato, pruebas y secretos— se validó el 2026-11-23 en un repositorio temporal privado generado con `ll-blazor`: los dos trabajos pasaron en verde en el run `45213388991` (commit `f29dc7a` del repositorio temporal), con las acciones de `core` fijadas a `v1.8`.

El CI de seguridad de la API generada —compilación, secretos, SAST, SCA, contenedor y la revisión de dependencias, que solo corre en las pull requests— se validó el 2026-11-23 en un repositorio temporal público generado con `ll-api`: los cinco trabajos que corren en un push pasaron en verde en el segundo intento del run `45213362682` (commit `285f180` del repositorio temporal), con las acciones de `core` fijadas a `v1.8`; la revisión de dependencias sigue sin ejercitar hasta que un repositorio generado reciba una pull request. El primer intento, con el repositorio aún privado, falló en los tres trabajos que publican SARIF: la publicación de hallazgos exige un repositorio público o GitHub Advanced Security. Desde entonces la plantilla condiciona el envío de SARIF y `dependency-review` a `github.event.repository.visibility`, y el SAST pasó a los pasos de `github/codeql-action` con publicación condicionada: en privado el análisis y el escaneo siguen corriendo y solo se omite la publicación. Ninguna de las dos rutas se ha recorrido con este workflow en un repositorio temporal; la ejecución citada es de la versión anterior, así que la plantilla queda en Parcial. La generación, compilación, pruebas y formato siguen cubiertos por `verify-template.sh`.

El CI de la biblioteca generada —compilación, formato, pruebas, paquete y secretos— se validó el 2026-11-23 en un repositorio temporal privado generado con `ll-nuget`: los dos trabajos pasaron en verde en el run `45213410774` (commit `e882543` del repositorio temporal), con las acciones de `core` fijadas a `v1.8`.

El análisis estático y el escaneo de la web y de la biblioteca se añadieron después de esas ejecuciones: todavía no se han ejercitado en un repositorio generado, así que sus filas quedan en **Parcial**. `scripts/verify-template.sh` comprueba que el CI que viaja con cada plantilla ejecuta `sast` y `scan`, y que la plantilla con `Dockerfile` escanea la imagen y comprueba que el contenedor no ejecuta como root; el CI de este repositorio construye además esa imagen y ejecuta la misma comprobación.

Los tres repositorios temporales se archivaron al cerrar la prueba; los de la web y la biblioteca eran privados, así que sus runs no son enlazables.

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
- `Directory.Build.props` y `Directory.Packages.props`: una sola versión por paquete, fijada, con auditoría que falla ante una vulnerabilidad alta o crítica y avisa en las bajas y moderadas.
- `LL.Security` y `LL.Hosting`: CORS con denegación por defecto, cabeceras de seguridad, límite por IP, ProblemDetails y salud anónima.
- `.github/workflows/ci.yml` con las acciones `dotnet`, `gitleaks` y `scan` de `core` y CodeQL con `github/codeql-action`: compilación y pruebas, secretos, análisis estático, Trivy sobre dependencias e imagen y `dependency-review` en las pull requests.
- El CI construye el contenedor, comprueba que no ejecuta como root y lo escanea. El análisis de IaC no es automático: queda manual hasta que el repositorio incluya `infra/`.
- Dependabot para NuGet y GitHub Actions, con auto-merge de parche y minor.
- `Dockerfile` multi-stage, usuario no privilegiado y credencial del feed por secreto de BuildKit.

## Qué incluye la web generada

- `src/MiWeb`, una aplicación Blazor WebAssembly que consume la API por HTTP; la dirección vive en `wwwroot/appsettings.json`.
- `tests/MiWeb.Tests`, con pruebas del cliente HTTP y un manejador falso.
- `Directory.Build.props` y `Directory.Packages.props` con la compilación centralizada, una sola versión por paquete y la misma auditoría: falla ante una vulnerabilidad alta o crítica y avisa en las bajas y moderadas.
- `.github/workflows/ci.yml` con las acciones `dotnet`, `gitleaks`, `sast` y `scan` de `core`: compilación y pruebas, secretos, CodeQL, Trivy sobre dependencias e imagen. El workflow construye la imagen, comprueba que no ejecuta como root y la escanea.
- Dependabot para NuGet y GitHub Actions, con auto-merge de parche y minor.
- `Dockerfile` con nginx sin privilegios y cabeceras de seguridad en `nginx.conf`.

## Qué incluye la biblioteca generada

- `src/MiPaquete`, una biblioteca empaquetable con `Slug` como ejemplo y el README dentro del `.nupkg`.
- `tests/MiPaquete.Tests`, con pruebas de la biblioteca.
- `Directory.Build.props` y `Directory.Packages.props` con la compilación centralizada, la versión, una sola versión por paquete y la misma auditoría: falla ante una vulnerabilidad alta o crítica y avisa en las bajas y moderadas.
- `.github/workflows/ci.yml` con las acciones `dotnet`, `gitleaks`, `sast` y `scan` de `core`: compilación, formato, pruebas y paquete, secretos, CodeQL y Trivy sobre las dependencias. Una comprobación posterior verifica que el `.nupkg` contiene la biblioteca y el README.
- `.github/workflows/publish.yml`: una etiqueta `vX.Y.Z` compila, prueba, empaqueta y publica en GitHub Packages con `GITHUB_TOKEN`.
- Dependabot para NuGet y GitHub Actions, con auto-merge de parche y minor.

## Verificación del repositorio

```bash
export GH_PACKAGES_TOKEN="<pat-de-solo-lectura>"   # solo para ll-api
./scripts/verify-template.sh
gitleaks detect --source . --redact --verbose --exit-code 2
```

El script recorre todas las plantillas: instala cada una en un directorio temporal, genera un proyecto, restaura, compila, prueba, comprueba el formato, verifica que el CI generado ejecuta `sast` y `scan` —y, cuando hay `Dockerfile`, que escanea la imagen y comprueba que no ejecuta como root— y empaqueta los proyectos que se declaren publicables. Una plantilla está lista cuando ese recorrido termina sin fallos y el CI está en verde.

Licencia: MIT.
