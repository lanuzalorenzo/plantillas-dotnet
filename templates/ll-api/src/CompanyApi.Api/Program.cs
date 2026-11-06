using LL.Hosting;
using LL.Security;
using Microsoft.AspNetCore.RateLimiting;

var builder = WebApplication.CreateBuilder(args);

builder.Services.AddOpenApi();
builder.Services.AddApiProblemDetails();
builder.Services.AddApiHealthChecks();
builder.Services.AddDenyByDefaultCors(builder.Configuration);
builder.Services.AddRemoteIpRateLimiting();

var app = builder.Build();

if (app.Environment.IsDevelopment())
{
    app.MapOpenApi();
}

// El orden importa: las cabeceras se escriben cuando empieza la respuesta y el
// manejador de excepciones va antes que el resto del pipeline de la aplicación.
app.UseSecurityHeaders();
app.UseApiProblemDetails();
app.UseApiTransportSecurity(app.Environment);
app.UseCors("ApiCors");
app.UseRateLimiter();

app.MapGet("/api/saludo", () => Results.Ok(new { mensaje = "Hola" }));
// La sonda de la plataforma no comparte el cupo del tráfico de la API.
app.MapApiHealthChecks().DisableRateLimiting();

app.Run();

// Expuesto para que las pruebas de integración usen WebApplicationFactory<Program>.
public partial class Program;
