# Define the path to 7-Zip executable
$sevenZipPath = "C:\Program Files\7-Zip\7z.exe"

# Supported archive extensions
$extensions = @(".zip", ".rar", ".7z", ".cbz", ".cbr", ".cb7")

# Function to extract an archive
function Extract-Archive {
    param (
        [string]$archivePath
    )

    # Get the parent folder and archive name without extension
    $parentFolder = Split-Path -Path $archivePath -Parent
    $archiveName = [System.IO.Path]::GetFileNameWithoutExtension($archivePath)

    # Define the extraction folder path
    $extractFolder = Join-Path -Path $parentFolder -ChildPath $archiveName

    # Ensure the extraction folder exists
    if (-Not (Test-Path -Path $extractFolder)) {
        New-Item -ItemType Directory -Path $extractFolder | Out-Null
    }

    Write-Output "Extracting `"$archivePath`" to `"$extractFolder`""

    # Extract the archive's contents
    $extractResult = & "$sevenZipPath" x "`"$archivePath`"" -o"`"$extractFolder`"" -y

    if ($extractResult -ne $null) {
        Write-Output "Extraction completed for: $archivePath"

        # Delete the archive if extraction was successful
        Write-Output "Deleting archive: $archivePath"
        Remove-Item -LiteralPath $archivePath -Force

        # Confirm deletion
        if (!(Test-Path -LiteralPath $archivePath)) {
            Write-Output "Deleted archive: $archivePath"
        } else {
            Write-Output "Failed to delete archive: $archivePath. Check permissions."
        }
    } else {
        Write-Output "Extraction failed for: $archivePath"
    }
}

# Recursive function to process all supported archives
function Process-Archives {
    param (
        [string]$basePath
    )

    # Get all files in the current directory and subdirectories
    Get-ChildItem -Path $basePath -File -Recurse | Where-Object {
        $extensions -contains $_.Extension.ToLower()
    } | ForEach-Object {
        Extract-Archive -archivePath $_.FullName
    }
}

# Main logic
$currentDir = Get-Location
Write-Output "Starting extraction in $currentDir"
Process-Archives -basePath $currentDir
