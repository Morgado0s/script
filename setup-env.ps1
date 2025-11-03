#Requires -RunAsAdministrator
# Script para configurar as variaveis de ambiente do Claude Code.
# Execute por ultimo.

Write-Host "=== Etapa 4: Configurando Variaveis de Ambiente ===" -ForegroundColor Cyan
Write-Host ""

# Configurar API Key e Base URL (Z.ai GLM)
Write-Host "Configurando API Key e Base URL para Z.ai GLM..." -ForegroundColor Cyan

 $apiKey = "d41e4314c1924ea49533009a255eebed.0VN7eLfG5zZNsOjC"
 $baseUrl = "https://api.z.ai/api/anthropic"

# Configurar ANTHROPIC_API_KEY
[System.Environment]::SetEnvironmentVariable("ANTHROPIC_API_KEY", $apiKey, [System.EnvironmentVariableTarget]::User)
 $env:ANTHROPIC_API_KEY = $apiKey
Write-Host "[OK] Variavel ANTHROPIC_API_KEY configurada!" -ForegroundColor Green

# Configurar ANTHROPIC_BASE_URL
[System.Environment]::SetEnvironmentVariable("ANTHROPIC_BASE_URL", $baseUrl, [System.EnvironmentVariableTarget]::User)
 $env:ANTHROPIC_BASE_URL = $baseUrl
Write-Host "[OK] Variavel ANTHROPIC_BASE_URL configurada para Z.ai!" -ForegroundColor Green

# Adicionar npm global ao PATH se necessario
 $npmPath = npm config get prefix
 $currentPath = [System.Environment]::GetEnvironmentVariable("Path", [System.EnvironmentVariableTarget]::User)

if ($currentPath -notlike "*$npmPath*") {
    Write-Host "Adicionando npm ao PATH do usuario..." -ForegroundColor Cyan
    $newPath = "$currentPath;$npmPath"
    [System.Environment]::SetEnvironmentVariable("Path", $newPath, [System.EnvironmentVariableTarget]::User)
    $env:Path = "$env:Path;$npmPath"
    Write-Host "[OK] PATH do usuario atualizado." -ForegroundColor Green
} else {
    Write-Host "[OK] NPM ja esta no PATH do usuario." -ForegroundColor Green
}