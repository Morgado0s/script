#Requires -RunAsAdministrator
# Script para instalar o Node.js (se necessario) e o Claude Code.
# Execute apos o script de SSH.

Write-Host "=== Etapa 2: Instalando Node.js e Claude Code ===" -ForegroundColor Cyan
Write-Host ""

# --- Verificacao e Instalacao do Node.js ---
 $nodeCommand = Get-Command node -ErrorAction SilentlyContinue
 $nodeVersion = $null
if ($nodeCommand) {
    $nodeVersionOutput = & node -v
    $nodeVersion = [version]($nodeVersionOutput.TrimStart('v'))
    Write-Host "[OK] Node.js encontrado. Versao atual: $nodeVersionOutput" -ForegroundColor Green
} else {
    Write-Host "[!] Node.js nao encontrado." -ForegroundColor Yellow
}

 $minRecommendedVersion = [version]"18.0.0"

if (-not $nodeCommand -or $nodeVersion -lt $minRecommendedVersion) {
    Write-Host "[!] Node.js nao esta instalado ou a versao e muito antiga." -ForegroundColor Yellow
    Write-Host "    Versao minima recomendada: $minRecommendedVersion" -ForegroundColor Cyan
    Write-Host "    Iniciando instalacao automatica da versao mais recente (LTS)..." -ForegroundColor Cyan

    $nodeUrl = "https://nodejs.org/dist/v22.4.1/node-v22.4.1-x64.msi"
    $installerPath = "$env:TEMP\node-installer.msi"

    try {
        Write-Host "    Baixando o instalador do Node.js..." -ForegroundColor Cyan
        Invoke-WebRequest -Uri $nodeUrl -OutFile $installerPath -UseBasicParsing
        
        Write-Host "    Instalando Node.js de forma silenciosa (isso pode levar alguns minutos)..." -ForegroundColor Cyan
        $process = Start-Process -FilePath "msiexec.exe" -ArgumentList "/i `"$installerPath`" /quiet /norestart" -Wait -PassThru -NoNewWindow

        if ($process.ExitCode -eq 0) {
            Write-Host "[OK] Node.js instalado com sucesso!" -ForegroundColor Green
            Remove-Item $installerPath -ErrorAction SilentlyContinue
        } else {
            Write-Host "[X] Falha na instalacao do Node.js. Codigo de saida: $($process.ExitCode)" -ForegroundColor Red
            exit 1
        }
    } catch {
        Write-Host "[X] Ocorreu um erro ao baixar ou instalar o Node.js." -ForegroundColor Red
        Write-Host "    Erro: $($_.Exception.Message)" -ForegroundColor Yellow
        exit 1
    }
}

# --- Instalacao do Claude Code ---
Write-Host ""
Write-Host "Instalando Claude Code globalmente..." -ForegroundColor Cyan
npm install -g @anthropic-ai/claude-code

if ($?) {
    Write-Host "[OK] Claude Code instalado com sucesso!" -ForegroundColor Green
} else {
    Write-Host "[X] Erro ao instalar Claude Code." -ForegroundColor Red
    exit 1
}