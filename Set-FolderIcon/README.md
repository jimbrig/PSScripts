# Set-FolderIcon

> This function sets a folder icon on specified folder.

[![PowerShell Gallery Version](https://img.shields.io/powershellgallery/v/Set-FolderIcon?include_prereleases)](https://www.powershellgallery.com/packages/Set-FolderIcon/)

## Contents

[TOC]

## Tags

Windows Utility Directories Configure Personalization Tool

## Release Notes

### Version 1.0.2

- Added Script Certificate Signature

### Version 1.0.1

- Added a check to see if the desktop.ini file already exists in the target directory.
        If it does, it will throw a warning and not overwrite the file.

- Added LICENSEURI, PROJECTURI, and RELEASENOTES to the PSScriptInfo block.

### Version 1.0.0

- Initial Release

## Notes

- A Script to set the icon for a provided folder.
- Will create two files in the destination path, both set as hidden system files: DESKTOP.ini and FOLDER.ICO.

## Parameters

### -Icon

```powershell
.PARAMETER Icon
    Path to the icon (*.ico) file to use.
```

### -Path

```powershell
.PARAMETER Path
    Path to the folder to add the icon to.
```

### -Recurse

```powershell
.PARAMETER Recurse
    [Boolean] Recurse sub-directories?
```

## Examples

```powershell
# Changes the default folder icon to the custom one I donwloaded from Google Images.
Set-FolderIcon -Icon "C:\Users\Mark\Downloads\Radvisual-Holographic-Folder.ico" -Path "C:\Users\Mark"
```

```powershell
# Changes the default folder icon to custom one for a UNC Path.
Set-FolderIcon -Icon "C:\Users\Mark\Downloads\wii_folder.ico" -Path "\\FAMILY\Media\Wii"
```

```powershell
# Changes the default folder icon to custom one for all folders in specified folder and that folder itself.
Set-FolderIcon -Icon "C:\Users\Mark\Downloads\Radvisual-Holographic-Folder.ico" -Path "C:\Test" -Recurse
```

