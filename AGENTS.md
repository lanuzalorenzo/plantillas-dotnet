# Guía para agentes: plantillas-dotnet

Plantillas de `dotnet new` que crean repositorios con la línea base del portfolio. Este repositorio no contiene la aplicación ni los controles: la primera vive en el repositorio generado y los segundos en `shared-dotnet`.

## Estructura

- `templates/<nombre>/`: una plantilla. El contenido generado está en la raíz de la carpeta y la definición en `.template.config/template.json`.
- `assets/iconos/`: icono del repositorio, con los valores en línea.
- `scripts/verify-template.sh`: recorre las plantillas, instala cada una en un directorio temporal, genera el proyecto, restaura, compila, prueba y verifica el formato.
- `.github/workflows/`: CI del repositorio y flujo de auto-merge de Dependabot.

## Reglas

- Una plantilla no duplica la lógica de `shared-dotnet`: la consume por versión publicada.
- El contenido generado no cita repositorios privados, rutas del workspace ni documentos internos.
- Sin secretos ni credenciales versionadas. En `templates/ll-api`, el `NuGet.config` lee `GITHUB_TOKEN` del entorno; `templates/ll-blazor` solo usa nuget.org.
- La línea base de los repos públicos se aplica aquí sin excepción: Gitleaks sobre el historial completo, Dependabot con auto-merge de parche y minor, permisos mínimos y `main` con rama y pull request.
- Una plantilla nueva entra con su recorrido de verificación. Una plantilla que no puede generar, compilar y probar un proyecto no se publica.
- Un proyecto que se declare publicable se comprueba además con `dotnet pack`; el recorrido falla si el `.nupkg` no contiene la biblioteca.
- Las comprobaciones de seguridad no se relajan para que una plantilla pase.

## Verificación

```bash
./scripts/verify-template.sh
gitleaks detect --source . --redact --verbose --exit-code 2
```

El CI ejecuta el mismo recorrido y escanea secretos con la acción de `core`. Un cambio está listo cuando el pipeline pasa en verde y los comandos anteriores no fallan.

## Commits

Formato: `type(scope): imperative summary in English`. Tipos: `feat`, `fix`, `docs`, `refactor`, `test`, `chore`. Scopes: `template`, `ci`, `docs`, `repo`.

Los cambios entran por rama y pull request. `main` exige los checks del repositorio y rama actualizada; no hagas push directo.

Licencia: MIT.
