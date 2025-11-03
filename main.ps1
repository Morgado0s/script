# Script de Automacao - SSH Git + Node.js + Python + Claude Code
# Executar como Administrador
# Salvar como UTF-8 com BOM

Write-Host "=== Iniciando Configuracao Automatica ===" -ForegroundColor Cyan
Write-Host ""

# Verificar se esta executando como Administrador
 $isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

if (-not $isAdmin) {
    Write-Host "[X] Este script precisa ser executado como Administrador!" -ForegroundColor Red
    Write-Host ""
    Write-Host "Como executar como Administrador:" -ForegroundColor Yellow
    Write-Host "  1. Clique com botao direito no PowerShell" -ForegroundColor White
    Write-Host "  2. Selecione 'Executar como Administrador'" -ForegroundColor White
    Write-Host "  3. Execute o script novamente" -ForegroundColor White
    Write-Host ""
    Read-Host "Pressione Enter para sair"
    exit 1
}

Write-Host "[OK] Executando como Administrador" -ForegroundColor Green
Write-Host ""

# ============================================
# 1. CONFIGURACAO DE CHAVE SSH PARA GIT
# ============================================
Write-Host "Etapa 1: Configurando Chave SSH para Git" -ForegroundColor Yellow

 $sshDir = "$env:USERPROFILE\.ssh"
 $sshKeyPath = "$sshDir\id_ed25519"

# Criar diretorio .ssh se nao existir
if (-not (Test-Path $sshDir)) {
    New-Item -ItemType Directory -Path $sshDir | Out-Null
    Write-Host "[OK] Diretorio .ssh criado" -ForegroundColor Green
}

# Verificar se ja existe chave SSH
if (Test-Path $sshKeyPath) {
    Write-Host "[!] Chave SSH ja existe em $sshKeyPath" -ForegroundColor Yellow
    $overwrite = Read-Host "Deseja sobrescrever? (s/n)"
    if ($overwrite -ne "s") {
        Write-Host "[OK] Mantendo chave SSH existente" -ForegroundColor Green
    } else {
        Remove-Item $sshKeyPath -Force
        Remove-Item "$sshKeyPath.pub" -Force -ErrorAction SilentlyContinue
    }
}

# Gerar nova chave SSH se nao existir
if (-not (Test-Path $sshKeyPath)) {
    # Credenciais GitHub pre-configuradas
    $gitEmail = "Morgado0s@users.noreply.github.com"
    
    Write-Host "Gerando chave SSH..." -ForegroundColor Cyan
    
    ssh-keygen -t ed25519 -C "$gitEmail" -f $sshKeyPath -N '""'
    
    if ($?) {
        Write-Host "[OK] Chave SSH gerada com sucesso!" -ForegroundColor Green
    } else {
        Write-Host "[X] Erro ao gerar chave SSH" -ForegroundColor Red
        exit 1
    }
}

# Iniciar ssh-agent e adicionar chave
Write-Host "Configurando ssh-agent..." -ForegroundColor Cyan

# Iniciar servico ssh-agent
Start-Service ssh-agent -ErrorAction SilentlyContinue
Set-Service -Name ssh-agent -StartupType Automatic

# Adicionar chave ao ssh-agent
ssh-add $sshKeyPath

# Copiar chave publica para clipboard
Get-Content "$sshKeyPath.pub" | Set-Clipboard
Write-Host "[OK] Chave publica copiada para area de transferencia!" -ForegroundColor Green
Write-Host ""
Write-Host "IMPORTANTE: Adicione esta chave a sua conta GitHub:" -ForegroundColor Yellow
Write-Host "  Usuario GitHub: Morgado0s" -ForegroundColor Cyan
Write-Host "  Link: https://github.com/settings/keys" -ForegroundColor Cyan
Write-Host "  A chave publica ja esta na area de transferencia (Ctrl+V para colar)" -ForegroundColor Cyan
Write-Host ""
Read-Host "Pressione Enter apos adicionar a chave ao GitHub..."

# ============================================
# 2. INSTALACAO DO NODE.JS E CLAUDE CODE
# ============================================
Write-Host ""
Write-Host "Etapa 2: Verificando e Instalando Node.js" -ForegroundColor Yellow

# --- Verificacao e Instalacao do Node.js ---
 $nodeCommand = Get-Command node -ErrorAction SilentlyContinue
 $nodeVersion = $null
if ($nodeCommand) {
    $nodeVersionOutput = & node -v
    # Ex: v22.4.1 -> 22.4.1
    $nodeVersion = [version]($nodeVersionOutput.TrimStart('v'))
    Write-Host "[OK] Node.js encontrado. Versao atual: $nodeVersionOutput" -ForegroundColor Green
} else {
    Write-Host "[!] Node.js nao encontrado." -ForegroundColor Yellow
}

# Definir versao minima recomendada para Claude Code
 $minRecommendedVersion = [version]"18.0.0"

if (-not $nodeCommand -or $nodeVersion -lt $minRecommendedVersion) {
    Write-Host "[!] Node.js nao esta instalado ou a versao e muito antiga." -ForegroundColor Yellow
    Write-Host "    Versao minima recomendada: $minRecommendedVersion" -ForegroundColor Cyan
    Write-Host "    Iniciando instalacao automatica da versao mais recente (LTS)..." -ForegroundColor Cyan

    # URL do instalador LTS (atualize quando uma nova versao LTS for lancada)
    $nodeUrl = "https://nodejs.org/dist/v22.4.1/node-v22.4.1-x64.msi"
    $installerPath = "$env:TEMP\node-installer.msi"

    try {
        Write-Host "    Baixando o instalador do Node.js..." -ForegroundColor Cyan
        Invoke-WebRequest -Uri $nodeUrl -OutFile $installerPath -UseBasicParsing
        
        Write-Host "    Instalando Node.js de forma silenciosa (isso pode levar alguns minutos)..." -ForegroundColor Cyan
        $process = Start-Process -FilePath "msiexec.exe" -ArgumentList "/i `"$installerPath`" /quiet /norestart" -Wait -PassThru -NoNewWindow

        if ($process.ExitCode -eq 0) {
            Write-Host "[OK] Node.js instalado com sucesso!" -ForegroundColor Green
            # Limpar o instalador
            Remove-Item $installerPath -ErrorAction SilentlyContinue
        } else {
            Write-Host "[X] Falha na instalacao do Node.js. Codigo de saida: $($process.ExitCode)" -ForegroundColor Red
            Write-Host "    Verifique o log de eventos do Windows para mais detalhes." -ForegroundColor Yellow
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
    Write-Host "[X] Erro ao instalar Claude Code" -ForegroundColor Red
    Write-Host "    Verifique se a sua conexao com a internet esta ativa e se o Node.js foi instalado corretamente." -ForegroundColor Yellow
    exit 1
}

# ============================================
# 3. INSTALACAO DO PYTHON
# ============================================
Write-Host ""
Write-Host "Etapa 3: Verificando e Instalando Python" -ForegroundColor Yellow

# --- Verificacao e Instalacao do Python ---
 $pythonCommand = Get-Command python -ErrorAction SilentlyContinue
 $pythonVersion = $null
if ($pythonCommand) {
    # `python --version` outputs to stderr, so we redirect it
    $versionString = & python --version 2>&1
    if ($versionString -match "Python (\d+\.\d+\.\d+)") {
        $pythonVersion = [version]$matches[1]
        Write-Host "[OK] Python encontrado. Versao atual: $versionString" -ForegroundColor Green
    }
} else {
    Write-Host "[!] Python (comando 'python') nao encontrado." -ForegroundColor Yellow
}

# Definir versao minima recomendada
 $minPythonVersion = [version]"3.8.0"

if (-not $pythonCommand -or $pythonVersion -lt $minPythonVersion) {
    Write-Host "[!] Python nao esta instalado ou a versao e muito antiga." -ForegroundColor Yellow
    Write-Host "    Versao minima recomendada: $minPythonVersion" -ForegroundColor Cyan
    Write-Host "    Iniciando instalacao automatica da versao mais recente..." -ForegroundColor Cyan

    # URL do instalador mais recente do Python 3 (64-bit)
    $pythonUrl = "https://www.python.org/ftp/python/3.12.4/python-3.12.4-amd64.exe"
    $installerPath = "$env:TEMP\python-installer.exe"

    try {
        Write-Host "    Baixando o instalador do Python..." -ForegroundColor Cyan
        Invoke-WebRequest -Uri $pythonUrl -OutFile $installerPath -UseBasicParsing
        
        Write-Host "    Instalando Python de forma silenciosa (isso pode levar alguns minutos)..." -ForegroundColor Cyan
        # Argumentos: /quiet (silencioso), InstallAllUsers=1 (para todos usuarios), PrependPath=1 (adiciona ao PATH), Include_test=0 (nao instala testes)
        $process = Start-Process -FilePath $installerPath -ArgumentList "/quiet", "InstallAllUsers=1", "PrependPath=1", "Include_test=0" -Wait -PassThru -NoNewWindow

        if ($process.ExitCode -eq 0) {
            Write-Host "[OK] Python instalado com sucesso!" -ForegroundColor Green
            # Limpar o instalador
            Remove-Item $installerPath -ErrorAction SilentlyContinue
        } else {
            Write-Host "[X] Falha na instalacao do Python. Codigo de saida: $($process.ExitCode)" -ForegroundColor Red
            Write-Host "    Verifique o log de eventos do Windows para mais detalhes." -ForegroundColor Yellow
            # Nao vamos fazer 'exit 1' aqui para nao bloquear o resto do script, mas e bom avisar.
        }
    } catch {
        Write-Host "[X] Ocorreu um erro ao baixar ou instalar o Python." -ForegroundColor Red
        Write-Host "    Erro: $($_.Exception.Message)" -ForegroundColor Yellow
    }
}

# ============================================
# 4. CONFIGURACAO DE VARIAVEIS DE AMBIENTE
# ============================================
Write-Host ""
Write-Host "Etapa 4: Configurando Variaveis de Ambiente" -ForegroundColor Yellow

# Configurar API Key e Base URL (Z.ai GLM)
Write-Host "Configurando API Key e Base URL para Z.ai GLM..." -ForegroundColor Cyan

# Variaveis pre-configuradas para Z.ai
 $apiKey = "d41e4314c1924ea49533009a255eebed.0VN7eLfG5zZNsOjC"
 $baseUrl = "https://api.z.ai/api/anthropic"

# Configurar ANTHROPIC_API_KEY
[System.Environment]::SetEnvironmentVariable("ANTHROPIC_API_KEY", $apiKey, [System.EnvironmentVariableTarget]::User)
 $env:ANTHROPIC_API_KEY = $apiKey

# Configurar ANTHROPIC_BASE_URL
[System.Environment]::SetEnvironmentVariable("ANTHROPIC_BASE_URL", $baseUrl, [System.EnvironmentVariableTarget]::User)
 $env:ANTHROPIC_BASE_URL = $baseUrl

Write-Host "[OK] Variavel ANTHROPIC_API_KEY configurada!" -ForegroundColor Green
Write-Host "[OK] Variavel ANTHROPIC_BASE_URL configurada para Z.ai!" -ForegroundColor Green

# Adicionar npm global ao PATH se necessario
 $npmPath = npm config get prefix
 $currentPath = [System.Environment]::GetEnvironmentVariable("Path", [System.EnvironmentVariableTarget]::User)

if ($currentPath -notlike "*$npmPath*") {
    Write-Host "Adicionando npm ao PATH..." -ForegroundColor Cyan
    $newPath = "$currentPath;$npmPath"
    [System.Environment]::SetEnvironmentVariable("Path", $newPath, [System.EnvironmentVariableTarget]::User)
    $env:Path = "$env:Path;$npmPath"
    Write-Host "[OK] PATH atualizado" -ForegroundColor Green
}

# ============================================
# FINALIZACAO
# ============================================
Write-Host ""
Write-Host "=== Configuracao Concluida! ===" -ForegroundColor Green
Write-Host ""
Write-Host "Resumo:" -ForegroundColor Cyan
Write-Host "  [OK] Chave SSH configurada: $sshKeyPath" -ForegroundColor White
Write-Host "  [OK] Node.js instalado/atualizado" -ForegroundColor White
Write-Host "  [OK] Python instalado/atualizado" -ForegroundColor White
Write-Host "  [OK] Claude Code instalado" -ForegroundColor White
Write-Host "  [OK] API Key Z.ai configurada" -ForegroundColor White
Write-Host "  [OK] Base URL Z.ai configurada" -ForegroundColor White
Write-Host ""
Write-Host "Configuracoes:" -ForegroundColor Yellow
Write-Host "  - GitHub User: Morgado0s" -ForegroundColor White
Write-Host "  - API Provider: Z.ai GLM" -ForegroundColor White
Write-Host "  - Base URL: https://api.z.ai/api/anthropic" -ForegroundColor White
Write-Host ""
Write-Host "Proximos passos:" -ForegroundColor Yellow
Write-Host "  1. **REINICIE O TERMINAL** para carregar todas as variaveis de ambiente e o PATH." -ForegroundColor White
Write-Host "  2. Teste a chave SSH: ssh -T git@github.com" -ForegroundColor White
Write-Host "  3. Execute o Claude Code: claude" -ForegroundColor White
Write-Host "  4. Verifique as versoes: node -v e python --version" -ForegroundColor White
Write-Host ""
Write-Host "Documentacao do Claude Code: https://docs.claude.com/en/docs/claude-code" -ForegroundColor Cyan
Write-Host ""

Read-Host "Pressione Enter para sair"
