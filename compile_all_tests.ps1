$inputDir = "./benches_briloop_json"
$outputDir = "./benches_briloop_wat"

$files = Get-ChildItem -Path $inputDir -File

foreach ($file in $files) {
    $inputFilePath = $file.FullName
    $baseName = $file.BaseName
    $outputFileName = "$baseName.wat"
    $outputFilePath = Join-Path -Path $outputDir -ChildPath $outputFileName

    Write-Host "Processing $($file.Name)"
    [IO.File]::WriteAllLines($outputFilePath, $(deno --allow-read index.ts $inputFilePath))
    Write-Host "Writing to $($outputFilePath)"
}
