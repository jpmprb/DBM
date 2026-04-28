# ==============================================================================
# SCRIPT DE COMPILAÇÃO JAVA PARA RENEW (Versão Windows com JARs Locais - jcompile.ps1)
# ==============================================================================
# O QUE ESTA SCRIPT FAZ:
# - Encontra a instalação do Renew e adiciona as suas bibliotecas ao Classpath.
# - Procura e adiciona quaisquer ficheiros .jar na pasta de projeto atual 
#   (e em subpastas como 'libs') ao Classpath de compilação.
# - Protege contra caminhos e nomes de ficheiros com espaços.
# - Se não forem passados argumentos, procura automaticamente todos os ficheiros
#   .java na pasta onde é chamada e em todas as suas subpastas.
# - Chama o compilador Java (javac) para compilar os ficheiros encontrados.
# ==============================================================================

Write-Host "========================================================" -ForegroundColor Cyan
Write-Host " A PREPARAR COMPILAÇÃO JAVA (jcompile)                  " -ForegroundColor Cyan
Write-Host "========================================================" -ForegroundColor Cyan

# 1. Definir e verificar caminhos
$ScriptDir = $PSScriptRoot
$WorkDir = $PWD.Path

Write-Host " -> A verificar instalação do Renew..."

# Caminho relativo para a pasta do Renew
$HomeRenewRelPath = "..\renew4.2"
$HomeRenewPath = Join-Path -Path $ScriptDir -ChildPath $HomeRenewRelPath

# Tenta resolver o caminho absoluto
$HomeRenew = $null
if (Test-Path $HomeRenewPath) {
    $HomeRenew = (Resolve-Path $HomeRenewPath).Path
}

if ([string]::IsNullOrEmpty($HomeRenew) -or -not (Test-Path -Path $HomeRenew -PathType Container)) {
    Write-Host "[ERRO FATAL] Instalação do Renew não encontrada em: $HomeRenewPath" -ForegroundColor Red
    exit 1
}

Write-Host " -> Renew encontrado em: $HomeRenew"

# 2. Construir o Classpath (CP) de compilação de forma segura
Write-Host " -> A carregar bibliotecas (.jar) do Renew para o Classpath..."

# Usamos um array para ir guardando os caminhos limpos
$CpList = @(".")
if ($env:CLASSPATH) {
    $CpList += $env:CLASSPATH
}

# Procurar todos os JARs do Renew (recursivo)
$RenewJars = Get-ChildItem -Path $HomeRenew -Filter *.jar -Recurse -File -ErrorAction SilentlyContinue | Select-Object -ExpandProperty FullName
if ($RenewJars) {
    $CpList += $RenewJars
}

# Procurar todos os JARs na pasta do projeto atual e suas subpastas (ex: libs/)
Write-Host " -> A procurar bibliotecas (.jar) locais no projeto atual..."
$LocalJars = Get-ChildItem -Path $WorkDir -Filter *.jar -Recurse -File -ErrorAction SilentlyContinue | Select-Object -ExpandProperty FullName

if ($LocalJars) {
    # Garante que é tratado como array para contar corretamente
    $LocalJarsArray = @($LocalJars)
    Write-Host "    Encontrada(s) $($LocalJarsArray.Count) biblioteca(s) local/locais adicionada(s) ao Classpath."
    $CpList += $LocalJarsArray
}

# Unir tudo com ponto e vírgula (o separador do Windows para o Classpath)
$CP = $CpList -join ";"

# 3. Descobrir o compilador Java (javac)
$JavacCmd = "javac"
if ($env:JAVA_HOME) {
    $JavacTest = Join-Path $env:JAVA_HOME "bin\javac.exe"
    if (Test-Path $JavacTest) {
        $JavacCmd = $JavacTest
    }
}

Write-Host " -> Compilador configurado: $JavacCmd"
Write-Host "--------------------------------------------------------"

# 4. Determinar quais os ficheiros .java a compilar
$JavaFiles = @()

# Se não foram passados ficheiros como argumento ($args.Count é 0)
if ($args.Count -eq 0) {
    Write-Host " -> A procurar ficheiros .java na pasta atual e em todas as subpastas..."
    
    # O '-Recurse' procura em todas as subpastas a partir da pasta atual
    $FoundJavaFiles = Get-ChildItem -Path $WorkDir -Filter *.java -Recurse -File -ErrorAction SilentlyContinue | Select-Object -ExpandProperty FullName

    if ($null -eq $FoundJavaFiles -or $FoundJavaFiles.Count -eq 0) {
        Write-Host "[AVISO] Não foi encontrado nenhum ficheiro .java na pasta: $WorkDir" -ForegroundColor Yellow
        Write-Host "[INFO] A compilação foi cancelada porque não há código fonte." -ForegroundColor Cyan
        exit 0
    }
    
    $JavaFiles = @($FoundJavaFiles)
    Write-Host " -> Encontrado(s) $($JavaFiles.Count) ficheiro(s) .java para compilar."
} else {
    # Se o utilizador passou argumentos (ex: ..\..\scripts\jcompile.ps1 Ficheiro.java)
    Write-Host " -> A utilizar o(s) ficheiro(s) especificado(s) pelo utilizador:"
    Write-Host "    $($args -join ' ')"
    $JavaFiles = $args
}

# 5. Executar a compilação
Write-Host " -> A iniciar compilação..."

# Prepara os argumentos com o classpath e os ficheiros
$JavacArgs = @("-classpath", $CP) + $JavaFiles

# Executa o compilador
& $JavacCmd $JavacArgs
$ExitCode = $LASTEXITCODE

# 6. Avaliar o resultado final
Write-Host "--------------------------------------------------------"
if ($ExitCode -eq 0) {
    Write-Host "[SUCESSO] Compilação terminada sem erros. Os teus ficheiros .class estão prontos." -ForegroundColor Green
} else {
    Write-Host "[ERRO] A compilação falhou. Verifica os erros de sintaxe no teu código Java apresentados acima." -ForegroundColor Red
    exit $ExitCode
}