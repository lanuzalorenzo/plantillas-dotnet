# Guía para agentes: CompanyWeb

Aplicación Blazor WebAssembly en .NET 10 creada desde la plantilla `ll-blazor`. Este archivo cubre la estructura, la seguridad y la verificación del repositorio.

## Arquitectura

- La aplicación se ejecuta en el navegador: no contiene lógica de servidor ni secretos. Todo lo que se publica en `wwwroot` es público.
- La API se consume por HTTP. La dirección vive en `wwwroot/appsettings.json` (`ApiBaseUrl`) y el cliente en `Services/ApiClient.cs`.
- La configuración común de compilación está en `Directory.Build.props` y la única versión de cada paquete en `Directory.Packages.props`; los `.csproj` no repiten `Nullable`, `ImplicitUsings` ni `Version`.
- La aplicación no referencia capas de servidor. Si necesita un DTO de la API, lo declara en su propio proyecto.

## Seguridad

- Sin secretos, credenciales ni cadenas reales. Todo lo que se publica en `wwwroot` es público: no pongas ahí configuración sensible.
- El contenedor usa nginx sin privilegios y sirve en el puerto 8080. `nginx.conf` añade `X-Content-Type-Options`, `X-Frame-Options` y `Referrer-Policy`.
- La API debe permitir el origen de la aplicación en su lista de CORS; no se relaja la denegación por defecto de la API para que la web cargue.
- Pruebas en `tests/CompanyWeb.Tests` para cualquier cambio de comportamiento del cliente.

## Verificación

```bash
dotnet restore CompanyWeb.slnx
dotnet build CompanyWeb.slnx -c Release --no-restore
dotnet test CompanyWeb.slnx -c Release --no-build --no-restore
dotnet format CompanyWeb.slnx --verify-no-changes --no-restore
gitleaks detect --source . --redact --verbose --exit-code 2
```

Los pasos .NET y el escaneo de secretos se ejecutan con las acciones compartidas de `core` desde `.github/workflows/ci.yml`. **Definición de cambio listo:** los cinco comandos anteriores sin fallos y el pipeline en verde, sin bypass.

## Commits

Formato: `type(scope): imperative summary in English`. Scopes: `web`, `ci`, `tests`, `docs`, `repo`. Tipos: `feat`, `fix`, `docs`, `refactor`, `test`, `chore`.

Los cambios entran por rama y pull request: `main` exige PR y los checks del pipeline.
