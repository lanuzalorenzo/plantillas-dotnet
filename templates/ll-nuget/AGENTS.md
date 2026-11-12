# Guía para agentes: CompanyPackage

Biblioteca .NET 10 publicable como paquete NuGet, creada desde la plantilla `ll-nuget`. Este archivo cubre la estructura, la publicación y la verificación del repositorio.

## Estructura

- `src/CompanyPackage/`: biblioteca empaquetable. Solo este proyecto declara `IsPackable` en `true`.
- `tests/CompanyPackage.Tests/`: pruebas de la biblioteca.
- `Directory.Build.props`: versión, licencia y compilación común. `Directory.Packages.props`: una sola versión por paquete.
- `.github/workflows/publish.yml`: etiqueta `vX.Y.Z`, compilación, pruebas, `dotnet pack` y publicación en GitHub Packages.

## Reglas

- Todo cambio de comportamiento entra con prueba en `tests/CompanyPackage.Tests`.
- La API pública del paquete se documenta y no se rompe sin subir la versión mayor.
- Los metadatos del paquete (`Description`, `PackageTags`, `PackageReadmeFile`) viven en el `.csproj` de la biblioteca; la licencia (`PackageLicenseExpression`) está en `Directory.Build.props` y no se duplica en el workflow.
- Sin secretos versionados: la publicación usa `GITHUB_TOKEN` y el consumidor, un token con `read:packages`.
- La versión se fija con `VersionPrefix` o con la etiqueta. `--skip-duplicate` evita republicar una versión existente.

## Verificación

```bash
dotnet restore CompanyPackage.slnx
dotnet build CompanyPackage.slnx -c Release --no-restore
dotnet test CompanyPackage.slnx -c Release --no-build --no-restore
dotnet format CompanyPackage.slnx --verify-no-changes --no-restore
dotnet pack CompanyPackage.slnx -c Release --no-build
gitleaks detect --source . --redact --verbose --exit-code 2
```

**Definición de cambio listo:** los seis comandos anteriores sin fallos y el pipeline en verde, sin bypass.

## Dependabot

Si una PR de Dependabot queda `BEHIND`, actualiza su rama con `gh api -X PUT repos/{owner}/{repo}/pulls/N/update-branch`; el push resultante dispara CI y el auto-merge la fusiona. No se automatiza con `GITHUB_TOKEN`: sus eventos no disparan workflows y Dependabot rechaza los comandos de `github-actions[bot]`.

## Commits

Formato: `type(scope): imperative summary in English`. Scopes: `package`, `ci`, `tests`, `docs`, `repo`. Tipos: `feat`, `fix`, `docs`, `refactor`, `test`, `chore`.

Los cambios entran por rama y pull request: `main` exige PR y los checks del pipeline.
