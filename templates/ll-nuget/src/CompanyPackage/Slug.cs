using System.Globalization;
using System.Text;

namespace CompanyPackage;

/// <summary>
/// Convierte un texto en un identificador estable: minúsculas, sin acentos y con guiones.
/// </summary>
public static class Slug
{
    public static string Create(string? value)
    {
        if (string.IsNullOrWhiteSpace(value))
        {
            return string.Empty;
        }

        var slug = new StringBuilder(value.Length);
        var pendingSeparator = false;

        foreach (var character in value.Normalize(NormalizationForm.FormD))
        {
            if (CharUnicodeInfo.GetUnicodeCategory(character) == UnicodeCategory.NonSpacingMark)
            {
                continue;
            }

            if (char.IsLetterOrDigit(character))
            {
                if (pendingSeparator && slug.Length > 0)
                {
                    slug.Append('-');
                }

                slug.Append(char.ToLowerInvariant(character));
                pendingSeparator = false;
            }
            else
            {
                pendingSeparator = true;
            }
        }

        return slug.ToString();
    }
}
