
<#PSScriptInfo

.VERSION 2.0.0

.GUID 16a6fd80-10ea-4595-a14e-932a6dc559d3

.AUTHOR Jimmy Briggs

.COMPANYNAME jimbrig

.COPYRIGHT Jimmy Briggs | 2025

.TAGS PowerShell Script

.LICENSEURI https://github.com/jimbrig/PSScripts/blob/main/LICENSE

.PROJECTURI https://github.com/jimbrig/PSScripts/tree/main/Cleanup-PathEnv/

.ICONURI

.EXTERNALMODULEDEPENDENCIES

.REQUIREDSCRIPTS

.EXTERNALSCRIPTDEPENDENCIES

.RELEASENOTES
Initial Release

#>

<#
.SYNOPSIS
    Cleans up and reorganizes Windows PATH environment variables.

.DESCRIPTION
    This script helps clean up and optimize Windows PATH environment variables by:
    - Removing duplicate entries
    - Removing invalid/non-existent paths
    - Categorizing and reorganizing paths by type
    - Creating backups before making changes
    - Providing detailed reporting

.PARAMETER DryRun
    Runs the script without making any actual changes to PATH variables.

.PARAMETER NoBackup
    Skips the backup step before making changes.

.PARAMETER ExportReport
    Exports a detailed before/after report to HTML.

.PARAMETER RestoreBackup
    Restores PATH variables from a backup file. Specify 'latest' to use most recent backup
    or provide a specific timestamp in the format 'yyyy-MM-dd_HH-mm-ss'.

.PARAMETER Normalize
    Attempts to normalize paths by standardizing format and using environment variables.

.PARAMETER NoConfirm
    Skips the confirmation prompt before making changes.

.PARAMETER LogLevel
    Sets the logging level. Valid values: Silent, Error, Warning, Info, Verbose, Debug.
    Default is 'Info'.

.EXAMPLE
    .\Cleanup-PathEnv.ps1
    Runs the script with default settings, prompting for confirmation before changes.

.EXAMPLE
    .\Cleanup-PathEnv.ps1 -DryRun
    Shows what changes would be made without actually applying them.

.EXAMPLE
    .\Cleanup-PathEnv.ps1 -ExportReport -NoConfirm
    Cleans up PATH variables, exports a report, and skips confirmation.

.EXAMPLE
    .\Cleanup-PathEnv.ps1 -RestoreBackup latest
    Restores PATH variables from the most recent backup.

.NOTES
    Version:        2.0.0
    Author:         Jimmy Briggs <jimmy.briggs@noclocks.dev>
    Creation Date:  April 14, 2025
    Last Modified:  April 14, 2025
#>
#Requires -RunAsAdministrator
[CmdletBinding(DefaultParameterSetName = 'Cleanup')]
Param(
    [Parameter(ParameterSetName = 'Cleanup')]
    [switch]$DryRun = $false,  # Run without making changes

    [Parameter(ParameterSetName = 'Cleanup')]
    [switch]$NoBackup = $false, # Skip backup step

    [Parameter(ParameterSetName = 'Cleanup')]
    [switch]$ExportReport = $false, # Export before/after report

    [Parameter(ParameterSetName = 'Restore', Mandatory = $true)]
    [string]$RestoreBackup, # Restore from backup

    [Parameter(ParameterSetName = 'Cleanup')]
    [switch]$Normalize = $false, # Normalize paths

    [Parameter(ParameterSetName = 'Cleanup')]
    [switch]$NoConfirm = $false, # Skip confirmation

    [Parameter(ParameterSetName = 'Cleanup')]
    [ValidateSet('Silent', 'Error', 'Warning', 'Info', 'Verbose', 'Debug')]
    [string]$LogLevel = 'Info' # Logging level
)

# Script Version
$script:Version = "2.0.0"

#region Script Variables

# Set backup directory
$script:backupDir = "$env:USERPROFILE\PathBackup"
$script:timestamp = Get-Date -Format "yyyy-MM-dd_HH-mm-ss"
$script:logFile = "$script:backupDir\path_cleanup_$script:timestamp.log"
$script:reportFile = "$script:backupDir\path_report_$script:timestamp.html"

# Define log levels
$script:LogLevels = @{
    'Silent'  = 0
    'Error'   = 1
    'Warning' = 2
    'Info'    = 3
    'Verbose' = 4
    'Debug'   = 5
}

# Current log level value
$script:CurrentLogLevel = $script:LogLevels[$LogLevel]

# Path categories with expanded definitions
$script:PathCategories = @{
    # Windows system directories
    'Windows' = @(
        '*\Windows\*',
        '*\System32\*',
        '*\wbem\*',
        '*\WindowsPowerShell\*',
        '*\OpenSSH\*',
        '*\WindowsApps\*'
    )

    # Programming languages and runtimes
    'Languages' = @(
        '*\Python*',
        '*\jdk*',
        '*\java*',
        '*\R\*',
        '*\nodejs*',
        '*\dotnet*',
        '*\PowerShell*',
        '*\npm*',
        '*\.cargo*',
        '*\go\*',
        '*\Ruby*',
        '*\Perl*',
        '*\Rust*',
        '*\gcc*',
        '*\msys*',
        '*\mingw*'
    )

    # Developer tools
    'DevTools' = @(
        '*\git*',
        '*\GitHub*',
        '*\VS Code*',
        '*\Docker*',
        '*\AWS*',
        '*\Azure*',
        '*\Microsoft SQL Server*',
        '*\Android\*',
        '*\gradle*',
        '*\maven*',
        '*\terraform*',
        '*\kubectl*',
        '*\Microsoft\VisualStudio\*',
        '*\JetBrains\*',
        '*\cmake*'
    )

    # Package managers and utilities
    'PackageManagers' = @(
        '*\chocolatey*',
        '*\scoop*',
        '*\pip*',
        '*\winget*',
        '*\nuget*',
        '*\vcpkg*',
        '*\yarn*',
        '*\pnpm*',
        '*\brew*'
    )

    # Utilities and other applications
    'Utilities' = @(
        '*\bin*',
        '*\oh-my-posh*',
        '*\sysinternals*',
        '*\curl*',
        '*\ssh*',
        '*\putty*',
        '*\vagrant*',
        '*\ffmpeg*',
        '*\ImageMagick*',
        '*\GnuWin*'
    )
}

#endregion

#region Logging Functions

# Function to write log messages
function Write-Log {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Message,

        [Parameter(Mandatory = $false)]
        [ValidateSet('Error', 'Warning', 'Info', 'Verbose', 'Debug')]
        [string]$Level = 'Info',

        [Parameter(Mandatory = $false)]
        [switch]$NoConsole
    )

    $levelValue = $script:LogLevels[$Level]

    # Skip if current log level is lower than this message's level
    if ($levelValue -gt $script:CurrentLogLevel) {
        return
    }

    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logMessage = "[$timestamp] [$Level] $Message"

    # Write to log file
    if (-not $NoBackup) {
        # Ensure the log directory exists
        $logDir = Split-Path -Path $script:logFile -Parent
        if (-not (Test-Path $logDir)) {
            try {
                New-Item -Path $logDir -ItemType Directory -Force | Out-Null
                Write-Host "Created log directory: $logDir" -ForegroundColor Cyan
            }
            catch {
                Write-Host "Warning: Could not create log directory: $($_.Exception.Message)" -ForegroundColor Yellow
            }
        }

        # Now try to write to the log file
        try {
            Add-Content -Path $script:logFile -Value $logMessage -ErrorAction SilentlyContinue
        }
        catch {
            # Just continue if we can't write to the log file
            Write-Host "Warning: Could not write to log file: $($_.Exception.Message)" -ForegroundColor Yellow
        }
    }

    # Write to console with color based on level
    if (-not $NoConsole) {
        $color = switch ($Level) {
            'Error'   { 'Red' }
            'Warning' { 'Yellow' }
            'Info'    { 'Green' }
            'Verbose' { 'Cyan' }
            'Debug'   { 'Magenta' }
            default   { 'White' }
        }

        Write-Host $logMessage -ForegroundColor $color
    }
}

#endregion

#region Utility Functions

# Function to check if a path exists
function Test-PathValidity {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$Path,

        [Parameter(Mandatory = $false)]
        [switch]$Detailed
    )

    $result = [PSCustomObject]@{
        Path = $Path
        OriginalPath = $Path
        Exists = $false
        Expanded = $Path
        ErrorMessage = $null
    }

    try {
        # Expand environment variables if present
        if ($Path -match '%.*%') {
            $result.Expanded = [System.Environment]::ExpandEnvironmentVariables($Path)
        } elseif ($Path -match '\$env:') {
            # Handle PowerShell $env:VAR format
            $result.Expanded = $ExecutionContext.InvokeCommand.ExpandString($Path)
        }

        # Test if the path exists
        $result.Exists = (Test-Path -Path $result.Expanded -ErrorAction Stop)

        return $Detailed ? $result : $result.Exists
    }
    catch {
        $result.ErrorMessage = $_.Exception.Message
        Write-Log "Error testing path '$Path': $($_.Exception.Message)" -Level Error

        return $Detailed ? $result : $false
    }
}

# Function to normalize a path
function Get-NormalizedPath {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$Path
    )

    try {
        # Skip if path is empty or null
        if ([string]::IsNullOrWhiteSpace($Path)) {
            return $Path
        }

        # Expand the path (if it contains environment variables)
        $expandedPath = [System.Environment]::ExpandEnvironmentVariables($Path)

        # Try to get canonical path if it exists
        if (Test-Path -Path $expandedPath) {
            $expandedPath = (Resolve-Path -Path $expandedPath).Path
        }

        # Replace common paths with environment variables
        if ($Normalize) {
            # System drive
            if ($expandedPath -like "$env:SystemDrive\*") {
                $expandedPath = $expandedPath -replace [regex]::Escape($env:SystemDrive), '%SystemDrive%'
            }

            # Windows directory
            if ($expandedPath -like "$env:windir\*") {
                $expandedPath = $expandedPath -replace [regex]::Escape($env:windir), '%windir%'
            }

            # Program Files
            if ($expandedPath -like "$env:ProgramFiles\*") {
                $expandedPath = $expandedPath -replace [regex]::Escape($env:ProgramFiles), '%ProgramFiles%'
            }

            # Program Files (x86)
            if ($expandedPath -like "${env:ProgramFiles(x86)}\*") {
                $expandedPath = $expandedPath -replace [regex]::Escape("${env:ProgramFiles(x86)}"), '%ProgramFiles(x86)%'
            }

            # User profile
            if ($expandedPath -like "$env:USERPROFILE\*") {
                $expandedPath = $expandedPath -replace [regex]::Escape($env:USERPROFILE), '%USERPROFILE%'
            }
        }

        # Remove trailing backslash unless it's just a drive letter
        if ($expandedPath -match '^[A-Za-z]:$') {
            # It's just a drive letter, append backslash
            $expandedPath = "$expandedPath\"
        }
        else {
            # Remove trailing backslash if present
            $expandedPath = $expandedPath.TrimEnd('\')
        }

        return $expandedPath
    }
    catch {
        Write-Log "Error normalizing path '$Path': $($_.Exception.Message)" -Level Error
        return $Path
    }
}

# Function to remove duplicates while preserving order
function Remove-Duplicates {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string[]]$Paths
    )

    Write-Log "Removing duplicates from $($Paths.Count) path entries..." -Level Verbose

    $uniquePaths = @()
    $seenPaths = @{}
    $duplicateCount = 0

    foreach ($path in $Paths) {
        if ([string]::IsNullOrWhiteSpace($path)) {
            Write-Log "Skipping empty path entry" -Level Debug
            continue
        }

        # Normalize path for comparison (lowercase, remove trailing slashes)
        $normalizedPath = Get-NormalizedPath -Path $path
        $comparisonPath = $normalizedPath.TrimEnd('\').ToLower()

        if (-not $seenPaths.ContainsKey($comparisonPath)) {
            $uniquePaths += $normalizedPath
            $seenPaths[$comparisonPath] = $true
            Write-Log "Kept path: $normalizedPath" -Level Debug
        } else {
            $duplicateCount++
            Write-Log "Removing duplicate: $path" -Level Info
        }
    }

    Write-Log "Removed $duplicateCount duplicate path entries" -Level Info
    return $uniquePaths
}

# Function to get category for a path
function Get-PathCategory {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$Path
    )

    $normalizedPath = $Path.ToLower()

    # Check each category's patterns
    foreach ($category in $script:PathCategories.Keys) {
        foreach ($pattern in $script:PathCategories[$category]) {
            if ($normalizedPath -like $pattern.ToLower()) {
                Write-Log "Path '$Path' categorized as '$category'" -Level Debug
                return $category
            }
        }
    }

    # Default category
    Write-Log "Path '$Path' categorized as 'Other'" -Level Debug
    return "Other"
}

# Function to restore from backup
function Restore-PathFromBackup {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$BackupIdentifier
    )

    Write-Log "Starting PATH restore process..." -Level Info

    # Create backup directory if it doesn't exist
    if (-not (Test-Path $script:backupDir)) {
        Write-Log "Creating backup directory: $script:backupDir" -Level Info
        New-Item -Path $script:backupDir -ItemType Directory -Force | Out-Null
    }

    # If 'latest', find the most recent backup
    if ($BackupIdentifier -eq 'latest') {
        Write-Log "Looking for most recent backup..." -Level Info

        $latestSystemBackup = Get-ChildItem -Path $script:backupDir -Filter "system_path_backup_*.txt" |
                             Sort-Object -Property LastWriteTime -Descending |
                             Select-Object -First 1

        $latestUserBackup = Get-ChildItem -Path $script:backupDir -Filter "user_path_backup_*.txt" |
                           Sort-Object -Property LastWriteTime -Descending |
                           Select-Object -First 1

        if (-not $latestSystemBackup -or -not $latestUserBackup) {
            Write-Log "No backups found to restore!" -Level Error
            return $false
        }

        $systemBackupFile = $latestSystemBackup.FullName
        $userBackupFile = $latestUserBackup.FullName

        $backupTimestamp = $latestSystemBackup.Name -replace 'system_path_backup_' -replace '.txt'
        Write-Log "Found most recent backup from $backupTimestamp" -Level Info
    }
    else {
        # Use the specified timestamp
        $systemBackupFile = "$script:backupDir\system_path_backup_$BackupIdentifier.txt"
        $userBackupFile = "$script:backupDir\user_path_backup_$BackupIdentifier.txt"

        if (-not (Test-Path $systemBackupFile) -or -not (Test-Path $userBackupFile)) {
            Write-Log "Backup with timestamp $BackupIdentifier not found!" -Level Error
            return $false
        }

        Write-Log "Using backup from $BackupIdentifier" -Level Info
    }

    # Read backup files
    try {
        $systemPath = Get-Content -Path $systemBackupFile -Raw
        $userPath = Get-Content -Path $userBackupFile -Raw

        # Confirm before restoring
        if (-not $NoConfirm) {
            $confirmation = Read-Host "Do you want to restore PATH variables from backup? (Y/N)"
            if ($confirmation -ne "Y" -and $confirmation -ne "y") {
                Write-Log "Restore operation cancelled by user" -Level Warning
                return $false
            }
        }

        # Set environment variables
        [Environment]::SetEnvironmentVariable("PATH", $systemPath, "Machine")
        [Environment]::SetEnvironmentVariable("PATH", $userPath, "User")

        # Update current session
        $env:PATH = $systemPath + ";" + $userPath

        Write-Log "PATH variables have been restored successfully!" -Level Info
        Write-Log "Current session's PATH has been updated." -Level Info

        return $true
    }
    catch {
        Write-Log "Error restoring PATH from backup: $($_.Exception.Message)" -Level Error
        return $false
    }
}

# Function to create HTML report
function Export-PathReport {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string[]]$OriginalSystemPaths,

        [Parameter(Mandatory = $true)]
        [string[]]$OriginalUserPaths,

        [Parameter(Mandatory = $true)]
        [string[]]$NewSystemPaths,

        [Parameter(Mandatory = $true)]
        [string[]]$NewUserPaths,

        [Parameter(Mandatory = $false)]
        [hashtable]$SystemPathsByCategory,

        [Parameter(Mandatory = $false)]
        [hashtable]$UserPathsByCategory,

        [Parameter(Mandatory = $false)]
        [string]$OutputFile = $script:reportFile
    )

    Write-Log "Generating HTML report..." -Level Info

    try {
        # Ensure directory exists
        $reportDir = Split-Path -Path $OutputFile -Parent
        if (-not (Test-Path $reportDir)) {
            New-Item -Path $reportDir -ItemType Directory -Force | Out-Null
        }

        # Create HTML content
        $htmlContent = @"
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>PATH Environment Variable Report</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 20px; line-height: 1.6; color: #333; }
        h1, h2, h3 { color: #0066cc; }
        .container { max-width: 1200px; margin: 0 auto; }
        .summary { background-color: #f0f7ff; padding: 15px; border-radius: 5px; margin-bottom: 20px; }
        .category { background-color: #e9ecef; padding: 10px; margin: 15px 0; border-radius: 5px; }
        .path-entry { margin: 5px 0; padding: 8px; border-left: 4px solid #ddd; }
        .path-entry.exists { border-color: #28a745; }
        .path-entry.missing { border-color: #dc3545; }
        .path-entry.duplicate { border-color: #ffc107; }
        .status-badge {
            display: inline-block;
            padding: 2px 8px;
            border-radius: 3px;
            font-size: 12px;
            margin-right: 10px;
        }
        .status-exists { background-color: #d4edda; color: #155724; }
        .status-missing { background-color: #f8d7da; color: #721c24; }
        .status-duplicate { background-color: #fff3cd; color: #856404; }
        .stats { display: flex; justify-content: space-between; flex-wrap: wrap; }
        .stat-box { background-color: #e9ecef; padding: 10px; margin: 5px; border-radius: 5px; flex: 1; min-width: 200px; }
        .removed { background-color: #ffdddd; text-decoration: line-through; }
        .added { background-color: #ddffdd; }
        table { width: 100%; border-collapse: collapse; margin: 15px 0; }
        th, td { text-align: left; padding: 8px; border-bottom: 1px solid #ddd; }
        th { background-color: #f2f2f2; }
    </style>
</head>
<body>
    <div class="container">
        <h1>PATH Environment Variable Report</h1>
        <p>Generated on $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")</p>

        <div class="summary">
            <h2>Summary</h2>
            <div class="stats">
                <div class="stat-box">
                    <h3>System PATH</h3>
                    <p>Original entries: $($OriginalSystemPaths.Count)</p>
                    <p>New entries: $($NewSystemPaths.Count)</p>
                    <p>Removed: $($OriginalSystemPaths.Count - $NewSystemPaths.Count)</p>
                </div>
                <div class="stat-box">
                    <h3>User PATH</h3>
                    <p>Original entries: $($OriginalUserPaths.Count)</p>
                    <p>New entries: $($NewUserPaths.Count)</p>
                    <p>Removed: $($OriginalUserPaths.Count - $NewUserPaths.Count)</p>
                </div>
            </div>
        </div>

        <h2>System PATH Changes</h2>
        <table>
            <tr>
                <th>Original Path</th>
                <th>Status</th>
            </tr>
"@

        # Add system path entries
        foreach ($path in $OriginalSystemPaths) {
            $status = "Removed"
            $statusClass = "removed"

            if ($NewSystemPaths -contains $path) {
                $status = "Kept"
                $statusClass = ""
            }

            $exists = Test-PathValidity -Path $path
            $statusBadge = $exists ? "Valid" : "Invalid"
            $badgeClass = $exists ? "status-exists" : "status-missing"

            $htmlContent += @"
            <tr class="$statusClass">
                <td>$([System.Web.HttpUtility]::HtmlEncode($path))</td>
                <td>
                    <span class="status-badge $badgeClass">$statusBadge</span>
                    $status
                </td>
            </tr>
"@
        }

        # Check for new entries
        foreach ($path in $NewSystemPaths) {
            if ($OriginalSystemPaths -notcontains $path) {
                $exists = Test-PathValidity -Path $path
                $statusBadge = $exists ? "Valid" : "Invalid"
                $badgeClass = $exists ? "status-exists" : "status-missing"

                $htmlContent += @"
                <tr class="added">
                    <td>$([System.Web.HttpUtility]::HtmlEncode($path))</td>
                    <td>
                        <span class="status-badge $badgeClass">$statusBadge</span>
                        Added
                    </td>
                </tr>
"@
            }
        }

        $htmlContent += @"
        </table>

        <h2>User PATH Changes</h2>
        <table>
            <tr>
                <th>Original Path</th>
                <th>Status</th>
            </tr>
"@

        # Add user path entries
        foreach ($path in $OriginalUserPaths) {
            $status = "Removed"
            $statusClass = "removed"

            if ($NewUserPaths -contains $path) {
                $status = "Kept"
                $statusClass = ""
            }

            $exists = Test-PathValidity -Path $path
            $statusBadge = $exists ? "Valid" : "Invalid"
            $badgeClass = $exists ? "status-exists" : "status-missing"

            $htmlContent += @"
            <tr class="$statusClass">
                <td>$([System.Web.HttpUtility]::HtmlEncode($path))</td>
                <td>
                    <span class="status-badge $badgeClass">$statusBadge</span>
                    $status
                </td>
            </tr>
"@
        }

        # Check for new entries
        foreach ($path in $NewUserPaths) {
            if ($OriginalUserPaths -notcontains $path) {
                $exists = Test-PathValidity -Path $path
                $statusBadge = $exists ? "Valid" : "Invalid"
                $badgeClass = $exists ? "status-exists" : "status-missing"

                $htmlContent += @"
                <tr class="added">
                    <td>$([System.Web.HttpUtility]::HtmlEncode($path))</td>
                    <td>
                        <span class="status-badge $badgeClass">$statusBadge</span>
                        Added
                    </td>
                </tr>
"@
            }
        }

        $htmlContent += @"
        </table>
"@

        # Add categories if available
        if ($SystemPathsByCategory) {
            $htmlContent += @"

        <h2>System PATH by Category</h2>
"@

            foreach ($category in $SystemPathsByCategory.Keys) {
                $paths = $SystemPathsByCategory[$category]
                if ($paths.Count -gt 0) {
                    $htmlContent += @"
        <div class="category">
            <h3>$category ($($paths.Count) entries)</h3>
"@

                    foreach ($path in $paths) {
                        $exists = Test-PathValidity -Path $path
                        $statusClass = $exists ? "exists" : "missing"
                        $statusBadge = $exists ? "Valid" : "Invalid"
                        $badgeClass = $exists ? "status-exists" : "status-missing"

                        $htmlContent += @"
            <div class="path-entry $statusClass">
                <span class="status-badge $badgeClass">$statusBadge</span>
                $([System.Web.HttpUtility]::HtmlEncode($path))
            </div>
"@
                    }

                    $htmlContent += @"
        </div>
"@
                }
            }
        }

        # Add categories if available
        if ($UserPathsByCategory) {
            $htmlContent += @"

        <h2>User PATH by Category</h2>
"@

            foreach ($category in $UserPathsByCategory.Keys) {
                $paths = $UserPathsByCategory[$category]
                if ($paths.Count -gt 0) {
                    $htmlContent += @"
        <div class="category">
            <h3>$category ($($paths.Count) entries)</h3>
"@

                    foreach ($path in $paths) {
                        $exists = Test-PathValidity -Path $path
                        $statusClass = $exists ? "exists" : "missing"
                        $statusBadge = $exists ? "Valid" : "Invalid"
                        $badgeClass = $exists ? "status-exists" : "status-missing"

                        $htmlContent += @"
            <div class="path-entry $statusClass">
                <span class="status-badge $badgeClass">$statusBadge</span>
                $([System.Web.HttpUtility]::HtmlEncode($path))
            </div>
"@
                    }

                    $htmlContent += @"
        </div>
"@
                }
            }
        }

        $htmlContent += @"
    </div>
</body>
</html>
"@

        # Write HTML to file
        $htmlContent | Out-File -FilePath $OutputFile

        Write-Log "HTML report generated: $OutputFile" -Level Info
        return $true
    }
    catch {
        Write-Log "Error generating HTML report: $($_.Exception.Message)" -Level Error
        return $false
    }
}

#endregion

#region Main Script

# Check if restoration is requested
if ($PSCmdlet.ParameterSetName -eq 'Restore') {
    $result = Restore-PathFromBackup -BackupIdentifier $RestoreBackup

    if ($result) {
        Write-Log "PATH variables have been successfully restored from backup '$RestoreBackup'." -Level Info
    }
    else {
        Write-Log "Failed to restore PATH variables from backup." -Level Error
    }

    # Exit script after restore operation
    exit
}

Write-Log "PATH Environment Variable Cleanup Script v$script:Version" -Level Info
Write-Log "Starting cleanup process..." -Level Info

# Create backup directory if it doesn't exist and backup is enabled
if (-not $NoBackup) {
    if (-not (Test-Path $script:backupDir)) {
        Write-Log "Creating backup directory: $script:backupDir" -Level Info
        New-Item -Path $script:backupDir -ItemType Directory -Force | Out-Null
    }

    # Backup current PATH variables with timestamp
    $systemPathBackup = "$script:backupDir\system_path_backup_$script:timestamp.txt"
    $userPathBackup = "$script:backupDir\user_path_backup_$script:timestamp.txt"

    [Environment]::GetEnvironmentVariable("PATH", "Machine") | Out-File -FilePath $systemPathBackup
    [Environment]::GetEnvironmentVariable("PATH", "User") | Out-File -FilePath $userPathBackup

    Write-Log "Backed up current PATH variables to $script:backupDir" -Level Info
}

# Get current PATH variables
$systemPath = [Environment]::GetEnvironmentVariable("PATH", "Machine")
$userPath = [Environment]::GetEnvironmentVariable("PATH", "User")

$systemPaths = $systemPath -split ";" | Where-Object { $_ -and $_ -ne "" }
$userPaths = $userPath -split ";" | Where-Object { $_ -and $_ -ne "" }

$originalSystemPaths = $systemPaths.Clone()
$originalUserPaths = $userPaths.Clone()

Write-Log "Processing System PATH with $($systemPaths.Count) entries..." -Level Info
Write-Log "Processing User PATH with $($userPaths.Count) entries..." -Level Info

# Step 1: Remove duplicates
Write-Log "`n1. Removing duplicates..." -Level Info
$systemPaths = Remove-Duplicates -Paths $systemPaths
$userPaths = Remove-Duplicates -Paths $userPaths

Write-Log "After removing duplicates - System PATH: $($systemPaths.Count) entries" -Level Info
Write-Log "After removing duplicates - User PATH: $($userPaths.Count) entries" -Level Info

# Step 2: Remove invalid paths
Write-Log "`n2. Removing invalid paths..." -Level Info
$validSystemPaths = @()
$validUserPaths = @()

# Show a progress bar for system paths
$i = 0
$count = $systemPaths.Count
foreach ($path in $systemPaths) {
    $i++
    Write-Progress -Activity "Checking System PATH entries" -Status "Processing $i of $count" -PercentComplete (($i / $count) * 100)

    if ([string]::IsNullOrWhiteSpace($path)) {
        Write-Log "Skipping empty System PATH entry" -Level Debug
        continue
    }

    if (Test-PathValidity -Path $path) {
        $validSystemPaths += $path
    } else {
        Write-Log "Removing invalid System PATH: $path" -Level Warning
    }
}
Write-Progress -Activity "Checking System PATH entries" -Completed

# Show a progress bar for user paths
$i = 0
$count = $userPaths.Count
foreach ($path in $userPaths) {
    $i++
    Write-Progress -Activity "Checking User PATH entries" -Status "Processing $i of $count" -PercentComplete (($i / $count) * 100)

    if ([string]::IsNullOrWhiteSpace($path)) {
        Write-Log "Skipping empty User PATH entry" -Level Debug
        continue
    }

    if (Test-PathValidity -Path $path) {
        $validUserPaths += $path
    } else {
        Write-Log "Removing invalid User PATH: $path" -Level Warning
    }
}
Write-Progress -Activity "Checking User PATH entries" -Completed

Write-Log "After removing invalid paths - System PATH: $($validSystemPaths.Count) entries" -Level Info
Write-Log "After removing invalid paths - User PATH: $($validUserPaths.Count) entries" -Level Info

# Step 3: Normalize paths if requested
if ($Normalize) {
    Write-Log "`n3. Normalizing paths..." -Level Info
    $normalizedSystemPaths = @()
    $normalizedUserPaths = @()

    foreach ($path in $validSystemPaths) {
        $normalizedPath = Get-NormalizedPath -Path $path
        $normalizedSystemPaths += $normalizedPath

        if ($normalizedPath -ne $path) {
            Write-Log "Normalized System PATH: $path -> $normalizedPath" -Level Info
        }
    }

    foreach ($path in $validUserPaths) {
        $normalizedPath = Get-NormalizedPath -Path $path
        $normalizedUserPaths += $normalizedPath

        if ($normalizedPath -ne $path) {
            Write-Log "Normalized User PATH: $path -> $normalizedPath" -Level Info
        }
    }

    $validSystemPaths = $normalizedSystemPaths
    $validUserPaths = $normalizedUserPaths

    Write-Log "Path normalization complete" -Level Info
}

# Step 4: Reorganize paths by category
Write-Log "`n4. Reorganizing paths by category..." -Level Info
$systemCategories = @{
    "Windows" = @()
    "Languages" = @()
    "DevTools" = @()
    "PackageManagers" = @()
    "Utilities" = @()
    "Other" = @()
}

$userCategories = @{
    "Windows" = @()
    "Languages" = @()
    "DevTools" = @()
    "PackageManagers" = @()
    "Utilities" = @()
    "Other" = @()
}

foreach ($path in $validSystemPaths) {
    $category = Get-PathCategory -Path $path
    $systemCategories[$category] += $path
}

foreach ($path in $validUserPaths) {
    $category = Get-PathCategory -Path $path
    $userCategories[$category] += $path
}

# Create reorganized paths in the desired order
$reorganizedSystemPaths = @()
$reorganizedSystemPaths += $systemCategories["Windows"]
$reorganizedSystemPaths += $systemCategories["Languages"]
$reorganizedSystemPaths += $systemCategories["DevTools"]
$reorganizedSystemPaths += $systemCategories["PackageManagers"]
$reorganizedSystemPaths += $systemCategories["Utilities"]
$reorganizedSystemPaths += $systemCategories["Other"]

$reorganizedUserPaths = @()
$reorganizedUserPaths += $userCategories["Windows"]
$reorganizedUserPaths += $userCategories["Languages"]
$reorganizedUserPaths += $userCategories["DevTools"]
$reorganizedUserPaths += $userCategories["PackageManagers"]
$reorganizedUserPaths += $userCategories["Utilities"]
$reorganizedUserPaths += $userCategories["Other"]

# Generate HTML report if requested
if ($ExportReport) {
    Write-Log "`nGenerating detailed HTML report..." -Level Info
    $reportResult = Export-PathReport -OriginalSystemPaths $originalSystemPaths `
                                     -OriginalUserPaths $originalUserPaths `
                                     -NewSystemPaths $reorganizedSystemPaths `
                                     -NewUserPaths $reorganizedUserPaths `
                                     -SystemPathsByCategory $systemCategories `
                                     -UserPathsByCategory $userCategories

    if ($reportResult) {
        Write-Log "HTML report generated successfully: $script:reportFile" -Level Info
    }
    else {
        Write-Log "Failed to generate HTML report" -Level Error
    }
}

# Review changes
Write-Log "`n5. Review reorganized paths:" -Level Info

Write-Log "`nReorganized System PATH ($($reorganizedSystemPaths.Count) entries):" -Level Info
foreach ($category in @("Windows", "Languages", "DevTools", "PackageManagers", "Utilities", "Other")) {
    if ($systemCategories[$category].Count -gt 0) {
        Write-Log "`n  ## $category" -Level Info
        $systemCategories[$category] | ForEach-Object { Write-Log "    $_" -Level Verbose }
    }
}

Write-Log "`nReorganized User PATH ($($reorganizedUserPaths.Count) entries):" -Level Info
foreach ($category in @("Windows", "Languages", "DevTools", "PackageManagers", "Utilities", "Other")) {
    if ($userCategories[$category].Count -gt 0) {
        Write-Log "`n  ## $category" -Level Info
        $userCategories[$category] | ForEach-Object { Write-Log "    $_" -Level Verbose }
    }
}

# Join paths
$newSystemPath = $reorganizedSystemPaths -join ";"
$newUserPath = $reorganizedUserPaths -join ";"

# Display statistics
$systemRemoved = $originalSystemPaths.Count - $reorganizedSystemPaths.Count
$userRemoved = $originalUserPaths.Count - $reorganizedUserPaths.Count

Write-Log "`n6. Summary of changes:" -Level Info
Write-Log "System PATH: $($originalSystemPaths.Count) entries → $($reorganizedSystemPaths.Count) entries ($systemRemoved removed)" -Level Info
Write-Log "User PATH: $($originalUserPaths.Count) entries → $($reorganizedUserPaths.Count) entries ($userRemoved removed)" -Level Info

# If dry run, just display what would happen
if ($DryRun) {
    Write-Log "`n*** DRY RUN MODE - No changes will be made ***" -Level Warning
    Write-Log "The following PATH variables would be set:" -Level Info
    Write-Log "`nSystem PATH would be set to:" -Level Info
    Write-Log $newSystemPath -Level Verbose
    Write-Log "`nUser PATH would be set to:" -Level Info
    Write-Log $newUserPath -Level Verbose

    if ($ExportReport) {
        Write-Log "`nA detailed report has been generated at: $script:reportFile" -Level Info
        Write-Log "You can open this file to review all changes in detail." -Level Info
    }

    Write-Log "`nTo apply these changes, run the script again without the -DryRun switch." -Level Info
    exit
}

# Confirm before setting
if (-not $NoConfirm) {
    $confirmation = Read-Host "`nDo you want to set these new PATH variables? (Y/N)"
    if ($confirmation -ne "Y" -and $confirmation -ne "y") {
        Write-Log "Operation cancelled. Your PATH variables remain unchanged." -Level Warning

        if ($ExportReport) {
            Write-Log "A detailed report was still generated at: $script:reportFile" -Level Info
        }

        exit
    }
}

# Set variables
[Environment]::SetEnvironmentVariable("PATH", $newSystemPath, "Machine")
[Environment]::SetEnvironmentVariable("PATH", $newUserPath, "User")

Write-Log "`nPATH variables have been updated successfully!" -Level Info
Write-Log "You may need to restart your applications or log off and on again for changes to take effect." -Level Warning

# Update current session's PATH
$env:PATH = $newSystemPath + ";" + $newUserPath
Write-Log "Current session's PATH has been updated." -Level Info

if ($ExportReport) {
    # Provide link to the report
    Write-Log "`nA detailed report has been generated at: $script:reportFile" -Level Info
    Write-Log "You can open this file to review all changes in detail." -Level Info

    # Try to open the report in the default browser
    try {
        Start-Process $script:reportFile
    }
    catch {
        Write-Log "Could not open the report automatically. Please open it manually." -Level Warning
    }
}

Write-Log "Script execution completed successfully." -Level Info

#endregion


# SIG # Begin signature block
# MIIbrQYJKoZIhvcNAQcCoIIbnjCCG5oCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCCZb8r0d92brpvW
# AL+cUrDxobazWwPXeBYCs2hjNhbl+aCCFgMwggL8MIIB5KADAgECAhAeucN4UQWG
# pkfnuZqnJIqGMA0GCSqGSIb3DQEBCwUAMBYxFDASBgNVBAMMC0ppbUJyaWdEZXZ0
# MB4XDTI1MDQxNDIxMzMzN1oXDTI2MDQxNDIxNTMzN1owFjEUMBIGA1UEAwwLSmlt
# QnJpZ0RldnQwggEiMA0GCSqGSIb3DQEBAQUAA4IBDwAwggEKAoIBAQDD7cp3mivP
# JOT8BZr0/MwWf+1GQQNkQq0/LhovZnBmQvpGzlNCldN33Lv8cdyaWY3RSdzpV+xt
# og232PVcVe5IhCzRAtGjrkVBdSR+bdFL258guggMFuE4/R28V/yqyu104oCRxZTl
# tUYMCu00CsoL0Z+N1FlCWKZFgwQyPxzgbSlC31pPZzRqr3X0AeVWphLW/7MsXHUb
# AAQDwCTOTuOyr258LdwDZG9t0R0G68LmfYD1PYQP3LP5kxj7agZb9WaynCFqWmxN
# KRjkScPQV3sDn6M7VC5JUy3ZcyFLjJeCF5M8Pk5JfL7pyP+WiGZU60ai2Hxl+RlT
# F74gPpUv3zfxAgMBAAGjRjBEMA4GA1UdDwEB/wQEAwIHgDATBgNVHSUEDDAKBggr
# BgEFBQcDAzAdBgNVHQ4EFgQUHs0F61/78bZDiTmi8x921yt/pM4wDQYJKoZIhvcN
# AQELBQADggEBAIeMBkw6OPlr5DHF4cv+xgUfzpIl4ZWUJ4XAA3e/6ex8/QdarXz+
# 7degiiUMOv3j54XqV/cuATfVisbAlM7/jPasClKI86FXQ3EZAqO+IPYBYnrsWGoS
# lbmunslvRG/UlkR8zolPaTuE+r18Dh8G1sYuhi1Dtv1cfG9HygIXTEAbs2J5G9em
# VhYeH9VI41H6IRzfTEKna4TXan7LsSsGNZxUe4oyad0eB+p4YhDEP/JoHGpBofEr
# dqiZWg9tUStVLyKtYTSXkLE7QuXiGIgvWZ9mmAAsaDpAdTDen1heB/n4ZaKd7I2X
# I/ORBjn+1E7PP5nhhn59Dq53Nl2WNCK4RewwggWNMIIEdaADAgECAhAOmxiO+dAt
# 5+/bUOIIQBhaMA0GCSqGSIb3DQEBDAUAMGUxCzAJBgNVBAYTAlVTMRUwEwYDVQQK
# EwxEaWdpQ2VydCBJbmMxGTAXBgNVBAsTEHd3dy5kaWdpY2VydC5jb20xJDAiBgNV
# BAMTG0RpZ2lDZXJ0IEFzc3VyZWQgSUQgUm9vdCBDQTAeFw0yMjA4MDEwMDAwMDBa
# Fw0zMTExMDkyMzU5NTlaMGIxCzAJBgNVBAYTAlVTMRUwEwYDVQQKEwxEaWdpQ2Vy
# dCBJbmMxGTAXBgNVBAsTEHd3dy5kaWdpY2VydC5jb20xITAfBgNVBAMTGERpZ2lD
# ZXJ0IFRydXN0ZWQgUm9vdCBHNDCCAiIwDQYJKoZIhvcNAQEBBQADggIPADCCAgoC
# ggIBAL/mkHNo3rvkXUo8MCIwaTPswqclLskhPfKK2FnC4SmnPVirdprNrnsbhA3E
# MB/zG6Q4FutWxpdtHauyefLKEdLkX9YFPFIPUh/GnhWlfr6fqVcWWVVyr2iTcMKy
# unWZanMylNEQRBAu34LzB4TmdDttceItDBvuINXJIB1jKS3O7F5OyJP4IWGbNOsF
# xl7sWxq868nPzaw0QF+xembud8hIqGZXV59UWI4MK7dPpzDZVu7Ke13jrclPXuU1
# 5zHL2pNe3I6PgNq2kZhAkHnDeMe2scS1ahg4AxCN2NQ3pC4FfYj1gj4QkXCrVYJB
# MtfbBHMqbpEBfCFM1LyuGwN1XXhm2ToxRJozQL8I11pJpMLmqaBn3aQnvKFPObUR
# WBf3JFxGj2T3wWmIdph2PVldQnaHiZdpekjw4KISG2aadMreSx7nDmOu5tTvkpI6
# nj3cAORFJYm2mkQZK37AlLTSYW3rM9nF30sEAMx9HJXDj/chsrIRt7t/8tWMcCxB
# YKqxYxhElRp2Yn72gLD76GSmM9GJB+G9t+ZDpBi4pncB4Q+UDCEdslQpJYls5Q5S
# UUd0viastkF13nqsX40/ybzTQRESW+UQUOsxxcpyFiIJ33xMdT9j7CFfxCBRa2+x
# q4aLT8LWRV+dIPyhHsXAj6KxfgommfXkaS+YHS312amyHeUbAgMBAAGjggE6MIIB
# NjAPBgNVHRMBAf8EBTADAQH/MB0GA1UdDgQWBBTs1+OC0nFdZEzfLmc/57qYrhwP
# TzAfBgNVHSMEGDAWgBRF66Kv9JLLgjEtUYunpyGd823IDzAOBgNVHQ8BAf8EBAMC
# AYYweQYIKwYBBQUHAQEEbTBrMCQGCCsGAQUFBzABhhhodHRwOi8vb2NzcC5kaWdp
# Y2VydC5jb20wQwYIKwYBBQUHMAKGN2h0dHA6Ly9jYWNlcnRzLmRpZ2ljZXJ0LmNv
# bS9EaWdpQ2VydEFzc3VyZWRJRFJvb3RDQS5jcnQwRQYDVR0fBD4wPDA6oDigNoY0
# aHR0cDovL2NybDMuZGlnaWNlcnQuY29tL0RpZ2lDZXJ0QXNzdXJlZElEUm9vdENB
# LmNybDARBgNVHSAECjAIMAYGBFUdIAAwDQYJKoZIhvcNAQEMBQADggEBAHCgv0Nc
# Vec4X6CjdBs9thbX979XB72arKGHLOyFXqkauyL4hxppVCLtpIh3bb0aFPQTSnov
# Lbc47/T/gLn4offyct4kvFIDyE7QKt76LVbP+fT3rDB6mouyXtTP0UNEm0Mh65Zy
# oUi0mcudT6cGAxN3J0TU53/oWajwvy8LpunyNDzs9wPHh6jSTEAZNUZqaVSwuKFW
# juyk1T3osdz9HNj0d1pcVIxv76FQPfx2CWiEn2/K2yCNNWAcAgPLILCsWKAOQGPF
# mCLBsln1VWvPJ6tsds5vIy30fnFqI2si/xK4VC0nftg62fC2h5b9W9FcrBjDTZ9z
# twGpn1eqXijiuZQwggauMIIElqADAgECAhAHNje3JFR82Ees/ShmKl5bMA0GCSqG
# SIb3DQEBCwUAMGIxCzAJBgNVBAYTAlVTMRUwEwYDVQQKEwxEaWdpQ2VydCBJbmMx
# GTAXBgNVBAsTEHd3dy5kaWdpY2VydC5jb20xITAfBgNVBAMTGERpZ2lDZXJ0IFRy
# dXN0ZWQgUm9vdCBHNDAeFw0yMjAzMjMwMDAwMDBaFw0zNzAzMjIyMzU5NTlaMGMx
# CzAJBgNVBAYTAlVTMRcwFQYDVQQKEw5EaWdpQ2VydCwgSW5jLjE7MDkGA1UEAxMy
# RGlnaUNlcnQgVHJ1c3RlZCBHNCBSU0E0MDk2IFNIQTI1NiBUaW1lU3RhbXBpbmcg
# Q0EwggIiMA0GCSqGSIb3DQEBAQUAA4ICDwAwggIKAoICAQDGhjUGSbPBPXJJUVXH
# JQPE8pE3qZdRodbSg9GeTKJtoLDMg/la9hGhRBVCX6SI82j6ffOciQt/nR+eDzMf
# UBMLJnOWbfhXqAJ9/UO0hNoR8XOxs+4rgISKIhjf69o9xBd/qxkrPkLcZ47qUT3w
# 1lbU5ygt69OxtXXnHwZljZQp09nsad/ZkIdGAHvbREGJ3HxqV3rwN3mfXazL6IRk
# tFLydkf3YYMZ3V+0VAshaG43IbtArF+y3kp9zvU5EmfvDqVjbOSmxR3NNg1c1eYb
# qMFkdECnwHLFuk4fsbVYTXn+149zk6wsOeKlSNbwsDETqVcplicu9Yemj052FVUm
# cJgmf6AaRyBD40NjgHt1biclkJg6OBGz9vae5jtb7IHeIhTZgirHkr+g3uM+onP6
# 5x9abJTyUpURK1h0QCirc0PO30qhHGs4xSnzyqqWc0Jon7ZGs506o9UD4L/wojzK
# QtwYSH8UNM/STKvvmz3+DrhkKvp1KCRB7UK/BZxmSVJQ9FHzNklNiyDSLFc1eSuo
# 80VgvCONWPfcYd6T/jnA+bIwpUzX6ZhKWD7TA4j+s4/TXkt2ElGTyYwMO1uKIqjB
# Jgj5FBASA31fI7tk42PgpuE+9sJ0sj8eCXbsq11GdeJgo1gJASgADoRU7s7pXche
# MBK9Rp6103a50g5rmQzSM7TNsQIDAQABo4IBXTCCAVkwEgYDVR0TAQH/BAgwBgEB
# /wIBADAdBgNVHQ4EFgQUuhbZbU2FL3MpdpovdYxqII+eyG8wHwYDVR0jBBgwFoAU
# 7NfjgtJxXWRM3y5nP+e6mK4cD08wDgYDVR0PAQH/BAQDAgGGMBMGA1UdJQQMMAoG
# CCsGAQUFBwMIMHcGCCsGAQUFBwEBBGswaTAkBggrBgEFBQcwAYYYaHR0cDovL29j
# c3AuZGlnaWNlcnQuY29tMEEGCCsGAQUFBzAChjVodHRwOi8vY2FjZXJ0cy5kaWdp
# Y2VydC5jb20vRGlnaUNlcnRUcnVzdGVkUm9vdEc0LmNydDBDBgNVHR8EPDA6MDig
# NqA0hjJodHRwOi8vY3JsMy5kaWdpY2VydC5jb20vRGlnaUNlcnRUcnVzdGVkUm9v
# dEc0LmNybDAgBgNVHSAEGTAXMAgGBmeBDAEEAjALBglghkgBhv1sBwEwDQYJKoZI
# hvcNAQELBQADggIBAH1ZjsCTtm+YqUQiAX5m1tghQuGwGC4QTRPPMFPOvxj7x1Bd
# 4ksp+3CKDaopafxpwc8dB+k+YMjYC+VcW9dth/qEICU0MWfNthKWb8RQTGIdDAiC
# qBa9qVbPFXONASIlzpVpP0d3+3J0FNf/q0+KLHqrhc1DX+1gtqpPkWaeLJ7giqzl
# /Yy8ZCaHbJK9nXzQcAp876i8dU+6WvepELJd6f8oVInw1YpxdmXazPByoyP6wCeC
# RK6ZJxurJB4mwbfeKuv2nrF5mYGjVoarCkXJ38SNoOeY+/umnXKvxMfBwWpx2cYT
# gAnEtp/Nh4cku0+jSbl3ZpHxcpzpSwJSpzd+k1OsOx0ISQ+UzTl63f8lY5knLD0/
# a6fxZsNBzU+2QJshIUDQtxMkzdwdeDrknq3lNHGS1yZr5Dhzq6YBT70/O3itTK37
# xJV77QpfMzmHQXh6OOmc4d0j/R0o08f56PGYX/sr2H7yRp11LB4nLCbbbxV7HhmL
# NriT1ObyF5lZynDwN7+YAN8gFk8n+2BnFqFmut1VwDophrCYoCvtlUG3OtUVmDG0
# YgkPCr2B2RP+v6TR81fZvAT6gt4y3wSJ8ADNXcL50CN/AAvkdgIm2fBldkKmKYcJ
# RyvmfxqkhQ/8mJb2VVQrH4D6wPIOK+XW+6kvRBVK5xMOHds3OBqhK/bt1nz8MIIG
# vDCCBKSgAwIBAgIQC65mvFq6f5WHxvnpBOMzBDANBgkqhkiG9w0BAQsFADBjMQsw
# CQYDVQQGEwJVUzEXMBUGA1UEChMORGlnaUNlcnQsIEluYy4xOzA5BgNVBAMTMkRp
# Z2lDZXJ0IFRydXN0ZWQgRzQgUlNBNDA5NiBTSEEyNTYgVGltZVN0YW1waW5nIENB
# MB4XDTI0MDkyNjAwMDAwMFoXDTM1MTEyNTIzNTk1OVowQjELMAkGA1UEBhMCVVMx
# ETAPBgNVBAoTCERpZ2lDZXJ0MSAwHgYDVQQDExdEaWdpQ2VydCBUaW1lc3RhbXAg
# MjAyNDCCAiIwDQYJKoZIhvcNAQEBBQADggIPADCCAgoCggIBAL5qc5/2lSGrljC6
# W23mWaO16P2RHxjEiDtqmeOlwf0KMCBDEr4IxHRGd7+L660x5XltSVhhK64zi9Ce
# C9B6lUdXM0s71EOcRe8+CEJp+3R2O8oo76EO7o5tLuslxdr9Qq82aKcpA9O//X6Q
# E+AcaU/byaCagLD/GLoUb35SfWHh43rOH3bpLEx7pZ7avVnpUVmPvkxT8c2a2yC0
# WMp8hMu60tZR0ChaV76Nhnj37DEYTX9ReNZ8hIOYe4jl7/r419CvEYVIrH6sN00y
# x49boUuumF9i2T8UuKGn9966fR5X6kgXj3o5WHhHVO+NBikDO0mlUh902wS/Eeh8
# F/UFaRp1z5SnROHwSJ+QQRZ1fisD8UTVDSupWJNstVkiqLq+ISTdEjJKGjVfIcsg
# A4l9cbk8Smlzddh4EfvFrpVNnes4c16Jidj5XiPVdsn5n10jxmGpxoMc6iPkoaDh
# i6JjHd5ibfdp5uzIXp4P0wXkgNs+CO/CacBqU0R4k+8h6gYldp4FCMgrXdKWfM4N
# 0u25OEAuEa3JyidxW48jwBqIJqImd93NRxvd1aepSeNeREXAu2xUDEW8aqzFQDYm
# r9ZONuc2MhTMizchNULpUEoA6Vva7b1XCB+1rxvbKmLqfY/M/SdV6mwWTyeVy5Z/
# JkvMFpnQy5wR14GJcv6dQ4aEKOX5AgMBAAGjggGLMIIBhzAOBgNVHQ8BAf8EBAMC
# B4AwDAYDVR0TAQH/BAIwADAWBgNVHSUBAf8EDDAKBggrBgEFBQcDCDAgBgNVHSAE
# GTAXMAgGBmeBDAEEAjALBglghkgBhv1sBwEwHwYDVR0jBBgwFoAUuhbZbU2FL3Mp
# dpovdYxqII+eyG8wHQYDVR0OBBYEFJ9XLAN3DigVkGalY17uT5IfdqBbMFoGA1Ud
# HwRTMFEwT6BNoEuGSWh0dHA6Ly9jcmwzLmRpZ2ljZXJ0LmNvbS9EaWdpQ2VydFRy
# dXN0ZWRHNFJTQTQwOTZTSEEyNTZUaW1lU3RhbXBpbmdDQS5jcmwwgZAGCCsGAQUF
# BwEBBIGDMIGAMCQGCCsGAQUFBzABhhhodHRwOi8vb2NzcC5kaWdpY2VydC5jb20w
# WAYIKwYBBQUHMAKGTGh0dHA6Ly9jYWNlcnRzLmRpZ2ljZXJ0LmNvbS9EaWdpQ2Vy
# dFRydXN0ZWRHNFJTQTQwOTZTSEEyNTZUaW1lU3RhbXBpbmdDQS5jcnQwDQYJKoZI
# hvcNAQELBQADggIBAD2tHh92mVvjOIQSR9lDkfYR25tOCB3RKE/P09x7gUsmXqt4
# 0ouRl3lj+8QioVYq3igpwrPvBmZdrlWBb0HvqT00nFSXgmUrDKNSQqGTdpjHsPy+
# LaalTW0qVjvUBhcHzBMutB6HzeledbDCzFzUy34VarPnvIWrqVogK0qM8gJhh/+q
# DEAIdO/KkYesLyTVOoJ4eTq7gj9UFAL1UruJKlTnCVaM2UeUUW/8z3fvjxhN6hdT
# 98Vr2FYlCS7Mbb4Hv5swO+aAXxWUm3WpByXtgVQxiBlTVYzqfLDbe9PpBKDBfk+r
# abTFDZXoUke7zPgtd7/fvWTlCs30VAGEsshJmLbJ6ZbQ/xll/HjO9JbNVekBv2Tg
# em+mLptR7yIrpaidRJXrI+UzB6vAlk/8a1u7cIqV0yef4uaZFORNekUgQHTqddms
# PCEIYQP7xGxZBIhdmm4bhYsVA6G2WgNFYagLDBzpmk9104WQzYuVNsxyoVLObhx3
# RugaEGru+SojW4dHPoWrUhftNpFC5H7QEY7MhKRyrBe7ucykW7eaCuWBsBb4HOKR
# FVDcrZgdwaSIqMDiCLg4D+TPVgKx2EgEdeoHNHT9l3ZDBD+XgbF+23/zBjeCtxz+
# dL/9NWR6P2eZRi7zcEO1xwcdcqJsyz/JceENc2Sg8h3KeFUCS7tpFk7CrDqkMYIF
# ADCCBPwCAQEwKjAWMRQwEgYDVQQDDAtKaW1CcmlnRGV2dAIQHrnDeFEFhqZH57ma
# pySKhjANBglghkgBZQMEAgEFAKCBhDAYBgorBgEEAYI3AgEMMQowCKACgAChAoAA
# MBkGCSqGSIb3DQEJAzEMBgorBgEEAYI3AgEEMBwGCisGAQQBgjcCAQsxDjAMBgor
# BgEEAYI3AgEVMC8GCSqGSIb3DQEJBDEiBCA82OBmlts8R6l/wBpjSn5LyJIFND6M
# VjB/BC2HDiRDkDANBgkqhkiG9w0BAQEFAASCAQCKs31tGk2kfPxBUiMJCGyAH6fc
# a8p5eS88LEy9EYN5quGf3rAeTyb5yU58DtaeM8rLJI+bb267Nq0uwhpM99wKd3pa
# Ljrx7thCz1dpWf5zWzLvuZpOHV/2pIG2ZvN16Rhil1N/gpcnH4oZ4ad8HF1dRlkT
# lgn1nGA5EYEUeZvRvtKhHF8WZpn/X57rHRcTosAcHh2nSLWrw8t0y9O7JNgpWMlS
# BrgBiDQIR58DkeCH3UMwlWOy2eW1zj43moPu/S4e2ihJjOLRoCL/hjlrfsOYZ6Lj
# q+0XXjaADiaRS13C9BLxhwbqS5hE0a+PatzwAhV6P8UdC0AxHqu/wyy16JFroYID
# IDCCAxwGCSqGSIb3DQEJBjGCAw0wggMJAgEBMHcwYzELMAkGA1UEBhMCVVMxFzAV
# BgNVBAoTDkRpZ2lDZXJ0LCBJbmMuMTswOQYDVQQDEzJEaWdpQ2VydCBUcnVzdGVk
# IEc0IFJTQTQwOTYgU0hBMjU2IFRpbWVTdGFtcGluZyBDQQIQC65mvFq6f5WHxvnp
# BOMzBDANBglghkgBZQMEAgEFAKBpMBgGCSqGSIb3DQEJAzELBgkqhkiG9w0BBwEw
# HAYJKoZIhvcNAQkFMQ8XDTI1MDQxNDIxNDYwNFowLwYJKoZIhvcNAQkEMSIEIBj8
# oA4SCq65LqSYUihymiAzw/lLVCY7l+Cd7Y2BJIkoMA0GCSqGSIb3DQEBAQUABIIC
# ALS1LG1Z2klYcNivsLi9COeGQJ1RKFOyCKlUc8fW8Dj01yv5ZLwJrtxPGG1E9N+e
# 0GlZS45ufXWysMrRvqfhinuPCyztfF91ySIeH2NK/uZ9gH3ai+Q+cmml1AAHww7R
# mmynmI7X2jhSXrCHzQ7XiwfYHq4gch/+GfJQ65ZYtaJkuxwj65aivvaUFaLoBF/u
# y8lziD4Ii4VjnRh0a6HesenrVNG9S/tqKqgQa8XbSM2nvhj3IOFcc29cdD1oQK5J
# 0pIENImgMJFjjWq/969pjxpSETxlCzpDIIs4hnrMejIFg4j29K20hkQ8ar/WAU8I
# erQw/UnB6BBiLK2rQ7k6sNjTvzISRof3yNEoeEgPwyksoEOlrof+ogEKoanjsEMd
# /FvoMMqz8eyOlT+M98DTGz6/D+D0fkuyMNfDCRS5+A/z+jiBOf6ktZIL9BLYGoKl
# L6W+lRQiOxFT1+DljUup8uzDzgiF2AHRFr0Y05gBLmfz7af1Yz3k/vMHSqZVxPqK
# OiF7dbJszjB0pAeCpQHzy2lBMsl3JD4J1YbTlAB3vX1OrzVZBRjH9qQuchd+/VEJ
# JsUNVZzhR55VrbsBAcBxbV0stKOwgtwXZzK3o47aVDT9f7LKVGk7eCIFs4zAjhum
# PjR9sRSRGH6m6XnORiDjjJz33OYfdmaHdomamm9WIRP2
# SIG # End signature block
