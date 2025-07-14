# Define the path to 7-Zip executable
$sevenZipPath = "C:\Program Files\7-Zip\7z.exe"

# Function to check for .cbz files in a folder
function Has-CbzFiles {
    param (
        [string]$folderPath
    )

    # Check if the folder contains any .cbz files
    $cbzFiles = Get-ChildItem -Path $folderPath -Filter "*.cbz" -File
    return $cbzFiles.Count -gt 0
}

# Function to compress contents of a folder
function Compress-Folder {
    param (
        [string]$folderPath
    )

    # Get the parent folder and folder name
    $parentFolder = Split-Path -Path $folderPath -Parent
    $folderName = Split-Path -Path $folderPath -Leaf

    # Define the archive path
    $archivePath = Join-Path -Path $parentFolder -ChildPath "$folderName.zip"

    Write-Output "Compressing folder: $folderName in $parentFolder"

    # Escape special characters in file paths
    $escapedFolderPath = "`"$folderPath\*`""
    $escapedArchivePath = "`"$archivePath`""

    # Compress the folder's contents without including the folder structure
    $compressionResult = & "$sevenZipPath" a -tzip $escapedArchivePath $escapedFolderPath -mx9

    # Check if the compression was successful
    if (Test-Path -Path $archivePath) {
        # Rename the archive to .cbz
        $cbzPath = [System.IO.Path]::ChangeExtension($archivePath, ".cbz")
        Rename-Item -Path $archivePath -NewName $cbzPath
        Write-Output "Renamed $folderName.zip to $folderName.cbz in $parentFolder"

        # Delete the original folder
        Write-Output "Deleting original folder: $folderPath"
        Remove-Item -Path $folderPath -Recurse -Force

        # Confirm deletion
        if (!(Test-Path -Path $folderPath)) {
            Write-Output "Deleted folder: $folderPath"
        } else {
            Write-Output "Failed to delete folder: $folderPath. Check permissions."
        }
    } else {
        Write-Output "Compression failed for folder: $folderName"
    }
}

# Recursive function to process folders
function Process-InnermostFolders {
    param (
        [string]$basePath
    )

    # Get all directories at the current level
    $folders = Get-ChildItem -Path $basePath -Directory

    foreach ($folder in $folders) {
        # Check if the folder has subdirectories
        $subFolders = Get-ChildItem -Path $folder.FullName -Directory
        if ($subFolders.Count -eq 0) {
            # If no subdirectories, this is an innermost folder

            # Skip folder if it already contains .cbz files
            if (Has-CbzFiles -folderPath $folder.FullName) {
                Write-Output "Skipping folder: $folder.FullName (contains .cbz files)"
                continue
            }

            # Compress the folder
            Compress-Folder -folderPath $folder.FullName
        } else {
            # If subdirectories exist, recurse into them
            Process-InnermostFolders -basePath $folder.FullName
        }
    }
}

# Main logic
$currentDir = Get-Location
Write-Output "Starting compression in $currentDir"
Process-InnermostFolders -basePath $currentDir