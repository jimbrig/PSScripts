
<#PSScriptInfo

.VERSION 1.0.0

.GUID ad6c0995-0367-4d91-bc81-88839dae144c

.AUTHOR Jimmy Briggs

.COMPANYNAME jimbrig

.COPYRIGHT Jimmy Briggs | 2023

.TAGS Windows Shortcut Admin Control Maintain Machine Settings Utility Setup

.LICENSEURI https://github.com/jimbrig/PSScripts/blob/main/LICENSE

.PROJECTURI https://github.com/jimbrig/PSScripts/Add-GodModeShortcut/

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
        Adds a desktop shortcut for the `GodMode` Windows Advanced Options.
    .EXAMPLE
        Add-GodModeShortcut
        
        # Now Desktop has a shortcut.
#>
[CmdletBinding()]
Param()

$ErrorActionPreference = 'Stop'

$Desktop = [Environment]::GetFolderPath("Desktop")

If (!(Test-Path "$Desktop\GodMode.{ED7BA470-8E54-465E-825C-99712043E01C}")) { 
    New-Item -Path "$Desktop\GodMode.{ED7BA470-8E54-465E-825C-99712043E01C}" -ItemType Directory | Out-Null
}
