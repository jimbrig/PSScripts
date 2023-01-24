
<#PSScriptInfo

.VERSION 1.0.0

.GUID 5dc94ebe-f6a8-45e0-bc15-d68136c7d49c

.AUTHOR Jimmy Briggs

.COMPANYNAME jimbrig

.COPYRIGHT Jimmy Briggs | 2023

.TAGS Secret Management Credentials Read Utility

.LICENSEURI https://github.com/jimbrig/PSScripts/blob/main/LICENSE

.PROJECTURI https://github.com/jimbrig/PSScripts/Read-HostSecret/

.ICONURI

.EXTERNALMODULEDEPENDENCIES 

.REQUIREDSCRIPTS

.EXTERNALSCRIPTDEPENDENCIES

.RELEASENOTES
Initial Release

.PRIVATEDATA

#>

<# 
.DESCRIPTION 
    Reads a secure string credential from the user 
.PARAMETER Prompt
    The prompt to display to the user
#> 
Param(
    [Parameter(Mandatory)] $Prompt
)

$password = Read-Host -Prompt $Prompt -AsSecureString
[PSCredential]::new("X", $Password).GetNetworkCredential().Password




