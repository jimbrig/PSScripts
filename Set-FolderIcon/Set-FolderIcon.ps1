
<#PSScriptInfo

.VERSION 1.0.1

.GUID b4bc8c7c-92fc-46cb-9f61-3e2118597165

.AUTHOR Jimmy Briggs

.COMPANYNAME jimbrig

.COPYRIGHT Jimmy Briggs | 2023

.TAGS Windows Utility Directories Configure Personalization Tool

.LICENSEURI https://github.com/jimbrig/PSScripts/blob/main/LICENSE

.PROJECTURI https://github.com/jimbrig/PSScripts/Set-FolderIcon/

.ICONURI

.EXTERNALMODULEDEPENDENCIES 

.REQUIREDSCRIPTS

.EXTERNALSCRIPTDEPENDENCIES

.RELEASENOTES
    **Version 1.0.1**

    - Added a check to see if the desktop.ini file already exists in the target directory. 
        If it does, it will throw a warning and not overwrite the file.

    - Added LICENSEURI, PROJECTURI, and RELEASENOTES to the PSScriptInfo block.

.PRIVATEDATA

#>

<# 

.SYNOPSIS
    This function sets a folder icon on specified folder.
.DESCRIPTION 
    A Script to set the icon for a provided folder. 
    Will create two files in the destination path, both set as hidden system files: DESKTOP.ini and FOLDER.ICO. 
.PARAMETER Icon
    Path to the icon (*.ico) file to use.
.PARAMETER Path
    Path to the folder to add the icon to.
.PARAMETER Recurse
    [Boolean] Recurse sub-directories?
.EXAMPLE
    Set-FolderIcon -Icon "C:\Users\Mark\Downloads\Radvisual-Holographic-Folder.ico" -Path "C:\Users\Mark"
    
    # Changes the default folder icon to the custom one I donwloaded from Google Images.
.EXAMPLE
    Set-FolderIcon -Icon "C:\Users\Mark\Downloads\wii_folder.ico" -Path "\\FAMILY\Media\Wii"
    
    # Changes the default folder icon to custom one for a UNC Path.
.EXAMPLE
    Set-FolderIcon -Icon "C:\Users\Mark\Downloads\Radvisual-Holographic-Folder.ico" -Path "C:\Test" -Recurse
    
    # Changes the default folder icon to custom one for all folders in specified folder and that folder itself.
#> 
[CmdletBinding()]
Param(
    [Parameter(Mandatory = $True, Position = 0)]
    [string[]]$Icon,
    [Parameter(Mandatory = $True, Position = 1)]
    [string]$Path
)

If (!(Test-Path $Icon)) {
    throw "[Error] Specified Icon Path not found: $Icon"
}

If (!(Test-Path $Path)) {
    throw "[Error] Specified Directory Path not found: $Path"
}

$TargetDirectory = Convert-Path $Path

$DesktopIni = "[.ShellClassInfo]`n" + "IconResource=$Icon`n"

If (Test-Path "$($TargetDirectory)\desktop.ini") {
    Write-Warning -Message 'desktop.ini already found within directory.'
}
	
Add-Content "$($TargetDirectory)\desktop.ini" -Value $DesktopIni
	(Get-Item "$($TargetDirectory)\desktop.ini" -Force).Attributes = 'Hidden, System, Archive'
	(Get-Item $TargetDirectory -Force).Attributes = 'ReadOnly, Directory'

