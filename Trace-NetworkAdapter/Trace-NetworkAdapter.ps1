
<#PSScriptInfo

.VERSION 1.0.0

.GUID ef0c9f0a-166e-44d4-8654-30b38293ee82

.AUTHOR Jimmy Briggs

.COMPANYNAME jimbrig

.COPYRIGHT Jimmy Briggs | 2023

.TAGS Monitor Network Adapter Connection

.LICENSEURI https://github.com/jimbrig/PSScripts/blob/main/LICENSE

.PROJECTURI https://github.com/jimbrig/PSScripts/tree/main/Trace-NetworkAdapter/

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
    Monitor a network adapter's connection every second and log the timestamp it is found disconnected.

  .DESCRIPTION 
    Monitor a network adapter's connection every second and log the timestamp it is found disconnected. 

  .NOTES
  ## Codes

  - Disconnected=0,
  - Connecting=1,
  - Connected=2,
  - Disconnecting=3,
  - Hardware_Not_present=4,
  - Hardware_disabled=5,
  - Hardware_malfunction=6,
  - Media_disconnected=7,
  - Authenticating=8,
  - Authentication_succeeded=9,
  - Authentication_failed=10,
  - Invalid_address=11,
  - Credentials_required=12

#> 
[CmdletBinding()]
Param()

Write-Host " _____     _   _____   _         _              _____         _ _           
|   | |___| |_|  _  |_| |___ ___| |_ ___ ___   |     |___ ___|_| |_ ___ ___ 
| | | | -_|  _|     | . | .'| . |  _| -_|  _|  | | | | . |   | |  _| . |  _|
|_|___|___|_| |__|__|___|__,|  _|_| |___|_|    |_|_|_|___|_|_|_|_| |___|_|  
                            |_|                                             
                            "
Write-Host "This script is used to monitor a network adapter's connection every second, and then log the date and time the second it is found to be disconnected."
Write-Host ""

$script:time = Get-Date -Format HH:mm:ss

Function getAdapters {
  #Variable that allows us to loop through and get all adapters with 'Wi' in the name.
  $adapters = Get-CimInstance -Class Win32_NetworkAdapter | Select-Object Name, deviceID, NetConnectionStatus

  #Loop through adapters and create/update variables for each one.
  foreach ($adapter in $adapters) {
    Set-Variable -Name "$($adapter.deviceID) : Adapter:$($adapter.Name)" -Value $adapter.NetConnectionStatus -Scope script #create variable
  }
}

#Function to calculate time left from total seconds provided
Function getTimeLeft ($n) {
  $day = ($n / (24 * 3600))
    
  $n = $n % (24 * 3600)
  $hour = $n / 3600

  $n %= 3600
  $minutes = $n / 60

  $n %= 60
  $seconds = $n

  $daysLeft = [Math]::Floor($day)
  $hoursleft = [Math]::Floor($hour)
  $minutesLeft = [Math]::Floor($minutes)

  if ($daysLeft -ge 1) {
    return "Remaining: Day:$daysLeft Hr:$hoursLeft Min:$minutesLeft Sec:$seconds."
  }
  if ($hoursLeft -ge 1) {
    return "Remaining: Hr:$hoursLeft Min:$minutesLeft Sec:$seconds."
  }
  if ($minutesLeft -ge 1) {
    return "Remaining: Min:$minutesLeft Sec:$seconds."
  }
    
  return "Remaining: Sec:$seconds."
}

$script:monitorCount = 1 #Variable to track step in animation
$script:incline = $true #Variable to track direction animation should go in
#Function to update animation
Function monitorAnimation {

  if ($monitorCount -eq 1) {
    Write-Host "|" -ForegroundColor Yellow -NoNewline;
    Write-Host "-   |" -NoNewline
    $script:incline = $true
    if ($incline) {
      $script:monitorCount += 1
    }
    else {
      $script:monitorCount -= 1
    }
    return
  }
  if ($monitorCount -eq 2) {
    Write-Host "| -  |" -NoNewline
    if ($incline) {
      $script:monitorCount += 1
    }
    else {
      $script:monitorCount -= 1
    }
    return
  }
  if ($monitorCount -eq 3) {
    Write-Host "|  - |" -NoNewline
    if ($incline) {
      $script:monitorCount += 1
    }
    else {
      $script:monitorCount -= 1
    }
    return
  }
  if ($monitorCount -eq 4) {
    Write-Host "|   -" -NoNewline
    Write-Host "|" -ForegroundColor Green -NoNewline
    $script:incline = $false
    $script:monitorCount -= 1
    return
  }
}

#Get wifi adapters and create/update variables made from them.
getAdapters

#Variable that will allow us to loop through the variables we made in the function getAdapters
$adapterVariables = Get-Variable -Name "*Adapter*"

#List available network adapter variables for selection
foreach ($adap in $adapterVariables) {
  if ($($adap.value) -eq 2) {
    Write-Host "$($adap.Name) is connected!" -ForegroundColor Green
  }
  else {
    Write-Host "$($adap.Name) is disconnected..." -ForegroundColor Red
  }
}

Write-Host ""

#Get user input for monitoring
$answer = Read-Host "Select an adapter to monitor. (Enter the number seen before 'Adapter')"
Write-Host ""
$answer2 = Read-Host "How long will we monitor? (Answer in minutes)"
Write-Host ""

try {
  $script:monitorLength = [int]$answer2 * 60
}
catch {
  Write-Host "Invalid input for time to wait."
  Write-Host ""
  break
}

#Check input and begin monitoring if necessary
if (-not(Get-Variable -Name "$answer :*")) {
  Write-Host "Invalid adpater selection."
  Write-Host ""
  break
}
else {
  $adapter = Get-Variable -Name "$answer :*" #Get variable that corresponds with our answer
  if (-not($adapter.Value -eq 2)) {
    Write-Host "Device is disconnected. No monitoring necessary."
    Write-Host ""
    break
  }
  else {
    Write-Host "Monitoring $($adapter.Name)."
    Write-Host "Monitoring will begin in 5 seconds and check every second for connection status."
    Write-Host ""
    Start-Sleep 5
  }
}

$script:reconnectTime = $null
$script:disconnectTime = $null
#Function to update results txt file with disconnect info.
Function logConnection ($connectionStart) {
    
  if (-not($null -eq (Get-Variable -Name "$answer :*"))) {
    #Get current user's documents folder
    $userDocuments = [Environment]::GetFolderPath("MyDocuments")
    # Write-Host "$userDocuments"
    $script:resultsDir = "$userDocuments\AdapterMonitorResults"
    $script:resultsTxtPath = "$resultsDir\AdapterMonitorResults.txt"
    
    #If directory already exists
    if (Test-Path $resultsDir) {
      if (-not(Test-Path $resultsTxtPath -PathType leaf)) {
        New-item -Path $resultsDir -Name "AdapterMonitorResults.txt" -ItemType "file" | Out-Null
      }
    }
    else {
      #Make the directory and the txt file
      mkdir $resultsDir | Out-Null
      New-item -Path $resultsDir -Name "AdapterMonitorResults.txt" -ItemType "file" | Out-Null
    }
    
    $adapter = Get-Variable -Name "$answer :*"

    if ($connectionStart) {
      Add-Content -Path $resultsTxtPath -Value "Monitoring started on $($adapter.Name) at $(Get-Date)."
    }

    if ($disconnectCounter -ge 1 -AND $connected) {
      $script:reconnectTime = Get-Date
      $timeWhileDisconnected = New-TimeSpan -Start $disconnectTime -End $reconnectTime
      $timeWhileDisconnected = $timeWhileDisconnected.ToString("dd' days 'hh' hours 'mm' minutes and 'ss' seconds'")
      Write-Host "Reconnected at $time." -ForegroundColor Green
      Add-Content -Path $resultsTxtPath -Value "`n$($adapter.Name) reconnected at $(Get-Date)."
      Add-Content -Path $resultsTxtPath -Value "Disconnected for $timeWhileDisconnected"
    }

    if ($disconnectCounter -eq 1) {
      $script:disconnectTime = Get-Date
      Write-Host "Disconnected at $time." -ForegroundColor Red
      Add-Content -Path $resultsTxtPath -Value "`n$($adapter.Name) disconnected at $(Get-Date)."
    }
  }
}

$script:disconnectCounter = 0
$script:startMonitor = $false
$script:connected = $false
#Function to update adapter NetConenctionStatus values and show status in terminal
Function monitorAdapter {
  $timeLeft = getTimeLeft($monitorLength)
  getAdapters #update wifi adapter variables for next loop through

  $adapterValue = Get-Variable -Name "$answer :*" -ValueOnly

  #If connected, reset disconnect counter and update animation and adapter variables
  if ($adapterValue -eq 2) {
    $script:connected = $true
    Write-Host "Connected" -ForegroundColor Green -NoNewline
    Write-Host " Ctrl+C to QUIT"
    monitorAnimation
    Write-Host "$timeLeft"
    Write-Host ""
    logConnection
    $script:disconnectCounter = 0
  }

  #If disconnected, update disconnect counter, log connection info if necessary, and update adapter variables
  if (-not($adapterValue -eq 2)) {
    $script:connected = $false
    $script:disconnectCounter += 1
    Write-Host "Disconnected." -ForegroundColor Red -NoNewline
    Write-Host " Ctrl+C to QUIT"
    Write-Host "|" -ForegroundColor Red -NoNewline; Write-Host "-XX-" -ForegroundColor Yellow -NoNewline; Write-Host "|" -ForegroundColor Red -NoNewline;
    Write-Host "$timeLeft"
    Write-Host ""
    logConnection
  }
}

#If a variable coresponds with answer (it's not null), run the while loop
if (-not($null -eq (Get-Variable -Name "$answer :*"))) {

  #We've started monitoring, so log monitor start
  logConnection($connectionStart = $true)
  $script:startMonitor = $true

  while ($script:startMonitor) {

    monitorAdapter
    $script:monitorLength -= 1

    #If monitor length time expires end the loop
    if ($script:monitorLength -le 0) {
      $script:startMonitor = $false
      break
    }

    Start-Sleep 1
  }
}

Write-Host ""
Write-Host "Results have been saved to a txt file at $script:resultsTxtPath."
Write-Host ""
    
Start-Process explorer $script:resultsDir

# SIG # Begin signature block
# MIIbsQYJKoZIhvcNAQcCoIIbojCCG54CAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCAvN+gi4WKEXfu4
# Ypn6aftTyeEAte/6URgZQcxro9bUd6CCFgcwggL8MIIB5KADAgECAhBvRxLIstso
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
# DAYKKwYBBAGCNwIBFTAvBgkqhkiG9w0BCQQxIgQgmU+iDQTYUfKpNIK1y9zYYgQj
# Pw0PKmxBMAH6JJMkczUwDQYJKoZIhvcNAQEBBQAEggEAXapdUAaSYAWvIvjiOM7E
# utd0AYS9dcjy3CQfJ1nTbMjU5cElLS5We0Z1C1964vqTgj5yiZdBURSICxVzcYrE
# WKX7uXMSbsgZqlxIQWWXlT/YA7pg5dJiOwU+Ex2KrSc7ghbTD+JhvPTtUqok/1mT
# mTwNhMsBsgDFpCUA9A8DNOywYPPvB2PD7lVq/4W3qLHiMDl66dj4eQUG4pgRcc2t
# FAamJGDc+5NooCi9eIO16+6hZZih0bsa7iHbJvHoMNMNU3qs+peRLec3MRJW+9If
# KYat0UkJsPhwRHAjEu8bZdPMkmC9lfql1VkAcWYTtiR2q6sMkv8oqZSkG/h841Il
# dqGCAyAwggMcBgkqhkiG9w0BCQYxggMNMIIDCQIBATB3MGMxCzAJBgNVBAYTAlVT
# MRcwFQYDVQQKEw5EaWdpQ2VydCwgSW5jLjE7MDkGA1UEAxMyRGlnaUNlcnQgVHJ1
# c3RlZCBHNCBSU0E0MDk2IFNIQTI1NiBUaW1lU3RhbXBpbmcgQ0ECEAxNaXJLlPo8
# Kko9KQeAPVowDQYJYIZIAWUDBAIBBQCgaTAYBgkqhkiG9w0BCQMxCwYJKoZIhvcN
# AQcBMBwGCSqGSIb3DQEJBTEPFw0yMzAzMTMwMDI3MThaMC8GCSqGSIb3DQEJBDEi
# BCDUmSPno4DePTnm9+bzdbRV3/f0hLeWgxOZhs8VVjVEtjANBgkqhkiG9w0BAQEF
# AASCAgB7039TPoMbIaMszD5D2kBquKfDsnMuiK066Q2OYtCD8e5gkWSSET3Q8fwG
# E0GVD5yHOv18CtpJGQuMPcqf+4uEuDnzB8fZ+2uyK6xhVFEMfRcnUyAK3UbMVb2V
# O8d9QR1/HW4oJ2zjGQA59ITLz30zRMb+gr33qsLgPwMKgvwjCfMlsfPkYUm4rceo
# 3fdvBd1/obIE5JaivqB9TY+cZcq9NyCE+OgIW5bXLfPRjLSWo9V0+QY+OAhwkkRJ
# DBabhddwOAbSrBlp3oBeUYNZ38B6eR6GaZIsXcP/ksAJ+CUABJ8ohO+SgIzbB1pz
# zCT12QYjhy07KUCS2v1Yy9nlr6pn1CN/MC6rAKNYD5fRI9anqahQYdxGT1DAT1zA
# /himqcZx866QIWITSj/azhVf/yMrphP2FPXxdWbzIgwXiJ3+0kmohEt98gFqARH5
# d0EJflx5mqN/b4vs+tntsH/m50GTAPoFTwIrLtkJGC3z/at2VBXi0RJSvcDWgu1S
# M4QpXcEVlRa7y+kotzrf5dyryA3gSOJDwCLNd+r+cfOqsuvRzU1Lc4LDvPRnwWPU
# ZxTsJP9sckg5qqhc2Zbj5S8RBTMoT5CdPSj3551K50pJ29mbS8EthfupOxeAfkgT
# vauZLT9WgC5RXVYhETqDiAvpM6oMOfUHj+CPKzl2lz4NXzUoHA==
# SIG # End signature block
