param([Parameter(Mandatory=$true)][string]$Docx,[Parameter(Mandatory=$true)][string]$Pdf)
$ErrorActionPreference='Stop'
$word=$null;$doc=$null
try {
    $word=New-Object -ComObject Word.Application
    $word.Visible=$false;$word.DisplayAlerts=0
    $doc=$word.Documents.Open([IO.Path]::GetFullPath($Docx),$false,$true)
    $doc.Repaginate()
    $doc.ExportAsFixedFormat([IO.Path]::GetFullPath($Pdf),17)
    Write-Output ('WORD_RENDERED_PAGES='+$doc.ComputeStatistics(2))
}finally{
    if($null -ne $doc){$doc.Close(0);[Runtime.InteropServices.Marshal]::FinalReleaseComObject($doc)|Out-Null}
    if($null -ne $word){$word.Quit();[Runtime.InteropServices.Marshal]::FinalReleaseComObject($word)|Out-Null}
}
