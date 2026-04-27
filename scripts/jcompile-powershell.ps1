<#
.SYNOPSIS
SCRIPT DE COMPILAÇÃO JAVA PARA RENEW (Windows PowerShell - jcompile.ps1)
==============================================================================
O QUE ESTA SCRIPT FAZ:
- Encontra a instalação do Renew e adiciona todas as bibliotecas (.jar) 
  necessárias ao Classpath de compilação.
- Resolve automaticamente os caminhos absolutos do Windows.
- Chama o compilador Java (javac) para compilar os teus ficheiros .java.
==============================================================================
#>

Write-Host "========================================================" -ForegroundColor Cyan
Write-Host " A PREPARAR COMPILAÇÃO JAVA (jcompile)                  " -ForegroundColor Cyan
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
# Array que começa com a diretoria atual
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

# 3. Descobrir o compilador Java (javac)
$JavacCmd = "javac"
if ($env:JAVA_HOME) {
    $JavacExe = Join-Path $env:JAVA_HOME "bin\javac.exe"
    if (Test-Path $JavacExe) {
        $JavacCmd = $JavacExe
    }
}

Write-Host "  -> Compilador configurado: $JavacCmd"
Write-Host "--------------------------------------------------------" -ForegroundColor Cyan

# 4. Compilar os ficheiros passados como argumento
# Juntamos os argumentos nativos (-classpath) com os argumentos que o utilizador escreveu ($args)
$JavacArgs = @("-classpath", $CP) + $args

& $JavacCmd $JavacArgs
$ExitCode = $LASTEXITCODE

if ($ExitCode -eq 0) {
    Write-Host "[SUCESSO] Compilação terminada sem erros." -ForegroundColor Green
} else {
    Write-Host "[ERRO] A compilação falhou. Verifica o código Java." -ForegroundColor Red
}

exit $ExitCode