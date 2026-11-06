# CompanyWeb

Aplicación Blazor WebAssembly en .NET 10 con la línea base del portfolio: compilación centralizada, pruebas, CI y contenedor nginx sin privilegios. Consume una API por HTTP; no contiene lógica de servidor ni secretos.

## Estructura

- `src/CompanyWeb`: aplicación Blazor WebAssembly. El cliente HTTP y su configuración viven en `Program.cs` y `wwwroot/appsettings.json`.
- `tests/CompanyWeb.Tests`: pruebas del cliente HTTP con un manejador falso.
- `Directory.Build.props` y `Directory.Packages.props`: configuración común y una sola versión por paquete.
- `Dockerfile` y `nginx.conf`: publicación estática con cabeceras de seguridad y usuario sin privilegios.

## Puesta en marcha

```bash
dotnet restore CompanyWeb.slnx
dotnet run --project src/CompanyWeb
```

La aplicación queda en `http://localhost:5080`. La dirección de la API se configura en `src/CompanyWeb/wwwroot/appsettings.json` (`ApiBaseUrl`); por defecto apunta a `http://localhost:5094/`.

Si la API aplica CORS con denegación por defecto, añade `http://localhost:5080` a sus orígenes permitidos. El navegador no carga la respuesta si el origen no está en la lista.

## Verificación

```bash
dotnet restore CompanyWeb.slnx
dotnet build CompanyWeb.slnx -c Release --no-restore
dotnet test CompanyWeb.slnx -c Release --no-build --no-restore
dotnet format CompanyWeb.slnx --verify-no-changes --no-restore
gitleaks detect --source . --redact --verbose --exit-code 2
```

El CI llama a la acción `dotnet` de [`core`](https://github.com/lanuzalorenzo/core) y escanea secretos con Gitleaks sobre el historial completo.

## Docker

```bash
docker build -t company-web .
docker run --rm -p 8080:8080 company-web
```

La imagen sirve los archivos estáticos con nginx sin privilegios. `appsettings.json` se publica como archivo estático: si cambias la dirección de la API después de compilar, edita ese archivo en la imagen o vuelve a publicar.

Licencia: MIT.
