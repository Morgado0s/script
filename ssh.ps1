#Requires -RunAsAdministrator
# Script para gerar e configurar a chave SSH para o GitHub.
# Execute este script primeiro.

Write-Host "=== Etapa 1: Configurando Chave SSH para Git ===" -ForegroundColor Cyan
Write-Host ""

 $sshDir = "$env:USERPROFILE\.ssh"
 $sshKeyPath = "$sshDir\id_ed25519"

# Criar diretorio .ssh se nao existir
if (-not (Test-Path $sshDir)) {
    New-Item -ItemType Directory -Path $sshDir | Out-Null
    Write-Host "[OK] Diretorio .ssh criado em $sshDir" -ForegroundColor Green
}

# Verificar se ja existe chave SSH
if (Test-Path $sshKeyPath) {
    Write-Host "[!] Chave SSH ja existe em $sshKeyPath" -ForegroundColor Yellow
    $overwrite = Read-Host "Deseja sobrescrever? (s/n)"
    if ($overwrite -ne "s") {
        Write-Host "[OK] Mantendo chave SSH existente." -ForegroundColor Green
        exit 0
    } else {
        Remove-Item $sshKeyPath -Force
        Remove-Item "$sshKeyPath.pub" -Force -ErrorAction SilentlyContinue
        Write-Host "Chave antiga removida." -ForegroundColor Yellow
    }
}

# Gerar nova chave SSH
 $gitEmail = "Morgado0s@users.noreply.github.com"
Write-Host "Gerando nova chave SSH para $gitEmail..." -ForegroundColor Cyan

ssh-keygen -t ed25519 -C "$gitEmail" -f $sshKeyPath -N '""'

if ($?) {
    Write-Host "[OK] Chave SSH gerada com sucesso!" -ForegroundColor Green
} else {
    Write-Host "[X] Erro ao gerar chave SSH." -ForegroundColor Red
    exit 1
}

# Iniciar ssh-agent e adicionar chave
Write-Host "Configurando ssh-agent..." -ForegroundColor Cyan
Start-Service ssh-agent -ErrorAction SilentlyContinue
Set-Service -Name ssh-agent -StartupType Automatic
ssh-add $sshKeyPath

# Copiar chave publica para clipboard
Get-Content "$sshKeyPath.pub" | Set-Clipboard
Write-Host "[OK] Chave publica copiada para area de transferencia!" -ForegroundColor Green
Write-Host ""
Write-Host "IMPORTANTE: Adicione esta chave a sua conta GitHub:" -ForegroundColor Yellow
Write-Host "  Usuario GitHub: Morgado0s" -ForegroundColor Cyan
Write-Host "  Link: https://github.com/settings/keys" -ForegroundColor Cyan
Write-Host "  A chave publica ja esta na area de transferencia (Ctrl+V para colar)." -ForegroundColor Cyan
Write-Host ""
Read-Host "Pressione Enter apos adicionar a chave ao GitHub para finalizar..."