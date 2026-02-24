Write-Host "=== Enviando trace de teste para Tempo ===" -ForegroundColor Cyan

$traceId = [System.Guid]::NewGuid().ToString("N").Substring(0, 16)
$spanId = [System.Guid]::NewGuid().ToString("N").Substring(0, 8)

$tracePayload = @{
    resourceSpans = @(
        @{
            resource = @{
                attributes = @(
                    @{key = "service.name"; value = @{stringValue = "test-service"}}
                )
            }
            scopeSpans = @(
                @{
                    spans = @(
                        @{
                            traceId = $traceId
                            spanId = $spanId
                            name = "test-span"
                            kind = 1
                            startTimeUnixNano = [DateTimeOffset]::UtcNow.ToUnixTimeMilliseconds() * 1000000
                            endTimeUnixNano = ([DateTimeOffset]::UtcNow.ToUnixTimeMilliseconds() + 100) * 1000000
                            attributes = @(
                                @{key = "http.method"; value = @{stringValue = "GET"}}
                                @{key = "http.route"; value = @{stringValue = "/test"}}
                            )
                        }
                    )
                }
            )
        }
    )
} | ConvertTo-Json -Depth 10

try {
    $response = Invoke-RestMethod -Uri "http://localhost:4318/v1/traces" -Method Post -Body $tracePayload -ContentType "application/json"
    Write-Host "✅ Trace enviado com sucesso!" -ForegroundColor Green
    Write-Host "TraceID: $traceId" -ForegroundColor Yellow
} catch {
    Write-Host "❌ Erro ao enviar trace: $_" -ForegroundColor Red
}

# Aguardar processamento
Start-Sleep -Seconds 2

# Buscar o trace no Tempo
Write-Host "`nBuscando trace no Tempo..." -ForegroundColor Yellow
try {
    $trace = Invoke-RestMethod -Uri "http://localhost:3200/api/traces/$traceId" -ErrorAction SilentlyContinue
    if ($trace) {
        Write-Host "✅ Trace encontrado no Tempo!" -ForegroundColor Green
    } else {
        Write-Host "❌ Trace não encontrado no Tempo" -ForegroundColor Red
    }
} catch {
    Write-Host "❌ Erro ao buscar trace: $_" -ForegroundColor Red
}