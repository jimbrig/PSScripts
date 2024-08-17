$dirs = (Get-ChildItem -Path $PWD -Directory -Recurse -Exclude @('.utils', 'ScriptCertificates', '.github', '.git', '.LocalRegistry', 'workflows')).Name
$scriptFiles = ForEach ($dir in $dirs) { ".\$dir\$dir.ps1" }  # $dirs | ForEach-Object { Get-ChildItem -Path "$PSScriptRoot\$_" -Filter *.ps1 -Recurse }

#$localRegistry = '.\.LocalRegistry'

. "$PWD\.utils\Set-ScriptSignature.ps1"

If ($scriptFiles.Count -eq 0) {
    Write-Warning 'No script files found.'
    return
}

If ($null -eq $Env:NUGET_API_TOKEN) {
    Write-Warning 'NUGET_API_TOKEN environment variable not set.'
    return
}

# Register the local registry as a trusted package source
#If (!(Get-PackageSource -Name LocalRegistry -ErrorAction SilentlyContinue)) {
#    If (!(Test-Path $localRegistry)) {
#        New-Item -ItemType Directory -Path $localRegistry
#    }
#    Register-PackageSource -Trusted -Provider PowerShellGet -Name LocalRegistry -Location $localRegistry
#}

ForEach ($scriptFile in $scriptFiles) {
    $ErrorActionPreference = "Continue"
    Test-ScriptFileInfo -Path $scriptFile
    # Set-ScriptSignature -ScriptPath $scriptFile
    # Publish-Script -Path $scriptFile -Repository LocalRegistry -NuGetApiKey $Env:NUGET_API_TOKEN -ErrorAction SilentlyContinue -WarningAction SilentlyContinue
    try {
        Publish-Script -Path $scriptFile -NuGetApiKey $Env:NUGET_API_TOKEN -Verbose -ErrorAction SilentlyContinue -WarningAction SilentlyContinue
    } 
    catch {
        Write-Warning "Caught an exception:"
        Write-Warning "Exception Type: $($_.Exception.GetType().FullName)"
        Write-Warning "Exception Message: $($_.Exception.Message)"
    }
}

# Start-Process "https://www.powershellgallery.com/profiles/jimbrig"

# Test-ScriptFileInfo -Path $PSScriptRoot\Set-FolderIcon\Set-FolderIcon.ps1 -Verbose

# Publish-Script -Path .\Set-FolderIcon\Set-FolderIcon\Set-FolderIcon.ps1 -NuGetApiKey $Env:NUGET_API_TOKEN -Verbose

# Test-ScriptFileInfo -Path $PSScriptRoot\Set-FolderIcon.ps1 -Verbose

# Publish-Script -Path .\Set-FolderIcon\Set-FolderIcon.ps1 -NuGetApiKey $Env:NUGET_API_TOKEN -Verbose
