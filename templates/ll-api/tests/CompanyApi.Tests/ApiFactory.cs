using Microsoft.AspNetCore.Hosting;
using Microsoft.AspNetCore.Mvc.Testing;

namespace CompanyApi.Tests;

public sealed class ApiFactory : WebApplicationFactory<Program>
{
    protected override void ConfigureWebHost(IWebHostBuilder builder)
    {
        // El entorno de pruebas se salta la redirección a HTTPS: los clientes de
        // prueba hablan HTTP y una redirección les rompería la petición.
        builder.UseEnvironment("Testing");
    }
}
