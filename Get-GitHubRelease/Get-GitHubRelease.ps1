
<#PSScriptInfo

.VERSION 1.0.0

.GUID 16a73147-5803-4143-9c23-ea8cee731a9f

.AUTHOR Jimmy Briggs

.COMPANYNAME jimbrig

.COPYRIGHT Jimmy Briggs | 2023

.TAGS GitHub Version Release Download Tool Asset Install

.LICENSEURI https://github.com/jimbrig/PSScripts/blob/main/LICENSE

.PROJECTURI https://github.com/jimbrig/PSScripts/Get-GitHubRelease/

.ICONURI

.EXTERNALMODULEDEPENDENCIES 

.REQUIREDSCRIPTS

.EXTERNALSCRIPTDEPENDENCIES

.RELEASENOTES
Initial Release

.PRIVATEDATA

#>

<# 

    .SYNOPSIS
        Retrieve the latest release from a GitHub repository.
    .DESCRIPTION
        Uses the GitHub API to pull the latest release of any app, tool or utility hosted on GitHub.
    .PARAMETER Repo
        GitHub Repository Reference in the format: <user/org>/<repo>.
    .PARAMETER Extensions
        Target glob patterns of desired extension to search for.
    .PARAMETER DownloadPath
        Path to download to, defaults to ~/Downloads.
    .EXAMPLE
        Get-LatestGitHubRelease -Repo 'r-darwish/topgrade' -Extensions @('.zip') -DownloadPath "$HOME\Downloads"

        # Downloads the latest release of topgrade from GitHub.
#> 
[CmdletBinding()]
Param(
    [Parameter(Mandatory = $True, Position = 0, HelpMessage = 'Enter the GitHub Repo Name (e.g. microsoft/winget-cli)')]
    [string]$Repo,
    [Parameter(Mandatory = $False, Position = 1, HelpMessage = 'Enter the file extensions to search for (e.g. .zip)')]
    [string[]]$Extensions = @('.zip', '.msi', '.exe', '.deb', '.rpm', '.pkg', '.dmg', '.tar.gz', '.tar.xz', '.tar.bz2', '.msi', 'appxbundle', 'appx', 'msixbundle', 'msix'),
    [Parameter(Mandatory = $False, Position = 2, HelpMessage = 'Path to download to, defaults to ~/Downloads')]
    [string]$DownloadPath = "$HOME\Downloads"
)

# Define Environment Variables
$ProgressPreference = 'SilentlyContinue'
$ErrorActionPreference = 'SilentlyContinue'
If (!($Extensions)) {
    $Extensions = @(".zip", ".msixbundle", ".msix", ".msi", ".exe", ".appxbundle", ".appx")
}

$ScriptRoot = Split-Path $MyInvocation.MyCommand.Path
$targetExtensions = $Extensions
$transcriptLogPath = $env:APPDATA + "\PSUtils\Logs\Get-LatestGitHubRelease.txt"
If (!(Test-Path $transcriptLogPath)) {
    New-Item -ItemType File -Path $transcriptLogPath -Force
}
# Initialize the script
Start-Transcript -Path $transcriptLogPath -Append -Force
Write-Host "[ Get-LatestGitHubRelease.ps1 ]"

# Step 1: Ask for user input
If (!$Repo) {
    $Repo = Read-Host -Prompt "Please Enter the GitHub Repo Name (e.g. microsoft/winget-cli)"
}
$repo = $Repo
# The URL to the GitHub API for Releases
$GitHubReleasesURL = "https://api.github.com/repos/$repo/releases"
Write-Host "Targeted Repo: " -NoNewline
Write-Host "$GitHubReleasesURL" -ForegroundColor Green

# Step 2: Get the latest release from GitHub
Write-Host "Getting the latest release from GitHub, please wait..."
Write-Host

try {

    # Send a 'GET' request to the GitHub REST API (returns JSON)
    $json = Invoke-WebRequest $GitHubReleasesURL -Method Get -ContentType "application/json" -Headers @{Accept = "application/vnd.github.v3+json" }

    # Convert the JSON to a PowerShell object
    $releaseObj = ($json | ConvertFrom-Json)[0]

    # Get the ID of the latest release
    $releaseId = $releaseObj.id

    # Get the name of the latest release
    $releaseName = $releaseObj.tag_name

    Write-Host "Latest Release: $releaseName"

    Write-Host "Retrieving list of assets from this release... "

    # The URL to the GitHub API for the latest release
    $apiUrlForRelease = "https://api.github.com/repos/$repo/releases/$releaseId/assets"
    $releaseAssetList = Invoke-RestMethod -Method Get -Uri $apiUrlForRelease -ContentType "application/json" -Headers @{Accept = "application/vnd.github.v3+json" }

    Write-Host "Finding download links for your Operating System, please wait... "
    foreach ($myAsset in $releaseAssetList) {
        # $assetId = $myAsset.id
        $assetName = $myAsset.name # Microsoft.DesktopAppInstaller_8wekyb3d8bbwe.msixbundle
        # $assetAPIUrl = "https://api.github.com/repos/$repo/releases/assets/$assetId"
        $assetSizeMB = [math]::round($myAsset.size / 1MB, 2)
        $assetDownloadUrl = $myAsset.browser_download_url

        if (($targetExtensions | ForEach-Object { $assetName.contains($_) }) -contains $true) {
            Write-Host "Targeted Asset: " -NoNewline
            Write-Host "$assetName ($assetSizeMB MB)" -ForegroundColor Green
            $assetFileOutput = $DownloadPath + "\$assetName"
            Write-Host "[Asset Download URL] $assetDownloadUrl"
            Write-Host "[Asset Local File Name] $assetFileOutput"
            Write-Host "Downloading, please wait... " -NoNewline
            Invoke-WebRequest -Uri $assetDownloadUrl -OutFile $assetFileOutput
            Write-Host "Done!" -ForegroundColor Green
            break
        }
    }

    Write-Host
    Write-Host "Installing the package, please wait... "

    If ('.zip' -in $targetExtensions) {
        Write-Host "Unzipping downloaded zip: $assetName" -ForegroundColor Green
        Expand-Archive -Path $assetFileOutput -DestinationPath $DownloadPath -Force
    }

    Write-Host "Done!" -ForegroundColor Green
    explorer.exe $DownloadPath

} catch {
    Write-Host "An error occurred while trying to get the latest release from GitHub." -ForegroundColor Red
    $issueStr = "$($PSItem.ToString())"
    Write-Warning -Message $issueStr
    Write-Host
}

# End of Script
Stop-Transcript

# End of Script
