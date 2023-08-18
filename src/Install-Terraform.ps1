
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
    [ValidateSet('AllUsers', 'CurrentUser')]
    [string] $Scope = 'CurrentUser'
)
$release = Invoke-RestMethod 'https://api.github.com/repos/hashicorp/terraform/releases/latest'
$version = ($release.tag_name).Replace('v', '')

if ($Scope -eq 'AllUsers') {
    $DownloadPath = $env:TEMP
    $InstallPath = "$env:ProgramFiles/terraform"
} else {
    $DownloadPath = (New-Object -ComObject Shell.Application).NameSpace('shell:Downloads').Self.Path
    $InstallPath = "$env:USERPROFILE/.terraform"
}

Start-BitsTransfer -Source "https://releases.hashicorp.com/terraform/$version/terraform_$version`_windows_amd64.zip" -Destination "$DownloadPath/terraform.zip"
Get-Item "$DownloadPath/terraform.zip"
Get-Item "$DownloadPath/terraform.zip" | Expand-Archive -DestinationPath $InstallPath -Force -PassThru
Get-Item "$DownloadPath/terraform.zip" | Remove-Item -Force
$env:PATH += ";$InstallPath"

if ($Scope -eq 'AllUsers') {
    [Environment]::SetEnvironmentVariable('PATH', $env:PATH, [EnvironmentVariableTarget]::Machine)
} else {
    [Environment]::SetEnvironmentVariable('PATH', $env:PATH, [EnvironmentVariableTarget]::User)
}

terraform --version
