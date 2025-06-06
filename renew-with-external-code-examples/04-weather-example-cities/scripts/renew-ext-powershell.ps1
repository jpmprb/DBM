#Requires -Version 5.1
# ==============================================================================
# Script to run Renew with external classes and specific .rnw files (PowerShell)
# Version: 1.0
# Purpose: This script configures the Java environment and launches the
#          Renew application, including user-specified external JARs and
#          automatically opening .rnw files. HOMERENEW and
#          MY_EXTERNAL_CLASSES_DIR are resolved relative to the script's location.
#
# Key Features:
# - Automatically detects Renew home and external class directories relative
#   to this script's location.
# - Constructs Classpath (CP) and Module Path (MP) including Renew's internal
#   JARs and user-provided external JARs using absolute paths.
# - Requires Java 11 or newer due to the use of java.net.http.HttpClient.
# - Includes diagnostics for Java version and critical class presence.
# - Explicitly adds the java.net.http module for compatibility.
# ==============================================================================
param() # Makes this a script that can accept $Args

# --- Helper: Write Message with Color ---
function Write-Message {
    param(
        [string]$Message,
        [string]$Type = "INFO" # INFO, ERROR, WARNING, DEBUG, CHECK, OK, EXEC
    )
    $color = switch ($Type.ToUpper()) {
        "INFO"    { "Green" }
        "ERROR"   { "Red" }
        "WARNING" { "Yellow" }
        "DEBUG"   { "Cyan" }
        "CHECK"   { "Magenta" }
        "OK"      { "Green" }
        "EXEC"    { "Blue" }
        default   { "White" }
    }
    Write-Host $Message -ForegroundColor $color
}

# --- Configuration ---
Write-Message "[CONFIG] Initializing script configuration..." -Type INFO

# Determine the absolute directory where this script is located.
# $PSScriptRoot is an automatic variable containing the script's directory.
$SCRIPT_DIR = $PSScriptRoot
if (-not (Test-Path $SCRIPT_DIR -PathType Container)) {
    Write-Message "[CONFIG FATAL] Could not determine the script's own directory: $SCRIPT_DIR. Exiting." -Type ERROR
    exit 1
}
Write-Message "  [INFO] Script directory (SCRIPT_DIR) resolved to: $SCRIPT_DIR" -Type INFO

# Define the Renew home directory.
# Path is relative to this script's own location.
$_HOMERENEW_REL_PATH = "..\..\renew4.1base" # Equivalent to ../../renew4.1base
$_CANDIDATE_HOMERENEW_ABS_PATH = Join-Path -Path $SCRIPT_DIR -ChildPath $_HOMERENEW_REL_PATH

try {
    $HOMERENEW = Resolve-Path -LiteralPath $_CANDIDATE_HOMERENEW_ABS_PATH -ErrorAction Stop | Select-Object -ExpandProperty Path
} catch {
    $HOMERENEW = $null # Ensure it's null if Resolve-Path failed
}

if (-not $HOMERENEW -or -not (Test-Path $HOMERENEW -PathType Container)) {
    Write-Message "[CONFIG FATAL] Could not resolve Renew home directory (HOMERENEW)." -Type ERROR
    Write-Message "  Script location (SCRIPT_DIR):       '$SCRIPT_DIR'" -Type DEBUG
    Write-Message "  Configured relative path to Renew:  '$_HOMERENEW_REL_PATH'" -Type DEBUG
    Write-Message "  Attempted to find Renew at:         '$_CANDIDATE_HOMERENEW_ABS_PATH'" -Type DEBUG
    Write-Message "  This path does not resolve to a valid directory." -Type ERROR
    Write-Message "  Please ensure the directory exists at this location relative to the script." -Type ERROR
    exit 1
}
Write-Message "  [INFO] Renew home (HOMERENEW) resolved to: $HOMERENEW" -Type INFO

# Define MY_EXTERNAL_CLASSES_DIR as the parent directory of this script's location.
$_CANDIDATE_MY_EXT_CLASSES_ABS_PATH = Join-Path -Path $SCRIPT_DIR -ChildPath ".."
try {
    $MY_EXTERNAL_CLASSES_DIR = Resolve-Path -LiteralPath $_CANDIDATE_MY_EXT_CLASSES_ABS_PATH -ErrorAction Stop | Select-Object -ExpandProperty Path
} catch {
    $MY_EXTERNAL_CLASSES_DIR = $null
}

if (-not $MY_EXTERNAL_CLASSES_DIR -or -not (Test-Path $MY_EXTERNAL_CLASSES_DIR -PathType Container)) {
    Write-Message "[CONFIG FATAL] Could not resolve external classes directory (MY_EXTERNAL_CLASSES_DIR)." -Type ERROR
    Write-Message "  Script location (SCRIPT_DIR):          '$SCRIPT_DIR'" -Type DEBUG
    Write-Message "  Attempted to find external classes at: '$_CANDIDATE_MY_EXT_CLASSES_ABS_PATH' (parent of script dir)" -Type DEBUG
    Write-Message "  This path does not resolve to a valid directory." -Type ERROR
    exit 1
}
Write-Message "  [INFO] External classes (MY_EXTERNAL_CLASSES_DIR) resolved to: $MY_EXTERNAL_CLASSES_DIR" -Type INFO

# Define the fully qualified name of a custom class to check for diagnostic purposes.
$CUSTOM_CLASS_TO_CHECK = "pt.ipbeja.weather.WeatherDataReader"
# Convert Java package dot notation to path slash notation for searching in JARs.
$CUSTOM_CLASS_PATH_TO_CHECK = ($CUSTOM_CLASS_TO_CHECK -replace '\.', '/') + ".class"
Write-Message "[CONFIG] Initialization complete." -Type OK
Write-Host ""


# --- Helper Functions ---

# Function: Collect-JarsFromDir
# Description: Finds all .jar files within a given directory (and its subdirectories)
#              and returns them as a semicolon-separated string.
function Collect-JarsFromDir {
    param(
        [string]$SearchDir
    )
    $collectedJarsList = [System.Collections.Generic.List[string]]::new()
    $foundCount = 0

    if (-not (Test-Path $SearchDir -PathType Container)) {
        Write-Message "    [DEBUG] Collect-JarsFromDir: Directory '$SearchDir' not found. Skipping." -Type DEBUG
        return "" # Return empty string
    }

    Write-Message "    [DEBUG] Collect-JarsFromDir: Searching for JARs in '$SearchDir'..." -Type DEBUG
    Get-ChildItem -Path $SearchDir -Filter "*.jar" -Recurse -File | ForEach-Object {
        $collectedJarsList.Add($_.FullName)
        $foundCount++
    }

    Write-Message "    [INFO] Found $foundCount JAR(s) in '$SearchDir'." -Type INFO
    return $collectedJarsList -join ";"
}

# Function: Clean-PathString
# Description: Cleans a semicolon-separated path string.
function Clean-PathString {
    param(
        [string]$PathString
    )
    $cleaned = $PathString -replace '^;+|;+$', ''  # Remove leading/trailing semicolons
    $cleaned = $cleaned -replace ';{2,}', ';'      # Replace multiple semicolons with one
    if ([string]::IsNullOrEmpty($cleaned)) {
        return "."
    }
    return $cleaned
}

# Function: Check-ClassInJars
# Description: Searches for a specific .class file entry within .jar files.
# Requires jar.exe to be in PATH or $PathToJarExe to be set.
$PathToJarExe = "jar.exe" # Assume in PATH, or set explicitly e.g., Join-Path $JAVA_HOME "bin\jar.exe"

function Check-ClassInJars {
    param(
        [string]$SearchDir,
        [string]$ClassPath, # e.g., "java/lang/String.class"
        [string]$ClassDesc
    )
    $classActuallyFound = $false

    Write-Message "  [CHECK] Searching for '$ClassDesc' ($ClassPath) in JARs under '$SearchDir'..." -Type CHECK
    if (-not (Test-Path $SearchDir -PathType Container)) {
        Write-Message "    [ERROR] Directory '$SearchDir' not found for class check." -Type ERROR
        return $false
    }

    Get-ChildItem -Path $SearchDir -Filter "*.jar" -Recurse -File | ForEach-Object {
        $jarFile = $_.FullName
        try {
            # Capture output (stdout and stderr) from jar.exe
            $jarContents = & $PathToJarExe tf $jarFile 2>&1
            if ($LASTEXITCODE -ne 0 -and -not $jarContents) { # Check if jar command itself failed silently
                 Write-Message "    [WARN] 'jar tf $jarFile' command might have failed or produced no output. Exit code: $LASTEXITCODE" -Type WARNING
            }

            # Search for the exact class path in the output
            # The regex ensures it matches the full line, using '/' as separator.
            if ($jarContents -match "(?m)^$([regex]::Escape($ClassPath))$") {
                Write-Message "    [FOUND] '$ClassDesc' in JAR: $jarFile" -Type OK
                $script:classActuallyFound = $true # Set script-level flag
                # Could 'break' here if only one instance needs to be found
            }
        } catch {
            Write-Message "    [WARN] Error processing JAR '$jarFile': $($_.Exception.Message)" -Type WARNING
        }
    }

    if (-not $script:classActuallyFound) {
        Write-Message "    [NOT FOUND] '$ClassDesc' ($ClassPath) was not found in any JAR under '$SearchDir'." -Type WARNING
        return $false
    }
    return $true
}
Write-Host ""

# --- Phase 1: Initial Sanity Checks ---
Write-Message "[PHASE 1] Initial Sanity Checks..." -Type INFO

$renewLoaderJarPath = Join-Path $HOMERENEW "de.renew.loader.jar"
if (-not (Test-Path $renewLoaderJarPath -PathType Leaf)) {
    Write-Message "  [ERROR] Renew loader.jar not found or not readable at '$renewLoaderJarPath'!" -Type ERROR
    Write-Message "  The HOMERENEW directory itself ('$HOMERENEW') was found, but 'de.renew.loader.jar' is missing or unreadable inside it." -Type ERROR
    exit 1
}
Write-Message "  [OK] Renew loader.jar found and readable in '$HOMERENEW'." -Type OK

Write-Message "  [INFO] External classes directory '$MY_EXTERNAL_CLASSES_DIR' was successfully resolved." -Type INFO
Write-Message "  Contents of MY_EXTERNAL_CLASSES_DIR (your project files):" -Type INFO
Get-ChildItem -Path $MY_EXTERNAL_CLASSES_DIR | Format-Table -AutoSize
Write-Host ""


# --- Phase 2: Classpath (CP) Construction ---
Write-Message "[PHASE 2] Constructing Classpath (CP)..." -Type INFO
$cpBaseDirsList = [System.Collections.Generic.List[string]]::new()
$cpBaseDirsList.Add($HOMERENEW) # HOMERENEW is absolute

$renewLibPath = Join-Path $HOMERENEW "lib"
if (Test-Path $renewLibPath -PathType Container) {
    $cpBaseDirsList.Add($renewLibPath)
}

$renewLibsPath = Join-Path $HOMERENEW "libs"
if (Test-Path $renewLibsPath -PathType Container) {
    $isLibsDifferentFromLib = $true
    if ((Test-Path $renewLibPath -PathType Container) -and `
        ((Resolve-Path $renewLibPath).Path -eq (Resolve-Path $renewLibsPath).Path)) {
        $isLibsDifferentFromLib = $false
    }
    if ($isLibsDifferentFromLib) {
        $cpBaseDirsList.Add($renewLibsPath)
    }
}
$cpBaseDirsList.Add($MY_EXTERNAL_CLASSES_DIR) # MY_EXTERNAL_CLASSES_DIR is absolute

Write-Message "  Collecting JARs for Classpath..." -Type DEBUG
$homerenewJars = Collect-JarsFromDir -SearchDir $HOMERENEW
$myExternalJars = Collect-JarsFromDir -SearchDir $MY_EXTERNAL_CLASSES_DIR

$cpList = [System.Collections.Generic.List[string]]::new()
$cpList.AddRange($cpBaseDirsList)
if (-not [string]::IsNullOrEmpty($homerenewJars)) { $cpList.Add($homerenewJars) }
if (-not [string]::IsNullOrEmpty($myExternalJars)) { $cpList.Add($myExternalJars) }

$CP = Clean-PathString -PathString ($cpList -join ";")
Write-Message "  [OK] Final Classpath (CP): $CP" -Type OK
Write-Host ""


# --- Phase 3: Module Path (MODULE_PATH) Construction ---
Write-Message "[PHASE 3] Constructing Module Path (MODULE_PATH)..." -Type INFO
$modulePathDirsList = [System.Collections.Generic.List[string]]::new()
$modulePathDirsList.Add($HOMERENEW)

if (Test-Path $renewLibPath -PathType Container) {
    $modulePathDirsList.Add($renewLibPath)
}

if (Test-Path $renewLibsPath -PathType Container) {
    $isLibsDifferentMp = $true
    $resolvedLibsPath = (Resolve-Path $renewLibsPath).Path
    if ((Test-Path $renewLibPath -PathType Container) -and `
        ((Resolve-Path $renewLibPath).Path -eq $resolvedLibsPath)) {
        $isLibsDifferentMp = $false
    }

    $isAlreadyPresent = $false
    $modulePathDirsList | ForEach-Object {
        if ((Test-Path $_ -PathType Container) -and ((Resolve-Path $_).Path -eq $resolvedLibsPath)) {
            $script:isAlreadyPresent = $true # Using script scope for flag
        }
    }
    if ($isLibsDifferentMp -and (-not $script:isAlreadyPresent)) {
        $modulePathDirsList.Add($renewLibsPath)
    }
}

$isMyExternalAlreadyPresent = $false
$modulePathDirsList | ForEach-Object {
    if ((Test-Path $_ -PathType Container) -and ((Resolve-Path $_).Path -eq $MY_EXTERNAL_CLASSES_DIR)) {
        $script:isMyExternalAlreadyPresent = $true
    }
}
if (-not $script:isMyExternalAlreadyPresent) {
    $modulePathDirsList.Add($MY_EXTERNAL_CLASSES_DIR)
}

$MODULE_PATH = Clean-PathString -PathString ($modulePathDirsList -join ";")
Write-Message "  [OK] Final Module Path: $MODULE_PATH" -Type OK
Write-Host ""


# --- Phase 4: Java Command Setup ---
Write-Message "[PHASE 4] Setting up Java Command..." -Type INFO
$JAVACMD = "java.exe" # Default
$PathToJarExe = "jar.exe" # Default for jar.exe

if ($env:JAVA_HOME -and (Test-Path (Join-Path $env:JAVA_HOME "bin\java.exe") -PathType Leaf)) {
    $JAVACMD = Join-Path $env:JAVA_HOME "bin\java.exe"
    $PathToJarExe = Join-Path $env:JAVA_HOME "bin\jar.exe"
    Write-Message "  [INFO] Using Java from JAVA_HOME: $JAVACMD" -Type INFO
} else {
    Write-Message "  [INFO] Using Java from system PATH: $JAVACMD (JAVA_HOME not set or its 'bin\java.exe' not found/executable)" -Type INFO
    Write-Message "  [INFO] To use a specific Java version (11+ recommended), set the JAVA_HOME environment variable." -Type INFO
}
# Update PathToJarExe if JAVACMD was found in PATH, assuming jar.exe is also in PATH
if ($JAVACMD -eq "java.exe" -and $PathToJarExe -ne (Join-Path $env:JAVA_HOME "bin\jar.exe")) {
     # Check if jar.exe is in path
    if (-not (Get-Command "jar.exe" -ErrorAction SilentlyContinue)) {
        Write-Message "  [WARNING] jar.exe not found in PATH and JAVA_HOME not set to a JDK. Class checking might fail." -Type WARNING
    }
}


Write-Message "  [INFO] Checking Java version..." -Type INFO
$javaVersionOutput = ""
try {
    # Capturing output from external commands, especially stderr, can be tricky.
    # This approach attempts to get stderr which is where `java -version` often writes.
    $pinfo = New-Object System.Diagnostics.ProcessStartInfo
    $pinfo.FileName = $JAVACMD
    $pinfo.RedirectStandardError = $true
    $pinfo.RedirectStandardOutput = $true # Capture stdout too, just in case
    $pinfo.UseShellExecute = $false
    $pinfo.CreateNoWindow = $true
    $pinfo.Arguments = "-version"
    $p = New-Object System.Diagnostics.Process
    $p.StartInfo = $pinfo
    $p.Start() | Out-Null
    $stdoutVersion = $p.StandardOutput.ReadToEnd()
    $stderrVersion = $p.StandardError.ReadToEnd()
    $p.WaitForExit()
    $javaVersionOutput = $stderrVersion + $stdoutVersion # Combine, typically version is on stderr
} catch {
    Write-Message "    [ERROR] Failed to execute '$JAVACMD -version': $($_.Exception.Message)" -Type ERROR
}

if (-not [string]::IsNullOrWhiteSpace($javaVersionOutput)) {
    Write-Message "    ----- Java Version Output -----" -Type DEBUG
    $javaVersionOutput.Split([Environment]::NewLine) | ForEach-Object { Write-Message "    $_" -Type DEBUG }
    Write-Message "    -----------------------------" -Type DEBUG

    if ($javaVersionOutput -match 'version "(1\.[1-8]|[9]|10)\.') { # Matches "1.8", "9.x.y", "10.x.y"
        Write-Message "    [WARNING] Detected Java version older than 11. Java 11 or newer is required for java.net.http.HttpClient." -Type WARNING
        Write-Message "    [WARNING] Please set JAVA_HOME to a JDK 11+ installation or update your system's default Java." -Type WARNING
    } elseif ($javaVersionOutput -match 'version "(1[1-9]|[2-9]\d*)') { # Matches "11", "17.0.1", "21" etc.
        Write-Message "    [INFO] Java version appears to be 11 or newer. This should be compatible." -Type INFO
    } else {
        Write-Message "    [WARNING] Could not definitively determine if Java version is 11+ or older from the output." -Type WARNING
        Write-Message "    [WARNING] The script will proceed, but if 'java.net.http.HttpClient' related errors occur," -Type WARNING
        Write-Message "    [WARNING] please ensure you are using Java 11 or a newer version." -Type WARNING
    }
} else {
    Write-Message "    [ERROR] Could not determine Java version using '$JAVACMD -version'. No output received." -Type ERROR
    Write-Message "    [ERROR] Please ensure Java (11+ recommended) is installed and in your PATH or JAVA_HOME is set correctly." -Type ERROR
}
Write-Host ""


# --- Phase 5: Pre-flight Diagnostics ---
Write-Message "[PHASE 5] Pre-flight Diagnostics..." -Type INFO
Write-Message "  Configuration Summary:" -Type DEBUG
Write-Message "    HOMERENEW (Renew Installation): $HOMERENEW" -Type DEBUG
Write-Message "    MY_EXTERNAL_CLASSES_DIR (Your Project): $MY_EXTERNAL_CLASSES_DIR" -Type DEBUG
Write-Message "    Renew's 'de.renew.netPath' property will be set to: $MY_EXTERNAL_CLASSES_DIR" -Type DEBUG
Write-Message "    Script arguments received by this script: $($Args -join ' ')" -Type DEBUG
Write-Host ""

Write-Message "  Classpath & Module Path Verification:" -Type DEBUG
Write-Message "    Final Classpath (CP) that will be used by Java:" -Type DEBUG
Write-Message "      $CP" -Type DEBUG
Write-Message "    Final Module Path (MODULE_PATH) that will be used by Java:" -Type DEBUG
Write-Message "      $MODULE_PATH" -Type DEBUG
Write-Host ""

Write-Message "  Critical Class Presence Checks:" -Type INFO
# Reset script-level flags for Check-ClassInJars
$script:classActuallyFound = $false
$renewCoreClassFound = Check-ClassInJars -SearchDir $HOMERENEW -ClassPath "de/renew/net/NetInstanceImpl.class" -ClassDesc "Renew Core (NetInstanceImpl)"

$script:classActuallyFound = $false # Reset for next call
$customClassFound = Check-ClassInJars -SearchDir $MY_EXTERNAL_CLASSES_DIR -ClassPath $CUSTOM_CLASS_PATH_TO_CHECK -ClassDesc "Custom Class ($CUSTOM_CLASS_TO_CHECK)"

if (-not $renewCoreClassFound) {
    Write-Message "  [CRITICAL ERROR] Renew core class 'de.renew.net.NetInstanceImpl' was NOT FOUND in HOMERENEW JARs." -Type ERROR
    Write-Message "  This will likely cause a NoClassDefFoundError. Please check your Renew installation at $HOMERENEW." -Type ERROR
}
if (-not $customClassFound) {
    Write-Message "  [CRITICAL WARNING] Your custom class '$CUSTOM_CLASS_TO_CHECK' was NOT FOUND in any JAR under '$MY_EXTERNAL_CLASSES_DIR'." -Type WARNING
    Write-Message "  This will likely cause a 'No such class' or 'ClassNotFoundException' error from Renew." -Type WARNING
    Write-Message "  Verify your JAR is correctly built, contains the class with the correct package structure, and is placed in '$MY_EXTERNAL_CLASSES_DIR'." -Type WARNING
}
Write-Host ""


# --- Phase 6: Renew Execution ---
Write-Message "[PHASE 6] Preparing to Launch Renew..." -Type INFO

$foundRnwFilesInParentDir = $false
$rnwFilesToOpen = @()
if (Get-ChildItem -Path $MY_EXTERNAL_CLASSES_DIR -Filter "*.rnw" -File -ErrorAction SilentlyContinue | Select-Object -First 1) {
    $foundRnwFilesInParentDir = $true
    $rnwFilesToOpen = (Get-ChildItem -Path $MY_EXTERNAL_CLASSES_DIR -Filter "*.rnw" -File).FullName
    Write-Message "  [INFO] Found .rnw files in '$MY_EXTERNAL_CLASSES_DIR'. They will be passed to Renew: $($rnwFilesToOpen -join ', ')" -Type INFO
} else {
    Write-Message "  [INFO] No .rnw files found directly in '$MY_EXTERNAL_CLASSES_DIR'. Renew will start without opening specific files from there initially (unless passed as arguments to this script)." -Type INFO
}

# Arguments for Java command. Each element is a separate argument.
$javaArgs = [System.Collections.Generic.List[string]]::new()
$javaArgs.Add("--add-modules")
$javaArgs.Add("java.net.http")
$javaArgs.Add("-Xmx512M")
$javaArgs.Add("-Dde.renew.netPath=""$MY_EXTERNAL_CLASSES_DIR""") # Quotes inside for value if it has spaces
$javaArgs.Add("-classpath")
$javaArgs.Add($CP) # $CP is already a string like "path1;path2"
$javaArgs.Add("-p")
$javaArgs.Add($MODULE_PATH) # $MODULE_PATH is similar
$javaArgs.Add("-m")
$javaArgs.Add("de.renew.loader/de.renew.plugin.PluginManager")
$javaArgs.Add("gui")

if ($foundRnwFilesInParentDir) {
    $javaArgs.AddRange($rnwFilesToOpen)
}

# Add script arguments ($Args)
if ($Args.Count -gt 0) {
    $javaArgs.AddRange($Args)
}

Write-Message "  [EXEC] Launching Renew. Command structure (placeholders for long paths):" -Type EXEC
Write-Message "    $JAVACMD [JVM_OPTIONS] -Dde.renew.netPath=`"...`" -classpath [CP] -p [MP] -m de.renew.loader/... gui [RNW_FILES] [SCRIPT_ARGS]" -Type DEBUG
Write-Message "    (Actual paths are absolute and printed in Phase 5 diagnostics if needed.)" -Type DEBUG

Write-Message "  [DEBUG] Full command to be executed (arguments will be passed separately):" -Type DEBUG
Write-Message "    Executable: $JAVACMD" -Type DEBUG
Write-Message "    Arguments : $($javaArgs -join ' ')" -Type DEBUG # For display purposes

try {
    # Using Start-Process for better control over execution and argument passing
    $process = Start-Process -FilePath $JAVACMD -ArgumentList $javaArgs -Wait -NoNewWindow -PassThru
    $renewExitCode = $process.ExitCode
} catch {
    Write-Message "  [ERROR] Failed to start Renew process: $($_.Exception.Message)" -Type ERROR
    $renewExitCode = -1 # Indicate failure
}
Write-Host ""

# --- Phase 7: Renew Execution Finished ---
Write-Message "[PHASE 7] Renew execution finished with exit code $renewExitCode." -Type INFO
exit $renewExitCode
