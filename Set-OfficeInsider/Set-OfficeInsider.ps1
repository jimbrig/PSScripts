
<#PSScriptInfo

.VERSION 1.0.0

.GUID 2894ac7b-9fa8-4ea9-a82c-1af4b5b8ad58

.AUTHOR Jimmy Briggs

.COMPANYNAME jimbrig

.COPYRIGHT Jimmy Briggs | 2023

.TAGS Office365 Windows Insiders

.LICENSEURI https://github.com/jimbrig/PSScripts/blob/main/LICENSE

.PROJECTURI https://github.com/jimbrig/PSScripts/Set-OfficeInsider/

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
        This script will set the Office Channel info in the Registry

   .DESCRIPTION
        This script will add the Office Insider Channel Information in the Registry.
        It is a Quick and Dirty Solution.

   .PARAMETER Channel
        The Office Release Channel
        
        Possible Values for the Channel Variable are:
            - Insiderfast - With weekly builds, not generally supported (Default)
            - FirstReleaseCurrent - Office Insider Slow aka First Release Channel
            - Current - Current Channel
            - Validation - First Release for Deferred Channel
            - Business - Also known as Current Branch for Business
   
   .EXAMPLE
        Set-OfficeInsider.ps1 -Channel 'Insiderfast'

        # Set the Distribution Channel to Insiderfast - Weekly builds
   
   .EXAMPLE
        Set-OfficeInsider.ps1 -Channel 'Business'

        # Set the Distribution Channel to Business - Slow updates
   
   .NOTES
   
        This will work with Windows based Office 365 (Click to Run) installations only! 
        Change the Release Channel might cause issues! Do this at your own risk.
        Not all Channels are supported by Microsoft.
#>
[CmdletBinding()]
Param(
    [Parameter(ValueFromPipeline = $true, Position = 0)]
    [ValidateSet('Insiderfast', 'FirstReleaseCurrent', 'Current', 'Validation', 'Business', IgnoreCase = $true)]
    [ValidateNotNullOrEmpty()]
    [string]$Channel = 'InsiderFast'
)

Begin {
    
    $SC = 'SilentlyContinue'
    
    try {
        $paramNewItem = @{
            Path          = 'HKLM:\SOFTWARE\Policies\Microsoft\office\16.0\common\'
            Name          = 'officeupdate'
            Force         = $true
            ErrorAction   = $SC
            WarningAction = $SC
            Confirm       = $false
        }
        
        $null = (New-Item @paramNewItem)
        
        Write-Verbose -Message 'The Registry Structure was created.'
   } catch {

      Write-Verbose -Message 'The Registry Structure exists...'
   
   }

   Process {

    try {
      
      $paramNewItemProperty = @{
         Path          = 'HKLM:\SOFTWARE\Policies\Microsoft\office\16.0\common\officeupdate'
         Name          = 'updatebranch'
         PropertyType  = 'String'
         Value         = $Channel
         Force         = $true
         ErrorAction   = $SC
         WarningAction = $SC
         Confirm       = $false
      }
      
      $null = (New-ItemProperty @paramNewItemProperty)

      Write-Verbose -Message 'Registry Entry was created.'
   }
   catch {
      $paramSetItem = @{
         Path          = 'HKLM:\SOFTWARE\Policies\Microsoft\office\16.0\common\officeupdate\updatebranch'
         Value         = $Channel
         Force         = $true
         ErrorAction   = $SC
         WarningAction = $SC
         Confirm       = $false
      }
      $null = (Set-Item @paramSetItem)

      Write-Verbose -Message 'Registry Entry was changed.'
   }
   }

}


