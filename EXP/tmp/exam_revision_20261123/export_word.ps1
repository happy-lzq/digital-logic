[Console]::OutputEncoding = [System.Text.UTF8Encoding]::new()
$ErrorActionPreference = 'Stop'
$examOutputDir = Join-Path $PSScriptRoot 'output'
$examWordApp = New-Object -ComObject Word.Application
$examWordApp.Visible = $false
$examWordApp.DisplayAlerts = 0
$examWordApp.ScreenUpdating = $false
$examExportResults = @()
try {
    foreach ($examFileName in @('数字逻辑_期末试卷_A卷_2026版.docx','数字逻辑_期末试卷_A卷_2026版_参考答案.docx')) {
        $examDocPath = Join-Path $examOutputDir $examFileName
        $examPdfPath = [IO.Path]::ChangeExtension($examDocPath,'.pdf')
        $examWordDoc = $examWordApp.Documents.Open($examDocPath,$false,$false,$false)
        try {
            $null = $examWordDoc.Fields.Update()
            foreach ($examSection in $examWordDoc.Sections) {
                foreach ($examHeader in $examSection.Headers) { $null = $examHeader.Range.Fields.Update() }
                foreach ($examFooter in $examSection.Footers) { $null = $examFooter.Range.Fields.Update() }
            }
            $examWordDoc.Repaginate()
            $null = $examWordDoc.Fields.Update()
            $examWordDoc.Save()
            $examPageCount = $examWordDoc.ComputeStatistics(2)
            $examWordDoc.ExportAsFixedFormat($examPdfPath,17)
            $examExportResults += [PSCustomObject]@{File=$examFileName;Pages=$examPageCount;PDF=$examPdfPath}
        } finally {
            $examWordDoc.Close(0)
            [void][Runtime.InteropServices.Marshal]::FinalReleaseComObject($examWordDoc)
        }
    }
} finally {
    $examWordApp.Quit()
    [void][Runtime.InteropServices.Marshal]::FinalReleaseComObject($examWordApp)
}
$examExportResults | ConvertTo-Json

