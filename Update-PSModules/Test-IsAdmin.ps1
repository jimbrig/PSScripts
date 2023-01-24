Function Test-IsAdmin {
    <#
    .SYNOPSIS
        Test if the current user is an administrator.
    .DESCRIPTION
        Test admin privileges without using -Requires RunAsAdministrator, which causes a nasty error message if
        trying to load the function within a PS profile but without Administrative privileges.
    .EXAMPLE
        PS> Test-IsAdmin
        True
    #>
    [CmdletBinding()]
    Param ()

    # Get the Principal Object
    $Principal = New-Object `
        System.Security.Principal.WindowsPrincipal([System.Security.Principal.WindowsIdentity]::GetCurrent())

    # Check if the Principal Object is in the Administrator Role
    $IsAdmin = $Principal.IsInRole([System.Security.Principal.WindowsBuiltInRole]::Administrator)

    If (-not $IsAdmin) {
        $ParentFunction = (Get-PSCallStack | Select-Object FunctionName -Skip 1 -First 1).FunctionName
        Write-Warning ("Function {0} needs admin privileges. Break now." -f $ParentFunction)
        return $false
    }
    Else {
        return $true
    }    
}