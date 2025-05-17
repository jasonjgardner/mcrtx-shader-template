$results = @{}

Get-AppxPackage -Name "Microsoft.Minecraft*" | Select-Object -Property Version, PackageFullName, @{Name = "InstallLocation"; Expression = { $_.InstallLocation } } | ForEach-Object {
    $version = $_.Version
    $name = $_.PackageFullName
    $location = $_.InstallLocation

    $results[$version] = @{
        "name"     = $name
        "location" = $location
    }
}

$results = $results.GetEnumerator() | Sort-Object Name
$results = $results | ForEach-Object {
    $version = $_.Key
    $name = $_.Value.name
    $location = $_.Value.location

    [PSCustomObject]@{
        Version         = $version
        PackageName     = $name
        InstallLocation = $location
    }
}

$results = $results | ForEach-Object {
    $item = $_
    $materialBinFiles = @()

    if (-not [string]::IsNullOrEmpty($item.InstallLocation) -and (Test-Path -LiteralPath $item.InstallLocation -PathType Container)) {
        try {
            $foundFiles = Get-ChildItem -Path $item.InstallLocation -Recurse -Filter "RTX*.material.bin" -File -ErrorAction Stop
            
            if ($null -ne $foundFiles) {
                $materialBinFiles = $foundFiles | Select-Object -ExpandProperty FullName
            }
        }
        catch {
            Write-Warning "Error searching for material files in '$($item.InstallLocation)': $($_.Exception.Message)"
        }
    }
    
    $item | Add-Member -MemberType NoteProperty -Name "MaterialBinFiles" -Value $materialBinFiles -PassThru
}

Write-Host "Minecraft Package Information:"
$results | ForEach-Object {
    Write-Host "Version: $($_.Version)"
    Write-Host "Package Name: $($_.PackageName)"
    Write-Host "Install Location: $($_.InstallLocation)"
    Write-Host "Material Bin Files: $($_.MaterialBinFiles -join "`n")"
    Write-Host "----------------------------------------"
    Write-Host ""

    $copyFiles = Read-Host "Do you want to copy material files for version $($_.Version)? (Y/N)"

    if ($copyFiles -ne "Y" -and $copyFiles -ne "y") {
        Write-Host "Skipping copy for version $($_.Version)"
        return
    }

    $materialBinFiles = $_.MaterialBinFiles
    if ($materialBinFiles.Count -gt 0) {
        try {
            $packageDir = (Get-Location).Path
            
            foreach ($file in $materialBinFiles) {
                $fileName = Split-Path -Path $file -Leaf
                $destination = Join-Path -Path $packageDir -ChildPath $fileName

                Copy-Item -Path $file -Destination $destination -Force -ErrorAction Stop -Confirm:$false
                Write-Host "Copied '$file' to '$destination'"
            }
        }
        catch {
            Write-Warning "Failed to copy file '$file': $($_.Exception.Message)"
            Write-Host "Attempting to open the directory in Explorer for manual copying."

            $explorerPath = [System.IO.Path]::GetDirectoryName($file)
            if (Test-Path -LiteralPath $explorerPath) {
                Start-Process "explorer.exe" -ArgumentList "/select,`"$file`""
            }
            else {
                Write-Warning "Directory '$explorerPath' does not exist."
            }
        }
    }
}
