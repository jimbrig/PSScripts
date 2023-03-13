Function New-PSCustomScript {
    <#
    .SYNOPSIS
        Creates a new PowerShell script file and folder.
    .PARAMETER ScriptName
        Name of the script to create.
    .PARAMETER Description
        Description of the script to create.
    .PARAMETER Tags
        Tags to add to the script.
    .PARAMETER ScriptVersion
        Version of the script to create.
    .PARAMETER ReleaseNotes
        Release notes to add to the script.
    .EXAMPLE
        New-PSCustomScript -ScriptName 'Set-FolderIcon' -Description 'A Script to set the icon for a provided folder.' `
            -Tags @('Folder', 'Icon', 'Set') -ReleaseNotes 'Initial Release'

        # Creates a new folder and script file for the Set-FolderIcon script.
    #>
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory = $True, Position = 0)]
        [string]$ScriptName,
        [Parameter(Mandatory = $True, Position = 1)]
        [string]$Description,
        [Parameter(Mandatory = $False, Position = 2)]
        [string[]]$Tags = @('PowerShell', 'Script'),
        [Parameter(Mandatory = $False, Position = 3)]
        [string]$ScriptVersion = '1.0.0',
        [Parameter(Mandatory = $False, Position = 4)]
        [string]$ReleaseNotes = 'Initial Release'
    )

    $CommonParams = @{
        Path         = "$PWD\$ScriptName\$ScriptName.ps1"
        Description  = "$Description"
        Tags         = $Tags
        Version      = "$ScriptVersion"
        Author       = 'Jimmy Briggs'
        CompanyName  = 'jimbrig'
        Guid         = (New-Guid)
        Copyright    = 'Jimmy Briggs | 2023'
        LicenseUri   = 'https://github.com/jimbrig/PSScripts/blob/main/LICENSE'
        ProjectUri   = "https://github.com/jimbrig/PSScripts/tree/main/$ScriptName/"
        ReleaseNotes = "$ReleaseNotes"
        # IconUri                    = ''
        # ExternalModuleDependencies = ''
        # RequiredScripts            = ''
        # ExternalScriptDependencies = ''
        # PrivateData                = ''    
    }

    New-Item -ItemType Directory -Path "$PWD\$ScriptName" -Force -ErrorAction SilentlyContinue
    New-ScriptFileInfo @CommonParams -Verbose -Force

    New-Item -ItemType File -Path "$PWD\$ScriptName\README.md" -Force -ErrorAction SilentlyContinue

    $mdTags = $Tags -join ', '

    $galleryBadge = "[![PowerShell Gallery Version](https://img.shields.io/powershellgallery/v/$ScriptName?include_prereleases)](https://www.powershellgallery.com/packages/$ScriptName/)"
    
    $mdContent = @"
# $ScriptName

$galleryBadge

> $Description

## Tags

$mdTags

## Release Notes

### Version 1.0.0

- Initial Release

"@

    $mdContent | Out-File -FilePath "$PWD\$ScriptName\README.md" -Force

}

