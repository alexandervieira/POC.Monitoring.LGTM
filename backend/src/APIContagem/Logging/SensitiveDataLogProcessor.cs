using OpenTelemetry;
using OpenTelemetry.Logs;
using System.Reflection;

namespace APIContagem.Logging;

public class SensitiveDataLogProcessor : BaseProcessor<LogRecord>
{
    private static readonly FieldInfo? _stateField;

    static SensitiveDataLogProcessor()
    {
        _stateField = typeof(LogRecord).GetField("_state", BindingFlags.NonPublic | BindingFlags.Instance);
    }

    public override void OnEnd(LogRecord data)
    {
        try
        {
            Console.WriteLine($"[LGPD] Processando log: {data.Body}");
            
            var state = data.State;
            if (state != null)
            {
                var stateStr = state.ToString();
                if (!string.IsNullOrEmpty(stateStr))
                {
                    var redacted = SensitiveDataRedactor.Redact(stateStr);
                    if (redacted != stateStr && _stateField != null)
                    {
                        Console.WriteLine($"[LGPD] State sanitizado: {stateStr} -> {redacted}");
                        _stateField.SetValue(data, redacted);
                    }
                }
            }

            if (data.Body != null)
            {
                var bodyStr = data.Body.ToString();
                if (!string.IsNullOrEmpty(bodyStr))
                {
                    var redacted = SensitiveDataRedactor.Redact(bodyStr);
                    if (redacted != bodyStr)
                    {
                        Console.WriteLine($"[LGPD] Body sanitizado: {bodyStr} -> {redacted}");
                        var bodyField = typeof(LogRecord).GetField("_body", BindingFlags.NonPublic | BindingFlags.Instance);
                        bodyField?.SetValue(data, redacted);
                    }
                }
            }
        }
        catch (Exception ex)
        {
            Console.WriteLine($"[LGPD] Erro: {ex.Message}");
        }

        base.OnEnd(data);
    }
}
