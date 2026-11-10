FROM mcr.microsoft.com/dotnet/sdk:11.0 AS build
WORKDIR /src

COPY Directory.Build.props ./
COPY Directory.Packages.props ./
COPY NuGet.config ./
COPY src/CompanyWeb/CompanyWeb.csproj src/CompanyWeb/
RUN dotnet restore src/CompanyWeb/CompanyWeb.csproj

COPY src/CompanyWeb/ src/CompanyWeb/
RUN dotnet publish src/CompanyWeb/CompanyWeb.csproj -c Release -o /app/publish --no-restore

FROM nginxinc/nginx-unprivileged:1.31.7-alpine AS final

COPY nginx.conf /etc/nginx/conf.d/default.conf
COPY --from=build /app/publish/wwwroot /usr/share/nginx/html

EXPOSE 8080
