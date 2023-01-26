Install-Module EZOut -AllowClobber -Scope CurrentUser
Install-Module ImportExcel -AllowClobber -Scope CurrentUser

Import-Excel $Path | Format-Markdown



Function ConvertFrom-ExcelToMarkdown {

    <#
    .SYNOPSIS
        Converts an Excel xlsx file's content (table, sheet, etc.) to a Markdown Table.
    .DESCRIPTION
        Authoring tables in Markdown can be a little tedious, so with this tool you can maintain your table in excel 
        and convert it to a Markdown table.
    .EXAMPLE
        ConvertFrom-ExcelToMarkdown
    
    .PARAMETER WorkbookPath
        Points to the location of the Excel Workbook.
    .PARAMETER Worksheet
        Determines which of the sheets will be used to extract the data.
    .PARAMETER OutputPath
        Determines where the output file will be saved.    

    #>
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory = $True, Position = 0)]
        [string]$WorkbookPath,
        [Parameter(Mandatory = $False, Position = 1)]
        [string]$Worksheet = 1,
        [Parameter(Mandatory = $False, Position = 2)]
        [string]$OutputPath
    )



}

function Import-ExcelSpreadSheet {
    <#
    .SYNOPSIS
      Converts an Excel xlsx file to either CSV or a Markdown Table
    .DESCRIPTION
      Authoring tables in Markdown can be a little tedious, so with this
      tool you can maintain your table in excel and convert it to either
      markdown or CSV format
    .EXAMPLE
      Import-ExcelSpreadSheet
      This will seek for a default file path of C:\test\Book1.xlsx and
      using the default spreadsheet name of Sheet1 will convert the
      Spreadsheet into a Markdown table
    .EXAMPLE
      Import-ExcelSpreadSheet -Format Csv
      This will seek for a default file path of C:\test\Book1.xlsx and
      using the default spreadsheet name of Sheet1 will convert the
      Spreadsheet into a CSV formatted output
    .EXAMPLE
      Import-ExcelSpreadSheet -ExcelFilePath c:\test\table.xlsx -SpreadSheetName Sheet2 -Format Markdowntable
      This will use the file path of C:\test\table.xlsx and using the
      spreadsheet name of Sheet2 will convert the spreadsheet into
      a Markdown table output
    .PARAMETER ExcelFilePath
      Points to the location of the Excel spreadsheet
    .PARAMETER SpreadSheetName
      Determines which of the sheets will be used to extract the data
    .PARAMETER Format
      Gives the choice either MarkdownTable or CSV output
    .NOTES
      General notes
        Created By: Brent Denny
        Created On: 28-Apr-2022
        Last Modified: 01-May-2022
      ChangeLog
        Version Date Details
        ------- ---- -------
         v0.0.0 28-Apr-2022 Created initial concept
         v0.1.0 01-May-2022 Added the formatting code to convert to csv or markdown
    #>
    Param (
      [string]$ExcelFilePath = 'C:\test\Book1.xlsx',
      [string]$SpreadSheetName = 'Sheet1',
      [ValidateSet('MarkdownTable','CSV')]
      [string]$Format = 'MarkdownTable'
    )
    
    function Convert-CsvToMarkdownTable {
      Param ([string[]]$CSV)
      $Header = ($CSV[0]) -replace '\,','|' -replace '"',''
      $TableLine = ($CSV[0]) -replace '\,','|' -replace '"','' -replace '[^|]+','---'
      $TableData = ($CSV ) -replace '\,','|' -replace '"','' | Select-Object -Skip 1
      Write-Output $Header
      Write-Output $TableLine
      Write-Output $TableData
    }
  
    if (Test-Path -Path $ExcelFilePath) {
      [array]$ConvertedObj = New-Object -TypeName psobject
      $ExcelObj  = New-Object -ComObject 'Excel.Application'
      $Workbook  = $ExcelObj.Workbooks.Open($ExcelFilePath)
      $WorkSheet = $Workbook.Sheets.Item($SpreadSheetName)
      $Cells     = $WorkSheet.Cells
      $ColumnPos = 0
      $KeyPath = 'HKCU:\Software\Microsoft\Internet Explorer\Main'
      try {
        if ((Test-Path $KeyPath) -eq $false) {New-Item $KeyPath -force -ErrorAction stop}
        Set-ItemProperty -Path $KeyPath -Name 'DisableFirstRunCustomize' -Value 1 -ErrorAction Stop
      }
      catch {break}
      [string[]]$Headers = @()
      do {
        $ColumnPos++
        If ($Cells[1,$ColumnPos].Text -ne '') {$Headers += $Cells[1,$ColumnPos].Text}
        else { break }
      } while ($Cells[1,$ColumnPos].Text -ne '')
      $Row = 2
      do {
        $ColNum = 0
        $HashTable = [System.Collections.Specialized.OrderedDictionary]::new()
        foreach ($Header in $Headers) {
          $ColNum++
          $Value = $Cells[$Row,$ColNum].Text
          $HashTable.Add($Header,$Value)
        }
        $RowObject = New-Object -TypeName psobject -Property $HashTable
        if ($Row -eq 2) {$ConvertedObj = $RowObject } 
        else {$ConvertedObj += $RowObject }
        $Row++
      } until ($Cells[$Row,1].Text -eq '')
      $Output = if ($Format -eq 'CSV') {$ConvertedObj | ConvertTo-Csv -NoTypeInformation} 
                elseif ($Format -eq 'MarkdownTable') { Convert-CsvToMarkdownTable -CSV ($ConvertedObj | ConvertTo-Csv -NoTypeInformation) }
      return ($Output) 
    }
  }