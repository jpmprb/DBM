<#
.SYNOPSIS
SCRIPT DE GERAÇÃO DE STUBS PARA RENEW (Windows PowerShell - compilestub.ps1)
==============================================================================
O QUE ESTA SCRIPT FAZ:
- Encontra a instalação do Renew e constrói o Classpath com os ficheiros .jar.
- Chama a classe interna 'de.renew.call.StubCompiler' para compilar 
  as declarações de rede num formato que o Java compreenda.
==============================================================================
#>

Write-Host "========================================================" -ForegroundColor Cyan
Write-Host " A GERAR STUBS DO RENEW (compilestub)                   " -ForegroundColor Cyan
Write-Host "========================================================" -ForegroundColor Cyan

# 1. Definir e verificar caminhos
$ScriptDir = $PSScriptRoot
$HomeRenewRel = Join-Path $ScriptDir "..\renew4.2"
$HomeRenew = [System.IO.Path]::GetFullPath($HomeRenewRel)

if (-not (Test-Path $HomeRenew)) {
    Write-Host "[ERRO FATAL] Instalação do Renew não encontrada em: $HomeRenew" -ForegroundColor Red
    exit 1
}
Write-Host "  -> Renew encontrado em: $HomeRenew"

# 2. Construir o Classpath (CP)
$CpList = @(".")

if ($env:CLASSPATH) {
    $CpList += $env:CLASSPATH
}

# Procurar todos os JARs na pasta do Renew
$RenewJars = Get-ChildItem -Path $HomeRenew -Filter "*.jar" -Recurse | Select-Object -ExpandProperty FullName
if ($null -ne $RenewJars) {
    $CpList += $RenewJars
}

# Juntar usando ponto e vírgula (separador do Windows)
$CP = $CpList -join ";"

# 3. Descobrir o comando Java (java)
$JavaCmd = "java"
if ($env:JAVA_HOME) {
    $JavaExe = Join-Path $env:JAVA_HOME "bin\java.exe"
    if (Test-Path $JavaExe) {
        $JavaCmd = $JavaExe
    }
}

Write-Host "  -> Comando Java configurado: $JavaCmd"
Write-Host "--------------------------------------------------------" -ForegroundColor Cyan

# 4. Invocar o compilador de stubs do Renew
# Juntamos os argumentos para chamar a classe StubCompiler e o que quer que o utilizador tenha passado ($args)
$JavaArgs = @("-cp", $CP, "de.renew.call.StubCompiler") + $args

& $JavaCmd $JavaArgs
$ExitCode = $LASTEXITCODE

if ($ExitCode -eq 0) {
    Write-Host "[SUCESSO] Geração de Stubs terminada." -ForegroundColor Green
} else {
    Write-Host "[ERRO] Falha ao gerar os Stubs. Verifica a sintaxe ou dependências." -ForegroundColor Red
}

exit $ExitCode