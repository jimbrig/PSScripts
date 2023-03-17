<p>
    <img src="https://github.com/jimbrig/PSXLDevTools/blob/main/resources/images/powershellcore.png?raw=true" align="left" style="float:left" height="8%" width="8%">
    <h1>Custom PowerShell Scripts</h1>
    <a href="https://www.powershellgallery.com/profiles/jimbrig" target="_blank"><img src="https://img.shields.io/badge/PowerShell%20Gallery-jimbrig-blue" align="right" style="float:right" /></a>
    <a href="https://github.com/jimbrig/PSScripts/actions/workflows/publish.yml" target="_blank"><img src="https://github.com/jimbrig/PSScripts/actions/workflows/publish.yml/badge.svg" align="right" style="float:right" /></a>
</p>
<br>

> **Note**  
> Collection of PowerShell Scripts published to my [Powershell Gallery Profile](https://www.powershellgallery.com/profiles/jimbrig).

## Contents

- [Overview](#overview)
- [Installation](#installation)
  - [Bulk Installation](#bulk-installation)
  - [Individual Script Installation](#individual-script-installation)
  - [Clone Locally](#clone-locally)
- [Roadmap](#roadmap)
- [Scripts](#scripts)
- [Appendices](#appendices)
  - [License](#license)
  - [Versioning](#versioning)  
  - [Acknowledgments](#acknowledgments)
  - [Contact](#contact)

## Overview

> **Note**
> *View the Repository's [CHANGELOG](CHANGELOG.md) for the latest updates and changes made over time*

This repository contains a collection of PowerShell scripts that I have written for various purposes and published 
to my [Powershell Gallery Profile](https://powershellgallery.com/profiles/jimbrig).

## Installation

### Bulk Installation

To install all scripts at once use the [Install-PSCustomScripts.ps1](Install-PSCustomScripts/Install-PSCustomScripts.ps1) script:

```powershell
Install-Script -Name Install-PSCustomScripts.ps1

Install-PSCustomScripts
```

### Individual Script Installation

To install any individual script listed in this repository, you can use the `Install-Script` cmdlet from the 
[PowerShellGet](https://docs.microsoft.com/en-us/powershell/gallery/overview) module.

```powershell
Install-Script -Name <script-name>
```

### Clone Locally

Lastly, one can simply clone or download the scripts for use locally:

```bash
# SSH
git clone git@github.com:jimbrig/PSScripts.git

# HTTPS
https://github.com/jimbrig/PSScripts.git

# Github-CLI
gh repo clone jimbrig/PSScripts
```

## Roadmap

- [Get-FileHash]() - Calculates the hash of a file using the specified algorithm.

## Scripts


### [ConvertTo-Markdown](./ConvertTo-Markdown/)

This script converts a string to Markdown.

```powershell

```

### [Read-HostSecret](Read-HostSecret) 

This script reads an encrypted secret from the user.

```powershell

```

### [Set-FolderIcon](Set-FolderIcon)

Sets the icon for a folder:

```powershell

```

### [Update-PSModules](Update-PSModules)

Update all modules at once:

```powershell

```

## Appendices

### License

This project is licensed under the [Unlicense](https://unlicense.org/). See the [LICENSE](LICENSE) file for details.

### Versioning

I use [Semantic Versioning](http://semver.org/) for versioning all the scripts.

### Acknowledgments

> Hat tip to anyone whose code was used:

- https://github.com/riedyw/PoshFunctions
- https://github.com/riedyw/MyPoshFunctions/tree/master

### Contact

- [jimmy.briggs@jimbrig.com](mailto:jimmy.briggs@jimbrig.com)


