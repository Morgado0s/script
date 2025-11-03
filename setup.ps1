# Script de Automacao - SSH Git + Claude Code
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
# 2. INSTALACAO DO CLAUDE CODE
# ============================================
Write-Host ""
Write-Host "Etapa 2: Instalando Claude Code" -ForegroundColor Yellow

# Verificar se npm esta instalado
$npmExists = Get-Command npm -ErrorAction SilentlyContinue
if (-not $npmExists) {
    Write-Host "[X] Node.js/npm nao encontrado!" -ForegroundColor Red
    Write-Host "Por favor, instale o Node.js de: https://nodejs.org/" -ForegroundColor Yellow
    $installNode = Read-Host "Deseja abrir o site agora? (s/n)"
    if ($installNode -eq "s") {
        Start-Process "https://nodejs.org/"
    }
    exit 1
}

Write-Host "[OK] npm encontrado" -ForegroundColor Green
Write-Host "Instalando Claude Code globalmente..." -ForegroundColor Cyan

npm install -g @anthropic-ai/claude-code

if ($?) {
    Write-Host "[OK] Claude Code instalado com sucesso!" -ForegroundColor Green
} else {
    Write-Host "[X] Erro ao instalar Claude Code" -ForegroundColor Red
    exit 1
}

# ============================================
# 3. CONFIGURACAO DE VARIAVEIS DE AMBIENTE
# ============================================
Write-Host ""
Write-Host "Etapa 3: Configurando Variaveis de Ambiente" -ForegroundColor Yellow

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
Write-Host "  1. Reinicie o terminal para carregar as variaveis de ambiente" -ForegroundColor White
Write-Host "  2. Teste a chave SSH: ssh -T git@github.com" -ForegroundColor White
Write-Host "  3. Execute o Claude Code: claude-code" -ForegroundColor White
Write-Host ""
Write-Host "Documentacao do Claude Code: https://docs.claude.com/en/docs/claude-code" -ForegroundColor Cyan
Write-Host ""

Read-Host "Pressione Enter para sair"