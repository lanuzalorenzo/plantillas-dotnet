using System.Text.Json;

namespace CompanyWeb.Services;

/// <summary>Cliente HTTP mínimo para la API que consume la aplicación.</summary>
public sealed class ApiClient(HttpClient http)
{
    public async Task<string?> ObtenerSaludoAsync(CancellationToken cancellationToken = default)
    {
        using var respuesta = await http.GetAsync("api/saludo", cancellationToken);
        respuesta.EnsureSuccessStatusCode();

        await using var contenido = await respuesta.Content.ReadAsStreamAsync(cancellationToken);
        using var documento = await JsonDocument.ParseAsync(contenido, cancellationToken: cancellationToken);

        return documento.RootElement.TryGetProperty("mensaje", out var mensaje)
            ? mensaje.GetString()
            : null;
    }
}
