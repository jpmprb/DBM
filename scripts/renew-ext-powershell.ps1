<#
.SYNOPSIS
SCRIPT DE EXECUÇÃO DO RENEW COM CÓDIGO EXTERNO (Versão Windows PowerShell - 4.1)
==============================================================================
COMO USAR:
1. Abre o PowerShell.
2. Navega até à pasta do teu projeto (ex: cd C:\Caminho\Para\02-weather-simple).
3. Executa a script chamando o caminho onde ela está: ..\..\scripts\renew-ext.ps1

O QUE ESTA SCRIPT FAZ:
- Deteta onde o Renew está instalado e a diretoria atual do terminal.
- Protege a visibilidade dos módulos do Java (JPMS).
- Passa o código do teu projeto diretamente para o motor do Renew 
  (usando a propriedade de.renew.classPath) evitando falhas de dependência.
- Carrega ficheiros .rnw e bibliotecas externas (.jar) em conformidade.
==============================================================================
#>

Write-Host "========================================================" -ForegroundColor Cyan
Write-Host " INICIANDO O RENEW 4.2 COM SUPORTE A PROJETOS EXTERNOS  " -ForegroundColor Cyan
Write-Host "========================================================" -ForegroundColor Cyan
Write-Host ""

# ------------------------------------------------------------------------------
# FASE 0: CONFIGURAÇÃO DE PASTAS E CAMINHOS
# ------------------------------------------------------------------------------
Write-Host "[FASE 0] A descobrir a localização das pastas..." -ForegroundColor Yellow

# $PSScriptRoot é a pasta onde esta script (.ps1) está guardada
$ScriptDir = $PSScriptRoot
if ([string]::IsNullOrEmpty($ScriptDir) -or -not (Test-Path $ScriptDir)) {
    Write-Host "[ERRO FATAL] Não foi possível determinar a localização desta script." -ForegroundColor Red
    exit 1
}

# Assumimos que a pasta renew4.2 está ao lado da pasta scripts (..)
$HomeRenewRel = Join-Path $ScriptDir "..\renew4.2"
$HomeRenew = [System.IO.Path]::GetFullPath($HomeRenewRel)

if (-not (Test-Path $HomeRenew)) {
    Write-Host "[ERRO FATAL] A pasta do Renew não foi encontrada em: $HomeRenew" -ForegroundColor Red
    exit 1
}
Write-Host "  -> Instalação do Renew (HOMERENEW): $HomeRenew"

# A pasta do projeto será sempre o local de onde executas o comando ($PWD)
$MyExternalClassesDir = $PWD.Path
if (-not (Test-Path $MyExternalClassesDir)) {
    Write-Host "[ERRO FATAL] Não foi possível ler a pasta atual do terminal." -ForegroundColor Red
    exit 1
}
Write-Host "  -> Pasta do teu Projeto (MY_EXTERNAL_CLASSES_DIR): $MyExternalClassesDir"
Write-Host ""

# ------------------------------------------------------------------------------
# FASE 1: VERIFICAÇÕES DE SEGURANÇA
# ------------------------------------------------------------------------------
Write-Host "[FASE 1] Verificação de segurança aos ficheiros principais..." -ForegroundColor Yellow

$LoaderJar = Join-Path $HomeRenew "de.renew.loader.jar"
if (-not (Test-Path $LoaderJar)) {
    Write-Host "  [ERRO] O ficheiro 'de.renew.loader.jar' não foi encontrado dentro da pasta do Renew!" -ForegroundColor Red
    exit 1
}
Write-Host "  -> Ficheiro Loader do Renew encontrado. OK."
Write-Host ""

# ------------------------------------------------------------------------------
# FASE 2: PREPARAÇÃO DO CLASSPATH INTERNO DO RENEW
# É aqui que indicamos o teu código ao Renew, protegendo-o do Java base.
# ------------------------------------------------------------------------------
Write-Host "[FASE 2] A configurar o Classpath interno do simulador..." -ForegroundColor Yellow

# Inicia a lista com a pasta do projeto
$RenewCustomCpList = @($MyExternalClassesDir)

# Procura todos os ficheiros .jar dentro da pasta do teu projeto
$ProjectJars = Get-ChildItem -Path $MyExternalClassesDir -Filter "*.jar" -Recurse | Select-Object -ExpandProperty FullName
if ($null -ne $ProjectJars) { 
    $RenewCustomCpList += $ProjectJars 
}

# No Windows, as listas de caminhos (Classpath) são separadas por ponto e vírgula (;)
$RenewCustomCp = $RenewCustomCpList -join ";"

Write-Host "  -> Código externo mapeado e pronto a injetar."
Write-Host ""

# ------------------------------------------------------------------------------
# FASE 3: CONSTRUÇÃO DO SYSTEM CLASSPATH E MODULE PATH PARA O JAVA BASE
# Garantimos que o Java apenas carrega o que é absolutamente necessário.
# ------------------------------------------------------------------------------
Write-Host "[FASE 3] A construir as raízes do Sistema Java..." -ForegroundColor Yellow

# O Classpath do sistema fica apenas com as bibliotecas de apoio do Renew (pasta libs)
$SystemCpList = @()
$LibsDir = Join-Path $HomeRenew "libs"
if (Test-Path $LibsDir) {
    $SystemCpJars = Get-ChildItem -Path $LibsDir -Filter "*.jar" -Recurse | Select-Object -ExpandProperty FullName
    if ($null -ne $SystemCpJars) { 
        $SystemCpList += $SystemCpJars 
    }
}
$SystemCp = $SystemCpList -join ";"
if ([string]::IsNullOrWhiteSpace($SystemCp)) { $SystemCp = "." }

# O Module Path regista onde estão os plugins oficiais, MAS NÃO o teu projeto
$ModulePathList = @($HomeRenew)
$LibDir = Join-Path $HomeRenew "lib"

if (Test-Path $LibDir) { $ModulePathList += $LibDir }
if (Test-Path $LibsDir) { $ModulePathList += $LibsDir }

$ModulePath = ($ModulePathList | Select-Object -Unique) -join ";"

Write-Host "  -> Caminhos do sistema Java criados com segurança."
Write-Host ""

# ------------------------------------------------------------------------------
# FASE 4: CONFIGURAÇÃO DO JAVA
# ------------------------------------------------------------------------------
Write-Host "[FASE 4] A validar o ambiente Java instalado..." -ForegroundColor Yellow

$JavaCmd = "java"
if ($env:JAVA_HOME) {
    $JavaExe = Join-Path $env:JAVA_HOME "bin\java.exe"
    if (Test-Path $JavaExe) { 
        $JavaCmd = $JavaExe 
    }
}

try {
    # Tenta capturar a versão para garantir que o Java funciona
    $JavaVersionOutput = & $JavaCmd -version 2>&1
    Write-Host "  -> Executável do Java localizado. OK."
} catch {
    Write-Host "  [ERRO] O comando 'java' não foi reconhecido. Verifica se o Java está instalado e na variável PATH." -ForegroundColor Red
    exit 1
}
Write-Host ""

# ------------------------------------------------------------------------------
# FASE 5: PREPARAÇÃO PARA O ARRANQUE (RENEW)
# ------------------------------------------------------------------------------
Write-Host "[FASE 5] A arrancar o motor do Renew..." -ForegroundColor Yellow

# Procura ficheiros .rnw apenas na pasta principal do projeto
$RnwFiles = Get-ChildItem -Path $MyExternalClassesDir -Filter "*.rnw" -File | Select-Object -ExpandProperty FullName

if ($null -ne $RnwFiles -and $RnwFiles.Count -gt 0) {
    Write-Host "  -> Ficheiros .rnw detetados na pasta atual. Vão ser abertos automaticamente."
} else {
    Write-Host "  -> Nenhum ficheiro .rnw detetado. A abrir ambiente de trabalho limpo."
}

# Constrói a lista de argumentos para chamar o Java
# O PowerShell lida automaticamente com os espaços nos caminhos quando usamos Arrays (@).
$JavaArgs = @(
    "--add-modules", "java.net.http",
    "-Xmx512M",
    "-Dde.renew.netPath=$MyExternalClassesDir",
    "-Dde.renew.classPath=$RenewCustomCp",
    "-classpath", $SystemCp,
    "-p", $ModulePath,
    "-m", "de.renew.loader/de.renew.plugin.PluginManager",
    "gui"
)

# Adiciona as Redes de Petri ao final, se existirem
if ($null -ne $RnwFiles) { 
    $JavaArgs += $RnwFiles 
}

# Se o utilizador tiver passado argumentos extra na linha de comandos, adiciona-os
if ($args.Count -gt 0) { 
    $JavaArgs += $args 
}

Write-Host "--------------------------------------------------------" -ForegroundColor Cyan
Write-Host " A EXECUTAR O RENEW... (A interface gráfica vai abrir)" -ForegroundColor Cyan
Write-Host "--------------------------------------------------------" -ForegroundColor Cyan

# O símbolo '&' em PowerShell executa o comando passando-lhe a Array de argumentos
& $JavaCmd $JavaArgs
$ExitCode = $LASTEXITCODE

Write-Host ""
Write-Host "[FIM] O Renew foi encerrado (Código de saída: $ExitCode)." -ForegroundColor Green
exit $ExitCode