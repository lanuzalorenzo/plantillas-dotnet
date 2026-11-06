using System.Net;
using System.Text;
using CompanyWeb.Services;

namespace CompanyWeb.Tests;

public sealed class ApiClientTests
{
    [Fact]
    public async Task Lee_el_mensaje_de_la_api()
    {
        using var manejador = new ManejadorFalso(HttpStatusCode.OK, """{"mensaje":"Hola"}""");
        using var http = new HttpClient(manejador) { BaseAddress = new Uri("https://api.test/") };
        var cliente = new ApiClient(http);

        var mensaje = await cliente.ObtenerSaludoAsync();

        Assert.Equal("Hola", mensaje);
    }

    [Fact]
    public async Task Un_error_de_la_api_se_propaga()
    {
        using var manejador = new ManejadorFalso(HttpStatusCode.InternalServerError, "{}");
        using var http = new HttpClient(manejador) { BaseAddress = new Uri("https://api.test/") };
        var cliente = new ApiClient(http);

        await Assert.ThrowsAsync<HttpRequestException>(() => cliente.ObtenerSaludoAsync());
    }

    private sealed class ManejadorFalso(HttpStatusCode estado, string cuerpo) : HttpMessageHandler
    {
        protected override Task<HttpResponseMessage> SendAsync(
            HttpRequestMessage request,
            CancellationToken cancellationToken) =>
            Task.FromResult(new HttpResponseMessage(estado)
            {
                Content = new StringContent(cuerpo, Encoding.UTF8, "application/json")
            });
    }
}
