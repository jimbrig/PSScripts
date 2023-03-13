
<#PSScriptInfo

.VERSION 1.0.2

.GUID 8b80dbcc-b787-47b0-9e3f-96c73cb7f72b

.AUTHOR Jimmy Briggs

.COMPANYNAME jimbrig

.COPYRIGHT Jimmy Briggs | 2023

.TAGS Excel PowerQuery M-Code Export Utility Mashup Formula Automation VersionControl Extract

.LICENSEURI https://github.com/jimbrig/PSScripts/blob/main/LICENSE

.PROJECTURI https://github.com/jimbrig/PSScripts/tree/main/Export-PowerQuery/

.ICONURI

.EXTERNALMODULEDEPENDENCIES DataMashup

.REQUIREDSCRIPTS

.EXTERNALSCRIPTDEPENDENCIES

.RELEASENOTES

    1.0.2: Fixed Link to Project in Metadata

    1.0.1: Updated to use DataMashup PowerShell Module

    1.0.0: Initial Release

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

# SIG # Begin signature block
# MIIbsQYJKoZIhvcNAQcCoIIbojCCG54CAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCBtKNb40+E5tAys
# WYvY3FfKlfgurGYTzHvcoKH3WptoZKCCFgcwggL8MIIB5KADAgECAhBvRxLIstso
# kkFFgS0muvCbMA0GCSqGSIb3DQEBCwUAMBYxFDASBgNVBAMMC0ppbUJyaWdEZXZ0
# MB4XDTIzMDMxMDIzMjY1NVoXDTI0MDMxMDIzNDY1NVowFjEUMBIGA1UEAwwLSmlt
# QnJpZ0RldnQwggEiMA0GCSqGSIb3DQEBAQUAA4IBDwAwggEKAoIBAQDHDgwOjMvc
# sURWKCDgflsMLhNRIA5yWwkkwCSRTb2jPZTniUkPGgdJy8XQRXoecakq9Cw5QS2x
# UeCwVw+om9b4TeHdcZP237tLwJzMVf38xEfE7pE4jZHqcWd4owLtuD9oB//1nkiy
# FqiVBVgsOyRy4YJmwvhtbmA5ZWW1WHkNOgnh4ZPEBdLIIwsZlQT8B5aTHZQCj2YX
# NgUeroPJH0WgVajI4FDvN3usL8m3uh0UvE82nBgkJ5dkuVxHB2U3G4FN6nVb7N2y
# 4urqwBG/L8R04vI/IYYSEj2wxZb1swF5BJ22opDauWFdFQ7sN4qpElNMb6teAG7M
# qW6FK+eSLrJ1AgMBAAGjRjBEMA4GA1UdDwEB/wQEAwIHgDATBgNVHSUEDDAKBggr
# BgEFBQcDAzAdBgNVHQ4EFgQUacXlY5TOFBx5jUTmblh9+x5NcSUwDQYJKoZIhvcN
# AQELBQADggEBALbBLxYxORHVIHbZELfnX89QPM3+uKs0/SVWD7tiSa2HRPBDPSo1
# xFC2k/FzkzXaNXatKj1+4S/W/2tbOv7AM9a8t5luZeRZcRrfhaM+MHlN31ATBDMB
# ENMFt3iA70ToY5yRdVBaBsoA0FVvdmaIK/NsfwfU0hqz891w5bgYV4JFju832e19
# yoDqTXWmQUaAxFDQhL8I08y/cWTSxicRNdfEmn9ySV+QBrd76CV4F49nWWK9gcvP
# Ja2cOHxWb1EWW2yBC54aVOKidI+CzlYBYYeZZpRtkTseirvxoMt34b8iajKKqPlr
# VPNjRcQxLgfT841f49girM/UA4gtKgXBexYwggWNMIIEdaADAgECAhAOmxiO+dAt
# 5+/bUOIIQBhaMA0GCSqGSIb3DQEBDAUAMGUxCzAJBgNVBAYTAlVTMRUwEwYDVQQK
# EwxEaWdpQ2VydCBJbmMxGTAXBgNVBAsTEHd3dy5kaWdpY2VydC5jb20xJDAiBgNV
# BAMTG0RpZ2lDZXJ0IEFzc3VyZWQgSUQgUm9vdCBDQTAeFw0yMjA4MDEwMDAwMDBa
# Fw0zMTExMDkyMzU5NTlaMGIxCzAJBgNVBAYTAlVTMRUwEwYDVQQKEwxEaWdpQ2Vy
# dCBJbmMxGTAXBgNVBAsTEHd3dy5kaWdpY2VydC5jb20xITAfBgNVBAMTGERpZ2lD
# ZXJ0IFRydXN0ZWQgUm9vdCBHNDCCAiIwDQYJKoZIhvcNAQEBBQADggIPADCCAgoC
# ggIBAL/mkHNo3rvkXUo8MCIwaTPswqclLskhPfKK2FnC4SmnPVirdprNrnsbhA3E
# MB/zG6Q4FutWxpdtHauyefLKEdLkX9YFPFIPUh/GnhWlfr6fqVcWWVVyr2iTcMKy
# unWZanMylNEQRBAu34LzB4TmdDttceItDBvuINXJIB1jKS3O7F5OyJP4IWGbNOsF
# xl7sWxq868nPzaw0QF+xembud8hIqGZXV59UWI4MK7dPpzDZVu7Ke13jrclPXuU1
# 5zHL2pNe3I6PgNq2kZhAkHnDeMe2scS1ahg4AxCN2NQ3pC4FfYj1gj4QkXCrVYJB
# MtfbBHMqbpEBfCFM1LyuGwN1XXhm2ToxRJozQL8I11pJpMLmqaBn3aQnvKFPObUR
# WBf3JFxGj2T3wWmIdph2PVldQnaHiZdpekjw4KISG2aadMreSx7nDmOu5tTvkpI6
# nj3cAORFJYm2mkQZK37AlLTSYW3rM9nF30sEAMx9HJXDj/chsrIRt7t/8tWMcCxB
# YKqxYxhElRp2Yn72gLD76GSmM9GJB+G9t+ZDpBi4pncB4Q+UDCEdslQpJYls5Q5S
# UUd0viastkF13nqsX40/ybzTQRESW+UQUOsxxcpyFiIJ33xMdT9j7CFfxCBRa2+x
# q4aLT8LWRV+dIPyhHsXAj6KxfgommfXkaS+YHS312amyHeUbAgMBAAGjggE6MIIB
# NjAPBgNVHRMBAf8EBTADAQH/MB0GA1UdDgQWBBTs1+OC0nFdZEzfLmc/57qYrhwP
# TzAfBgNVHSMEGDAWgBRF66Kv9JLLgjEtUYunpyGd823IDzAOBgNVHQ8BAf8EBAMC
# AYYweQYIKwYBBQUHAQEEbTBrMCQGCCsGAQUFBzABhhhodHRwOi8vb2NzcC5kaWdp
# Y2VydC5jb20wQwYIKwYBBQUHMAKGN2h0dHA6Ly9jYWNlcnRzLmRpZ2ljZXJ0LmNv
# bS9EaWdpQ2VydEFzc3VyZWRJRFJvb3RDQS5jcnQwRQYDVR0fBD4wPDA6oDigNoY0
# aHR0cDovL2NybDMuZGlnaWNlcnQuY29tL0RpZ2lDZXJ0QXNzdXJlZElEUm9vdENB
# LmNybDARBgNVHSAECjAIMAYGBFUdIAAwDQYJKoZIhvcNAQEMBQADggEBAHCgv0Nc
# Vec4X6CjdBs9thbX979XB72arKGHLOyFXqkauyL4hxppVCLtpIh3bb0aFPQTSnov
# Lbc47/T/gLn4offyct4kvFIDyE7QKt76LVbP+fT3rDB6mouyXtTP0UNEm0Mh65Zy
# oUi0mcudT6cGAxN3J0TU53/oWajwvy8LpunyNDzs9wPHh6jSTEAZNUZqaVSwuKFW
# juyk1T3osdz9HNj0d1pcVIxv76FQPfx2CWiEn2/K2yCNNWAcAgPLILCsWKAOQGPF
# mCLBsln1VWvPJ6tsds5vIy30fnFqI2si/xK4VC0nftg62fC2h5b9W9FcrBjDTZ9z
# twGpn1eqXijiuZQwggauMIIElqADAgECAhAHNje3JFR82Ees/ShmKl5bMA0GCSqG
# SIb3DQEBCwUAMGIxCzAJBgNVBAYTAlVTMRUwEwYDVQQKEwxEaWdpQ2VydCBJbmMx
# GTAXBgNVBAsTEHd3dy5kaWdpY2VydC5jb20xITAfBgNVBAMTGERpZ2lDZXJ0IFRy
# dXN0ZWQgUm9vdCBHNDAeFw0yMjAzMjMwMDAwMDBaFw0zNzAzMjIyMzU5NTlaMGMx
# CzAJBgNVBAYTAlVTMRcwFQYDVQQKEw5EaWdpQ2VydCwgSW5jLjE7MDkGA1UEAxMy
# RGlnaUNlcnQgVHJ1c3RlZCBHNCBSU0E0MDk2IFNIQTI1NiBUaW1lU3RhbXBpbmcg
# Q0EwggIiMA0GCSqGSIb3DQEBAQUAA4ICDwAwggIKAoICAQDGhjUGSbPBPXJJUVXH
# JQPE8pE3qZdRodbSg9GeTKJtoLDMg/la9hGhRBVCX6SI82j6ffOciQt/nR+eDzMf
# UBMLJnOWbfhXqAJ9/UO0hNoR8XOxs+4rgISKIhjf69o9xBd/qxkrPkLcZ47qUT3w
# 1lbU5ygt69OxtXXnHwZljZQp09nsad/ZkIdGAHvbREGJ3HxqV3rwN3mfXazL6IRk
# tFLydkf3YYMZ3V+0VAshaG43IbtArF+y3kp9zvU5EmfvDqVjbOSmxR3NNg1c1eYb
# qMFkdECnwHLFuk4fsbVYTXn+149zk6wsOeKlSNbwsDETqVcplicu9Yemj052FVUm
# cJgmf6AaRyBD40NjgHt1biclkJg6OBGz9vae5jtb7IHeIhTZgirHkr+g3uM+onP6
# 5x9abJTyUpURK1h0QCirc0PO30qhHGs4xSnzyqqWc0Jon7ZGs506o9UD4L/wojzK
# QtwYSH8UNM/STKvvmz3+DrhkKvp1KCRB7UK/BZxmSVJQ9FHzNklNiyDSLFc1eSuo
# 80VgvCONWPfcYd6T/jnA+bIwpUzX6ZhKWD7TA4j+s4/TXkt2ElGTyYwMO1uKIqjB
# Jgj5FBASA31fI7tk42PgpuE+9sJ0sj8eCXbsq11GdeJgo1gJASgADoRU7s7pXche
# MBK9Rp6103a50g5rmQzSM7TNsQIDAQABo4IBXTCCAVkwEgYDVR0TAQH/BAgwBgEB
# /wIBADAdBgNVHQ4EFgQUuhbZbU2FL3MpdpovdYxqII+eyG8wHwYDVR0jBBgwFoAU
# 7NfjgtJxXWRM3y5nP+e6mK4cD08wDgYDVR0PAQH/BAQDAgGGMBMGA1UdJQQMMAoG
# CCsGAQUFBwMIMHcGCCsGAQUFBwEBBGswaTAkBggrBgEFBQcwAYYYaHR0cDovL29j
# c3AuZGlnaWNlcnQuY29tMEEGCCsGAQUFBzAChjVodHRwOi8vY2FjZXJ0cy5kaWdp
# Y2VydC5jb20vRGlnaUNlcnRUcnVzdGVkUm9vdEc0LmNydDBDBgNVHR8EPDA6MDig
# NqA0hjJodHRwOi8vY3JsMy5kaWdpY2VydC5jb20vRGlnaUNlcnRUcnVzdGVkUm9v
# dEc0LmNybDAgBgNVHSAEGTAXMAgGBmeBDAEEAjALBglghkgBhv1sBwEwDQYJKoZI
# hvcNAQELBQADggIBAH1ZjsCTtm+YqUQiAX5m1tghQuGwGC4QTRPPMFPOvxj7x1Bd
# 4ksp+3CKDaopafxpwc8dB+k+YMjYC+VcW9dth/qEICU0MWfNthKWb8RQTGIdDAiC
# qBa9qVbPFXONASIlzpVpP0d3+3J0FNf/q0+KLHqrhc1DX+1gtqpPkWaeLJ7giqzl
# /Yy8ZCaHbJK9nXzQcAp876i8dU+6WvepELJd6f8oVInw1YpxdmXazPByoyP6wCeC
# RK6ZJxurJB4mwbfeKuv2nrF5mYGjVoarCkXJ38SNoOeY+/umnXKvxMfBwWpx2cYT
# gAnEtp/Nh4cku0+jSbl3ZpHxcpzpSwJSpzd+k1OsOx0ISQ+UzTl63f8lY5knLD0/
# a6fxZsNBzU+2QJshIUDQtxMkzdwdeDrknq3lNHGS1yZr5Dhzq6YBT70/O3itTK37
# xJV77QpfMzmHQXh6OOmc4d0j/R0o08f56PGYX/sr2H7yRp11LB4nLCbbbxV7HhmL
# NriT1ObyF5lZynDwN7+YAN8gFk8n+2BnFqFmut1VwDophrCYoCvtlUG3OtUVmDG0
# YgkPCr2B2RP+v6TR81fZvAT6gt4y3wSJ8ADNXcL50CN/AAvkdgIm2fBldkKmKYcJ
# RyvmfxqkhQ/8mJb2VVQrH4D6wPIOK+XW+6kvRBVK5xMOHds3OBqhK/bt1nz8MIIG
# wDCCBKigAwIBAgIQDE1pckuU+jwqSj0pB4A9WjANBgkqhkiG9w0BAQsFADBjMQsw
# CQYDVQQGEwJVUzEXMBUGA1UEChMORGlnaUNlcnQsIEluYy4xOzA5BgNVBAMTMkRp
# Z2lDZXJ0IFRydXN0ZWQgRzQgUlNBNDA5NiBTSEEyNTYgVGltZVN0YW1waW5nIENB
# MB4XDTIyMDkyMTAwMDAwMFoXDTMzMTEyMTIzNTk1OVowRjELMAkGA1UEBhMCVVMx
# ETAPBgNVBAoTCERpZ2lDZXJ0MSQwIgYDVQQDExtEaWdpQ2VydCBUaW1lc3RhbXAg
# MjAyMiAtIDIwggIiMA0GCSqGSIb3DQEBAQUAA4ICDwAwggIKAoICAQDP7KUmOsap
# 8mu7jcENmtuh6BSFdDMaJqzQHFUeHjZtvJJVDGH0nQl3PRWWCC9rZKT9BoMW15GS
# OBwxApb7crGXOlWvM+xhiummKNuQY1y9iVPgOi2Mh0KuJqTku3h4uXoW4VbGwLpk
# U7sqFudQSLuIaQyIxvG+4C99O7HKU41Agx7ny3JJKB5MgB6FVueF7fJhvKo6B332
# q27lZt3iXPUv7Y3UTZWEaOOAy2p50dIQkUYp6z4m8rSMzUy5Zsi7qlA4DeWMlF0Z
# Wr/1e0BubxaompyVR4aFeT4MXmaMGgokvpyq0py2909ueMQoP6McD1AGN7oI2TWm
# tR7aeFgdOej4TJEQln5N4d3CraV++C0bH+wrRhijGfY59/XBT3EuiQMRoku7mL/6
# T+R7Nu8GRORV/zbq5Xwx5/PCUsTmFntafqUlc9vAapkhLWPlWfVNL5AfJ7fSqxTl
# OGaHUQhr+1NDOdBk+lbP4PQK5hRtZHi7mP2Uw3Mh8y/CLiDXgazT8QfU4b3ZXUtu
# MZQpi+ZBpGWUwFjl5S4pkKa3YWT62SBsGFFguqaBDwklU/G/O+mrBw5qBzliGcnW
# hX8T2Y15z2LF7OF7ucxnEweawXjtxojIsG4yeccLWYONxu71LHx7jstkifGxxLjn
# U15fVdJ9GSlZA076XepFcxyEftfO4tQ6dwIDAQABo4IBizCCAYcwDgYDVR0PAQH/
# BAQDAgeAMAwGA1UdEwEB/wQCMAAwFgYDVR0lAQH/BAwwCgYIKwYBBQUHAwgwIAYD
# VR0gBBkwFzAIBgZngQwBBAIwCwYJYIZIAYb9bAcBMB8GA1UdIwQYMBaAFLoW2W1N
# hS9zKXaaL3WMaiCPnshvMB0GA1UdDgQWBBRiit7QYfyPMRTtlwvNPSqUFN9SnDBa
# BgNVHR8EUzBRME+gTaBLhklodHRwOi8vY3JsMy5kaWdpY2VydC5jb20vRGlnaUNl
# cnRUcnVzdGVkRzRSU0E0MDk2U0hBMjU2VGltZVN0YW1waW5nQ0EuY3JsMIGQBggr
# BgEFBQcBAQSBgzCBgDAkBggrBgEFBQcwAYYYaHR0cDovL29jc3AuZGlnaWNlcnQu
# Y29tMFgGCCsGAQUFBzAChkxodHRwOi8vY2FjZXJ0cy5kaWdpY2VydC5jb20vRGln
# aUNlcnRUcnVzdGVkRzRSU0E0MDk2U0hBMjU2VGltZVN0YW1waW5nQ0EuY3J0MA0G
# CSqGSIb3DQEBCwUAA4ICAQBVqioa80bzeFc3MPx140/WhSPx/PmVOZsl5vdyipjD
# d9Rk/BX7NsJJUSx4iGNVCUY5APxp1MqbKfujP8DJAJsTHbCYidx48s18hc1Tna9i
# 4mFmoxQqRYdKmEIrUPwbtZ4IMAn65C3XCYl5+QnmiM59G7hqopvBU2AJ6KO4ndet
# Hxy47JhB8PYOgPvk/9+dEKfrALpfSo8aOlK06r8JSRU1NlmaD1TSsht/fl4JrXZU
# inRtytIFZyt26/+YsiaVOBmIRBTlClmia+ciPkQh0j8cwJvtfEiy2JIMkU88ZpSv
# XQJT657inuTTH4YBZJwAwuladHUNPeF5iL8cAZfJGSOA1zZaX5YWsWMMxkZAO85d
# NdRZPkOaGK7DycvD+5sTX2q1x+DzBcNZ3ydiK95ByVO5/zQQZ/YmMph7/lxClIGU
# gp2sCovGSxVK05iQRWAzgOAj3vgDpPZFR+XOuANCR+hBNnF3rf2i6Jd0Ti7aHh2M
# WsgemtXC8MYiqE+bvdgcmlHEL5r2X6cnl7qWLoVXwGDneFZ/au/ClZpLEQLIgpzJ
# GgV8unG1TnqZbPTontRamMifv427GFxD9dAq6OJi7ngE273R+1sKqHB+8JeEeOMI
# A11HLGOoJTiXAdI/Otrl5fbmm9x+LMz/F0xNAKLY1gEOuIvu5uByVYksJxlh9ncB
# jDGCBQAwggT8AgEBMCowFjEUMBIGA1UEAwwLSmltQnJpZ0RldnQCEG9HEsiy2yiS
# QUWBLSa68JswDQYJYIZIAWUDBAIBBQCggYQwGAYKKwYBBAGCNwIBDDEKMAigAoAA
# oQKAADAZBgkqhkiG9w0BCQMxDAYKKwYBBAGCNwIBBDAcBgorBgEEAYI3AgELMQ4w
# DAYKKwYBBAGCNwIBFTAvBgkqhkiG9w0BCQQxIgQgvkCFDQl4ctEQSHXfxjwvfC1i
# lXeDJlP8O/TA8T9QeAUwDQYJKoZIhvcNAQEBBQAEggEAYdQ70ldu1QA5ZxUjSz2h
# wrF3dY/oznzMJEPwtY/DO8n6zTzB+MoHHtf5LDLi8wBk2EBUrODE+cqQVa7Ubo00
# IHYyJq8nxUfzX1YDkQqAqY2UVq7XqIYr/amm0JSDdHBj4dEtcLn+1x5jdnZ9TDlE
# mVzWsOJaEtWzUeOkB/0IajZzrDR/pRxi2ZjUNDtx6BVzVGxZsi9poQGyep09tqtf
# M89ji0jI3jXRt6pigrLO+K47NKmeZkf60AU7UKOQWfXel4MbM9Gz5mLb3AP2DlJP
# 4vSrr7vMTSZueqh1VrCVrCwGk/gMrnRaXBouUVb4sz3egrnseuHM4pa7KItkzBoG
# 9aGCAyAwggMcBgkqhkiG9w0BCQYxggMNMIIDCQIBATB3MGMxCzAJBgNVBAYTAlVT
# MRcwFQYDVQQKEw5EaWdpQ2VydCwgSW5jLjE7MDkGA1UEAxMyRGlnaUNlcnQgVHJ1
# c3RlZCBHNCBSU0E0MDk2IFNIQTI1NiBUaW1lU3RhbXBpbmcgQ0ECEAxNaXJLlPo8
# Kko9KQeAPVowDQYJYIZIAWUDBAIBBQCgaTAYBgkqhkiG9w0BCQMxCwYJKoZIhvcN
# AQcBMBwGCSqGSIb3DQEJBTEPFw0yMzAzMTMwMDI2NDFaMC8GCSqGSIb3DQEJBDEi
# BCC4TCGxmSqKUhoCUe4kex+15xRjdgzYFm43J0clqUfXZzANBgkqhkiG9w0BAQEF
# AASCAgAVCU6d0ZC6k0fSWPyBp/1xW67MCnj1R8LDT7sOUTQl1ASd4PtZoBPr/77/
# Ms1wLBEflUMb4ako5BPEOjgZa0du557wUdKCCozsnNp9+9IgVcduh5QSfYKHQ1Tl
# Izi/WhfXiL+1LvjacOxdapNXQGrEd0ifVsbXZLajD5WcOUaghINIBdH4jF0xkU8c
# LHNG57cu3nkKcU946MVDxEI3PeitDbEXKC2FBf9jMekHpAI8XS/3qHHhH/37I+lL
# G9O2mxQu2ZIDUqBlLhbZJPsWYnbQEeTBn+qXWht2VYxMjrnlLhCjwKWRVZ2Prq9W
# uhcWbaY6lxvAyV9hRaqRuz4QTo5OH/hr682jfP1WyS9xTY79ar1zsds+yb9GnKH7
# uadm6AnzZTCCC2H5AsO4m1pumNSdVs6v6eJJycBl0/cBfn1uaG5rBQDh3nSbzc3x
# ZJKuAAyci1BioB7cBUPfPyE2CI/CR6PW+VEO+SrgLw8NECtqUAC7PtteWj5Ahhen
# a7Q3N5JLQ1/GmJSVEmx8id1x3A715BByf/bCwR8KzGRxabz8Z1QdJaQ9qAs24p85
# n8lus/sZ9K9l1n3ZfX29cYofLRQsFMxUyz8xIhBjapQxvq9J36BjzBJTh/bw5DKU
# tBfmFcmyywqxQucq9WmkTs9C/KGWVwXG+f+VJZ5U3/qF9uEd7A==
# SIG # End signature block
