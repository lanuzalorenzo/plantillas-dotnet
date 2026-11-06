# CompanyApi

API empresarial en .NET 10 con la línea base del portfolio: arquitectura por capas, compilación centralizada, controles compartidos, CI y contenedor sin privilegios.

## Estructura

- `src/CompanyApi.Domain`: entidades e invariantes. Sin dependencias.
- `src/CompanyApi.Application`: casos de uso y puertos. Solo depende de `Domain`.
- `src/CompanyApi.Infrastructure`: adaptadores. Depende de `Application` y `Domain`.
- `src/CompanyApi.Api`: host mínimo; compone los servicios y expone los endpoints.
- `tests/CompanyApi.Tests`: pruebas de contrato HTTP.

La regla de dependencias es `Domain ← Application ← Infrastructure ← Api`. No la debilites.

## Puesta en marcha

```bash
export GITHUB_TOKEN="$(gh auth token)"
dotnet restore CompanyApi.slnx
dotnet run --project src/CompanyApi.Api
```

`/health` responde sin autenticación y `/api/saludo` sirve el endpoint de ejemplo. La documentación OpenAPI solo se publica en Development.

## Controles

Los paquetes `LL.Security` y `LL.Hosting` aportan CORS con denegación por defecto, cabeceras de seguridad, límite por IP, ProblemDetails, HTTPS/HSTS y salud anónima. La configuración entra por `Program.cs` y `appsettings.json`; los orígenes permitidos van en `Cors:AllowedOrigins`.

## Verificación

```bash
dotnet restore CompanyApi.slnx
dotnet build CompanyApi.slnx -c Release --no-restore
dotnet test CompanyApi.slnx -c Release --no-build --no-restore
dotnet format CompanyApi.slnx --verify-no-changes --no-restore
gitleaks detect --source . --redact --verbose --exit-code 2
```

El CI llama a las acciones de [`core`](https://github.com/lanuzalorenzo/core) y restaura los paquetes de [`shared-dotnet`](https://github.com/lanuzalorenzo/shared-dotnet). La versión de `LL.*` está fijada en `Directory.Packages.props`; se sube a mano cuando `shared-dotnet` publica una versión nueva.

## Docker

```bash
docker build --secret id=github_token,env=GITHUB_TOKEN -t company-api .
docker run --rm -p 8080:8080 company-api
```

El contenedor ejecuta con usuario no privilegiado y escucha HTTP en el 8080. La redirección a HTTPS se aplica en cualquier entorno salvo `Testing` cuando hay un puerto HTTPS configurado; HSTS se añade fuera de Development. En el contenedor no hay puerto HTTPS: la terminación TLS corresponde al host o a la plataforma, así que la imagen no redirige por sí sola.

Licencia: MIT.
