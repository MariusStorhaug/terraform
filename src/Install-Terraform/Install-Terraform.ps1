
<#PSScriptInfo

.VERSION 0.1.0

.GUID 326d27d7-4582-4d06-99d4-2a9e238a44c6

.AUTHOR Marius Storhaug

.COMPANYNAME

.COPYRIGHT

.TAGS

.LICENSEURI

.PROJECTURI

.ICONURI

.EXTERNALMODULEDEPENDENCIES

.REQUIREDSCRIPTS

.EXTERNALSCRIPTDEPENDENCIES

.RELEASENOTES


.PRIVATEDATA

#>

<#

.DESCRIPTION
    Installs Terraform

#>
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

terraform --version

