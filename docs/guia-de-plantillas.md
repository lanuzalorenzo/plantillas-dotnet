# Guía de plantillas: de la idea al molde

> **Para quién es:** para quien va a crear una API o una web con la línea base puesta, y para quien mantiene las plantillas cuando aparece un artefacto nuevo.
>
> **Qué resuelve:** el recorrido completo: elegir la pieza, generar el proyecto, comprobarlo y, si el recorrido se repite, convertirlo en plantilla. Fija el orden y los criterios; los comandos exactos están en el `README` y en el `AGENTS.md` generado.
>
> **Estado:** Runbook preparado (2026-11-22). Las tres están cubiertas por `verify-template.sh`; el estado y su evidencia están en la tabla del [`README`](../README.md). Este documento describe cómo se hace una nueva y no se ha ejecutado todavía para crear una plantilla desde cero.

La idea cabe en una frase: **la plantilla crea la casa, el paquete mantiene la instalación y el inspector comprueba antes de abrir.** Por eso son tres repositorios y no uno: este crea el esqueleto, [`shared-dotnet`](https://github.com/lanuzalorenzo/shared-dotnet) mantiene los controles por versión y [`core`](https://github.com/lanuzalorenzo/core) ejecuta las comprobaciones. El motivo está en el [ADR 0003](https://github.com/lanuzalorenzo/shared-dotnet/blob/main/docs/adr/0003-plantillas-fuera-del-repositorio.md).

Esta guía vive aquí porque este repositorio es el dueño de las plantillas. El [módulo 07 del portfolio](https://github.com/lanuzalorenzo/portfolio-ciberseguridad-lorenzo/tree/main/07-devsecops) enseña los controles aplicados sobre el banco de pruebas; es la evidencia, no el procedimiento.

## 1. Elige la pieza

La pieza la decide el artefacto, no la costumbre. Si existe una que lo cubre, se usa; no se copia otro repositorio ni se improvisa uno nuevo.

| Artefacto | Pieza | Dónde |
|---|---|---|
| API ASP.NET Core | `ll-api` | este repositorio |
| Aplicación Blazor | `ll-blazor` | este repositorio |
| Biblioteca NuGet | `ll-nuget` | este repositorio |
| Sitio o documentación estática | sin plantilla: `check-links` y la línea base | `core` |
| Acción o workflow de CI | acción o workflow nuevo | `core` |

Antes de crear una plantilla, comprueba si el caso es una **variante** de una que ya existe:

- Si solo cambia un nombre, un paquete o una opción, no es una plantilla nueva: es una opción de la que ya hay.
- Si es un **control** que comparten varias aplicaciones, va a `shared-dotnet`.
- Si es **CI**, va a `core`.
- Una plantilla nueva solo se justifica cuando aparece un **tipo de artefacto** que no existe.

## 2. El orden: API primero, web después

Dentro de un proyecto, y dentro de cada pieza, el orden no es indiferente:

1. **API antes que web.** La web existe para llamar a la API. `ll-blazor` trae `ApiBaseUrl`; si la API todavía no responde, la web es un esqueleto muerto.
2. **Local antes que remoto.** Primero se genera, compila, prueba y formatea en el equipo. Publicar antes de comprobar traslada el fallo al CI y multiplica el ruido.
3. **Un frente abierto.** Dos repositorios a la vez son dos CI, dos bandejas de Dependabot y dos pull requests. La web no se pierde por esperar: se genera en minutos cuando la API ya responde.

El CORS refuerza ese orden: la web necesita que la API permita su origen. Esa decisión se toma con la API delante; al revés, se acaba relajando la denegación por defecto para que la web cargue, y eso no se hace.

## 3. Qué significa «segura de base»

No significa «con login». Significa que el proyecto nace con los controles que no dependen del negocio. La autenticación se añade después, cuando hay emisor, audiencia y usuarios: el paquete la trae, pero la plantilla no la activa porque no puede inventar esos valores.

### API (`ll-api`)

| Control | Dónde vive |
|---|---|
| CORS sin orígenes por defecto | `LL.Security` |
| Cabeceras de seguridad y `Server` apagada | `LL.Security` |
| Política de contenido | `LL.Security` |
| Límite por IP | `LL.Security` |
| JWT endurecido, disponible sin montar | `LL.Security` |
| ProblemDetails | `LL.Hosting` |
| HTTPS con HSTS | `LL.Hosting` |
| Salud anónima | `LL.Hosting` |
| Capas y regla de dependencias | plantilla |
| Dockerfile sin privilegios | plantilla |
| Compilación, formato y pruebas | `core/actions/dotnet` |
| Gitleaks sobre el historial completo | `core/actions/gitleaks` |
| CodeQL | `core/actions/sast` |
| Trivy sobre dependencias e imagen | `core/actions/scan` |
| Contenedor sin root y revisión de dependencias | workflow generado |
| Dependabot con auto-merge de parche y minor | plantilla |

**No entra:** autenticación montada, negocio, datos ni secretos. La autenticación necesita un emisor y una audiencia reales; montarla con marcadores produce un servicio que arranca mal configurado.

### Web (`ll-blazor`)

| Control | Dónde vive |
|---|---|
| Todo `wwwroot` se considera público | regla de la plantilla |
| nginx sin privilegios y en el puerto 8080 | contenedor |
| `server_tokens off` y cabeceras de seguridad | `nginx.conf` |
| El origen de la web se declara en el CORS de la API | configuración del consumidor |
| Compilación, formato y pruebas | `core/actions/dotnet` |
| Gitleaks sobre el historial completo | `core/actions/gitleaks` |
| Dependabot con auto-merge de parche y minor | plantilla |

**No entra:** autenticación, lógica de servidor ni secretos. Lo que se publica en `wwwroot` lo ve cualquiera.

El inventario exacto, con los archivos, está en el [`README`](../README.md) y en el `AGENTS.md` del repositorio generado. Esta sección solo explica qué significa «base»; no repite el código, que vive en `templates/`.

## 4. Genera y comprueba el proyecto

```bash
dotnet new install ./templates/ll-api
dotnet new ll-api -n MiApi -o ../mi-api
```

`ll-api` restaura los paquetes `LL.*` desde GitHub Packages, que exige autenticación incluso para leer paquetes públicos: exporta `GH_PACKAGES_TOKEN` con permiso `read:packages` antes de restaurar. No uses `GITHUB_TOKEN`: `gh` y Git la leen como credencial de sesión y un token sin `repo` deja los `push` en `403`.

La instalación, el token y los comandos de restauración, compilación, pruebas, formato y Gitleaks son los del [`README`](../README.md) §Uso; no se repiten aquí. El `AGENTS.md` del repositorio generado tiene los comandos exactos de esa pieza, y esos mandan sobre esta guía. Si alguno falla, se corrige la causa: no se relaja la comprobación para que pase.

La API tiene una comprobación que las pruebas no ven: `TestServer` no escribe la cabecera `Server`. Se arranca, se espera a que responda y se mira `/health`:

```bash
ASPNETCORE_URLS=http://127.0.0.1:8099 dotnet run --project src/MiApi.Api --no-launch-profile &
api_pid=$!
respondio=0
for _ in $(seq 1 30); do
  if curl -fsS -D /tmp/health-headers -o /dev/null --connect-timeout 1 --max-time 2 http://127.0.0.1:8099/health; then
    respondio=1
    break
  fi
  sleep 1
done
if [ "$respondio" -ne 1 ]; then
  echo "la API no respondió" >&2
elif grep -qi '^server:' /tmp/health-headers; then
  echo "publica Server"
else
  echo "sin cabecera Server"
fi
kill "$api_pid" 2>/dev/null || true
```

### Web

Con la API en marcha, la web se genera y se apunta a ella:

```bash
dotnet new install ./templates/ll-blazor
dotnet new ll-blazor -n MiWeb -o ../mi-web
```

Después, antes de compilar:

1. Pon la dirección de la API en `wwwroot/appsettings.json` (`ApiBaseUrl`).
2. Añade el origen de la web a `Cors:AllowedOrigins` de la API. No se relaja la denegación por defecto: se declara el origen concreto.
3. Pasa las mismas comprobaciones que en la API (`restore`, `build`, `test`, `format` y Gitleaks). `ll-blazor` no necesita `GH_PACKAGES_TOKEN` porque solo usa nuget.org.

## 5. Publícalo

El repositorio remoto nace con `main` protegida, rama y pull request, checks obligatorios y Dependabot. La regla de rama se aplica con la acción `regla-rama` de `core`, no marcando casillas a mano. El procedimiento completo, con las comprobaciones y el orden, está en [`core/docs/crear-un-repositorio.md`](https://github.com/lanuzalorenzo/core/blob/main/docs/crear-un-repositorio.md); la apertura a público, en [`core/docs/publicar-un-repositorio.md`](https://github.com/lanuzalorenzo/core/blob/main/docs/publicar-un-repositorio.md).

Regla que no se salta: **nunca push directo a `main`**, ni siquiera el primero. El primer cambio entra por rama y pull request.

## 6. Convierte el recorrido en plantilla

### 6.1 Cuándo

Solo cuando aparece un tipo de artefacto nuevo que no se cubre con una plantilla existente. Una variante se resuelve con una opción en la plantilla que ya hay; un control, en `shared-dotnet`; un paso de CI, en `core`.

### 6.2 Dónde

```text
templates/<nombre>/
  .template.config/template.json   # la definición: identidad, nombre corto, símbolos
  <contenido generado en la raíz>   # el proyecto tal y como nace
  assets/iconos/                    # el icono que referencia el README
```

El contenido generado va en la raíz de la carpeta, no dentro de una subcarpeta. `dotnet new` copia esa raíz y sustituye los símbolos.

### 6.3 Pasos

1. **Parte de la plantilla más cercana.** Se copia el molde, no el repositorio de un consumidor: copiar `ll-api` o `ll-blazor` y quitar lo que no aplique es más seguro que empezar en blanco.
2. **Ajusta `template.json`:** `identity`, `name`, `description`, `shortName`, `sourceName` y `classifications`. El `sourceName` es el nombre que se sustituye al generar; si el proyecto necesita más símbolos, se declaran en `symbols`.
3. **Mantén la exclusión de `bin` y `obj`** en `sources.modifiers`. Si no, el molde arrastra artefactos de compilación.
4. **Revisa los nombres.** Carpetas, soluciones, proyectos y espacios de nombres tienen que usar el `sourceName`, no un nombre fijo.
5. **Ajusta `README.md`, `AGENTS.md` y `LICENSE`.** El README generado explica qué es y cómo se arranca; el `AGENTS.md`, la estructura y la verificación reales; la licencia, el titular. Sin referencias a repositorios privados, rutas del workspace ni documentos internos.
6. **Fija las acciones de `core` por etiqueta publicada** en `.github/workflows/ci.yml`, y añade Dependabot para cada ecosistema presente y para GitHub Actions.
7. **Añade el icono** en `assets/iconos/` y comprueba que la ruta del README viaja con la plantilla. `verify-template.sh` falla si el README apunta a un icono que no existe.
8. **Si el proyecto es publicable**, declara `IsPackable` y `PackageReadmeFile`. El recorrido ya empaqueta y comprueba que el `.nupkg` contiene la biblioteca; no añadas lógica al script.

### 6.4 Contrato

- La plantilla no duplica la lógica de `shared-dotnet`: la consume por versión publicada.
- Una sola versión por paquete en `Directory.Packages.props`; la auditoría de dependencias falla la compilación ante una vulnerabilidad conocida.
- El contenido generado no cita repositorios privados, rutas del workspace ni documentos internos.
- Sin secretos ni credenciales versionadas.
- Dockerfile con usuario no privilegiado.
- Las comprobaciones de seguridad no se relajan para que una plantilla pase.

### 6.5 Verificación

```bash
./scripts/verify-template.sh
gitleaks detect --source . --redact --verbose --exit-code 2
```

El recorrido instala también `ll-api`, así que necesita `GH_PACKAGES_TOKEN` exportado, como en el [`README`](../README.md) §Uso. El script recorre todas las plantillas: instala cada una en un directorio temporal, genera un proyecto, restaura, compila, prueba, comprueba el formato, arranca la API y verifica que `/health` no publica `Server`, y empaqueta lo que se declare publicable.

Una plantilla que no puede generar, compilar y probar un proyecto no se publica. Y un recorrido verde en local no demuestra que el CI funcione: eso solo lo dice una ejecución real en un repositorio generado.

### 6.6 Publicación

El cambio entra por rama y pull request; `main` exige los checks del repositorio y rama actualizada. Al añadir una plantilla, actualiza la tabla de [`README.md`](../README.md) y, si cambia la estructura del repositorio, [`AGENTS.md`](../AGENTS.md).

Una plantilla nueva no se declara **Validado** por compilar en local. El estado sale de la evidencia: generación, compilación y pruebas en el recorrido; y, para **Validado**, una ejecución real del CI en un repositorio generado, fechada.

## 7. Lista de comprobación

- [ ] El artefacto no se cubre con una plantilla existente; es un tipo nuevo, no una variante.
- [ ] El contenido generado está en la raíz de `templates/<nombre>/`.
- [ ] `template.json` tiene identidad, nombre corto, `sourceName` y exclusiones de `bin` y `obj`.
- [ ] README, `AGENTS.md` y `LICENSE` se ajustan al proyecto generado y no citan lo privado.
- [ ] Las acciones de `core` van fijadas por etiqueta y Dependabot cubre los ecosistemas presentes.
- [ ] El Dockerfile no ejecuta como root.
- [ ] `verify-template.sh` termina sin fallos y Gitleaks no encuentra nada.
- [ ] El primer CI en un repositorio generado pasa en verde antes de declarar **Validado**.
- [ ] La tabla del README y la estructura de `AGENTS.md` están al día.

## 8. Dónde está la verdad

| Qué quieres | Abre |
|---|---|
| Qué crea cada plantilla y cómo se usa | [`README.md`](../README.md) |
| Qué debe cumplir una plantilla | [`AGENTS.md`](../AGENTS.md) |
| Cómo se verifica | [`scripts/verify-template.sh`](../scripts/verify-template.sh) |
| Por qué las plantillas están fuera de `shared-dotnet` | [ADR 0003](https://github.com/lanuzalorenzo/shared-dotnet/blob/main/docs/adr/0003-plantillas-fuera-del-repositorio.md) |
| Los controles que consumen las APIs | [`shared-dotnet`](https://github.com/lanuzalorenzo/shared-dotnet) |
| Crear un repositorio con la línea base | [`core/docs/crear-un-repositorio.md`](https://github.com/lanuzalorenzo/core/blob/main/docs/crear-un-repositorio.md) |
| Abrir un repositorio a público | [`core/docs/publicar-un-repositorio.md`](https://github.com/lanuzalorenzo/core/blob/main/docs/publicar-un-repositorio.md) |
| Los controles aplicados y observados | [portfolio, módulo 07](https://github.com/lanuzalorenzo/portfolio-ciberseguridad-lorenzo/tree/main/07-devsecops) |

Licencia: MIT.
