using System.Text.RegularExpressions;

namespace APIContagem.Logging;

public partial class SensitiveDataRedactor
{
    [GeneratedRegex(@"\d{3}\.?\d{3}\.?\d{3}-?\d{2}", RegexOptions.Compiled)]
    private static partial Regex CpfRegex();

    [GeneratedRegex(@"[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}", RegexOptions.Compiled)]
    private static partial Regex EmailRegex();

    [GeneratedRegex(@"\d{4}[\s-]?\d{4}[\s-]?\d{4}[\s-]?\d{4}", RegexOptions.Compiled)]
    private static partial Regex CardRegex();

    [GeneratedRegex(@"\(?\d{2}\)?\s?\d{4,5}-?\d{4}", RegexOptions.Compiled)]
    private static partial Regex PhoneRegex();

    [GeneratedRegex(@"\d{2}\.?\d{3}\.?\d{3}\/?\d{4}-?\d{2}", RegexOptions.Compiled)]
    private static partial Regex CnpjRegex();

    [GeneratedRegex(@"eyJ[a-zA-Z0-9_-]+\.[a-zA-Z0-9_-]+\.[a-zA-Z0-9_-]+", RegexOptions.Compiled)]
    private static partial Regex JwtRegex();

    public static string Redact(string message)
    {
        if (string.IsNullOrEmpty(message))
            return message;

        message = CpfRegex().Replace(message, "***CPF-REDACTED***");
        message = EmailRegex().Replace(message, "***EMAIL-REDACTED***");
        message = CardRegex().Replace(message, "***CARD-REDACTED***");
        message = PhoneRegex().Replace(message, "***PHONE-REDACTED***");
        message = CnpjRegex().Replace(message, "***CNPJ-REDACTED***");
        message = JwtRegex().Replace(message, "***JWT-REDACTED***");

        return message;
    }
}
