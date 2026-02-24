using APIContagem;
using APIContagem.Data;
using APIContagem.Models;
using APIContagem.Tracing;
using APIContagem.Logging;
using Microsoft.EntityFrameworkCore;
using OpenTelemetry.Logs;
using OpenTelemetry.Metrics;
using OpenTelemetry.Resources;
using OpenTelemetry.Trace;
using OpenTelemetry.Exporter;
using APIContagem.GDPR;

var builder = WebApplication.CreateBuilder(args);

builder.Services.AddDbContext<ContagemPostgresContext>(options =>
{
    options.UseNpgsql(
        builder.Configuration.GetConnectionString("BaseContagemPostgres"),
        o => o.UseNodaTime());
});

var otlpEndpoint = builder.Configuration["OTEL_EXPORTER_OTLP_ENDPOINT"] ?? "http://localhost:4317";

var resourceBuilder = ResourceBuilder.CreateDefault()
    .AddService(serviceName: OpenTelemetryExtensions.ServiceName,
        serviceVersion: OpenTelemetryExtensions.ServiceVersion);

builder.Services.AddOpenTelemetry()
    .WithTracing((traceBuilder) =>
    {
        traceBuilder
            .AddSource(OpenTelemetryExtensions.ServiceName)
            .SetResourceBuilder(resourceBuilder)
            .AddAspNetCoreInstrumentation()
            .AddHttpClientInstrumentation()
            .AddEntityFrameworkCoreInstrumentation()
            .AddOtlpExporter(options =>
            {
                options.Endpoint = new Uri(otlpEndpoint);
                options.Protocol = OtlpExportProtocol.Grpc;
            });
    });

builder.Logging.AddOpenTelemetry(options =>
{
    options.SetResourceBuilder(resourceBuilder);
    options.IncludeFormattedMessage = false;
    options.IncludeScopes = true;
    options.ParseStateValues = false;
    options.AddProcessor(new SensitiveDataLogProcessor());
    options.AddOtlpExporter(otlpOptions =>
    {
        otlpOptions.Endpoint = new Uri(otlpEndpoint);
        otlpOptions.Protocol = OtlpExportProtocol.Grpc;
    });
});

builder.Services.AddOpenTelemetry()
    .WithMetrics((metricBuilder) =>
    {
        metricBuilder.AddView(
            "http.server.request.duration",
            new ExplicitBucketHistogramConfiguration()
            {
                Boundaries = [0, 0.005, 0.01, 0.025, 0.05, 0.075, 0.1, 0.25, 0.5, 0.75, 1, 2.5, 5, 7.5, 10]
            }
        );
        metricBuilder.AddMeter(
            "System.Diagnostics.Metrics",
            "Microsoft.AspNetCore.Hosting",
            "Microsoft.AspNetCore.Server.Kestrel",
            "System.Net.Http");
        metricBuilder
            .SetResourceBuilder(resourceBuilder)
            .AddAspNetCoreInstrumentation()
            .AddRuntimeInstrumentation()
            .AddProcessInstrumentation()
            .AddHttpClientInstrumentation()
            .AddPrometheusExporter(options =>
            {
                options.ScrapeResponseCacheDurationMilliseconds = 0;
            });
    });

builder.Services.AddOpenApi();

builder.Services.AddScoped<ContagemRepository>();
builder.Services.AddSingleton<Contador>();
builder.Services.AddSingleton(new byte[32]); // Chave AES (em produção, use Key Vault)
builder.Services.AddHttpClient();

var app = builder.Build();

app.UseOpenTelemetryPrometheusScrapingEndpoint();

app.MapOpenApi();

Lock ContagemLock = new();

app.MapGet("/contador", (ContagemRepository repository, Contador contador) =>
{
    using var activity1 = OpenTelemetryExtensions.ActivitySource
        .StartActivity("GerarValorContagem")!;
            
    int valorAtualContador;
    using (ContagemLock.EnterScope())
    {
        contador.Incrementar();
        valorAtualContador = contador.ValorAtual;
    }
    activity1.SetTag("valorAtual", valorAtualContador);
    app.Logger.LogInformation($"Contador - Valor atual: {valorAtualContador}");

    var resultadoContador = new ResultadoContador()
    {
        ValorAtual = contador.ValorAtual,
        Local = contador.Local,
        Kernel = contador.Kernel,
        Framework = contador.Framework,
        Mensagem = app.Configuration["Saudacao"]
    };
    activity1.Stop();

    using var activity2 = OpenTelemetryExtensions.ActivitySource
        .StartActivity("RegistrarRetornarValorContagem")!;

    repository.Insert(resultadoContador);
    app.Logger.LogInformation($"Registro inserido com sucesso! Valor: {valorAtualContador}");

    activity2.SetTag("valorAtual", valorAtualContador);
    activity2.SetTag("horario", $"{DateTime.UtcNow.AddHours(-3):HH:mm:ss}");

    return Results.Ok(resultadoContador);
})
.Produces<ResultadoContador>();

app.MapGet("/badrequest", () =>
{
    using var activity = OpenTelemetryExtensions.ActivitySource
        .StartActivity("SimularBadRequest")!;

    activity.SetTag("erro", "Simulação de Bad Request");
    app.Logger.LogWarning("Simulação de Bad Request realizada.");

    return Results.BadRequest(new { Erro = "Este é um Bad Request simulado." });
});

app.MapGet("/error", () =>
{
    using var activity = OpenTelemetryExtensions.ActivitySource
        .StartActivity("SimularErroInterno")!;

    activity.SetTag("erro", "Simulação de erro interno");
    app.Logger.LogError("Simulação de erro interno (500).");

    throw new InvalidOperationException("Erro simulado para teste de métricas");
});

app.MapGet("/test-lgpd", () =>
{
    using var activity = OpenTelemetryExtensions.ActivitySource
        .StartActivity("TesteLGPD")!;

    app.Logger.LogInformation("Usuário CPF 123.456.789-10 acessou o sistema");
    app.Logger.LogInformation("Email de contato: teste@email.com, telefone (11) 98765-4321");
    app.Logger.LogInformation("Cartão registrado: 4111 1111 1111 1111");
    app.Logger.LogInformation("CNPJ da empresa: 12.345.678/0001-90");
    app.Logger.LogInformation("Token JWT: eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiIxMjM0NTY3ODkwIn0.dozjgNryP4J3jVmNHl0w5N_XgL0n3I9PlFUP0THsR8U");

    return Results.Ok(new { 
        Message = "Logs com dados sensíveis enviados. Verifique o Loki - dados devem estar sanitizados.",
        Expected = new[] {
            "CPF -> ***CPF-REDACTED***",
            "Email -> ***EMAIL-REDACTED***",
            "Telefone -> ***PHONE-REDACTED***",
            "Cartão -> ***CARD-REDACTED***",
            "CNPJ -> ***CNPJ-REDACTED***",
            "JWT -> ***JWT-REDACTED***"
        }
    });
});

app.MapGet("/test-lgpd-hash", () =>
{
    var cpf = "123.456.789-10";
    var userHash = UserHashService.GenerateHash(cpf);
    
    using var activity = OpenTelemetryExtensions.ActivitySource
        .StartActivity("TesteLGPDHash")!;
    
    activity.SetTag("user.id", userHash);
    
    using (app.Logger.BeginScope(new Dictionary<string, object>
    {
        ["user.id"] = userHash
    }))
    {
        app.Logger.LogInformation("Usuário acessou o sistema");
        app.Logger.LogInformation("Ação realizada com sucesso");
    }
    
    return Results.Ok(new { 
        UserHash = userHash,
        Message = "Logs associados ao user_id hash, não ao CPF real"
    });
});

app.MapDelete("/gdpr/user/{cpf}", async (string cpf, IHttpClientFactory httpClientFactory) =>
{
    var userHash = UserHashService.GenerateHash(cpf);
    var httpClient = httpClientFactory.CreateClient();
    
    // Deletar logs no Loki
    var lokiUrl = $"http://localhost:3100/loki/api/v1/delete?query={{user_id=\"{userHash}\"}}";
    await httpClient.PostAsync(lokiUrl, null);
    
    return Results.Ok(new { Message = "Dados excluídos conforme LGPD", UserHash = userHash });
});

app.Run();