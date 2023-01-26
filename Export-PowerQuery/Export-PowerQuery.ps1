
<#PSScriptInfo

.VERSION 1.0.0

.GUID 8b80dbcc-b787-47b0-9e3f-96c73cb7f72b

.AUTHOR Jimmy Briggs

.COMPANYNAME jimbrig

.COPYRIGHT Jimmy Briggs | 2023

.TAGS Excel PowerQuery M-Code Export Utility Mashup Formula Automation VersionControl Extract

.LICENSEURI https://github.com/jimbrig/PSScripts/blob/main/LICENSE

.PROJECTURI https://github.com/jimbrig/PSScripts/Export-PowerQuery/

.ICONURI

.EXTERNALMODULEDEPENDENCIES DataMashup

.REQUIREDSCRIPTS

.EXTERNALSCRIPTDEPENDENCIES

.RELEASENOTES
Initial Release

.PRIVATEDATA

#>

<# 
    .SYNOPSIS 
        Exports Power Queries' M-Code Formulae from an Excel PowerQuery Enabled Workbook to a specified folder.

    .DESCRIPTION 
        This function exports Power Queries' M-Code Formulae from an Excel PowerQuery Enabled Workbook to a specified
        destination source code folder. This allows for the M-Code to be version controlled and maintained in a
        source code repository alongside the rest of the workbook's source code (VBA, XML, SQL, DAX, etc.).

        The function is designed to be used in conjunction with the Import-PowerQueries function, which imports all of
        the Power Queries' M-Code Formulae from the specified source code folder into the Excel PowerQuery Enabled Workbook.
    
    .PARAMETER Path
        The path to the Excel PowerQuery Enabled Workbook.

    .PARAMETER ExportPath
        (Optional) The path to the folder where the Power Queries' M-Code Formulae will be exported to. If not specified,
        `<ProjectRoot>/Source/PowerQuery/*` is used as the default source code export path for the queries.

    .PARAMETER Extension
        (Optional) The file extension to use for the exported Power Queries' M-Code Formulae. If not specified, `.pq` is used
        as the default file extension. Typically, `.pq` is used for Power Query M-Code files, but other extensions are also
        common such as `.m`, `.pqm`, `.txt`, etc.

    .PARAMETER Force
        (Optional) If specified, the function will overwrite any existing files in the specified source code export path.

    .EXAMPLE
        Export-PowerQuery -Path ".\MyWorkbook.xlsx" -ExportPath ".\Source\PowerQuery"

        # Exports all Power Queries' M-Code Formulae from the Excel PowerQuery Enabled Workbook at the specified path
        # to the specified source code export path.
    .EXAMPLE
        Export-PowerQuery -Path .\Test.xlsm -ExportPath .\Source\PQ -Extension .pqm -Force
        
        # Exports all Power Queries' M-Code Formulae from the Excel PowerQuery Enabled Workbook at the specified path
        # to the specified source code export path, using the specified file extension, and overwriting any existing files
        # in the specified source code export path.
    .NOTES
        During Development of Excel based applications, an essential component of developing and maintaining the
        project's source code is continuous export/import and synchronization of source files with the
        host application for portability and most of all, version control.

        One area typically overlooked in this regard is the M-Code behind the Power Query components in the workbook's
        data model. Whether it be a Dynamic Query, User Defined Function, Query Parameter, Lookup Table, or any other
        Power Query component type (i.e. template, data source, properties, metadata, etc.), the M-Code behind
        the scenes is the foundation that all queries are built from and what drives the core behaviour of the query's
        component.
    .COMPONENT
        - [Dependency]: DataMashup PowerShell Module
        - [Related]: PSXLDevTools PowerShell Module
        - [Related]: Import-PowerQuery PowerShell Function
    
    .LINK
        https://github.com/jimbrig/PSXLDevTools/blob/main/PSXLDevTools/Public/Export-PowerQuery.ps1

    .OUTPUTS
        System.Collections.ArrayList

    .INPUTS
        
#>
[CmdletBinding()]
[OutputType([System.Collections.ArrayList])]

Param(
    [Parameter(Mandatory = $true, Position = 0, HelpMessage = 'The path to the Excel PowerQuery Enabled Workbook.')]
    [string]$Path,
    [Parameter(Mandatory = $false, Position = 1, HelpMessage = 'The path to the folder where the Power Queries'' M-Code Formulae will be exported to. If not specified, `<ProjectRoot>/Source/PowerQuery/*` is used as the default source code export path for the queries.')]
    [string]$ExportPath = (Join-Path (Split-Path $Path -Parent)),
    [Parameter(Mandatory = $false, Position = 2, HelpMessage = 'The file extension to use for the exported Power Queries')]
    [ValidateSet('.pq', '.m', '.pqm', '.txt', '.qry')]
    [string]$Extension = '.pq',
    [Parameter(Mandatory = $false, Position = 3, HelpMessage = 'If specified, the function will overwrite any existing files in the specified source code export path.')]
    [switch]$Force
)

Begin {

    # Check if DataMashup PowerShell Module is installed
    If (-not (Get-Module -Name DataMashup -ListAvailable)) {
        Write-Output 'DataMashup PowerShell Module is not installed. Please install it before running this function.' -ForegroundColor Red
        throw 'DataMashup PowerShell Module is not installed. Please install it before running this function.'
    }

    # Check if the specified Excel Workbook exists
    If (-not (Test-Path -Path $Path)) {
        Write-Output 'The specified Excel Workbook does not exist. Please specify a valid path to an Excel Workbook.' -ForegroundColor Red
        throw 'The specified Excel Workbook does not exist. Please specify a valid path to an Excel Workbook.'
    }

    # Check if the specified Excel Workbook is a PowerQuery Enabled Workbook
    If (-not (Test-DataMashup -Path $Path)) {
        Write-Output 'The specified Excel Workbook is not a PowerQuery Enabled Workbook or has Data Connections Disabled.' -ForegroundColor Red
        throw 'The specified Excel Workbook is not a PowerQuery Enabled Workbook or has Data Connections Disabled.'
    }

    # Check if the specified Export Path exists
    If (-not (Test-Path -Path $ExportPath)) {
        Write-Information 'The specified Export Path does not exist. Creating the path...' -ForegroundColor Yellow
        New-Item -Path $ExportPath -ItemType Directory -Force
    }

    # For user-provided extensions:
    If ($Extension -ne '.pq') {

        # Check the provided Extension is valid:
        $validExtensions = @('.pq', '.m', '.pqm', '.txt', '.qry')

        # Parse the provided Extension to ensure has leading period:
        If ($Extension -notlike '.?*') {
            $Extension = ".$Extension"
        }

        If (-not ($validExtensions -contains $Extension)) {
            Write-Output 'The provided Extension is not valid. Please specify a valid file extension from the following list:' -ForegroundColor Red
            Write-Output $validExtensions -ForegroundColor Magenta
            throw "The provided Extension is not valid. Please specify a valid file extension from the following list: $($validExtensions -join ', ')"
        }
    }
}

Process {

    Import-Module DataMashup

    # Export DataMashup for the PowerQueries via Export-DataMashup:
    try {
        $PQs = Export-DataMashup $Path
    }
    catch {
        Write-Output 'An error occurred while exporting the Power Queries from the specified Excel Workbook.' -ForegroundColor Red
        Write-Output $_.Exception.Message -ForegroundColor Magenta
        throw "An error occurred while exporting the Power Queries from the specified Excel Workbook: $_.Exception.Message"
    }
    finally {
        Remove-Module DataMashup
    }

    # Export PowerQuery query formulas to files:
    ForEach ($pq in $PQs) {
        $pqName = $pq.Name
        $pqFormula = $pq.Expression
        try {
            $pqFormula | Out-File -FilePath "$ExportPath\$pqName$Extension" -Encoding UTF8 -Force:$Force
        }
        catch {
            Write-Output "An error occurred while exporting $pqName to file $ExportPath\$pqName$Extension" -ForegroundColor Red
            Write-Output $_.Exception.Message -ForegroundColor Magenta
            throw "An error occurred while exporting $pqName to file $ExportPath\$pqName$Extension - $_.Exception.Message"
        }
        finally {
            Write-Output "Successfully exported $pqName to file $ExportPath\$pqName$Extension" -ForegroundColor Green
        }
    }
}

End {
    Write-Output 'Successfully exported all Power Queries from the specified Excel Workbook.' -ForegroundColor Green
}
