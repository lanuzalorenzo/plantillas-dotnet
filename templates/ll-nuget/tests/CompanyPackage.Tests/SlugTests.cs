namespace CompanyPackage.Tests;

public class SlugTests
{
    [Theory]
    [InlineData("Hola Mundo", "hola-mundo")]
    [InlineData("  Acentos: árbol, cañón  ", "acentos-arbol-canon")]
    [InlineData("C# 12 / .NET", "c-12-net")]
    [InlineData("v1.2.3", "v1-2-3")]
    [InlineData("---", "")]
    [InlineData("", "")]
    [InlineData(null, "")]
    public void Create_normaliza_el_texto(string? entrada, string esperado)
    {
        Assert.Equal(esperado, Slug.Create(entrada));
    }
}
