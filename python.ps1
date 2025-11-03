#Requires -RunAsAdministrator
# Script para instalar o Python (se necessario).
# Execute apos o script de Node.js.

Write-Host "=== Etapa 3: Instalando Python ===" -ForegroundColor Cyan
Write-Host ""

# --- Verificacao e Instalacao do Python ---
 $pythonCommand = Get-Command python -ErrorAction SilentlyContinue
 $pythonVersion = $null
if ($pythonCommand) {
    $versionString = & python --version 2>&1
    if ($versionString -match "Python (\d+\.\d+\.\d+)") {
        $pythonVersion = [version]$matches[1]
        Write-Host "[OK] Python encontrado. Versao atual: $versionString" -ForegroundColor Green
    }
} else {
    Write-Host "[!] Python (comando 'python') nao encontrado." -ForegroundColor Yellow
}

 $minPythonVersion = [version]"3.8.0"

if (-not $pythonCommand -or $pythonVersion -lt $minPythonVersion) {
    Write-Host "[!] Python nao esta instalado ou a versao e muito antiga." -ForegroundColor Yellow
    Write-Host "    Versao minima recomendada: $minPythonVersion" -ForegroundColor Cyan
    Write-Host "    Iniciando instalacao automatica da versao mais recente..." -ForegroundColor Cyan

    $pythonUrl = "https://www.python.org/ftp/python/3.12.4/python-3.12.4-amd64.exe"
    $installerPath = "$env:TEMP\python-installer.exe"

    try {
        Write-Host "    Baixando o instalador do Python..." -ForegroundColor Cyan
        Invoke-WebRequest -Uri $pythonUrl -OutFile $installerPath -UseBasicParsing
        
        Write-Host "    Instalando Python de forma silenciosa (isso pode levar alguns minutos)..." -ForegroundColor Cyan
        $process = Start-Process -FilePath $installerPath -ArgumentList "/quiet", "InstallAllUsers=1", "PrependPath=1", "Include_test=0" -Wait -PassThru -NoNewWindow

        if ($process.ExitCode -eq 0) {
            Write-Host "[OK] Python instalado com sucesso!" -ForegroundColor Green
            Remove-Item $installerPath -ErrorAction SilentlyContinue
        } else {
            Write-Host "[X] Falha na instalacao do Python. Codigo de saida: $($process.ExitCode)" -ForegroundColor Red
            exit 1
        }
    } catch {
        Write-Host "[X] Ocorreu um erro ao baixar ou instalar o Python." -ForegroundColor Red
        Write-Host "    Erro: $($_.Exception.Message)" -ForegroundColor Yellow
        exit 1
    }
}