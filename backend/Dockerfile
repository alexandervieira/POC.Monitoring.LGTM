# Etapa de build com Native AOT
FROM mcr.microsoft.com/dotnet/nightly/sdk:10.0-preview AS build
WORKDIR /source

# Copiar arquivos de projeto
COPY src/APIContagem/*.csproj APIContagem/
#COPY src/APIContagem.Application/*.csproj APIContagem.Application/
#COPY src/APIContagem.Infrastructure/*.csproj APIContagem.Infrastructure/

# Restaurar pacotes
RUN dotnet restore APIContagem/APIContagem.csproj /p:PublishReadyToRun=true

# Copiar código fonte
COPY src/ .

# Publicar com Native AOT
RUN dotnet publish APIContagem/APIContagem.csproj \
    -c Release \
    -o /app/publish \
    -p:PublishSingleFile=true \
    -p:PublishTrimmed=true \
    -p:PublishReadyToRun=true \
    -p:EnableCompressionInSingleFile=true \
    -p:DebugType=embedded \
    --self-contained true \
    -r linux-x64

# Imagem final
FROM mcr.microsoft.com/dotnet/nightly/runtime-deps:10.0-preview
WORKDIR /app

# Instalar certificados para HTTPS
RUN apt-get update && \
    apt-get install -y ca-certificates && \
    update-ca-certificates

# Copiar binário compilado
COPY --from=build /app/publish .

# Configurar variáveis de ambiente
ENV ASPNETCORE_ENVIRONMENT=Production
ENV ASPNETCORE_URLS=http://+:8080
ENV OTEL_EXPORTER_OTLP_ENDPOINT=http://alloy:4317
ENV OTEL_SERVICE_NAME=apicontagem

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD curl -f http://localhost:8080/health || exit 1

# Porta do Cloud Run
EXPOSE 8080

ENTRYPOINT ["./APIContagem"]