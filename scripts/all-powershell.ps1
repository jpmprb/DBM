# Para a execução caso ocorra algum erro
$ErrorActionPreference = "Stop"

Write-Host "A iniciar a execução no Windows 11..." -ForegroundColor Cyan

Write-Host "-> A executar compilestub-powershell..."
& "$PSScriptRoot\compilestub-powershell.ps1"

Write-Host "-> A executar jcompile-powershell..."
& "$PSScriptRoot\jcompile-powershell.ps1"

Write-Host "-> A executar renew-ext-powershell..."
& "$PSScriptRoot\renew-ext-powershell.ps1"

Write-Host "Todas as scripts foram executadas com sucesso!" -ForegroundColor Green
