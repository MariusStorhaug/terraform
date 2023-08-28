function Get-TerraformInstalledVersion {
    param(
        [Parameter(
            ValueFromPipeline,
            ValueFromPipelineByPropertyName
        )]
        [Alias('FullName')]
        [string[]] $Path = (Find-Terraform)
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

function Find-Terraform {
    [OutputType([string[]])]
    [CmdletBinding()]
    param ()
    $terraformPaths = @()

    $drives = Get-Volume | Where-Object { $_.DriveType -eq 'Fixed' -and $_.FileSystem -eq 'NTFS' -and $null -ne $_.DriveLetter }
    $driveLetters = $drives.driveletter

    foreach ($driveLetter in $driveLetters) {
        $terraformPaths = Get-ChildItem -Path "$driveLetter`:\" -Filter terraform.exe -Recurse -ErrorAction SilentlyContinue -Force | Select-Object -ExpandProperty FullName
    }

    if ($terraformPaths.count -eq 0) {
        Write-Error 'No terraform.exe files found on the system'
        return
    }

    return $terraformPaths
}

function Get-TerraformVersion {
    [OutputType([string[]])]
    [CmdletBinding()]
    param ()

    $versionPattern = [regex]'(0|[1-9]\d*)\.(0|[1-9]\d*)\.(0|[1-9]\d*)(?:-((?:0|[1-9]\d*|\d*[a-zA-Z-][0-9a-zA-Z-]*)(?:\.(?:0|[1-9]\d*|\d*[a-zA-Z-][0-9a-zA-Z-]*))*))?(?:\+([0-9a-zA-Z-]+(?:\.[0-9a-zA-Z-]+)*))?$'

    $releases = Invoke-RestMethod 'https://api.github.com/repos/hashicorp/terraform/releases'

    $releaseTags = $releases.tag_name
    $releaseVersions = $releaseTags | Where-Object { $_ -match $versionPattern } | Sort-Object

    if ($releaseVersions.Count -eq 0) {
        Write-Error "No releases found for version [$Version]"
        return
    }

    if ($Latest) {
        return $releaseVersions[-1]
    }

    return $releaseVersions
}

function Get-TerraformReleases {
    param (
        [Parameter()]
        [switch] $Latest,

        [Parameter()]
        [switch] $AllowPrerelease,

        [Parameter()]
        [SupportsWildcards()]
        [string] $Version = '*'
    )

    $semverVersionPattern = [regex]'\d+\.\d+\.\d+$'
    if ($AllowPrerelease) {
        $semverVersionPattern = [regex]'\d+\.\d+\.\d+(-\w+)?'
    }

    $releases = Invoke-RestMethod 'https://api.github.com/repos/hashicorp/terraform/releases'

    $releaseTags = $releases.tag_name
    $releaseVersions = $releaseTags | Where-Object { $_ -match $semverVersionPattern -and $_ -like "$Version" } | Sort-Object

    if ($releaseVersions.Count -eq 0) {
        Write-Error "No releases found for version [$Version]"
        return
    }

    if ($Latest) {
        return $releaseVersions[-1]
    }

    return $releaseVersions
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
