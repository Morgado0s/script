#Requires -RunAsAdministrator
# Script principal para executar todos os scripts de automacao em sequencia.
# Coloque este arquivo na mesma pasta que os outros 4 scripts.

Write-Host "=== Iniciando Configuracao Automatica Completa ===" -ForegroundColor Cyan
Write-Host "Este script executara todas as etapas de configuracao."
Write-Host ""

 $scripts = @(
    ".\1-Setup-SSH-Git.ps1",
    ".\2-Install-Node-Claude.ps1",
    ".\3-Install-Python.ps1",
    ".\4-Setup-Environment-Variables.ps1"
)

foreach ($script in $scripts) {
    if (Test-Path $script) {
        Write-Host "-----------------------------------------------------" -ForegroundColor DarkGray
        Write-Host "Executando $script..." -ForegroundColor Yellow
        Write-Host "-----------------------------------------------------" -ForegroundColor DarkGray
        try {
            & $script
            Write-Host "[OK] $script concluido com sucesso." -ForegroundColor Green
        } catch {
            Write-Host "[X] Erro ao executar $script. Abortando." -ForegroundColor Red
            Write-Host "Erro: $($_.Exception.Message)" -ForegroundColor DarkRed
            # Interrompe a execucao se um script falhar
            exit 1
        }
    } else {
        Write-Host "[X] Script nao encontrado: $script. Verifique se todos os arquivos estao na mesma pasta." -ForegroundColor Red
        exit 1
    }
    Write-Host ""
}

Write-Host "=====================================================" -ForegroundColor Green
Write-Host "=== Configuracao Concluida com Sucesso! ===" -ForegroundColor Green
Write-Host "=====================================================" -ForegroundColor Green
Write-Host ""
Write-Host "IMPORTANTE: **REINICIE O TERMINAL** para carregar todas as variaveis de ambiente." -ForegroundColor Yellow
Write-Host ""
Write-Host "Proximos passos:" -ForegroundColor Cyan
Write-Host "  1. Teste a chave SSH: ssh -T git@github.com" -ForegroundColor White
Write-Host "  2. Execute o Claude Code: claude" -ForegroundColor White
Write-Host "  3. Verifique as versoes: node -v e python --version" -ForegroundColor White
Write-Host ""
Read-Host "Pressione Enter para sair"