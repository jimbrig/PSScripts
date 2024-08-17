#Requires -Module Pester -Version 5.0

# Import the script containing the function
. "$PSScriptRoot\Set-FolderIcon.ps1"

Describe "Set-FolderIcon Function Tests" -Tags "Unit" {

  # Define a temporary directory for testing
  $tempDir = Join-Path -Path $env:TEMP -ChildPath "SetFolderIconTest"

  # Cleanup temp directory before each test
  BeforeEach {
    if (Test-Path $tempDir) {
      Remove-Item -Recurse -Force $tempDir
    }
    New-Item -ItemType Directory -Force -Path $tempDir | Out-Null
  }

  # Remove temp directory after all tests
  AfterAll {
    if (Test-Path $tempDir) {
      Remove-Item -Recurse -Force $tempDir
    }
  }

  It "Should throw an error if the icon path does not exist" {
    {
      Set-FolderIcon -Icon "C:\NonExistentPath\icon.ico" -Path $tempDir
    } | Should -Throw -ErrorId "Error"
  }

  It "Should throw an error if the directory path does not exist" {
    {
      Set-FolderIcon -Icon "C:\Windows\System32\shell32.dll,0" -Path "C:\NonExistentPath"
    } | Should -Throw -ErrorId "Error"
  }

  It "Should create a desktop.ini file in the target directory" {
    $iconPath = "$env:SystemRoot\System32\shell32.dll,0"
    Set-FolderIcon -Icon $iconPath -Path $tempDir

    Test-Path "$tempDir\desktop.ini" | Should -Be $true
  }

  It "Should set the desktop.ini file with the correct content" {
    $iconPath = "$env:SystemRoot\System32\shell32.dll,0"
    Set-FolderIcon -Icon $iconPath -Path $tempDir

    $content = Get-Content "$tempDir\desktop.ini"
    $content | Should -Contain "[.ShellClassInfo]"
    $content | Should -Contain "IconResource=$iconPath"
  }

  It "Should set the desktop.ini file as hidden and system" {
    $iconPath = "$env:SystemRoot\System32\shell32.dll,0"
    Set-FolderIcon -Icon $iconPath -Path $tempDir

    $attributes = (Get-Item "$tempDir\desktop.ini" -Force).Attributes
    $attributes | Should -Contain "Hidden"
    $attributes | Should -Contain "System"
  }

  It "Should set the directory as read-only" {
    $iconPath = "$env:SystemRoot\System32\shell32.dll,0"
    Set-FolderIcon -Icon $iconPath -Path $tempDir

    $attributes = (Get-Item $tempDir -Force).Attributes
    $attributes | Should -Contain "ReadOnly"
  }

  It "Should apply the icon to subdirectories when -Recurse is used" {
    $subDir1 = New-Item -ItemType Directory -Force -Path "$tempDir\SubDir1"
    $subDir2 = New-Item -ItemType Directory -Force -Path "$tempDir\SubDir2"
    $iconPath = "$env:SystemRoot\System32\shell32.dll,0"

    Set-FolderIcon -Icon $iconPath -Path $tempDir -Recurse

    Test-Path "$subDir1\desktop.ini" | Should -Be $true
    Test-Path "$subDir2\desktop.ini" | Should -Be $true
  }

  It "Should not apply the icon to subdirectories when -Recurse is not used" {
    $subDir1 = New-Item -ItemType Directory -Force -Path "$tempDir\SubDir1"
    $subDir2 = New-Item -ItemType Directory -Force -Path "$tempDir\SubDir2"
    $iconPath = "$env:SystemRoot\System32\shell32.dll,0"

    Set-FolderIcon -Icon $iconPath -Path $tempDir

    Test-Path "$subDir1\desktop.ini" | Should -Be $false
    Test-Path "$subDir2\desktop.ini" | Should -Be $false
  }
}
