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
    Write-Error "Please check the `$BaseDirRelative` variable path in the script ('$($BaseDirRelative)') or your directory structure."
    exit 1
}
$RenewBaseAbs = (Resolve-Path -LiteralPath $RenewBaseAbsUnresolved).Path
Write-Host "Using Renew base directory: $RenewBaseAbs"

# Search for needed .jar files in the Renew base directory (recursively)
# The original script's comment "search for needed jars in dist/plugins directory" might be
# a specific context, but the "find * -name '*.jar'" command after "cd RENEW_BASE_ABS"
# implies searching all subdirectories of RENEW_BASE_ABS. This script does the latter.
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

# Find the Java Compiler (javac) command to use
$JavaC = "javac.exe" # Default to 'javac.exe', assuming it's in the system PATH
if (-not [string]::IsNullOrEmpty($env:JAVA_HOME)) {
    $JavaCompilerPathInHome = Join-Path -Path $env:JAVA_HOME -ChildPath "bin\javac.exe"
    if (Test-Path -Path $JavaCompilerPathInHome -PathType Leaf) {
        $JavaC = $JavaCompilerPathInHome
        Write-Host "Using Java Compiler from JAVA_HOME: $JavaC"
    } else {
        Write-Warning "JAVA_HOME is set ('$($env:JAVA_HOME)'), but '$JavaCompilerPathInHome' was not found. Falling back to '$JavaC' from PATH."
    }
} else {
    Write-Host "JAVA_HOME environment variable is not set. Using '$JavaC' from PATH."
}

# Invoke the Java Compiler
# $Args is an automatic variable in PowerShell containing command-line arguments passed to the script.
# These arguments are expected to be source files or other javac options.
if ($Args.Count -eq 0) {
    Write-Warning "No source files or compiler options provided to the script."
    Write-Warning "Usage: $($MyInvocation.MyCommand.Name) <source_files_or_javac_options>"
    # javac typically shows its help message if run with no arguments.
    # To explicitly show help, you could add: & $JavaC -help
    # To exit if no arguments are provided:
    # Write-Error "Aborting due to missing arguments."
    # exit 2
}

Write-Host "Executing: & '$JavaC' -classpath ""$CP"" $($Args -join ' ')" # Using -join for display
& $JavaC -classpath "$CP" $Args

# To capture exit code from javac (optional)
$ExitCode = $LASTEXITCODE
Write-Host "Java Compiler exited with code: $ExitCode"
# exit $ExitCode # Uncomment to make the PowerShell script exit with javac's exit code