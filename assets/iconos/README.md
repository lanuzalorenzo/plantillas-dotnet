# Iconos del repositorio

`plantillas-dotnet.svg` es el icono de este repositorio y encabeza su README. Las tres plantillas llevan cada una el suyo dentro de `templates/ll-*/assets/iconos/`, porque `dotnet new` genera un repositorio nuevo y la cabecera tiene que resolver allí:

- `ll-api.svg`: ángulos con un punto central, por la API y su contrato de endpoints.
- `ll-blazor.svg`: ventana de navegador con sus tres puntos, por la aplicación web sin lógica de servidor.
- `ll-nuget.svg`: caja isométrica, por el paquete que se publica en GitHub Packages.

Formato común: 64×64, `rx=16`, fondo navy con degradado (`#07131e` → `#0e2a47`), borde cian sólido de 2 px (`#38bdf8`) y glifo blanco relleno (`#f8fafc`) en una caja de 44×44 centrada. El icono lleva su propio fondo, así que se lee sobre GitHub claro y oscuro. Sin texto, número ni color por plantilla; las cuatro siluetas se distinguen entre sí a 32 px.

En el visor de NuGet la ruta relativa del README no resuelve: el icono se ve en GitHub, no en la ficha del paquete.
