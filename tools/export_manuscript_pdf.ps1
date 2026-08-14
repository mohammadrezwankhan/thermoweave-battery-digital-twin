$ErrorActionPreference = 'Stop'
$projectRoot = Split-Path -Parent $PSScriptRoot
$documentPath = Join-Path $projectRoot 'manuscript\ThermoWeave_3D_Manuscript.docx'
$pdfPath = Join-Path $projectRoot 'manuscript\ThermoWeave_3D_Manuscript.pdf'
$word = New-Object -ComObject Word.Application
$word.Visible = $false
$word.DisplayAlerts = 0
try {
    $document = $word.Documents.Open($documentPath, $false, $true)
    $document.ExportAsFixedFormat($pdfPath, 17)
    $document.Close($false)
}
finally {
    $word.Quit()
}
Get-Item -LiteralPath $pdfPath | Select-Object FullName,Length,LastWriteTime
