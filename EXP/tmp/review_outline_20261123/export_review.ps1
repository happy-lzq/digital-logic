[Console]::OutputEncoding = [System.Text.UTF8Encoding]::new()
$ErrorActionPreference = 'Stop'
$reviewDocx = 'C:\suat\ljl-digital\digital-logic-materials\EXP\output\review_20261123\数字逻辑_期末复习提纲_2026版.docx'
$reviewPdf = [IO.Path]::ChangeExtension($reviewDocx,'.pdf')
$reviewWord = New-Object -ComObject Word.Application
$reviewWord.Visible = $false
$reviewWord.DisplayAlerts = 0
$reviewWord.ScreenUpdating = $false
try {
    $reviewDocument = $reviewWord.Documents.Open($reviewDocx,$false,$false,$false)
    try {
        $null = $reviewDocument.Fields.Update()
        foreach ($reviewSection in $reviewDocument.Sections) {
            foreach ($reviewFooter in $reviewSection.Footers) {
                $null = $reviewFooter.Range.Fields.Update()
            }
        }
        $reviewDocument.Repaginate()
        $reviewPages = $reviewDocument.ComputeStatistics(2)
        $reviewDocument.Save()
        $reviewDocument.ExportAsFixedFormat($reviewPdf,17)
        [PSCustomObject]@{Docx=$reviewDocx;PDF=$reviewPdf;Pages=$reviewPages} | ConvertTo-Json
    } finally {
        $reviewDocument.Close(0)
        [void][Runtime.InteropServices.Marshal]::FinalReleaseComObject($reviewDocument)
    }
} finally {
    $reviewWord.Quit()
    [void][Runtime.InteropServices.Marshal]::FinalReleaseComObject($reviewWord)
}
