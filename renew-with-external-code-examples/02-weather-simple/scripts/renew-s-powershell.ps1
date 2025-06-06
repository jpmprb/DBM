# PowerShell Script to run Renew on Windows
# Based on the provided Unix shell script

# --- 1. Set Renew Home and Check for Loader ---
# In PowerShell, paths are typically Windows-style.
# IMPORTANT: You MUST update this path to your actual Renew installation directory on Windows.
$env:HOMERENEW = "..\..\renew4.1base" # Example: "C:\Program Files\Renew" or "C:\Users\jpb\Renew"

# Check if HOMERENEW is set
if ([string]::IsNullOrEmpty($env:HOMERENEW)) {
    Write-Error "Error: HOMERENEW environment variable is not set."
    Write-Error "Please set HOMERENEW to the root directory of your Renew installation."
    exit 1
}

# Check if HOMERENEW directory exists
if (-not (Test-Path -Path $env:HOMERENEW -PathType Container)) {
    Write-Error "Error: HOMERENEW directory does not exist: $($env:HOMERENEW)"
    Write-Error "Please check your HOMERENEW variable."
    exit 1
}

# Search for loader.jar in HOMERENEW (not dist directory as per original script's logic for de.renew.loader.jar)
$loaderJarPath = Join-Path -Path $env:HOMERENEW -ChildPath "de.renew.loader.jar"
if (-not (Test-Path -Path $loaderJarPath -PathType Leaf)) {
    Write-Error "Error: cannot find de.renew.loader.jar in $($env:HOMERENEW)!"
    Write-Error "Please check your HOMERENEW variable and Renew installation."
    exit 1
}
Write-Host "HOMERENEW set to: $($env:HOMERENEW)"
Write-Host "Found loader.jar: $loaderJarPath"

# --- 2. Define your external classes directory ---
# Get the directory where the script is located
$ScriptDir = $PSScriptRoot # This is an automatic variable in PowerShell for the script's directory

# Set MY_EXTERNAL_CLASSES_DIR to the parent directory of the script's location
# Resolve-Path ".." relative to $ScriptDir gives the parent directory
$MY_EXTERNAL_CLASSES_DIR = (Resolve-Path (Join-Path -Path $ScriptDir -ChildPath "..")).Path

Write-Host "MY_EXTERNAL_CLASSES_DIR set to: $MY_EXTERNAL_CLASSES_DIR"

# Optional: Check if the directory exists and list its contents
if (Test-Path -Path $MY_EXTERNAL_CLASSES_DIR -PathType Container) {
    Write-Host "Contents of MY_EXTERNAL_CLASSES_DIR:"
    Get-ChildItem -Path $MY_EXTERNAL_CLASSES_DIR | ForEach-Object { Write-Host $_.Name }
} else {
    Write-Warning "Warning: MY_EXTERNAL_CLASSES_DIR does not exist or is not a directory: $MY_EXTERNAL_CLASSES_DIR"
    # Depending on requirements, you might want to exit here if this directory is crucial
    # exit 1
}

# --- 3. CLASSPATH ---
# PowerShell uses a semicolon (;) as the path separator for CLASSPATH
$pathSeparator = ";"
$addcpList = [System.Collections.Generic.List[string]]::new()

# Correctly iterate over files, ensuring HOMERENEW is the base for find
# Get-ChildItem recursively finds all .jar files
Get-ChildItem -Path $env:HOMERENEW -Filter "*.jar" -Recurse -File | ForEach-Object {
    $addcpList.Add($_.FullName)
}
$addcp = $addcpList -join $pathSeparator

# Set CLASSPATH components:
$CLASSPATH_COMPONENTS_LIST = @(
    $env:HOMERENEW,
    (Join-Path -Path $env:HOMERENEW -ChildPath "lib"), # Assuming a "lib" subdirectory like in Unix
    $MY_EXTERNAL_CLASSES_DIR
)
$CLASSPATH_COMPONENTS = $CLASSPATH_COMPONENTS_LIST -join $pathSeparator


# Construct the final CLASSPATH (CP)
# This logic is a bit complex in the original script, let's simplify if possible
# or replicate carefully.
# The original script's logic for addcp seems to prepend a colon if addcp is not empty
# and doesn't already start with one. In PowerShell, we'll join with semicolons.

$CP_List = [System.Collections.Generic.List[string]]::new()

# Add HOMERENEW
$CP_List.Add($env:HOMERENEW)

# Add HOMERENEW/lib if it exists
$renewLibPath = Join-Path -Path $env:HOMERENEW -ChildPath "lib"
if (Test-Path -Path $renewLibPath -PathType Container) {
    $CP_List.Add($renewLibPath)
}

# Add all JARs found under HOMERENEW
$CP_List.AddRange($addcpList)

# Add MY_EXTERNAL_CLASSES_DIR (if it's not already implicitly included or empty)
if (-not [string]::IsNullOrEmpty($MY_EXTERNAL_CLASSES_DIR) -and ($CP_List -notcontains $MY_EXTERNAL_CLASSES_DIR)) {
     $CP_List.Add($MY_EXTERNAL_CLASSES_DIR)
}

# Remove duplicates and empty entries, then join
$CP = ($CP_List | Where-Object { -not [string]::IsNullOrEmpty($_) } | Select-Object -Unique) -join $pathSeparator


# Ensure CP is not empty; if so, set to current directory "."
if ([string]::IsNullOrEmpty($CP) -or $CP -eq $pathSeparator) {
    $CP = "."
}

# Remove leading or trailing path separators (though Join-Path and array joining usually handle this well)
if ($CP.StartsWith($pathSeparator)) {
    $CP = $CP.Substring(1)
}
if ($CP.EndsWith($pathSeparator)) {
    $CP = $CP.Substring(0, $CP.Length - 1)
}

Write-Host "CLASSPATH: $CP"

# --- 4. Command ---
# Find java command
$JAVACMD = "java.exe" # Usually java.exe is in PATH on Windows

if (-not [string]::IsNullOrEmpty($env:JAVA_HOME)) {
    $javaInJavaHome = Join-Path -Path $env:JAVA_HOME -ChildPath "bin\java.exe"
    if (Test-Path -Path $javaInJavaHome -PathType Leaf) {
        $JAVACMD = $javaInJavaHome
    }
}
# Verify JAVACMD
try {
    Get-Command $JAVACMD -ErrorAction Stop | Out-Null
}
catch {
    Write-Error "Error: Java command ($JAVACMD) not found or not executable."
    Write-Error "Please ensure Java is installed and in your PATH, or JAVA_HOME is set correctly."
    exit 1
}


# Ensure MY_EXTERNAL_CLASSES_DIR is not empty before using it for netPath
if ([string]::IsNullOrEmpty($MY_EXTERNAL_CLASSES_DIR)) {
    Write-Error "Error: MY_EXTERNAL_CLASSES_DIR is not set. Cannot start Renew."
    exit 1
}

# Construct the module path carefully
# In Java 9+ module system, -p or --module-path uses the platform's path separator
$MODULE_PATH_List = [System.Collections.Generic.List[string]]::new()
$MODULE_PATH_List.Add($env:HOMERENEW)

$renewLibsPath = Join-Path -Path $env:HOMERENEW -ChildPath "libs" # Assuming "libs" not "lib" for modules as per original
if (Test-Path -Path $renewLibsPath -PathType Container) {
    $MODULE_PATH_List.Add($renewLibsPath)
}

if ((-not [string]::IsNullOrEmpty($MY_EXTERNAL_CLASSES_DIR)) `
    -and ($MY_EXTERNAL_CLASSES_DIR -ne $env:HOMERENEW) `
    -and ($MY_EXTERNAL_CLASSES_DIR -ne $renewLibsPath)) {
    $MODULE_PATH_List.Add($MY_EXTERNAL_CLASSES_DIR)
}
$MODULE_PATH = ($MODULE_PATH_List | Select-Object -Unique) -join $pathSeparator


Write-Host "JAVA COMMAND: $JAVACMD"
Write-Host "NETPATH (de.renew.netPath): $MY_EXTERNAL_CLASSES_DIR"
Write-Host "MODULE_PATH (-p): $MODULE_PATH"

# --- Start Renew GUI with .rnw files from parent directory and original script args ---

# Check if any .rnw files exist in MY_EXTERNAL_CLASSES_DIR
$foundRnwFilesInParentDir = $false
$rnwFilesToOpen = @()

if (Test-Path -Path $MY_EXTERNAL_CLASSES_DIR -PathType Container) {
    $rnwFiles = Get-ChildItem -Path $MY_EXTERNAL_CLASSES_DIR -Filter "*.rnw" -File
    if ($rnwFiles.Count -gt 0) {
        $foundRnwFilesInParentDir = $true
        $rnwFilesToOpen = $rnwFiles.FullName
    }
}

# Base Java command arguments
# Arguments for external processes in PowerShell are best passed as an array.
# Quotes around paths with spaces are handled automatically by PowerShell when passing an array.
$javaArgs = @(
    "-Xmx200M",
    "-Dde.renew.netPath=""$MY_EXTERNAL_CLASSES_DIR""", # Double quotes for the value if it contains spaces
    "-classpath", """$CP""", # Classpath value often needs to be a single quoted string for Java
    "-p", """$MODULE_PATH""", # Module path value also often needs to be a single quoted string
    "-m", "de.renew.loader/de.renew.plugin.PluginManager",
    "gui"
)

# Append .rnw files if found
if ($foundRnwFilesInParentDir) {
    Write-Host "Found .rnw files in parent directory. Opening them."
    foreach ($rnwFile in $rnwFilesToOpen) {
        $javaArgs += """$rnwFile""" # Add each .rnw file, quoted
    }
} else {
    Write-Host "No .rnw files found in $MY_EXTERNAL_CLASSES_DIR, or directory not accessible."
}

# Append original script arguments ($args is the PowerShell equivalent of $@)
# Ensure script arguments are also quoted if they contain spaces
if ($args.Count -gt 0) {
    foreach ($argItem in $args) {
        $javaArgs += """$argItem"""
    }
}

# --- Launch Renew ---
Write-Host "Executing: $JAVACMD $($javaArgs -join ' ')"

# Using Start-Process is generally safer for complex argument handling and GUI apps
# Start-Process -FilePath $JAVACMD -ArgumentList $javaArgs -NoNewWindow # Use -NoNewWindow if you want to see console output
# Or, for direct execution in the current console (might be better for seeing Java errors):
try {
    & $JAVACMD $javaArgs
}
catch {
    Write-Error "Failed to start Renew."
    Write-Error "Exception: $($_.Exception.Message)"
    # You can add more detailed error logging here if needed
    # For example, to see the full stack trace:
    # Write-Error ($_.ScriptStackTrace)
    exit 1
}

Write-Host "Renew execution attempt finished."
# Optional: Add exit code handling from Java if necessary
# $LASTEXITCODE
