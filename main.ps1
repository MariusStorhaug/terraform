$terraform = terraform --version
#Use regex to get the file version
$regex = [regex]'\d+\.\d+\.\d+'
$version = $regex.Match($terraform).Value
$version


# Find the terraform.exe file on the current system
$terraformPath = Get-ChildItem -Path C:\ -Filter terraform.exe -Recurse -ErrorAction SilentlyContinue -Force | Select-Object -First 1 -ExpandProperty FullName
$terraformPath



# Get all formatted data drives on the current system
$drives = Get-Volume | Where-Object { $_.DriveType -eq 'Fixed' -and $_.FileSystem -eq 'NTFS' -and $_.DriveLetter -ne $null }
$driveLetters = $drives.driveletter

# For each drive letter, find the terraform.exe file
foreach ($driveLetter in $driveLetters) {
    $terraformPath = Get-ChildItem -Path "$driveLetter`:\" -Filter terraform.exe -Recurse -ErrorAction SilentlyContinue -Force | Select-Object -ExpandProperty FullName #-First 1
    if ($terraformPath) {
        $terraform = $terraformPath
        break
    }
}
