# CompanyPackage

Biblioteca .NET 10 publicable como paquete NuGet, creada con la línea base del portfolio: compilación centralizada, pruebas, CI y publicación por etiqueta en GitHub Packages.

`Slug.Create` es el ejemplo incluido: convierte un texto en un identificador estable, sin acentos y con guiones. Sustitúyelo por el código real de la biblioteca.

## Estructura

- `src/CompanyPackage`: biblioteca empaquetable. El paquete toma el nombre del proyecto.
- `tests/CompanyPackage.Tests`: pruebas de la biblioteca.
- `Directory.Build.props` y `Directory.Packages.props`: configuración común, versión y una sola versión por paquete.
- `.github/workflows/ci.yml`: restaura, compila, verifica el formato, prueba y empaqueta.
- `.github/workflows/publish.yml`: publica el paquete en GitHub Packages al hacer push de una etiqueta `vX.Y.Z`.

## Compilar y probar

```bash
dotnet restore CompanyPackage.slnx
dotnet build CompanyPackage.slnx -c Release --no-restore
dotnet test CompanyPackage.slnx -c Release --no-build --no-restore
dotnet format CompanyPackage.slnx --verify-no-changes --no-restore
```

## Empaquetar

```bash
dotnet pack CompanyPackage.slnx -c Release -o ./artefactos
```

El paquete incluye la biblioteca y este README. La versión sale de `VersionPrefix` en `Directory.Build.props`; la etiqueta puede fijarla sin tocar el archivo.

## Publicar

`publish.yml` se dispara con una etiqueta `vX.Y.Z`: valida el formato, compila, prueba, empaqueta y publica en el feed de GitHub Packages del propietario del repositorio con `GITHUB_TOKEN`. El workflow ya declara `packages: write`.

```bash
git tag v0.1.0
git push origin v0.1.0
```

El consumidor necesita autenticarse contra el feed incluso para paquetes públicos: añade `https://nuget.pkg.github.com/OWNER/index.json` como origen y usa un token con `read:packages`.

## Verificación

```bash
dotnet restore CompanyPackage.slnx
dotnet build CompanyPackage.slnx -c Release --no-restore
dotnet test CompanyPackage.slnx -c Release --no-build --no-restore
dotnet format CompanyPackage.slnx --verify-no-changes --no-restore
dotnet pack CompanyPackage.slnx -c Release --no-build
gitleaks detect --source . --redact --verbose --exit-code 2
```

El CI llama a la acción `dotnet` de [`core`](https://github.com/lanuzalorenzo/core) y escanea secretos con Gitleaks sobre el historial completo.

Licencia: MIT.
