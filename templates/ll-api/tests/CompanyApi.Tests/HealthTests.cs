using System.Net;

namespace CompanyApi.Tests;

public sealed class HealthTests(ApiFactory factory) : IClassFixture<ApiFactory>
{
    [Fact]
    public async Task Health_responde_sin_autenticacion()
    {
        var cliente = factory.CreateClient();

        var respuesta = await cliente.GetAsync("/health");

        Assert.Equal(HttpStatusCode.OK, respuesta.StatusCode);
    }

    [Fact]
    public async Task Las_respuestas_llevan_cabeceras_de_seguridad()
    {
        var cliente = factory.CreateClient();

        var respuesta = await cliente.GetAsync("/api/saludo");

        Assert.Equal(HttpStatusCode.OK, respuesta.StatusCode);
        Assert.Equal("nosniff", respuesta.Headers.GetValues("X-Content-Type-Options").Single());
        Assert.Equal("DENY", respuesta.Headers.GetValues("X-Frame-Options").Single());
    }
}
