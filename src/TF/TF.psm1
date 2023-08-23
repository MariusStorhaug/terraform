function Get-TerraformInstalledVersion {
    param(
        [Parameter(
            ValueFromPipeline,
            ValueFromPipelineByPropertyName
        )]
        [Alias('FullName')]
        [string[]] $Path = 'terraform'
    )

    begin {
        $versionPattern = [regex]'\d+\.\d+\.\d+(-\w+)?'
    }

    process {
        foreach ($TerraformPath in $Path) {
            $terraformVersionOutput = & $TerraformPath --version
            $version = $versionPattern.Match($terraformVersionOutput).Value
            [pscustomobject]@{
                Path    = $TerraformPath
                Version = $version
            }
        }
    }
}

function Get-TerraformReleases {
    param (
        [switch] $Latest,
        [switch] $AllowPrerelease
    )

    $semverVersionPattern = [regex]'\d+\.\d+\.\d+(-\w+)?'

    $releases = Invoke-RestMethod 'https://api.github.com/repos/hashicorp/terraform/releases'

    $releaseTagNames = $releases.tag_name
    $releaseVersions = $releaseTagNames | ForEach-Object { $semverVersionPattern.Match($_).Value } | Sort-Object

    if (-not $AllowPrerelease) {
        $releaseVersions = $releaseVersions | Where-Object { $_ -notlike '*-*' }
    }

    if ($Latest) {
        return $releaseVersions[-1]
    }

    return $releaseVersions
}

function Find-Terraform {
    # Get all formatted data drives on the current system
    $drives = Get-Volume | Where-Object { $_.DriveType -eq 'Fixed' -and $_.FileSystem -eq 'NTFS' -and $_.DriveLetter -ne $null }
    $driveLetters = $drives.driveletter

    # For each drive letter, find the terraform.exe file
    foreach ($driveLetter in $driveLetters) {
        Get-ChildItem -Path "$driveLetter`:\" -Filter terraform.exe -Recurse -ErrorAction SilentlyContinue -Force | Select-Object -ExpandProperty FullName
    }
}

function Install-xTerraform {
    [CmdletBinding()]
    param (
        [Parameter()]
        [ValidateSet('AllUsers', 'CurrentUser')]
        [string] $Scope = 'CurrentUser',
        [Parameter()]
        [ValidateScript({ Get-TerraformReleases })]
        [string] $Version = (Get-TerraformReleases -Latest)
    )
    $Version
}

function Test-TerraformAddedInPath {
    param (
        [Parameter()]
        [Alias('FullName')]
        [string[]] $Path = 'C:\Program Files\terraform'
    )
    [Environment]::SetEnvironmentVariable('PATH', $env:PATH, [EnvironmentVariableTarget]::Machine)

    [Environment]::SetEnvironmentVariable('PATH', $env:PATH, [EnvironmentVariableTarget]::User)


    $inMachinePAth = $Path -in ([System.Environment]::GetEnvironmentVariable('PATH', [System.EnvironmentVariableTarget]::Machine) | Split-String -Separator ';')
    [System.Environment]::GetEnvironmentVariable('PATH', [System.EnvironmentVariableTarget]::User)
}

<#
.DESCRIPTION
    Installs Terraform
#>
function Install-Terraform {
    [CmdletBinding()]
    param (
        [Parameter()]
        [ValidateSet(
            'AllUsers',
            'CurrentUser'
        )]
        [string] $Scope = 'CurrentUser',

        [Parameter(
            ValueFromPipeline,
            ValueFromPipelineByPropertyName
        )]
        [ValidateScript(
            {
                Get-TerraformReleases
            }
        )]
        $Version = (Get-TerraformReleases -Latest)
    )

    $Version = Get-TerraformReleases -Latest -AllowPrerelease

    if ($Scope -eq 'AllUsers') {
        $DownloadPath = $env:TEMP
        $InstallPath = "$env:ProgramFiles/terraform"
    } else {
        $DownloadPath = (New-Object -ComObject Shell.Application).NameSpace('shell:Downloads').Self.Path
        $InstallPath = "$env:USERPROFILE/.terraform"
    }

    Start-BitsTransfer -Source "https://releases.hashicorp.com/terraform/$Version/terraform_$Version`_windows_amd64.zip" -Destination "$DownloadPath/terraform.zip"
    Get-Item "$DownloadPath/terraform.zip" | Expand-Archive -DestinationPath $InstallPath -Force
    Get-Item "$DownloadPath/terraform.zip" | Remove-Item -Force
    $env:PATH += ";$InstallPath"

    if ($Scope -eq 'AllUsers') {
        $PATH = [System.Environment]::GetEnvironmentVariable('PATH', [System.EnvironmentVariableTarget]::Machine)
        $PATH += ";$InstallPath"
        [System.Environment]::SetEnvironmentVariable('PATH', $PATH, [System.EnvironmentVariableTarget]::Machine)
    } else {
        $PATH = [System.Environment]::GetEnvironmentVariable('PATH', [System.EnvironmentVariableTarget]::User)
        $PATH += ";$InstallPath"
        [System.Environment]::SetEnvironmentVariable('PATH', $PATH, [System.EnvironmentVariableTarget]::User)
    }
}

<#
.DESCRIPTION
    Uninstalls Terraform
#>
function Uninstall-Terraform {
    [CmdletBinding()]
    param (
        [Parameter()]
        [ValidateSet('AllUsers', 'CurrentUser')]
        [string]$Scope = 'CurrentUser'
    )

    if ($Scope -eq 'AllUsers') {
        $terraformPath = "$env:ProgramFiles/terraform"
        Get-Item "$terraformPath/terraform.exe" | Remove-Item -Force
        $env:PATH = $env:PATH.replace(";$terraformPath", '')
        [Environment]::SetEnvironmentVariable('PATH', $env:PATH, [EnvironmentVariableTarget]::Machine)
    } else {
        $terraformPath = "$env:USERPROFILE/.terraform"
        Get-Item "$terraformPath/terraform.exe" | Remove-Item -Force
        $env:PATH = $env:PATH.replace(";$terraformPath", '')
        [Environment]::SetEnvironmentVariable('PATH', $env:PATH, [EnvironmentVariableTarget]::User)
    }
}

Export-ModuleMember -Function '*' -Cmdlet '*' -Variable '*' -Alias '*'
