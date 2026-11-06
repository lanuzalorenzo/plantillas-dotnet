# syntax=docker/dockerfile:1
# Multi-stage, imagen reducida y usuario no privilegiado.

FROM mcr.microsoft.com/dotnet/sdk:10.0 AS build
WORKDIR /src

# La configuración y los csproj van primero para aprovechar la caché de capas.
# GitHub Packages exige token incluso para leer paquetes públicos: entra como
# secreto de BuildKit y no queda en ninguna capa de la imagen.
COPY ["NuGet.config", "."]
COPY ["Directory.Build.props", "."]
COPY ["Directory.Packages.props", "."]
COPY ["src/CompanyApi.Api/CompanyApi.Api.csproj", "src/CompanyApi.Api/"]
COPY ["src/CompanyApi.Domain/CompanyApi.Domain.csproj", "src/CompanyApi.Domain/"]
COPY ["src/CompanyApi.Application/CompanyApi.Application.csproj", "src/CompanyApi.Application/"]
COPY ["src/CompanyApi.Infrastructure/CompanyApi.Infrastructure.csproj", "src/CompanyApi.Infrastructure/"]
RUN --mount=type=secret,id=github_token \
    GITHUB_TOKEN="$(cat /run/secrets/github_token)" \
    dotnet restore "src/CompanyApi.Api/CompanyApi.Api.csproj"

COPY . .
RUN dotnet publish "src/CompanyApi.Api/CompanyApi.Api.csproj" -c Release --no-restore -o /app/publish /p:UseAppHost=false

FROM mcr.microsoft.com/dotnet/aspnet:10.0 AS final
WORKDIR /app

# Parches del sistema operativo base en la construcción, sin listas de APT en la imagen final.
RUN apt-get update \
    && apt-get -y upgrade \
    && rm -rf /var/lib/apt/lists/*

EXPOSE 8080
ENV ASPNETCORE_URLS=http://+:8080
ENV ASPNETCORE_ENVIRONMENT=Production

USER $APP_UID

COPY --from=build --chown=$APP_UID:$APP_UID /app/publish .

ENTRYPOINT ["dotnet", "CompanyApi.Api.dll"]
