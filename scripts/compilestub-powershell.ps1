# ==============================================================================
# SCRIPT DE GERAÇÃO DE STUBS PARA RENEW (Versão Windows - compilestub.ps1)
# ==============================================================================
# O QUE ESTA SCRIPT FAZ:
# - Encontra a instalação do Renew de forma relativa.
# - Adiciona os ficheiros .jar ao Classpath (usando ';' no Windows).
# - Procura por ficheiros .stub na pasta de trabalho atual.
# - Chama a classe 'de.renew.call.StubCompiler' do Renew.
# ==============================================================================

Write-Host "========================================================" -ForegroundColor Cyan
Write-Host " A GERAR STUBS DO RENEW (compilestub)                   " -ForegroundColor Cyan
Write-Host "========================================================" -ForegroundColor Cyan

# 1. Definir e verificar caminhos
# $PSScriptRoot devolve a pasta onde esta script .ps1 está guardada
$ScriptDir = $PSScriptRoot
$WorkDir = $PWD.Path

# Caminho relativo para a pasta do Renew
$HomeRenewRelPath = "..\renew4.2"
$HomeRenewPath = Join-Path -Path $ScriptDir -ChildPath $HomeRenewRelPath

# Tenta resolver o caminho absoluto para ficar mais limpo
$HomeRenew = $null
if (Test-Path $HomeRenewPath) {
    $HomeRenew = (Resolve-Path $HomeRenewPath).Path
}

# Verifica se a pasta do Renew existe
if ([string]::IsNullOrEmpty($HomeRenew) -or -not (Test-Path -Path $HomeRenew -PathType Container)) {
    Write-Host "[ERRO] Diretoria do Renew não encontrada em: $HomeRenewPath" -ForegroundColor Red
    Write-Host "Verifica se a pasta renew4.2 existe na localização correta." -ForegroundColor Red
    exit 1
}

Write-Host " -> Renew encontrado em: $HomeRenew"
Write-Host " -> Comando Java configurado: java"

# 2. Construir o Classpath (adicionar os .jar necessários)
# No Windows, o separador de Classpath é o ponto e vírgula (;)
$JarPaths = @(
    $HomeRenew,
    (Join-Path $HomeRenew "libs"),
    (Join-Path $HomeRenew "plugins")
)

# Captura todos os .jar e junta-os numa única string
$JarFiles = Get-ChildItem -Path $JarPaths -Filter *.jar -File -ErrorAction SilentlyContinue | Select-Object -ExpandProperty FullName
$CP = $JarFiles -join ";"

# 3. Determinar os ficheiros a compilar
Write-Host "--------------------------------------------------------"

$StubFiles = @()

# Se o utilizador não passou argumentos ($args contém os argumentos)
if ($args.Count -eq 0) {
    Write-Host " -> Nenhum ficheiro especificado. A procurar ficheiros .stub na pasta atual..."
    
    $FoundStubs = Get-ChildItem -Path $WorkDir -Filter *.stub -File -ErrorAction SilentlyContinue | Select-Object -ExpandProperty Name
    
    if ($FoundStubs.Count -eq 0 -or $FoundStubs -eq $null) {
        Write-Host "[AVISO] Não foi encontrado nenhum ficheiro .stub em: $WorkDir" -ForegroundColor Yellow
        Write-Host "[INFO] Podes também passar os ficheiros como argumento:" -ForegroundColor Cyan
        Write-Host "       Exemplo: ..\..\scripts\compilestub.ps1 ficheiro.stub" -ForegroundColor Cyan
        exit 0
    }
    
    $StubFiles = $FoundStubs
    Write-Host " -> Ficheiro(s) encontrado(s): $($StubFiles -join ', ')"
} else {
    # Se o utilizador passou argumentos, usamos esses ficheiros
    Write-Host " -> Ficheiro(s) especificado(s) pelo utilizador: $($args -join ', ')"
    $StubFiles = $args
}

# 4. Executar o Compilador de Stubs do Renew
Write-Host " -> A iniciar compilação..."

# Preparamos os argumentos como um array para chamar o Java de forma segura no PowerShell
$JavaArgs = @("-cp", $CP, "de.renew.call.StubCompiler") + $StubFiles

# O operador & (call operator) é necessário no PowerShell para executar comandos externos
& java $JavaArgs

# Guardar o código de saída do Java
$ExitCode = $LASTEXITCODE

# 5. Verificar o resultado final
Write-Host "--------------------------------------------------------"
if ($ExitCode -eq 0) {
    Write-Host "[SUCESSO] Geração de Stubs terminada sem erros." -ForegroundColor Green
} else {
    Write-Host "[ERRO] Falha ao gerar os Stubs. Verifica a sintaxe, dependências ou a mensagem acima." -ForegroundColor Red
    exit 1
}