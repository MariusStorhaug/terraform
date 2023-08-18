function Get-TerraformInstalledVersion {
    $terraformVersionOutput = terraform --version
    $versionPattern = [regex]'\d+\.\d+\.\d+'
    $version = $versionPattern.Match($terraformVersionOutput).Value
    return $version
}

function Get-TerraformLatestVersion {
    param (
        [switch] $Latest
    )

    $semverVersionPattern = [regex]'\d+\.\d+\.\d+(-\w+)?'
    $semverVersionPattern = [regex]'\d+\.\d+\.\d+?'

    if ($Latest) {
        $releases = Invoke-RestMethod 'https://api.github.com/repos/hashicorp/terraform/releases/latest'
    } else {
        $releases = Invoke-RestMethod 'https://api.github.com/repos/hashicorp/terraform/releases'
    }

    $releaseTagNames = $releases.tag_name
    $releaseVersions = $releaseTagNames | ForEach-Object { $semverVersionPattern.Match($_).Value } | Sort-Object
    $releaseVersions

    $latestRelease = $releases | Sort-Object -Property published_at -Descending | Select-Object -First 1

    $latestReleaseTagName = $latestReleaseData.tag_name
    $latestVersion = $versionPattern.Match($latestReleaseTagName).Value
    return $latestVersion
}





function Get-Terraform {
    # Find the terraform.exe file on the current system
    $terraformPath = Get-ChildItem -Path C:\ -Filter terraform.exe -Recurse -ErrorAction SilentlyContinue -Force | Select-Object -First 1 -ExpandProperty FullName
    $terraformPath

    # Get all formatted data drives on the current system
    $drives = Get-Volume | Where-Object { $_.DriveType -eq 'Fixed' -and $_.FileSystem -eq 'NTFS' -and $_.DriveLetter -ne $null }
    $driveLetters = $drives.driveletter

    # For each drive letter, find the terraform.exe file
    foreach ($driveLetter in $driveLetters) {
        $terraformPath = Get-ChildItem -Path "$driveLetter`:\" -Filter terraform.exe -Recurse -ErrorAction SilentlyContinue -Force | Select-Object -ExpandProperty FullName
        if ($terraformPath) {
            $terraform = $terraformPath
        }
    }
}
