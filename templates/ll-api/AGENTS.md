# Guía para agentes: CompanyApi

API empresarial en .NET 10 creada desde la plantilla `ll-api`. Este archivo cubre la estructura, la seguridad y la verificación del repositorio.

## Arquitectura

- Desacoplada: `Domain` sin dependencias, `Application` solo `Domain`, `Infrastructure` de ambas y el host compone todo. No debilites esa separación.
- Toda decisión estructural se documenta como ADR; el primero se crea al tomar la primera decisión que lo merezca.
- `Directory.Build.props` fija la configuración común de compilación y `Directory.Packages.props` la única versión de cada paquete; los `.csproj` no repiten `Nullable`, `ImplicitUsings` ni `Version`.

## Seguridad

- Security by Design y OWASP API Security Top 10.
- Los controles compartidos se consumen desde `LL.Security` y `LL.Hosting`; no los reimplementes en el host.
- CORS con denegación por defecto y orígenes explícitos.
- Dockerfile con usuario no privilegiado (`USER $APP_UID`). El CI construye la imagen, comprueba que no ejecuta como root y la escanea con Trivy; las dependencias se escanean con el mismo Trivy sobre los manifiestos.
- Sin secretos ni cadenas reales en el código: `appsettings.Local.json` (ignorado), user-secrets o variables de entorno. `appsettings.Development.json` se versiona sin secretos.
- Pruebas de integración en `tests/CompanyApi.Tests` para cualquier cambio de comportamiento.

## Verificación

```bash
dotnet restore CompanyApi.slnx
dotnet build CompanyApi.slnx -c Release --no-restore
dotnet test CompanyApi.slnx -c Release --no-build --no-restore
dotnet format CompanyApi.slnx --verify-no-changes --no-restore
gitleaks detect --source . --redact --verbose --exit-code 2
```

Las pruebas no ven la cabecera `Server` porque `TestServer` no la escribe. Para comprobarla, arranca la API y mira `/health`:

```bash
ASPNETCORE_URLS=http://127.0.0.1:8099 dotnet run --project src/CompanyApi.Api --no-launch-profile &
curl -sI http://127.0.0.1:8099/health | grep -i '^server:' && echo "publica Server" || echo "sin cabecera Server"
```

El CI usa las acciones de `core` para compilar, escanear secretos, analizar el código y escanear dependencias e imagen. El job de SCA restaura y compila antes de `scan`, como pide `core`; la construcción del contenedor, la comprobación de usuario no privilegiado y la revisión de dependencias van en el mismo workflow. **Definición de cambio listo:** los cinco comandos anteriores sin fallos y el pipeline en verde, sin bypass.

## Commits

Formato: `type(scope): imperative summary in English`. Scopes: `api`, `ci`, `tests`, `docs`, `repo`. Tipos: `feat`, `fix`, `docs`, `refactor`, `test`, `chore`.

Los cambios entran por rama y pull request: `main` exige PR y los checks del pipeline.
