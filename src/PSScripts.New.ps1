

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
    [string[]]$Tags,
    [Parameter(Mandatory = $False, Position = 3)]
    [string]$ScriptVersion = '1.0.0',
    [Parameter(Mandatory = $False, Position = 4)]
    [string]$ReleaseNotes
)

$ScriptRoot = Split-Path $MyInvocation.MyCommand.Path

. "$ScriptRoot\.utils\New-PSCustomScript.ps1"

New-PSCustomScript @PSBoundParameters

