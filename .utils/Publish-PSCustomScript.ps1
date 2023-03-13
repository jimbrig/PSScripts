Function Publish-PSCustomScript {
  <#
  .SYNOPSIS
      Publishes a PowerShell Script to the PowerShell Gallery and LocalRegistry.
  .PARAMETER ScriptName
      Name of the script to publish.
  #>
  [CmdletBinding()]
  Param(
    [Parameter(Mandatory = $True, Position = 0)]
    [string]$ScriptName
  )

  $ScriptFile = "$PWD\$ScriptName\$ScriptName.ps1"
  $LocalRegistry = "$PWD\.LocalRegistry"
  
  . "$PWD\.utils\Set-ScriptSignature.ps1"

  If ($null -eq $Env:NUGET_API_TOKEN) {
    Write-Warning 'NUGET_API_TOKEN environment variable not set.'
    return
  }

  # Register the local registry as a trusted package source
  If (!(Get-PackageSource -Name LocalRegistry -ErrorAction SilentlyContinue)) {
    Register-PackageSource -Trusted -Provider PowerShellGet -Name LocalRegistry -Location $LocalRegistry
  }

  Test-ScriptFileInfo -Path $ScriptFile
  Set-ScriptSignature -ScriptPath $ScriptFile
  Publish-Script -Path $ScriptFile -Repository LocalRegistry -NuGetApiKey $Env:NUGET_API_TOKEN -ErrorAction SilentlyContinue -WarningAction SilentlyContinue
  Publish-Script -Path $ScriptFile -NuGetApiKey $Env:NUGET_API_TOKEN -Verbose -ErrorAction SilentlyContinue -WarningAction SilentlyContinue
  
  Unregister-PSRepository -Name LocalRegistry -ErrorAction SilentlyContinue

  # Start-Process "https://www.powershellgallery.com/profiles/jimbrig"
}
