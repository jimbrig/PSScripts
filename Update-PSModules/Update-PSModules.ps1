
<#PSScriptInfo

.VERSION 1.0.1

.GUID 3187ed58-720b-4e9c-b3c2-707c00842fdf

.AUTHOR Jimmy Briggs

.COMPANYNAME jimbrig

.COPYRIGHT Jimmy Briggs | 2023

.TAGS PowerShell Modules Management Utility Update Cleanup

.LICENSEURI https://github.com/jimbrig/PSScripts/blob/main/LICENSE

.PROJECTURI https://github.com/jimbrig/PSScripts/Update-PSModules/

.ICONURI

.EXTERNALMODULEDEPENDENCIES 

.REQUIREDSCRIPTS

.EXTERNALSCRIPTDEPENDENCIES Test-IsAdmin.ps1,Update-Modules.ps1

.RELEASENOTES

1.0.1
Added Test-IsAdmin.ps1 and Update-Modules.ps1 to .EXTERNALSCRIPTDEPENDENCIES

1.0.0
Initial Release

.PRIVATEDATA

#>

<#
.SYNOPSIS
    Updates PowerShell Modules.
.DESCRIPTION 
    A script for updating and cleaning up old versions of your installed PowerShell Modules. 
.EXAMPLE
    .\Update-PSModules.ps1

    # Updates Modules.
.PARAMETER AllowPrerelease
    Allows the script to update to prerelease versions of modules.
#>
[CmdletBinding()]
Param (
    [Parameter(Mandatory=$false)]
    [switch]$AllowPrerelease
)

$ErrorActionPreference = 'Stop'

$ScriptRoot = Split-Path $MyInvocation.MyCommand.Path

. "$ScriptRoot\Test-IsAdmin.ps1"
. "$ScriptRoot\Update-Modules.ps1"

If ($AllowPrerelease) { Update-Modules -AllowPreRelease } Else { Update-Modules }
