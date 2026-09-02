param(
    [switch]$NoBuild
)

$ErrorActionPreference = "Stop"

$serviceRoot = Split-Path -Parent $PSScriptRoot
$composeFile = Join-Path $serviceRoot "docker-compose.yml"
$dockerCommand = Get-Command docker -ErrorAction SilentlyContinue

if ($null -eq $dockerCommand) {
    $dockerDesktopCli = Join-Path $env:LOCALAPPDATA "Programs\DockerDesktop\resources\bin\docker.exe"
    if (-not (Test-Path $dockerDesktopCli)) {
        throw "Docker CLI was not found. Start Docker Desktop or add docker to PATH."
    }

    $dockerCommand = Get-Item $dockerDesktopCli
    $env:PATH = "$(Split-Path $dockerDesktopCli);$env:PATH"
}

$docker = $dockerCommand.Source

Write-Host "Starting DMS Order Service stack..."
if ($NoBuild) {
    & $docker compose -f $composeFile up -d
} else {
    & $docker compose -f $composeFile up -d --build
}
if ($LASTEXITCODE -ne 0) {
    exit $LASTEXITCODE
}

Write-Host "`nContainer status:"
& $docker compose -f $composeFile ps
if ($LASTEXITCODE -ne 0) {
    exit $LASTEXITCODE
}

try {
    $health = Invoke-WebRequest -UseBasicParsing "http://localhost:8080/healthz"
    Write-Host "`nAPI health check: HTTP $($health.StatusCode) $($health.Content)"
} catch {
    Write-Error "Stack started but the API health check failed: $($_.Exception.Message)"
    & $docker compose -f $composeFile logs --tail 100 dms-order-service
    exit 1
}

Write-Host "`nAPI:        http://localhost:8080"
Write-Host "Prometheus: http://localhost:9090"
Write-Host "Grafana:    http://localhost:3000"