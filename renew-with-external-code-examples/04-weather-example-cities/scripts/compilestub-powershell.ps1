#Requires -Version 5.1

# Define the base directory using a relative path
$BaseDirRelative = "..\..\renew4.1base" # Using .. for parent directory in Windows

# Get the absolute, canonical path of the script's directory
# $PSScriptRoot is an automatic variable containing the directory of the script.
# Resolve-Path ensures we get the canonical path, resolving any symbolic links.
$ScriptDirAbs = (Resolve-Path -LiteralPath $PSScriptRoot).Path

# Construct the absolute path for renew4.1base
$RenewBaseAbsUnresolved = Join-Path -Path $ScriptDirAbs -ChildPath $BaseDirRelative

# Verify the renew4.1base directory exists and then get its canonical path
if (-not (Test-Path -LiteralPath $RenewBaseAbsUnresolved -PathType Container)) {
    Write-Error "Error: The base directory for Renew does not exist at '$RenewBaseAbsUnresolved'."
    Write-Error "Please check the RENEW_BASE_RELATIVE path in the script or your directory structure."
    exit 1
}
$RenewBaseAbs = (Resolve-Path -LiteralPath $RenewBaseAbsUnresolved).Path
Write-Host "Using Renew base directory: $RenewBaseAbs"

# Search for needed .jar files in the Renew base directory (recursively)
$discoveredJarFiles = Get-ChildItem -Path $RenewBaseAbs -Recurse -Filter "*.jar" | ForEach-Object { $_.FullName }

# Construct the additional classpath string from discovered jar files
# [System.IO.Path]::PathSeparator is the OS-specific path separator (';' on Windows, ':' on Linux/macOS)
$additionalClasspath = $discoveredJarFiles -join [System.IO.Path]::PathSeparator

# Set the CLASSPATH (CP)
# $env:CLASSPATH accesses the current CLASSPATH environment variable.
$existingClasspath = $env:CLASSPATH

if (-not [string]::IsNullOrEmpty($existingClasspath)) {
    if (-not [string]::IsNullOrEmpty($additionalClasspath)) {
        $CP = "$existingClasspath$([System.IO.Path]::PathSeparator)$additionalClasspath"
    } else {
        $CP = $existingClasspath
    }
} else {
    if (-not [string]::IsNullOrEmpty($additionalClasspath)) {
        # Original script prepends "." if CLASSPATH is empty.
        $CP = ".$([System.IO.Path]::PathSeparator)$additionalClasspath"
    } else {
        # If CLASSPATH is empty and no new jars are found, default to current directory ".".
        $CP = "."
    }
}

Write-Host "Using CLASSPATH: $CP"

# Find the java command to use
$JavaCmd = "java.exe" # Default to 'java.exe', assuming it's in the system PATH
if (-not [string]::IsNullOrEmpty($env:JAVA_HOME)) {
    $JavaPathInHome = Join-Path -Path $env:JAVA_HOME -ChildPath "bin\java.exe"
    if (Test-Path -Path $JavaPathInHome -PathType Leaf) {
        $JavaCmd = $JavaPathInHome
        Write-Host "Using Java from JAVA_HOME: $JavaCmd"
    } else {
        Write-Warning "JAVA_HOME is set ('$($env:JAVA_HOME)'), but '$JavaPathInHome' was not found. Falling back to '$JavaCmd' from PATH."
    }
} else {
    Write-Host "JAVA_HOME environment variable is not set. Using '$JavaCmd' from PATH."
}

# Invoke the StubCompiler Java application
# $Args is an automatic variable in PowerShell containing command-line arguments passed to the script.
Write-Host "Executing: & '$JavaCmd' -cp ""$CP"" de.renew.call.StubCompiler $Args"
& $JavaCmd -cp "$CP" de.renew.call.StubCompiler $Args

# To capture exit code from the Java application (optional)
# $ExitCode = $LASTEXITCODE
# Write-Host "Java application exited with code: $ExitCode"
# exit $ExitCode