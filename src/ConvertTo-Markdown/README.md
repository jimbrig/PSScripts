# ConvertTo-Markdown

[![PowerShell Gallery Version](https://img.shields.io/powershellgallery/v/ConvertTo-Markdown?include_prereleases)](https://www.powershellgallery.com/packages/ConvertTo-Markdown/)

> Convert pipeline output to a markdown document.

## Contents

[TOC]

## Tags

Markdown Utility Conversion Documentation Automation Tool

## Release Notes

### Version 1.0.0

- Initial Release

## Notes

- This command is designed to accept pipelined output and create a markdown document.
- The pipeline output will formatted as a text block.
- You can optionally define a title, content to appear before the output and content to appear after the output.
- The command does not create a text file.
- You need to pipe results from this command to a cmdlet like Out-File or Set-Content.

## Parameters

### -Title

*Specify a top level title. You do not need to include any markdown.*

```powershell
.PARAMETER Title
    Specify a top level title. You do not need to include any markdown.
```

### -PreContent

*Enter whatever content you want to appear before converted input. You can use whatever markdown you wish.*

```powershell
.PARAMETER PreContent
    Enter whatever content you want to appear before converted input. You can use whatever markdown you wish.
```

### -PostContent

*Enter whatever content you want to appear after converted input. You can use whatever markdown you wish.*

```powershell
.PARAMETER PostContent
    Enter whatever content you want to appear after converted input. You can use whatever markdown you wish.
```

### -Width

*Specify the document width. Depending on what you intend to do with the markdown from this command you may want to adjust this value.*

```powershell
.PARAMETER Width
    Specify the document width. Depending on what you intend to do with the markdown from this command you may want to adjust this value.
```

## Examples

```powershell
# Service Check
## THINK51
Get-Service Bits,Winrm | Convertto-Markdown -title "Service Check" -precontent "## $($env:computername)" -postcontent "_report $(Get-Date)_"

# Output
# text
#  Status   Name               DisplayName
#  ------   ----               -----------
#  Running  Bits               Background Intelligent Transfer Ser...
#  Running  Winrm              Windows Remote Management (WS-Manag...

# _report 07/20/2018 18:40:52_
```

```powershell
# Re-run the previous command and save output to a file.
Get-Service Bits,Winrm | Convertto-Markdown -title "Service Check" -precontent "## $($env:computername)" -postcontent "_report $(Get-Date)_" | Out-File c:\work\svc.md
```

```powershell
# Here is an example that create a series of markdown fragments for each computer 
# and at the end creates a markdown document.

$computers = "srv1","srv2","srv4"
$Title = "System Report"
$footer = "_report run $(Get-Date) by $($env:USERDOMAIN)\$($env:USERNAME)_"
$sb =  {
  $os = get-ciminstance -classname win32_operatingsystem -property caption,lastbootUptime
  [PSCustomObject]@{
    PSVersion = $PSVersionTable.PSVersion
    OS = $os.caption
    Uptime = (Get-Date) - $os.lastbootUpTime
    SizeFreeGB = (Get-Volume -DriveLetter C).SizeRemaining /1GB
  }
}
$out = Convertto-Markdown -title $Title
ForEach ($computer in $computers) {
  $out+= Invoke-command -scriptblock $sb -ComputerName $computer -HideComputerName |
  Select-Object -Property * -ExcludeProperty RunspaceID |
  ConvertTo-Markdown -PreContent "## $($computer.toUpper())"
}

$out += ConvertTo-Markdown -PostContent $footer
$out | set-content c:\work\report.md
```

## Links

Learn more about PowerShell: <https://jdhitsolutions.com/blog/essential-powershell-resources/>

- [ConvertTo-HTML]()
- [Out-File]()

