
<#PSScriptInfo

.VERSION 1.0.0

.GUID 7255ee4a-a899-465c-ad86-aa40b4de6e6d

.AUTHOR Jimmy Briggs

.COMPANYNAME jimbrig

.COPYRIGHT Jimmy Briggs | 2023

.TAGS Permissions Test Admin User UAC Utility Assertion

.LICENSEURI https://github.com/jimbrig/PSScripts/blob/main/LICENSE

.PROJECTURI https://github.com/jimbrig/PSScripts/Test-IsAdmin/

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
        Test if the current user is an administrator.
    .DESCRIPTION
        Test admin privileges without using -Requires RunAsAdministrator, which causes a nasty error message if
        trying to load the function within a PS profile but without Administrative privileges.
    .EXAMPLE
        Test-IsAdmin

        # Returns True if the current user is an administrator.
    
#>
[CmdletBinding()]
Param()

# Get the Principal Object
$Principal = New-Object `
    System.Security.Principal.WindowsPrincipal([System.Security.Principal.WindowsIdentity]::GetCurrent())

# Check if the Principal Object is in the Administrator Role
$IsAdmin = $Principal.IsInRole([System.Security.Principal.WindowsBuiltInRole]::Administrator)

If (-not $IsAdmin) {
    $ParentFunction = (Get-PSCallStack | Select-Object FunctionName -Skip 1 -First 1).FunctionName
    Write-Warning ('Function {0} needs admin privileges. Break now.' -f $ParentFunction)
    return $false
}
Else {
    return $true
}
