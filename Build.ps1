$dirs = (Get-ChildItem -Path $PSScriptRoot -Directory -Recurse -Exclude @('.utils', '.github', '.git', '.LocalRegistry', 'workflows')).Name
$scriptFiles = ForEach ($dir in $dirs) { ".\$dir\$dir.ps1" }  # $dirs | ForEach-Object { Get-ChildItem -Path "$PSScriptRoot\$_" -Filter *.ps1 -Recurse }

$localRegistry = ".\.LocalRegistry"

If ($scriptFiles.Count -eq 0) {
    Write-Warning "No script files found."
    return
}

If ($null -eq $Env:NUGET_API_KEY) {
    Write-Warning "NUGET_API_KEY environment variable not set."
    return
}

# Register the local registry as a trusted package source
If (!(Get-PackageSource -Name LocalRegistry -ErrorAction SilentlyContinue)) {
    If (!(Test-Path $localRegistry)) {
        New-Item -ItemType Directory -Path $localRegistry
    }
    Register-PackageSource -Trusted -Provider PowerShellGet -Name LocalRegistry -Location "$PSScriptRoot\LocalRegistry"
}

ForEach ($scriptFile in $scriptFiles) {
    Test-ScriptFileInfo -Path $scriptFile
    Publish-Script -Path $scriptFile -Repository LocalRegistry -NuGetApiKey $Env:NUGET_API_KEY -ErrorAction SilentlyContinue -WarningAction SilentlyContinue
    Publish-Script -Path $scriptFile -NuGetApiKey $Env:NUGET_API_KEY -Verbose -ErrorAction SilentlyContinue -WarningAction SilentlyContinue
}

# Start-Process "https://www.powershellgallery.com/profiles/jimbrig"

# Test-ScriptFileInfo -Path $PSScriptRoot\Set-FolderIcon\Set-FolderIcon.ps1 -Verbose

# Publish-Script -Path .\Set-FolderIcon\Set-FolderIcon\Set-FolderIcon.ps1 -NuGetApiKey $Env:NUGET_API_KEY -Verbose

# Test-ScriptFileInfo -Path $PSScriptRoot\Set-FolderIcon.ps1 -Verbose

# Publish-Script -Path .\Set-FolderIcon\Set-FolderIcon.ps1 -NuGetApiKey $Env:NUGET_API_KEY -Verbose
